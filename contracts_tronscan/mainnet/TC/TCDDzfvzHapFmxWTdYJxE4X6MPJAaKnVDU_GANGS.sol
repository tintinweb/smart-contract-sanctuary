//SourceUnit: v_15.sol

pragma solidity 0.5.10;

contract GANGS {
    using SafeMath for uint256;

    address public owner;

    uint256 constant public OWNER_PERCENT = 10;
    uint256 constant public REF_PERCENT = 10;

    uint256 public constant AIRDROP_COLLECT_TIME_PAUSE = 8 hours;
    uint256 public constant USUAL_COLLECT_TIME_PAUSE =  1 hours;
    uint256 public constant BANDITS_PROFITS_DIVIDED = 30 * 24 hours;

    uint256 public constant BANDITS_TYPES = 7;
    uint256 public constant BANDITS_LEVELS = 6;
    uint256 public constant STARS = 10;

    uint256 public REP_PER_TRX = 50;
    uint256 public CASH_FOR_TRX = 50;

    uint256 public constant REP_AND_CASH_DECIMALS = 6;

    uint32[BANDITS_TYPES] public BANDITS_PRICES = [5000, 25000, 125000, 250000, 500000, 2500000, 500000];

    uint32[BANDITS_TYPES] public BANDITS_PROFITS_PERCENTS = [200, 205, 212, 220, 230, 250, 280];

    uint32[BANDITS_LEVELS] public BANDITS_LEVELS_CASH_PERCENTS = [40, 42, 44, 46, 48, 50];
    uint32[BANDITS_LEVELS] public BANDITS_LEVELS_PRICES = [0, 35000, 100000, 210000, 425000, 850000];

    uint32[BANDITS_TYPES] public BANDIT_GANGS_PRICES = [0, 12500, 50000, 150000, 500000, 1250000, 0];

    uint32[STARS + 1] public STARS_POINTS = [0, 50000, 185000, 500000, 1350000, 3250000, 5750000, 8750000, 12750000, 25000000];
    uint32[STARS + 1] public STARS_REWARD = [0, 5000, 12500, 25000, 65000, 135000, 185000, 235000, 285000, 750000];

    uint256 public BRIBERY_PRICE = 2500000;

    uint256 public maxTrxOnContract;
    bool public criticalTrxBalance;

    struct BanditGang {
        bool unlocked;
        uint256 totalBandits;
        uint256 unlockedTime;
    }

    struct PlayerRef {
        address referral;
        uint256 cash;
        uint256 points;
    }

    struct PlayerBalance {
        uint256 rep;
        uint256 cash;
        uint256 points;
        uint64 collectedStar;
        uint64 level;

        address referrer;
        uint256 referrerIndex;

        uint256 referralsCount;
        PlayerRef[] referralsArray;

        uint256 airdropUnlockedTime;
        uint256 airdropCollectedTime;

        uint256 banditsCollectedTime;
        uint256 banditsTotalPower;
        BanditGang[BANDITS_TYPES] banditGangs;

        bool bribed;
    }

    mapping(address => PlayerBalance) public playerBalances;
    mapping (address => uint256[2]) stat;

    uint256 public balanceForAdmin;

    uint256 public statTotalInvested;
    uint256 public statTotalSold;
    uint256 public statTotalPlayers;
    uint256 public statTotalBandits;
    uint256 public statMaxReferralsCount;
    address public statMaxReferralsReferrer;

    address[] public statPlayers;

    event repBought(address indexed player, uint256 _trx, uint256 rep);
    event copBribed(address indexed player);
    event cashSold(address indexed player, uint256 cash, uint256 _trx);
    event starCollected(address indexed player, uint256 rep);
    event airdropUnlocked(address indexed player);
    event gangUnlocked(address indexed player, uint256 gang);
    event airdropCollected(address indexed player, uint256 rep);
    event banditBought(address indexed player, uint256 gang, uint256 totalBandits);
    event levelBought(address indexed player, uint256 level);
    event allCollected(address indexed player, uint256 cash, uint256 rep);
    event operation(address indexed player, uint256 amount, string _type);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address initialOwner) public {
        require(initialOwner != address(0));
        owner = initialOwner;
    }

    function() external payable {
        buyRep();
    }

    function buyRep() payable public returns (bool success) {
        require(msg.value > 0, "please pay something");
        uint256 _rep = msg.value;
        _rep = _rep.mul(REP_PER_TRX);

        uint256 _payment = msg.value.mul(OWNER_PERCENT).div(100);
        balanceForAdmin = (balanceForAdmin.add(_payment));

        PlayerBalance storage player = playerBalances[msg.sender];
        PlayerBalance storage referrer = playerBalances[player.referrer];

        player.rep = (player.rep.add(_rep));
        player.points = (player.points.add(_rep));
        if (player.collectedStar < 1) {
            player.collectedStar = 1;
        }
        if (player.referrer != address(0)) {
            uint256 _ref = _rep.mul(REF_PERCENT).div(100);
            referrer.points = (referrer.points.add(_ref));
            referrer.cash = (referrer.cash.add(_ref));
            uint256 _index = player.referrerIndex;
            referrer.referralsArray[_index].cash = (referrer.referralsArray[_index].cash.add(_ref));
        }
        if (maxTrxOnContract <= address(this).balance) {
            maxTrxOnContract = address(this).balance;
            criticalTrxBalance = false;
        }

        statTotalInvested = (statTotalInvested.add(msg.value));
        stat[msg.sender][0] = stat[msg.sender][0].add(msg.value);

        emit repBought(msg.sender, msg.value, _rep);
        emit operation(msg.sender, msg.value, "invest");

        return true;
    }

    function bribeCop() payable public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];

        require(!player.bribed, "Cop is bribed already");

        uint256 briberyPrice = BRIBERY_PRICE.mul(10 ** REP_AND_CASH_DECIMALS);

        _payRep(briberyPrice);

        player.bribed = true;

        if (maxTrxOnContract <= address(this).balance) {
            maxTrxOnContract = address(this).balance;
            criticalTrxBalance = false;
        }

        statTotalInvested = (statTotalInvested.add(msg.value));
        stat[msg.sender][0] = stat[msg.sender][0].add(msg.value);

        emit copBribed(msg.sender);
        emit operation(msg.sender, msg.value, "bribery");

        return true;
    }

    function _payRep(uint256 _rep) internal {
        uint256 rep = _rep;
        PlayerBalance storage player = playerBalances[msg.sender];
        if (player.rep < _rep) {
            uint256 cash = _rep.sub(player.rep);
            _payCash(cash);
            rep = player.rep;
        }
        if (rep > 0) {
            player.rep = player.rep.sub(rep);
        }
    }

    function _payCash(uint256 _cash) internal {
        PlayerBalance storage player = playerBalances[msg.sender];

        player.cash = player.cash.sub(_cash);
    }

    function withdrawAdminBalance(uint256 _value) external onlyOwner {
        balanceForAdmin = (balanceForAdmin.sub(_value));
        statTotalSold = (statTotalSold.add(_value));
        address(msg.sender).transfer(_value);

        if (address(this).balance < maxTrxOnContract.mul(70).div(100))  {
            criticalTrxBalance = true;
        }
    }

    function sellCash(uint256 _cash) public returns (bool success) {
        require(_cash > 0, "couldnt sell zero");
        require(_collectAll(), "problems with collect all before unlock gang");
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256 money = _cash.div(CASH_FOR_TRX);
        require(address(this).balance >= money, "couldnt sell more than total trx balance");
        player.cash = (player.cash.sub(_cash));
        address(msg.sender).transfer(money);
        stat[msg.sender][1] = stat[msg.sender][1].add(money);
        statTotalSold = (statTotalSold.add(money));
        if (address(this).balance < maxTrxOnContract.mul(70).div(100))  {
            criticalTrxBalance = true;
        }

        emit cashSold(msg.sender, _cash, money);
        emit operation(msg.sender, money, "withdraw");

        return true;
    }

    function collectStar() public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint64 star = player.collectedStar;
        require(star < STARS, "no stars left");
        uint256 pointToHave = STARS_POINTS[star];
        pointToHave = pointToHave.mul(1000000);
        require(player.points >= pointToHave, "not enough points");
        uint256 _rep = STARS_REWARD[star];
        if (_rep > 0) {
            _rep = _rep.mul(10 ** REP_AND_CASH_DECIMALS);
            player.rep = player.rep.add(_rep);
        }
        player.collectedStar = star + 1;

        emit starCollected(msg.sender, _rep);

        return true;
    }

    function unlockAirdropBandit(address _referrer) public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        require(player.airdropUnlockedTime == 0, "couldnt unlock already unlocked");

        if (playerBalances[_referrer].airdropUnlockedTime > 0 || _referrer == address(0x5332f73842f11f49219763c99757C8a31DCA0582)) {
            player.referrer = _referrer;
            require(playerBalances[_referrer].referralsCount + 1 > playerBalances[_referrer].referralsCount, "no overflow");
            playerBalances[_referrer].referralsArray.push(PlayerRef(msg.sender, 0, 0));
            player.referrerIndex =  playerBalances[_referrer].referralsCount;
            playerBalances[_referrer].referralsCount++;
            if (playerBalances[_referrer].referralsCount > statMaxReferralsCount) {
                statMaxReferralsCount = playerBalances[_referrer].referralsCount;
                statMaxReferralsReferrer = msg.sender;
            }
        }

        player.airdropUnlockedTime = now;
        player.airdropCollectedTime = now;
        player.banditGangs[0].unlocked = true;
        player.banditGangs[0].unlockedTime = now;
        statTotalBandits = (statTotalBandits.add(1));
        player.collectedStar += 1;
        player.banditsCollectedTime = now;

        statTotalPlayers = (statTotalPlayers.add(1));
        statPlayers.push(msg.sender);

        emit airdropUnlocked(msg.sender);

        return true;
    }

    function unlockGang(uint256 _gang) public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];

        require(_gang < 6, "coulnt unlock out of range");
        require(player.banditGangs[0].unlocked, "unlock airdrop bandit first");
        require(!player.banditGangs[_gang].unlocked, "coulnt unlock already unlocked");
        if (_gang == 5) {
            require(player.collectedStar >= 9, "platinum star required");
        }
        require(_collectAll(), "problems with collect all before unlock gang");
        uint256 _rep = BANDIT_GANGS_PRICES[_gang];
        _rep = _rep.mul(10 ** REP_AND_CASH_DECIMALS);
        _payRep(_rep);
        if (player.banditsCollectedTime != now) {
            player.banditsCollectedTime = now;
        }
        player.banditGangs[_gang].unlocked = true;
        player.banditGangs[_gang].unlockedTime = now;
        player.banditGangs[_gang].totalBandits = 1;
        player.banditsTotalPower = (player.banditsTotalPower.add(_getBanditPower(_gang)));
        statTotalBandits = (statTotalBandits.add(1));

        emit gangUnlocked(msg.sender, _gang);

        return true;
    }

    function buyBandit(uint256 _gang) public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        if (_gang == 6) {
            require(criticalTrxBalance, "only when critical trx flag is on");
        } else {
            require(player.banditGangs[_gang].unlocked, "coulnt buy in locked gang");
        }
        require(_collectAll(), "problems with collect all before buy");
        uint256 _rep = BANDITS_PRICES[_gang];
        _rep = _rep.mul(10 ** REP_AND_CASH_DECIMALS);
        _payRep(_rep);
        if (player.banditsCollectedTime != now) {
            player.banditsCollectedTime = now;
        }
        player.banditGangs[_gang].totalBandits++;
        player.banditsTotalPower = (player.banditsTotalPower.add(_getBanditPower(_gang)));
        statTotalBandits = (statTotalBandits.add(1));

        emit banditBought(msg.sender, _gang, player.banditGangs[_gang].totalBandits);

        return true;
    }

    function buyLevel() public returns (bool success) {
        require(_collectAll(), "problems with collect all before level up");
        PlayerBalance storage player = playerBalances[msg.sender];
        uint64 level = player.level + 1;
        require(level < BANDITS_LEVELS, "couldnt go level more than maximum");
        uint256 _cash = BANDITS_LEVELS_PRICES[level];
        _cash = _cash.mul(10 ** REP_AND_CASH_DECIMALS);
        _payCash(_cash);
        player.level = level;

        emit levelBought(msg.sender, level);

        return true;
    }

    function collectAirdrop() public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        require(player.airdropUnlockedTime > 0, "should be unlocked");
        require(now - player.airdropUnlockedTime >= AIRDROP_COLLECT_TIME_PAUSE, "should be unlocked");
        require(player.airdropCollectedTime == 0 || now - player.airdropCollectedTime >= AIRDROP_COLLECT_TIME_PAUSE, "should be never collected before or more then 8 hours from last collect");
        uint256 _rep = (10 ** REP_AND_CASH_DECIMALS).mul(250);
        player.airdropCollectedTime = now;
        player.rep = (player.rep.add(_rep));

        emit airdropCollected(msg.sender, _rep);

        return true;
    }

    function collectProducts() public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256 passTime = now - player.banditsCollectedTime;
        require(passTime >= USUAL_COLLECT_TIME_PAUSE, "should wait a little bit");
        return _collectAll();
    }

    function _getBanditPower(uint256 _gang) public view returns (uint256) {
        return BANDITS_PROFITS_PERCENTS[_gang] * BANDITS_PRICES[_gang];
    }

    function _getCollectAllAvailable() public view returns (uint256, uint256) {
        PlayerBalance storage player = playerBalances[msg.sender];

        uint256 monthlyIncome = player.banditsTotalPower.div(100).mul(10 ** REP_AND_CASH_DECIMALS);
        uint256 passedTime = now.sub(player.banditsCollectedTime);
        uint256 income = monthlyIncome.mul(passedTime).div(BANDITS_PROFITS_DIVIDED);

        if (player.bribed) {
            income = income.mul(110).div(100);
        }

        uint256 _cash = income.mul(BANDITS_LEVELS_CASH_PERCENTS[player.level]).div(100);
        uint256 _rep = income.sub(_cash);

        return (_cash, _rep);
    }

    function _collectAll() internal returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256 _cash;
        uint256 _rep;
        (_cash, _rep) = _getCollectAllAvailable();
        if (_rep > 0 || _cash > 0) {
            player.banditsCollectedTime = now;
        }
        if (_rep > 0) {
            player.rep = player.rep.add(_rep);
        }
        if (_cash > 0) {
            player.cash = player.cash.add(_cash);
        }

        emit allCollected(msg.sender, _cash, _rep);

        return true;
    }

    function getGameStats() public view returns (uint256[] memory, address) {
        uint256[] memory combined = new uint256[](5);
        combined[0] = statTotalInvested;
        combined[1] = statTotalSold;
        combined[2] = statTotalPlayers;
        combined[3] = statTotalBandits;
        combined[4] = statMaxReferralsCount;
        return (combined, statMaxReferralsReferrer);
    }

    function getBanditGangFullInfo(uint256 _gang) public view returns (uint256[] memory) {
        uint256[] memory combined = new uint256[](5);

        PlayerBalance storage player = playerBalances[msg.sender];

        combined[0] = player.banditGangs[_gang].unlocked ? 1 : 0;
        combined[1] = player.banditGangs[_gang].totalBandits;
        combined[2] = player.banditGangs[_gang].unlockedTime;
        combined[3] = player.banditsTotalPower;
        combined[4] = player.banditsCollectedTime;
        if (_gang == 6) {
          combined[0] = criticalTrxBalance ? 1 : 0;
        }
        return combined;
    }

    function getPlayersInfo() public view returns (address[] memory, uint256[] memory) {
        address[] memory combinedA = new address[](statTotalPlayers);
        uint256[] memory combinedB = new uint256[](statTotalPlayers);
        for (uint256 i=0; i<statTotalPlayers; i++) {
            combinedA[i] = statPlayers[i];
            combinedB[i] = playerBalances[statPlayers[i]].banditsTotalPower;
        }
        return (combinedA, combinedB);
    }

    function getReferralsInfo() public view returns (address[] memory, uint256[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];

        address[] memory combinedA = new address[](player.referralsCount);
        uint256[] memory combinedB = new uint256[](player.referralsCount);
        for (uint256 i=0; i<player.referralsCount; i++) {
            combinedA[i] = player.referralsArray[i].referral;
            combinedB[i] = player.referralsArray[i].cash;
        }
        return (combinedA, combinedB);
    }

    function getReferralsNumber(address _address) public view returns (uint256) {
        return playerBalances[_address].referralsCount;
    }

    function getReferralsNumbersList(address[] memory _addresses) public view returns (uint256[] memory) {
        uint256[] memory counters = new uint256[](_addresses.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            counters[i] = playerBalances[_addresses[i]].referralsCount;
        }

        return counters;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function playerUnlockedInfo(address _referrer) public view returns (uint256) {
        return playerBalances[_referrer].banditGangs[0].unlocked ? 1 : 0;
    }

    function collectStarInfo() public view returns (uint256[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];

        uint256[] memory combined = new uint256[](5);
        uint64 star = player.collectedStar;
        if (star >= STARS) {
            combined[0] = 1;
            combined[1] = star + 1;
            return combined;
        }

        combined[1] = star + 1;
        combined[2] = player.points;
        uint256 pointToHave = STARS_POINTS[star];
        combined[3] = pointToHave.mul(1000000);
        combined[4] = STARS_REWARD[star];
        combined[4] = combined[4].mul(1000000);

        if (player.points < combined[3]) {
            combined[0] = 2;
            return combined;
        }
        return combined;
    }

    function unlockGangInfo(uint256 _gang) public view returns (uint256[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256[] memory combined = new uint256[](4);
        if (_gang == 6) {
            if (!criticalTrxBalance) {
                combined[0] = 88;
                return combined;
            }
        } else {
            if (player.banditGangs[_gang].unlocked) {
                combined[0] = 2;
                return combined;
            }
            if (_gang == 5) {
                if (player.collectedStar < 9) {
                    combined[0] = 77;
                    return combined;
                }
            }
        }
        uint256 _rep = BANDIT_GANGS_PRICES[_gang];
        _rep = _rep.mul(10 ** REP_AND_CASH_DECIMALS);
        uint256 _new_cash;
        uint256 _new_rep;
        (_new_cash, _new_rep) = _getCollectAllAvailable();
        combined[1] = _rep;
        combined[2] = _rep;
        if (player.rep + _new_rep < _rep) {
            combined[2] = player.rep + _new_rep;
            combined[3] = _rep - combined[2];
            if (player.cash + _new_cash < combined[3]) {
                combined[0] = 55;
            }
        }
        return combined;
    }

    function buyBanditInfo(uint256 _gang) public view returns (uint256[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256[] memory combined = new uint256[](4);
        if (_gang == 6) {
            if (!criticalTrxBalance) {
                combined[0] = 88;
                return combined;
            }
        } else {
            if (!player.banditGangs[_gang].unlocked) {
                combined[0] = 1;
                return combined;
            }
        }
        uint256 _rep = BANDITS_PRICES[_gang];
        _rep = _rep.mul(10 ** REP_AND_CASH_DECIMALS);
        uint256 _new_cash;
        uint256 _new_rep;
        (_new_cash, _new_rep) = _getCollectAllAvailable();
        combined[1] = _rep;
        combined[2] = _rep;
        if (player.rep + _new_rep < _rep) {
            combined[2] = player.rep + _new_rep;
            combined[3] = _rep - combined[2];
            if (player.cash + _new_cash < combined[3]) {
                combined[0] = 55;
            }
        }
        return combined;
    }


    function buyLevelInfo() public view returns (uint256[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256[] memory combined = new uint256[](4);
        if (player.level + 1 >= BANDITS_LEVELS) {
            combined[0] = 2;
            return combined;
        }
        combined[1] = player.level + 1;
        uint256 _cash = BANDITS_LEVELS_PRICES[combined[1]];
        _cash = _cash.mul(10 ** REP_AND_CASH_DECIMALS);
        combined[2] = _cash;

        uint256 _new_cash;
        uint256 _new_rep;
        (_new_cash, _new_rep) = _getCollectAllAvailable();
        if (player.cash + _new_cash < _cash) {
            combined[0] = 55;
        }

        return combined;
    }

    function collectAirdropInfo() public view returns (uint256[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256[] memory combined = new uint256[](3);
        if (player.airdropUnlockedTime == 0) {
            combined[0] = 1;
            return combined;
        }
        if (now - player.airdropUnlockedTime < AIRDROP_COLLECT_TIME_PAUSE) {
            combined[0] = 10;
            combined[1] = now - player.airdropUnlockedTime;
            combined[2] = AIRDROP_COLLECT_TIME_PAUSE - combined[1];
            return combined;
        }
        if (player.airdropCollectedTime != 0 && now - player.airdropCollectedTime < AIRDROP_COLLECT_TIME_PAUSE) {
            combined[0] = 11;
            combined[1] = now - player.airdropCollectedTime;
            combined[2] = AIRDROP_COLLECT_TIME_PAUSE - combined[1];
            return combined;
        }
        uint256 _rep = (10 ** REP_AND_CASH_DECIMALS).mul(250);
        combined[0] = 0;
        combined[1] = _rep;
        combined[2] = 0;
        if (player.rep + _rep < player.rep) {
            combined[0] = 255;
            return combined;
        }
        return combined;

    }

    function collectProductsInfo() public view returns (uint256[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256[] memory combined = new uint256[](3);
        if (!(player.banditsCollectedTime > 0)) {
            combined[0] = 3;
            return combined;
        }

        uint256 passTime = now - player.banditsCollectedTime;
        if (passTime < USUAL_COLLECT_TIME_PAUSE) {
            combined[0] = 11;
            combined[1] = passTime;
            combined[2] = USUAL_COLLECT_TIME_PAUSE - combined[1];
            return combined;
        }

        uint256 _cash;
        uint256 _rep;
        (_cash, _rep) = _getCollectAllAvailable();

        combined[0] = 0;
        combined[1] = _rep;
        combined[2] = _cash;
        if (player.rep + _rep < player.rep) {
            combined[0] = 255;
            return combined;
        }
        return combined;
    }

    function getStat(address addr) public view returns (uint256, uint256) {
        return (stat[addr][0], stat[addr][1]);
    }

    function getIncome(address addr) public view returns (uint256, uint256) {
        PlayerBalance storage player = playerBalances[addr];

        uint256 hourlyIncome = player.banditsTotalPower.div(100).mul(10 ** REP_AND_CASH_DECIMALS).div(720);

        if (player.bribed) {
            hourlyIncome = hourlyIncome.mul(110).div(100);
        }
        uint256 _cash = hourlyIncome.mul(BANDITS_LEVELS_CASH_PERCENTS[player.level]).div(100);
        uint256 _rep = hourlyIncome.sub(_cash);

        if (player.airdropUnlockedTime > 0) {
            _rep = _rep.add((10 ** REP_AND_CASH_DECIMALS).mul(250).div(8));
        }

        return (_rep, _cash);
    }

    function getReferralList(address addr) public view returns (address[] memory, uint256[] memory) {
        PlayerBalance storage player = playerBalances[addr];

        address[] memory referrals = new address[](player.referralsArray.length);
        uint256[] memory amounts = new uint256[](player.referralsArray.length);

        for (uint256 i = 0; i < player.referralsArray.length; i++) {
            referrals[i] = player.referralsArray[i].referral;
        }

        for (uint256 i = 0; i < player.referralsArray.length; i++) {
            amounts[i] = stat[player.referralsArray[i].referral][0];
        }

        return (referrals, amounts);
    }

    function getAmountOfBandits(address addr) public view returns (uint256[] memory) {
        PlayerBalance storage player = playerBalances[addr];

        uint256[] memory amounts = new uint256[](BANDITS_TYPES);

        for (uint256 i = 0; i < BANDITS_TYPES; i++) {
            amounts[i] = player.banditGangs[i].totalBandits;
        }

        return amounts;
    }

    function getAvailable(address addr) public view returns (uint256, uint256) {
        PlayerBalance storage player = playerBalances[addr];

        uint256 _cash;
        uint256 _rep;

        (_cash, _rep) = _getCollectAllAvailable();

        return (_cash.add(player.cash), _rep.add(player.rep));
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