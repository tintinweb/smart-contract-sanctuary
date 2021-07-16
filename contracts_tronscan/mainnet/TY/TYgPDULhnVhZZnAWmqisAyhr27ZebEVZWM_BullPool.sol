//SourceUnit: BullPool.sol

pragma experimental ABIEncoderV2;
pragma solidity 0.5.12;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
}

contract Governance {
    
    address public governance;

    event GovernanceTransferred(address indexed oldOwner,address indexed newOwner);

    constructor() public {
        governance = tx.origin;
    }

    modifier onlyGovernance {
        require(msg.sender == governance, "not governance");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance {
        require(_governance != address(0), "new governance the zero address");
        governance = _governance;
        emit GovernanceTransferred(governance, _governance);
    }
    
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function allowance(address owner, address spender)external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval( address indexed owner,address indexed spender, uint256 value);
    
}

contract BullPool is Governance {
    
    using SafeMath for uint256;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct UserRef {
        address refer;
        uint256 level;
        uint256 ref_1;
        uint256 ref_2;
        uint256 ref_3;
        uint256 ref_m;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256 ref_bonus;
        uint256 ref_bonus_withdraw;
        uint256 level_bonus;
        uint256 level_bonus_withdraw;
        uint256 week_bonus;
        uint256 week_bonus_withdraw;
    }

    struct TokenPool {
        string name;
        address addr;
        uint256 decimals;
        uint256 price;
        uint256 base_rate;
        uint256 hold_rate;
        uint256 min_amount;
        uint256 day_step_amount;
        uint256 invested;
        uint256 deposit;
        uint256 balance;
        uint256 system;
        uint256 market;
        uint256 reward;
        uint256 users;
        uint256 invest_times;
        uint256 token_times;
        uint256 token_decay_round;
        uint256 token_decay_rate;
        uint256 start;
        uint256 model; //1 recom,2 high,3 stable
        uint256 code;
        bool enable;
    }

    struct WeekRef {
        address user;
        uint256 count;
        uint256 reward;
        uint256 code;
    }

    TokenPool[] _token_pools;

    uint256 _current_ref_code = 100000;

    uint256 _pool_code_base = 1000;

    uint256 _create_ref_amount = 100000000;

    address payable internal _system_addr;

    address payable internal _market_addr;

    address internal _mainCoin = 0x6666666666666666666666666666666666666666;

    address public _pool_token_addr;

    uint256[] public _ref_percents = [500, 300, 200, 100, 50];

    uint256[] public _week_ref_percents = [4000,2000,1000,500,400,300,200,100];

    uint256[] public _sys_percents = [200, 200, 200];

    uint256 public constant _percents_div = 10000;

    uint256 public constant _time_step = 1 days;

    uint256 public _level = 10;

    uint256 public _level_amount = 3000000000;

    mapping(address => uint256) public _ref_addr_code;

    mapping(uint256 => address) public _ref_code_addr;

    mapping(uint256 => TokenPool) internal _pools;

    mapping(uint256 => mapping(address => User)) internal _pool_users;

    mapping(address => UserRef) internal _user_refs;

    WeekRef[] internal _week_refs;

    event Newbie(address user);

    event NewDeposit(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    event RefCreated(address indexed user, uint256 code);

    event Upgraded(address indexed user, uint256 level);

    constructor() public {
        TokenPool storage tp = _pools[0];
        tp.name = "TRX";
        tp.addr = _mainCoin;
        tp.decimals = 6;
        tp.price = 30000;
        tp.base_rate = 100;
        tp.hold_rate = 10;
        tp.min_amount = 100000000;
        tp.day_step_amount = 100000000000;
        tp.invest_times = 10000;
        tp.token_times = 200000;
        tp.token_decay_round = 15 days;
        tp.token_decay_rate = 1000;
        tp.start = block.timestamp;
        tp.model = 1;
        tp.code = _pool_code_base;
        tp.enable = true;
        _token_pools.push(tp);
    }

    function() external payable {
        revert();
    }

    function setSysAddress(address payable addr) public onlyGovernance {
        require(addr != address(0));
        _system_addr = addr;
    }

    function setMarketAddress(address payable addr) public onlyGovernance {
        require(addr != address(0));
        _market_addr = addr;
    }

    function setPoolTokenAddress(address addr) public onlyGovernance {
        require(addr != address(0));
        _pool_token_addr = addr;
    }

    function setRefPercents(uint256[] memory percents) public onlyGovernance {
        _ref_percents = percents;
    }

    function setSysPercents(uint256[] memory percents) public onlyGovernance {
        _sys_percents = percents;
    }

    function setWeekRefPercents(uint256[] memory percents) public onlyGovernance {
        _week_ref_percents = percents;
    }

    function setLevel(uint256 level, uint256 price) public onlyGovernance {
        require(level > 0 && price >= 0);
        _level = level;
        _level_amount = price;
    }

    function mint(uint256 amount) public onlyGovernance {
        require(amount > 0 && _pool_token_addr != address(0));
        IERC20(_pool_token_addr).mint(address(this), amount);
    }

    function updatePrice(uint256 code, uint256 price) public onlyGovernance {
        require(code != 0);
        uint256 idx = 0;
        bool exist = false;
        for (uint256 i = 0; i < _token_pools.length; i++) {
            if (_token_pools[i].code == code) {
                exist = true;
                idx = i;
                break;
            }
        }
        require(exist);
        TokenPool storage tp = _token_pools[idx];
        tp.price = price;
    }

    function updateEnable(uint256 code, bool enable) public onlyGovernance {
        require(code != 0);
        uint256 idx = 0;
        bool exist = false;
        for (uint256 i = 0; i < _token_pools.length; i++) {
            if (_token_pools[i].code == code) {
                exist = true;
                idx = i;
                break;
            }
        }
        require(exist);
        TokenPool storage tp = _token_pools[idx];
        tp.enable = enable;
    }

    function createTokenPool(
        string memory name,
        address addr,
        uint256 price,
        uint256 base_rate,
        uint256 hold_rate,
        uint256 min_amount,
        uint256 day_step_amount,
        uint256 invest_times,
        uint256 model,
        uint256 [] memory tokeninfo
    ) public onlyGovernance {
        require(addr != address(0));
        uint256 decimals = 18;
        if (addr == _mainCoin) {
            decimals = 6;
        } else {
            IERC20 token = IERC20(addr);
            decimals = token.decimals();
            require(decimals > 0);
        }
        _pool_code_base = _pool_code_base.add(1);
        TokenPool storage tp = _pools[0];
        tp.name = name;
        tp.addr = addr;
        tp.decimals = decimals;
        tp.price = price;
        tp.base_rate = base_rate;
        tp.hold_rate = hold_rate;
        tp.min_amount = min_amount;
        tp.day_step_amount = day_step_amount;
        tp.invest_times = invest_times;
        tp.token_times = tokeninfo[0];
        tp.token_decay_round = tokeninfo[1];
        tp.token_decay_rate = tokeninfo[2];
        tp.start = block.timestamp;
        tp.model = model;
        tp.code = _pool_code_base;
        tp.enable = true;
        _token_pools.push(tp);
    }

    function updateTokenPool(
        uint256 code,
        uint256 price,
        uint256 invest_times,
        uint256 token_times,
        uint256 token_decay_rate,
        uint256 token_decay_round,
        uint256 base_rate,
        uint256 hold_rate,
        uint256 min_amount,
        uint256 day_step_amount,
        uint256 model
    ) public onlyGovernance {
        require(code != 0);
        uint256 idx = 0;
        bool exist = false;
        for (uint256 i = 0; i < _token_pools.length; i++) {
            if (_token_pools[i].code == code) {
                exist = true;
                idx = i;
                break;
            }
        }
        require(exist);
        TokenPool storage tp = _token_pools[idx];
        tp.price = price;
        tp.model = model;
        tp.base_rate = base_rate;
        tp.hold_rate = hold_rate;
        tp.min_amount = min_amount;
        tp.day_step_amount = day_step_amount;
        tp.token_times = token_times;
        tp.token_decay_round = token_decay_round;
        tp.token_decay_rate = token_decay_rate;
        tp.invest_times = invest_times;
    }

    function generateSysCode(address addr) public onlyGovernance {
        require(addr != address(0));
        if (_ref_addr_code[addr] == 0) {
            _current_ref_code = _current_ref_code.add(1);
            _ref_addr_code[addr] = _current_ref_code;
            _ref_code_addr[_current_ref_code] = addr;
            UserRef storage ref = _user_refs[addr];
            ref.level = _level;
            ref.refer = _mainCoin;
        }
    }

    function generateRefCode(uint256 refCode) public payable {
        require(msg.value >= _create_ref_amount);
        require(_system_addr!=address(0));
        bool newRef = addRef(refCode, msg.sender);
        if (newRef) {
            UserRef storage currentRef = _user_refs[msg.sender];
            address upline = currentRef.refer;
            uint256 i = 0;
            while ( (upline != address(0) && upline != _mainCoin)) {
                UserRef storage upRef = _user_refs[upline];
                if (i == 0) {
                    upRef.ref_1 = upRef.ref_1.add(1);
                } else if (i == 1) {
                    upRef.ref_2 = upRef.ref_2.add(1);
                } else if (i == 2) {
                    upRef.ref_3 = upRef.ref_3.add(1);
                } else if (i >= 3 && i < _ref_percents.length) {
                    upRef.ref_m = upRef.ref_m.add(1);
                }
                i++;
                upline = upRef.refer;
                if (i > _ref_percents.length - 1) {
                    upline = address(0);
                }
            }
        }
        if (_ref_addr_code[msg.sender] == 0) {
            _current_ref_code = _current_ref_code.add(1);
            _ref_addr_code[msg.sender] = _current_ref_code;
            _ref_code_addr[_current_ref_code] = msg.sender;
        }
        _system_addr.transfer(msg.value);
        emit RefCreated(msg.sender, _ref_addr_code[msg.sender]);
    }

    function getRefCode(address addr) public view returns (uint256) {
        return _ref_addr_code[addr];
    }

    function getTokenPools() public view returns (string [] memory,address [] memory,uint256[][] memory) {
        uint256 [][] memory rts = new uint256[][] (_token_pools.length);
        address [] memory addrs  = new address[](_token_pools.length);
        string [] memory names  = new string[](_token_pools.length);
        for (uint256 j = 0; j < _token_pools.length; j++) {
            TokenPool memory r = _token_pools[j];
            uint256 [] memory a = new uint256[](14);
            a[0]=r.model; 
            a[1]=r.decimals;
            a[2]=r.invested;
            a[3]=r.balance;
            a[4]=r.users;
            a[5]=r.min_amount;
            a[6]=r.code;
            a[7]=r.price;
            a[8]=r.base_rate;
            a[9]=r.hold_rate;
            a[10]=r.invest_times;
            a[11]=r.token_times;
            a[12]=r.token_decay_rate;
            a[13]=r.token_decay_round;
            rts[j]=a;
            addrs[j]=r.addr;
            names[j]=r.name;
         }
        return (names,addrs,rts);
    }

    function getWeekRefs() public view returns (uint256[][] memory) {
        uint256 len = _week_refs.length;
        WeekRef[] memory arr = new WeekRef[](len);
        for (uint256 i = 0; i < len; i++) {
            arr[i] = _week_refs[i];
        }
        for (uint256 i = 0; i < len - 1; i++) {
            for (uint256 j = 0; j < len - 1 - i; j++) {
                if (arr[j].count < arr[j + 1].count) {
                    WeekRef memory temp = arr[j + 1];
                    arr[j + 1] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        for (uint256 i = 0; i < _token_pools.length; i++) {
            TokenPool memory tp = _token_pools[i];
            for (uint256 j = 0; j < arr.length; j++) {
                WeekRef memory r = arr[j];
                uint256 dec = 10**tp.decimals;
                uint256 fee = _week_ref_percents[j];
                uint256 amount = tp.reward.mul(fee).div(_percents_div);
                r.reward = r.reward.add(amount.mul(tp.price).div(dec));
                r.code = _ref_addr_code[r.user];
            }
        }
        uint256 [][] memory rts = new uint256[][] (arr.length);
         for (uint256 j = 0; j < arr.length; j++) {
                WeekRef memory r = arr[j];
                uint256 [] memory a = new uint256[](3);
                a[0]=r.code;
                a[1]=r.count;
                a[2]=r.reward;
                rts[j]=a;
         }
        return rts;
    }

    function getTokenPool(uint256 code) public view returns (TokenPool memory) {
        require(code != 0);
        for (uint256 i = 0; i < _token_pools.length; i++) {
            if (_token_pools[i].code == code) {
                return _token_pools[i];
            }
        }
    }

    function addRef(uint256 refCode, address sender) internal returns (bool) {
        UserRef storage currentRef = _user_refs[sender];
        bool newRef = false;
        if (currentRef.refer == address(0)) {
            address referrer = _ref_code_addr[refCode];
            require(referrer != address(0));
            require(referrer != sender);
            require(_user_refs[referrer].refer != sender);
            currentRef.refer = referrer;
            addWeekRef(referrer);
            newRef = true;
        }
        return newRef;
    }

    function refReward(
        uint256 refCode,
        address sender,
        uint256 amount,
        TokenPool memory tp
    ) internal returns (uint256) {
        bool newRef = addRef(refCode, sender);
        UserRef storage currentRef = _user_refs[sender];
        uint256 subAmount = 0;
        uint256 tpcode = tp.code;
        if (currentRef.refer != address(0)) {
            address upline = currentRef.refer;
            uint256 i = 0;
            uint256 lastnode = 0;
            uint256 tmpindex = 0;
            address[] memory tmpnodes = new address[](10);
            uint256 inAmount = amount;
            while ((upline != address(0) && upline != _mainCoin)) {
                UserRef storage upRef = _user_refs[upline];
                User storage upPoolUser = _pool_users[tpcode][upline];
                if (newRef) {
                    if (i == 0) {
                        upRef.ref_1 = upRef.ref_1.add(1);
                    } else if (i == 1) {
                        upRef.ref_2 = upRef.ref_2.add(1);
                    } else if (i == 2) {
                        upRef.ref_3 = upRef.ref_3.add(1);
                    } else if (i >= 3 && i < _ref_percents.length) {
                        upRef.ref_m = upRef.ref_m.add(1);
                    }
                }
                if (i < _ref_percents.length) {
                    if (inAmount > 0) {
                        uint256 ref_amount = inAmount.mul(_ref_percents[i]).div(_percents_div);
                        upPoolUser.ref_bonus = upPoolUser.ref_bonus.add(ref_amount);
                        subAmount = subAmount.add(ref_amount);
                    }
                }
                if (upRef.level > lastnode) {
                    lastnode = upRef.level;
                    tmpnodes[tmpindex] = upline;
                    tmpindex++;
                }
                upline = upRef.refer;
                i++;
                if (i > _ref_percents.length - 1 && lastnode >= _level) {
                    upline = address(0);
                }
                if (i > 40) {
                    upline = address(0);
                }
            }
            if (inAmount > 0) {
                uint256 lastLevel = 0;
                for (uint256 j = 0; j < tmpnodes.length; j++) {
                    address addr = tmpnodes[j];
                    if (addr != address(0)) {
                        UserRef memory userRef = _user_refs[addr];
                        User storage poolUser = _pool_users[tpcode][addr];
                        uint256 level_amount = inAmount.mul(userRef.level.sub(lastLevel).mul(100)).div(_percents_div);
                        poolUser.level_bonus = poolUser.level_bonus.add(level_amount);
                        lastLevel = userRef.level;
                        subAmount = subAmount.add(level_amount);
                    } else {
                        break;
                    }
                }
            }
        }
        return subAmount;
    }

    function upgrade(uint256 refCode) public payable {
        UserRef storage ref = _user_refs[msg.sender];
        uint256 price = _level_amount.mul(ref.level.add(1));
        require(msg.value >= price);
        require(ref.level < _level - 2);
        ref.level = ref.level.add(1);
        uint256 idx = 0;
        bool exist = false;
        for (uint256 i = 0; i < _token_pools.length; i++) {
            if (_token_pools[i].code == 1000) {
                exist = true;
                idx = i;
                break;
            }
        }
        require(exist);
        TokenPool storage tp = _token_pools[idx];
        uint256 subAmount = refReward(refCode, msg.sender, msg.value, tp);
        tp.system = tp.system.add(msg.value.sub(subAmount));
        tp.balance = tp.balance.add(msg.value);
        emit Upgraded(msg.sender, ref.level);
    }

    function getMaxInvest(uint256 code, address user)
        public
        view
        returns (uint256, uint256)
    {
        TokenPool memory tp = getTokenPool(code);
        User storage currentPoolUser = _pool_users[tp.code][user];
        uint256 day = 0;
        uint256 inved = 0;
        for (uint256 i = 0; i < currentPoolUser.deposits.length; i++) {
            inved = inved.add(currentPoolUser.deposits[i].amount);
        }
        if (currentPoolUser.deposits.length > 0) {
            uint256 stime = currentPoolUser.deposits[0].start;
            if (stime > 0) {
                day = (now.sub(stime)).div(_time_step);
            }
        }
        uint256 max = day.add(1).mul(tp.day_step_amount);
        return (max, inved);
    }

    function addWeekRef(address user) internal {
        UserRef memory ref = _user_refs[user];
        uint256 count = ref.ref_1.add(1);
        bool exist = false;
        for (uint256 i = 0; i < _week_refs.length; i++) {
            WeekRef storage r = _week_refs[i];
            if (r.user == user) {
                r.count = count;
                exist = true;
                break;
            }
        }
        if (!exist) {
            if (_week_refs.length == _week_ref_percents.length) {
                for (uint256 i = 0; i < _week_refs.length; i++) {
                    WeekRef storage f = _week_refs[i];
                    if (f.count < count) {
                        f.user = user;
                        f.count = count;
                        break;
                    }
                }
            } else {
                _week_refs.push(WeekRef(user, count, 0, 0));
            }
        }
    }

    function weekReward() public onlyGovernance {
        uint256 len = _week_refs.length;
        WeekRef[] memory arr = new WeekRef[](len);
        for (uint256 i = 0; i < len; i++) {
            arr[i] = _week_refs[i];
        }
        for (uint256 i = 0; i < len - 1; i++) {
            for (uint256 j = 0; j < len - 1 - i; j++) {
                if (arr[j].count < arr[j + 1].count) {
                    WeekRef memory temp = arr[j + 1];
                    arr[j + 1] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        for (uint256 i = 0; i < _token_pools.length; i++) {
            TokenPool storage tp = _token_pools[i];
            if (tp.reward > 0) {
                uint256 total = 0;
                for (uint256 j = 0; j < arr.length; j++) {
                    WeekRef memory r = arr[j];
                    uint256 fee = _week_ref_percents[j];
                    uint256 amount = tp.reward.mul(fee).div(_percents_div);
                    User storage u = _pool_users[tp.code][r.user];
                    u.week_bonus = u.week_bonus.add(amount);
                    total = total.add(amount);
                }
                tp.reward = tp.reward.sub(total);
            }
        }
    }

    function withdrawSys(uint256 code) public onlyGovernance {
        require(_system_addr!=address(0));
        for (uint256 i = 0; i < _token_pools.length; i++) {
            TokenPool storage tp = _token_pools[i];
            if (tp.code == code && tp.system > 0) {
                uint256 amount = tp.system;
                if (tp.system > tp.balance) {
                    amount = tp.balance;
                }
                if (tp.addr == _mainCoin) {
                    _system_addr.transfer(amount);
                } else {
                    IERC20(tp.addr).transfer(_system_addr, amount);
                }
                tp.balance = tp.balance.sub(amount);
                tp.system = tp.system.sub(amount);
                break;
            }
        }
    }

    function withdrawMarket(uint256 code) public onlyGovernance {
        require(_market_addr!=address(0));
        for (uint256 i = 0; i < _token_pools.length; i++) {
            TokenPool storage tp = _token_pools[i];
            if (tp.code == code && tp.market > 0) {
                uint256 amount = tp.market;
                if (tp.market > tp.balance) {
                    amount = tp.balance;
                }
                if (tp.addr == _mainCoin) {
                    _market_addr.transfer(amount);
                } else {
                    IERC20(tp.addr).transfer(_market_addr, amount);
                }
                tp.balance = tp.balance.sub(amount);
                tp.market = tp.market.sub(amount);
                break;
            }
        }
    }

    function withdraw(uint256 code) public {
        uint256 idx = 0;
        bool exist = false;
        for (uint256 i = 0; i < _token_pools.length; i++) {
            if (_token_pools[i].code == code) {
                exist = true;
                idx = i;
                break;
            }
        }
        require(exist);
        TokenPool storage tp = _token_pools[idx];
        require(tp.enable);

        // token times decay
        uint256 decay_count = (block.timestamp.sub(tp.start)).div(tp.token_decay_round);
        if (decay_count >= 1) {
            uint256 decay = tp.token_times.mul(tp.token_decay_rate).div(_percents_div);
            tp.token_times = tp.token_times.sub(decay);
            tp.start = block.timestamp;
        }
        
        uint256 in_amount = 0;
        uint256 base_rate = tp.base_rate;
        uint256 total_rate = tp.base_rate;
        uint256 token_times = tp.token_times;
        uint256 hold_day = 0;
        uint256 hold_rate = 0;
        uint256 invest_reward = 0;
        uint256 invest_times = tp.invest_times;
       
        uint256 pool_balance = tp.balance;
        address token_addr = tp.addr;
        User storage user = _pool_users[tp.code][msg.sender];
        if (user.deposits.length > 0) {
            hold_day = (now.sub(user.checkpoint)).div(_time_step);
            hold_rate = hold_day.mul(tp.hold_rate);
            total_rate = base_rate.add(hold_rate);
            for (uint256 i = 0; i < user.deposits.length; i++) {
                Deposit storage dsp = user.deposits[i];
                in_amount = in_amount.add(dsp.amount);
                uint256 tra = total_rate;
                uint256 max = dsp.amount.mul(invest_times).div(_percents_div);
                if (dsp.withdrawn < max) {
                    uint256 dividends;
                    if (dsp.start > user.checkpoint) {
                        dividends = (dsp.amount.mul(tra).div(_percents_div)).mul(block.timestamp.sub(dsp.start)).div(_time_step);
                    } else {
                        dividends = (dsp.amount.mul(tra).div(_percents_div)).mul(block.timestamp.sub(user.checkpoint)).div(_time_step);
                    }
                    if (dsp.withdrawn.add(dividends) > max) {
                        dividends = max.sub(dsp.withdrawn);
                    }
                    dsp.withdrawn = dsp.withdrawn.add(dividends);
                    invest_reward = invest_reward.add(dividends);
                }
            }
        }
        TokenPool storage t = tp;
        uint256 invest_amount = in_amount;
        uint256 invest_value = invest_reward;
        uint256 invest_u = invest_value.mul(t.price).div(10**t.decimals);
        uint256 token_value = invest_u.mul(10**12).div(_percents_div).mul(token_times).div(_percents_div);
        uint256 ref_value = 0;
        uint256 total_w = user.ref_bonus_withdraw.add(user.level_bonus_withdraw).add(user.week_bonus_withdraw);
        uint256 max_out_amount =invest_amount.sub(total_w);
        if (ref_value < max_out_amount) {
            uint256 ava = user.ref_bonus.sub(user.ref_bonus_withdraw);
            if (ref_value.add(ava) > max_out_amount) {
                ava = max_out_amount.sub(ref_value);
            }
            ref_value = ref_value.add(ava);
            user.ref_bonus_withdraw = user.ref_bonus_withdraw.add(ava);
        }
        if (ref_value < max_out_amount) {
            uint256 ava = user.level_bonus.sub(user.level_bonus_withdraw);
            if (ref_value.add(ava) > max_out_amount) {
                ava = max_out_amount.sub(ref_value);
            }
            ref_value = ref_value.add(ava);
            user.level_bonus_withdraw = user.level_bonus_withdraw.add(ava);
        }
        if (ref_value < max_out_amount) {
            uint256 ava = user.week_bonus.sub(user.week_bonus_withdraw);
            if (ref_value.add(ava) > max_out_amount) {
                ava = max_out_amount.sub(ref_value);
            }
            ref_value = ref_value.add(ava);
            user.week_bonus_withdraw = user.week_bonus_withdraw.add(ava);
        }

        IERC20 erc = IERC20(_pool_token_addr);
        uint256 bls = erc.balanceOf(address(this));
        if (bls > 0) {
            if (token_value > bls) {
                token_value = bls;
            }
            erc.transfer(msg.sender, token_value);
        }
        uint256 out = invest_value.add(ref_value);
        if (out > pool_balance) {
            out = pool_balance;
        }
        if (out > 0) {
            if (token_addr == _mainCoin) {
                uint256 eb = address(this).balance;
                if (out > eb) {
                    out = eb;
                }
                msg.sender.transfer(out);
            } else {
                IERC20 e = IERC20(token_addr);
                uint256 eb = e.balanceOf(address(this));
                if (out > eb) {
                    out = eb;
                }
                e.transfer(msg.sender, out);
            }
        }
        t.balance = t.balance.sub(out);
        user.checkpoint = block.timestamp;
        emit Withdrawn(msg.sender, out);
    }

    function canRef(uint256 refCode, address addr) public view returns (bool) {
        address referrer = _ref_code_addr[refCode];
        if (
            referrer == address(0) ||
            referrer == addr ||
            _user_refs[referrer].refer == addr
        ) {
            return false;
        }
        return true;
    }

    function invest(
        uint256 code,
        uint256 invest_amount,
        uint256 refCode
    ) public payable {
        uint256 idx = 0;
        bool exist = false;
        for (uint256 i = 0; i < _token_pools.length; i++) {
            if (_token_pools[i].code == code) {
                exist = true;
                idx = i;
                break;
            }
        }
        require(exist);
        TokenPool storage tp = _token_pools[idx];
        require(tp.enable);

        // token times decay
        uint256 decay_count = (block.timestamp.sub(tp.start)).div(
            tp.token_decay_round
        );
        if (decay_count >= 1) {
            uint256 decay = tp.token_times.mul(tp.token_decay_rate).div(
                _percents_div
            );
            tp.token_times = tp.token_times.sub(decay);
            tp.start = block.timestamp;
        }
        // token
        IERC20 token;
        uint256 amount = invest_amount;
        if (tp.addr == _mainCoin) {
            amount = msg.value;
        } else {
            token = IERC20(tp.addr);
            token.transferFrom(msg.sender, address(this), amount);
        }
        require(amount >= tp.min_amount);
        uint256 max = 0;
        uint256 inv = 0;
        (max, inv) = getMaxInvest(code, msg.sender);
        require(inv.add(amount) <= max);
        bool lost = false;
        if (tp.invest_times > _percents_div) {
            lost = true;
            uint256 system_fee = amount.mul(_sys_percents[0]).div(
                _percents_div
            );
            uint256 market_fee = amount.mul(_sys_percents[1]).div(
                _percents_div
            );
            uint256 reward_fee = amount.mul(_sys_percents[2]).div(
                _percents_div
            );
            tp.reward = tp.reward.add(reward_fee);
            tp.system = tp.system.add(system_fee);
            tp.market = tp.market.add(market_fee);
        } else if (tp.invest_times < _percents_div) {
            lost = false;
            uint256 fee = _percents_div.sub(tp.invest_times);
            uint256 fee_amount = amount.mul(fee).div(_percents_div);
            tp.system = tp.system.add(fee_amount);
        } else {
            lost = false;
        }
        tp.invested = tp.invested.add(amount);
        tp.deposit = tp.deposit.add(1);
        tp.balance = tp.balance.add(amount);
        // refs
        refReward(refCode, msg.sender, lost ? amount : 0, tp);
        // deposit
        User storage currentPoolUser = _pool_users[tp.code][msg.sender];
        if (currentPoolUser.deposits.length == 0) {
            currentPoolUser.checkpoint = block.timestamp;
            tp.users = tp.users.add(1);
            emit Newbie(msg.sender);
        }
        currentPoolUser.deposits.push(Deposit(amount, 0, block.timestamp));
        emit NewDeposit(msg.sender, amount);
    }

    function getPubInfo() public view returns (uint256[] memory) {
        uint256 total_invest = 0;
        uint256 total_balance = 0;
        uint256 total_users = 0;
        for (uint256 i = 0; i < _token_pools.length; i++) {
            TokenPool memory tp = _token_pools[i];
            uint256 dec = 10**tp.decimals;
            total_invest = total_invest.add(tp.invested.mul(tp.price).div(dec));
            total_balance = total_balance.add(
                tp.balance.mul(tp.price).div(dec)
            );
            total_users = total_users.add(tp.users);
        }
        uint256[] memory info = new uint256[](10);
        info[0] = total_invest;
        info[1] = total_balance;
        info[2] = total_users;
        info[3] = _create_ref_amount;
        info[4] = _level_amount;
        info[5] = _ref_percents.length;
        info[6] = _level;
        return info;
    }

    function getUserInfo(address addr) public view returns (uint256[] memory) {
        uint256 code = _ref_addr_code[addr];
        UserRef memory ref = _user_refs[addr];
        uint256 ref_bonus = 0;
        uint256 level_bonus = 0;
        for (uint256 i = 0; i < _token_pools.length; i++) {
            TokenPool memory tp = _token_pools[i];
            mapping(address => User) storage u = _pool_users[tp.code];
            User storage user = u[addr];
            uint256 dec = 10**tp.decimals;
            ref_bonus = ref_bonus.add(user.ref_bonus.mul(tp.price).div(dec));
            level_bonus = level_bonus.add(
                user.level_bonus.mul(tp.price).div(dec)
            );
        }
        uint256[] memory info = new uint256[](10);
        info[0] = code;
        info[1] = ref.level;
        info[2] = ref.ref_1;
        info[3] = ref.ref_2;
        info[4] = ref.ref_3;
        info[5] = ref.ref_m;
        info[6] = ref_bonus;
        info[7] = level_bonus;
        return info;
    }
    
    function investReward(TokenPool memory tp,User memory user) view internal returns (uint256,uint256,uint256) {
        uint256 in_amount = 0;
        uint256 out_amount = 0;
        uint256 invest_reward = 0;
        uint256 invest_times = tp.invest_times;
        if (user.deposits.length > 0) {
            uint256 checkpoint = user.deposits[user.deposits.length - 1].start;
            uint256 hold_day = (now.sub(user.checkpoint)).div(_time_step);
            uint256 hold_rate = hold_day.mul(tp.hold_rate);
            uint256 total_rate = tp.base_rate.add(hold_rate);
            for (uint256 i = 0; i < user.deposits.length; i++) {
                Deposit memory dsp = user.deposits[i];
                in_amount = in_amount.add(dsp.amount);
                out_amount = out_amount.add(dsp.withdrawn);
                uint256 max = dsp.amount.mul(invest_times).div(_percents_div);
                if (dsp.withdrawn < max) {
                    uint256 dividends = 0;
                    if (dsp.start > user.checkpoint) {
                        dividends = (dsp.amount.mul(total_rate).div(_percents_div)).mul(block.timestamp.sub(dsp.start)).div(_time_step);
                    } else {
                        dividends = (dsp.amount.mul(total_rate).div(_percents_div)).mul(block.timestamp.sub(checkpoint)).div(_time_step);
                    }
                    if (dsp.withdrawn.add(dividends) > max) {
                        dividends = max.sub(dsp.withdrawn);
                    }
                    invest_reward = invest_reward.add(dividends);
                }
            }
        }
        return (in_amount,out_amount,invest_reward);
    }

    function getUserInvest(uint256 code, address addr)
        public
        view
        returns (uint256[] memory)
    {
        TokenPool memory tp = getTokenPool(code);
        User memory user = _pool_users[tp.code][addr];
        uint256 in_amount = 0;
        uint256 out_amount = 0;
        uint256 invest_reward = 0;
        uint256 checkpoint = user.checkpoint;
        if(user.deposits.length>0) checkpoint = user.deposits[user.deposits.length - 1].start;
        (in_amount,out_amount,invest_reward) = investReward(tp,user);
       
        uint256[] memory info = new uint256[](20);
        info[0] = tp.base_rate;
        info[1] = tp.hold_rate;
        info[2] = user.deposits.length;
        info[3] = checkpoint;
        info[4] = in_amount;
        info[5] = out_amount.add(invest_reward);
        info[6] = out_amount;
        info[7] = invest_reward;
        info[8] = user.ref_bonus;
        info[9] = user.ref_bonus_withdraw;
        if (user.ref_bonus > user.ref_bonus_withdraw) {
            info[10] = user.ref_bonus.sub(user.ref_bonus_withdraw);
        } else {
            info[10] = 0;
        }
        info[11] = user.level_bonus;
        info[12] = user.level_bonus_withdraw;
        if (user.level_bonus > user.level_bonus_withdraw) {
            info[13] = user.level_bonus.sub(user.level_bonus_withdraw);
        } else {
            info[13] = 0;
        }
        info[14] = user.week_bonus;
        info[15] = user.week_bonus_withdraw;
        if (user.week_bonus > user.week_bonus_withdraw) {
            info[16] = user.week_bonus.sub(user.week_bonus_withdraw);
        } else {
            info[16] = 0;
        }
        
        uint256 invest_u = invest_reward.mul(tp.price).div(10**tp.decimals);
        uint256 token_value = invest_u.mul(10**12).div(_percents_div).mul(tp.token_times).div(_percents_div);
        info[17] = token_value;
        uint256 max_out_amount = 0;
        if(in_amount>0){
             max_out_amount = in_amount.sub(user.ref_bonus_withdraw).sub(user.level_bonus_withdraw).sub(user.week_bonus_withdraw);
        }
        uint256 ref_total = info[10].add(info[13]).add(info[16]);
        if(ref_total>max_out_amount){
            ref_total = max_out_amount;
        }
        info[18]=ref_total.add(invest_reward);
        info[19]=tp.token_times;
        return info;
    }
}