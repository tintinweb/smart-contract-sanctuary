pragma solidity ^0.6.0;
import "./Ownable.sol";
import "./Bet.sol";

contract CreateBet is Ownable {
    
    address payable createbetmaster;
    constructor() public payable {
        createbetmaster = msg.sender;
    }

    struct s_yesnobet {
        yesnobet _bet;
        address payable _admin;
        mapping(uint => s_yesplayer) yesplayers;
        mapping(uint => s_noplayer) noplayers;
        uint256 _yesplayers;
        uint256 _noplayers;
        uint256 _genesisvotes;
        uint256 _yesvotes;
        uint256 _novotes;
        uint256 _yeswagers;
        uint256 _nowagers;
        string _proposition;
        int _outcome;
        uint _id;
        bool _resolver;
        address payable _betaddress;
    }

    struct s_yesplayer {
        address payable _yesplayer;
        uint256 _yesvotes;
        uint256 _yesbalance;
        uint256 _uniqueplayer;
    }
    struct s_noplayer {
        address payable _noplayer;
        uint256 _novotes;
        uint256 _nobalance;
        uint256 _uniqueplayer;
    }

    struct s_betstats{
        uint256 _betbalance;
        uint256 _yesodds;
        uint256 _noodds;
        uint256 _genesiscost;
    }

    struct s_tests {
        uint256 _betindex;
        uint256 _bettorindex;
        uint256 _specificindex;
        address _contract;
        address _player;
        uint256 _playeryesvotes;
        uint256 _playeryesbalance;
        uint256 _playernovotes;
        uint256 _playernobalance;
        uint _time;
        bool _isyes;
        bool _isno;
    }

    mapping(uint => s_yesnobet) public bets;
    mapping(uint => s_betstats) public stats;
    mapping(uint => s_tests) public tests;

    uint public index = 0;
    uint public bettorindex = 0;
    
    function createyesnobet(string memory _createproposition, uint256 _genesisodds, uint256 _gasfee, uint256 _adminfee, uint256 _genesiscost) public payable onlyOwner {
        require(_genesisodds < 100, "set yes odds below 100 to start; recommend 50/50 unless there is justification for other");
        yesnobet bet = new yesnobet(this, _createproposition , _genesisodds, _gasfee, _adminfee, _genesiscost);
        bets[index]._bet = bet;
        bets[index]._admin = msg.sender;
        bets[index]._genesisvotes = _genesisodds;
        bets[index]._yesvotes = _genesisodds;
        bets[index]._novotes = 100 - _genesisodds;
        bets[index]._proposition = _createproposition;
        bets[index]._outcome = 3; // 3 = none
        bets[index]._id = index;
        bets[index]._resolver = false;
        bets[index]._betaddress = address(bet);
        this.updatestats(index);
        index ++;
    }

    function updatestats(uint _index) public {
        yesnobet bet = bets[_index]._bet;
        stats[_index]._betbalance = address(bets[_index]._bet).balance;
        stats[_index]._noodds = (bets[_index]._novotes * 10000) / (bets[_index]._yesvotes + bets[_index]._novotes);
        stats[_index]._yesodds = (bets[_index]._yesvotes * 10000) / (bets[_index]._yesvotes + bets[_index]._novotes);
        stats[_index]._genesiscost = bet.genesiscost();
    }

    function test(
        uint _betindex,
        uint _bettorindex,
        uint _specificindex,
        address _contract,
        address _player,
        uint256 _yesvotes,
        uint256 _yesbalance,
        uint256 _novotes,
        uint256 _nobalance,
        bool _yes,
        bool _no
        ) public
        {
        tests[_bettorindex]._betindex = _betindex;
        tests[_bettorindex]._bettorindex = bettorindex;
        tests[_bettorindex]._specificindex = _specificindex;
        tests[_bettorindex]._contract = _contract;
        tests[_bettorindex]._player = _player;
        tests[_bettorindex]._playeryesvotes = _yesvotes;
        tests[_bettorindex]._playeryesbalance = _yesbalance;
        tests[_bettorindex]._playernovotes = _novotes;
        tests[_bettorindex]._playernobalance = _nobalance;
        tests[_bettorindex]._time = block.timestamp;
        tests[_bettorindex]._isyes = _yes;
        tests[_bettorindex]._isno = _no;
        
    }
    

    function betyes(uint _index) public payable {
        require( bets[_index]._outcome == 3, "this bet is already resolved");
        yesnobet bet = bets[_index]._bet;
        payable(address(bet)).transfer(address(this).balance);
        uint price = (bets[_index]._yesvotes * 10000 * bet.genesiscost()) / (bets[_index]._yesvotes + bets[_index]._novotes) / 10000;
        uint votes = msg.value / price;
        bets[_index].yesplayers[bets[_index]._yesplayers]._yesplayer = msg.sender;
        bets[_index]._yesvotes = bets[_index]._yesvotes + votes;
        bets[_index].yesplayers[bets[_index]._yesplayers]._yesvotes = votes;
        bets[_index].yesplayers[bets[_index]._yesplayers]._yesbalance = msg.value;
        bets[_index]._yeswagers = bets[_index]._yeswagers + msg.value;
        bets[_index].yesplayers[bets[_index]._yesplayers]._uniqueplayer = bettorindex;
        this.updatestats(_index);
        this.test(_index, bettorindex, bets[_index]._yesplayers, address(bet), tx.origin, votes, msg.value, 0, 0, true, false);
        bets[_index]._yesplayers ++;
        bettorindex ++;
    }

    function betno(uint _index) public payable {
        require( bets[_index]._outcome == 3, "this bet is already resolved");
        yesnobet bet = bets[_index]._bet;
        payable(address(bet)).transfer(address(this).balance);
        uint price = (bets[_index]._novotes * 10000 * bet.genesiscost()) / (bets[_index]._yesvotes + bets[_index]._novotes) / 10000;
        uint votes = msg.value / price;
        bets[_index].noplayers[bets[_index]._noplayers]._noplayer = msg.sender;
        bets[_index]._novotes = bets[_index]._novotes + votes;
        bets[_index].noplayers[bets[_index]._noplayers]._novotes = votes;
        bets[_index].noplayers[bets[_index]._noplayers]._nobalance = msg.value;
        bets[_index]._nowagers = bets[_index]._nowagers + msg.value;
        bets[_index].noplayers[bets[_index]._noplayers]._uniqueplayer = bettorindex;
        this.updatestats(_index);this.updatestats(_index);
        this.test(_index, bettorindex,bets[_index]._noplayers, address(bet), tx.origin, 0, 0,votes, msg.value, false, true);
        bets[_index]._noplayers ++;
        bettorindex ++;
    }

    function setoracle (uint _index, int _outcome) public onlyOwner {
        bool yes = false; 
        bool no = false; 
        bool push = false; 
        bool none = false;

        if (_outcome == 0) {
            no = true;
        } else if (_outcome == 1) {
            yes = true;
        } else if (_outcome == 2) {
            push = true;
        } else if (_outcome == 3) {
            none = true;
        }
        require( no || yes || push || none, "outcomes should be 0 (no), 1 (yes), 2 (push), or 3 (none)");
        bets[_index]._outcome = _outcome;
    }

    function resolve (uint _index) public onlyOwner {
        int _outcome = bets[_index]._outcome;
        require(_outcome != 3, "contract oracle not resolved");
        require(bets[_index]._resolver == false, "no double resolving");
        
        if (_outcome == 0) {
            payno(_index);//no
        } else if (_outcome == 1) {
            payyes(_index); //yes
        } else if (_outcome == 2) {
            paypush(_index);//push;
        }
        this.updatestats(_index);
        bets[_index]._resolver = true;

    }
    function revertno(uint _index, uint _player) public onlyOwner {
        yesnobet bet = bets[_index]._bet;
        bets[_index]._nowagers = bets[_index]._nowagers - bets[_index].noplayers[_player]._nobalance;
        bets[_index]._novotes = bets[_index]._novotes - bets[_index].noplayers[_player]._novotes;
        uint256 fees =  bets[_index].noplayers[_player]._nobalance * bet.gasfee() / 10000;
        bet.payout(bets[_index]._admin, fees);
        uint256 amount = bets[_index].noplayers[_player]._nobalance - fees;
        address payable receiver = bets[_index].noplayers[_player]._noplayer;
        bet.payout(receiver, amount);
        bets[_index].noplayers[_player]._nobalance = 0;
        bets[_index].noplayers[_player]._novotes = 0;
        this.updatestats(_index);
        this.test(_index, 
        bets[_index].noplayers[_player]._uniqueplayer, 
        _player, 
        address(bet), 
        tx.origin, 0, 0, 0, 0, false, true);
    }

    function revertyes(uint _index, uint _player) public onlyOwner {
        yesnobet bet = bets[_index]._bet;
        bets[_index]._yeswagers = bets[_index]._yeswagers - bets[_index].yesplayers[_player]._yesbalance;
        bets[_index]._yesvotes = bets[_index]._yesvotes - bets[_index].yesplayers[_player]._yesvotes;
        uint256 fees =  bets[_index].yesplayers[_player]._yesbalance * bet.gasfee() / 10000;
        bet.payout(bets[_index]._admin, fees);
        uint256 amount = bets[_index].yesplayers[_player]._yesbalance - fees;
        address payable receiver = bets[_index].yesplayers[_player]._yesplayer;
        bet.payout(receiver, amount);
        bets[_index].yesplayers[_player]._yesbalance = 0;
        bets[_index].yesplayers[_player]._yesvotes = 0;
        this.updatestats(_index);
        this.test(_index, 
        bets[_index].yesplayers[_player]._uniqueplayer, 
        _player, 
        address(bet), 
        tx.origin, 0, 0, 0, 0, true, false);
    }

    function payyes (uint _index) public onlyOwner {
        yesnobet bet = bets[_index]._bet;
        uint256 yesfees = bets[_index]._yeswagers * bet.gasfee() / 10000 + bets[_index]._yeswagers * bet.adminfee() / 10000;
        uint256 nofees = bets[_index]._nowagers * bet.gasfee() / 10000 + bets[_index]._nowagers * bet.adminfee() / 10000;
        uint256 fees = yesfees + nofees;
        bet.payout(bets[_index]._admin, fees);
        uint256 wagers = bets[_index]._yeswagers - yesfees;
        uint256 upside = bets[_index]._nowagers - nofees;

        for (uint256 i = 0; i < bets[_index]._yesplayers; i++ ) {
            uint256 wagershare = bets[_index].yesplayers[i]._yesbalance * 10000 /  (bets[_index]._yeswagers);
            uint256 upsideshare = bets[_index].yesplayers[i]._yesvotes * 10000 /  (bets[_index]._yesvotes - bets[_index]._genesisvotes);
            uint256 wageramount = wagers * wagershare / 10000;
            uint256 upsideamount = upside * upsideshare / 10000;
            uint256 amount = wageramount + upsideamount;
            address payable receiver = bets[_index].yesplayers[i]._yesplayer;
            bet.payout(receiver, amount);
        }
        this.updatestats(_index);
    }

    function payno (uint _index) public onlyOwner {
        yesnobet bet = bets[_index]._bet;
        uint256 yesfees = bets[_index]._yeswagers * bet.gasfee() / 10000 + bets[_index]._yeswagers * bet.adminfee() / 10000;
        uint256 nofees = bets[_index]._nowagers * bet.gasfee() / 10000 + bets[_index]._nowagers * bet.adminfee() / 10000;
        uint256 fees = yesfees + nofees;
        bet.payout(bets[_index]._admin, fees);
        uint256 wagers = bets[_index]._nowagers - nofees;
        uint256 upside = bets[_index]._yeswagers - yesfees;

        for (uint256 i = 0; i < bets[_index]._noplayers; i++ ) {
            uint256 wagershare = bets[_index].noplayers[i]._nobalance * 10000 /  (bets[_index]._nowagers);
            uint256 upsideshare = bets[_index].noplayers[i]._novotes * 10000 /  (bets[_index]._novotes - (100 - bets[_index]._genesisvotes));
            uint256 wageramount = wagers * wagershare / 10000;
            uint256 upsideamount = upside * upsideshare / 10000;
            uint256 amount = wageramount + upsideamount;
            address payable receiver = bets[_index].noplayers[i]._noplayer;
            bet.payout(receiver, amount);
        }
        this.updatestats(_index);
    }

    function paypush (uint _index) public onlyOwner {
        yesnobet bet = bets[_index]._bet;
        uint256 yesfees = bets[_index]._yeswagers * bet.gasfee() / 10000;
        uint256 nofees = bets[_index]._nowagers * bet.gasfee() / 10000;
        uint256 fees = yesfees + nofees;
        bet.payout(bets[_index]._admin, fees);
        uint256 yeswagers = bets[_index]._yeswagers - yesfees;
        uint256 nowagers = bets[_index]._nowagers - nofees;

        for (uint256 i = 0; i < bets[_index]._yesplayers; i++ ) {
            uint256 wagershare = bets[_index].yesplayers[i]._yesbalance * 10000 /  (bets[_index]._yeswagers);
            uint256 wageramount = yeswagers * wagershare / 10000;
            uint256 amount = wageramount;
            address payable receiver = bets[_index].yesplayers[i]._yesplayer;
            bet.payout(receiver, amount);
        }

        for (uint256 i = 0; i < bets[_index]._noplayers; i++ ) {
            uint256 wagershare = bets[_index].noplayers[i]._nobalance * 10000 /  (bets[_index]._nowagers);
            uint256 wageramount = nowagers * wagershare / 10000;
            uint256 amount = wageramount;
            address payable receiver = bets[_index].noplayers[i]._noplayer;
            bet.payout(receiver, amount);
        }
        this.updatestats(_index);
    }

    function validatemaster() public view returns(address){
        return address(createbetmaster);
    }
}