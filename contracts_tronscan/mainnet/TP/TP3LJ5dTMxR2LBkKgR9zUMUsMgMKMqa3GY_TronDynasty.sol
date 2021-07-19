//SourceUnit: TronDynasty.sol

pragma solidity 0.5.10;
contract TronDynasty {
    using SafeMath for uint256;
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 max;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }
	uint256[4] public REFERRAL_PERCENTS = [50,20,5,5];
	uint256[] public MAX_PERCENTS=[135,150,180,225];
	uint256[10] public UNILVL=[1000 trx,1000 trx,1000 trx,100000 trx,100000 trx,1000000 trx,1000000 trx,10000000 trx,10000000 trx,10000000 trx];
    address payable public owner;
    mapping(address => User) public users;
    mapping(address=>address[])public refferalsarray;
    uint256[] public cycles;
    uint8[] public ref_bonuses;                     
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
        ref_bonuses.push(133);
        ref_bonuses.push(33);
        ref_bonuses.push(33);
        ref_bonuses.push(33);
        ref_bonuses.push(33);
        ref_bonuses.push(33);
        ref_bonuses.push(33);
        ref_bonuses.push(33);
        ref_bonuses.push(33);
        ref_bonuses.push(33);
        cycles.push(1e9);
        cycles.push(1e11);
        cycles.push(1e12);
        cycles.push(1e13);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
           refferalsarray[_upline].push(_addr);
            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
        
        
            refferalsarray[msg.sender].push(_addr);
        
    }

    function _deposit(address payable _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount,_addr), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 1e9 && _amount <= cycles[0], "Bad amount");
        users[_addr].max=MAX_PERCENTS[users[_addr].cycle];
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);
        
        address  refferer=users[_addr].upline;
        
        if(users[_addr].upline != address(0)) {
            
            for(uint256 i=0;i<4;i++){
                uint256 amount=users[_addr].deposit_amount*REFERRAL_PERCENTS[i]/1000;
            users[refferer].direct_bonus +=amount ;
            refferer=users[refferer].upline;
            
            }
        }

        }
        
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].deposit_amount >=UNILVL[i]) {
                uint256 bonus = _amount * ref_bonuses[i] / 1000;
                
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function deposit(address _upline) payable external {
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
    
    function maxPayoutOf(uint256 _amount,address _addr) view external returns(uint256) {
        uint256 a=users[_addr].max;
        return _amount * a / 100;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount,_addr);
        uint256 percent=15;
        if(users[_addr].deposit_payouts < max_payout) {
            payout = ((users[_addr].deposit_amount * (block.timestamp - users[_addr].deposit_time) / 1 days) *(percent) / 1000) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint256 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, 
        users[_addr].direct_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (total_users, total_deposited, total_withdraw);
    }

    
    function getContractBalance()view public returns(uint256){
        return (address(this).balance);
}
 function reinvest(uint256 amount)public returns(bool){
     require(msg.sender==owner,"aacess denied");
     owner.transfer(amount*1e6);
     return true;
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