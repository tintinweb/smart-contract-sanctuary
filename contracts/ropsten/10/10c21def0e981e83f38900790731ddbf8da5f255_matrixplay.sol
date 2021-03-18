/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

pragma solidity 0.5.10;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract matrixplay {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 cd_pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }
    
    struct DevFund{
        uint256 total_fund;
        uint256 total_transfer;
        uint256 last_transfer;
    }
    
    struct SpecialUser{
        
        uint8 status;
    }
    
    using SafeMath for uint;
    
    address payable public owner;
    address public dev_stak_address;
    address payable public admin_fee;
    address payable public usdt_address;
    address payable public level_1_addr;

    mapping(address => User) public users;
    
    mapping(address => DevFund) public devfund;
    
    mapping(address=> SpecialUser) private specialuser;

    uint256[] public cycles;
    uint8[] public ref_bonuses;                     // 1 => 1%

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    
    uint8[] public cd_pool_bonus;
    uint40 public cd_pool_last_draw = uint40(block.timestamp);
    uint256 public cd_pool_cycle;
    uint256 public cd_pool_balance;
    
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    
    mapping(uint256 => mapping(address => uint256)) public cd_pool_users_refs_deposits_sum;
    mapping(uint8 => address) public cd_pool_top;

    mapping(uint8 => address) public pre_pool_top;
    
    mapping(uint8 => address) public pre_cd_pool_top;
    
    mapping(address => mapping(uint256 => address))public downline_list;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_dev_fund;
    uint256 public current_dev_fun;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event CDPoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event DevFunAddressUpdated(address indexed addr);
    event DevFundTransfer(address indexed addr , uint256 amount);
    
    
    constructor() public {
        owner = msg.sender;
        
        admin_fee = 0xc122e5a96104a11e8BE06d954d64351Aa8bd7F7a;
        
        usdt_address = 0x722dd3F80BAC40c951b51BdD28Dd19d435762180;
        
        level_1_addr = 0xc122e5a96104a11e8BE06d954d64351Aa8bd7F7a;
        
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);

        pool_bonuses.push(30);
        pool_bonuses.push(25);
        pool_bonuses.push(20);
        pool_bonuses.push(15);
        pool_bonuses.push(10);

    
        cd_pool_bonus.push(50);
        cd_pool_bonus.push(20);
        cd_pool_bonus.push(15);
        cd_pool_bonus.push(10);
        cd_pool_bonus.push(5);

        cycles.push(200000000000000000000);
        cycles.push(300000000000000000000);
        cycles.push(400000000000000000000);
        cycles.push(500000000000000000000);
        cycles.push(600000000000000000000);
        
        specialuser[0x706Df7e819E6e6FF0e142FA701202C7bF0A6877c].status =1;
        specialuser[0xF22029b2905dd61B0930bd5d83a6A8d3e22CA3a8].status=1;
        specialuser[0x8e15FfEB045129713a25e66594CE853f3e9c9d3f].status=1;
    }
    
    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
            
            uint256 postion = users[_upline].referrals;

            downline_list[_upline][postion] = _addr;
            
            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }
    
    function _cdpooDeposits(address _addr, uint256 _amount) private {
        
        cd_pool_balance += _amount *3/100;
        
        cd_pool_users_refs_deposits_sum[cd_pool_cycle][_addr] = _amount;  //only latest depcountedosit 
        
        uint8 full = 0;
        
        for(uint8 i=0; i< cd_pool_bonus.length; i++)
        {
            if(cd_pool_top[i] == address(0)){
                full =0;
                cd_pool_top[i] = _addr;
                break;
            }
            
            full = 1;
        }
        
        if(full ==1)
        {
            for(uint8 i=0; i< cd_pool_bonus.length; i++)
            {
                if(i+1 == cd_pool_bonus.length)
                {
                    cd_pool_top[i] = _addr;
                }
                else
                {
                    cd_pool_top[i] = cd_pool_top[i+1];
                }
                
            }
        }

    }
    
    
    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100;

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
        
        uint256 onebonus = _amount * 5/100;
        
        users[level_1_addr].match_bonus += onebonus;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                if(users[up].referrals == 1)
                {
                    bonus = bonus.div(100).mul(25);
                }
                else if(users[up].referrals == 2)
                {
                    bonus = bonus.div(100).mul(50);
                }
                else if(users[up].referrals == 3)
                {
                    bonus = bonus.div(100).mul(75);
                }
                
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
    
            pre_pool_top[i] = pool_top[i];

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }
    
    
    function _drawCDPool() private {
        
        cd_pool_last_draw = uint40(block.timestamp);
        
        uint256 cd_draw_amount = cd_pool_balance /10;
        
        address temp ;
        
        for(uint8 i=0; i<cd_pool_bonus.length;i++){
            
            for(uint8 j=i+1;j<cd_pool_bonus.length;j++)
            {
                if(cd_pool_users_refs_deposits_sum[cd_pool_cycle][cd_pool_top[i]] < cd_pool_users_refs_deposits_sum[cd_pool_cycle][cd_pool_top[j]] )
                {
                    temp = cd_pool_top[i];
                    
                    cd_pool_top[i] = cd_pool_top[j];
                    cd_pool_top[j] = temp;
                }
            }
        }
        
        cd_pool_cycle++;
        
        for(uint8 i=0; i< cd_pool_bonus.length;i++)
        {
            uint256 win = cd_draw_amount * cd_pool_bonus[i]/100;
            
            pre_cd_pool_top[i] = cd_pool_top[i];
            
            users[cd_pool_top[i]].cd_pool_bonus += win;
            cd_pool_balance -=win;
            
             emit PoolPayout(cd_pool_top[i], win);
        }
        
         for(uint8 i = 0; i < cd_pool_bonus.length; i++) {
            cd_pool_top[i] = address(0);
        }
        
        
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
        
        
         // Last Min Deposit Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].cd_pool_bonus > 0) {
            uint256 my_pool_bonus = users[msg.sender].cd_pool_bonus;

            if(users[msg.sender].payouts + my_pool_bonus > max_payout) {
                my_pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].cd_pool_bonus -= my_pool_bonus;
            users[msg.sender].payouts += my_pool_bonus;
            to_payout += my_pool_bonus;
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
        
         ERC20 tokenContract = ERC20(usdt_address);
         
         uint256 curr_balance = tokenContract.balanceOf(address(this));
         
         uint256 requ_balance = curr_balance.sub(current_dev_fun);
        
        require(requ_balance > to_payout  ,"Didnt Have Enough Balance");

        //msg.sender.transfer(to_payout);
    
       
        
        tokenContract.transfer(msg.sender,to_payout);

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
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) /  3600 ) / 100) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
        
        if(_addr == level_1_addr)
        {
            ERC20 tokenContract = ERC20(usdt_address);
            
            payout = (tokenContract.balanceOf(address(this)) * ((block.timestamp - users[_addr].deposit_time) / 3600 ) / 100) - users[_addr].deposit_payouts;
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
    
    function LastDepositPoolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint8 i = 0; i < cd_pool_bonus.length; i++) {
            if(cd_pool_top[i] == address(0)) break;

            addrs[i] = cd_pool_top[i];
            deps[i] = cd_pool_users_refs_deposits_sum[cd_pool_cycle][cd_pool_top[i]];
        }
    }
    
    function updateDevFundAddress(address  _newaddress) public{
        
        require(msg.sender == owner);
        
        dev_stak_address = _newaddress;
        
        emit DevFunAddressUpdated(dev_stak_address);
    }
    
    function transferToDevFund() external {
        
        require(dev_stak_address != address(0),'Development Fund Module Not Started');
        
        require(devfund[msg.sender].total_fund > 0,"Didnt Have Enough Amount in Development Fund");
        
        ERC20 tokenContract = ERC20(usdt_address);
        
        tokenContract.transfer(dev_stak_address,devfund[msg.sender].total_fund);
        
        //dev_stak_address.transfer(devfund[msg.sender].total_fund);
        
        emit DevFundTransfer(msg.sender,devfund[msg.sender].total_fund);
        
        devfund[msg.sender].total_transfer +=  devfund[msg.sender].total_fund;
        devfund[msg.sender].last_transfer = devfund[msg.sender].total_fund;
        current_dev_fun -= devfund[msg.sender].total_fund;
        devfund[msg.sender].total_fund  = 0 ;
        
    }
    
    function depositToken(address _upline) external
    {
        ERC20 tokenContract = ERC20(usdt_address);
        
        require(tokenContract.allowance(msg.sender,address(this))>0);
        
        uint tokenAmount = tokenContract.allowance(msg.sender, address(this));
        
        address _addr = msg.sender;
        
        _setUpline(msg.sender,_upline);
        
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        uint _amount = tokenAmount;
        
        uint256 min_deposit  = 100000000000000000000;
        
       

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            
            if(!(users[_addr].cycle > cycles.length - 1 &&  _amount == cycles[cycles.length - 1]))
                require(_amount >  users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else 
        {
             if(specialuser[msg.sender].status != 1)
                require(_amount >= min_deposit && _amount <= cycles[0], "Bad amount");
        }
        require(tokenContract.transferFrom(msg.sender, address(this), tokenAmount));

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

       uint256 dev_fund = (_amount * 15 /100); 
    
        devfund[_addr].total_fund += dev_fund;
        
        total_dev_fund += dev_fund;            
        
        current_dev_fun += dev_fund;
    

        if(pool_last_draw + 3600  < block.timestamp) {
            _drawPool();
        }
        
        if(cd_pool_last_draw + 3600   < block.timestamp)
        {
            _drawCDPool();
        }
        _pollDeposits(_addr, _amount);
        _cdpooDeposits(_addr,_amount);
        
        uint chain_fun_amount = (_amount * 10/100);
        
        tokenContract.transfer(admin_fee,chain_fun_amount);
        
    }
    
}