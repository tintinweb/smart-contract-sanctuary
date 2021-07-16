//SourceUnit: BeeHiveAPIS.sol

pragma solidity >=0.5.4;


contract Owned {
    address payable public owner;
    address payable public newOwner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this method");
        _;
    }

    function changeOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "should be newOwner to accept");
        owner = newOwner;
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

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ITokenRecipient {
  
  function tokenFallback(address _from, uint256 _value, bytes memory _data) public returns (bool);
}

contract Balances is Owned, ITokenRecipient {
    using SafeMath for uint256;

    uint256 public constant INITIAL_AUCTION_DEPOSIT = 200000; 

    uint public constant WAX_AND_HONEY_DECIMALS = 6; 

    uint public constant AIRDROP_COLLECT_TIME_PAUSE = 24 hours;
    uint public constant USUAL_COLLECT_TIME_PAUSE =  1 hours;
    uint public constant BEES_PROFITS_DIVIDED = 30 * 24  hours;
    uint public constant BEES_PER_BOX = 32;

    uint public constant BEES_TYPES = 7; 
    uint public constant BEES_LEVELS = 6;
    uint public constant MEDALS = 10;

    uint public WAX_PER_APIS = 25;
    uint public HONEY_FOR_APIS = 25;

    uint256 public MaxContractBalance = 0;
    uint256 public MaxContractBalance75 = 0;
    bool public CriticalContractBalance = false;

    uint256 constant public ADMIN_PERCENT = 10;
    uint256[8] public REF_PERCENTS = [300, 200, 100, 100, 50, 50, 25, 25];

    address constant public DEFAULT_REFERRER_ADDRESS = address(0x4119c5ba914966e468ae774e6bcd9926d3abe282a2);

    struct BeeBox {
        bool unlocked;
        uint256 totalBees;
        uint256 unlockedTime;
    }

    struct PlayerRef {
        address referral;
        uint256 honey;
    }

    struct PlayerBalance {
        uint256 wax;
        uint256 honey;
        uint256 points;
        uint64 collectedMedal;
        uint64 level;

        address referer;
        uint256 refererIndex;

        uint256 referralsCount;
        PlayerRef[] referralsArray;

        uint256 airdropUnlockedTime;
        uint256 airdropCollectedTime;

        uint256 beesCollectedTime;
        uint256 beesTotalPower;
        BeeBox[BEES_TYPES] beeBoxes;

        uint256 totalInvested;
        uint256 totalWithdrawn;
    }

    mapping (address => uint256) public referralAPISAmounts;

    mapping(address => PlayerBalance) public playerBalances;

    uint256 public statTotalInvested = 0; 
    uint256 public statTotalSold = 0; 
    uint256 public statTotalPlayers = 0; 
    uint256 public statTotalBees = 0; 
    uint256 public statMaxReferralsCount = 0; 
    address public statMaxReferralsReferer; 

    address[] public statPlayers; 

    address public constant TOKEN_CONTRACT_ADDRESS = address(0x4154be3a24303e44e8c22e779c343157310f6f7fd6); 
    IERC20 public TOKEN;

    event Withdraw(address indexed _to, uint256 _amount);
    event TransferWax(address indexed _from, address indexed _to, uint256 _amount);
    event TokensReceived(address indexed _from, uint256 _value, address indexed _tokenContractAddress, bytes _data);

    constructor() public {
      
      PlayerBalance storage player = playerBalances[msg.sender];
      player.wax = INITIAL_AUCTION_DEPOSIT.mul(WAX_PER_APIS).mul(10 ** WAX_AND_HONEY_DECIMALS);

      TOKEN = IERC20(TOKEN_CONTRACT_ADDRESS);
    }

    function tokenFallback(address _from, uint256 _value, bytes memory _data) public returns (bool) {
        emit TokensReceived(_from, _value, msg.sender, _data);

        require(_value > 0, "please pay something");
        uint256 _wax = _value;
        _wax = _wax.mul(WAX_PER_APIS);

        PlayerBalance storage player = playerBalances[_from];
        PlayerBalance storage referer = playerBalances[player.referer];

        player.wax = (player.wax.add(_wax));
        player.points = (player.points.add(_wax));
        if (player.collectedMedal < 1) {
            player.collectedMedal = 1;
        }
        if (player.referer != address(0)) {
            referer.points = (referer.points.add(_wax));

            address playerAddr = _from;
            address refAddr = player.referer;
            for (uint8 i = 0; i < REF_PERCENTS.length; i++) {
              if (refAddr == address(0)) {
                refAddr = DEFAULT_REFERRER_ADDRESS;
              }

              uint256 referrerReward = _wax.mul(REF_PERCENTS[i]).div(10000);
              playerBalances[refAddr].honey = playerBalances[refAddr].honey.add(referrerReward);
              referralAPISAmounts[refAddr] = referralAPISAmounts[refAddr].add(referrerReward.div(HONEY_FOR_APIS));

              uint256 _index = playerBalances[playerAddr].refererIndex;
              playerBalances[refAddr].referralsArray[_index].honey = playerBalances[refAddr].referralsArray[_index].honey.add(referrerReward);

              playerAddr = refAddr;
              refAddr = playerBalances[playerAddr].referer;
            }
        }
        if (MaxContractBalance <= TOKEN.balanceOf(address(this))) {
            MaxContractBalance = TOKEN.balanceOf(address(this));
            MaxContractBalance75 = MaxContractBalance.mul(95);
            MaxContractBalance75 = MaxContractBalance75.div(100);
            CriticalContractBalance = false;
        }
        statTotalInvested = (statTotalInvested.add(_value));
        player.totalInvested = player.totalInvested.add(_value);

        uint256 adminFee = _value.mul(ADMIN_PERCENT).div(100); 
        statTotalSold = statTotalSold.add(adminFee);
        TOKEN.transfer(owner, adminFee);
        emit Withdraw(owner, adminFee);

        return true;
    }

    function _payWax(uint256 _wax) internal {
        uint256 wax = _wax;
        PlayerBalance storage player = playerBalances[msg.sender];
        if (player.wax < _wax) {
            uint256 honey = _wax.sub(player.wax);
            _payHoney(honey);
            wax = player.wax;
        }
        if (wax > 0) {
            player.wax = player.wax.sub(wax);
        }
    }

    function _payHoney(uint256 _honey) internal {
        PlayerBalance storage player = playerBalances[msg.sender];

        player.honey = player.honey.sub(_honey);
    }

    
    function transferWax(address _to, uint256 _wax) external onlyOwner {
      require(_to != address(0x0), "Invalid receiver address");
      require(_wax > 0, "Invalid WAX amount to transfer");

      PlayerBalance storage player = playerBalances[msg.sender];
      require(player.wax >= _wax, "Not enough wax to transfer");

      player.wax = player.wax.sub(_wax);
      playerBalances[_to].wax = playerBalances[_to].wax.add(_wax);

      emit TransferWax(msg.sender, _to, _wax);
    }

}

contract Game is Balances {

    
    uint32[BEES_TYPES] public BEES_PRICES = [1500, 7500, 30000, 75000, 250000, 750000, 150000];

    uint32[BEES_TYPES] public BEES_PROFITS_PERCENTS = [150, 152, 154, 156, 158, 160, 180];

    
    uint32[BEES_LEVELS] public BEES_LEVELS_HONEY_PERCENTS = [50, 52, 54, 56, 58, 60];
    uint32[BEES_LEVELS] public BEES_LEVELS_PRICES = [0, 15000, 50000, 120000, 250000, 400000];

    

    uint32[BEES_TYPES] public BEES_BOXES_PRICES = [0, 11250, 45000, 112500, 375000, 1125000, 0];

    
    uint32[MEDALS + 1] public MEDALS_POINTS = [0, 50000, 190000, 510000, 1350000, 3225000, 5725000, 8850000, 12725000, 23500000];
    uint32[MEDALS + 1] public MEDALS_REWARD = [0, 3500, 10500, 24000, 65000, 140000, 185000, 235000, 290000, 800000];

    
    event SellHoney(address indexed _player, uint256 _honey);

    function sellHoney(uint256 _honey) public returns (bool success) {
        require(_honey > 0, "couldnt sell zero");
        require(_collectAll(), "problems with collect all before unlock box");
        PlayerBalance storage player = playerBalances[msg.sender];
        require(_honey <= player.honey, "Not enough honey on the balance");

        
        uint256 money = _honey.div(HONEY_FOR_APIS);
        uint256 possibleToWithdraw = player.totalInvested.mul(180).div(100).add(referralAPISAmounts[msg.sender]).sub(player.totalWithdrawn);
        bool reInitPlayer = false;
        if (possibleToWithdraw <= money) {
          reInitPlayer = true;

          money = possibleToWithdraw;
          _honey = money.mul(HONEY_FOR_APIS);

          player.wax = 0;
          player.honey = 0;
          
          player.level = 0;
          player.airdropUnlockedTime = now;
          player.airdropCollectedTime = now;
          player.beeBoxes[0].unlocked = true;
          player.beeBoxes[0].unlockedTime = now;
          player.beeBoxes[0].totalBees = 0;
          for (uint8 i = 1; i < BEES_TYPES; i++) {
            player.beeBoxes[i].unlocked = false;
            player.beeBoxes[i].unlockedTime = now;
            player.beeBoxes[i].totalBees = 0;
          }
          player.beesTotalPower = 0;
          
          player.beesCollectedTime = now;

          player.totalInvested = 0;
          player.totalWithdrawn = 0;

          referralAPISAmounts[msg.sender] = 0;
        }

        require(TOKEN.balanceOf(address(this)) >= money, "Couldn't withdraw more than total APIS balance on the contract");

        
        if (player.honey > 0) {
          player.honey = player.honey.sub(_honey);
        }
        TOKEN.transfer(msg.sender, money);
        statTotalSold = statTotalSold.add(money);

        if (!reInitPlayer) {
          player.totalWithdrawn = player.totalWithdrawn.add(money);
        }
        if (TOKEN.balanceOf(address(this)) < MaxContractBalance75)  {
            CriticalContractBalance = true; 
        }

        emit SellHoney(msg.sender, _honey);
        emit Withdraw(msg.sender, money);

        return true;
    }

    function collectMedal() public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint64 medal = player.collectedMedal;
        require(medal < MEDALS, "no medals left");
        uint256 pointToHave = MEDALS_POINTS[medal];
        pointToHave = pointToHave.mul(1000000);
        require(player.points >= pointToHave, "not enough points");
        uint256 _wax = MEDALS_REWARD[medal];
        if (_wax > 0) {
            _wax = _wax.mul(10 ** WAX_AND_HONEY_DECIMALS);
            player.wax = player.wax.add(_wax);
        }
        player.collectedMedal = medal + 1;
        return true;
    }

    function unlockAirdropBees(address _referer) public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        require(player.airdropUnlockedTime == 0, "coulnt unlock already unlocked");

        if (playerBalances[_referer].airdropUnlockedTime > 0 || _referer == DEFAULT_REFERRER_ADDRESS) {
            player.referer = _referer;
            require(playerBalances[_referer].referralsCount + 1 > playerBalances[_referer].referralsCount, "no overflow");
            playerBalances[_referer].referralsArray.push(PlayerRef(msg.sender, 0));
            player.refererIndex = playerBalances[_referer].referralsCount;
            playerBalances[_referer].referralsCount++;
            if (playerBalances[_referer].referralsCount > statMaxReferralsCount) {
                statMaxReferralsCount = playerBalances[_referer].referralsCount;
                statMaxReferralsReferer = _referer;
            }
        }

        player.airdropUnlockedTime = now;
        player.airdropCollectedTime = now;
        player.beeBoxes[0].unlocked = true;
        player.beeBoxes[0].unlockedTime = now;
        player.beeBoxes[0].totalBees = 0;
        player.beesTotalPower = 0;
        player.collectedMedal = 1;
        player.beesCollectedTime = now;

        statTotalPlayers = (statTotalPlayers.add(1));
        statPlayers.push(msg.sender);
        return true;
    }

    function unlockBox(uint _box) public returns (bool success) {
        require(_box > 0, "coulnt unlock already unlocked");
        require(_box < 6, "coulnt unlock out of range"); 

        PlayerBalance storage player = playerBalances[msg.sender];
        if (player.airdropUnlockedTime <= 0) {
          unlockAirdropBees(DEFAULT_REFERRER_ADDRESS);
          player = playerBalances[msg.sender];
        }

        require(!player.beeBoxes[_box].unlocked, "coulnt unlock already unlocked");
        

        
        if (player.beesTotalPower == 0) {
          player.beesCollectedTime = now;
        }

        require(_collectAll(), "problems with collect all before unlock box");
        uint256 _wax = BEES_BOXES_PRICES[_box];
        _wax = _wax.mul(10 ** WAX_AND_HONEY_DECIMALS);
        _payWax(_wax);
        player.beeBoxes[_box].unlocked = true;
        player.beeBoxes[_box].unlockedTime = now;
        player.beeBoxes[_box].totalBees = 1;
        player.beesTotalPower = (player.beesTotalPower.add(_getBeePower(_box)));
        statTotalBees = (statTotalBees.add(1));

        return true;
    }

    function buyBee(uint _box) public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        if (_box == 6) {
            require(CriticalContractBalance, "only when critical balance flag is on");
        } else {
            require(player.beeBoxes[_box].unlocked, "coulnt buy in locked box");
        }
        require(player.beeBoxes[_box].totalBees < BEES_PER_BOX, "coulnt buy in filled box");

        
        if (player.beesCollectedTime == 0) {
          player.beesCollectedTime = now;
        }

        require(_collectAll(), "problems with collect all before buy");
        uint256 _wax = BEES_PRICES[_box];
        _wax = _wax.mul(10 ** WAX_AND_HONEY_DECIMALS);
        _payWax(_wax);
        player.beeBoxes[_box].totalBees++;
        player.beesTotalPower = (player.beesTotalPower.add(_getBeePower(_box)));
        statTotalBees = (statTotalBees.add(1));
        return true;
    }

    function buyLevel() public returns (bool success) {
        require(_collectAll(), "problems with collect all before level up");
        PlayerBalance storage player = playerBalances[msg.sender];
        uint64 level = player.level + 1;
        require(level < BEES_LEVELS, "couldnt go level more than maximum");
        uint256 _honey = BEES_LEVELS_PRICES[level];
        _honey = _honey.mul(10 ** WAX_AND_HONEY_DECIMALS);
        _payHoney(_honey);
        player.level = level;
        return true;
    }

    
    function collectAirdrop() public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        require(player.airdropUnlockedTime > 0, "should be unlocked");
        require(now - player.airdropUnlockedTime >= AIRDROP_COLLECT_TIME_PAUSE, "should be unlocked");
        require(
          player.airdropCollectedTime == 0 || now - player.airdropCollectedTime >= AIRDROP_COLLECT_TIME_PAUSE,
          "should be never collected before or more then 8 hours from last collect"
        );

        uint256 _wax = (10 ** WAX_AND_HONEY_DECIMALS).mul(100); 
        player.airdropCollectedTime = now;
        player.wax = (player.wax.add(_wax));
        return true;
    }

    
    function collectProducts() public returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256 passTime = now - player.beesCollectedTime;
        if (player.beesCollectedTime <= 0) {
          playerBalances[msg.sender].beesCollectedTime = now;
          passTime = 0;
        }
        require(passTime >= USUAL_COLLECT_TIME_PAUSE, "should wait a little bit");
        return _collectAll();
    }

    function _getBeePower(uint _box) public view returns (uint) {
        return BEES_PROFITS_PERCENTS[_box] * BEES_PRICES[_box];
    }

    function _getCollectAllAvailable() public view returns (uint, uint) {
        PlayerBalance storage player = playerBalances[msg.sender];

        uint256 monthlyIncome = player.beesTotalPower.div(100).mul(10 ** WAX_AND_HONEY_DECIMALS);
        uint256 passedTime = now.sub(player.beesCollectedTime);
        if (player.beesCollectedTime <= 0) {
          return (0, 0);
        }
        uint256 income = monthlyIncome.mul(passedTime).div(BEES_PROFITS_DIVIDED);

        uint256 _honey = income.mul(BEES_LEVELS_HONEY_PERCENTS[player.level]).div(100);
        uint256 _wax = income.sub(_honey);

        return (_honey, _wax);
    }

    function _collectAll() internal returns (bool success) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint256 _honey;
        uint256 _wax;
        (_honey, _wax) = _getCollectAllAvailable();
        if (_wax > 0 || _honey > 0) {
            player.beesCollectedTime = now;
        }
        if (_wax > 0) {
            player.wax = player.wax.add(_wax);
        }
        if (_honey > 0) {
            player.honey = player.honey.add(_honey);
        }
        return true;
    }
}

contract BeeHiveAPIS is Game {

    mapping(address => uint256) private balances;
    uint256 public turnover;

    function getGameStats() public view returns (uint[] memory, address) {
        uint[] memory combined = new uint[](5);
        combined[0] = statTotalInvested;
        combined[1] = statTotalSold;
        combined[2] = statTotalPlayers;
        combined[3] = statTotalBees;
        combined[4] = statMaxReferralsCount;
        return (combined, statMaxReferralsReferer);
    }

    function getBeeBoxFullInfo(uint _box) public view returns (uint[] memory) {
        uint[] memory combined = new uint[](5);

        PlayerBalance storage player = playerBalances[msg.sender];

        combined[0] = player.beeBoxes[_box].unlocked ? 1 : 0;
        combined[1] = player.beeBoxes[_box].totalBees;
        combined[2] = player.beeBoxes[_box].unlockedTime;
        combined[3] = player.beesTotalPower;
        combined[4] = player.beesCollectedTime;
        if (_box == 6) {
          combined[0] = CriticalContractBalance ? 1 : 0;
        }
        return combined;
    }

    function getPlayersInfo() public view returns (address[] memory, uint[] memory) {
        address[] memory combinedA = new address[](statTotalPlayers);
        uint[] memory combinedB = new uint[](statTotalPlayers);
        for (uint i = 0; i<statTotalPlayers; i++) {
            combinedA[i] = statPlayers[i];
            combinedB[i] = playerBalances[statPlayers[i]].beesTotalPower;
        }
        return (combinedA, combinedB);
    }

    function getReferralsInfo() public view returns (address[] memory, uint[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];

        address[] memory combinedA = new address[](player.referralsCount);
        uint[] memory combinedB = new uint[](player.referralsCount);
        for (uint i = 0; i<player.referralsCount; i++) {
            combinedA[i] = player.referralsArray[i].referral;
            combinedB[i] = player.referralsArray[i].honey;
        }
        return (combinedA, combinedB);
    }

    function getReferralsNumber(address _address) public view returns (uint) {
        return playerBalances[_address].referralsCount;
    }

    function getReferralsNumbersList(address[] memory _addresses) public view returns (uint[] memory) {
        uint[] memory counters = new uint[](_addresses.length);
        for (uint i = 0; i < _addresses.length; i++) {
            counters[i] = playerBalances[_addresses[i]].referralsCount;
        }

        return counters;
    }

    function getContractBalance() public view returns (uint) {
        return TOKEN.balanceOf(address(this));
    }

    function playerUnlockedInfo(address _referer) public view returns (uint) {
        return playerBalances[_referer].beeBoxes[0].unlocked ? 1 : 0;
    }

    function collectMedalInfo() public view returns (uint[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];

        uint[] memory combined = new uint[](5);
        uint64 medal = player.collectedMedal;
        if (medal >= MEDALS) {
            combined[0] = 1;
            combined[1] = medal + 1;
            return combined;
            
        }

        combined[1] = medal + 1;
        combined[2] = player.points;
        uint256 pointToHave = MEDALS_POINTS[medal];
        combined[3] = pointToHave.mul(1000000);
        combined[4] = MEDALS_REWARD[medal];
        combined[4] = combined[4].mul(1000000);

        if (player.points < combined[3]) {
            combined[0] = 2;
            return combined;
            
        }
        return combined;
    }

    
    function unlockBoxInfo(uint _box) public view returns (uint[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint[] memory combined = new uint[](4);
        if (_box == 6) {
            if (!CriticalContractBalance) {
                
                combined[0] = 88; 
                return combined;
            }
        } else {
            
            if (player.beeBoxes[_box].unlocked) {
                combined[0] = 2; 
                return combined;
            }
        }
        uint256 _wax = BEES_BOXES_PRICES[_box];
        _wax = _wax.mul(10 ** WAX_AND_HONEY_DECIMALS);
        uint256 _new_honey;
        uint256 _new_wax;
        (_new_honey, _new_wax) = _getCollectAllAvailable();
        combined[1] = _wax;
        combined[2] = _wax;
        if (player.wax + _new_wax < _wax) {
            combined[2] = player.wax + _new_wax;
            combined[3] = _wax - combined[2];
            if (player.honey + _new_honey < combined[3]) {
                combined[0] = 55; 
            }
        }
        return combined;
    }

    function buyBeeInfo(uint _box) public view returns (uint[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint[] memory combined = new uint[](4);
        if (_box == 6) {
            if (!CriticalContractBalance) {
                combined[0] = 88;
                return combined;
                
            }
        } else {
            if (!player.beeBoxes[_box].unlocked) {
                combined[0] = 1;
                return combined;
                
            }
        }
        if (player.beeBoxes[_box].totalBees >= BEES_PER_BOX) {
            combined[0] = 2;
            return combined;
            
        }
        uint256 _wax = BEES_PRICES[_box];
        _wax = _wax.mul(10 ** WAX_AND_HONEY_DECIMALS);
        uint256 _new_honey;
        uint256 _new_wax;
        (_new_honey, _new_wax) = _getCollectAllAvailable();
        combined[1] = _wax;
        combined[2] = _wax;
        if (player.wax + _new_wax < _wax) {
            combined[2] = player.wax + _new_wax;
            combined[3] = _wax - combined[2];
            if (player.honey + _new_honey < combined[3]) {
                combined[0] = 55;
            }
        }
        return combined;
    }


    function buyLevelInfo() public view returns (uint[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint[] memory combined = new uint[](4);
        if (player.level + 1 >= BEES_LEVELS) {
            combined[0] = 2;
            return combined;
            
        }
        combined[1] = player.level + 1;
        uint256 _honey = BEES_LEVELS_PRICES[combined[1]];
        _honey = _honey.mul(10 ** WAX_AND_HONEY_DECIMALS);
        combined[2] = _honey;

        uint256 _new_honey;
        uint256 _new_wax;
        (_new_honey, _new_wax) = _getCollectAllAvailable();
        if (player.honey + _new_honey < _honey) {
            combined[0] = 55;
        }

        return combined;
    }

    
    function collectAirdropInfo() public view returns (uint[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint[] memory combined = new uint[](3);
        if (player.airdropUnlockedTime == 0) {
            combined[0] = 1; 
            return combined;
        }
        if (player.airdropUnlockedTime == 0) {
            combined[0] = 2; 
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

        uint256 _wax = (10 ** WAX_AND_HONEY_DECIMALS).mul(100); 
        combined[0] = 0;
        combined[1] = _wax;
        combined[2] = 0;
        if (player.wax + _wax < player.wax) {
            combined[0] = 255;
            return combined;
            
        }
        return combined;

    }

    function collectProductsInfo() public view returns (uint[] memory) {
        PlayerBalance storage player = playerBalances[msg.sender];
        uint[] memory combined = new uint[](3);
        if (!(player.beesCollectedTime > 0)) {
            combined[0] = 3;
            return combined;
            
        }

        uint256 passTime = now - player.beesCollectedTime;
        if (passTime < USUAL_COLLECT_TIME_PAUSE) {
            combined[0] = 11;
            combined[1] = passTime;
            combined[2] = USUAL_COLLECT_TIME_PAUSE - combined[1];
            return combined;
            
        }

        uint256 _honey;
        uint256 _wax;
        (_honey, _wax) = _getCollectAllAvailable();

        combined[0] = 0;
        combined[1] = _wax;
        combined[2] = _honey;
        if (player.wax + _wax < player.wax) {
            combined[0] = 255;
            return combined;
            
        }
        return combined;
    }

    function getWaxAndHoney(address _addr) public view returns(
      uint256, uint256, bool, uint256, uint256
    ) {
      return (
        TOKEN.balanceOf(address(this)),
        MaxContractBalance,
        CriticalContractBalance,
        MaxContractBalance75,
        referralAPISAmounts[_addr]
      );
    }

    function turnUsers() external {
      
    }

}