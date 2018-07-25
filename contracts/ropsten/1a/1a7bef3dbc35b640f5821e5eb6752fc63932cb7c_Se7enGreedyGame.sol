pragma solidity ^0.4.24;


/**
*
* @author Satan
*
*/
contract GreedyGameEvent {

    event Log(string content);

	// fired whenever theres a withdraw
    event onWithdraw
    (
        uint256 indexed playerId,
        address playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );

    event onBuy
    (
      address playerAddress,
      uint256 ethIn,
      uint256 keys
    );

    event onRoundGameOver
    (
        uint256 ronudId,
        address winer,
        uint256 prize,
        uint256 eths,
        uint256 keys,
        uint256 rest
    );

    // (fomo3d long only) fired whenever a player tries a reload after round timer
    // hit zero, and causes end round to be ran.
    event onReLoad
    (
        address playerAddress,
        uint256 eths
    );
}

contract modularLong is GreedyGameEvent {}


contract Se7enGreedyGame is modularLong {
    using SafeMath for *;
    using NameFilter for string;
    using GreedyKeysCalcLong for uint256;

    bool public isActive = false;

    string constant public name = &quot;Greedy of Se3en&quot;;
    string constant public symbol = &quot;Greedy&quot;;

    // total = 8% team fee + 48% big prize + 50% (bonus, 20% for next circle, 80% for player...)
    address public communityAddress = 0xbAbfCD5BFF3bd2ED6592d89856Aa2bA3a08fE86c;

    /* fee and rate  */
    uint256 constant public teamfee = 10;
    uint256 constant public winerPrizeRate = 42;
    uint256 constant public playersRate = 50;

    uint256 constant public nextRate = 10;
    uint256 constant public playerIncomeRate = 90;

    /*  statics */
    uint256 public currendRoundId = 0;

    /* player data */
    uint256 public pidNo = 1;
    mapping (address => uint256) public pIDxAddr;          // (addr => pID) returns player id by address
    mapping (uint256 => Greedydatasets.Player) public players;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => Greedydatasets.PlayerRounds)) public playerRounds;    // (pID => rID => data) player round data by player id & round id

    /*  round data */
    mapping (uint256 => Greedydatasets.Round) public rounds;   // (rID => data) round data

    uint256 constant public timeLimit = 1 hours;                // max length a round timer can be

    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, &quot;pocket lint: not a valid currency&quot;);
        require(_eth <= 100000000000000000000000, &quot;no vitalik, no&quot;);
        _;
    }

    function ()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
   {
       uint256 _playerId = determinePID(msg.sender);
       buyCore(_playerId);
    }


    function buyXaddr()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        uint256 _playerId = determinePID(msg.sender);
        buyCore(_playerId);
    }

    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID
     */
    function determinePID(address addr)
        private
        returns (uint256)
    {
        uint256 _playerId = pIDxAddr[addr];
        // if player is new to this version of fomo3d
        if (_playerId == 0)
        {
            // grab their player ID, name and last aff ID, from player names contract
            _playerId = pidNo;
            pidNo = pidNo + 1;
            pIDxAddr[addr] = _playerId;
            players[_playerId].addr = addr;
        }
        return (_playerId);
    }


    function buyCore(uint256 _playerId)
    private
    {
      uint256 _currendRoundId = currendRoundId;
      uint256 _now = now;
        emit GreedyGameEvent.Log(&quot;start to buy keys&quot;);

      // if round is active
      if (_now > rounds[_currendRoundId].start
        && (_now <= rounds[_currendRoundId].end   || (_now > rounds[_currendRoundId].end   && rounds[_currendRoundId].playerId == 0) ) )
      {
          // call core
          core(_currendRoundId, _playerId, msg.value);
      // if round is not actives
      } else {
          // check to see if end round needs to be ran
          if (_now > rounds[_currendRoundId].end && rounds[_currendRoundId].gameover == false)
          {
              // end the round (distributes pot) & start new round
              rounds[_currendRoundId].gameover = true;
              endRound();
          }
          emit GreedyGameEvent.Log(&quot;buyCore exit as _now < start or _now > end but playerId  != 0&quot;);
          // put eth in players vault
          players[_playerId].gen = players[_playerId].gen.add(msg.value);
      }
    }


    function core(uint256 _currentRoundId, uint256 _playerId, uint256 _eth)
        private
    {

      // if player is new to round
      if (playerRounds[_playerId][_currentRoundId].keys == 0){
          // if player has played a previous round, move their unmasked earnings
          // from that round to gen vault.
          if (players[_playerId].lastRoundId != 0)
              updateGenVault(_playerId, players[_playerId].lastRoundId);

          // update player&#39;s last round played
          players[_playerId].lastRoundId = currendRoundId;
      }

      // early round eth limiter
      if (rounds[_currentRoundId].eths < 100000000000000000000 && playerRounds[_playerId][_currentRoundId].eths.add(_eth) > 1000000000000000000)
      {
          uint256 _availableLimit = (1000000000000000000).sub(playerRounds[_playerId][_currentRoundId].eths);
          uint256 _refund = _eth.sub(_availableLimit);
          players[_playerId].gen = players[_playerId].gen.add(_refund);
          _eth = _availableLimit;
      }

      // if eth left is greater than min eth allowed (sorry no pocket lint)
      if (_eth > 1000000000)
      {
          // mint the new keys
          uint256 _keys = (rounds[_currentRoundId].eths).keysRec(_eth);

          // if they bought at least 1 whole key
          if (_keys >= 1000000000000000000)
          {
              uint256 _now = now;
              rounds[_currentRoundId].end = timeLimit.add(_now);

              // set new leaders
              if (rounds[_currentRoundId].playerId != _playerId)
                  rounds[_currentRoundId].playerId = _playerId;
          }

          // update player
          playerRounds[_playerId][_currentRoundId].keys = _keys.add(playerRounds[_playerId][_currentRoundId].keys);
          playerRounds[_playerId][_currentRoundId].eths = _eth.add(playerRounds[_playerId][_currentRoundId].eths);

          // update round
          rounds[_currentRoundId].keys = _keys.add(rounds[_currentRoundId].keys);
          rounds[_currentRoundId].eths = _eth.add(rounds[_currentRoundId].eths);

          // distribute eth
          // calculate gen share
          uint256 _gen = _eth.mul(playersRate).mul(playerIncomeRate)/10000;

          // distribute gen share (thats what updateMasks() does) and adjust
          // balances for dust.
          updateMasks(_currentRoundId, _playerId, _gen, _keys);

          rounds[_currentRoundId].pot = _gen.add(rounds[_currentRoundId].pot);

          emit GreedyGameEvent.onBuy(msg.sender, _eth, _keys);
      }
    }


    /**
    * 提前， 同时在游戏结束的时候，仍然支持大家提现
    *
    */
    function withdraw()
        isHuman()
        public
    {
        // setup local rID
        uint256 _currendRoundId = currendRoundId;

        // grab time
        uint256 _now = now;

        // fetch player ID
        uint256 _playerId = pIDxAddr[msg.sender];

        // setup temp var for player eth
        uint256 _eth;

        if (_now > rounds[_currendRoundId].end && rounds[_currendRoundId].gameover == false && rounds[_currendRoundId].playerId != 0)
        {
            // end the round (distributes pot)
			       rounds[_currendRoundId].gameover = true;
             endRound();
        }

        // get their earnings
        _eth = withdrawEarnings(_playerId);

        // gib moni
        if (_eth > 0) {
            players[_playerId].addr.transfer(_eth);
            emit GreedyGameEvent.onWithdraw(_playerId, msg.sender, _eth, _now);
        }
    }


    function reLoadXaddr(uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // fetch player ID
        uint256 _playerId = pIDxAddr[msg.sender];
        reLoadCore(_playerId, _eth);
    }

    /**
     * @dev logic runs whenever a reload order is executed.  determines how to handle
     * incoming eth depending on if we are in an active round or not
     */
    function reLoadCore(uint256 _playerId, uint256 _eth)
        private
    {
        // setup local rID
        uint256 _currendRoundId = currendRoundId;
        // grab time
        uint256 _now = now;

        // if round is active
        if (_now > rounds[_currendRoundId].start
          && (_now <= rounds[_currendRoundId].end
            || (_now > rounds[_currendRoundId].end
              && rounds[_currendRoundId].playerId == 0)))
        {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player
            // tried to spend more eth than they have.
            players[_playerId].gen = withdrawEarnings(_playerId).sub(_eth);

            // call core
            core(_currendRoundId, _playerId, _eth);

            emit onReLoad(
              msg.sender,
              _eth
            );
        // if round is not active and end round needs to be ran
        } else if (_now > rounds[_currendRoundId].end && rounds[_currendRoundId].gameover == false) {
            // end the round (distributes pot) & start new round
            rounds[_currendRoundId].gameover = true;
            endRound();
        }
    }


    /**
     * @dev adds up unmasked earnings, & vault earnings, sets them all to 0
     * @return earnings in wei format
     */
    function withdrawEarnings(uint256 _playerId)
        private
        returns(uint256)
    {
        // update gen vault
        updateGenVault(_playerId, players[_playerId].lastRoundId);

        // from vaults
        uint256 _earnings = (players[_playerId].win).add(players[_playerId].gen);
        if (_earnings > 0)
        {
            players[_playerId].win = 0;
            players[_playerId].gen = 0;
        }

        return(_earnings);
    }



    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(uint256 _playerId, uint256 lastRoundId)
        private
    {
        uint256 _earnings = calcUnMaskedEarnings(_playerId, lastRoundId);
        if (_earnings > 0)
        {
            // put in gen vault
            players[_playerId].gen = _earnings.add(players[_playerId].gen);
            // zero out their earnings by updating mask
            playerRounds[_playerId][lastRoundId].mask = _earnings.add(playerRounds[_playerId][lastRoundId].mask);
        }
    }


    /**
     * @dev updates masks for round and player when keys are bought
     * @return dust left over
     */
    function updateMasks(uint256 _currentRoundId, uint256 _playerId, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
        /* MASKING NOTES
            earnings masks are a tricky thing for people to wrap their minds around.
            the basic thing to understand here.  is were going to have a global
            tracker based on profit per share for each round, that increases in
            relevant proportion to the increase in share supply.

            the player will have an additional mask that basically says &quot;based
            on the rounds mask, my shares, and how much i&#39;ve already withdrawn,
            how much is still owed to me?&quot;
        */

        // calc profit per key & round mask based on this buy:  (dust goes to pot)
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (rounds[_currentRoundId].keys);
        rounds[_currentRoundId].mask = _ppt.add(rounds[_currentRoundId].mask);

        // calculate player earning from their own buy (only based on the keys
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        playerRounds[_playerId][_currentRoundId].mask = (((rounds[_currentRoundId].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(playerRounds[_playerId][_currentRoundId].mask);

        // calculate & return dust
        return(_gen.sub((_ppt.mul(rounds[_currentRoundId].keys)) / (1000000000000000000)));
        /*  = _gen */
    }


    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound()
        private
    {
        // setup local rID
        uint256 _currendRoundId = currendRoundId;

        // grab our winning player and team id&#39;s
        uint256 _winPID = rounds[_currendRoundId].playerId;

        // grab our pot amount
        uint256 _eth = rounds[_currendRoundId].eths;       // 总eth池子

        // calculate our winner share, community rewards, gen share, and amount reserved for next pot
        uint256 _win = _eth.mul(winerPrizeRate) / 100;  // big prize
        uint256 _com = _eth.mul(teamfee) / 100;         // community prize
        uint256 _rest = _eth.mul(playersRate).mul(nextRate) / 100;
        uint256 _gen = rounds[_currendRoundId].pot;

        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (rounds[_currendRoundId].keys);

        // pay our winner
        players[_winPID].win = _win.add(players[_winPID].win);

        // send to community
        communityAddress.transfer(_com);

        // distribute gen portion to key holders
        rounds[_currendRoundId].mask = _ppt.add(rounds[_currendRoundId].mask);


        emit GreedyGameEvent.onRoundGameOver(
            _currendRoundId,
            players[_winPID].addr,
            _win,
            _eth,
            rounds[_currendRoundId].keys,
            _rest
        );

        // start next round
        currendRoundId++;
        _currendRoundId = currendRoundId;

        rounds[_currendRoundId].start = now;
        rounds[_currendRoundId].end = now.add(timeLimit);
        rounds[_currendRoundId].eths = _rest;
        rounds[_currendRoundId].pot = _rest.mul(playersRate).mul(playerIncomeRate) / 10000;
    }


    function activate()
        public
    {
        // only team just can activate
        require(isActive == false, &quot;Greedy Game already activated&quot;);

        // activate the contract
        isActive = true;

        // lets start first round
		    currendRoundId = 1;
        rounds[1].start = now;
        rounds[1].end = now.add(timeLimit);
    }


    modifier isActivated() {
        require(isActive == true, &quot;its not ready yet.  check ?eta in discord&quot;);
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, &quot;sorry humans only&quot;);
        _;
    }



    /**
     * @dev calculates unmasked earnings (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedEarnings(uint256 _playerId, uint256 lastRoundId)
        private
        view
        returns(uint256)
    {
        return(  (((rounds[lastRoundId].mask).mul(playerRounds[_playerId][lastRoundId].keys)) / (1000000000000000000)).sub(playerRounds[_playerId][lastRoundId].mask)  );
    }

    /**
     * @dev returns the amount of keys you would get given an amount of eth.
     * -functionhash- 0xce89c80c
     * @param _currentRoundId round ID you want price for
     * @param _eth amount of eth sent in
     * @return keys received
     */
    function calcKeysReceived(uint256 _currentRoundId, uint256 _eth)
        public
        view
        returns(uint256)
    {
        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > rounds[_currentRoundId].start
          && (_now <= rounds[_currentRoundId].end
            || (_now > rounds[_currentRoundId].end
              && rounds[_currentRoundId].playerId == 0)))
            return ( (rounds[_currentRoundId].eths).keysRec(_eth) );
        else // rounds over.  need keys for new round
            return ( (_eth).keys() );
    }

    /**
     * @dev returns current eth price for X keys.
     * -functionhash- 0xcf808000
     * @param _keys number of keys desired (in 18 decimal format)
     * @return amount of eth needed to send
     */
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _currentRoundId = currendRoundId;
        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > rounds[_currentRoundId].start
          && (_now <= rounds[_currentRoundId].end
            || (_now > rounds[_currentRoundId].end
              && rounds[_currentRoundId].playerId == 0)))
            return ( (rounds[_currentRoundId].keys.add(_keys)).ethRec(_keys) );
        else // rounds over.  need price for new round
            return ( (_keys).eth() );
    }


    /**
     * @dev return the price buyer will pay for next 1 individual key.
     * -functionhash- 0x018a25e8
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice()
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _currentRoundId = currendRoundId;
        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > rounds[_currentRoundId].start
          && (_now <= rounds[_currentRoundId].end
            || (_now > rounds[_currentRoundId].end
              && rounds[_currentRoundId].playerId == 0)))
            return ( (rounds[_currentRoundId].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( 75000000000000 ); // init
    }

    /**
     * @dev returns time left.  dont spam this, you&#39;ll ddos yourself from your node
     * provider
     * -functionhash- 0xc7e284b8
     * @return time left in seconds
     */
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _currendRoundId = currendRoundId;

        // grab time
        uint256 _now = now;

        if (_now < rounds[_currendRoundId].end)
            return( (rounds[_currendRoundId].end).sub(_now) );
        else
            return(0);
    }

    /**
     * @dev returns player earnings per vaults
     * -functionhash- 0x63066434
     * @return winnings vault
     * @return general vault
     */
    function getPlayerVaults(uint256 _playerId)
        public
        view
        returns(uint256 ,uint256)
    {
        // setup local rID
        uint256 _currendRoundId = currendRoundId;

        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        if (now > rounds[_currendRoundId].end && rounds[_currendRoundId].gameover == false && rounds[_currendRoundId].playerId != 0)
        {
            // if player is winner
            if (rounds[_currendRoundId].playerId == _playerId)
            {
                return
                (
                    (players[_playerId].win).add( ((rounds[_currendRoundId].eths).mul(winerPrizeRate)) / 100 ),
                    (players[_playerId].gen).add(  getPlayerVaultsHelper(_playerId, _currendRoundId).sub(playerRounds[_playerId][_currendRoundId].mask)   )
                );
            // if player is not the winner
            } else {
                return
                (
                    players[_playerId].win,
                    (players[_playerId].gen).add( getPlayerVaultsHelper(_playerId, _currendRoundId).sub(playerRounds[_playerId][_currendRoundId].mask) )
                );
            }

        // if round is still going on, or round has ended and round end has been ran
        } else {
            return
            (
                players[_playerId].win,
                (players[_playerId].gen).add(calcUnMaskedEarnings(_playerId, players[_playerId].lastRoundId))
            );
        }
    }

    /**
     * solidity hates stack limits.  this lets us avoid that hate
     */
    function getPlayerVaultsHelper(uint256 _playerId, uint256 _currendRoundId)
        private
        view
        returns(uint256)
    {
        return(  ((((rounds[_currendRoundId].mask).add(((((rounds[_currendRoundId].pot))).mul(1000000000000000000)) / (rounds[_currendRoundId].keys))).mul(playerRounds[_playerId][_currendRoundId].keys)) / 1000000000000000000) );
    }

    /**
     * @dev returns all current round info needed for front end
     * -functionhash- 0x747dff42
     * @return game over?
     * @return round id
     * @return total keys for round
     * @return time round ends
     * @return time round started
     * @return eths
     * @return prize
     * @return current pot // 分红池子
     * @return current player ID in lead
     * @return current player in leads address
     * @return total players
     */
    function getCurrentRoundInfo()
        public
        view
        returns(bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, uint256)
    {
        // setup local rID
        uint256 _currendRoundId = currendRoundId;

        return
        (
            rounds[_currendRoundId].gameover,
            _currendRoundId,                           //1
            rounds[_currendRoundId].keys,              //2
            rounds[_currendRoundId].end,               //3
            rounds[_currendRoundId].start,              //4
            rounds[_currendRoundId].eths,               //5
            rounds[_currendRoundId].eths.mul(winerPrizeRate)/100,// winner prize
            rounds[_currendRoundId].pot,               //5
            rounds[_currendRoundId].playerId,          //6
            players[rounds[_currendRoundId].playerId].addr,  //7
            pidNo - 1
        );
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will
     * use msg.sender
     * -functionhash- 0xee0b5d8b
     * @param _addr address of the player you want to lookup
     * @return player ID
     * @return keys owned (current round)
     * @return winnings vault
     * @return general vault
     * @return player round eth
     */
    function getPlayerInfoByAddress(address _addr)
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _currendRoundId = currendRoundId;

        if (_addr == address(0)){
            _addr == msg.sender;
        }
        uint256 _playerId = pIDxAddr[_addr];

        return
        (
            _playerId,                               //0
            playerRounds[_playerId][_currendRoundId].keys,         //2
            players[_playerId].win,                    //3
            (players[_playerId].gen).add(calcUnMaskedEarnings(_playerId, players[_playerId].lastRoundId)),       //4
            playerRounds[_playerId][_currendRoundId].eths          //6
        );
    }

}


library Greedydatasets {

  struct Player {
      address addr;   // player address

      uint256 win;    // winnings vault
      uint256 gen;    // general vault
      uint256 lastRoundId;   // last round played
  }

  struct PlayerRounds {
      uint256 eths;    // eth player has added to round (used for eth limiter)
      uint256 keys;   // keys
      uint256 mask;   // player mask
  }

  struct Round {
      bool gameover;     // has round end function been ran
      uint256 playerId;  // pID of player in lead
      uint256 end;       // time ends/gameover
      uint256 start;     // time round started
      uint256 keys;      // keys
      uint256 eths;      // total eths in

      uint256 pot;       // eth to pot (during round) / final amount paid to winner (after round ends)
      uint256 mask;      // player mask
  }
}


//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================
library GreedyKeysCalcLong {
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
     * @param _eth eth &quot;in contract&quot;
     * @return number of keys that would exist
     *    { sqrt[ (_eth * 3125) + 5624988281256103515625 ]  - 74999921875 } / 156250000
     */
    function keys(uint256 _eth)
        internal
        pure
        returns(uint256)
    {
        return (((  (   ((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)) .add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }

    /**
     * @dev calculates how much eth would be in contract given a number of keys
     * @param _keys number of keys &quot;in contract&quot;
     * @return eth that would exists
     *   { [ 78125000 * _keys^2  + ( 149999843750000  * _keys ) ] / 2 } ^ 2
     *
     */
    function eth(uint256 _keys)
        internal
        pure
        returns(uint256)
    {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
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
        require (_length <= 32 && _length > 0, &quot;string must be between 1 and 32 characters&quot;);
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, &quot;string cannot start or end with space&quot;);
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, &quot;string cannot start with 0x&quot;);
            require(_temp[1] != 0x58, &quot;string cannot start with 0X&quot;);
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
                    &quot;string contains invalid characters&quot;
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, &quot;string cannot contain consecutive spaces&quot;);

                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, &quot;string cannot be only numbers&quot;);

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
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
        require(c / a == b, &quot;SafeMath mul failed&quot;);
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
        require(b <= a, &quot;SafeMath sub failed&quot;);
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
        require(c >= a, &quot;SafeMath add failed&quot;);
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