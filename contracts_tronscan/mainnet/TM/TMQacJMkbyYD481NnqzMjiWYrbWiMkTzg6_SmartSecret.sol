//SourceUnit: SmartSecret.sol

pragma solidity 0.5.12;

contract SmartSecret {
    ITRC20 token;
    address payable root;
    address payable fee;

    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 ref_bonus;
        uint256 lottery_bonus;
        uint256 jackpot_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        Structure[12] structures;
        Total totals;
    }

    struct Structure {
        uint256 quantity;
        uint256 income;
    }

    struct Total {
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_lottery;
        uint256 total_jackpot;
    }

    mapping(address => User) users;
    uint8[12] ref_bonuses;
    uint8[3] ref_direct;
    uint256[4] cycles;
    uint256 lottery_cycle;
    uint256 jackpot_cycle;
    uint256 lottery_balance;
    uint256 jackpot_balance;
    uint8 lottery_users_len;
    uint8 jackpot_users_len;
    address[12] lottery_users;
    address[12] jackpot_users;
    uint256 total_users;
    uint256 total_deposited;
    uint256 total_withdraw;
    uint256 total_lottery;
    uint256 total_jackpot;
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event RefPayout(address indexed addr, address indexed from, uint256 amount);
    event LotteryPayout(address indexed addr, uint256 amount);
    event JackpotPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _root, address payable _fee, ITRC20 _token) public {
        root = _root;
        fee = _fee;
        token = _token;
        ref_bonuses = [50,10,10,10,10,10,10,5,5,5,5,5];
        ref_direct = [5,2,3];
        cycles = [1e10,3e10,9e10,2e11];
    }

    function _drawLottery() private {
        lottery_cycle++;
        uint256 win = lottery_balance / 2;
        (uint8 indx) = rand(lottery_cycle);
        if(indx >= lottery_users.length) indx = 0;
        address winner = lottery_users[indx];
        if(winner != address(0)){
            users[winner].lottery_bonus += win;
            jackpot_users[jackpot_users_len] = winner;
            jackpot_users_len++;

            emit LotteryPayout(winner, win);
        }
        jackpot_balance += lottery_balance - win;
        lottery_balance = 0;
        lottery_users_len = 0;
    }

    function _drawJackpot() private {
        jackpot_cycle++;
        (uint8 indx) = rand(jackpot_cycle);
        if(indx >= jackpot_users.length) indx = 0;
        address winner = jackpot_users[indx];
        if(winner != address(0)){
            users[winner].jackpot_bonus += jackpot_balance;

            emit JackpotPayout(winner, jackpot_balance);
        }
        jackpot_balance = 0;
        jackpot_users_len = 0;
    }

    function deposit(address _upline, uint256 _amount) external {
        address _addr = msg.sender;
        require(!_addr.isContract, "No Contract");
        User storage u = users[_addr];
        bool _addstruct = false;
        if(u.upline == address(0) && _addr != _upline && _addr != root && (users[_upline].deposit_time > 0
        || _upline == root)) {
            u.upline = _upline;
            users[_upline].referrals++;
            total_users++;
            _addstruct = true;
            emit Upline(_addr, _upline);
        }
        require(u.upline != address(0) || _addr == root, "No upline");
        if(u.deposit_time > 0) {
            u.cycle++;
            require(u.payouts >= this.maxPayoutOf(u.deposit_amount), "Deposit already exists");
            require(
                _amount >= u.deposit_amount + (u.deposit_amount / 10 < 10 ? 10 : u.deposit_amount / 10) &&
                _amount <= cycles[u.cycle > 3 ? 3 : u.cycle], "Bad amount");
        } else
            require(_amount >= 1e7 && _amount <= cycles[0], "Bad amount");
        u.payouts = 0;
        u.deposit_amount = _amount;
        u.deposit_payouts = 0;
        u.deposit_time = uint40(block.timestamp);
        u.totals.total_deposits += _amount;
        total_deposited += _amount;
        token.transferFrom(_addr, address(this), _amount);

        emit NewDeposit(_addr, _amount);

        uint256 ref_length = _addstruct == true ? 12 : 3;
        for(uint8 i = 0; i < ref_length; i++) {
            if(_upline == address(0)) break;
            if(users[_upline].referrals >= i + 1 && i < 3) {
                uint256 bonus = _amount * ref_direct[i] / 100;
                users[_upline].direct_bonus += bonus;
                users[_upline].structures[i].income += bonus;
                emit DirectPayout(_upline, _addr, bonus);
            }
            if(_addstruct == true) users[_upline].structures[i].quantity++;
            _upline = users[_upline].upline;
        }
        if(_amount >= 1e8){
            lottery_balance += _amount / 100;
            lottery_users[lottery_users_len] = _addr;
            lottery_users_len++;
            if(lottery_users_len >= 12) _drawLottery();
            if(jackpot_users_len >= 12) _drawJackpot();
        }
        token.transfer(fee, _amount / 20);
    }

    function withdraw() external {
        address _addr = msg.sender;
        User storage u = users[_addr];
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(_addr);
        require(u.payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(u.payouts + to_payout > max_payout) to_payout = max_payout - u.payouts;
            u.deposit_payouts += to_payout;
            u.payouts += to_payout;

            address up = u.upline;
            for(uint8 i = 0; i < 12; i++) {
                if(up == address(0)) break;
                if(users[up].referrals >= i + 1) {
                    uint256 bonus = to_payout * ref_bonuses[i] / 100;
                    users[up].ref_bonus += bonus;
                    users[up].structures[i].income += bonus;
                    emit RefPayout(up, _addr, bonus);
                }
                up = users[up].upline;
            }
        }

        uint256 _bonus;
        // Direct payout
        if(u.payouts < max_payout && u.direct_bonus > 0) {
            _bonus = u.direct_bonus;
            if(u.payouts + _bonus > max_payout) _bonus = max_payout - u.payouts;
            u.direct_bonus -= _bonus;
            u.payouts += _bonus;
            to_payout += _bonus;
        }

        // Ref payout
        if(u.payouts < max_payout && u.ref_bonus > 0) {
            _bonus = u.ref_bonus;
            if(u.payouts + _bonus > max_payout) _bonus = max_payout - u.payouts;
            u.ref_bonus -= _bonus;
            u.payouts += _bonus;
            to_payout += _bonus;
        }

        // Lottery payout
        if(u.payouts < max_payout && u.lottery_bonus > 0) {
            _bonus = u.lottery_bonus;
            if(u.payouts + _bonus > max_payout) _bonus = max_payout - u.payouts;
            u.lottery_bonus -= _bonus;
            u.payouts += _bonus;
            u.totals.total_lottery += _bonus;
            to_payout += _bonus;
            total_lottery += _bonus;
        }

        // Jackpot payout
        if(u.payouts < max_payout && u.jackpot_bonus > 0) {
            _bonus = u.jackpot_bonus;
            if(u.payouts + _bonus > max_payout) _bonus = max_payout - u.payouts;
            u.jackpot_bonus -= _bonus;
            u.payouts += _bonus;
            u.totals.total_jackpot += _bonus;
            to_payout += _bonus;
            total_jackpot += _bonus;
        }

        require(to_payout > 0, "Zero payout");
        u.totals.total_payouts += to_payout;
        total_withdraw += to_payout;
        token.transfer(_addr, to_payout);

        emit Withdraw(_addr, to_payout);

        if(u.payouts >= max_payout) emit LimitReached(_addr, u.payouts);
    }

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 312 / 100;
    }

    function payoutOf(address _addr) view external returns(uint256 to_payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
        if(users[_addr].deposit_payouts < max_payout) {
            to_payout = (users[_addr].deposit_amount * (block.timestamp - users[_addr].deposit_time) / 1 days / 100)
            - users[_addr].deposit_payouts;
            if(users[_addr].deposit_payouts + to_payout > max_payout)
                to_payout = max_payout - users[_addr].deposit_payouts;
        }
    }

    function userInfo(address _addr) view external returns(
        address upline,
        uint40 deposit_time,
        uint256 deposit_amount,
        uint256 payouts,
        uint256 direct_bonus,
        uint256 ref_bonus,
        uint256 lottery_bonus,
        uint256 jackpot_bonus) {
        User memory u = users[_addr];
        return (
        u.upline,
        u.deposit_time,
        u.deposit_amount,
        u.payouts,
        u.direct_bonus,
        u.ref_bonus,
        u.lottery_bonus,
        u.jackpot_bonus);
    }

    function userInfoTotals(address _addr) view external returns(
        uint256 cycle,
        uint256 referrals,
        uint256 total_deposits,
        uint256 total_payouts,
        uint256 _total_lottery,
        uint256 _total_jackpot) {
        User memory u = users[_addr];
        return (
        u.cycle,
        u.referrals,
        u.totals.total_deposits,
        u.totals.total_payouts,
        u.totals.total_lottery,
        u.totals.total_jackpot);
    }

    function userInfoStructure(address _addr) view external returns(
        uint256[12] memory quantity,
        uint256[12] memory income) {
        for(uint8 i = 0; i < 12; i++) {
            quantity[i] = users[_addr].structures[i].quantity;
            income[i] = users[_addr].structures[i].income;
        }
    }

    function contractInfo() view external returns(
        uint256 _total_users,
        uint256 _total_deposited,
        uint256 _total_withdraw,
        uint256 _total_lottery,
        uint256 _total_jackpot) {
        return (
        total_users,
        total_deposited,
        total_withdraw,
        total_lottery,
        total_jackpot);
    }

    function lotteryInfo() view external returns(
        uint256 _lottery_cycle,
        uint256 _jackpot_cycle,
        uint8 _lottery_users_len,
        uint8 _jackpot_users_len,
        uint256 _lottery_balance,
        uint256 _jackpot_balance) {
        return (
        lottery_cycle,
        jackpot_cycle,
        lottery_users_len,
        jackpot_users_len,
        lottery_balance,
        jackpot_balance);
    }

    function lotteryUsers() view external returns(address[12] memory users_lottery,address[12] memory users_jackpot) {
        users_lottery = lottery_users;
        users_jackpot = jackpot_users;
    }

    function setToken(ITRC20 _token) external{ require(msg.sender == root, "Only root"); token = _token; }
    function setFee(address payable _fee) external{ require(msg.sender == root, "Only root"); fee = _fee; }
    function setRoot(address payable _root) external{ require(msg.sender == root, "Only root"); root = _root; }

    function rand(uint256 num) view private returns(uint8 indx){
        return uint8(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, blockhash(block.number - 1),
            num)))%12);
    }
}

interface ITRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}