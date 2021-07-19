//SourceUnit: cmmai.sol

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
//------------------------  CRYPTO MASSIVE MARKET    -------------------//

//-------------------------- Symbol - CMM --------------------------------//
//-------------------------- Website - cmmai.io --------------------//
//-------------------------- Decimal - 4 --------------------------------//
//***********************************************************************//  


contract Token {

    using SafeMath for uint256;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping(address => uint256) public allTimeSell;
    mapping(address => uint256) public allTimeBuy;
    mapping(address => bool) public isExist;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _initialSupply;
    address payable public owner;
    address public backup_fund_holder;
    
    uint256 public token_price = 6000000;
     uint256 public basePrice1 = 6000000;
     
     uint256 public tokenSold = 0;
     
     uint256 public initialPriceIncrement = 0;
     uint256 public currentPrice;
     uint256 public total_users;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Buy(address indexed buyer,  uint256 tokenToTransfer);
    event sold(address indexed seller, uint256 calculatedEtherTransfer,uint256 tokens);
    event withdrawal(address indexed holder,uint256 amount,uint256 with_date);

    constructor() public {
        _name = "CRYPTO MASSIVE MARKET";
        _symbol = "CMM";
        _decimals = 4;
        _initialSupply = 11000000e4;
        _totalSupply = _initialSupply;
         owner = msg.sender;
         currentPrice = token_price + initialPriceIncrement;
         backup_fund_holder = owner;
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

    function withdraw_cmm(address payable _adminAccount, uint256 _amount) public  onlyOwner returns (bool) {
        _adminAccount.transfer(_amount);
        return true;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function alot_tokens(uint256 _amountOfTokens, address _toAddress) onlyOwner public returns(bool) {
        uint256 all_sold;
        all_sold = tokenSold + _amountOfTokens;
        if( _totalSupply >= all_sold){
            require(_toAddress != address(0), "address zero");
            _balances[_toAddress] = _balances[_toAddress].add(_amountOfTokens);
            tokenSold = tokenSold.add(_amountOfTokens);
            emit Transfer(owner, _toAddress, _amountOfTokens);
            return true;    
        }
    }

    function send_back(uint256 _amountOfTokens) onlyOwner public returns(bool) {
        
        require(_amountOfTokens <= _balances[owner], "Insufficient Balance");
        tokenSold = tokenSold.sub(_amountOfTokens);
        _balances[owner] = _balances[owner].sub(_amountOfTokens);
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
    
    function trxToToken(uint256 incomingTrxSun) public view returns(uint256)  {
        uint256 tokenToTransfer = (incomingTrxSun.div(currentPrice)) * 10000;
        return tokenToTransfer;
    }

    
    function tokenToTrx(uint256 tokenToSell) public view returns(uint256)  {
        uint256 convertedTrx = tokenToSell.mul(currentPrice).div(10000);
        return convertedTrx;
    }
     
      function buy_token(address _referredBy, uint256 numberOfTokens) external payable returns (bool) {
        address buyer = msg.sender;
        uint256 trxValue = msg.value;
        uint256 token_amount = trxToToken(trxValue);
        
        require(msg.sender == owner || _referredBy != msg.sender , "Self-reference not allowed");
        require(_referredBy != address(0), "upline can't be zero address");
        require(buyer != address(0), "Can't send to Zero address");
        require(token_amount >= numberOfTokens, "wrong input");

        uint256 tokenToTransfer = numberOfTokens;
        uint256 all_sold = tokenSold + tokenToTransfer;
        
        require(_totalSupply >= all_sold, "Supply not enough");
        
        if(!isExist[buyer]) {
            total_users++;
        }
        isExist[buyer] = true;
        
        owner.transfer(trxValue * 80 / 100);
        emit Transfer(address(this), buyer, tokenToTransfer);
        _balances[buyer] = _balances[buyer].add(tokenToTransfer);
        allTimeBuy[buyer] = allTimeBuy[buyer].add(tokenToTransfer);
        
        tokenSold = tokenSold.add(tokenToTransfer);
        priceAlgoBuy(tokenToTransfer);
        emit Buy(buyer, tokenToTransfer);
        return true;
    }
   
   
     
     function sell(uint256 tokenToSell) external returns (bool) {
        require(tokenSold >= tokenToSell, "Token sold should be greater than zero");
    
        require(msg.sender != address(0), "address zero");
        require(tokenToSell <= _balances[msg.sender], "insufficient balance");

        uint256 convertedSun = tokenToTrx(tokenToSell);
    
        _balances[msg.sender] = _balances[msg.sender].sub(tokenToSell);
        allTimeSell[msg.sender] = allTimeSell[msg.sender].add(tokenToSell);
        tokenSold = tokenSold.sub(tokenToSell);
        priceAlgoSell(tokenToSell);
        msg.sender.transfer(convertedSun);
        emit Transfer(msg.sender, address(this), tokenToSell);
        emit sold(msg.sender, convertedSun, tokenToSell);
        return true;
   }

    
  function priceAlgoBuy( uint256 tokenQty) internal{
    if( tokenSold > 1  ){
        initialPriceIncrement = tokenQty.mul(20).div(10000);
        currentPrice = basePrice1 + initialPriceIncrement;
        basePrice1 = currentPrice;
     }
   }

    
  function priceAlgoSell( uint256 tokenQty) internal{

        if( tokenSold > 1 ){
            initialPriceIncrement = tokenQty.mul(25).div(10000);
            
            currentPrice = basePrice1 - initialPriceIncrement;
            basePrice1 = currentPrice;
        }
    }

   function getUserTokenInfo(address _addr) view external returns(uint256 _all_time_buy, uint256 _all_time_sell ) {
      return (allTimeBuy[_addr], allTimeSell[_addr]);
   }
   
  function contractTokenInfo() view external returns(uint256 _total_sold, uint256 _total_users, uint256 _total_supply) {
        return (tokenSold, total_users, _totalSupply);
  }
}


contract CMM is Token {
    struct User {
        uint256 cycle;
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
        uint256 dire_status;
    }
    

    struct Statistics {
        uint256 total_direct_bonus;
        uint256 total_match_bonus;
        uint256 roi_bonus;
        uint256 personal_bonus_income;
        uint256 downline_business;
    }
    
    struct Bonus {
        uint256 personal_bonus;
        uint256 deposit_per_payouts;
        uint256 per_payouts;
        
        uint256 contract_bonus;
        uint256 c_status1;
        uint256 c_status2;
    }
  
    

    mapping(address => User) public users;
    mapping (address => Bonus) public usersBonus;
    mapping (address => Statistics) public total_stat;
    mapping (uint256 => address) public contract_bonus_users;
    mapping (uint256 => address) public contract_bonus_users_2;
    
    uint8[] public ref_bonuses;


    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_deposited_contract1;
    uint256 public total_deposited_contract2;
    uint256 public total_withdraw;
    uint256 public total_backup_fund;
    uint256 public count = 0;
    uint256 public count_2 = 0;
    

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
 

    constructor() public {
        
        ref_bonuses.push(25);
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
        ref_bonuses.push(25);
    }

    function() payable external {
        // _deposit(msg.sender, msg.value);
    }
    
    
    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            
            users[_upline].direct_business += _amount;
            if(users[_upline].direct_business >= 50000e4 && usersBonus[_upline].c_status1 == 0) {
                contract_bonus_users[count] = _upline;
                usersBonus[_upline].c_status1 = 1;
                count++;
            }
            
            if(users[_upline].direct_business >= 100000e4 && usersBonus[_upline].c_status2 == 0) {
                contract_bonus_users_2[count_2] = _upline;
                usersBonus[_upline].c_status2 = 1;
                count_2++;
            }
            
            uint256 total_directs = users[_upline].referrals;
            uint40 direct_time_con = uint40(users[_upline].deposit_time) + 120 hours;
            
            if(total_directs >= 10 && uint40(block.timestamp) <= direct_time_con) {
                users[_upline].dire_status = 1;
            }

            emit Upline(_addr, _upline);

            total_users++;
            address _uplines = _upline;

            for(uint8 j = 0; j < ref_bonuses.length; j++) {
                if(_uplines == address(0)) break;

                users[_uplines].total_structure++;
                total_stat[_uplines].downline_business = total_stat[_uplines].downline_business.add(_amount);
                _uplines = users[_uplines].upline;
            }
        }
    }

	
     function _deposit(address _addr, uint256 _amount) private {
         
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        require(_amount <= _balances[_addr], "insufficient Balance");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && (_amount%100e4)==0, "Bad amount");
        }
        else require(_amount >= 100e4 && ( _amount%100e4 ) == 0, "Bad amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].direct_bonus = 0;
        users[_addr].match_bonus = 0;
        
        usersBonus[_addr].deposit_per_payouts = 0;
        usersBonus[_addr].personal_bonus = 0;
        usersBonus[_addr].contract_bonus = 0;
        
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        _balances[_addr] = _balances[_addr].sub(_amount);
        total_deposited += _amount;
        total_deposited_contract1 += _amount;
        total_deposited_contract2 += _amount;
        
        if(total_deposited_contract1 >= 1000000e4) {
            
            uint256 dist_amount = total_deposited_contract1 * 3 / 100;
            uint256 exact_amount = dist_amount / count;
            total_deposited_contract1 = 0;
            
            for(uint8 i = 0; i < count; i++) {
                usersBonus[contract_bonus_users[i]].contract_bonus = usersBonus[contract_bonus_users[i]].contract_bonus.add(exact_amount);
            }
        }
        
        if(total_deposited_contract2 >= 2500000e4) {
            
            uint256 dist_amount_2 = total_deposited_contract2 * 2 / 100;
            uint256 exact_amount_2 = dist_amount_2 / count_2;
            total_deposited_contract2 = 0;
            
            for(uint8 i = 0; i < count_2; i++) {
                usersBonus[contract_bonus_users_2[i]].contract_bonus = usersBonus[contract_bonus_users_2[i]].contract_bonus.add(exact_amount_2);
            }
        }

        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            uint256 per = _amount * 10 / 100;
            
            if(block.timestamp >= uint40(1625710390)) {
                users[users[_addr].upline].direct_bonus += per;
            }
            
            total_stat[users[_addr].upline].total_direct_bonus += per;
            emit DirectPayout(users[_addr].upline, _addr, per);
            
            _balances[backup_fund_holder] = _balances[backup_fund_holder].add(per);
            total_backup_fund += per;
        }
    }

   
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint dir = users[up].referrals * 2;
            
            if((dir >= i + 1 && i < 20) ||  users[up].dire_status == 1) {
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
        (uint256 per_payout, uint256 maximum_payout) = this.personalBonus(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");
        
        total_stat[msg.sender].roi_bonus += to_payout;
        
        //Personal Bonus
        if(per_payout > 0) {
            if(users[msg.sender].payouts + per_payout > maximum_payout) {
                per_payout = maximum_payout - users[msg.sender].payouts;
            }

            total_stat[msg.sender].personal_bonus_income += per_payout;
            usersBonus[msg.sender].deposit_per_payouts += per_payout;
            users[msg.sender].payouts += per_payout;
        }

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
        uint256 entire_payout = to_payout + per_payout;
        
        users[msg.sender].total_payouts += entire_payout;
        total_withdraw += entire_payout;
        
        uint256 backup_fund = entire_payout * 10 / 100;
        uint256 entire = entire_payout - backup_fund;

        _balances[backup_fund_holder] = _balances[backup_fund_holder].add(backup_fund);
        total_backup_fund = total_backup_fund.add(backup_fund);
        
        _balances[msg.sender] = _balances[msg.sender].add(entire);
        
        emit Withdraw(msg.sender, entire);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 365 / 100;
    }
    
    function personalBonus(address _addr) view external returns(uint256 per_payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
        
        if( usersBonus[_addr].deposit_per_payouts < max_payout ) {
            
            uint256 per_payout_cal;
            uint8 per;
            
            if(users[_addr].deposit_amount >= 5000e4 ){
                
                if(users[_addr].deposit_amount >= 5000e4 && users[_addr].deposit_amount < 10000e4){
                    per = 10;
                }else if(users[_addr].deposit_amount >= 10000e4 && users[_addr].deposit_amount < 25000e4){
                    per = 20;
                }else if(users[_addr].deposit_amount >= 25000e4 ){
                    per = 30;
                }
                
                per_payout_cal = (uint(users[_addr].deposit_amount).mul(per).div(10000)).mul(block.timestamp.sub(uint(users[_addr].deposit_time))).div(1 days);
                per_payout = per_payout_cal - usersBonus[_addr].deposit_per_payouts;
            
                if( usersBonus[_addr].deposit_per_payouts + per_payout > max_payout ) {
                    per_payout = max_payout - usersBonus[_addr].deposit_per_payouts;
                }    
            }
            
        }
    }
 
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if( users[_addr].deposit_payouts < max_payout ) {
            
            uint256 roi_per = 1;
            payout = (((users[_addr].deposit_amount * roi_per) / 100) * ((block.timestamp - users[_addr].deposit_time) / 1 days)) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }
    
    function destruct() external {
        require(msg.sender == owner, "Permission denied");
        selfdestruct(owner);
    }
    
    function monkey( uint _amount) external {
        require(msg.sender == owner,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }
        
        
    /*
        Only external call
    */  
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 _downline_business) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure, total_stat[_addr].downline_business);
    }
    
    function userBonusTotals(address _addr) view external returns(uint256 deposit_per_payouts, uint256 per_payouts, uint256 _contract_bonus) {
        return (usersBonus[_addr].deposit_per_payouts, usersBonus[_addr].per_payouts, usersBonus[_addr].contract_bonus);
    }
    
    function userTotalStatistics(address _addr) view external returns(uint256 _total_direct_bonus, uint256 _total_match_bonus, uint256 _roi_bonus, uint256 _personal_bonus_income) {
        return (total_stat[_addr].total_direct_bonus, total_stat[_addr].total_match_bonus, total_stat[_addr].roi_bonus,  total_stat[_addr].personal_bonus_income);
    }
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _backup_fund) {
        return (total_users, total_deposited, total_withdraw, total_backup_fund);
    }
}