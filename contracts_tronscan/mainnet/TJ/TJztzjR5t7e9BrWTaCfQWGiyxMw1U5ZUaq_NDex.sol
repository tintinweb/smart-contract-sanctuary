//SourceUnit: IERC20.sol

pragma solidity  >=0.5.0 <0.7.0;
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool success);
    function burnFrom(address _from, uint256 _value) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value); 
}


//SourceUnit: NDex.sol

pragma solidity ^0.5.10;

import './IERC20.sol';
import './SafeMath.sol';

contract NDex{
    using SafeMath for uint256;
    struct NdxUser {
        uint256 ndx_distribution;
        uint256 ndx_payout;
        uint256 ndx_distribution_payout;
        uint256 ndx_total_payout;
        uint256 ndx_match_bonus;
    }
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40  deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 family_deposit; 
        uint8   dao_level; //default is 0, 1 for one star, 2 for two star
    }

    address payable public owner;
    address payable public admin_fee;
    address payable public entropy_pool;

    mapping(address => User) public users;
    mapping(address => NdxUser) public ndx_users;

    uint256[] public cycles;
    uint8[] public ref_bonuses; 

    address[] public dao_1star;   //one star DAO members
    address[] public dao_2star;   //two star DAO members

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public ndx_total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event NDXWithdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    IERC20 usdt;
    IERC20 ndx;

    constructor() public {
        owner = msg.sender;
    
    	ndx = IERC20(0x563CB80479ca86cffC16160d80433B4Ceaac07d2); //NDX contract mainnet
    	//ndx = IERC20(0xB7eF020E3b15b2f4cD73fBbc03B7833688B9e5a1); //NDX contract shasta
    	usdt = IERC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C); //USDT contract mainnet
    	//usdt = IERC20(0xd98BF77669F75dfBFEe95643a313acD0Ba5E9b62); //USDT contract shasta
        admin_fee = address(0x2d097516aEd475dFB92bA611e1E5fd665e67dbB3);  //cold wallet mainnet
        //admin_fee = address(0x2d097516aEd475dFB92bA611e1E5fd665e67dbB3);  //cold wallet shasta 
        entropy_pool = address(0x504A9088291c325338d171dDE587B26296399E58);  //entropy pool mainnet
        //entropy_pool = address(0xc0d37625D56651a30e2188DB42996Ef269fc0b6A);  //entropy pool shasta 
        
        ref_bonuses.push(30);
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
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        cycles.push(3e9);
        cycles.push(9e9);
        cycles.push(27e9);
        cycles.push(6e10);
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

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }else 
	{
        	require(total_deposited.add(_amount) <= 300000000000000, "Limit of 300m USDT reached");
		require(_amount >= 5e7 && _amount <= cycles[0], "Bad amount");
	}
        
	usdt.transferFrom(_addr, address(this), _amount);
        emit NewDeposit(_addr, _amount);

	usdt.transfer(admin_fee, _amount.div(20)); //admin fee 5%

	usdt.transfer(entropy_pool, _amount.div(10)); //entropy pool 10%

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits = users[_addr].total_deposits.add(_amount);
        users[_addr].family_deposit = users[_addr].family_deposit.add(_amount);
        total_deposited = total_deposited.add(_amount);
        
	_refDeposit(_addr, _amount);
	if(total_deposited <= 300000000000000)
		_ndxDistribute(_addr, _amount);
    }


    function checkDao() external returns (uint256 result){
    	address _addr = msg.sender;
	uint256 dao1star_standard = 500000000000; //0.5m  USDT
	uint256 dao2star_standard = 1000000000000; //1m USDT

	uint256 family_deposit = users[_addr].family_deposit;

	if(family_deposit >= dao2star_standard)
	{
		int flag = 0;
		for(uint256 i=0; i < dao_2star.length; i++)
		{
			if(dao_2star[i] == address(0)) break;
			if(dao_2star[i] == _addr)
			{
				flag = 1;
				break;
			}
		}
		if(flag == 0)
			dao_2star.push(_addr);
		users[_addr].dao_level = 2;
		return 2;
	}else if(family_deposit >= dao1star_standard)
	{
		int flag = 0;
		for(uint256 i=0; i < dao_1star.length; i++)
		{
			if(dao_1star[i] == address(0)) break;
			if(dao_1star[i] == _addr)
			{
				flag = 1;
				break;
			}
		}
		if(flag == 0)
			dao_1star.push(_addr);
		users[_addr].dao_level = 1;
		return 1;
	}
	users[_addr].dao_level = 0;
	return 0;
    }

    function _ndxDistribute(address _addr, uint256 _amount) private {
        require(_addr != address(0), "NDX to zero");
	uint256 layer_deposit = 1000000000000;
	uint256 base = 200000000000;
	uint256 gap = 2000000000;

	uint256 layer = total_deposited.div(layer_deposit);
	uint256 distribution = _amount.mul(base.add(layer.mul(gap))).div(layer_deposit).div(2);
	ndx_users[_addr].ndx_distribution = ndx_users[_addr].ndx_distribution.sub(ndx_users[_addr].ndx_distribution_payout).add(distribution);
	ndx_users[_addr].ndx_payout = 0;
	ndx_users[_addr].ndx_distribution_payout = 0;
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);
                
                users[up].match_bonus = users[up].match_bonus.add(bonus);

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _refDeposit(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            users[up].family_deposit = users[up].family_deposit.add(_amount);
            up = users[up].upline;
        }
    }

    function _ndxRefPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);
                
                ndx_users[up].ndx_match_bonus = ndx_users[up].ndx_match_bonus.add(bonus);

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function deposit(address _upline, uint256 _amount) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, _amount);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts.add(to_payout) > max_payout) {
                to_payout = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].deposit_payouts = users[msg.sender].deposit_payouts.add(to_payout);
            users[msg.sender].payouts = users[msg.sender].payouts.add(to_payout);

            _refPayout(msg.sender, to_payout);
        }
        
        // Match payout - structure
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts.add(match_bonus) > max_payout) {
                match_bonus = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].match_bonus = users[msg.sender].match_bonus.sub(match_bonus);
            users[msg.sender].payouts = users[msg.sender].payouts.add(match_bonus);
            to_payout = to_payout.add(match_bonus);
        }

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts = users[msg.sender].total_payouts.add(to_payout);
        total_withdraw = total_withdraw.add(to_payout);

	usdt.transfer(msg.sender, to_payout);
	emit Withdraw(msg.sender, to_payout);

	if(users[msg.sender].payouts >= max_payout) {
	    emit LimitReached(msg.sender, users[msg.sender].payouts);
	}
    }

    //airdrop of NDX
    function withdraw_ndx() external {
        uint256 to_payout  = this.ndx_payoutOf(msg.sender);
        
        // Deposit payout
        if(to_payout > 0) {
            ndx_users[msg.sender].ndx_distribution_payout = ndx_users[msg.sender].ndx_distribution_payout.add(to_payout);
            ndx_users[msg.sender].ndx_payout = ndx_users[msg.sender].ndx_payout.add(to_payout);

            _ndxRefPayout(msg.sender, to_payout);
        }
        
        // Match payout - structure
        if(ndx_users[msg.sender].ndx_match_bonus > 0) {
            uint256 match_bonus = ndx_users[msg.sender].ndx_match_bonus;

            ndx_users[msg.sender].ndx_match_bonus = ndx_users[msg.sender].ndx_match_bonus.sub(match_bonus);
            ndx_users[msg.sender].ndx_payout = ndx_users[msg.sender].ndx_payout.add(match_bonus);
            to_payout = to_payout.add(match_bonus);
        }

        require(to_payout > 0, "Zero ndx payout");
        
        ndx_users[msg.sender].ndx_total_payout = ndx_users[msg.sender].ndx_total_payout.add(to_payout);
        ndx_total_withdraw = ndx_total_withdraw.add(to_payout);

	ndx.transfer(msg.sender, to_payout);
	emit NDXWithdraw(msg.sender, to_payout);
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount.mul(27).div(10);
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount.mul((block.timestamp.sub(users[_addr].deposit_time)).div(1 days)).div(100)).sub(users[_addr].deposit_payouts);
            
            if(users[_addr].deposit_payouts.add(payout) > max_payout) {
                payout = max_payout.sub(users[_addr].deposit_payouts);
            }
        }
    }

    function ndx_payoutOf(address _addr) view external returns(uint256 payout) {
        require(_addr != address(0), "NDX payout zero");
	
	uint256 gap = (block.timestamp.sub(users[_addr].deposit_time)).div(1 days);
	if(gap > 100)
		gap = 100;
        payout = (ndx_users[_addr].ndx_distribution.mul(gap).div(100)).sub(ndx_users[_addr].ndx_distribution_payout);

	if(payout < 0)
		payout =  0;
    }

    /*
        Only external call
    */
    function get1starDAO() view external returns (address[] memory _dao_1star){
        return dao_1star;
    }

    function get2starDAO() view external returns (address[] memory _dao_2star){
        return dao_2star;
    }

    function userInfoNdx(address _addr) view external returns(uint256 ndx_distribution, uint256 ndx_payout, uint256 ndx_total_payout, uint256 ndx_match_bonus, uint256 ndx_distribution_payout) {
        return (ndx_users[_addr].ndx_distribution, ndx_users[_addr].ndx_payout, ndx_users[_addr].ndx_total_payout, ndx_users[_addr].ndx_match_bonus, ndx_users[_addr].ndx_distribution_payout);
    }
    
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus,  uint256 deposit_payouts) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].match_bonus, users[_addr].deposit_payouts);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint8 dao_level, uint256 family_deposit) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure, users[_addr].dao_level,  users[_addr].family_deposit);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _ndx_total_withdraw) {
        return (total_users, total_deposited, total_withdraw, ndx_total_withdraw);
    }
}


//SourceUnit: SafeMath.sol

pragma solidity  >=0.5.0 <0.7.0;
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

  /**
   * @dev gives square root of given x.
   */
  function sqrt(uint256 x)
  internal
  pure
  returns(uint256 y) {
    uint256 z = ((add(x, 1)) / 2);
    y = x;
    while (z < y) {
      y = z;
      z = ((add((x / z), z)) / 2);
    }
  }

  /**
   * @dev gives square. multiplies x by x
   */
  function sq(uint256 x)
  internal
  pure
  returns(uint256) {
    return (mul(x, x));
  }

  /**
   * @dev x to the power of y
   */
  function pwr(uint256 x, uint256 y)
  internal
  pure
  returns(uint256) {
    if (x == 0)
      return (0);
    else if (y == 0)
      return (1);
    else {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z, x);
      return (z);
    }
  }
}