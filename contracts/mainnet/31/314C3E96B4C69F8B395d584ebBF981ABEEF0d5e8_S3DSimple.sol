pragma solidity ^0.4.24;

contract S3Devents {
    // fired at end of buy or reload
    event onEndTx
    (
        uint256 compressedData,
        uint256 compressedIDs,
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount,
        uint256 potAmount
    );

	// fired whenever theres a withdraw
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );

    // fired whenever a withdraw forces end round to be ran
    event onWithdrawAndDistribute
    (
        address playerAddress,
        uint256 ethOut,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );

    // (Solitaire3D long only) fired whenever a player tries a buy after round timer
    // hit zero, and causes end round to be ran.
    event onBuyAndDistribute
    (
        address playerAddress,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
}

contract modularLong is S3Devents { }

contract S3DSimple is modularLong {
    using SafeMath for *;
    using S3DKeysCalcLong for uint256;

    string constant public name = "Solitaire 3D";
    string constant public symbol = "Solitaire";
    uint256 private rndExtra_ = 30 seconds;     // length of the very first ICO
    uint256 private rndGap_ = 30 seconds;         // length of ICO phase, set to 1 year for EOS.
    uint256 constant private rndInit_ = 10 minutes;                // round timer starts at this
    uint256 constant private rndInc_ = 60 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be
    address constant private developer = 0xA7759a5CAcE1a3b54E872879Cf3942C5D4ff5897;
    address constant private operator = 0xc3F465FD001f78DCEeF6f47FD18E3B04F95f2337;

    uint256 public rID_;    // round id number / total rounds that have happened

    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (uint256 => S3Ddatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => S3Ddatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id

    mapping (uint256 => S3Ddatasets.Round) public round_;   // (rID => data) round data
    uint256 public pID_;
    S3Ddatasets.TeamFee public fee_;

    constructor()
        public
    {

        fee_ = S3Ddatasets.TeamFee(50);   //20% to pot, 15% to aff, 2% to com, 1% to pot swap, 1% to air drop pot
        plyr_[1].addr = 0xA7759a5CAcE1a3b54E872879Cf3942C5D4ff5897;
        pIDxAddr_[0xA7759a5CAcE1a3b54E872879Cf3942C5D4ff5897] = 1;
        pID_ = 1;
    }
    /**
     * @dev used to make sure no one can interact with contract until it has
     * been activated.
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord");
        _;
    }

    /**
     * @dev prevents contracts from interacting with Solitaire3D
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
        require(_eth >= 0, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

    /**
     * @dev emergency buy uses last stored affiliate ID and team snek
     */
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        S3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // buy core
        if (msg.value > 1000000000){
            buyCore(_pID, _eventData_);
        }else{
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
            withdraw();
        }

    }

    /**
     * @dev withdraws all of your earnings.
     * -functionhash- 0x3ccfd60b
     */
    function withdraw()
        isActivated()
        isHuman()
        public
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // setup temp var for player eth
        uint256 _eth;

        // check to see if round has ended and no one has run round end yet
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // set up our tx event data
            S3Ddatasets.EventReturns memory _eventData_;

            // end the round (distributes pot)
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

			// get their earnings
            _eth = withdrawEarnings(_pID);

            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire withdraw and distribute event
            emit S3Devents.onWithdrawAndDistribute
            (
                msg.sender,
                _eth,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.genAmount
            );

        // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(_pID);

            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // fire withdraw event
            emit S3Devents.onWithdraw(_pID, msg.sender, _eth, _now);
        }
    }

//==============================================================================
//     _  _ _|__|_ _  _ _  .
//    (_|(/_ |  | (/_| _\  . (for UI & viewing things on etherscan)
//=====_|=======================================================================
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
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
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
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + rndGap_).sub(_now) );
        else
            return(0);
    }

    /**
     * @dev returns player earnings per vaults
     * -functionhash- 0x63066434
     * @return winnings vault
     * @return general vault
     * @return affiliate vault
     */
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // if player is winner
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(90)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   )
                );
            // if player is not the winner
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  )
                );
            }

        // if round is still going on, or round has ended and round end has been ran
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd))
            );
        }
    }

    /**
     * solidity hates stack limits.  this lets us avoid that hate
     */
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return(((((round_[_rID].mask) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000);
    }

    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, address)
    {
        // setup local rID
        uint256 _rID = rID_;

        return
        (
            _rID,                           //0
            round_[_rID].keys,              //1
            round_[_rID].end,               //2
            round_[_rID].strt,              //3
            round_[_rID].pot,               //4
            plyr_[round_[_rID].plyr].addr  //5
        );
    }

    function getPlayerInfoByAddress(address _addr)
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
            _pID,                               //0
            plyrRnds_[_pID][_rID].keys,         //1
            plyr_[_pID].win,                    //2
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)), //3
            plyrRnds_[_pID][_rID].eth           //4
        );
    }

//==============================================================================
//     _ _  _ _   | _  _ . _  .
//    (_(_)| (/_  |(_)(_||(_  . (this + tools + calcs + modules = our softwares engine)
//=====================_|=======================================================
    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle
     * incoming eth depending on if we are in an active round or not
     */
    function buyCore(uint256 _pID, S3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // if round is active
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // call core
            core(_rID, _pID, msg.value, _eventData_);

        // if round is not active
        } else {
            // check to see if end round needs to be ran
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                // end the round (distributes pot) & start new round
			    round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                // build event data
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                // fire buy and distribute event
                emit S3Devents.onBuyAndDistribute
                (
                    msg.sender,
                    msg.value,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,
                    _eventData_.winnerAddr,
                    _eventData_.amountWon,
                    _eventData_.newPot,
                    _eventData_.genAmount
                );
            }

            // put eth in players vault
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }

    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            // put in gen vault
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // zero out their earnings by updating mask
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }
    function managePlayer(uint256 _pID, S3Ddatasets.EventReturns memory _eventData_)
        private
        returns (S3Ddatasets.EventReturns)
    {
        // if player has played a previous round, move their unmasked earnings
        // from that round to gen vault.
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

        // update player&#39;s last round played
        plyr_[_pID].lrnd = rID_;

        // set the joined round bool to true
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }
    /**
     * @dev this is the core logic for any buy/reload that happens while a round
     * is live.
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, S3Ddatasets.EventReturns memory _eventData_)
        private
    {

        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
        // if eth left is greater than min eth allowed (sorry no pocket lint)
        if (_eth > 1000000000)
        {

            // mint the new keys
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);

            // if they bought at least 1 whole key
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);

                // set new leaders
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;

                // set the new leader bool to true
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

            // update player
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            // update round
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);

            // distribute eth
            _eventData_ = distributeExternal(_eth, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _keys, _eventData_);

            // call end tx function to fire end tx event.
            endTx(_pID, _eth, _keys, _eventData_);
        }
    }

    /**
     * @dev returns the amount of keys you would get given an amount of eth.
     * -functionhash- 0xce89c80c
     * @param _rID round ID you want price for
     * @param _eth amount of eth sent in
     * @return keys received
     */
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth) );
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
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else // rounds over.  need price for new round
            return ( (_keys).eth() );
    }

    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID
     */
    function determinePID(S3Ddatasets.EventReturns memory _eventData_)
        private
        returns (S3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        // if player is new to this version of Solitaire3D
        if (_pID == 0)
        {
            // grab their player ID, name and last aff ID, from player names contract

            pID_++;
            _pID = pID_;
            // set up player account
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;

            // set the new player bool to true
            _eventData_.compressedData = _eventData_.compressedData + 1;
        }
        return (_eventData_);
    }

    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound(S3Ddatasets.EventReturns memory _eventData_)
        private
        returns (S3Ddatasets.EventReturns)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab our winning player and team id&#39;s
        uint256 _winPID = round_[_rID].plyr;

        // grab our pot amount
        uint256 _pot = round_[_rID].pot;

        // calculate our winner share, community developers, gen share,
        // p3d share, and amount reserved for next pot
        uint256 _win = (_pot.mul(90)) / 100;
        uint256 _com = (_pot / 20);
        uint256 _res = ((_pot.sub(_win)).sub(_com)).sub(_com);

        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        if (_com > 0) {
            developer.transfer(_com);
            operator.transfer(_com);
        }

        // prepare event data
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = 0;
        _eventData_.newPot = _res;

        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = _res;

        return(_eventData_);
    }
    /**
     * @dev updates round timer based on number of whole keys bought.
     */
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        // grab time
        uint256 _now = now;

        // calculate time based on number of keys bought
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);

        // compare to max and set new end time
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }
    /**
     * @dev distributes eth based on fees to com, aff, and p3d
     */
    function distributeExternal(uint256 _eth, S3Ddatasets.EventReturns memory _eventData_)
        private
        returns(S3Ddatasets.EventReturns)
    {

        // pay 5% to developer and operator
        uint256 _long = _eth / 20;
        developer.transfer(_long);
        operator.transfer(_long);

        return(_eventData_);
    }

    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _keys, S3Ddatasets.EventReturns memory _eventData_)
        private
        returns(S3Ddatasets.EventReturns)
    {
        // calculate gen share
        uint256 _gen = (_eth.mul(fee_.gen)) / 100;

        // update eth balance (eth = eth - (dev share + oper share))
        _eth = _eth.sub(((_eth.mul(10)) / 100));

        // calculate pot
        uint256 _pot = _eth.sub(_gen);

        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

        // add eth to pot
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

        // set up event data
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return(_eventData_);
    }

    /**
     * @dev updates masks for round and player when keys are bought
     * @return dust left over
     */
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {

        // calc profit per key & round mask based on this buy:  (dust goes to pot)
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // calculate player earning from their own buy (only based on the keys
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

        // calculate & return dust
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }

    /**
     * @dev adds up unmasked earnings, & vault earnings, sets them all to 0
     * @return earnings in wei format
     */
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        updateGenVault(_pID, plyr_[_pID].lrnd);
        // from vaults
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
        }

        return(_earnings);
    }

    /**
     * @dev prepares compression data and fires event for buy or reload tx&#39;s
     */
    function endTx(uint256 _pID, uint256 _eth, uint256 _keys, S3Ddatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit S3Devents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.genAmount,
            _eventData_.potAmount
        );
    }

    bool public activated_ = false;
    function activate()
        public
    {
        // only team just can activate
        require(
            msg.sender == 0xA7759a5CAcE1a3b54E872879Cf3942C5D4ff5897,
            "only team just can activate"
        );

        // can only be ran once
        require(activated_ == false, "Solitaire3D already activated");

        // activate the contract
        activated_ = true;

        // lets start first round
		rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }
}

library S3Ddatasets {

    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 potAmount;          // amount added to pot
        uint256 genAmount;
    }
    struct Player {
        address addr;   // player address
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 lrnd;   // last round played
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask
    }
    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
    }
    struct TeamFee {
        uint256 gen;    // % of buy in thats paid to key holders of current round
    }
    struct PotSplit {
        uint256 gen;    // % of pot thats paid to key holders of current round
    }
}

//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================
library S3DKeysCalcLong {
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
     * @param _eth eth "in contract"
     * @return number of keys that would exist
     */
    function keys(uint256 _eth)
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
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