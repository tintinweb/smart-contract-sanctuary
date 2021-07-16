//SourceUnit: TronDeFiYieldFarm.sol

pragma solidity ^0.5.9;

contract TronDeFi {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
}

contract TronDeFiYieldFarm {
    uint256 constant MINIMUM_AMOUNT     = 1000 trx;
    uint256 constant ORDER_PERIOD       = 300 days;
    uint256 constant SUPER_TEAM_VALUE   = 5000000 trx;
    uint8   constant MAX_SUPER_TEAM_NUM = 10;

    struct Order{
        uint256 tdf_value;
        uint256 start_time;
        uint256 conversion_time;
    }

    struct User{
        address ref;
        bool    is_user;
        uint256 tdf_value;
        uint256 total_tdf_value;
        uint16  order_seq;
        mapping(uint16 => Order) orders;

        bool    is_team_leader;
        bool    is_super_team;
        uint256 team_value;
    }

    mapping(address => User) users;
    TronDeFi  tronDefi;
    address[] teams;
    address[] super_teams;
    uint256 liquidity_user_num;
    uint256 all_liquidity_value;
    address funds;

    constructor(address tronDefi_addr, address _funds) public {
        funds = _funds;
        users[funds].is_user = true;
        // 连接TDF代币的智能合约地址
        // connect the TDF Token contract
        tronDefi = TronDeFi(tronDefi_addr);
    }

    /// 增加一笔流动性挖矿订单
    /// add a liquidity mining order
    /// @param amount the TDF amount / TDF的数量
    /// @param ref the referrer address / 推荐人地址
    function add_liquidity(uint256 amount, address ref) public returns (bool){
        require(amount >= MINIMUM_AMOUNT, "A minimum of 1000 TDF to add liquidity");
        require((users[msg.sender].is_user || users[ref].is_user), "The referrer is not TronDeFi user");

        bool result = tronDefi.transferFrom(msg.sender, address(this), amount);
        require(result == true);

        if(users[msg.sender].is_user == false){
            users[msg.sender].ref = ref;
            users[msg.sender].is_user = true;
            liquidity_user_num += 1;
            
            if(ref == funds){
                users[msg.sender].is_team_leader = true;
                teams.push(msg.sender);
            }
        }

        create_order(msg.sender, users[msg.sender].order_seq, amount);

        return true;
    }

    /// 用TDF收益余额再次复投一笔流动性挖矿订单
    /// add a liquidity mining order by user TDF income balance
    function add_liquidity_by_balance() public returns (bool){
        require(users[msg.sender].is_user, "Not the TronDeFi user");
        uint16 order_seq = users[msg.sender].order_seq;
        uint256 amount = users[msg.sender].tdf_value;

        if(order_seq > 0){
            for(uint16 i = 0; i < order_seq; i++){
                uint256 bonus = calc_hold_bonus(users[msg.sender].orders[i].tdf_value, 
                                                users[msg.sender].orders[i].start_time, 
                                                users[msg.sender].orders[i].conversion_time);
                if(bonus > 0){
                    users[msg.sender].orders[i].conversion_time = block.timestamp;
                    amount += bonus;
                }
            }
        }
        
        require(amount >= MINIMUM_AMOUNT, "Insufficient TDF value to add liquidity");
        
        create_order(msg.sender, order_seq, amount);
        users[msg.sender].tdf_value = 0;

        return true;
    }

    /// 创建一笔详细的流动性挖矿订单
    /// create a liquidity mining order
    /// @param addr user address / 用户地址
    /// @param order_seq user's order sequence number / 用户的订单序列号
    /// @param amount the TDF amount / 订单的TDF数量
    function create_order(address addr, uint16 order_seq, uint256 amount) private {
        uint256 user_total_tdf_value = users[addr].total_tdf_value;
        address _ref = users[addr].ref;
        address _current = addr;
        for(uint8 i = 0; i < 9; i++){
            if(users[_ref].is_user){
                if(_ref != funds){
                    // 基金账户不能获得推荐奖金
                    // ths funds can not get the referrer bonus
                    uint256 _ref_total_tdf_value = users[_ref].total_tdf_value;
                    uint256 real_ref_amount = 0;
                    if(_ref_total_tdf_value >= (user_total_tdf_value + amount)){
                        // 烧伤机制：只有推荐人的TDF投资总额大于当前投资人的TDF投资总额，才能得到推荐奖金
                        // Burns Mechanism: only the referrer's total TDF great than the current user's total tdf
                        real_ref_amount = amount;
                    } else if(_ref_total_tdf_value > user_total_tdf_value){
                        // 此时推荐人只能获取部分推荐奖金
                        // the referrer could only get the part of bonus
                        real_ref_amount = _ref_total_tdf_value - user_total_tdf_value;
                    }
                    uint256 ref_bonus = calc_ref_bonus(real_ref_amount, i);
                    if(ref_bonus > 0){
                        users[_ref].tdf_value += ref_bonus;
                    }
                }

                if(users[_current].is_team_leader){
                    // 团队长累积团队TDF投资总额
                    // only team leader can grow up to the super team
                    users[_current].team_value += amount;
                    if(super_teams.length < MAX_SUPER_TEAM_NUM && 
                       users[_current].team_value >= SUPER_TEAM_VALUE &&
                       users[_current].is_super_team == false){
                           users[_current].is_super_team = true;
                           super_teams.push(_current);
                    }
                }
            } else {
                break;
            }
            _current = _ref;
            _ref = users[_ref].ref;
        }

        for(uint8 i = 0; i < super_teams.length; i++){
            // 超级团队获取特别奖金
            // super team get the special bonus
            address super_team = super_teams[i];
            users[super_team].tdf_value += amount * 1 / 100;
        }
        
        // 创建一笔实际的流动性挖矿订单
        // create a new liquidity mining order
        users[addr].orders[order_seq].tdf_value = amount;
        users[addr].orders[order_seq].start_time = block.timestamp;
        users[addr].orders[order_seq].conversion_time = block.timestamp;
        users[addr].order_seq += 1;

        users[addr].total_tdf_value += amount;
        // 基金账户获得保留基金奖励
        // ths funds get the reserve fund
        users[funds].tdf_value += amount * 10 / 100;
        all_liquidity_value += amount;
    }

    /// 提现流动性挖矿收益和推荐收益
    /// withdraw the liquidity mining value & ref bonus value
    function withdraw_tdf() public returns (bool){
        require(users[msg.sender].is_user, "Not the TronDeFi user");
        uint16 order_seq = users[msg.sender].order_seq;
        uint256 amount = users[msg.sender].tdf_value;

        if(order_seq > 0){
            for(uint16 i = 0; i < order_seq; i++){
                uint256 bonus = calc_hold_bonus(users[msg.sender].orders[i].tdf_value, 
                                                users[msg.sender].orders[i].start_time, 
                                                users[msg.sender].orders[i].conversion_time);
                if(bonus > 0){
                    users[msg.sender].orders[i].conversion_time = block.timestamp;
                    amount += bonus;
                }
            }
        }
        
        require(amount > 0, "Insufficient TDF value to withdraw");
        users[msg.sender].tdf_value = 0;

        bool result = tronDefi.transfer(msg.sender, amount);
        require(result == true);
        return true;
    }

    /// 赎回一笔指定ID的流动性挖矿订单
    /// redeem the liquidity mining order with the order_id
    /// @param order_id the the liquidity mining order id / 流动性挖矿的订单ID
    function redeem(uint16 order_id) public returns (bool){
        require(users[msg.sender].is_user, "Not the TronDeFi user");
        require(users[msg.sender].order_seq > 0, "Never add one liquidity order");
        require(order_id < users[msg.sender].order_seq, "Redeem order id must be less the bigest seq");
        
        uint256 tdf_value = users[msg.sender].orders[order_id].tdf_value;
        uint256 start_time = users[msg.sender].orders[order_id].start_time; 
        uint256 conversion_time = users[msg.sender].orders[order_id].conversion_time;

        // 计算该订单的赎回剩余价值
        // calculate the order's residual value
        uint256 residual_value = calc_residual_value(tdf_value, start_time, conversion_time);
        uint256 start_days = (block.timestamp - start_time) / 1 days;
        // 只能创建75（不含）天之内的订单
        // only the order be created within 75 days
        require(start_days < 75, "Redeem need within 75 days");
        require(residual_value > 0 && residual_value < tdf_value, "Insufficient residual value to redeem");

        users[msg.sender].orders[order_id].tdf_value = 0;
        users[msg.sender].orders[order_id].start_time = 0;
        users[msg.sender].orders[order_id].conversion_time = 0;

        users[msg.sender].total_tdf_value -= tdf_value;

        bool result = tronDefi.transfer(msg.sender, residual_value);
        require(result == true);
        return true;
    }

    /// 查询用户的基本信息
    /// query basic info of the account 
    function query_account(address addr) public view returns(uint256, bool, uint16, uint256, uint256){
        uint16 order_seq = users[addr].order_seq;
        uint256 amount = users[addr].tdf_value;

        for(uint16 i = 0; i < order_seq; i++){
            amount += calc_hold_bonus(users[addr].orders[i].tdf_value, 
                                      users[addr].orders[i].start_time, 
                                      users[addr].orders[i].conversion_time);
        }

        uint256 allowance = tronDefi.allowance(addr, address(this));
        return (allowance, users[addr].is_user, order_seq, users[addr].total_tdf_value, amount);
    }

    /// 查询用户的扩展信息
    /// query more info of the account 
    function query_account_more(address addr)public view returns(uint256, uint256, bool, uint256, bool, uint256){
        return (tronDefi.balanceOf(addr), addr.balance, users[addr].is_team_leader, users[addr].team_value, users[addr].is_super_team, super_teams.length);
    }

    /// 查询一笔流动性挖矿订单的明细
    /// query the detail of the order
    function query_account_order(address addr, uint16 order_id)public view returns(uint256, uint256, uint256, uint256, uint256){
        uint256 tdf_value       = 0;
        uint256 start_time      = 0;
        uint256 conversion_time = 0;
        uint256 residual_value  = 0;
        uint256 start_days      = 0;

        if(users[addr].is_user && users[addr].order_seq > 0 && order_id < users[addr].order_seq){
            tdf_value       = users[addr].orders[order_id].tdf_value;
            start_time      = users[addr].orders[order_id].start_time;
            conversion_time = users[addr].orders[order_id].conversion_time;
            residual_value  = calc_residual_value(tdf_value, start_time, conversion_time);
            if(start_time > 0){
                start_days = (block.timestamp - start_time) / 1 days;
            }
        }

        return (tdf_value, start_time, conversion_time, residual_value, start_days);
    }

    /// 查询合约的统计信息
    /// query the summary info of the contract
    /// @param index the array index of the teams & super teams / 团队和超级团队的索引ID
    function query_summary(uint256 index)public view returns(uint256, uint256, uint256, uint256, address, address) {
        address t = index < teams.length ? teams[index] : address(0);
        address s = index < super_teams.length ? super_teams[index] : address(0);
        return (liquidity_user_num, all_liquidity_value, teams.length, super_teams.length, t, s);
    }

    /// 计算推荐奖金
    /// calculate the referrer bonus
    /// @param amount total amount / 要计算推荐奖金的TDF数量
    /// @param i the referrer level(0~8) / 推荐人的层级
    function calc_ref_bonus(uint256 amount, uint8 i) private pure returns(uint256){
        if(i == 0){ return amount * 8 / 100; }
        if(i == 1){ return amount * 6 / 100; }
        if(i == 2){ return amount * 4 / 100; }
        if(i == 3){ return amount * 2 / 100; }
        if(i == 4){ return amount * 5 / 1000; }
        if(i == 5){ return amount * 4 / 1000; }
        if(i == 6){ return amount * 3 / 1000; }
        if(i == 7){ return amount * 2 / 1000; }
        if(i == 8){ return amount * 1 / 1000; }
    }

    /// 计算用户持有流动性挖矿的订单的挖矿收益
    /// calculate the user's liquidity mining order bonus
    /// @param amount the order TDF value / 流动性挖矿订单的TDF数量
    /// @param start_time the time of order create / 流动性挖矿订单的创建时间
    /// @param conversion_time the time of withraw or liquidity mining by balance / 流动性挖矿订单收益的提现或再投资的时间
    function calc_hold_bonus(uint256 amount, uint256 start_time, uint256 conversion_time) private view returns(uint256) {
        uint256 hold_bonus = 0;

        if(amount > 0 && 
           start_time > 0 && 
           conversion_time > 0 && 
           block.timestamp > start_time && 
           block.timestamp > conversion_time &&
           (conversion_time - start_time) < ORDER_PERIOD){

            uint256 start_days = (block.timestamp - start_time) / 1 days;
            uint256 hold_days =  (block.timestamp - conversion_time) / 1 days;
            if(start_days > ORDER_PERIOD){
                hold_days = hold_days - (start_days - ORDER_PERIOD);
            }

            if(hold_days > ORDER_PERIOD){
                // 最大挖矿时间不能大于最大挖矿时间
                // the max days equals the ORDER_PERIOD
                hold_days = ORDER_PERIOD;
            }
            // 每天挖矿产出投资TDF数量的1%
            // release 1% TDF per day
            hold_bonus = amount * hold_days / 100;
        }

        return hold_bonus;
    }
    
    /// 计算流动性挖矿订单赎回后的剩余价值
    /// calculate the residual value when user redeem the liquidity mining order
    function calc_residual_value(uint256 amount, uint256 start_time, uint256 conversion_time) private pure returns(uint256) {
        // 最多赎回投资TDF数量的75%
        // the max residual value is 75% of the original order value
        uint256 residual_value = amount * 75 / 100;

        if(amount > 0 && start_time > 0 && conversion_time > 0 && conversion_time > start_time){
            // 扣除已经提现或再投资的TDF数量
            // minus the allocated bonus of the order 
            uint256 conversion_days =  (conversion_time - start_time) / 1 days;
            if(conversion_days < 75){
                uint256 conversion_amount = amount * conversion_days / 100;
                residual_value -= conversion_amount;
                if(residual_value > amount){
                    residual_value = 0;
                }
            } else {
                residual_value = 0;
            }
        }
        
        return residual_value;
    }
}