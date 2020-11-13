// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


contract Governable is Initializable {
    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function initialize(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    modifier governance() {
        require(msg.sender == governor);
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {

    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    
    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfig(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfig(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}


interface IFarm {
    function getBonusToken() external view returns (address);
}

interface IPool {
    event Farming(address indexed farmer, address indexed from, uint amount);
    event Unfarming(address indexed farmer, address indexed to, uint amount);
    event Harvest(address indexed farmer, address indexed to, uint amount);
    
    function farming(uint amount) external;
    function farming(address from, uint amount) external;
    function unfarming() external returns (uint amount);
    function unfarming(uint amount) external returns (uint);
    function unfarming(address to, uint amount) external returns (uint);
    function harvest() external returns (uint amount);
    function harvest(address to) external returns (uint amount);
    function harvestCapacity(address farmer) external view returns (uint amount);
}

contract SimplePool is IPool, Configurable {
    using SafeMath for uint;
    using TransferHelper for address;

	address public farm;
	address public underlying;
	uint public span;
	uint public end;
	uint public totalStaking;
	mapping(address => uint) public stakingOf;
	mapping(address => uint) public lasttimeOf;
	
	function initialize(address governor, address _farm, address _underlying) public initializer {
	    super.initialize(governor);
	    
	    farm        = _farm;
	    underlying  = _underlying;
	    
	    IFarm(farm).getBonusToken();                  // just check
	    IERC20(underlying).totalSupply();          // just check
	}
    
    function setHarvestSpan(uint _span, bool isLinear) virtual external governance {
        span = _span;
        if(isLinear)
            end = now + _span;
        else
            end = 0;
    }
    
    function farming(uint amount) virtual override external {
        farming(msg.sender, amount);
    }
    function farming(address from, uint amount) virtual override public {
        harvest();
        
        _farming(from, amount);
        
        stakingOf[msg.sender] = stakingOf[msg.sender].add(amount);
        totalStaking = totalStaking.add(amount);
        
        emit Farming(msg.sender, from, amount);
    }
    function _farming(address from, uint amount) virtual internal {
        underlying.safeTransferFrom(from, address(this), amount);
    }
    
    function unfarming() virtual override external returns (uint amount){
        return unfarming(msg.sender, stakingOf[msg.sender]);
    }
    function unfarming(uint amount) virtual override external returns (uint){
        return unfarming(msg.sender, amount);
    }
    function unfarming(address to, uint amount) virtual override public returns (uint){
        harvest();
        
        totalStaking = totalStaking.sub(amount);
        stakingOf[msg.sender] = stakingOf[msg.sender].sub(amount);
        
        _unfarming(to, amount);
        
        emit Unfarming(msg.sender, to, amount);
        return amount;
    }
    function _unfarming(address to, uint amount) virtual internal returns (uint){
        underlying.safeTransfer(to, amount);
        return amount;
    }
    
    function harvest() virtual override public returns (uint amount) {
        return harvest(msg.sender);
    }
    function harvest(address to) virtual override public returns (uint amount) {
        amount = harvestCapacity(msg.sender);
        _harvest(to, amount);
    
        lasttimeOf[msg.sender] = now;

        emit Harvest(msg.sender, to, amount);
    }
    function _harvest(address to, uint amount) virtual internal {
        if(amount > 0) {
            IFarm(farm).getBonusToken().safeTransferFrom(farm, to, amount);
            if(config['teamAddr'] != 0 && config['teamRatio'] != 0)
                IFarm(farm).getBonusToken().safeTransferFrom(farm, address(config['teamAddr']), amount.mul(config['teamRatio']).div(1 ether));
        }
    }
    
    function harvestCapacity(address farmer) virtual override public view returns (uint amount) {
        if(span == 0 || totalStaking == 0)
            return amount;
        
        amount = IERC20(IFarm(farm).getBonusToken()).allowance(farm, address(this));
        amount = amount.mul(stakingOf[farmer]).div(totalStaking);
        
        uint lasttime = lasttimeOf[farmer];
        if(end == 0) {                                                         // isNonLinear, endless
            if(now.sub(lasttime) < span)
                amount = amount.mul(now.sub(lasttime)).div(span);
        }else if(now < end)
            amount = amount.mul(now.sub(lasttime)).div(end.sub(lasttime));
        else if(lasttime >= end)
            amount = 0;
    }
} 

contract ExactPool is IPool, Configurable {
    using SafeMath for uint;
    using TransferHelper for address;

	bytes32 constant private _bonusPerDay_		= 'bonusPerDay';

	address public farm;
	address public underlying;
	uint public totalStaking;
	mapping(address => uint) public stakingOf;
	mapping(address => uint) public sumRewardPerOf;
	uint public sumRewardPer;
	uint public lasttime;
	
	function initialize(address governor, address _farm, address _underlying, uint bonusPerDay) virtual public initializer {
	    super.initialize(governor);
	    
	    farm     = _farm;
	    underlying  = _underlying;
		config[_bonusPerDay_] = bonusPerDay;
        lasttime = now;
	    
	    IFarm(farm).getBonusToken();                   // just check
	    IERC20(underlying).totalSupply();           // just check
	}
    
    function farming(uint amount) virtual override external {
        farming(msg.sender, amount);
    }
    function farming(address from, uint amount) virtual override public {
        harvest();
        
        _farming(from, amount);
        
        stakingOf[msg.sender] = stakingOf[msg.sender].add(amount);
        totalStaking = totalStaking.add(amount);
        
        emit Farming(msg.sender, from, amount);
    }
    function _farming(address from, uint amount) virtual internal {
        underlying.safeTransferFrom(from, address(this), amount);
    }
    
    function unfarming() virtual override external returns (uint amount){
        return unfarming(msg.sender, stakingOf[msg.sender]);
    }
    function unfarming(uint amount) virtual override external returns (uint){
        return unfarming(msg.sender, amount);
    }
    function unfarming(address to, uint amount) virtual override public returns (uint){
        harvest();
        
        totalStaking = totalStaking.sub(amount);
        stakingOf[msg.sender] = stakingOf[msg.sender].sub(amount);
        
        _unfarming(to, amount);
        
        emit Unfarming(msg.sender, to, amount);
        return amount;
    }
    function _unfarming(address to, uint amount) virtual internal returns (uint){
        underlying.safeTransfer(to, amount);
        return amount;
    }
    
    function harvest() virtual override public returns (uint amount) {
        return harvest(msg.sender);
    }
    function harvest(address to) virtual override public returns (uint amount) {
        amount = 0;
        if(totalStaking == 0)
            return amount;
        
        uint delta = _harvestDelta();
        amount = _harvestCapacity(msg.sender, delta, sumRewardPer, sumRewardPerOf[msg.sender]);
        
        if(delta > 0)
            sumRewardPer = sumRewardPer.add(delta.mul(1 ether).div(totalStaking));
        if(sumRewardPerOf[msg.sender] != sumRewardPer)
            sumRewardPerOf[msg.sender] = sumRewardPer;
        lasttime = now;

        _harvest(to, amount);
    
        emit Harvest(msg.sender, to, amount);
    }
    function _harvest(address to, uint amount) virtual internal {
        if(amount > 0) {
            IFarm(farm).getBonusToken().safeTransferFrom(farm, to, amount);
            if(config['teamAddr'] != 0 && config['teamRatio'] != 0)
                IFarm(farm).getBonusToken().safeTransferFrom(farm, address(config['teamAddr']), amount.mul(config['teamRatio']).div(1 ether));
        }
    }
    
    function harvestCapacity(address farmer) virtual override public view returns (uint amount) {
        amount = _harvestCapacity(farmer, _harvestDelta(), sumRewardPer, sumRewardPerOf[farmer]);
    }
    function _harvestCapacity(address farmer, uint delta, uint sumPer, uint lastSumPer) virtual internal view returns (uint amount) {
        if(totalStaking == 0)
            return 0;
        
        amount = sumPer.sub(lastSumPer);
        amount = amount.add(delta.mul(1 ether).div(totalStaking));
        amount = amount.mul(stakingOf[farmer]).div(1 ether);
    }
    function _harvestDelta() virtual internal view returns(uint) {
		if(now > lasttime)
			return getBonusPerDay().mul(now.sub(lasttime)).div(1 days);
		else
		    return 0;
    }
    
    function getBonusPerDay() public view returns (uint) {
        return config[_bonusPerDay_];
    }
} 

contract LiquidityPool is ExactPool {
	function initialize(address governor, address bounce, address lp_token, uint bonusPerDay) virtual override public initializer {
	    super.initialize(governor, bounce, lp_token, bonusPerDay);
	}
}


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}