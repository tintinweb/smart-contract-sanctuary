//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner,address spender) public view returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
    _burn(account, value);
  }
}

//SourceUnit: ERC20Detailed.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string memory) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

//SourceUnit: IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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
}

//SourceUnit: MoGu.sol

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./Pools.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract MoGu is ERC20, ERC20Detailed, Pools {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("MoGu", "MOGU", 18) {
        _mint(msg.sender, 1 * (10 ** uint256(decimals())));
        _deployer = msg.sender;
    }
    
    function getPoolInfo(address lp) public view returns (uint256 startTime, uint256 stopTime, uint256 rewardsRate, uint256 rewardsPerToken, uint256 totalFee, uint256 totalPledge, uint256 totalRewards){
        return (_pools[lp].startTime, _pools[lp].stopTime, _pools[lp].rewardsRate, _pools[lp].rewardsPerToken, _pools[lp].totalFee, _pools[lp].totalPledge, _pools[lp].totalRewards);
    }
    
    function getPledge(address lp) public view returns (uint256) {
        return _pools[lp].pledges[msg.sender];
    }
    
    function getDeployer() public view returns (address) {
        return _deployer;
    }
}

//SourceUnit: Pools.sol

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeERC20.sol";


contract Pools is ERC20,ERC20Detailed{

    using SafeMath for uint256;
    using SafeERC20 for ERC20Detailed;  
    address internal _deployer;                    
    mapping(address => Pool) internal _pools;

    
    struct Pool {
        address lp;
        
        uint256 startTime;                  
        uint256 stopTime;
        uint256 lastUpdateTime;
        
        uint256 rewardsRate;
        uint256 rewardsPerToken;
        
        uint256 totalFee;
        uint256 totalPledge;
        uint256 totalRewards;   
    
        mapping(address => uint256) userRewardPerToken;
        mapping(address => uint256) userRewards;
        mapping(address => uint256) pledges;     
    }              

    event AddMiningPool(address indexed lp, uint256 startTime, uint256 stopTime, uint256 totalRewards);     
    event Pledge(address indexed lp, address indexed user, uint256 amount);
    event ReceiveReward(address indexed lp, address indexed user,uint256 amount);    
    event Redemption(address indexed lp, address indexed user, uint256 amount);
    event WithdrawFee(address indexed lp, address indexed recipient, uint256 amount);
    
    event UpdateRewardsPerToken(address indexed lp,uint256 rewardsPerToken, uint256 time, uint256 lastTime, uint256 p,uint256 rewardsRate,uint256 totalPledge);
   



    /**
     * @dev Add a pledged mining pool.
     * only the deployer can call
     */
    function addPool (address lp,uint256 startTime,uint256 stopTime,uint256 totalRewards) public returns (bool){

        require(msg.sender == _deployer, "Only deplpyer can call this.");

        uint256 precision = 10 ** uint256(decimals());
        uint256 rewardsRate = totalRewards.mul(precision).div(stopTime.sub(startTime));
        _pools[lp] = Pool(lp, startTime, stopTime, startTime, rewardsRate, 0, 0, 0, totalRewards.mul(precision));
        
        emit AddMiningPool(lp, startTime, stopTime, totalRewards);
        return true;
    }
    
    function withdrawFee (address lp, address recipient) public returns (bool) {
        
        require(msg.sender == _deployer, "Only deplpyer can call this.");
        
        ERC20Detailed(lp).safeTransfer(recipient, _pools[lp].totalFee);
        emit WithdrawFee(lp,recipient,_pools[lp].totalFee);
        
        _pools[lp].totalFee = 0;
    }

    // stake
    function pledge(address lp,uint256 amount) public returns (bool){

        require(block.timestamp < _pools[lp].stopTime, "It has ended");
        require(amount > 0, "The number must be greater than 0");
        require(_pools[lp].lp == lp, "Pledge pool does not exist");
        
        // 
        if (block.timestamp > _pools[lp].startTime) {
            if (_pools[lp].pledges[msg.sender] > 0) {
                _updateRewardsPerToken(lp);
                uint256 p = _pools[lp].rewardsPerToken.sub(_pools[lp].userRewardPerToken[msg.sender]);
                uint256 reward = _pools[lp].pledges[msg.sender].mul(p);
                _pools[lp].userRewards[msg.sender] = _pools[lp].userRewards[msg.sender].add(reward);
            }
            _pools[lp].userRewardPerToken[msg.sender] = _pools[lp].rewardsPerToken;
        }
        
        
        // amount arrived to msg.sender
        uint256 arrivedAmount = amount.mul(95).div(100);
        _pools[lp].pledges[msg.sender] = _pools[lp].pledges[msg.sender].add(arrivedAmount);
        _pools[lp].totalPledge = _pools[lp].totalPledge.add(arrivedAmount);
        
        // fee to deplpyer
        uint256 feeAmount = amount.sub(arrivedAmount);
        _pools[lp].totalFee = _pools[lp].totalFee.add(feeAmount);
        
        // transfer 
        ERC20Detailed(lp).safeTransferFrom(msg.sender, address(this), amount);
        
        // event
        emit Pledge(lp, msg.sender, amount);
        return true;
    }

    function getReceivableRewards(address lp) public view returns (uint256) {
        
        if (block.timestamp <= _pools[lp].startTime) {
            return 0;
        }
        if (_pools[lp].lp != lp) {
            return 0;
        }
        if (_pools[lp].pledges[msg.sender] == 0) {
            return 0;
        }
    
        uint256 thisTime = SafeMath.min(block.timestamp, _pools[lp].stopTime);
        
        uint256 precision = 10 ** uint256(decimals());
        uint256 p = thisTime.sub(_pools[lp].lastUpdateTime);
        p = p.mul(_pools[lp].rewardsRate)
            .mul(precision)
            .div(_pools[lp].totalPledge)
            .add(_pools[lp].rewardsPerToken)
            .sub(_pools[lp].userRewardPerToken[msg.sender]);
        
        return
            _pools[lp].pledges[msg.sender]
            .mul(p)
            .add(_pools[lp].userRewards[msg.sender])
            .div(precision);
    }
    
    
    function receiveRewards(address lp) public returns (bool){
        require(block.timestamp > _pools[lp].startTime, "Not started yet");
        require(_pools[lp].lp == lp, "Pledge pool does not exist");
        uint256 pledges = _pools[lp].pledges[msg.sender];
        require(pledges > 0, "You can receive rewards only after pledge");
        
        _receiveReward(lp);
        return true;
    }
 
    function redemption(address lp) public returns (bool){
        require(_pools[lp].lp == lp, "Pledge pool does not exist");
        
        
        uint256 amount = _pools[lp].pledges[msg.sender];
        require(amount > 0, "Cannot withdraw 0");
        
        if (block.timestamp > _pools[lp].startTime) {
            _receiveReward(lp);
        }
        
        uint256 arrivedAmount = amount.mul(95).div(100);
        _pools[lp].pledges[msg.sender] = 0;
        _pools[lp].totalPledge = _pools[lp].totalPledge.sub(amount);
        
        uint256 feeAmount = amount.mul(5).div(100);
        _pools[lp].totalFee = _pools[lp].totalFee.add(feeAmount);
        
       
        ERC20Detailed(lp).safeTransfer(msg.sender, arrivedAmount);
       
        emit Redemption(lp, msg.sender, amount);
        return true;
    }
    
    function _receiveReward(address lp) internal {
        _updateRewardsPerToken(lp);
        
        uint256 p = _pools[lp].rewardsPerToken.sub(_pools[lp].userRewardPerToken[msg.sender]);
        
        uint256 reward = _pools[lp].pledges[msg.sender].mul(p).add(_pools[lp].userRewards[msg.sender]);
        _pools[lp].userRewards[msg.sender] = 0;
        
        _pools[lp].userRewardPerToken[msg.sender] = _pools[lp].rewardsPerToken;
        
        uint256 precision = 10 ** uint256(decimals());
        reward = reward.div(precision);
        
        _mint(msg.sender,reward);
        
        emit ReceiveReward(lp, msg.sender, reward);
    }



    function _updateRewardsPerToken(address lp) internal {
      
        uint256 last = _pools[lp].lastUpdateTime;
        uint256 thisTime = SafeMath.min(block.timestamp, _pools[lp].stopTime);
        
        uint256 precision = 10 ** uint256(decimals());
        
        uint256 p = thisTime
            .sub(_pools[lp].lastUpdateTime)
            .mul(_pools[lp].rewardsRate)
            .mul(precision)
            .div(_pools[lp].totalPledge); 
       
        _pools[lp].rewardsPerToken = _pools[lp].rewardsPerToken.add(p);
        _pools[lp].lastUpdateTime = thisTime;
        
        emit UpdateRewardsPerToken(lp,_pools[lp].rewardsPerToken,thisTime,last, p,_pools[lp].rewardsRate,_pools[lp].totalPledge);
    }
}


//SourceUnit: SafeERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
      require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
      require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
      // safeApprove should only be called when setting an initial allowance, 
      // or when resetting it to zero. To increase and decrease it, use 
      // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
      require((value == 0) || (token.allowance(msg.sender, spender) == 0));
      require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
      uint256 newAllowance = token.allowance(address(this), spender).add(value);
      require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
      uint256 newAllowance = token.allowance(address(this), spender).sub(value);
      require(token.approve(spender, newAllowance));
    }
    
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
    * @dev Returns the largest of two numbers.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
    * @dev Returns the smallest of two numbers.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Calculates the average of two numbers. Since these are integers,
    * averages of an even and odd number cannot be represented, and will be
    * rounded down.
    */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}