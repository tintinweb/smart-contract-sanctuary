//SourceUnit: Zeus.sol

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.5.10;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;

        return c;
    }
}

contract Rhea {
    function balanceOf(address who) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function query_price() public view returns(uint);
    function query_tower() public view returns(uint);
}

contract TRC20 {
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint);
    function approve(address spender, uint value) public returns (bool);
    function burn(uint value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
    event Mining(address indexed owner, uint value);
}

contract StandardToken is TRC20 {
    using SafeMath for uint;

    uint public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) internal allowed;
    
    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender], "Insufficient allowed");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

    function burn(uint _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function _mining(address _owner, uint _value) internal returns (bool){
        require(_owner != address(0), "Address is null");
        require(_value > 0);
        balances[_owner] = balances[_owner].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Mining(_owner, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        require(_from != address(0), "Address is null");
        require(_to != address(0), "Address is null");
        require(_value <= balances[_from], "Insufficient balance");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract Zeus is StandardToken {
    string  public name;
    string  public symbol;
    uint    public decimals;

    //  start with 172800 token per day, cutback 5% every 60 days
    uint constant START_DAILY_TOKEN = 172800 trx; // init daily yield 
    uint constant CUTBACK_DAYS      = 60;         // cutback cycle days
    uint constant CUTBACK_RATE      = 5;          // cutback rate
    uint constant CUTBACK_RATE_PER  = 100;        // cutback rate percent

    // the max token num
    uint constant MAX_KAS_TOKEN     = 210000000 trx;
    
    Rhea rhea;
    uint contract_start_date;

    uint total_activity_user;
    uint total_pledge_cas;
    uint total_ref_power;
    uint total_cash_kas;
    uint total_mining_token;

    struct Gain{
        uint timestamp;
        uint kas;
        uint star_kas;
        uint super_kas;
    }
    mapping(address => mapping(uint => Gain)) gain_datas;

    struct BigNode{
        uint star_node;
        uint super_node;
    }
    mapping(uint => BigNode) node_claims;

    struct User{
        bool    actived;
        address ref;
        uint direct_members;
        uint indirect_members;

        uint pledge_cas;
        uint ref_cas;
        uint ref_power;
        uint start_date;
        uint total_mining_kas;
    }
    mapping(address => User) users;
    address[] user_list;

    constructor(string memory _name, string memory _symbol, address _rhea_addr) public {
        name = _name;
        symbol = _symbol;
        decimals = 6;

        contract_start_date = block.timestamp.div(1 days);
        // connect the rhea contract
        rhea = Rhea(_rhea_addr);

        // init the root user
        users[msg.sender].actived = true;
        users[msg.sender].pledge_cas = 1 trx;
        users[msg.sender].start_date = contract_start_date;

        // the first user
        user_list.push(msg.sender);
        total_activity_user = 1;
    }

    function () external payable {}

    function active_mining(address ref) public returns (bool) {
        require(users[msg.sender].actived == false, "You are already active mining");
        require(users[ref].actived == true, "The referrer is not activity user");
        uint tower = rhea.query_tower();
        if(tower < 10){
            require(rhea.balanceOf(msg.sender) >= 30 trx, "Need 30 CAS token to active mining");
        } else {
            require(rhea.balanceOf(msg.sender) >= 12 trx, "Need 12 CAS token to active mining");
        }

        if(tower < 10){
            // 18 CAS token bonus to direct referrer within 10 towers
            rhea.transferFrom(msg.sender, address(ref), 18 trx);
        }

        if(total_activity_user > 6){
            for(uint i = 0; i < 6; i++){
                // 12 CAS token bonus to 6 lucky guys, each guys can got 2 CAS token 
                uint lucky_num = uint(keccak256(abi.encodePacked(block.timestamp.add(i), msg.sender))) % total_activity_user;
                address lucky_guys = user_list[lucky_num];
                if(lucky_guys != address(0)){
                    rhea.transferFrom(msg.sender, lucky_guys, 2 trx);
                }
            }
        } else {
            rhea.transferFrom(msg.sender, address(this), 12 trx);
        }

        // init user info
        users[msg.sender].actived = true;
        users[msg.sender].ref = ref;

        address _ref = ref;
        for(uint i = 0; i < 9; i++){
            if(users[_ref].actived == true){
                if(i == 0){
                    // count direct members
                    users[_ref].direct_members = users[_ref].direct_members.add(1);
                } else {
                    // count indirect members
                    users[_ref].indirect_members = users[_ref].indirect_members.add(1);
                }

                _ref = users[_ref].ref;
            } else {
                break;
            }
        }

        // count total info
        total_activity_user = total_activity_user.add(1);
        user_list.push(msg.sender);

        return true;
    }

    function pledge_mining(uint amount) public returns (bool) {
        require(users[msg.sender].actived == true, "You are not activity user");
        require(amount >= 100 trx, "A minimum of 100 CAS token to pledge mining");
        require(rhea.balanceOf(msg.sender) >= amount, "Not enough CAS token to pledge mining");

        if(total_activity_user < 20000){
            require(amount.add(users[msg.sender].pledge_cas) <= 100000 trx, "Need all pledge cas <= 100000");
        } else {
            require(amount.add(users[msg.sender].pledge_cas) <= 200000 trx, "Need all pledge cas need <= 200000");
        }

        // calc the referrer power up to 9 levels
        uint basic_power = calc_basic_power(amount);
        address ref = users[msg.sender].ref;
        
        for(uint i = 0; i < 9; i++){
            if(users[ref].actived == true){
                uint ref_power;
                if(i == 0){
                    // add direct referrer with 20% bonus power
                    ref_power = basic_power.mul(20).div(100);
                } else {
                    // add indirect referrer with 4% bonus power
                    ref_power = basic_power.mul(4).div(100);
                }

                uint ref_user_basic_power = calc_basic_power(users[ref].pledge_cas);
                uint max_ref_power;

                if(users[ref].pledge_cas < 10000 trx){
                    // max ref power up to 30 multiply
                    max_ref_power = ref_user_basic_power.mul(30);
                } else {
                    // max ref power up to 35 multiply
                    max_ref_power = ref_user_basic_power.mul(35);
                }

                // add the ref power
                if(users[ref].ref_power.add(ref_power) > max_ref_power){
                    users[ref].ref_power = max_ref_power;
                } else {
                    users[ref].ref_power = users[ref].ref_power.add(ref_power);
                }

                // add the ref cas token
                users[ref].ref_cas = users[ref].ref_cas.add(amount);

                // add total ref power
                total_ref_power = total_ref_power.add(ref_power);

                ref = users[ref].ref;
            } else {
                break;
            }
        }
        
        // add the pledge CAS token
        users[msg.sender].pledge_cas = users[msg.sender].pledge_cas.add(amount);
        // reset start_date for the credit power
        users[msg.sender].start_date = block.timestamp.div(1 days);

        // add total
        total_pledge_cas = total_pledge_cas.add(amount);
        
        // pledge token to mining pool
        rhea.transferFrom(msg.sender, address(this), amount);
        return true;
    }

    // redeem all pledge CAS token
    function redeem() public returns (bool) {
        require(users[msg.sender].actived == true, "You are not activity user");
        uint pledge_cas = users[msg.sender].pledge_cas;
        require(pledge_cas > 0, "Not enough CAS token to redeem");
        
        uint basic_power = calc_basic_power(pledge_cas);
        address ref = users[msg.sender].ref;
        
        for(uint i = 0; i < 9; i++){
            if(users[ref].actived == true){
                uint ref_power;
                if(i == 0){
                    // sub the direct referrer with 20% bonus power
                    ref_power = basic_power.mul(20).div(100);
                } else {
                    // sub indirectly referrer with 4% bonus power
                    ref_power = basic_power.mul(4).div(100);
                }

                // sub the ref power
                if(ref_power > users[ref].ref_power){
                    users[ref].ref_power = 0;
                } else {
                    users[ref].ref_power = users[ref].ref_power.sub(ref_power);
                }

                // sub the ref cas token
                if(pledge_cas > users[ref].ref_cas){
                    users[ref].ref_cas = 0;
                } else {
                    users[ref].ref_cas = users[ref].ref_cas.sub(pledge_cas);
                }

                // sub total ref power
                if(ref_power > total_ref_power){
                    total_ref_power = 0;
                } else {
                    total_ref_power = total_ref_power.sub(ref_power);
                }

                ref = users[ref].ref;
            } else {
                break;
            }
        }

        // remove the pledge CAS token
        users[msg.sender].pledge_cas = 0;
        // reset start_date for the credit power
        users[msg.sender].start_date = 0;

        // sub total pledge cas
        if(pledge_cas > total_pledge_cas){
            total_pledge_cas = 0;
        } else {
            total_pledge_cas = total_pledge_cas.sub(pledge_cas);
        }

        // return the pledge CAS token to user
        rhea.transfer(msg.sender, pledge_cas);
        return true;
    }

    // claim daily gain
    function claim() public returns (bool){
        require(total_mining_token < MAX_KAS_TOKEN, "Finished mining");
        require(users[msg.sender].actived == true, "You are not activity user");
        // calc daily gain of KAS token
        (uint timestamp, uint kas, uint star_kas, uint super_kas) = query_daily_gain(msg.sender);
        require(timestamp == 0, "Already claimed");
        require(kas > 0, "Not enough KAS token to claim");
        
        // save the claim data
        uint gain_date = block.timestamp.div(1 days);
        uint total_kas = kas;

        Gain storage gain_data = gain_datas[msg.sender][gain_date];
        gain_data.timestamp = block.timestamp;
        gain_data.kas = kas;
        
        // count the star node & super node claim 
        uint star_node = node_claims[gain_date].star_node;
        uint super_node = node_claims[gain_date].super_node;
        if(super_kas > 0 && super_node < 10 ){ // max 10 super nodes
            // add super node special bonus
            total_kas = total_kas.add(super_kas);
            gain_data.super_kas = super_kas;

            node_claims[gain_date].super_node = super_node.add(1);
        } else if(star_kas > 0 && star_node < 100){ // max 100 star nodes
            // add star node special bonus
            total_kas = total_kas.add(star_kas);
            gain_data.star_kas = star_kas;
            
            node_claims[gain_date].star_node = star_node.add(1);
        }
        
        total_mining_token = total_mining_token.add(total_kas);
        if(total_mining_token > MAX_KAS_TOKEN){
            total_kas = total_kas.sub(total_mining_token.sub(MAX_KAS_TOKEN));
            total_mining_token = MAX_KAS_TOKEN;
        }

        // count user total mining kas
        users[msg.sender].total_mining_kas = users[msg.sender].total_mining_kas.add(total_kas);

        // mining KAS token for user
        _mining(msg.sender, total_kas);
        return true;
    }

    function cash(uint amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Not enough KAS token to cash");

        uint price = rhea.query_price();
        uint value = amount.mul(price).div(1 trx);

        total_cash_kas = total_cash_kas.add(amount);

        // burn the KAS token
        burn(amount);
        
        // 5% cash fee
        value = value.sub(value.mul(5).div(100));
        msg.sender.transfer(value);

        return true;
    }

    function query_daily_gain(address addr) public view returns (uint, uint, uint, uint){
        uint gain_date = block.timestamp.div(1 days);
        Gain memory gain_data = gain_datas[addr][gain_date];

        if(gain_data.timestamp > 0){
            return (gain_data.timestamp,
                    gain_data.kas,
                    gain_data.star_kas,
                    gain_data.super_kas);
        } else {
            uint start_date = users[addr].start_date;

            // calc daily gain
            uint kas;
            uint star_kas;
            uint super_kas;

            if(users[addr].pledge_cas > 0 && gain_date > start_date){
                (kas, star_kas, super_kas) = calc_kas(addr);
            }
            
            return (0, kas, star_kas, super_kas);
        }
    }

    function is_big_node(address addr) public view returns(bool, bool){
        uint pledge_cas = users[addr].pledge_cas;
        uint kas = balances[addr];
        uint hold_days = block.timestamp.div(1 days).sub(users[addr].start_date);
        uint ref_cas = users[addr].ref_cas;

        bool is_star_node;
        bool is_super_node;
        if(pledge_cas >= 200000 trx && kas >= 600000 trx && hold_days >= 70 && ref_cas >= 20000000 trx){
            // super node:
            //  1. pledge 200000 CAS
            //  2. hold 600000 KAS
            //  3. credit power 35%
            //  4. total user ref pledge CAS 20000000
            is_super_node = true;
        } else if(pledge_cas >= 100000 trx && kas >= 200000 trx && hold_days >= 70 && ref_cas >= 5000000 trx){
            // star node: 
            //  1. pledge 100000 CAS
            //  2. hold 200000 KAS
            //  3. credit power 35%
            //  4. total user ref pledge CAS 5000000
            is_star_node = true;
        } 
        return (is_star_node, is_super_node);
    }

    function query_account(address addr)public view returns(uint, bool, uint, uint, uint, uint) {
        uint allowance = rhea.allowance(addr, address(this));
        return (allowance, users[addr].actived, addr.balance, rhea.balanceOf(addr), balances[addr], users[addr].total_mining_kas);
    }

    function query_ref(address addr)public view returns(address) {
        return users[addr].ref;
    }

    function query_team(address addr)public view returns(uint, uint, uint) {
        return (users[addr].direct_members, users[addr].indirect_members, users[addr].ref_cas);
    }

    function query_mining(address addr)public view returns(uint, uint, uint, uint) {
        return (users[addr].pledge_cas, users[addr].ref_cas, users[addr].ref_power, users[addr].start_date);
    }

    function query_power(address addr) public view returns(uint, uint, uint, uint) {
        uint basic_power = calc_basic_power(users[addr].pledge_cas);
        uint hold_days;

        if(users[addr].start_date > 0){
            hold_days = block.timestamp.div(1 days).sub(users[addr].start_date);
        }

        if(users[addr].pledge_cas < 10000 trx){
            // max credit power up to 60 days
            hold_days = hold_days > 60 ? 60 : hold_days;
        } else {
            // max credit power up to 70 days
            hold_days = hold_days > 70 ? 70 : hold_days;
        }

        uint total_power = calc_basic_power(total_pledge_cas).add(total_ref_power);

        return (basic_power, users[addr].ref_power, hold_days, total_power);
    }

    function query_daily_token() public view returns(uint) {
        uint pass_cutback_cycles = block.timestamp.div(1 days).sub(contract_start_date).div(CUTBACK_DAYS);
        uint _token = START_DAILY_TOKEN;
        for(uint i = 0; i < pass_cutback_cycles; i++){
            _token = _token.sub(_token.mul(CUTBACK_RATE).div(CUTBACK_RATE_PER));
        }
        return _token;
    }

    function query_summary() public view returns(uint, uint, uint, uint, uint) {
        return (address(this).balance, total_activity_user, total_pledge_cas, total_ref_power, total_cash_kas);
    }

    function calc_basic_power(uint cas_amount) public pure returns(uint) {
        if(cas_amount < 500 trx){
            // 1-499        : 0.010 power
            return cas_amount.mul(10).div(1000);
        } else if(cas_amount < 1000 trx){
            // 500-999      : 0.012
            return cas_amount.mul(12).div(1000);
        } else if(cas_amount < 5000 trx){
            // 1000-4999    : 0.014
            return cas_amount.mul(14).div(1000);
        } else if(cas_amount < 10000 trx){
            // 5000-9999    : 0.016
            return cas_amount.mul(16).div(1000);
        } else if(cas_amount < 50000 trx){
            // 10000-49999  : 0.018
            return cas_amount.mul(18).div(1000);
        } else if(cas_amount < 100000 trx){
            // 50000-99999  : 0.019
            return cas_amount.mul(19).div(1000);
        } else {
            // 100000—200000: 0.020
            return cas_amount.mul(20).div(1000);
        }
    }

    function calc_kas(address addr) private view returns(uint, uint, uint){
        uint basic_power = calc_basic_power(users[addr].pledge_cas);
        uint hold_days = block.timestamp.div(1 days).sub(users[addr].start_date);
        uint daily_token = query_daily_token();

        uint kas;
        uint star_kas;
        uint super_kas;
        
        if(users[addr].pledge_cas < 10000 trx){
            // max credit power up to 60 days
            hold_days = hold_days > 60 ? 60 : hold_days;
        } else {
            // max credit power up to 70 days
            hold_days = hold_days > 70 ? 70 : hold_days;
        }
        
        uint credit_power = basic_power.mul(hold_days).mul(5).div(1000);
        // user_power = basic_power + credit_power + ref_power;
        uint user_power = basic_power.add(credit_power).add(users[addr].ref_power);
        uint total_power = calc_basic_power(total_pledge_cas).add(total_ref_power);
        
        // user daily token = daily_token * 80% * (user_power / total_power)
        kas = daily_token.mul(80).div(100).mul(user_power).div(total_power);

        // calc star node or super node special bonus with 20% of total daily KAS token
        (bool is_star_node, bool is_super_node) = is_big_node(addr);
        if(is_super_node){
            // super node claim the 1% of daily KAS token
            super_kas = daily_token.mul(1).div(100);
        } else if(is_star_node){
            // star node claim the 0.1% of daily KAS token
            star_kas = daily_token.mul(1).div(1000);
        }

        return (kas, star_kas, super_kas);
    }
}