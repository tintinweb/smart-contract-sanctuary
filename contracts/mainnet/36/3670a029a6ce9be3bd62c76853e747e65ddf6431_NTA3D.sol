pragma solidity ^0.4.25;

contract NTA3DEvents {

    event onNewName (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        uint256 timeStamp
    );

    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

    event onBuyKey
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        uint256 roundID,
        uint256 ethIn,
        uint256 keys,
        uint256 timeStamp
    );

    event onBuyCard
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        uint256 cardID,
        uint256 ethIn,
        uint256 timeStamp
    );

    event onRoundEnd
    (
        address winnerAddr,
        bytes32 winnerName,
        uint256 roundID,
        uint256 amountWon,
        uint256 newPot,
        uint256 timeStamp
    );

    event onDrop
    (
        address dropwinner,
        bytes32 winnerName,
        uint256 roundID,
        uint256 droptype, //0:smalldrop 1:bigdop
        uint256 win,
        uint256 timeStamp
    );

}

contract NTA3D is NTA3DEvents {
    using SafeMath for *;
    using NameFilter for string;
    using NTA3DKeysCalc for uint256;

    string constant public name = "No Tricks Allow 3D";
    string constant public symbol = "NTA3D";
    bool activated_;
    address admin;
    uint256 constant private rndStarts = 12 hours; // ??need to be continue
    uint256 constant private rndPerKey = 15 seconds; // every key increase seconds
    uint256 constant private rndMax = 12 hours;  //max count down time;
    uint256 constant private cardValidity = 1 hours; //stock cards validity
    uint256 constant private cardPrice = 0.05 ether; //stock cards validity
    uint256 constant private DIVIDE = 1000; // common divide tool

    uint256 constant private smallDropTrigger = 100 ether;
    uint256 constant private bigDropTrigger = 300000 * 1e18;
    uint256 constant private keyPriceTrigger = 50000 * 1e18;
    uint256 constant private keyPriceFirst = 0.0005 ether;
    uint256 constant private oneOffInvest1 = 0.1 ether;//VIP 1
    uint256 constant private oneOffInvest2 = 1 ether;// VIP 2

    //uint256 public airDropTracker_ = 0;
    uint256 public rID;    // round id number / total rounds that have happened
    uint256 public pID;    // total players

    //player map data
    mapping (address => uint256) public pIDxAddr; // get pid by address
    mapping (bytes32 => uint256) public pIDxName; // get name by pid
    mapping (uint256 => NTAdatasets.Player) public pIDPlayer; // get player struct by pid\
    mapping (uint256 => mapping (uint256 => NTAdatasets.PlayerRound)) public pIDPlayerRound; // pid => rid => playeround

    //stock cards
    mapping (uint256 => NTAdatasets.Card) cIDCard; //get card by cID
    address cardSeller;

    //team map data
    //address gameFundsAddr = 0xFD7A82437F7134a34654D7Cb8F79985Df72D7076;
    address[11] partner;
    address to06;
    address to04;
    address to20A;
    address to20B;
    mapping (address => uint256) private gameFunds; // game develeopment get 5% funds
    //uint256 private teamFee;    // team Fee 5%

    //round data
    mapping (uint256 => NTAdatasets.Round) public rIDRound;   // round data

    // team dividens
    mapping (uint256 => NTAdatasets.Deposit) public deposit;
    mapping (uint256 => NTAdatasets.PotSplit) public potSplit;

    constructor() public {

        //constructor
        activated_ = false;
        admin = msg.sender;
        // Team allocation structures
        // 0 = BISHOP
        // 1 = ROOK

        // BISHOP team: ==> |46% to all, 17% to winnerPot, 5% to develop funds, 5% to teamfee, 10% to cards,
        //                  |7% to fisrt degree invatation
        //                  |3% to second degree invatation, 2% to big airdrop, 5% to small airdrop
        deposit[0] = NTAdatasets.Deposit(460, 170, 50, 50, 100, 100, 20, 50);
        // ROOK team:   ==> |20% to all, 43% to winnerPot, 5% to develop funds, 5% to teamfee, 10% to cards,
        //                  |7% to fisrt degree invatation
        //                  |3% to second degree invatation, 2% to big airdrop, 5% to small airdrop
        deposit[1] = NTAdatasets.Deposit(200, 430, 50, 50, 100, 100, 20, 50);

        // potSplit:    ==> |20% to all, 45% to lastwinner, 5% to inviter 1st, 3% to inviter 2nd, 2% to inviter 3rd,
        //                  |8% to key buyer 1st, 5% to key buyer 2nd, 2% to key buyer 3rd, 10% to next round
        potSplit[0] = NTAdatasets.PotSplit(200, 450, 50, 30, 20, 80, 50, 20, 100);
        potSplit[1] = NTAdatasets.PotSplit(200, 450, 50, 30, 20, 80, 50, 20, 100);
        //partner list 
        //iniailize in active function
        //develeopment
        to06 = 0x9B53CC857cD9DD5EbE6bc07Bde67D8CE4076345f;
        to04 = 0x5835a72118c0C784203B8d39936A0875497B6eCa;
        to20A = 0xEc2441D3113fC2376cd127344331c0F1b959Ce1C;
        to20B = 0xd1Dac908c97c0a885e9B413a84ACcC0010C002d2;
        
        //card
        cardSeller = 0xeE4f032bdB0f9B51D6c7035d3DEFfc217D91225C;
    }

//==============================================================================
//
//    safety checks
//==============================================================================
    //tested
    modifier isActivated() {
        require(activated_ == true, "its not ready yet");
        _;
    }

    /**
     * @dev prevents contracts from interacting with fomo3d
     */
    //tested
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    //tested
    modifier isAdmin() {require(msg.sender == admin, "its can only be call by admin");_;}

    /**
     * @dev sets boundaries for incoming tx
     */
    //tested
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

//==============================================================================
//
//    admin functions
//==============================================================================
    //tested
    function active() isAdmin() public {
        activated_ = true;
        partner[0] = 0xE27Aa5E7D8906779586CfB9DbA2935BDdd7c8210;
        partner[1] = 0xD4638827Dc486cb59B5E5e47955059A160BaAE13;
        partner[2] = 0xa088c667591e04cC78D6dfA3A392A132dc5A7f9d;
        partner[3] = 0xed38deE26c751ff575d68D9Bf93C312e763f8F87;
        partner[4] = 0x42A7B62f71b7778279DA2639ceb5DD6ee884f905;
        partner[5] = 0xd471409F3eFE9Ca24b63855005B08D4548742a5b;
        partner[6] = 0x41c9F005eD19C2B620152f5562D26029b32078B6;
        partner[7] = 0x11b85bc860A6C38fa7fe6f54f18d350eF5f2787b;
        partner[8] = 0x11a7c5E7887F2C34356925275882D4321a6B69A8;
        partner[9] = 0xB5754c7bD005b6F25e1FDAA5f94b2b71e6eA260f;
        partner[10] = 0x6fbC15cF6d0B05280E99f753E45B631815715E99;
    }
    //tested
    function startFirstRound() isAdmin() isActivated() public {
        //must not open before
        require(rID == 0);
        newRound(0);
    }

    function teamWithdraw() public
    isHuman()
    isActivated()
    {
        uint256 _temp;
        address to = msg.sender;
        require(gameFunds[to] != 0, "you dont have funds");
        _temp = gameFunds[to];
        gameFunds[to] = 0;
        to.transfer(_temp);
    }

    function getTeamFee(address _addr)
    public
    view
    returns(uint256) {
        return gameFunds[_addr];
    }

    function getScore(address _addr)
    public
    view
    isAdmin()
    returns(uint256) {
        uint256 _pID = pIDxAddr[_addr];
        if(_pID == 0 ) return 0;
        else return pIDPlayerRound[_pID][rID].score;
    }

//==============================================================================
//
//    player functions
//==============================================================================

    //emergency buy uses BISHOP team to buy keys
    function()
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        //fetch player
        require(rID != 0, "No round existed yet");
        uint256 _pID = managePID(0);
        //buy key
        buyCore(_pID, 0);
    }

    // buy with ID: inviter use pID to invate player to buy like "www.NTA3D.io/?id=101"
    function buyXid(uint256 _team,uint256 _inviter)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        require(rID != 0, "No round existed yet");
        uint256 _pID = managePID(_inviter);
        if (_team < 0 || _team > 1 ) {
            _team = 0;
        }
        buyCore(_pID, _team);
    }

    // buy with ID: inviter use pID to invate player to buy like "www.NTA3D.io/?n=obama"
    function buyXname(uint256 _team,string _invName)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        require(rID != 0, "No round existed yet");
        bytes32 _name = _invName.nameFilter();
        uint256 _invPID = pIDxName[_name];
        uint256 _pID = managePID(_invPID);
        if (_team < 0 || _team > 1 ) {
            _team = 0;
        }
        buyCore(_pID, _team);
    }

    function buyCardXname(uint256 _cID, string _invName)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable {
        uint256 _value = msg.value;
        uint256 _now = now;
        require(_cID < 20, "only has 20 cards");
        require(_value == cardPrice, "the card cost 0.05 ether");
        require(cIDCard[_cID].owner == 0 || (cIDCard[_cID].buyTime + cardValidity) < _now, "card is in used");
        bytes32 _name = _invName.nameFilter();
        uint256 _invPID = pIDxName[_name];
        uint256 _pID = managePID(_invPID);
        for (uint i = 0; i < 20; i++) {
            require(_pID != cIDCard[i].owner, "you already registed a card");
        }
        gameFunds[cardSeller] = gameFunds[cardSeller].add(_value);
        cIDCard[_cID].addr = msg.sender;
        cIDCard[_cID].owner = _pID;
        cIDCard[_cID].buyTime = _now;
        cIDCard[_cID].earnings = 0;
        emit onBuyCard(_pID, pIDPlayer[_pID].addr, pIDPlayer[_pID].name, _cID, _value, now);
    }

    function buyCardXid(uint256 _cID, uint256 _inviter)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable {
        uint256 _value = msg.value;
        uint256 _now = now;
        require(_cID < 20, "only has 20 cards");
        require(_value == cardPrice, "the card cost 0.05 ether");
        require(cIDCard[_cID].owner == 0 || (cIDCard[_cID].buyTime + cardValidity) < _now, "card is in used");
        uint256 _pID = managePID(_inviter);
        for (uint i = 0; i < 20; i++) {
            require(_pID != cIDCard[i].owner, "you already registed a card");
        }
        gameFunds[cardSeller] = gameFunds[cardSeller].add(_value);
        cIDCard[_cID].addr = msg.sender;
        cIDCard[_cID].owner = _pID;
        cIDCard[_cID].buyTime = _now;
        cIDCard[_cID].earnings = 0;
        emit onBuyCard(_pID, pIDPlayer[_pID].addr, pIDPlayer[_pID].name, _cID, _value, now);
    }


    // regist a name
    function registNameXid(string _nameString, uint256 _inviter)
    isActivated()
    isHuman()
    public {
        bytes32 _name = _nameString.nameFilter();
        uint256 temp = pIDxName[_name];
        require(temp == 0, "name already regist");
        uint256 _pID = managePID(_inviter);
        pIDxName[_name] = _pID;
        pIDPlayer[_pID].name = _name;
        //emit
        emit onNewName(_pID, pIDPlayer[_pID].addr, pIDPlayer[_pID].name, now);
    }

    function registNameXname(string _nameString, string _inviterName)
    isActivated()
    isHuman()
    public {
        bytes32 _name = _nameString.nameFilter();
        uint256 temp = pIDxName[_name];
        require(temp == 0, "name already regist");
        bytes32 _invName = _inviterName.nameFilter();
        uint256 _invPID = pIDxName[_invName];
        uint256 _pID = managePID(_invPID);
        pIDxName[_name] = _pID;
        pIDPlayer[_pID].name = _name;
        //emit
        emit onNewName(_pID, pIDPlayer[_pID].addr, pIDPlayer[_pID].name, now);
    }

    function withdraw()
    isActivated()
    isHuman()
    public {
        // setup local rID
        uint256 _rID = rID;
        // grab time
        uint256 _now = now;
        uint256 _pID = pIDxAddr[msg.sender];
        require(_pID != 0, "cant find user");
        uint256 _eth = 0;
        if (rIDRound[_rID].end < _now && rIDRound[_rID].ended == false) {
            rIDRound[_rID].ended = true;
            endRound();
        }
        // get their earnings
        _eth = withdrawEarnings(_pID);
        // gib moni
        if (_eth > 0)
            pIDPlayer[_pID].addr.transfer(_eth);
        //emit
        emit onWithdraw(_pID, pIDPlayer[_pID].addr, pIDPlayer[_pID].name, _eth, now);
    }
//==============================================================================
//
//    view functions
//==============================================================================
    /**
     * return the price buyer will pay for next 1 individual key.
     * @return price for next key bought (in wei format)
     */
     //tested
    function getBuyPrice(uint256 _key)
    public
    view
    returns(uint256) {
        // setup local rID
        uint256 _rID = rID;
        // grab time
        uint256 _now = now;
        uint256 _keys = rIDRound[_rID].team1Keys + rIDRound[_rID].team2Keys;
        // round is active
        if (rIDRound[_rID].end >= _now || (rIDRound[_rID].end < _now && rIDRound[_rID].leadPID == 0))
            return _keys.ethRec(_key * 1e18);
        else
            return keyPriceFirst;
    }

    /**
     * @dev returns time left.  dont spam this, you&#39;ll ddos yourself from your node
     * @return time left in seconds
     */
     //tested
    function getTimeLeft()
    public
    view
    returns(uint256) {
        // setup local rID
        uint256 _rID = rID;
        // grab time
        uint256 _now = now;

        if (rIDRound[_rID].end >= _now)
            return (rIDRound[_rID].end.sub(_now));
        else
            return 0;
    }

    //tested
    function getPlayerVaults()
    public
    view
    returns(uint256, uint256, uint256, uint256, uint256) {
        // setup local rID
        uint256 _rID = rID;
        uint256 _now = now;
        uint256 _pID = pIDxAddr[msg.sender];
        if (_pID == 0)
            return (0, 0, 0, 0, 0);
        uint256 _last = pIDPlayer[_pID].lrnd;
        uint256 _inv = pIDPlayerRound[_pID][_last].inv;
        uint256 _invMask = pIDPlayerRound[_pID][_last].invMask;
        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        if (rIDRound[_rID].end < _now && rIDRound[_rID].ended == false && rIDRound[_rID].leadPID != 0) {
            // if player is winner
            if (rIDRound[_rID].leadPID == _pID)
                return (
                    (pIDPlayer[_pID].win).add((rIDRound[_rID].pot).mul(45) / 100),
                    pIDPlayer[_pID].gen.add(calcUnMaskedEarnings(_pID, pIDPlayer[_pID].lrnd)),
                    pIDPlayer[_pID].inv.add(_inv).sub0(_invMask),
                    pIDPlayer[_pID].tim.add(calcTeamEarnings(_pID, pIDPlayer[_pID].lrnd)),
                    pIDPlayer[_pID].crd
                );
            else
                return (
                    pIDPlayer[_pID].win,
                    pIDPlayer[_pID].gen.add(calcUnMaskedEarnings(_pID, pIDPlayer[_pID].lrnd)),
                    pIDPlayer[_pID].inv.add(_inv).sub0(_invMask),
                    pIDPlayer[_pID].tim.add(calcTeamEarnings(_pID, pIDPlayer[_pID].lrnd)),
                    pIDPlayer[_pID].crd
                );
        } else {
             return (
                    pIDPlayer[_pID].win,
                    pIDPlayer[_pID].gen.add(calcUnMaskedEarnings(_pID, pIDPlayer[_pID].lrnd)),
                    pIDPlayer[_pID].inv.add(_inv).sub0(_invMask),
                    pIDPlayer[_pID].tim.add(calcTeamEarnings(_pID, pIDPlayer[_pID].lrnd)),
                    pIDPlayer[_pID].crd
                );
        }
    }

    function getCurrentRoundInfo()
    public
    view
    returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256) {
        // setup local rID
        uint256 _rID = rID;
        return(_rID,
            rIDRound[_rID].team1Keys + rIDRound[_rID].team2Keys,    //total key
            rIDRound[_rID].eth,      //total eth
            rIDRound[_rID].strt,     //start time
            rIDRound[_rID].end,      //end time
            rIDRound[_rID].pot,      //last winer pot
            rIDRound[_rID].leadPID,  //current last player
            pIDPlayer[rIDRound[_rID].leadPID].addr, //cureest last player address
            pIDPlayer[rIDRound[_rID].leadPID].name, //cureest last player name
            rIDRound[_rID].smallDrop,
            rIDRound[_rID].bigDrop,
            rIDRound[_rID].teamPot   //teampot
            );
    }

    function getRankList()
    public
    view
            //invitetop3   amout      keyTop3      key
    returns (address[3], uint256[3], bytes32[3], address[3], uint256[3], bytes32[3]) {
        uint256 _rID = rID;
        address[3] memory inv;
        address[3] memory key;
        bytes32[3] memory invname;
        uint256[3] memory invRef;
        uint256[3] memory keyamt;
        bytes32[3] memory keyname;
        inv[0] = pIDPlayer[rIDRound[_rID].invTop3[0]].addr;
        inv[1] = pIDPlayer[rIDRound[_rID].invTop3[1]].addr;
        inv[2] = pIDPlayer[rIDRound[_rID].invTop3[2]].addr;
        invRef[0] = pIDPlayerRound[rIDRound[_rID].invTop3[0]][_rID].inv;
        invRef[1] = pIDPlayerRound[rIDRound[_rID].invTop3[1]][_rID].inv;
        invRef[2] = pIDPlayerRound[rIDRound[_rID].invTop3[2]][_rID].inv;
        invname[0] = pIDPlayer[rIDRound[_rID].invTop3[0]].name;
        invname[1] = pIDPlayer[rIDRound[_rID].invTop3[1]].name;
        invname[2] = pIDPlayer[rIDRound[_rID].invTop3[2]].name;

        key[0] = pIDPlayer[rIDRound[_rID].keyTop3[0]].addr;
        key[1] = pIDPlayer[rIDRound[_rID].keyTop3[1]].addr;
        key[2] = pIDPlayer[rIDRound[_rID].keyTop3[2]].addr;
        keyamt[0] = pIDPlayerRound[rIDRound[_rID].keyTop3[0]][_rID].team1Keys + pIDPlayerRound[rIDRound[_rID].keyTop3[0]][_rID].team2Keys;
        keyamt[1] = pIDPlayerRound[rIDRound[_rID].keyTop3[1]][_rID].team1Keys + pIDPlayerRound[rIDRound[_rID].keyTop3[1]][_rID].team2Keys;
        keyamt[2] = pIDPlayerRound[rIDRound[_rID].keyTop3[2]][_rID].team1Keys + pIDPlayerRound[rIDRound[_rID].keyTop3[2]][_rID].team2Keys;
        keyname[0] = pIDPlayer[rIDRound[_rID].keyTop3[0]].name;
        keyname[1] = pIDPlayer[rIDRound[_rID].keyTop3[1]].name;
        keyname[2] = pIDPlayer[rIDRound[_rID].keyTop3[2]].name;

        return (inv, invRef, invname, key, keyamt, keyname);
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will
     * use msg.sender
     * -functionhash- 0xee0b5d8b
     * @param _addr address of the player you want to lookup
     * @return player ID
     * @return player name
     * @return keys owned (current round)
     * @return winnings vault
     * @return general vault
     * @return affiliate vault
	 * @return player round eth
     */
    //tested
    function getPlayerInfoByAddress(address _addr)
        public
        view
        returns(uint256, bytes32, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID;

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr[_addr];
        if (_pID == 0)
            return (0, 0x0, 0, 0, 0);
        else
            return
            (
            _pID,                               //0
            pIDPlayer[_pID].name,                   //1
            pIDPlayerRound[_pID][_rID].team1Keys + pIDPlayerRound[_pID][_rID].team2Keys,
            pIDPlayerRound[_pID][_rID].eth,           //6
            pIDPlayer[_pID].vip
            );
    }

    function getCards(uint256 _id)
    public
    view
    returns(uint256, address, bytes32, uint256, uint256) {
        bytes32 _name = pIDPlayer[cIDCard[_id].owner].name;
        return (
            cIDCard[_id].owner,
            cIDCard[_id].addr,
            _name,
            cIDCard[_id].buyTime,
            cIDCard[_id].earnings
        );
    }
//==============================================================================
//
//    private functions
//==============================================================================

    //tested
    function managePID(uint256 _inviter) private returns(uint256) {
        uint256 _pID = pIDxAddr[msg.sender];
        if (_pID == 0) {
            pID++;
            pIDxAddr[msg.sender] = pID;
            pIDPlayer[pID].addr = msg.sender;
            pIDPlayer[pID].name = 0x0;
            _pID = pID;
        }
            // handle direct and second hand inviter
        if (pIDPlayer[_pID].inviter1 == 0 && pIDPlayer[_inviter].addr != address(0) && _pID != _inviter) {
            pIDPlayer[_pID].inviter1 = _inviter;
            uint256 _in = pIDPlayer[_inviter].inviter1;
            if (_in != 0) {
                    pIDPlayer[_pID].inviter2 = _in;
                }
            }
        // oneoff invite get invitation link
        if (msg.value >= oneOffInvest2) {
            pIDPlayer[_pID].vip = 2;
        } else if (msg.value >= oneOffInvest1) {
            if (pIDPlayer[_pID].vip != 2)
                pIDPlayer[_pID].vip = 1;
        }
        return _pID;
    }

    function buyCore(uint256 _pID, uint256 _team) private {
        // setup local rID
        uint256 _rID = rID;
        // grab time
        uint256 _now = now;

        //update last round;
        if (pIDPlayer[_pID].lrnd != _rID)
            updateVault(_pID);
        pIDPlayer[_pID].lrnd = _rID;
        uint256 _inv1 = pIDPlayer[_pID].inviter1;
        uint256 _inv2 = pIDPlayer[_pID].inviter2;

        // round is active
        if (rIDRound[_rID].end >= _now || (rIDRound[_rID].end < _now && rIDRound[_rID].leadPID == 0)) {
            core(_rID, _pID, msg.value, _team);
            if (_inv1 != 0)
                doRankInv(_rID, _inv1, rIDRound[_rID].invTop3, pIDPlayerRound[_inv1][_rID].inv);
            if (_inv2 != 0)
                doRankInv(_rID, _inv2, rIDRound[_rID].invTop3, pIDPlayerRound[_inv2][_rID].inv);
            doRankKey(_rID, _pID, rIDRound[_rID].keyTop3, pIDPlayerRound[_pID][_rID].team1Keys + pIDPlayerRound[_pID][_rID].team2Keys);
            emit onBuyKey(
                _pID,
                pIDPlayer[_pID].addr,
                pIDPlayer[_pID].name, _rID,
                msg.value,
                pIDPlayerRound[_pID][_rID].team1Keys + pIDPlayerRound[_pID][_rID].team2Keys,
                now);
        } else {
            if (rIDRound[_rID].end < _now && rIDRound[_rID].ended == false) {
                rIDRound[_rID].ended = true;
                endRound();
                //if you trigger the endround. whatever how much you pay ,you will fail to buykey
                //and the eth will return to your gen.
                pIDPlayer[_pID].gen = pIDPlayer[_pID].gen.add(msg.value);
            }
        }
    }

    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team) private {

        NTAdatasets.Round storage _roundID = rIDRound[_rID];
        NTAdatasets.Deposit storage _deposit = deposit[_team];
        //NTAdatasets.PlayerRound storage _playerRound = pIDPlayerRound[_pID][_rID];
        // calculate how many keys they can get
        uint256 _keysAll = _roundID.team1Keys + _roundID.team2Keys;//(rIDRound[_rID].eth).keysRec(_eth);
        uint256 _keys = _keysAll.keysRec(rIDRound[_rID].eth + _eth);
        if (_keys >= 1000000000000000000) {
            updateTimer(_keys, _rID);
        }

        uint256 _left = _eth;
        //2% to bigDrop
        uint256 _temp = _eth.mul(_deposit.bigDrop) / DIVIDE;
        doBigDrop(_rID, _pID, _keys, _temp);
        _left = _left.sub0(_temp);

        //5% to smallDrop
        _temp = _eth.mul(_deposit.smallDrop) / DIVIDE;
        doSmallDrop(_rID, _pID, _eth, _temp);
        _left = _left.sub0(_temp);

        _roundID.eth = _roundID.eth.add(_eth);
        pIDPlayerRound[_pID][_rID].eth = pIDPlayerRound[_pID][_rID].eth.add(_eth);
        if (_team == 0) {
            _roundID.team1Keys = _roundID.team1Keys.add(_keys);
            pIDPlayerRound[_pID][_rID].team1Keys = pIDPlayerRound[_pID][_rID].team1Keys.add(_keys);
        } else {
            _roundID.team2Keys = _roundID.team2Keys.add(_keys);
            pIDPlayerRound[_pID][_rID].team2Keys = pIDPlayerRound[_pID][_rID].team2Keys.add(_keys);
        }


        //X% to all
        uint256 _all = _eth.mul(_deposit.allPlayer) / DIVIDE;
        _roundID.playerPot = _roundID.playerPot.add(_all);
        uint256 _dust = updateMasks(_rID, _pID, _all, _keys);
        _roundID.pot = _roundID.pot.add(_dust);
        _left = _left.sub0(_all);

        //X% to winnerPot
        _temp = _eth.mul(_deposit.pot) / DIVIDE;
        _roundID.pot = _roundID.pot.add(_temp);
        _left = _left.sub0(_temp);

        //5% to develop funds
        _temp = _eth.mul(_deposit.devfunds) / DIVIDE;
        doDevelopFunds(_temp);
        //gameFunds[gameFundsAddr] = gameFunds[gameFundsAddr].add(_temp);
        _left = _left.sub0(_temp);

        //5% to team fee
        _temp = _eth.mul(_deposit.teamFee) / DIVIDE;
        //gameFunds[partner1] = gameFunds[partner1].add(_temp.mul(50) / DIVIDE);
        _dust = doPartnerShares(_temp);
        _left = _left.sub0(_temp).add(_dust);

        //10% to cards
        _temp = _eth.mul(_deposit.cards) / DIVIDE;
        _left = _left.sub0(_temp).add(distributeCards(_temp));
        // if no cards ,the money will add into left

        // 10% to invatation
        _temp = _eth.mul(_deposit.inviter) / DIVIDE;
        _dust = doInvite(_rID, _pID, _temp);
        _left = _left.sub0(_temp).add(_dust);

        //update round;
        if (_keys >= 1000000000000000000) {
            _roundID.leadPID = _pID;
            _roundID.team = _team;
        }


        _roundID.smallDrop = _roundID.smallDrop.add(_left);
    }

    //tested
    function doInvite(uint256 _rID, uint256 _pID, uint256 _value) private returns(uint256){
        uint256 _score = msg.value;
        uint256 _left = _value;
        uint256 _inviter1 = pIDPlayer[_pID].inviter1;
        uint256 _fee;
        uint256 _inviter2 = pIDPlayer[_pID].inviter2;
        if (_inviter1 != 0) 
            pIDPlayerRound[_inviter1][_rID].score = pIDPlayerRound[_inviter1][_rID].score.add(_score);
        if (_inviter2 != 0) 
            pIDPlayerRound[_inviter2][_rID].score = pIDPlayerRound[_inviter2][_rID].score.add(_score);
        //invitor
        if (_inviter1 == 0 || pIDPlayer[_inviter1].vip == 0)
            return _left;
        if (pIDPlayer[_inviter1].vip == 1) {
            _fee = _value.mul(70) / 100;
            _inviter2 = pIDPlayer[_pID].inviter2;
            _left = _left.sub0(_fee);
            pIDPlayerRound[_inviter1][_rID].inv = pIDPlayerRound[_inviter1][_rID].inv.add(_fee);
            if (_inviter2 == 0 || pIDPlayer[_inviter2].vip != 2)
                return _left;
            else {
                _fee = _value.mul(30) / 100;
                _left = _left.sub0(_fee);
                pIDPlayerRound[_inviter2][_rID].inv = pIDPlayerRound[_inviter2][_rID].inv.add(_fee);
                return _left;
            }
        } else if (pIDPlayer[_inviter1].vip == 2) {
            _left = _left.sub0(_value);
            pIDPlayerRound[_inviter1][_rID].inv = pIDPlayerRound[_inviter1][_rID].inv.add(_value);
            return _left;
        } else {
            return _left;
        }
    }

    function doRankInv(uint256 _rID, uint256 _pID, uint256[3] storage rank, uint256 _value) private {

        if (_value >= pIDPlayerRound[rank[0]][_rID].inv && _value != 0) {
            if (_pID != rank[0]) {
            uint256 temp = rank[0];
            rank[0] = _pID;
            if (rank[1] == _pID) {
                rank[1] = temp;
            } else {
                rank[2] = rank[1];
                rank[1] = temp;
            }
            }
        } else if (_value >= pIDPlayerRound[rank[1]][_rID].inv && _value != 0) {
            if (_pID != rank[1]) {
            rank[2] = rank[1];
            rank[1] = _pID;
            }
        } else if (_value >= pIDPlayerRound[rank[2]][_rID].inv && _value != 0) {
            rank[2] = _pID;
        }
    }

    function doRankKey(uint256 _rID, uint256 _pID, uint256[3] storage rank, uint256 _value) private {

        if (_value >= (pIDPlayerRound[rank[0]][_rID].team1Keys + pIDPlayerRound[rank[0]][_rID].team2Keys)) {
            if (_pID != rank[0]) {
            uint256 temp = rank[0];
            rank[0] = _pID;
            if (rank[1] == _pID) {
                rank[1] = temp;
            } else {
                rank[2] = rank[1];
                rank[1] = temp;
            }
            }
        } else if (_value >= (pIDPlayerRound[rank[1]][_rID].team1Keys + pIDPlayerRound[rank[1]][_rID].team2Keys)) {
            if (_pID != rank[1]){
            rank[2] = rank[1];
            rank[1] = _pID;
            }
        } else if (_value >= (pIDPlayerRound[rank[2]][_rID].team1Keys + pIDPlayerRound[rank[2]][_rID].team2Keys)) {
            rank[2] = _pID;
        }
    }

    //tested
    function doSmallDrop(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _small) private {
        // modulo current round eth, and add player eth to see if it can trigger the trigger;
        uint256 _remain = rIDRound[_rID].eth % smallDropTrigger;
        if ((_remain + _eth) >= smallDropTrigger) {
            uint256 _reward = rIDRound[_rID].smallDrop;
            rIDRound[_rID].smallDrop = 0;
            pIDPlayer[_pID].win = pIDPlayer[_pID].win.add(_reward);
            rIDRound[_rID].smallDrop = rIDRound[_rID].smallDrop.add(_small);
            emit NTA3DEvents.onDrop(pIDPlayer[_pID].addr, pIDPlayer[_pID].name, _rID, 0, _reward, now);
            //emit
        } else {
            rIDRound[_rID].smallDrop = rIDRound[_rID].smallDrop.add(_small);
        }
    }

    //tested
    function doBigDrop(uint256 _rID, uint256 _pID, uint256 _key, uint256 _big) private {
        uint256 _keys = rIDRound[_rID].team1Keys + rIDRound[_rID].team2Keys;
        uint256 _remain = _keys % bigDropTrigger;
        if ((_remain + _key) >= bigDropTrigger) {
            uint256 _reward = rIDRound[_rID].bigDrop;
            rIDRound[_rID].bigDrop = 0;
            pIDPlayer[_pID].win = pIDPlayer[_pID].win.add(_reward);
            rIDRound[_rID].bigDrop = rIDRound[_rID].bigDrop.add(_big);
            emit NTA3DEvents.onDrop(pIDPlayer[_pID].addr, pIDPlayer[_pID].name, _rID, 1, _reward, now);
            //emit
        } else {
            rIDRound[_rID].bigDrop = rIDRound[_rID].bigDrop.add(_big);
        }
    }

    function distributeCards(uint256 _eth) private returns(uint256){
        uint256 _each = _eth / 20;
        uint256 _remain = _eth;
        for (uint i = 0; i < 20; i++) {
            uint256 _pID = cIDCard[i].owner;
            if (_pID != 0) {
                pIDPlayer[_pID].crd = pIDPlayer[_pID].crd.add(_each);
                cIDCard[i].earnings = cIDCard[i].earnings.add(_each);
                _remain = _remain.sub0(_each);
            }
        }
        return _remain;
    }
    
    function doPartnerShares(uint256 _eth) private returns(uint256) {
        uint i;
        uint256 _temp;
        uint256 _left = _eth;
        //first 10%
        _temp = _eth.mul(10) / 100;
        gameFunds[partner[0]] = gameFunds[partner[0]].add(_temp);
        for(i = 1; i < 11; i++) {
            _temp = _eth.mul(9) / 100;
            gameFunds[partner[i]] = gameFunds[partner[i]].add(_temp);
            _left = _left.sub0(_temp);
        }
        return _left;
    }
    
    function doDevelopFunds(uint256 _eth) private{
        uint256 _temp;
        _temp = _eth.mul(12) / 100;
        gameFunds[to06] = gameFunds[to06].add(_temp);
        _temp = _eth.mul(8) / 100;    
        gameFunds[to04] = gameFunds[to04].add(_temp);
        _temp = _eth.mul(40) / 100;
        gameFunds[to20A] = gameFunds[to20A].add(_temp);
        _temp = _eth.mul(40) / 100;
        gameFunds[to20B] = gameFunds[to20B].add(_temp);
    }

    function endRound() private {
        NTAdatasets.Round storage _roundID = rIDRound[rID];
        NTAdatasets.PotSplit storage _potSplit = potSplit[0];
        uint256 _winPID = _roundID.leadPID;
        uint256 _pot = _roundID.pot;
        uint256 _left = _pot;

        //the pot is too small endround will ignore the dividens
        //new round will start at 0 eth
        if(_pot < 10000000000000) {
            emit onRoundEnd(pIDPlayer[_winPID].addr, pIDPlayer[_winPID].name, rID, _roundID.pot,0, now);
            newRound(0);
            return;
        }

        // potSplit:    ==> |20% to all, 45% to lastwinner, 5% to inviter 1st, 3% to inviter 2nd, 2% to inviter 3rd,
        //                  |8% to key buyer 1st, 5% to key buyer 2nd, 2% to key buyer 3rd, 10% to next round

        //20% to all
        uint256 _all = _pot.mul(_potSplit.allPlayer) / DIVIDE;
        _roundID.teamPot = _roundID.teamPot.add(_all);
        _left = _left.sub0(_all);

        //45% to lastwinner
        uint256 _temp = _pot.mul(_potSplit.lastWinner) / DIVIDE;
        pIDPlayer[_winPID].win = pIDPlayer[_winPID].win.add(_temp);
        _left = _left.sub0(_temp);

        //5% to inviter 1st, 3% to inviter 2nd, 2% to inviter 3rd
        uint256 _inv1st = _pot.mul(_potSplit.inviter1st) / DIVIDE;
        if (_roundID.invTop3[0] != 0) {
            pIDPlayer[_roundID.invTop3[0]].win = pIDPlayer[_roundID.invTop3[0]].win.add(_inv1st);
            _left = _left.sub0(_inv1st);
        }

        _inv1st = _pot.mul(_potSplit.inviter2nd) / DIVIDE;
        if (_roundID.invTop3[1] != 0) {
            pIDPlayer[_roundID.invTop3[1]].win = pIDPlayer[_roundID.invTop3[1]].win.add(_inv1st);
            _left = _left.sub0(_inv1st);
        }

        _inv1st = _pot.mul(_potSplit.inviter3rd) / DIVIDE;
        if (_roundID.invTop3[2] != 0) {
            pIDPlayer[_roundID.invTop3[2]].win = pIDPlayer[_roundID.invTop3[2]].win.add(_inv1st);
            _left = _left.sub0(_inv1st);
        }

         //8% to key buyer 1st, 5% to key buyer 2nd, 2% to key buyer 3rd
        _inv1st = _pot.mul(_potSplit.key1st) / DIVIDE;
        if (_roundID.keyTop3[0] != 0) {
            pIDPlayer[_roundID.keyTop3[0]].win = pIDPlayer[_roundID.keyTop3[0]].win.add(_inv1st);
            _left = _left.sub0(_inv1st);
        }

        _inv1st = _pot.mul(_potSplit.key2nd) / DIVIDE;
        if (_roundID.keyTop3[1] != 0) {
            pIDPlayer[_roundID.keyTop3[1]].win = pIDPlayer[_roundID.keyTop3[1]].win.add(_inv1st);
            _left = _left.sub0(_inv1st);
        }

        _inv1st = _pot.mul(_potSplit.key3rd) / DIVIDE;
        if (_roundID.keyTop3[2] != 0) {
            pIDPlayer[_roundID.keyTop3[2]].win = pIDPlayer[_roundID.keyTop3[2]].win.add(_inv1st);
            _left = _left.sub0(_inv1st);
        }

        //10% to next round
        uint256 _newPot = _pot.mul(potSplit[0].next) / DIVIDE;
        _left = _left.sub0(_newPot);
        emit onRoundEnd(pIDPlayer[_winPID].addr, pIDPlayer[_winPID].name, rID, _roundID.pot, _newPot + _left, now);
        //start new round
        newRound(_newPot + _left);
    }

    //tested
    function newRound(uint256 _eth) private {
        if (rIDRound[rID].ended == true || rID == 0) {
            rID++;
            rIDRound[rID].strt = now;
            rIDRound[rID].end = now.add(rndMax);
            rIDRound[rID].pot = rIDRound[rID].pot.add(_eth);
        }
    }

    function updateMasks(uint256 _rID, uint256 _pID, uint256 _all, uint256 _keys) private
    returns(uint256) {
        //calculate average share of each new eth in
        uint256 _allKeys = rIDRound[_rID].team1Keys + rIDRound[_rID].team2Keys;
        uint256 _unit = _all.mul(1000000000000000000) / _allKeys;
        rIDRound[_rID].mask = rIDRound[_rID].mask.add(_unit);
        //calculate this round player can get
        uint256 _share = (_unit.mul(_keys)) / (1000000000000000000);
        pIDPlayerRound[_pID][_rID].mask = pIDPlayerRound[_pID][_rID].mask.add((rIDRound[_rID].mask.mul(_keys) / (1000000000000000000)).sub(_share));
        return(_all.sub(_unit.mul(_allKeys) / (1000000000000000000)));
    }

    function withdrawEarnings(uint256 _pID) private returns(uint256) {
        updateVault(_pID);
        uint256 earnings = (pIDPlayer[_pID].win).add(pIDPlayer[_pID].gen).add(pIDPlayer[_pID].inv).add(pIDPlayer[_pID].tim).add(pIDPlayer[_pID].crd);
        if (earnings > 0) {
            pIDPlayer[_pID].win = 0;
            pIDPlayer[_pID].gen = 0;
            pIDPlayer[_pID].inv = 0;
            pIDPlayer[_pID].tim = 0;
            pIDPlayer[_pID].crd = 0;
        }
        return earnings;
    }

    function updateVault(uint256 _pID) private {
        uint256 _rID = pIDPlayer[_pID].lrnd;
        updateGenVault(_pID, _rID);
        updateInvVault(_pID, _rID);
        uint256 _team = calcTeamEarnings(_pID, _rID);
        //already calculate team reward,ended round key and mask dont needed
        if(rIDRound[_rID].ended == true) {
            pIDPlayerRound[_pID][_rID].team1Keys = 0;
            pIDPlayerRound[_pID][_rID].team2Keys = 0;
            pIDPlayerRound[_pID][_rID].mask = 0;
        }
        pIDPlayer[_pID].tim = pIDPlayer[_pID].tim.add(_team);
    }

    function updateGenVault(uint256 _pID, uint256 _rID) private {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rID);
        //put invitation reward to gen
        if (_earnings > 0) {
            // put in gen vault
            pIDPlayer[_pID].gen = _earnings.add(pIDPlayer[_pID].gen);
            // zero out their earnings by updating mask
            pIDPlayerRound[_pID][_rID].mask = _earnings.add(pIDPlayerRound[_pID][_rID].mask);
        }

    }

    function updateInvVault(uint256 _pID, uint256 _rID) private {
        uint256 _inv = pIDPlayerRound[_pID][_rID].inv;
        uint256 _invMask = pIDPlayerRound[_pID][_rID].invMask;
        if (_inv > 0) {
            pIDPlayer[_pID].inv = pIDPlayer[_pID].inv.add(_inv).sub0(_invMask);
            pIDPlayerRound[_pID][_rID].invMask = pIDPlayerRound[_pID][_rID].invMask.add(_inv).sub0(_invMask);
        }
    }

    //calculate valut not update
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rID) private view
    returns (uint256)
    {
        uint256 _all = pIDPlayerRound[_pID][_rID].team1Keys + pIDPlayerRound[_pID][_rID].team2Keys;
        return ((rIDRound[_rID].mask.mul(_all)) / (1000000000000000000)).sub(pIDPlayerRound[_pID][_rID].mask);
    }

    function calcTeamEarnings(uint256 _pID, uint256 _rID) private view
    returns (uint256)
    {
        uint256 _key1 = pIDPlayerRound[_pID][_rID].team1Keys;
        uint256 _key2 = pIDPlayerRound[_pID][_rID].team2Keys;
        if (rIDRound[_rID].ended == false)
            return 0;
        else {
            if (rIDRound[_rID].team == 0)
                return rIDRound[_rID].teamPot.mul(_key1 / rIDRound[_rID].team1Keys);
            else
                return rIDRound[_rID].teamPot.mul(_key2 / rIDRound[_rID].team2Keys);
        }
    }
    //tested
    function updateTimer(uint256 _keys, uint256 _rID) private {
        // grab time
        uint256 _now = now;
        // calculate new time
        uint256 _newTime;
        if (_now > rIDRound[_rID].end && rIDRound[_rID].leadPID == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndPerKey)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndPerKey)).add(rIDRound[_rID].end);

        // compare to max and set new end time
        if (_newTime < (rndMax).add(_now))
            rIDRound[_rID].end = _newTime;
        else
            rIDRound[_rID].end = rndMax.add(_now);
    }


}

library NTA3DKeysCalc {
    using SafeMath for *;
    uint256 constant private keyPriceTrigger = 50000 * 1e18;
    uint256 constant private keyPriceFirst = 0.0005 ether;
    uint256 constant private keyPriceAdd = 0.0001 ether;
    /**
     * @dev calculates number of keys received given X eth
     * _curEth current amount of eth in contract
     * _newEth eth being spent
     * @return amount of ticket purchased
     */
    function keysRec(uint256 _curKeys, uint256 _allEth)
        internal
        pure
        returns (uint256)
    {
        return(keys(_curKeys, _allEth));
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
        return(eth(_sellKeys.add(_curKeys)).sub(eth(_curKeys)));
    }

    /**
     * @dev calculates how many keys would exist with given an amount of eth
     * @param _eth eth "in contract"
     * @return number of keys that would exist
     */
    function keys(uint256 _keys, uint256 _eth)
        internal
        pure
        returns(uint256)
    {
        uint256 _times = _keys / keyPriceTrigger;
        uint i = 0;
        uint256 eth1;
        uint256 eth2;
        uint256 price;
        uint256 key2;
        for(i = _times;i < i + 200; i++) {
            if(eth(keyPriceTrigger * (i + 1)) >=  _eth) {
                if(i == 0) eth1 = 0;
                else eth1 = eth(keyPriceTrigger * i);
                eth2 = _eth.sub(eth1);
                price = i.mul(keyPriceAdd).add(keyPriceFirst);
                key2 = (eth2 / price).mul(1e18);
                return ((keyPriceTrigger * i + key2).sub0(_keys));
                break;
            }
        }
        //too large 
        require(false, "too large eth in");

    }

    /**
     * @dev calculates how much eth would be in contract given a number of keys
     * @param _keys number of keys "in contract"
     * @return eth that would exists
     */
     //tested
    function eth(uint256 _keys)
        internal
        pure
        returns(uint256)
    {
        uint256 _times = _keys / keyPriceTrigger;//keyPriceTrigger;
        uint256 _remain = _keys % keyPriceTrigger;//keyPriceTrigger;
        uint256 _price = _times.mul(keyPriceAdd).add(keyPriceFirst);
        if (_times == 0) {
            return (keyPriceFirst.mul(_keys / 1e18));
        } else {
            uint256 _up = (_price.sub(keyPriceFirst)).mul(_remain / 1e18);
            uint256 _down = (_keys / 1e18).mul(keyPriceFirst);
            uint256 _add = (_times.mul(_times).sub(_times) / 2).mul(keyPriceAdd).mul(keyPriceTrigger / 1e18);
            return (_up + _down + _add);
        }
    }
}

library NTAdatasets {

    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 inv;    // inviter vault
        uint256 tim;     //team pot
        uint256 crd;     //crd pot
        uint256 lrnd;   // last round played
        uint256 inviter1; // direct inviter
        uint256 inviter2; // second hand inviter
        uint256 vip; //0 no vip; 1 and 2
    }

    struct PlayerRound {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 team1Keys;
        uint256 team2Keys;
        uint256 inv;
        uint256 mask;
        uint256 invMask;
        uint256 score;
    }

    struct Round {
        uint256 leadPID;   // pID of player in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 team1Keys;   // keys
        uint256 team2Keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth win pot
        uint256 team;
        uint256 teamPot;
        uint256 smallDrop;//50Eth airdrop
        uint256 bigDrop; //300000 eth airdrop
        uint256 playerPot;
        uint256 mask;
        uint256[3] invTop3;
        uint256[3] keyTop3;
    }

    struct Card {
        uint256 owner;  //pID of card owner
        address addr;
        uint256 buyTime; //validity time check
        uint256 earnings;
    }

    struct Deposit {
        uint256 allPlayer;  // all player this rounds by key
        uint256 pot;        // last winner pot
        uint256 devfunds;   // game development Pot
        uint256 teamFee;    // team fee
        uint256 cards;      // stock right cards
        uint256 inviter;
        uint256 bigDrop;
        uint256 smallDrop;
    }

    struct PotSplit {
        uint256 allPlayer;  // all player this rounds by key
        uint256 lastWinner; // final player
        uint256 inviter1st; // player who get 1st of invatation
        uint256 inviter2nd;
        uint256 inviter3rd;
        uint256 key1st;     // player who get 1st key amount
        uint256 key2nd;
        uint256 key3rd;
        uint256 next;        // next round
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
    * @dev Subtracts two numbers, no throw
    */
    function sub0(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a < b) {
            return 0;
        } else {
            return a - b;
        }
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