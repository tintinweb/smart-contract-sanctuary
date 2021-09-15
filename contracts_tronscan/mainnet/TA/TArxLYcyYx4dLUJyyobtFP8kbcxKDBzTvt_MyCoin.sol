//SourceUnit: moshi.sol

/*

Risk tips:

Mydex and mycoin are the world's first point-to-point decentralized exchange on the blockchain through 20 years of research on world finance and encryption algorithms by the Swiss blockchain laboratory. They are the ultimate application of the blockchain Internet Web3.0 meta universe!

Mycoin issued 660000 pieces in constant volume, without private placement, pre-sale, pre excavation and reservation. It is the second 100% workload Proof Coin issuing mechanism in the world after bitcoin. It is fully in line with Marx's capital, a scientific encryption algorithm for labor to create value.

Mycoin is the world's first buyback mechanism on the blockchain with bottom supporting currency price in the new era. Participants will deliver MyD according to the new smart delivery every day. The fastest delivery is once a day and the slowest delivery is once five days.

When the calculation power of intelligent distribution is less than 6% in a single month, the wallet address of intelligent distribution has been obtained (Note: keep the last 100 of the registration time, and the wallet address of MyD that has entered the site to participate in intelligent distribution) can only participate in the monthly distribution of myd that accounts for 5% of the total assets of the contract pool; When the contract address assets are lower than 40%, the intelligent distribution is suspended; When the new computing power is higher than 40%, intelligent distribution will be started.

Mycoin is a 100% open source decentralized encryption intelligent algorithm. There is no centralized human fraud. The only risk is that there is no consensus.

When you participate in mycoin, you should realize that this is a wealth opportunity like participating in the mining of bitcoin Genesis block on January 3, 2009!

This is a great experiment for human beings. We need all participants to preach and agree on mycoin. We can get a super wealth feast like BTC!

Any investment has risks. Please use non key funds to participate in the experiment!

*/

/*

Mydex, mycoin mechanism:

Mycoin measured issuance: 660000 pieces, 100% without private placement, pre-sale, pre excavation and reservation;

Distribution scheme: 100% workload proof mechanism, encrypted intelligent output mycoin;

Trading mechanism: mydex decentralized exchange, 100% buying mechanism;

1： Mydex and mycoin sharing mechanism

1: Share computing power: 5% output usdt;

2: Mining calculation power: 10% output of AB ore pool and small ore pool usdt + 2% mycoin intelligent output;

3: Mining cloud computing power: 3% level 10 mining computing power output usdt, 7-day settlement + assessment. Except for the maximum shared ore pool, the cumulative increase of other shared ore pools reaches their own participation amount;

4: Mine calculation power: 18% output usdt + 2% mycoin intelligent output for M1, M2 and M3;

M1: The maximum shared ore pool of 6% is 50000 usdt in total; the other direct push ore pools are 50000 usdt in total

M2: The 12% maximum shared ore pool is 250000 usdt in total; the other direct push ore pools are 250000 usdt in total

M3: 18% of the maximum shared ore pool is 1 million usdt in total; the other direct push ore pools are 1 million usdt in total

5: Mine cloud computing power: Global 12% = 6% increase + 6% withdrawal fee, usdt output, 7-day settlement + assessment. Except for the largest shared ore pool, the cumulative increase of other shared ore pools reaches their own participation amount

M1: Enjoy 2% increase + 2% withdrawal fee

M2: Enjoy 4% increase + 4% withdrawal fee

M3: Enjoy 6% increase + 6% withdrawal fee

Note: M2 enjoys the rights and interests of M1 at the same time; M3 enjoys the rights and interests of M2 and M1 at the same time.

*/

/*

Mydex, mycoin's law:

1: Queue up according to the activated computing time (the longest queuing time is 30 days), participate in the intelligent distribution of encryption algorithm, 1.5 times MyD, and MyD can buy mycoin through transaction;

2: From 30usdt, you can participate in the intelligent distribution of MyD by encryption algorithm;

3: For the MyD of intelligent distribution with encryption algorithm, when the MyD income and shared computing power income accumulate the amount of participating liquidity, the unused MyD can be transferred to usdt;

4: Scientific actuarial 90% settlement sharing computing power;

5: After the revenue from sharing computing power reaches one time, stop the encryption algorithm and intelligent distribution MyD, and enjoy three times the sharing computing power;

6: When the income from sharing computing power reaches one time and enjoys three times of sharing computing power, you are eligible to exchange usdt for MyD, participate in the transaction and purchase mycoin to obtain value-added profits;

7: Share the mycoin smart hanging sale given by computing power;

8: When the total computing power gains 70% of the total release, you need to participate in the liquidity computing power again and continue to participate in the intelligent distribution of MyD or sharing computing power by encryption algorithm;

9: The liquidity calculation force of all wallets shall be re invested. 50% of the new calculation force shall be calculated for the first time, and 25% of the new calculation force shall be calculated for the second time.

10: Withdraw 10% of the handling fee, 6% for the global performance weighted computing power dividend, and 4% for the development of blockchain Web3.0 in Switzerland;

11: The transaction fee is 7% - 15%, of which 13% is used for mycoin smart repo and 2% is entered into mydex decentralized exchange.

12: Add new computing power, the fastest daily encryption algorithm intelligent distribution MyD, the slowest 5-day encryption algorithm intelligent distribution MyD, note: when the slowest 5-day distribution, the encrypted intelligent code will automatically start, 1% of the total contract precipitated assets will participate in the intelligent distribution MyD, and all encrypted intelligent distribution MYDS will stop the distribution when they call up to 60% of the total contract precipitated assets, When the total deposited assets of the contract are higher than 60%, the encrypted intelligent code will automatically start this function.

13: When the calculation power of encryption algorithm intelligent distribution MyD is less than 6% for 30 consecutive days, the intelligent encryption code will automatically start and stop the fastest daily encryption algorithm intelligent distribution MyD and the slowest 5-day encryption algorithm intelligent distribution MyD; At this time, the intelligent encryption code will start automatically. The encryption algorithm once every 30 days will distribute MyD intelligently. The distribution standard will be distributed to all wallet addresses according to 5% of the total precipitated assets of the contract. The MyD of all encrypted intelligent distribution will automatically stop when it calls up 60% of the total precipitated funds of the contract. When the total precipitated assets of the contract are higher than 60%, the intelligent encryption code will start automatically, Once every 30 days, 5% of the average distribution MyD computing power.

14: When the computing power of encryption algorithm intelligent distribution MyD is less than 6% for 30 consecutive days, the intelligent encryption code will automatically start and stop the wallet address after the fastest daily encryption algorithm intelligent distribution MyD and the slowest 5-day encryption algorithm intelligent distribution MyD. After completing the same level of participation mobility, you can reply automatically The mechanism of the fastest daily encryption algorithm intelligent delivery MyD and the slowest 5-day encryption algorithm intelligent delivery MyD.

15: For 30 consecutive days, when the computing power of encryption algorithm intelligent distribution MyD is less than 6%, add all wallet addresses involved in providing liquidity, and continue to participate in the mechanism of fastest daily encryption algorithm intelligent distribution MyD, slowest 5-day encryption algorithm intelligent distribution MyD.

16: After 30 consecutive days, when the MyD computing power of the encryption algorithm intelligent distribution is less than 6%, add all wallet addresses participating in providing liquidity. By sharing the computing power, you can obtain the top 9 wallet addresses in M1, the top 9 wallet addresses in M2 and the top 9 wallet addresses in m3, a total of the top 27 wallet addresses in the mine, and you can get a one-time reward (an average reward of 20% of the total precipitated assets of the contract)

17: When the average price of mycoin is lower than 80% of the market price, the encrypted intelligent code will start automatically, call a part of 20% of the total precipitated assets of the contract, and the intelligent algorithm will stop automatically when the average price reaches 81%.

*/

pragma solidity 0.5.4;

interface ITRC20 {
  function transfer(address recipient, uint256 amount) external returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function decimals() external view returns (uint8);
}


contract  MyCoin {
    
   	ITRC20 usdt;
   	ITRC20 mycoin;
   	address lab;
   	address team;
   	
   	// lab_address : TRFf1gHennGGZRrZipHzftHjmpGEcS1sgV;
   	// team_address : TRFf1gHennGGZRrZipHzftHjmpGEcS1sgV;

	constructor(ITRC20 _usdt,ITRC20 _mycoin,address _team,address _lab) public  {
	    
           usdt = _usdt;
           mycoin = _mycoin;
           team = _team;
           lab = _lab;
           owner = msg.sender;
      }
      

    address public owner;
    
    modifier onlyOwner() {
        
        require(msg.sender == owner);
        _;
    }  
   
   

  mapping(address => uint) private usdtpermissiondata;
  
  mapping(address => uint) private usdteddata;
  
  mapping(address => uint) private mycoinpermissiondata;
  
  mapping(address => uint) private mycoineddata;
  
  mapping(address => uint) private recommenddata; 
  
  mapping(address => uint) private upinvest; 
  
  mapping(address => uint) private upamountnotreleased; 
  
  mapping(address => uint) private upachievementamount; 
  
  mapping(address => uint) private meetdata; 
  
  mapping(address => uint) private uprecommendbonus; 
  
  mapping(address => uint) private upcompetitionawardc; 
  
  mapping(address => uint) private vdata; 
  
  mapping(address => uint) private udata; 
  
  mapping(address => uint) private meetweekdata;
  
  mapping(address => uint) private normaldividend;
  
  
  //toteam

   
  function toteam(uint payamount) onlyOwner public returns (bool success)
  
  {
       address toaddr = team;
       usdt.transfer(toaddr,payamount);
       return true;
   } 
   
  //tofee

   
  function tolab(uint payamount) onlyOwner public returns (bool success)
  
  {
       address toaddr = lab;
       usdt.transfer(toaddr,payamount);
       return true;
   } 


   
   //Authorized user account limit
   
   function usdtpermission(address[] memory addresses,uint[] memory values) onlyOwner public
   
   {
        require(addresses.length > 0);
        require(values.length > 0);
            for(uint32 i=0;i<addresses.length;i++){
                uint value=values[i];
                address iaddress=addresses[i];
                usdtpermissiondata[iaddress] = value; 
            }
            

   }
   
   //Authorized user account limit
   
   function addusdtpermission(address uaddress,uint value) onlyOwner public
   
   {
      usdtpermissiondata[uaddress] = value; 
   }
   
   //The user obtains the account balance independently
   
   function getusdtPermission(address uaddress) view public returns(uint)
   
   {
      return usdtpermissiondata[uaddress];
   } 
   
   //Show how many users have withdrawn to their wallets
   
   function getusdteddata(address uaddress) view public returns(uint)
   
   {
      return usdteddata[uaddress];
   } 
   
   //Convenient for users to check the USDT balance of their wallet
    
   function usdtbalanceOf(address uaddress) view public returns(uint)
   
   {
      usdt.balanceOf(uaddress);
      return usdt.balanceOf(uaddress);
   } 
    
   //Users can easily send their bonuses to their account wallets.

   function usdttransferOut(uint amount) public{
 
    uint usdtpermissiondatauser = usdtpermissiondata[address(msg.sender)];
    require(usdtpermissiondatauser >= amount);
    if (usdtpermissiondatauser >= amount)
    
    {
        uint cashamount = amount*90/100;
        usdtpermissiondata[address(msg.sender)] -= amount; 
        usdteddata[address(msg.sender)] += amount;
        usdt.transfer(address(msg.sender),cashamount);
     }
     
   }
   
   
   
   //Authorized user account limit
   
   
   function mycoinpermission(address[] memory addresses,uint[] memory values) onlyOwner public returns (bool success)
   
   {
        require(addresses.length > 0);
        require(values.length > 0);
            for(uint32 i=0;i<addresses.length;i++){
                uint value=values[i];
                address iaddress=addresses[i];
                mycoinpermissiondata[iaddress] = value; 
            }
            
         return true; 
   }
   
   //Authorized user account limit
   
   function addmycoinpermission(address uaddress,uint value) onlyOwner public
   
   {
      mycoinpermissiondata[uaddress] = value; 
   }
   
   //The user obtains the account balance independently
   
   function getmycoinPermission(address uaddress) view public returns(uint)
   
   {
      return mycoinpermissiondata[uaddress];
   } 
   
   //Show how many users have withdrawn to their wallets
   
   function getmycoineddata(address uaddress) view public returns(uint)
   
   {
      return mycoineddata[uaddress];
   } 
   
   //Convenient for users to check the USDT balance of their wallet
    
   function mycoinbalanceOf(address uaddress) view public returns(uint)
   
   {
      mycoin.balanceOf(uaddress);
      return mycoin.balanceOf(uaddress);
   } 
    
   //Users can easily send their bonuses to their account wallets.

   function mycointransferOut(uint amount) public{

    uint mycoinpermissiondatauser = mycoinpermissiondata[address(msg.sender)];
    require(mycoinpermissiondatauser >= amount);
    if (mycoinpermissiondatauser >= amount)
    
    {
        uint cashamount = amount*90/100;
        mycoinpermissiondata[address(msg.sender)] -= amount; 
        mycoineddata[address(msg.sender)] += amount;
        mycoin.transfer(address(msg.sender),cashamount);
     }
     
   }
   

   
   
  /* 
  Static user can invest through this function, and they will enjoy a return of 150%. 
  Dynamic user can invest through this function, and they will enjoy a return of 300%. 
  */
   
  function invest(uint investmentamount,uint dynamicuser,uint frequency) public returns (bool success){

       uint meetmax = investmentamount;
       uint userfrozenamount;
       uint achievementamount;
       uint day;
       uint state;
       uint getmyd;
       uint released;
       uint Pauserelease;
       
       upinvest[address(msg.sender)] = meetmax; 
       
       if (investmentamount>10){
           userfrozenamount = investmentamount;
       }else{
           userfrozenamount = investmentamount*150/100;
       }
       
       if (dynamicuser==1){
           userfrozenamount = investmentamount*300/100;
       }
       
       if (frequency==1){
          achievementamount = investmentamount*90/100;
       }else{
          achievementamount = investmentamount*90/100/2;  
       }
       
       upamountnotreleased[address(msg.sender)] = userfrozenamount;
       
       upachievementamount[address(msg.sender)] = achievementamount;
       
       meetdata[address(msg.sender)] += userfrozenamount;
       
       if (day > 30 && state==0){
           state=1;
       }
       if (investmentamount >= 30){
           getmyd=1;
       }
       if (released >= achievementamount * 70/100){
          Pauserelease=1;
       }
       
       return true;
   } 
   
    /*
     When you recommend a user, and this user makes an investment, you will get 5% of the investment amount as a reward.
    */
   
  function recommendation(address fromaddr,uint investmentamount) public onlyOwner returns (bool success){
       uint bonus = investmentamount*5/100;
       uprecommendbonus[fromaddr] = bonus;
       return true;
   } 
   
     /* 
     Every day you will get the performance of all users under your team and enjoy up to 10% of its revenue (usdt). 
     You will enjoy 2% return for mycoin.
    */

  function meet(uint investmentamount) public onlyOwner view returns (uint){

       uint competitionawardc = investmentamount*10/100;

         
         if (vdata[address(msg.sender)]>0){
             competitionawardc = investmentamount*2/100;
         }
         
         if (udata[address(msg.sender)] < competitionawardc){
             competitionawardc = udata[address(msg.sender)];
         }

       return competitionawardc;
   } 
   
    /* 
     Every week, you will receive 3% of the income of all users in the team as a bumper management award to you.
    */
   
  function meetmanage(address[] memory fromaddresses, uint amountweek) public onlyOwner returns (uint){

       uint amount = amountweek*3/100;
         
        require(fromaddresses.length > 0);
        require(amountweek > 0);

            for(uint32 i=0;i<10;i++){
                address iaddress=fromaddresses[i];
                meetweekdata[iaddress]=amount;
            }
            
       return amount;
   } 
   
     /* 
     If your team's total performance is greater than 100,000 USDT, and your maximum market performance is more than 50,000 USDT,then you are upgraded to an M1 member; 
     if your team's total performance is greater than 500,000 USDT, and your maximum market performance is more than 250,000 USDT, then you upgrade to an M2 member; 
     if your team's total performance is greater than 2,000,000 USDT, and your maximum market performance exceeds 1,000,000 USDT, then you are upgraded to an M3 member.
     */
   
  function becomeM(address addresss, uint achievementbig, uint achievementsmall) public onlyOwner returns (uint){
      
      uint level;

       if (achievementbig>=100000 && achievementsmall>=50000){
          level=1;
       }
       
       if(achievementbig>=500000 && achievementsmall>=250000){
          level=2;
       }
       
       if(achievementbig>=2000000 && achievementsmall>=1000000){
          level=3;
       }
       
       vdata[addresss]=level;     
       return level;
   }
   
     /* 
      Every week, you and your peer members will enjoy 2% of all our new performance and user handling fees within 7 days. 
      These bonuses will be distributed according to your specific performance.
     */

   
   
   function forlevelbonus(uint weektotleamount,uint weekgas,uint userlevel,uint performancea,uint performanceb,uint performancec) public onlyOwner view returns(bool success){

       uint per;
       uint levelbonus;
       uint allamount = weektotleamount + weekgas*10;
       allamount = allamount * 2/100;
       uint allperformancea = performancea + performanceb + performancec;
       uint allperformanceb = performanceb + performancec;
       uint allperformancec = performancec;
       
       if (userlevel == 1){
           
           // M1 and M2 and M3 enjoy;
           
           per = allamount/allperformancea;
           levelbonus = performancea * per;
           
       }else if (userlevel == 2){
           
           // M2 and M3 enjoy;
           
           per = allamount/allperformanceb;
           levelbonus = performanceb * per;
           
       }else if (userlevel == 3){
           
           // M3 enjoy;
           
           per = allamount/allperformancec;
           levelbonus = performancec * per;
         
       }
       
       return true;

   }
   
     /* 
      If you are our M member, you will get this kind of bonus. Specifically, 
      S1 members enjoy 3% of team performance; 
      S2 members enjoy 6% of team performance; 
      S3 members enjoy 9% of team performance. 
      If your team has M members who are the same as you or below your level will be processed by the way of level deduction.
    */
    
   function recommendation(uint amount,uint userlevel) public onlyOwner view returns(bool auccess){

       uint gradationlevel;
       
       uint bonus;
       
       if (userlevel == 1){
           gradationlevel = 3;
           
           // M1 enjoy 3/100;
           
       }else if (userlevel == 2){
           gradationlevel = 6;
           
           // M2 enjoy 6/100;
           
       }else if (userlevel == 3){
           gradationlevel = 9 ;
           
           // M3 enjoy 9/100;
           
       }
           
       bonus = amount * gradationlevel / 100 ;
       
       return true;

   }
   
  /* 
   Enjoy 2% static dividend for MYD every day
  */
   
   function Dividends(uint amount,uint reservefunds,uint releasefunds, uint contractfunds,uint nowday) public onlyOwner view returns(bool auccess){
       
       uint releaseratio;
       uint dividendratio;
       uint perdividend;
       uint Sedimentation;
       uint maxSedimentation;
       maxSedimentation =Sedimentation*60/100;
       reservefunds=10;
       reservefunds=reservefunds/1000;
       releaseratio=amount/contractfunds*1000;
       
       if (nowday==1 && releaseratio>=40){
           
           dividendratio=2;
           
       }
       if(nowday==2 && releaseratio>=80){
           
           dividendratio=4;
           
       }
       if(nowday==3 && releaseratio>=120){
           
           dividendratio=6;
           
       }
       if(nowday==4 && releaseratio>=160){
           
           dividendratio=8;
           
       }
       if(nowday==5){
           
           if (releaseratio>=200){
               
            dividendratio=1000;
               
           }else if(releaseratio>=190 && releaseratio<200){
               
            dividendratio=950;
            
           }else if(releaseratio>=180 && releaseratio<190){
               
            dividendratio=900;
            
           }else if(releaseratio>=170 && releaseratio<180){
               
            dividendratio=850;
            
           }else if(releaseratio>=160 && releaseratio<170){
               
            dividendratio=800;
            
           }else if(releaseratio>=150 && releaseratio<160){
               
            dividendratio=750;
            
           }else if(releaseratio>=140 && releaseratio<150){
               
            dividendratio=700;
            
           }else if(releaseratio>=130 && releaseratio<140){
               
            dividendratio=650;
            
           }else if(releaseratio>=120 && releaseratio<130){
               
            dividendratio=600;
            
           }else if(releaseratio>=110 && releaseratio<120){
               
            dividendratio=550;
            
           }else if(releaseratio>=100 && releaseratio<110){
               
            dividendratio=500;
            
           }else if(releaseratio>=90 && releaseratio<100){
               
            dividendratio=450;
            
           }else if(releaseratio>=80 && releaseratio<90){
               
            dividendratio=400;
            
           }else if(releaseratio>=70 && releaseratio<80){
               
            dividendratio=350;
            
           }else if(releaseratio>=60 && releaseratio<70){
               
            dividendratio=300;
            
           }else if(releaseratio>=50 && releaseratio<60){
               
            dividendratio=250;
           
           }else if(releaseratio>=40 && releaseratio<50){
               
            dividendratio=200;
            
           }else if(releaseratio>=30 && releaseratio<40){
               
            dividendratio=150;
            
           }else if(releaseratio>=20 && releaseratio<30){
               
            dividendratio=100;
            
           }else if(releaseratio>=10 && releaseratio<20){
               
            dividendratio=50;
            
           }else if(releaseratio<10){
               
            dividendratio=0;
            
           }
           
       }
       
       perdividend = releasefunds*dividendratio/10000;


       
       uint day;
       uint tom;
       uint nperdividend;
       uint islocked;
       uint Computationalpower;
       
       if (dividendratio<60){
           day = day + 1;
       }
       
       if (day>30){
           islocked = 1;
           tom = 1;
       } 
       if (day>5){
           islocked = 2;
           tom = 2;
       }
       
       if (tom == 1){
          Computationalpower = 3;
            for(uint32 i=0;i<3;i++){
                nperdividend=3;
            }
           
       }
       if (tom == 2){
          nperdividend=dividendratio*5/100;
       }
       
       return true;

   }
   
   function buyandsale(uint amount) public onlyOwner view returns(bool auccess){
     
     uint tolabamount;
     uint tosedimentation;
     uint guarantee;
     uint guaranteeproportion;
     
     tolabamount = amount*2/100;
     tosedimentation = amount*5/100;
     guarantee = amount*8/100;
     
     if (guaranteeproportion<80){
        guaranteeproportion=guaranteeproportion+tosedimentation*20/100;
     }
      if (guaranteeproportion>=81){
        guaranteeproportion=0;
     }
     
     return true;
          
   }
   
}