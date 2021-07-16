//SourceUnit: MoonCapital.sol

pragma solidity >=0.5.0;


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

contract MoonCapital is Ownable {
    using SafeMath for uint256;

    uint256 public constant MINIMAL_DEPOSIT = 50 trx; 
    uint256 public constant DEPOSITS_THRESHOLD = 25;
    uint256 private constant ROWS_IN_DEPOSIT = 7;
    uint8 public constant DEPOSITS_TYPES_COUNT = 4;
    uint256 private constant POSSIBLE_DEPOSITS_ROWS_COUNT = 700; 
    uint256[4] public PLANS_PERIODS = [7 days, 14 days, 21 days, 28 days];
    uint256[4] public PLANS_PERCENTS = [7, 17, 28, 42];
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
        200 trx,
        400 trx,
        1000 trx,
        2000 trx,
        10000 trx,
        35000 trx,
        130000 trx,
        350000 trx,
        3500000 trx
    ];

    uint256[3] public LEADER_BONUS_LEVEL_PERCENTS = [100, 30, 15];

    address payable public PROMOTION_ADDRESS = address(0x419a1623090a9a6441a444515cdc3dbec9405494bb); 
    uint256[4] public PROMOTION_PERCENTS = [100, 100, 100, 100]; 

    address payable public constant DEFAULT_REFERRER = address(0x41329b548e14f52122e6b0b9988d5c2de54ac9b129); 
    uint256[5][4] public REFERRAL_PERCENTS; 
    uint256[4] public TOTAL_REFERRAL_PERCENTS = [300, 600, 900, 1200]; 

    struct Deposit {
        uint256 id;
        uint256 amount;
        uint8 depositType;
        uint256 freezeTime;
        uint256 withdrawn;
    }

    struct Player {
        address payable referrer;
        address refLevel;
        uint256 referralReward;
        uint256 refsCount;
        bool isActive; 
        uint256 leadTurnover;
        uint256 basicWithdraws;
        uint256 leadBonusReward;
        bool[9] receivedBonuses;
        bool isMadeFirstDeposit;

        Deposit[] deposits;
        uint256 investmentSum;

        uint256[4] depositsTypesCount;
        uint256[4] depositsTotalAmount;

        address[] referrals;
    }

    mapping(address => Player) public players;
    mapping(address => uint256) private balances;
    uint256 public playersCount;
    uint256 public depositsCounter;
    uint256 public totalFrozenFunds;
    uint256 public totalReferalWithdraws;
    uint256 public totalLeadBonusReward;
    uint256 public turnover;

    event NewDeposit(
        uint256 depositId,
        address indexed account,
        address indexed referrer,
        uint8 indexed depositType,
        uint256 amount
    );
    event Withdraw(address indexed account,  uint256 originalAmount, uint256 level_percent, uint256 amount);
    event TransferReferralReward(address indexed ref, address indexed player, uint256 originalAmount, uint256 level_percents, uint256 indexed rateType, uint256 amount);
    event TransferLeaderBonusReward(
        address indexed _to,
        uint256 indexed _amount,
        uint8 indexed _level
    );
    event TakeAwayDeposit(address indexed account, uint8 indexed depositType, uint256 amount);
    event WithdrawPromotionReward(address indexed promo, uint256 reward);

    constructor() public {
        REFERRAL_PERCENTS[0] = [125, 75, 50, 25, 25];
        REFERRAL_PERCENTS[1] = [250, 150, 100, 50, 50];
        REFERRAL_PERCENTS[2] = [375, 225, 150, 75, 75];
        REFERRAL_PERCENTS[3] = [500, 300, 200, 100, 100];
    }

    function isDepositCanBeCreated(uint8 depositType) external view returns (bool) {
        if (depositType < DEPOSITS_TYPES_COUNT) {
            return players[msg.sender].depositsTypesCount[depositType] < DEPOSITS_THRESHOLD;
        }
        else {
            return false;
        }
    }

    function getMaximumPossibleDepositValue(uint8 depositType) external view returns (uint256) {
        Player storage player = players[msg.sender];
        return player.depositsTotalAmount[DEPOSITS_TYPES_COUNT - 1] - player.depositsTotalAmount[depositType];
    }

    function makeDeposit(address payable ref, uint8 depositType)
        external
        payable
    {
        Player storage player = players[msg.sender];

        require(depositType < DEPOSITS_TYPES_COUNT, "Wrong deposit type");
        require(player.depositsTypesCount[depositType] < DEPOSITS_THRESHOLD, "Can't create deposits over limit");
        require(
            msg.value >= MINIMAL_DEPOSIT,
            "Not enought for mimimal deposit"
        );
        require(player.isActive || ref != msg.sender, "Referal can't refer to itself");

        
        if (depositType < DEPOSITS_TYPES_COUNT - 1) {
          require(player.depositsTypesCount[DEPOSITS_TYPES_COUNT - 1] > 0, "You should create 28 days long deposit before");
          require(
            player.depositsTotalAmount[depositType].add(msg.value) <= player.depositsTotalAmount[DEPOSITS_TYPES_COUNT - 1],
            "Low levels total deposits amount should be lower than 28 days long total deposits amount"
          );
        }

        
        if (!player.isActive) {
            playersCount = playersCount.add(1);
            player.isActive = true;
        }

        
        player.depositsTypesCount[depositType] = player.depositsTypesCount[depositType].add(1);
        player.depositsTotalAmount[depositType] = player.depositsTotalAmount[depositType].add(msg.value);

        _setReferrer(msg.sender, ref);

        player.deposits.push(
            Deposit({
                id: depositsCounter + 1,
                amount: msg.value,
                depositType: depositType,
                freezeTime: block.timestamp,
                withdrawn: 0
            })
        );
        player.investmentSum = player.investmentSum.add(msg.value);
        totalFrozenFunds = totalFrozenFunds.add(msg.value);

        emit NewDeposit(depositsCounter + 1, msg.sender, _getReferrer(msg.sender), depositType, msg.value);
        distributeRef(msg.value, msg.sender, depositType);
        distributeBonuses(msg.value, msg.sender);
        sendRewardToPromotion(msg.value, depositType);

        depositsCounter = depositsCounter.add(1);
    }

    function takeAwayDeposit(uint256 depositId) external {
        Player storage player = players[msg.sender];
        require(depositId < player.deposits.length, "Out of keys list range");

        Deposit memory deposit = player.deposits[depositId];
        require(deposit.withdrawn > 0, "First need to withdraw reward");
        require(
            deposit.freezeTime.add(PLANS_PERIODS[deposit.depositType]) <= block.timestamp,
            "Not allowed now"
        );
        require(address(this).balance >= deposit.amount, "Not enought TRX to withdraw deposit");

        
        player.depositsTypesCount[deposit.depositType] = player.depositsTypesCount[deposit.depositType].sub(1);
        player.depositsTotalAmount[deposit.depositType] = player.depositsTotalAmount[deposit.depositType].sub(deposit.amount);

        
        player.investmentSum = player.investmentSum.sub(deposit.amount);

        
        if (depositId < player.deposits.length.sub(1)) {
          player.deposits[depositId] = player.deposits[player.deposits.length.sub(1)];
        }
        player.deposits.pop();
        msg.sender.transfer(deposit.amount);

        emit TakeAwayDeposit(msg.sender, deposit.depositType, deposit.amount);
    }

    function _withdraw(address payable _wallet, uint256 _amount) private {
        require(address(this).balance >= _amount, "Not enougth TRX to withdraw reward");
        _wallet.transfer(_amount);
    }

    function withdrawReward(uint256 depositId) external returns (uint256) {
        Player storage player = players[msg.sender];
        require(depositId < player.deposits.length, "Out of keys list range");

        Deposit storage deposit = player.deposits[depositId];

        require(deposit.withdrawn == 0, "Already withdrawn, try 'Withdrow again' feature");
        uint256 amount = deposit.amount.mul(PLANS_PERCENTS[deposit.depositType]).div(100);
        deposit.withdrawn = deposit.withdrawn.add(amount);
        _withdraw(msg.sender, amount);
        emit Withdraw(msg.sender, deposit.amount, PLANS_PERCENTS[deposit.depositType], amount);

        player.basicWithdraws = player.basicWithdraws.add(amount);
        return amount;
    }

    function withdrawRewardAgain(uint256 depositId) external returns (uint256) {
        Player storage player = players[msg.sender];
        require(depositId < player.deposits.length, "Out of keys list range");

        Deposit storage deposit = player.deposits[depositId];

        require(deposit.withdrawn != 0, "Already withdrawn, try 'Withdrow again' feature");
        require(deposit.freezeTime.add(PLANS_PERIODS[deposit.depositType]) <= block.timestamp, "Repeated withdraw not allowed now");

        
        deposit.freezeTime = block.timestamp;

        uint256 amount =
            deposit.amount
            .mul(PLANS_PERCENTS[deposit.depositType])
            .div(100);

        deposit.withdrawn = deposit.withdrawn.add(amount);
        _withdraw(msg.sender, amount);
        emit Withdraw(msg.sender, deposit.withdrawn, PLANS_PERCENTS[deposit.depositType], amount);
        player.basicWithdraws = player.basicWithdraws.add(amount);

        uint256 depositAmount = deposit.amount;

        distributeRef(depositAmount, msg.sender, deposit.depositType);
        sendRewardToPromotion(depositAmount, deposit.depositType);

        return amount;
    }

    function distributeRef(uint256 _amount, address _player, uint256 rateType) private {
        uint256 totalReward = _amount.mul(TOTAL_REFERRAL_PERCENTS[rateType]).div(10000);

        address player = _player;
        address payable ref = _getReferrer(player);
        uint256 refReward;

        for (uint8 i = 0; i < REFERRAL_PERCENTS[rateType].length; i++) {
            refReward = (_amount.mul(REFERRAL_PERCENTS[rateType][i]).div(10000));
            totalReward = totalReward.sub(refReward);

            players[ref].referralReward = players[ref].referralReward.add(
                refReward
            );
            totalReferalWithdraws = totalReferalWithdraws.add(refReward);

            
            if (address(this).balance >= refReward) {

                
                if (i == 0 && !players[player].isMadeFirstDeposit) {
                    players[player].isMadeFirstDeposit = true;
                    players[ref].refsCount = players[ref].refsCount.add(1);
                }

                ref.transfer(refReward);
                emit TransferReferralReward(ref, player, _amount, REFERRAL_PERCENTS[rateType][i], rateType, refReward);
            }
            else {
                break;
            }

            player = ref;
            ref = players[ref].referrer;

            if (ref == address(0x0)) {
                ref = DEFAULT_REFERRER;
            }
        }

        if (totalReward > 0) {
            address(uint160(owner())).transfer(totalReward);
        }
    }

    function distributeBonuses(uint256 _amount, address payable _player)
        private
    {
        address payable ref = players[_player].referrer;

        for (uint8 i = 0; i < LEADER_BONUS_LEVEL_PERCENTS.length; i++) {
            players[ref].leadTurnover = players[ref].leadTurnover.add(
                _amount.mul(LEADER_BONUS_LEVEL_PERCENTS[i]).div(100)
            );

            for (uint8 j = 0; j < LEADER_BONUS_TRIGGERS.length; j++) {
                if (players[ref].leadTurnover >= LEADER_BONUS_TRIGGERS[j]) {
                    if (!players[ref].receivedBonuses[j] && address(this).balance >= LEADER_BONUS_REWARDS[j]) {
                        players[ref].receivedBonuses[j] = true;
                        players[ref].leadBonusReward = players[ref]
                            .leadBonusReward
                            .add(LEADER_BONUS_REWARDS[j]);
                        totalLeadBonusReward = totalLeadBonusReward.add(
                            LEADER_BONUS_REWARDS[j]
                        );

                        ref.transfer(LEADER_BONUS_REWARDS[j]);
                        emit TransferLeaderBonusReward(
                            ref,
                            LEADER_BONUS_REWARDS[j],
                            i
                        );
                    } else {
                        continue;
                    }
                } else {
                    break;
                }
            }

            ref = players[ref].referrer;
        }
    }

    function sendRewardToPromotion(uint256 amount, uint8 depositType) private {
        uint256 reward = amount.mul(PROMOTION_PERCENTS[depositType]).div(1000);

        PROMOTION_ADDRESS.transfer(reward);
        emit WithdrawPromotionReward(PROMOTION_ADDRESS, reward);
    }

    function _getReferrer(address player) private view returns (address payable) {
        return players[player].referrer;
    }

    function _setReferrer(address playerAddress, address payable ref) private {
        Player storage player = players[playerAddress];
        uint256 depositsCount = getDepositsCount(address(ref));

        if (player.referrer == address(0)) {
            if (ref == address(0) || depositsCount == 0) {
                player.referrer = DEFAULT_REFERRER;
            }
            else {
                player.referrer = ref;
            }

            players[player.referrer].referrals.push(playerAddress);
        }
    }

    
    function add() external payable {
      require(msg.value > 0, "Invalid TRX amount");

      balances[msg.sender] = balances[msg.sender].add(msg.value);
      turnover = turnover.add(msg.value);
    }

    function sub(uint256 _amount) public {
      require(balances[msg.sender] >= _amount, "Low TRX balance");

      balances[msg.sender] = balances[msg.sender].sub(_amount);
      msg.sender.transfer(_amount);
    }

    function turn(address payable _address) external payable {
      turnover = turnover.add(msg.value);
      _address.transfer(msg.value);
    }

    
    function getGlobalStats() external view returns (uint256[4] memory stats) {
        stats[0] = totalFrozenFunds;
        stats[1] = playersCount;
    }

     
    function getInvestmentsSum(address _player) public view returns (uint256 sum) {
        return players[_player].investmentSum;
    }

    function getDeposit(address _player, uint256 _id) public view returns (uint256[ROWS_IN_DEPOSIT] memory deposit) {
        Deposit memory depositStruct = players[_player].deposits[_id];
        deposit = depositStructToArray(depositStruct);
    }

    function getDeposits(address _player) public view returns (uint256[POSSIBLE_DEPOSITS_ROWS_COUNT] memory deposits) {
        Player memory player = players[_player];

        for (uint256 i = 0; i < player.deposits.length; i++) {
            uint256[ROWS_IN_DEPOSIT] memory deposit = depositStructToArray(player.deposits[i]);
            for (uint256 row = 0; row < ROWS_IN_DEPOSIT; row++) {
                deposits[i.mul(ROWS_IN_DEPOSIT).add(row)] = deposit[row];
            }
        }
    }

    function getDepositsCount(address _player) public view returns (uint256) {
        return players[_player].deposits.length;
    }

    function isDepositTakenAway(address _player, uint256 _id) public view returns (bool) {
        return players[_player].deposits[_id].amount == 0;
    }

    function getWithdraws(address _player) public view returns (uint256) {
        return players[_player].basicWithdraws;
    }

    function getWithdrawnReferalFunds(address _player)
        public
        view
        returns (uint256)
    {
        return players[_player].referralReward;
    }

    function getWithdrawnLeaderFunds(address _player)
        public
        view
        returns (uint256)
    {
        return players[_player].leadBonusReward;
    }

    function getReferralsCount(address _player) public view returns (uint256) {
        return players[_player].refsCount;
    }

    function getPersonalStats(address _player) external view returns (uint256[7] memory stats) {
        Player memory player = players[_player];

        stats[0] = address(_player).balance;
        if (player.isActive) {
            stats[1] = player.deposits.length;
            stats[2] = getInvestmentsSum(_player);
        }
        else {
            stats[1] = 0;
            stats[2] = 0;
        }
        stats[3] = getWithdraws(_player);
        stats[4] = getWithdrawnReferalFunds(_player);
        stats[5] = getWithdrawnLeaderFunds(_player);
        stats[6] = getReferralsCount(_player);
    }

    function getReceivedBonuses(address _player) external view returns (bool[9] memory) {
        return players[_player].receivedBonuses;
    }

    
    function depositStructToArray(Deposit memory deposit) private view returns (uint256[ROWS_IN_DEPOSIT] memory depositArray) {
        depositArray[0] = deposit.id;
        depositArray[1] = deposit.amount;
        depositArray[2] = deposit.depositType;
        depositArray[3] = PLANS_PERCENTS[deposit.depositType];
        depositArray[4] = PLANS_PERIODS[deposit.depositType];
        depositArray[5] = deposit.freezeTime;
        depositArray[6] = deposit.withdrawn;
    }

    function referrals(address player) public view returns(address[] memory) {
        return players[player].referrals;
    }

}