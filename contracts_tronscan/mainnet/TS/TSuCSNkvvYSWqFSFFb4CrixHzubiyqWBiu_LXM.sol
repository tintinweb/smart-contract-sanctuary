//SourceUnit: lxm.sol

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
//------------------------  LEXAM CONTRACT    -------------------//

//-------------------------- Symbol - LXM --------------------------------//
//-------------------------- Total Supply - 12000000  -----------------//
//-------------------------- Staking Supply - 1200000  -----------------//
//-------------------------- Website - lexam.exchange --------------------//
//-------------------------- Decimal - 0 --------------------------------//
//***********************************************************************//  


contract LXM {

    using SafeMath for uint256;
    
    struct User {
        uint256 cycle;
        uint256 payouts;
        uint256 deposit_amount;
        uint40 deposit_time;
        uint256 deposit_payouts;
        uint256 total_deposits;
        uint256 total_payouts;
    }
    
    mapping(address => User) public users;
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping(address => uint256) public allTimeSell;
    mapping(address => uint256) public allTimeBuy;
    mapping(address => address) public gen_tree;
    mapping(address => uint256) public levelIncome;
    mapping(address => uint256) public mode;
    mapping(address => bool) public isExist;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _initialSupply;
    address payable public owner;
    uint256 public total_stake;

    
     uint256 public token_price = 200000;
     uint256 public basePrice1 = 200000;
     uint256 public basePrice2 = 400000;
     uint256 public basePrice3 = 1000000;
     uint256 public basePrice4 = 2000000;
     uint256 public basePrice5 = 5000000;
     uint256 public basePrice6 = 10000000;
     
     uint256 public tokenSold = 0;
     uint256 public initialPriceIncrement = 0;
     uint256 public currentPrice;
     uint256 public total_users;
     uint256 internal owner_holding;
     uint256 internal stakeSupply;
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Buy(
        address indexed buyer, 
        uint256 tokensTransfered, uint256 tokenToTransfer
    );
    
    event sold(
        address indexed seller, 
        uint256 calculatedEtherTransfer,
        uint256 tokens
    );
    
    event stake(
         address indexed staker,
         uint256 amount,
         uint256 staking_date
     );
    
    event withdrawal(
         address indexed holder,
         uint256 amount,
         uint256 with_date
    );
    
    event withdrawStake(
        address indexed addr, 
        uint256 amount
    );
    
    event LimitReached(
        address indexed addr,
        uint256 amount
    );
    
    constructor() public {
        _name = "LEXAM";
        _symbol = "LXM";
        _decimals = 0;
        _initialSupply = 12000000;
        _totalSupply = _initialSupply;
        
        owner = msg.sender;
        total_users = 1;
        owner_holding = 2400000;
        stakeSupply =  1200000;
        currentPrice = token_price + initialPriceIncrement;
        _balances[owner] = owner_holding;
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
    
    function get_level_income(address _addr) external view returns (uint256) {
        return levelIncome[_addr];
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
    
    function holdStake(uint256 _amount) external returns (bool) {
        address _addr = msg.sender;
        
        require(_amount <= _balances[_addr], 'Insufficient Balance');

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxStakingOf(users[_addr].deposit_amount), "Staking already exists");
            require(_amount >= users[_addr].deposit_amount, "Stake should be greater than or equal to the previous one");
        }
        
        else require(_amount >= 1000, "Min. staking is 1000 LXM");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;
        
        _balances[_addr] = _balances[_addr].sub(_amount);
        
        uint256 percent = _amount * 15 / 10;
        uint256 stake_out = percent - _amount;
        stakeSupply = stakeSupply.sub(stake_out);
        
        tokenSold = tokenSold.add(stake_out);
        total_stake += _amount;
        emit stake(_addr, _amount, block.timestamp);
        return true;
    }
    
    function maxStakingOf(uint256 _staking_amount) pure external returns(uint256) {
        return _staking_amount * 15 / 10;
    }
    
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxStakingOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
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

    function withdraw_LXM(address payable _adminAccount, uint256 _amount) public  onlyOwner returns (bool) {
        _adminAccount.transfer(_amount);
        return true;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
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
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "address zero");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    function alot_tokens(uint256 _amountOfTokens, address _toAddress) onlyOwner public returns(bool) {
        require(_amountOfTokens <= _balances[owner]);
        require(_toAddress != address(0), "address zero");
        
        _balances[owner] = _balances[owner].sub(_amountOfTokens);
        _balances[_toAddress] = _balances[_toAddress].add(_amountOfTokens);
        tokenSold = tokenSold.add(_amountOfTokens);
        emit Transfer(owner, _toAddress, _amountOfTokens);
        return true;
    }

    function getTaxedTrx(uint256 incomingTrx) public pure returns(uint256) {
        uint256 deduction = incomingTrx * 10000 / 100000;
        uint256 taxedTrx = incomingTrx - deduction;
        return taxedTrx;
    }
    
    function trxToToken(uint256 incomingTrxSun) public view returns(uint256)  {
        uint256 tokenToTransfer = incomingTrxSun.div(currentPrice);
        return tokenToTransfer;
    }
    
    function tokenToTrx(uint256 tokenToSell) public view returns(uint256)  {
        uint256 convertedTrx = tokenToSell * currentPrice;
        return convertedTrx;
    }
     
    function taxedTokenTransfer(uint256 incomingTrx) internal view returns(uint256) {
        uint256 deduction = incomingTrx * 10000/100000;
        uint256 taxedTRX = incomingTrx - deduction;
        uint256 tokenToTransfer = taxedTRX.div(currentPrice);
        return tokenToTransfer;
     }
     
     function add_level_income( address user, uint256 numberOfTokens) internal returns(bool) {
         
         address referral;
          for( uint i = 0 ; i < 1; i++ ){
            referral = gen_tree[user];
            
            if(referral == address(0)) {
                break;
            }
            uint256 convertedTRX = _balances[referral] * currentPrice;
            
            // Min. 500 TRX referral holding
            if( convertedTRX >= 500000000 ){ 
                uint256 commission = numberOfTokens * 10 / 100;
                levelIncome[referral] = levelIncome[referral].add(commission);
            }
            user = referral; 
         }
      }
     
     function buy_token(address _referredBy ) external payable returns (bool) {
         
        require(_referredBy != msg.sender, "Self reference not allowed");
        address buyer = msg.sender;
        uint256 trxValue = msg.value;
        uint256 taxedTokenAmount = taxedTokenTransfer(trxValue);
        uint256 tokenToTransfer = trxValue.div(currentPrice);
        
        require(trxValue >= 10000000, "Minimum purchase limit is 10 LXM"); 
        require(buyer != address(0), "Can't send to Zero address");
        
        if(!isExist[buyer]) {
            total_users++;
        }
        
        isExist[buyer] = true;
        
        if(mode[buyer] == 0) {
            gen_tree[buyer] = _referredBy;   
            mode[buyer] = 1;
         }
        
        add_level_income(buyer, tokenToTransfer);
       
        emit Transfer(address(this), buyer, taxedTokenAmount);
        _balances[buyer] = _balances[buyer].add(taxedTokenAmount);
        allTimeBuy[buyer] = allTimeBuy[buyer].add(tokenToTransfer);
        
        tokenSold = tokenSold.add(tokenToTransfer);
        priceAlgoBuy(tokenToTransfer);
        emit Buy(buyer,taxedTokenAmount, tokenToTransfer);
        return true;
   }
   
     function sell(uint256 tokenToSell) external returns (bool) {
        require(tokenSold >= tokenToSell, "Token sold should be greater than zero");
        require(msg.sender != address(0), "address zero");
        require(tokenToSell <= _balances[msg.sender], "insufficient balance");
        require(tokenToSell >= 10, "Min. Selling Limit is 10 LXM");
        
        uint256 deduction = tokenToSell * 1 / 100;
        uint256 payable_token = tokenToSell - deduction;
        uint256 convertedSun = tokenToTrx(payable_token);
    
        _balances[msg.sender] = _balances[msg.sender].sub(tokenToSell);
        allTimeSell[msg.sender] = allTimeSell[msg.sender].add(tokenToSell);
        tokenSold = tokenSold.sub(tokenToSell);
        priceAlgoSell(tokenToSell);
        msg.sender.transfer(convertedSun);
        emit Transfer(msg.sender, address(this), tokenToSell);
        emit sold(msg.sender, convertedSun, tokenToSell);
        return true;
   }

     function withdraw_bal(uint256 numberOfTokens, address _customerAddress)
        public returns(bool)
     {
          require(_customerAddress != address(0), "address zero");
          require(numberOfTokens <= levelIncome[_customerAddress], "insufficient bonus");
          
          levelIncome[_customerAddress] = levelIncome[_customerAddress].sub(numberOfTokens);
          _balances[_customerAddress] = _balances[_customerAddress].add(numberOfTokens);
          emit withdrawal(_customerAddress, numberOfTokens, block.timestamp);
          return true;
     }
     
     function total_stake_supply() external view returns (uint256) {
        return stakeSupply;
    }
     
     function stake_withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);

        require(stakeSupply > 0, "Full stake");
        require(to_payout >= 10, "Min. withdrawal is 10 LXM");
        require(users[msg.sender].payouts < max_payout, "Full payouts");
        
    
        if(users[msg.sender].payouts + to_payout > max_payout) {
            to_payout = max_payout - users[msg.sender].payouts;
        }

        users[msg.sender].deposit_payouts += to_payout;
        users[msg.sender].payouts += to_payout;
        users[msg.sender].total_payouts += to_payout;
        
        _balances[msg.sender] = _balances[msg.sender].add(to_payout);

        emit withdrawStake(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    
  function priceAlgoBuy( uint256 tokenQty) internal{

    if( tokenSold >= 1 && tokenSold <= 1000000 ){
        currentPrice = basePrice1;
        basePrice1 = currentPrice;
    }

    if( tokenSold > 1000000 && tokenSold <= 2500000 ){
        initialPriceIncrement = tokenQty * 1;
        currentPrice = basePrice2 + initialPriceIncrement;
        basePrice2 = currentPrice;
    }
    
    if( tokenSold > 2500000 && tokenSold <= 4000000 ){
        initialPriceIncrement = tokenQty*1;
        currentPrice = basePrice3 + initialPriceIncrement;
        basePrice3 = currentPrice;
    }

    if(tokenSold > 4000000 && tokenSold <= 5500000){
        initialPriceIncrement = tokenQty*1;
        currentPrice = basePrice4 + initialPriceIncrement;
        basePrice4 = currentPrice;
    }
    if(tokenSold > 5500000 && tokenSold <= 7000000){
        initialPriceIncrement = tokenQty*1;
        currentPrice = basePrice5 + initialPriceIncrement;
        basePrice5 = currentPrice;
    }
    if( tokenSold > 7000000 && tokenSold <= 8400000 ){
        initialPriceIncrement = tokenQty*1;
        currentPrice = basePrice6 + initialPriceIncrement;
        basePrice6 = currentPrice;
     }
   }

    
  function priceAlgoSell( uint256 tokenQty) internal{

        if( tokenSold >= 1 && tokenSold <= 1000000 ){
            currentPrice = basePrice1;
            basePrice1 = currentPrice;
        }

        if( tokenSold > 1000000 && tokenSold <= 2500000 ){
            initialPriceIncrement = tokenQty*1;
            currentPrice = basePrice2 - initialPriceIncrement;
            basePrice2 = currentPrice;
        }

        if( tokenSold > 2500000 && tokenSold <= 4000000 ){
            initialPriceIncrement = tokenQty*1;
            currentPrice = basePrice3 - initialPriceIncrement;
            basePrice3 = currentPrice;
        }

        if(tokenSold > 4000000 && tokenSold <= 5500000){
            initialPriceIncrement = tokenQty*1;
            currentPrice = basePrice4 - initialPriceIncrement;
            basePrice4 = currentPrice;
        }
        if(tokenSold > 5500000 && tokenSold <= 7000000){
            initialPriceIncrement = tokenQty*1;
            currentPrice = basePrice5 - initialPriceIncrement;
            basePrice5 = currentPrice;
        }
        if( tokenSold > 7000000 && tokenSold <= 8400000 ){
            initialPriceIncrement = tokenQty*1;
            currentPrice = basePrice6 - initialPriceIncrement;
            basePrice6 = currentPrice;
        }
    }

   function getUserTokenInfo(address _addr) view external returns(uint256 _levelIncome, uint256 _all_time_buy, uint256 _all_time_sell, address _referral ) {
      return (levelIncome[_addr], allTimeBuy[_addr], allTimeSell[_addr], gen_tree[_addr]);
   }  
   
   function userStakeInfo(address _addr) view external returns(uint256 _deposit_stake, uint256 _payouts, uint256 _deposit_payouts, uint256 _total_deposits, uint256 _total_payouts) {
        return (users[_addr].deposit_amount, users[_addr].payouts, users[_addr].deposit_payouts,users[_addr].total_deposits, users[_addr].total_payouts );
   }
   
   function contractInfo() view external returns(uint256 _total_sold, uint256 _total_stake, uint256 _total_users, uint256 _total_supply) {
        return (tokenSold, total_stake, total_users, _totalSupply );
   }
}