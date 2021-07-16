//SourceUnit: tron-x21 (2).sol

pragma solidity 0.5.8;

contract TronX21 {

    struct Deposit {
      uint256 amount;
      uint256 depTime;
      uint256 payout;
    }

    struct Player {
        address upline;
        Deposit[] deposits;
        uint256 last_payout;
        uint256 last_withdraw;
        uint256 last_reinvest;
        uint256 depositCount;
        uint256 reinvestCount;
        uint256 dividends;
        uint256 tarifN;
        uint256 r_count;
        uint256 refer_bonus;
       
        uint256 total_deposited;
        uint256 total_withdrawn;
        uint256 total_reinvested;
        uint256 total_refer_bonus;
        mapping(uint8 => uint256) structure;
    }

    address payable private developer;
    uint256 private contract_CreateTime;
    uint256 private contract_StartTime;
    uint256 private invested;
	uint256 private investors;
    uint256 private totalWithdrawn;
    uint256 private total_refer_bonus;
    uint256 private depositCount;
    uint8[] private ref_bonuses;

    // Const
    uint256 private constant DEV_FEE              = 10;
    uint256 private constant DAILY_HOLDBONUS      = 0.1E9;
    uint256 private constant UNI_R_BONUS          = 0.2E9;
    uint256 private constant DEFAULT_PLANBONUS    = 4.2E9;
    uint256 private constant MIN_INVEST           = 100E6;
    uint256 private constant MIN_WITHDRAW         = 100E6;
    uint256 private constant MAX_PLANPROFIT       = 210;
    uint256 private constant REINVESTBONUS_WAIT   = 24 * 60 * 60;
    uint256 private constant CONTRACT_TIMETOSTART = 24 * 60 * 60;
   
    mapping(address => Player) private players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        developer = msg.sender;
        ref_bonuses.push(7);
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        contract_CreateTime = now;
        contract_StartTime = contract_CreateTime + CONTRACT_TIMETOSTART;
    }

    function refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;

            uint256 bonus = _amount * ref_bonuses[i] / 100;

            players[up].refer_bonus += bonus;
            players[up].total_refer_bonus += bonus;

            total_refer_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != developer) {
             if(players[_upline].depositCount == 0) {
                 _upline = developer;
             }
             

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount * 1 / 100);

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }

    function deposit(address _upline) external payable {
        Player storage player = players[msg.sender];

        require(now >= contract_StartTime, "Deposits are not available yet");
        require(msg.value >= MIN_INVEST, "Minimum deposit is 100 TRX");

        setUpline(msg.sender, _upline, msg.value);

        if (player.depositCount == 0) {
            player.last_payout = now;
            player.last_withdraw = now;
            player.last_reinvest = now;
            player.tarifN = DEFAULT_PLANBONUS;
            investors++;
        }

        player.deposits.push(Deposit(msg.value, now, 0));

        player.depositCount++;
        player.total_deposited += msg.value;

        depositCount ++;
        invested += msg.value;

        payTrxOnTopFee(msg.value);

        refPayout(msg.sender, msg.value);

        emit NewDeposit(msg.sender, msg.value);
    }

    function withdraw() external {
        Player storage player = players[msg.sender];
        player.dividends = getTotal_InterestProfit(msg.sender);
        require(getContractBalance() >= player.dividends + player.refer_bonus , "Contract balance < Interest Profit");
        require(MIN_WITHDRAW <= player.dividends + player.refer_bonus , "Minimum to withdraw is 100 TRX");

        uint256 val;
		uint256 amount = player.refer_bonus;

		for (uint256 i = 0; i < player.deposits.length; i++) {
		   val = getPlan_InterestProfit(msg.sender, i);
		   player.deposits[i].payout += val;
		   amount += val;
		}

		player.last_payout = now;
        player.last_withdraw = now;

		player.tarifN = 0;
		player.r_count = 0;

        player.dividends = 0;
        player.refer_bonus = 0;
        

        player.total_withdrawn += amount;
        totalWithdrawn += amount;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function reinvest() external {
        Player storage player = players[msg.sender];

        uint256 val;
		uint256 reinvestAmount = player.refer_bonus ;

		for (uint256 i = 0; i < player.deposits.length; i++) {
		   val = getPlan_InterestProfit(msg.sender, i);
		   player.deposits[i].payout += val;
		   reinvestAmount += val;
		}

		if (now >= player.last_reinvest + REINVESTBONUS_WAIT) {
		    player.r_count++;
		    player.last_reinvest = now;
		}

		player.last_payout = now;

        player.dividends = 0;
        player.refer_bonus = 0;
        
        player.deposits.push(Deposit(reinvestAmount, now, 0));
        player.reinvestCount++;
        player.total_reinvested += reinvestAmount;
        emit NewDeposit(msg.sender, reinvestAmount);
    }

    function getHoldBonus(address _addr) internal view returns(uint256) {
        Player storage player = players[_addr];
        uint256 elapsed_time;
        if (player.depositCount > 0) {
            elapsed_time = minZero(now, player.last_withdraw);
        } else {
            elapsed_time = 0;
        }
        return UNI_R_BONUS * player.r_count + DAILY_HOLDBONUS / 86400 * elapsed_time;
    }

    function getTarif(address _addr) internal view returns(uint256) {
        Player storage player = players[_addr];
        uint256 tN = player.tarifN;
        uint256 tB = getHoldBonus(_addr);
        return tN + tB;
    }

    function getPlan_InterestProfit(address _addr, uint256 plan) view private returns(uint256) {
        Player storage player = players[_addr];
		uint256 div;
		uint256 tarif = getTarif(_addr);

	    uint256 fr = maxVal(player.last_payout, player.deposits[plan].depTime);
	    uint256 to = now;

        if(fr < to) {
           div = minVal(
                   minZero(player.deposits[plan].amount * MAX_PLANPROFIT / 100, player.deposits[plan].payout),
                   player.deposits[plan].amount * (to - fr) * tarif / 86400 / 100E9
                  );
        } else {
           div = 0;
        }
		return div;
    }

    function getTotal_InterestProfit(address _addr) view private returns(uint256) {
        Player storage player = players[_addr];
		uint256 total_div;
		for (uint256 i = 0; i < player.deposits.length; i++) {
		   total_div += getPlan_InterestProfit(_addr, i);
		}
		return total_div;
    }

    function getActiveDeposits(address _addr) view private returns(uint256) {
        Player storage player = players[_addr];
		uint256 amount;
		for (uint256 i = 0; i < player.deposits.length; i++) {
		   if (getPlan_InterestProfit(_addr, i) > 0) {
		      amount += player.deposits[i].amount;
		   }
		}
		return amount;
    }

    function payTrxOnTopFee(uint256 val) private {
        uint256 amount = (val * DEV_FEE) / 100;
        developer.transfer(amount);
    }

    function minZero(uint256 a, uint256 b) private pure returns(uint256) {
        if (a > b) {
           return a - b;
        } else {
           return 0;
        }
    }

    function maxVal(uint256 a, uint256 b) private pure returns(uint256) {
        if (a > b) {
           return a;
        } else {
           return b;
        }
    }

    function minVal(uint256 a, uint256 b) private pure returns(uint256) {
        if (a > b) {
           return b;
        } else {
           return a;
        }
    }

	function getContractBalance() internal view returns (uint256) {
		return address(this).balance;
	}

   function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _referBonus, uint256 _withdrawn, uint256 _depositCount,
                                                 uint256 _contractStartTime, uint256 _contractIniTime) {
        return (
            invested,
            investors,
            total_refer_bonus,
            totalWithdrawn,
            depositCount,
            contract_StartTime,
            minZero(contract_StartTime, now)
        );
    }

    function userGeneralInfo(address _addr) view external returns(uint256 _referBonus, uint256 _totalDeposited, uint256 _totalWithdrawn,
                                                                  uint256 _totalReinvested, uint256 _totalReferBonus,
                                                                  uint256 _refLevel1, uint256 _refLevel2, uint256[3] memory _structure) {
        Player storage player = players[_addr];

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            _structure[i] = player.structure[i];
        }
        return (
            player.refer_bonus,
            
            player.total_deposited,
            player.total_withdrawn,
            player.total_reinvested,
            player.total_refer_bonus,
            player.structure[0],
            player.structure[1],
            _structure
        );
    }

    function userPlanInfo(address _addr) view external returns(uint256 _depositCount, uint256 _activeDeposit, uint256 _reinvestCount, uint256 _dividends, uint256 _tarifN, uint256 _tarifB) {
        Player storage player = players[_addr];

        uint256 dividends = getTotal_InterestProfit(_addr) + player.refer_bonus ;

        return (
            player.depositCount,
            getActiveDeposits(_addr),
            player.reinvestCount,
            dividends,
            player.tarifN,
            getHoldBonus(_addr)
        );
    }

}