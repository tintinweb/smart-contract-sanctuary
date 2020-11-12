// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


library Math {
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract Context {
    
    
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

contract UserBonus {

    using SafeMath for uint256;

    uint256 public constant BONUS_PERCENTS_PER_WEEK = 1;
    uint256 public constant BONUS_TIME = 1 weeks;

    struct UserBonusData {
        uint256 threadPaid;
        uint256 lastPaidTime;
        uint256 numberOfUsers;
        mapping(address => bool) userRegistered;
        mapping(address => uint256) userPaid;
    }

    UserBonusData public bonus;

    event BonusPaid(uint256 users, uint256 amount);
    event UserAddedToBonus(address indexed user);

    modifier payRepBonusIfNeeded {
        payRepresentativeBonus();
        _;
    }

    constructor() public {
        bonus.lastPaidTime = block.timestamp;
    }

    function payRepresentativeBonus() public {
        while (bonus.numberOfUsers > 0 && bonus.lastPaidTime.add(BONUS_TIME) <= block.timestamp) {
            uint256 reward = address(this).balance.mul(BONUS_PERCENTS_PER_WEEK).div(100);
            bonus.threadPaid = bonus.threadPaid.add(reward.div(bonus.numberOfUsers));
            bonus.lastPaidTime = bonus.lastPaidTime.add(BONUS_TIME);
            emit BonusPaid(bonus.numberOfUsers, reward);
        }
    }

    function userRegisteredForBonus(address user) public view returns(bool) {
        return bonus.userRegistered[user];
    }

    function userBonusPaid(address user) public view returns(uint256) {
        return bonus.userPaid[user];
    }

    function userBonusEarned(address user) public view returns(uint256) {
        return bonus.userRegistered[user] ? bonus.threadPaid.sub(bonus.userPaid[user]) : 0;
    }

    function retrieveBonus() public virtual payRepBonusIfNeeded {
        require(bonus.userRegistered[msg.sender], "User not registered for bonus");

        uint256 amount = Math.min(address(this).balance, userBonusEarned(msg.sender));
        bonus.userPaid[msg.sender] = bonus.userPaid[msg.sender].add(amount);
        msg.sender.transfer(amount);
    }

    function _addUserToBonus(address user) internal payRepBonusIfNeeded {
        require(!bonus.userRegistered[user], "User already registered for bonus");

        bonus.userRegistered[user] = true;
        bonus.userPaid[user] = bonus.threadPaid;
        bonus.numberOfUsers = bonus.numberOfUsers.add(1);
        emit UserAddedToBonus(user);
    }
}

contract Claimable is Ownable {

    address public pendingOwner;

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    function renounceOwnership() public override(Ownable) onlyOwner {
        revert();
    }

    function transferOwnership(address newOwner) public override(Ownable) onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public virtual onlyPendingOwner {
        transferOwnership(pendingOwner);
        delete pendingOwner;
    }
}

contract EtherHives is Claimable, UserBonus {

    struct Player {
        uint256 registeredDate;
        bool airdropCollected;
        address referrer;
        uint256 balanceHoney;
        uint256 balanceWax;
        uint256 points;
        uint256 medals;
        uint256 qualityLevel;
        uint256 lastTimeCollected;
        uint256 unlockedBee;
        uint256[BEES_COUNT] bees;

        uint256 totalDeposited;
        uint256 totalWithdrawed;
        uint256 referralsTotalDeposited;
        uint256 subreferralsCount;
        address[] referrals;
    }

    uint256 public constant BEES_COUNT = 8;
    uint256 public constant SUPER_BEE_INDEX = BEES_COUNT - 1;
    uint256 public constant TRON_BEE_INDEX = BEES_COUNT - 2;
    uint256 public constant MEDALS_COUNT = 10;
    uint256 public constant QUALITIES_COUNT = 6;
    uint256[BEES_COUNT] public BEES_PRICES = [0e18, 1500e18, 7500e18, 30000e18, 75000e18, 250000e18, 750000e18, 100000e18];
    uint256[BEES_COUNT] public BEES_LEVELS_PRICES = [0e18, 0e18, 11250e18, 45000e18, 112500e18, 375000e18, 1125000e18, 0];
    uint256[BEES_COUNT] public BEES_MONTHLY_PERCENTS = [0, 220, 223, 226, 229, 232, 235, 333];
    uint256[MEDALS_COUNT] public MEDALS_POINTS = [0e18, 50000e18, 190000e18, 510000e18, 1350000e18, 3225000e18, 5725000e18, 8850000e18, 12725000e18, 23500000e18];
    uint256[MEDALS_COUNT] public MEDALS_REWARDS = [0e18, 3500e18, 10500e18, 24000e18, 65000e18, 140000e18, 185000e18, 235000e18, 290000e18, 800000e18];
    uint256[QUALITIES_COUNT] public QUALITY_HONEY_PERCENT = [80, 82, 84, 86, 88, 90];
    uint256[QUALITIES_COUNT] public QUALITY_PRICE = [0e18, 15000e18, 50000e18, 120000e18, 250000e18, 400000e18];

    uint256 public constant COINS_PER_ETH = 250000;
    uint256 public constant MAX_BEES_PER_TARIFF = 32;
    uint256 public constant FIRST_BEE_AIRDROP_AMOUNT = 500e18;
    uint256 public constant ADMIN_PERCENT = 10;
    uint256 public constant HONEY_DISCOUNT_PERCENT = 10;
    uint256 public constant SUPERBEE_PERCENT_UNLOCK = 5;
    uint256 public constant SUPER_BEE_BUYER_PERIOD = 7 days;
    uint256[] public REFERRAL_PERCENT_PER_LEVEL = [5, 3, 2];
    uint256[] public REFERRAL_POINT_PERCENT = [50, 25, 0];

    uint256 public maxBalance;
    uint256 public totalPlayers;
    uint256 public totalDeposited;
    uint256 public totalWithdrawed;
    uint256 public totalBeesBought;
    mapping(address => Player) public players;

    event Registered(address indexed user, address indexed referrer);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawed(address indexed user, uint256 amount);
    event ReferrerPaid(address indexed user, address indexed referrer, uint256 indexed level, uint256 amount);
    event MedalAwarded(address indexed user, uint256 indexed medal);
    event QualityUpdated(address indexed user, uint256 indexed quality);
    event RewardCollected(address indexed user, uint256 honeyReward, uint256 waxReward);
    event BeeUnlocked(address indexed user, uint256 bee);
    event BeesBought(address indexed user, uint256 bee, uint256 count);

    constructor() public {
        _register(owner(), address(0));
    }

    receive() external payable {
        if (msg.value == 0) {
            if (players[msg.sender].registeredDate > 0) {
                collect();
            }
        } else {
            deposit(address(0));
        }
    }

    function playerBees(address who) public view returns(uint256[BEES_COUNT] memory) {
        return players[who].bees;
    }

    function superBeeUnlocked() public view returns(bool) {
        return address(this).balance <= maxBalance.mul(100 - SUPERBEE_PERCENT_UNLOCK).div(100);
    }

    function referrals(address user) public view returns(address[] memory) {
        return players[user].referrals;
    }

    function referrerOf(address user, address ref) internal view returns(address) {
        if (players[user].registeredDate == 0 && ref != user) {
            return ref;
        }
        return players[user].referrer;
    }

    function transfer(address account, uint256 amount) public returns(bool) {
        require(msg.sender == owner());

        collect();

        _payWithWaxAndHoney(msg.sender, amount);
        players[account].balanceWax = players[account].balanceWax.add(amount);
        return true;
    }

    function deposit(address ref) public payable payRepBonusIfNeeded {
        Player storage player = players[msg.sender];
        address refAddress = referrerOf(msg.sender, ref);

        require((msg.value == 0) != player.registeredDate > 0, "Send 0 for registration");

        
        if (player.registeredDate == 0) {
            _register(msg.sender, refAddress);
        }

        collect();

        
        uint256 wax = msg.value.mul(COINS_PER_ETH);
        player.balanceWax = player.balanceWax.add(wax);
        player.totalDeposited = player.totalDeposited.add(msg.value);
        totalDeposited = totalDeposited.add(msg.value);
        player.points = player.points.add(wax);
        emit Deposited(msg.sender, msg.value);

        

        _distributeFees(msg.sender, wax, msg.value, refAddress);

        _addToBonusIfNeeded(msg.sender);

        uint256 adminWithdrawed = players[owner()].totalWithdrawed;
        maxBalance = Math.max(maxBalance, address(this).balance.add(adminWithdrawed));
    }

    function withdraw(uint256 amount) public {
        Player storage player = players[msg.sender];

        collect();

        uint256 value = amount.div(COINS_PER_ETH);
        require(value > 0, "Trying to withdraw too small");
        player.balanceHoney = player.balanceHoney.sub(amount);
        player.totalWithdrawed = player.totalWithdrawed.add(value);
        totalWithdrawed = totalWithdrawed.add(value);
        msg.sender.transfer(value);
        emit Withdrawed(msg.sender, value);
    }

    function collect() public payRepBonusIfNeeded {
        Player storage player = players[msg.sender];
        require(player.registeredDate > 0, "Not registered yet");

        if (userBonusEarned(msg.sender) > 0) {
            retrieveBonus();
        }

        (uint256 balanceHoney, uint256 balanceWax) = instantBalance(msg.sender);
        emit RewardCollected(
            msg.sender,
            balanceHoney.sub(player.balanceHoney),
            balanceWax.sub(player.balanceWax)
        );

        if (!player.airdropCollected && player.registeredDate < now) {
            player.airdropCollected = true;
        }

        player.balanceHoney = balanceHoney;
        player.balanceWax = balanceWax;
        player.lastTimeCollected = block.timestamp;
    }

    function instantBalance(address account)
        public
        view
        returns(
            uint256 balanceHoney,
            uint256 balanceWax
        )
    {
        Player storage player = players[account];
        if (player.registeredDate == 0) {
            return (0, 0);
        }

        balanceHoney = player.balanceHoney;
        balanceWax = player.balanceWax;

        uint256 collected = earned(account);
        if (!player.airdropCollected && player.registeredDate < now) {
            collected = collected.sub(FIRST_BEE_AIRDROP_AMOUNT);
            balanceWax = balanceWax.add(FIRST_BEE_AIRDROP_AMOUNT);
        }

        uint256 honeyReward = collected.mul(QUALITY_HONEY_PERCENT[player.qualityLevel]).div(100);
        uint256 waxReward = collected.sub(honeyReward);

        balanceHoney = balanceHoney.add(honeyReward);
        balanceWax = balanceWax.add(waxReward);
    }

    function unlock(uint256 bee) public payable payRepBonusIfNeeded {
        Player storage player = players[msg.sender];

        if (msg.value > 0) {
            deposit(address(0));
        }

        collect();

        require(bee < SUPER_BEE_INDEX, "No more levels to unlock"); 
        require(player.bees[bee - 1] == MAX_BEES_PER_TARIFF, "Prev level must be filled");
        require(bee == player.unlockedBee + 1, "Trying to unlock wrong bee type");

        if (bee == TRON_BEE_INDEX) {
            require(player.medals >= 9);
        }
        _payWithWaxAndHoney(msg.sender, BEES_LEVELS_PRICES[bee]);
        player.unlockedBee = bee;
        player.bees[bee] = 1;
        emit BeeUnlocked(msg.sender, bee);
    }

    function buyBees(uint256 bee, uint256 count) public payable payRepBonusIfNeeded {
        Player storage player = players[msg.sender];

        if (msg.value > 0) {
            deposit(address(0));
        }

        collect();

        require(bee > 0 && bee < BEES_COUNT, "Don't try to buy bees of type 0");
        if (bee == SUPER_BEE_INDEX) {
            require(superBeeUnlocked(), "SuperBee is not unlocked yet");
            require(block.timestamp.sub(player.registeredDate) < SUPER_BEE_BUYER_PERIOD, "You should be registered less than 7 days ago");
        } else {
            require(bee <= player.unlockedBee, "This bee type not unlocked yet");
        }

        require(player.bees[bee].add(count) <= MAX_BEES_PER_TARIFF);
        player.bees[bee] = player.bees[bee].add(count);
        totalBeesBought = totalBeesBought.add(count);
        uint256 honeySpent = _payWithWaxAndHoney(msg.sender, BEES_PRICES[bee].mul(count));

        _distributeFees(msg.sender, honeySpent, 0, referrerOf(msg.sender, address(0)));

        emit BeesBought(msg.sender, bee, count);
    }

    function updateQualityLevel() public payRepBonusIfNeeded {
        Player storage player = players[msg.sender];

        collect();

        require(player.qualityLevel < QUALITIES_COUNT - 1);
        _payWithHoneyOnly(msg.sender, QUALITY_PRICE[player.qualityLevel + 1]);
        player.qualityLevel++;
        emit QualityUpdated(msg.sender, player.qualityLevel);
    }

    function earned(address user) public view returns(uint256) {
        Player storage player = players[user];
        if (player.registeredDate == 0) {
            return 0;
        }

        uint256 total = 0;
        for (uint i = 1; i < BEES_COUNT; i++) {
            total = total.add(
                player.bees[i].mul(BEES_PRICES[i]).mul(BEES_MONTHLY_PERCENTS[i]).div(100)
            );
        }

        return total
            .mul(block.timestamp.sub(player.lastTimeCollected))
            .div(30 days)
            .add(player.airdropCollected || player.registeredDate == now ? 0 : FIRST_BEE_AIRDROP_AMOUNT);
    }

    function collectMedals(address user) public payRepBonusIfNeeded {
        Player storage player = players[user];

        collect();

        for (uint i = player.medals; i < MEDALS_COUNT; i++) {
            if (player.points >= MEDALS_POINTS[i]) {
                player.balanceWax = player.balanceWax.add(MEDALS_REWARDS[i]);
                player.medals = i + 1;
                emit MedalAwarded(user, i + 1);
            }
        }
    }

    function retrieveBonus() public override(UserBonus) {
        totalWithdrawed = totalWithdrawed.add(userBonusEarned(msg.sender));
        super.retrieveBonus();
    }

    function claimOwnership() public override(Claimable) {
        super.claimOwnership();
        _register(owner(), address(0));
    }

    function _distributeFees(address user, uint256 wax, uint256 deposited, address refAddress) internal {
        
        address(uint160(owner())).transfer(wax * ADMIN_PERCENT / 100 / COINS_PER_ETH);

        
        if (refAddress != address(0)) {
            Player storage referrer = players[refAddress];
            referrer.referralsTotalDeposited = referrer.referralsTotalDeposited.add(deposited);
            _addToBonusIfNeeded(refAddress);

            
            address to = refAddress;
            for (uint i = 0; to != address(0) && i < REFERRAL_PERCENT_PER_LEVEL.length; i++) {
                uint256 reward = wax.mul(REFERRAL_PERCENT_PER_LEVEL[i]).div(100);
                players[to].balanceHoney = players[to].balanceHoney.add(reward);
                players[to].points = players[to].points.add(wax.mul(REFERRAL_POINT_PERCENT[i]).div(100));
                emit ReferrerPaid(user, to, i + 1, reward);
                

                to = players[to].referrer;
            }
        }
    }

    function _register(address user, address refAddress) internal {
        Player storage player = players[user];

        player.registeredDate = block.timestamp;
        player.bees[0] = MAX_BEES_PER_TARIFF;
        player.unlockedBee = 1;
        player.lastTimeCollected = block.timestamp;
        totalBeesBought = totalBeesBought.add(MAX_BEES_PER_TARIFF);
        totalPlayers++;

        if (refAddress != address(0)) {
            player.referrer = refAddress;
            players[refAddress].referrals.push(user);

            if (players[refAddress].referrer != address(0)) {
                players[players[refAddress].referrer].subreferralsCount++;
            }

            _addToBonusIfNeeded(refAddress);
        }
        emit Registered(user, refAddress);
    }

    function _payWithHoneyOnly(address user, uint256 amount) internal {
        Player storage player = players[user];
        player.balanceHoney = player.balanceHoney.sub(amount);
    }

    function _payWithWaxOnly(address user, uint256 amount) internal {
        Player storage player = players[user];
        player.balanceWax = player.balanceWax.sub(amount);
    }

    function _payWithWaxAndHoney(address user, uint256 amount) internal returns(uint256) {
        Player storage player = players[user];

        uint256 wax = Math.min(amount, player.balanceWax);
        uint256 honey = amount.sub(wax).mul(100 - HONEY_DISCOUNT_PERCENT).div(100);

        player.balanceWax = player.balanceWax.sub(wax);
        _payWithHoneyOnly(user, honey);

        return honey;
    }

    function _addToBonusIfNeeded(address user) internal {
        if (user != address(0) && !bonus.userRegistered[user]) {
            Player storage player = players[user];

            if (player.totalDeposited >= 5 ether &&
                player.referrals.length >= 10 &&
                player.referralsTotalDeposited >= 50 ether)
            {
                _addUserToBonus(user);
            }
        }
    }
}