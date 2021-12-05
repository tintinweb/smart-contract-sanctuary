/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity ^0.4.24;

contract HFCToken {

    // 0x0000000000000000000000000000000000000000
    using SafeMath for uint;
    
    IBEP20 internal BEP20 = IBEP20(0x54079fae7d44cD8025e7578319C5E3148b00942F);

    // address public BUSD = address(0x8301f2213c0eed49a7e28ae4c3e91722919b8b47);

    AggregatorInterface internal priceFeed = AggregatorInterface(0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa);
    // 0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa
    // main = 0xcbb98864ef56e9042e7d2efef76141f15731b82f

    uint256 public total_users;
    address public owner;
    string public name;        
    uint256 public decimals;           
    string public symbol;
    uint256 public totalSupply;
    address public treasure_wallet_address;
    address public pool_address;
    uint public treasure_wallet_fees;
    uint public pool_holders_percentage;
    uint256 public referral_fees;
    uint256 public busd_price = 1000000000000000000;

    struct Users {
        uint256 id;
        address user_address;
        uint256 total_supply;
        uint256 balances;
        address referred_from;
    }

    struct Vote {
        address user;
        uint256 counts;
    }

    event VoteEvent (
        address user,
        uint256 counts
    );

    event Mint(
        uint256 id,
        address user_address,
        uint256 total_supply,
        uint256 balances,
        address referred_from
    );

    event Sell(
        address user_address,
        uint256 balances
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping (address => Users) public user;
    mapping (address => uint256) public balances;
    mapping (address => Users) public user_map;
    mapping (address => Vote) public vote;
    mapping (uint256 => address) public user_id_map;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor(
        ) public {
        owner = msg.sender;          
        name = "Hot Fries Coin";         
        decimals = 18;                     
        symbol = "HFC";
        treasure_wallet_fees = 2;
        pool_holders_percentage = 8;
        referral_fees = 2; // 0.2 -> 2/10
        treasure_wallet_address = 0xb06C23E4729615976378EF7A1699Ce6B79acD4f1;
        pool_address = 0x0067a8296ed1d1676f16A629145a3231ad46eb8a;

        initialize_treasurer();
        initialize_pool();
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    function voting() public {
        Vote storage votes = vote[msg.sender];
        Users storage user_data = user_map[msg.sender];

        uint256 vote_amount = 1000000000000000000;

        uint256 allowance_amount = BEP20.allowance(msg.sender, address(this));
        require(allowance_amount >= vote_amount);

        BEP20.transferFrom(msg.sender, treasure_wallet_address, vote_amount);

        user_data.balances -= vote_amount;
        totalSupply = totalSupply.add(vote_amount);
        balances[msg.sender] = balances[msg.sender].sub(vote_amount);

        if(votes.user == address(0)){
            vote[msg.sender] = Vote(msg.sender, 1);
            emit VoteEvent(msg.sender, 1);
        } else {
            votes.counts += 1;
            emit VoteEvent(msg.sender, votes.counts);
        }
    }

    function initialize_treasurer() public {
        total_users++;

        user_id_map[total_users] = treasure_wallet_address;

        user_map[treasure_wallet_address] = Users(total_users, treasure_wallet_address, 0, 0, address(0));

        totalSupply += 0;
        balances[treasure_wallet_address] += 0;
    }

    function initialize_pool() public {
        total_users++;

        user_id_map[total_users] = pool_address;

        user_map[pool_address] = Users(total_users, pool_address, 0, 0, address(0));

        totalSupply += 0;
        balances[pool_address] += 0;
    }

/*
10% will be deducted as fees.
From 10%, 2% goes to HFC treasure wallet and 8% to all users.
*/
    function buy(uint256 _amount, address _referral) public {
        Users storage user_data = user_map[msg.sender];

        (uint256 allowance_amount) = BEP20.allowance(msg.sender, address(this));

        (uint256 amt) = _amount;

        (uint256 price) = calculate_buy_price(amt);

        (uint256 amount) = amt.mul(price).div(10**18);

        require(allowance_amount >= amount);

        (uint256 treasurer) = calculate_tresurer_fees(amt);

        (uint256 pool) = calculate_users_fees(amt);

        (uint256 refer_fees) = calculate_referral_fees(treasurer);

        transfer_asset_to_referral(_referral, refer_fees);

        (uint256 final_amount) = amt.sub(treasurer).sub(pool);

        BEP20.transferFrom(msg.sender, treasure_wallet_address, amount);

        transfer_amount_to_pools_and_treasurer(treasurer, pool);

        Users storage user_datas = user_map[msg.sender];

        address refer = _referral;

        if(user_datas.user_address != address(0)){
            
            user_datas.balances += final_amount;
            totalSupply += _amount;
            balances[msg.sender] = balances[msg.sender].add(final_amount);

            emit Mint(user_datas.id, msg.sender, _amount, final_amount, refer);
        } else {
            total_users++;

            user_id_map[total_users] = msg.sender;

            user_map[msg.sender] = Users(total_users, msg.sender, final_amount, final_amount, refer);

            totalSupply += _amount;
            balances[msg.sender] += final_amount;

            emit Mint(total_users, msg.sender, final_amount, final_amount, refer);
        }

        busd_price = price;
    }

    function transfer_amount_to_pools_and_treasurer(uint256 treasurer, uint256 pool) private {
        Users storage treasurer_user_data = user_map[treasure_wallet_address];
        Users storage pool_user_data = user_map[pool_address];

        treasurer_user_data.balances += treasurer;
        balances[treasure_wallet_address] = balances[treasure_wallet_address].add(treasurer);

        pool_user_data.balances += pool;
        balances[pool_address] = balances[pool_address].add(pool);
    }

    function transfer_asset_to_referral(address _referral, uint256 refer_fees) private {
        if(_referral != address(0)){
            require(user_map[_referral].user_address != address(0));

            (uint256 fees) = calculate_referral_fees(refer_fees);
            
            user_map[_referral].balances += fees;   
            balances[_referral] += fees;
        }
    }

    function transfer_rewards_to_users(uint256 _amount) public {
        uint256 user_fees = calculate_users_fees(_amount);

        uint256 amt = user_fees.div(total_users);

        for(uint256 i = 1; i <= total_users; i++){
            address user_address = user_id_map[i];

            Users storage user_data = user_map[user_address];

            user_data.balances += amt;
        }
    }

    function get_total_buy_amount(uint256 _amount) public view returns(uint256){
        uint256 price = calculate_buy_price(_amount);
        return _amount.mul(price).div(10**18);
    }
    
    function sell(uint256 _value) public {
        // Give approval to contract address of busd

        Users storage user_data = user_map[msg.sender];

        require(balances[msg.sender] >= _value && user_data.balances >= _value);

        (uint256 fees) = calculate_users_mint_token(_value);

        (uint256 price) = calculate_sell_price(fees);

        (uint256 _amount) = fees.mul(price).div(10**18);

        uint256 allowance_amount = BEP20.allowance(treasure_wallet_address, address(this));

        require(allowance_amount >= _amount);

        BEP20.transferFrom(treasure_wallet_address, msg.sender, _amount);

        balances[msg.sender] -= fees;
        user_data.balances -= fees;
        totalSupply -= fees;

        emit Sell(msg.sender, _value);
    }

    function change_treaserer_address(address _treaserer) public onlyOwner {
        treasure_wallet_address = _treaserer;
    }

    function change_pool_address(address _pool) public onlyOwner {
        pool_address = _pool;
    }

    function decimals() external view returns (uint256) {
        return decimals;
    }

    function getLatestPrice() public view returns (uint256) {
        uint256 price = uint256(priceFeed.latestAnswer());
        return price;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address _owner, address spender) external view returns (uint256) {
    return _allowances[_owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    balances[sender] = balances[sender].sub(amount);
    balances[recipient] = balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address _owner, address spender, uint256 amount) internal {
    require(_owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[_owner][spender] = amount;
    emit Approval(_owner, spender, amount);
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns  (string memory) {
    return name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

    function calculate_tresurer_fees(uint _amount) public view returns(uint _fees) {
        return _amount.mul(treasure_wallet_fees).div(100);
    }

    function calculate_users_fees(uint _amount) public view returns(uint _fees) {
        return _amount.mul(pool_holders_percentage).div(100);
    }

    function calculate_referral_fees(uint _amount) public view returns(uint _fees) {
        return _amount.mul(referral_fees).div(100).div(10);
    }

    function calculate_users_mint_token(uint _amount) public view returns(uint _fees) {
        uint256 amt = uint256(100).sub(treasure_wallet_fees.add(pool_holders_percentage));
        return _amount.mul(amt).div(100);
    }

    function calculate_buy_price(uint256 _amount) public view returns(uint256 fees){
        Users memory pool_user_data = user_map[pool_address];

        uint amt = pool_user_data.balances.mul(10**18);

        return (amt.div(totalSupply.add(_amount))).add(busd_price);
    }

    function calculate_sell_price(uint256 _amount) public view returns(uint256 fees){
        Users memory pool_user_data = user_map[pool_address];

        uint amt = pool_user_data.balances.mul(10**18);

        return (amt.div(totalSupply.sub(_amount))).add(busd_price);
    }

    // 1 + (8/ (100 + 0.00008)) = 1.07999936

    // 1 + (8/(100 + 10)) = 1.072

    // 1*10**18 + ( 8 )

    // last_price + ( pool_balance )

    


    // 1 + (8/(100 + 100)) = 1.04
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

interface IBEP20 {
    function name() public view returns (string);

    function symbol() public view returns (string);

    function decimals() public view returns (uint8);

    function totalSupply() public view returns (uint256);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

}