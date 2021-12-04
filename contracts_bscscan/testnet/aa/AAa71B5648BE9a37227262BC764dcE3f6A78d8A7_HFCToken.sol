/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

pragma solidity ^0.4.24;

contract HFCToken {

    using SafeMath for uint;

    IERC20 internal ERC20 = IERC20(0x4938D01e9c9a5E8198616A526C5Bc72ad5000F86);

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
    uint public treasure_wallet_fees;
    uint public coin_holders_percentage;
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

    mapping (address => Users) public user;
    mapping (address => uint256) public balances;
    mapping (address => Users) public user_map;
    mapping (address => Vote) public vote;
    mapping (uint256 => address) public user_id_map;
    mapping (address => mapping (address => uint256)) public allowed;

    constructor(
        ) public {
        owner = msg.sender;          
        name = "Hot Fries Coin";         
        decimals = 18;                     
        symbol = "HFC";
        treasure_wallet_fees = 2;
        coin_holders_percentage = 8;
        treasure_wallet_address = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

   function getLatestPrice() public view returns (uint256) {
        uint256 price = uint256(priceFeed.latestAnswer());
        return price;
    }

    function voting() public {
        Vote storage votes = vote[msg.sender];
        Users storage user_data = user_map[msg.sender];

        uint256 vote_amount = 1000000000000000000;

        uint256 allowance_amount = ERC20.allowance(msg.sender, address(this));
        require(allowance_amount >= vote_amount);

        ERC20.transferFrom(msg.sender, treasure_wallet_address, vote_amount);

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

/*
10% will be deducted as fees.
From 10%, 2% goes to HFC treasure wallet and 8% to all users.
*/
    function buy(uint256 _amount, address _referral) public {
        Users storage user_data = user_map[msg.sender];

        // msg.sender -> approves -> contract address -> msg.sender transferfrom  
        // treasure_wallet_address using msg.sender as contract_address like this ->
        // ERC20.transferFrom(msg.sender, treasure_wallet_address, _amount);

        uint256 allowance_amount = ERC20.allowance(msg.sender, address(this));

        require(allowance_amount >= _amount && _amount == _amount.div(10**18).mul(busd_price));

        ERC20.transferFrom(msg.sender, treasure_wallet_address, _amount);

        uint256 user_amount = calculate_users_mint_token(_amount);

        if(_referral != address(0)){
            require(user_map[_referral].user_address != address(0));

            (uint256 fees) = calculate_referral_fees(_amount);

            user_map[_referral].balances += fees;
            balances[_referral] += fees;
        }

        if(user_data.user_address != address(0)){
            user_data.balances += user_amount;
            totalSupply = totalSupply.add(user_amount);
            balances[msg.sender] = balances[msg.sender].add(user_amount);

            emit Mint(user_data.id, msg.sender, _amount, user_amount, _referral);
        } else {
            total_users++;

            user_id_map[total_users] = msg.sender;

            user_map[msg.sender] = Users(total_users, msg.sender, user_amount, user_amount, _referral);

            totalSupply = totalSupply.add(user_amount);
            balances[msg.sender] += user_amount;

            emit Mint(total_users, msg.sender, user_amount, user_amount, _referral);
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
    
    function sell(uint256 _value) public {
        // Give approval to contract address of busd

        Users storage user_data = user_map[msg.sender];

        require(balances[msg.sender] >= _value && user_data.balances >= _value);

        (uint256 fees) = calculate_users_mint_token(_value);

        (uint256 _amount) = fees.mul(busd_price).div(10**18);

        uint256 allowance_amount = ERC20.allowance(treasure_wallet_address, address(this));

        require(allowance_amount >= _amount);

        ERC20.transferFrom(treasure_wallet_address, msg.sender, _amount);
        
        balances[msg.sender] -= fees;
        user_data.balances -= fees;
        totalSupply -= fees;

        emit Sell(msg.sender, _value);
    } 

    function decimals() external view returns (uint256) {
        return decimals;
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
        return _amount.mul(coin_holders_percentage).div(100);
    }

    function calculate_referral_fees(uint _amount) public view returns(uint _fees) {
        return _amount.mul(2).div(100).div(10);
    }

    function calculate_users_mint_token(uint _amount) public view returns(uint _fees) {
        uint256 amt = uint256(100).sub(treasure_wallet_fees.add(coin_holders_percentage));
        return _amount.mul(amt).div(100);
    }

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

interface IERC20 {
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