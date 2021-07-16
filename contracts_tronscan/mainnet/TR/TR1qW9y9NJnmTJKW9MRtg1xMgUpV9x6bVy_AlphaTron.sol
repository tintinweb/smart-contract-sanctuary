//SourceUnit: AlphaTron.sol

pragma solidity ^0.5.0;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AlphaTron is Ownable {

  using SafeMath for uint256;

    uint256 public MIN_DEPOSIT = 1 trx;
    uint256 public PROFIT_DAILY_PERCENT = 21;
    uint256 public PROFITABILITY_TRIGGER_PERCENT = 20;

    uint256 public ADMIN_FEE_DEPOSIT_PERCENT = 5;
    uint256 public ADMIN_FEE_REINVEST_PERCENT = 5;
    uint256 public ADMIN_FEE_WITHDRAW_PERCENT = 5;

    address payable PROMOTE_ADDRESS = address(0x41489d7bb736d2955db4d4b7a0458735a0406eafe5); 
    address payable COMPENSATIONS_ADDRESS = address(0x411fc1abdb3a7a0bc2a29dff056d45c4e568607985); 

    uint256[5] public REFERRAL_FEE_PERCENTS = [7, 5, 3, 2, 1]; 
    uint256 public REFERRAL_FEE_TOTAL_PERCENT = 18;

    uint256[9] public LEADER_BONUS_TRIGGERS = [
      10000 trx,
      20000 trx,
      50000 trx,
      100000 trx,
      500000 trx,
      1000000 trx,
      5000000 trx,
      10000000 trx,
      50000000 trx
    ];

    uint256[9] public LEADER_BONUS_REWARDS = [
      300 trx,
      600 trx,
      1500 trx,
      3000 trx,
      15000 trx,
      50000 trx,
      200000 trx,
      500000 trx,
      5000000 trx
    ];

    uint256[3] public LEADER_BONUS_LEVEL_PERCENTS = [100, 30, 15];

    uint256 public totalPlayers;
    uint256 public totalInvested;
    uint256 public totalPayout;

    uint256 public totalReferralReward;
    uint256 public totalLeadBonusReward;

    struct Player {
      uint256 time;
      uint256 deposit;
      uint256 profit;
      uint256 payout;
      uint256 dailyPercent;

      address referrer;
      uint256 referralNumber;
      uint256 referralReward;

      uint256 leadTurnover;
      uint256 leadBonusReward;
      bool[9] receivedBonuses;
    }

    mapping(address => Player) public players;

    uint256 public dailyPercent = PROFIT_DAILY_PERCENT;
    uint256 public dailyPercentTime;

    constructor() public {
      register(owner(), owner());
    }

    function register(address _addr, address _referrer) private {
      Player storage player = players[_addr];
      player.referrer = _referrer;

      players[_referrer].referralNumber = players[_referrer].referralNumber.add(1);
    }

    function () external payable {
      deposit(owner());
    }

    function deposit(address _referrer) public payable {
      collect(msg.sender);
      changeDailyPercent();

      require(msg.value >= MIN_DEPOSIT, "Minimum deposit is 1 TRX");

      Player storage player = players[msg.sender];
      if (msg.value >= player.deposit.mul(PROFITABILITY_TRIGGER_PERCENT).div(100)) {
        player.dailyPercent = dailyPercent;
      }

      if (player.time == 0) {
        player.time = now;
        totalPlayers++;
        if (_referrer != address(0x0) && players[_referrer].deposit > 0){
          register(msg.sender, _referrer);
        } else{
          register(msg.sender, owner());
        }

        player.dailyPercent = dailyPercent;
      }
      player.deposit = player.deposit.add(msg.value);

      distributeRef(msg.value, player.referrer);
      distributeBonuses(msg.value, player.referrer);

      totalInvested = totalInvested.add(msg.value);

      uint256 ownerReward = msg.value.mul(ADMIN_FEE_DEPOSIT_PERCENT).div(100);
      address(uint160(owner())).transfer(ownerReward);

      address(PROMOTE_ADDRESS).transfer(msg.value.div(100)); 
      address(COMPENSATIONS_ADDRESS).transfer(msg.value.div(50)); 
    }

    function reinvest() public {
      require(players[msg.sender].deposit > 0, "Nothing to reinvest");

      collect(msg.sender);
      changeDailyPercent();

      Player storage player = players[msg.sender];
      if (player.profit >= player.deposit.mul(PROFITABILITY_TRIGGER_PERCENT).div(100)) {
        player.dailyPercent = dailyPercent;
      }

      require(address(this).balance >= player.profit);
      uint256 amount = player.profit;

      player.profit = 0;
      player.deposit = player.deposit.add(amount);

      distributeRef(amount, player.referrer);
      distributeBonuses(amount, player.referrer);

      uint256 ownerReward = amount.mul(ADMIN_FEE_REINVEST_PERCENT).div(100);
      address(uint160(owner())).transfer(ownerReward);

      address(PROMOTE_ADDRESS).transfer(amount.div(100));
    }

    function withdraw() public {
      collect(msg.sender);
      require(players[msg.sender].profit > 0, "Nothing to withdraw");

      uint256 amount = players[msg.sender].profit;
      transferPayout(msg.sender, amount);

      address(PROMOTE_ADDRESS).transfer(amount.div(100));
    }

    function collect(address _addr) internal {
      Player storage player = players[_addr];

      uint256 timeDiff = now.sub(player.time);
      if (player.time > 0 && timeDiff > 0) {
        uint256 collectProfit = player.deposit.mul(timeDiff).mul(player.dailyPercent).div(100).div(1 days);
        player.profit = player.profit.add(collectProfit);
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
          player.payout = player.payout.add(payout);
          player.profit = player.profit.sub(payout);

          msg.sender.transfer(payout);

          contractBalance = contractBalance.sub(payout);
          uint256 ownerReward = payout.mul(ADMIN_FEE_WITHDRAW_PERCENT).div(100);
          ownerReward = ownerReward > contractBalance ? contractBalance : ownerReward;
          if (ownerReward > 0) {
            address(uint160(owner())).transfer(ownerReward);
          }
        }
      }
    }

    function distributeRef(uint256 _amount, address _referrer) private {
      uint256 totalReward = (_amount.mul(REFERRAL_FEE_TOTAL_PERCENT)).div(100);

      address ref = _referrer;
      uint256 refReward;
      for (uint8 i = 0; i < REFERRAL_FEE_PERCENTS.length; i++) {
        refReward = _amount.mul(REFERRAL_FEE_PERCENTS[i]).div(100);
        totalReward = totalReward.sub(refReward);

        players[ref].referralReward = players[ref].referralReward.add(refReward);
        totalReferralReward = totalReferralReward.add(refReward);

        
        address(uint160(ref)).transfer(refReward);

        ref = players[ref].referrer;
      }

      if (totalReward > 0) {
        address(uint160(owner())).transfer(totalReward);
      }
    }

    function distributeBonuses(uint256 _amount, address _referrer) private {
      address ref = _referrer;

      for (uint8 i = 0; i < LEADER_BONUS_LEVEL_PERCENTS.length; i++) {
        players[ref].leadTurnover = players[ref].leadTurnover.add(
          _amount.mul(LEADER_BONUS_LEVEL_PERCENTS[i]).div(100)
        );

        for (uint8 j = 0; j < LEADER_BONUS_TRIGGERS.length; j++) {
          if (players[ref].leadTurnover >= LEADER_BONUS_TRIGGERS[j]) {
            if (!players[ref].receivedBonuses[j]) {
              players[ref].receivedBonuses[j] = true;
              players[ref].leadBonusReward = players[ref].leadBonusReward.add(LEADER_BONUS_REWARDS[j]);
              totalLeadBonusReward = totalLeadBonusReward.add(LEADER_BONUS_REWARDS[j]);
              address(uint160(ref)).transfer(LEADER_BONUS_REWARDS[j]);
            }
          } else {
            break;
          }
        }

        ref = players[ref].referrer;
      }
    }

    function getPotencialProfit(address _addr) public view returns (uint256) {
      Player storage player = players[_addr];
      if (player.time == 0) {
        return 0;
      }

      uint256 timeDiff = now.sub(player.time);
      if (timeDiff > 0) {
        uint256 collectProfit = player.deposit.mul(timeDiff).mul(player.dailyPercent).div(100).div(1 days);

        return player.profit.add(collectProfit);
      }

      return player.profit;
    }

    function getStats() public view returns (uint256[6] memory) {
      return [
        totalPlayers,
        totalInvested,
        totalPayout,

        totalReferralReward,
        totalLeadBonusReward,

        dailyPercent
      ];
    }

    function getPlayerBonuses(address _addr) public view returns(bool[9] memory) {
      return players[_addr].receivedBonuses;
    }

    function changeDailyPercent() internal {
      
      if (dailyPercentTime != 0) {
        if (now > dailyPercentTime.add(24 hours)) {
          dailyPercent = dailyPercent.add(1);
          dailyPercentTime = now;
        }
      } else {
        dailyPercentTime = now;
      }
    }

}