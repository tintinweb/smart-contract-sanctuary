pragma solidity ^0.4.24;


contract Coinevents {
    // fired whenever a player registers a name
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 amountPaid,
        uint256 timeStamp
    );
    event onBuy (
        address playerAddress,
        uint256 begin,
        uint256 end,
        uint256 round,
        bytes32 playerName
    );
    // fired whenever theres a withdraw
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );
    // settle the contract
    event onSettle(
        uint256 rid,
        uint256 ticketsout,
        address winner,
        uint256 luckynum,
        uint256 jackpot
    );
    // settle the contract
    event onActivate(
        uint256 rid
    );
}


contract LuckyCoin is Coinevents{
    using SafeMath for *;
    using NameFilter for string;
    
    //**************** game settings ****************
     string constant public name = "LuckyCoin Super";
     string constant public symbol = "LuckyCoin";
     uint256 constant private rndGap_ = 2 hours;                // round timer starts at this

     uint256 ticketstotal_ = 1500;       // ticket total amonuts
     uint256 grouptotal_ = 250;    // ticketstotal_ divend to six parts
     //uint ticketprice_ = 0.005 ether;   // current ticket init price
     uint256 jackpot = 10 ether;
     uint256 public rID_= 0;      // current round id number / total rounds that have happened
     uint256 _headtickets = 500;  // head of 500, distributes valuet
     bool public activated_ = false;
     
     //address community_addr = 0x2b5006d3dce09dafec33bfd08ebec9327f1612d8;    // community addr
     //address prize_addr = 0x2b5006d3dce09dafec33bfd08ebec9327f1612d8;        // prize addr
 
     
     address community_addr = 0xfd76dB2AF819978d43e07737771c8D9E8bd8cbbF;    // community addr
     address prize_addr = 0xfd76dB2AF819978d43e07737771c8D9E8bd8cbbF;        // prize addr
     address activate_addr1 = 0xfd76dB2AF819978d43e07737771c8D9E8bd8cbbF;    // activate addr1
     address activate_addr2 = 0x6c7dfe3c255a098ea031f334436dd50345cfc737;    // activate addr2
     //address activate_addr2 = 0x2b5006d3dce09dafec33bfd08ebec9327f1612d8;    // activate addr2
     PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x748286a6a4cead7e8115ed0c503d77202eeeac6b);

    //**************** ROUND DATA ****************
    mapping (uint256 => Coindatasets.Round) public round_;   // (rID => data) round data
    
    //**************** PLAYER DATA ****************
    event LogbuyNums(address addr, uint begin, uint end);
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => Coindatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => Coindatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)
    
    //**************** ORDER DATA ****************
    mapping (uint256=>mapping(uint=> mapping(uint=>uint))) orders;  // (rid=>pid=group=>ticketnum)
    
    constructor() public{
        //round_[rID_].jackpot = 10 ether;
    }
    
    // callback function
    function ()
        payable
    {
        // fllows addresses only can activate the game
        if (msg.sender == activate_addr1 ||
            msg.sender == activate_addr2
        ){
           activate();
        }else if(msg.value > 0){ //bet order
            // fetch player id
            address _addr = msg.sender;
            uint256 _codeLength;
            require(tx.origin == msg.sender, "sorry humans only origin");
            assembly {_codeLength := extcodesize(_addr)}
            require(_codeLength == 0, "sorry humans only=================");

            determinePID();
            uint256 _pID = pIDxAddr_[msg.sender];
            uint256 _ticketprice = getBuyPrice();
            require(_ticketprice > 0);
            uint256 _tickets = msg.value / _ticketprice;
            require(_tickets > 0);
            // buy tickets
            require(activated_ == true, "its not ready yet.  contact administrators");
            require(_tickets <= ticketstotal_ - round_[rID_].tickets);
            buyTicket(_pID, plyr_[_pID].laff, _tickets);
        }

    }

    //  purchase value limit   
    modifier isWithinLimits(uint256 _eth, uint256 _tickets) {
        uint256 _ticketprice = getBuyPrice();
        require(_eth >= _tickets * _ticketprice);
        require(_eth <= 100000000000000000000000);
        _;    
    }
    
    modifier isTicketsLimits(uint256 _tickets){
        require(_tickets <= ticketstotal_ - round_[rID_].tickets);
        _;
    }
    
    modifier isActivated(){
        require(activated_, "not activate");
        _;
    }
    
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        require(tx.origin == msg.sender, "sorry humans only origin");
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only=================");
        _;
    }
    
    function buyXid(uint _tickets, uint256 _affCode)
          isHuman()
          isWithinLimits(msg.value, _tickets)
          isTicketsLimits(_tickets)
          isActivated
          public 
          payable
    {
       // set up our tx event data and determine if player is new or not
        //Coindatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        determinePID();
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == 0 || _affCode == _pID)
        {
            // use last stored affiliate code 
            _affCode = plyr_[_pID].laff;
            
        // if affiliate code was given & its not the same as previously stored 
        } else if (_affCode != plyr_[_pID].laff) {
            // update last affiliate 
            plyr_[_pID].laff = _affCode;
        }
        
        buyTicket(_pID, _affCode, _tickets);      
    }
    
    function buyXaddr(uint _tickets, address _affCode) 
          isHuman()
          isWithinLimits(msg.value, _tickets)
          isTicketsLimits(_tickets)
          isActivated
          public 
          payable 
    {
        // set up our tx event data and determine if player is new or not
        //Coindatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        // determine if player is new or not
        determinePID();
        
        uint256 _affID;
         
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender]; 
        
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            // use last stored affiliate code
            _affID = plyr_[_pID].laff;
        
        // if affiliate code was given    
        } else {
            // get affiliate ID from aff Code 
            _affID = pIDxAddr_[_affCode];
            
            // if affID is not the same as previously stored 
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }
        buyTicket(_pID, _affID, _tickets);
    }
    
    function buyXname(uint _tickets, bytes32 _affCode)
          isHuman()
          isWithinLimits(msg.value, _tickets)
          isTicketsLimits(_tickets)
          isActivated
          public 
          payable
    {
        // set up our tx event data and determine if player is new or not
        //Coindatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        determinePID();
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name)
        {
            // use last stored affiliate code
            _affID = plyr_[_pID].laff;
        
        // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];
            
            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }
        buyTicket(_pID, _affID, _tickets);
    }
    
    function reLoadXaddr(uint256 _tickets, address _affCode)
        isHuman()
        isActivated
        isTicketsLimits(_tickets)
        public
    {
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == address(0) || _affCode == msg.sender){
            _affID = plyr_[_pID].laff;
        }
        else{
           // get affiliate ID from aff Code 
            _affID = pIDxAddr_[_affCode];
            // if affID is not the same as previously stored 
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }
        reloadTickets(_pID, _affID, _tickets);
    }
    
        
    function reLoadXname(uint256 _tickets, bytes32 _affCode)
        isHuman()
        isActivated
        isTicketsLimits(_tickets)
        public
    {
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name){
            _affID = plyr_[_pID].laff;
        }
        else{
           // get affiliate ID from aff Code 
             _affID = pIDxName_[_affCode];
            // if affID is not the same as previously stored 
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }
        reloadTickets(_pID, _affID, _tickets);
    }
    
    function reloadTickets(uint256 _pID, uint256 _affID, uint256 _tickets)
        isActivated
        private
    {
        //************** ******************
        // setup local rID
        uint256 _rID = rID_;
        // grab time
        uint256 _now = now;
        // if round is active
        if (_now > round_[_rID].start && _now < round_[_rID].end && round_[_rID].ended == false){
            // call ticket
            uint256 _eth = getBuyPrice().mul(_tickets);
            
            //plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            reloadEarnings(_pID, _eth);
            
            ticket(_pID, _rID, _tickets, _affID, _eth);
            if (round_[_rID].tickets == ticketstotal_){
                round_[_rID].ended = true;
                round_[_rID].end = now;
                endRound();
            }
            
        }else if (_now > round_[_rID].end && round_[_rID].ended == false){
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            endRound();
        }
    }
    
    function withdraw() 
        isHuman()
        public
    {
        // setup local rID 
        //uint256 _rID = rID_;
        // grab time
        uint256 _now = now;
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];
        // setup temp var for player eth
        uint256 _eth;
        // check to see if round has ended and no one has run round end yet
        
        _eth = withdrawEarnings(_pID);
        if (_eth > 0){
            plyr_[_pID].addr.transfer(_eth);
            emit Coinevents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }

    function reloadEarnings(uint256 _pID, uint256 _eth)
        private
        returns(uint256)
    {
        // update gen vault
        updateTicketVault(_pID, plyr_[_pID].lrnd);
        
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        require(_earnings >= _eth, "earnings too lower");

        if (plyr_[_pID].gen >= _eth) {
            plyr_[_pID].gen = plyr_[_pID].gen.sub(_eth);
            return;
        }else{
            _eth = _eth.sub(plyr_[_pID].gen);
            plyr_[_pID].gen = 0;
        }
        
        if (plyr_[_pID].aff >= _eth){
            plyr_[_pID].aff = plyr_[_pID].aff.sub(_eth);
            return;
        }else{
            _eth = _eth.sub(plyr_[_pID].aff);
            plyr_[_pID].aff = 0;
        }
        
        plyr_[_pID].win = plyr_[_pID].win.sub(_eth);

    }
    
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        // update gen vault
        updateTicketVault(_pID, plyr_[_pID].lrnd);
        
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;  // winner
            plyr_[_pID].gen = 0;  //ticket valuet
            plyr_[_pID].aff = 0;  // aff player
        }

        return(_earnings);
    }
    // aquire buy ticket price
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {
        return round_[rID_].jackpot.mul(150) / 100 / 1500;
    }
    
    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not
    */
    function buyTicket( uint256 _pID, uint256 _affID, uint256 _tickets) 
         private
    {
        //************** ******************
        // setup local rID
        uint256 _rID = rID_;
        // grab time
        uint256 _now = now;
        
        // if round is active
        if (_now > round_[_rID].start && _now < round_[_rID].end){
            // call ticket
            ticket(_pID, _rID, _tickets, _affID, msg.value);
            if (round_[_rID].tickets == ticketstotal_){
                round_[_rID].ended = true;
                round_[_rID].end = now;
                endRound();
            }
        }else if (_now > round_[_rID].end && round_[_rID].ended == false){
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            //_eventData_ = endRound(_eventData_);
            endRound();
            // put eth in players vault
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
        //ticket(_pID, _rID, _tickets, _affID, msg.value);
    }
    
    function ticket(uint256 _pID, uint256 _rID, uint256 _tickets, uint256 _affID, uint256 _eth)
        private
    {
         // if player is new to round
        if (plyrRnds_[_pID][_rID].tickets == 0){
            managePlayer(_pID);
            round_[rID_].playernums += 1;
            plyrRnds_[_affID][_rID].affnums += 1;
        }

        // ********** buy ticket *************
        uint tickets = round_[rID_].tickets;
        uint groups = (tickets + _tickets  - 1) / grouptotal_ - tickets / grouptotal_;
        uint offset = tickets / grouptotal_;
       
        if (groups == 0){
            if (((tickets + _tickets) % grouptotal_) == 0){
                orders[rID_][_pID][offset] = calulateXticket(orders[rID_][_pID][offset], grouptotal_, tickets % grouptotal_);
            }else{
                orders[rID_][_pID][offset] = calulateXticket(orders[rID_][_pID][offset], (tickets + _tickets) % grouptotal_, tickets % grouptotal_);
            }
        }else{
            for(uint256 i = 0; i < groups + 1; i++){
                if (i == 0){
                     orders[rID_][_pID][offset+i] = calulateXticket(orders[rID_][_pID][offset + i], grouptotal_, tickets % grouptotal_);
                }
                if (i > 0 && i < groups){
                    orders[rID_][_pID][offset + i] = calulateXticket(orders[rID_][_pID][offset + i], grouptotal_, 0);
                }
                if (i == groups){
                    if (((tickets + _tickets) % grouptotal_) == 0){
                        orders[rID_][_pID][offset + i] = calulateXticket(orders[rID_][_pID][offset + i], grouptotal_, 0);
                    }else{
                        orders[rID_][_pID][offset + i] = calulateXticket(orders[rID_][_pID][offset + i], (tickets + _tickets) % grouptotal_, 0);
                    }
                }
            }
        }
        
        if (round_[rID_].tickets < _headtickets){
            if (_tickets.add(round_[rID_].tickets) <= _headtickets){
                plyrRnds_[_pID][_rID].luckytickets = _tickets.add(plyrRnds_[_pID][_rID].luckytickets);
            }
            else{
                plyrRnds_[_pID][_rID].luckytickets = (_headtickets - round_[rID_].tickets).add(plyrRnds_[_pID][_rID].luckytickets); 
            }
        }
        // set up purchase tickets
        round_[rID_].tickets = _tickets.add(round_[rID_].tickets);
        plyrRnds_[_pID][_rID].tickets = _tickets.add(plyrRnds_[_pID][_rID].tickets);
        plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
        round_[rID_].blocknum = block.number;
       
        // distributes valuet
        distributeVault(_pID, rID_, _affID, _eth, _tickets);
        // order event log
        //emit onBuy(msg.sender, tickets+1, tickets +_tickets,_rID, _eth, plyr_[_pID].name);
        emit Coinevents.onBuy(msg.sender, tickets+1, tickets +_tickets,_rID, plyr_[_pID].name);
    }

    function distributeVault(uint256 _pID, uint256 _rID, uint256 _affID, uint256 _eth, uint256 _tickets)
        private
    {    
         // distributes gen
         uint256 _gen = 0;
         uint256 _genvault = 0;
         uint256 ticketprice_ = getBuyPrice();
         if (round_[_rID].tickets > _headtickets){
             if (round_[_rID].tickets.sub(_tickets) > _headtickets){
                 _gen = _tickets;
                 //plyrRnds_[_pID][_rID].luckytickets = 
             }else{
                 _gen = round_[_rID].tickets.sub(_headtickets);
             }
         }
         
         if (_gen > 0){
             //_genvault = (((_gen / _tickets).mul(_eth)).mul(20)) / 100;   // 20 % to gen tickets
             _genvault = ((ticketprice_ * _gen).mul(20)) / 100;
             round_[_rID].mask = _genvault.add(round_[_rID].mask);   // update mask
         }
         
         uint256 _aff = _eth / 10;  //to================10%(aff)
         uint256 _com = _eth / 20;  //to================5%(community)
         uint256 _found = _eth.mul(32) / 100;
         round_[_rID].found = _found.add(round_[_rID].found);  //to============prize found
         if (_affID != 0){
             plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
             community_addr.transfer(_com);
         }else{
             _com = _com.add(_aff);
             community_addr.transfer(_com);
         }
         // ============to perhaps next round pool
         uint256 _nextpot = _eth.sub(_genvault);
         if (_affID != 0){
             _nextpot = _nextpot.sub(_aff);
         }
         _nextpot = _nextpot.sub(_com);
         _nextpot = _nextpot.sub(_found);
         round_[_rID].nextpot = _nextpot.add(round_[_rID].nextpot);  // next round pool
    }
    
    
    function calulateXticket(uint256 _target, uint256 _start, uint256 _end) pure private returns(uint256){
        return _target ^ (2 ** _start - 2 ** _end); 
    }
    
    function endRound() 
        private
    {
        // setup local rID
        uint256 _rID = rID_;
        uint256 prize_callback = 0;
        round_[_rID].lucknum = randNums();
        
        // 1. if win
        if (round_[_rID].tickets >= round_[_rID].lucknum){
           // community_addr.transfer(round_[_rID].income.sub(_com).sub(_gen));
            // need administrators take in 10 ETH activate next round
            prize_callback = round_[_rID].found.add(round_[_rID].nextpot);
            if (prize_callback > 0) {
                prize_addr.transfer(prize_callback);
                activated_ = false;   // need administrators to activate
                emit onSettle(_rID, round_[_rID].tickets, address(0), round_[_rID].lucknum, round_[_rID].jackpot);
            }
        }else{ 
            // 2. if nobody win
            // directly start next round
            prize_callback = round_[_rID].found;
            if (prize_callback > 0) {
                prize_addr.transfer(prize_callback);
            }
            rID_ ++;
            _rID ++;
            round_[_rID].start = now;
            round_[_rID].end = now.add(rndGap_);
            round_[_rID].jackpot = round_[_rID-1].jackpot.add(round_[_rID-1].nextpot);
            emit onSettle(_rID-1, round_[_rID-1].tickets, address(0), round_[_rID-1].lucknum, round_[_rID-1].jackpot);
        }

    }
 
     /**
     * @dev moves any unmasked earnings to ticket vault.  updates earnings
     */   
     // _pID: player pid _rIDlast: last roundid
    function updateTicketVault(uint256 _pID, uint256 _rIDlast) private{
        
         uint256 _gen = (plyrRnds_[_pID][_rIDlast].luckytickets.mul(round_[_rIDlast].mask / _headtickets)).sub(plyrRnds_[_pID][_rIDlast].mask);
         
         uint256 _jackpot = 0;
         if (judgeWin(_rIDlast, _pID) && address(round_[_rIDlast].winner) == 0) {
             _jackpot = round_[_rIDlast].jackpot;
             round_[_rIDlast].winner = msg.sender;
         }
         plyr_[_pID].gen = _gen.add(plyr_[_pID].gen);     // ticket valuet
         plyr_[_pID].win = _jackpot.add(plyr_[_pID].win); // player win
         plyrRnds_[_pID][_rIDlast].mask = plyrRnds_[_pID][_rIDlast].mask.add(_gen);
    }
    
    
    function managePlayer(uint256 _pID)
        private
    {
        // if player has played a previous round, move their unmasked earnings
        // from that round to gen vault.
        if (plyr_[_pID].lrnd != 0)
            updateTicketVault(_pID, plyr_[_pID].lrnd);
            
        // update player&#39;s last round played
        plyr_[_pID].lrnd = rID_;

    }
    //==============================================================================
    //     _ _ | _   | _ _|_ _  _ _  .
    //    (_(_||(_|_||(_| | (_)| _\  .
    //==============================================================================
    /**
     * @dev calculates unmasked earnings (just calculates, does not update ticket)
     * @return earnings in wei format
     */
     //计算每轮中pid前500ticket的分红
    function calcTicketEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {   // per round ticket valuet
        return (plyrRnds_[_pID][_rIDlast].luckytickets.mul(round_[_rIDlast].mask / _headtickets)).sub(plyrRnds_[_pID][_rIDlast].mask);
    }
    
    //====================/=========================================================
    /** upon contract deploy, it will be deactivated.  this is a one time
     * use function that will activate the contract.  we do this so devs 
     * have time to set things up on the web end                            **/
    
    function activate()
        isHuman()
        public
        payable
    {
        // can only be ran once
        require(msg.sender == activate_addr1 ||
            msg.sender == activate_addr2);
        
        require(activated_ == false, "LuckyCoin already activated");
        //uint256 _jackpot = 10 ether;
        require(msg.value == jackpot, "activate game need 10 ether");
        
        if (rID_ != 0) {
            require(round_[rID_].tickets >= round_[rID_].lucknum, "nobody win");
        }
        //activate the contract 
        activated_ = true;
        //lets start first round
        rID_ ++;
        round_[rID_].start = now;
        round_[rID_].end = now + rndGap_;
        round_[rID_].jackpot = msg.value;
        emit onActivate(rID_);
    }
    
    /**
	 * @dev receives name/player info from names contract 
     */
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff)
        external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if (pIDxAddr_[_addr] != _pID)
            pIDxAddr_[_addr] = _pID;
        if (pIDxName_[_name] != _pID)
            pIDxName_[_name] = _pID;
        if (plyr_[_pID].addr != _addr)
            plyr_[_pID].addr = _addr;
        if (plyr_[_pID].name != _name)
            plyr_[_pID].name = _name;
        if (plyr_[_pID].laff != _laff)
            plyr_[_pID].laff = _laff;
        if (plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }
    
//==============================PLAYER==========================================    
    /**
     * @dev receives entire player name list 
     */
    function receivePlayerNameList(uint256 _pID, bytes32 _name)
        external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }
    
    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID 
     */        
    function determinePID()
        private
        //returns (Coindatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        // if player is new to this version of luckycoin
        if (_pID == 0)
        {
            // grab their player ID, name and last aff ID, from player names contract 
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);
            
            // set up player account 
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;
            
            if (_name != "")
            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }
            
            if (_laff != 0 && _laff != _pID)
                plyr_[_pID].laff = _laff;
            
            // set the new player bool to true
            //_eventData_.compressedData = _eventData_.compressedData + 1;
        } 
        //return (_eventData_);
    }
    
    // only support Name by name
    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        
        // fire event
        emit Coinevents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
    
    function registerNameXaddr(string _nameString, address _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        // fire event
        emit Coinevents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
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
        
        if (_now < round_[_rID].end){
            return( (round_[_rID].end).sub(_now) );
        }
        else
            return(0);
    }
    
    function getCurrentRoundInfo() 
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bool)
    {
        // setup local rID
        uint256 _rID = rID_;
        return 
        (
            rID_,
            round_[_rID].tickets,
            round_[_rID].start,
            round_[_rID].end,
            round_[_rID].jackpot,
            round_[_rID].nextpot,
            round_[_rID].lucknum,
            round_[_rID].mask,
            round_[_rID].playernums,
            round_[_rID].winner,
            round_[_rID].ended
        );
    }
    
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        uint256 _lrnd =  plyr_[_pID].lrnd;
        uint256 _jackpot = 0;
        if (judgeWin(_lrnd, _pID) && address(round_[_lrnd].winner) == 0){
            _jackpot = round_[_lrnd].jackpot;
        }
        
        return
        (
            _pID,                               //0
            plyr_[_pID].name,                   //1
            plyrRnds_[_pID][_rID].tickets,      //2
            plyr_[_pID].win.add(_jackpot),                    //3
            plyr_[_pID].gen.add(calcTicketEarnings(_pID, _lrnd)),  //4
            plyr_[_pID].aff,                    //5
            plyrRnds_[_pID][_rID].eth,           //6
            plyrRnds_[_pID][_rID].affnums        // 7
        );
    }

    // generate a number between 1-1500 
    function randNums() public view returns(uint256) {
        return uint256(keccak256(block.difficulty, now, block.coinbase)) % ticketstotal_ + 1;
    }
    
    // search user if win
    function judgeWin(uint256 _rid, uint256 _pID)private view returns(bool){
        uint256 _group = (round_[_rid].lucknum -1) / grouptotal_;
        uint256 _temp = round_[_rid].lucknum % grouptotal_;
        if (_temp == 0){
            _temp = grouptotal_;
        }

        if (orders[_rid][_pID][_group] & (2 **(_temp-1)) == 2 **(_temp-1)){
            return true;
        }else{
            return false;
        }
    }

    // search the tickets owns
    function searchtickets()public view returns(uint256, uint256, uint256, uint256,uint256, uint256){
         uint256 _pID = pIDxAddr_[msg.sender];
         return (
             orders[rID_][_pID][0],
             orders[rID_][_pID][1],
             orders[rID_][_pID][2],
             orders[rID_][_pID][3],
             orders[rID_][_pID][4],
             orders[rID_][_pID][5]
            );
     }
     // search the tickets by address
    function searchTicketsXaddr(address addr) public view returns(uint256, uint256, uint256, uint256,uint256, uint256){
        uint256 _pID = pIDxAddr_[addr];
        return (
             orders[rID_][_pID][0],
             orders[rID_][_pID][1],
             orders[rID_][_pID][2],
             orders[rID_][_pID][3],
             orders[rID_][_pID][4],
             orders[rID_][_pID][5]
            );
     }
}


library Coindatasets {
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
        bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot
    }
    
     struct Round {
        uint256 tickets; // already purchase ticket
        bool ended;     // has round end function been ran
        uint256 jackpot;    // eth to pot, perhaps next round pot
        uint256 start;   // time round started
        uint256 end;    // time ends/ended
        address winner;  //win address
        uint256 mask;   // global mask
        uint256 found; // jackpot found
        uint256 lucknum;  // win num
        uint256 nextpot;  // next pot
        uint256 blocknum; // current blocknum
        uint256 playernums; // playernums
      }
      
    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 aff;    // affiliate vault
        uint256 lrnd;   // last round played
        uint256 laff;   // last affiliate id used
        uint256 luckytickets;  // head 500 will acquire distributes vault
    }
    
    struct PotSplit {
        uint256 community;    // % of pot thats paid to key holders of current round
        uint256 gen;    // % of pot thats paid to tickets holders
        uint256 laff;   // last affiliate id used
    }
    
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round
        uint256 tickets;   // tickets
        uint256 mask;  // player mask,
        uint256 affnums;
        uint256 luckytickets; // player luckytickets
    }
}


interface PlayerBookInterface {
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerName(uint256 _pID) external view returns (bytes32);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getNameFee() external view returns (uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
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
        require(c / a == b);
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
        require(b <= a);
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
        require(c >= a);
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