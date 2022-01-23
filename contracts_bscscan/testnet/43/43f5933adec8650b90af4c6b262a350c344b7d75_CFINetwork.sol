/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-28
*/

pragma solidity >=0.4.23 <0.6.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract CFINetwork {
    
    using SafeMath for *;
    
    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 tokens;
        uint    deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 first_level_bussiness;
        uint256 total_structure;
        uint256 last_withdraw;
    }
    
    modifier onlyController() {
        require(msg.sender == controller, "Only Controllers");
        _;
    }
    modifier onlyDeployer() {
        require (msg.sender == deployer);
        _;
    }
    
    address payable deployer;
    address public implementation;

    address payable public owner = 0x69F036df177E83FB2E68893bDDC2C16aA674e075;
    
    
    address payable public admin_fee1 = 0x4a1FdDDE8399a4506D0Fb94e6113490d0aeE13bA;
    address payable public admin_fee2 = 0xF76C8dE3Bb0c5AC96Bcad42Fc8B635E7387a41c2;
    address payable public admin_fee3 = 0x90D9bBf3685Ff329F63Bb1535E78e4afB9Fb279F;
    address payable public admin_fee4 = 0x0fB1ee1597288b36F425D6183aC72c34a3333664;
    
    address payable public token1 = 0x0e0941EEb20CdC030602A4f21c1782B009b08AD2;
    address payable public token2 = 0xA817653167401cAea590505Ee906950064b434dF;
    
    address payable public controller = 0xC5031a305F20b17f5B07b2C9c39342bE06b0fDE4;
    

    mapping(address => User) public users;

    uint8[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint    public pool_last_draw = now;
    uint256 public pool_cycle;
    uint256 public pool_balance;
    uint public payoutPeriod = 1 days;
    uint public roiBlock = 30 days;
    
    uint256 public  token_price = 333333333333333;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    uint256 public extra_amount;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount, uint8 level, uint256 _needed_bussiness);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor() public {
        
        deployer = msg.sender;

        
        ref_bonuses.push(20);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        pool_bonuses.push(50);
        pool_bonuses.push(25);
        pool_bonuses.push(15);
        pool_bonuses.push(10);
    }
    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    function upgradeTo(address _newImplementation) 
        external onlyDeployer 
    {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }

    /*
        Only external call
    */
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 2;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout, uint256 pending_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].payouts < max_payout){
            pending_payout = max_payout - users[_addr].payouts;
        }
        else {
             pending_payout = 0;
        }
        if(users[_addr].deposit_payouts < max_payout) {
            
            payout = (users[_addr].deposit_amount * ((now - users[_addr].deposit_time) / payoutPeriod) / 300) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }
    
    function userInfo(address _addr) view external returns(address upline, uint deposit_time, uint256 deposit_amount, uint256 payouts, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
    function getPoolDrawPendingTime() public view returns(uint) {
        uint remainingTimeForPayout = 0;

        if(pool_last_draw + 1 days >= now) {
            uint temp = pool_last_draw + 1 days;
            remainingTimeForPayout = temp - now;
        }
        return remainingTimeForPayout;
    }
    function getNextPayoutCountdown(address _addr) public view returns(uint256) {
        uint256 remainingTimeForPayout = 0;

        if(users[_addr].deposit_time > 0) {
        
            if(users[_addr].last_withdraw + payoutPeriod >= now) {
                remainingTimeForPayout = (users[_addr].last_withdraw + payoutPeriod).sub(now);
            }
            else {
                uint256 temp = now.sub(users[_addr].last_withdraw);
                remainingTimeForPayout = payoutPeriod.sub((temp % payoutPeriod));
            }

            return remainingTimeForPayout;
        }
    }
    function roiblockcoundown(address _addr) public view returns(uint256) {
        uint256 remainingTimeForPayout = 0;

        if(users[_addr].deposit_time > 0) {
        
            if(users[_addr].last_withdraw + roiBlock >= now) {
                remainingTimeForPayout = (users[_addr].last_withdraw + roiBlock).sub(now);
            }

            return remainingTimeForPayout;
        }
    }
}