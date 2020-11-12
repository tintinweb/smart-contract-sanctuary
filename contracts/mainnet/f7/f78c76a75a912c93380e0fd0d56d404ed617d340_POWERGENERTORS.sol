pragma solidity 0.6.4;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function supplyeffect(uint _amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
}

interface POWER {
    
   function scaledPower(uint amount) external returns(bool);
   function totalPopping() external view returns (uint256);
 }

interface FIRE {

    function balanceOf(address _user) external view returns (uint256); 
 }
 
 
contract POWERGENERTORS{
    
    using SafeMath for uint256;
    
    //======================================EVENTS=========================================//
    event POPCORNEvent(address indexed executioner, address indexed pool, uint amount);
    event DITCHEvent(address indexed executioner, address indexed pool, uint amount);
    event PooppingRewardEvent(address indexed executioner, address indexed pool, uint amount);

   
     //======================================INTERRACTING MACHINE SECTIONS=========================================//
    address public popcornToken;
    address public fireball;
    address public operator;
    address public powerToken;
    
    bool public _machineReady;
    
    uint256 constant private FLOAT_SCALAR = 2**64;
    uint256 public MINIMUM_POP = 10000000000000000000;
	uint256 private MIN_POP_DUR = 10 days;
	uint256 public MIN_FIRE_TO_POP = 1000000000000000000;
	
	uint public infocheck;
	
	uint actualValue;
    
    struct User {
        
		uint256 popslot;
		int256 scaledPayout;  
		uint256 poptime;
	}

	struct Info {
	    
		uint256 totalPopping;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken; //pool balance 
		address admin;
	}
	
	Info private info;
	//mapping(address => bool) whitelisted;
	
	constructor() public {
       
	    info.admin = msg.sender;
		_machineReady = true;
		
	}
	
//======================================ADMINSTRATION=========================================//

	modifier onlyCreator() {
        require(msg.sender == info.admin, "Ownable: caller is not the administrator");
        _;
    }
    
    modifier onlypopcornTokenoroperators() {
        require(msg.sender == popcornToken || msg.sender == operator, "Authorization: only authorized contract can call");
        _;
    }
    
    
 
    
	 function machinery(address _popcornToken, address _powertoken, address _fire, address _operator) public onlyCreator returns (bool success) {
	    
	    popcornToken = _popcornToken;
        powerToken = _powertoken; //liquidity token
        fireball = _fire;
        operator = _operator;
        
        return true;
    }
    

	
	function _minPopAmount(uint256 _number) onlyCreator public {
		
		MINIMUM_POP = _number*1000000000000000000;
		
	}
	
	function _minFIRE_TO_POP(uint256 _number) onlyCreator public {
		
		MIN_FIRE_TO_POP = _number*1000000000000000000;
		
	}
    
    function machineReady(bool _status) public onlyCreator {
	_machineReady = _status;
    }
    
  

	function popCorns(uint256 _tokens) external {
		_popcorns(_tokens);
	}
    
    function DitchCorns(uint256 _tokens) external {
		_ditchcorns(_tokens);
	}
	


	function totalPopping() public view returns (uint256) {
		return info.totalPopping;
	}
	
    function popslotOf(address _user) public view returns (uint256) {
		return info.users[_user].popslot;
	}

	function cornsOf(address _user) public view returns (uint256) {
	    
	   return uint256(int256(info.scaledPayoutPerToken * info.users[_user].popslot) - info.users[_user].scaledPayout) / FLOAT_SCALAR;   
	    
	}
	

	function userData(address _user) public view 
	returns (uint256 totalCornsPopping, uint256 userpopslot, 
	uint256 usercorns, uint256 userpoptime, int256 scaledPayout) {
	    
		return (totalPopping(), popslotOf(_user), cornsOf(_user), info.users[_user].poptime, info.users[_user].scaledPayout);
	
	    
	}
	

//======================================ACTION CALLS=========================================//	
	
	function _popcorns(uint256 _amount) internal {
	    
	    require(_machineReady, "Staking not yet initialized");
	    require(FIRE(fireball).balanceOf(msg.sender) > MIN_FIRE_TO_POP, "You do not have sufficient fire to pop this corn");
	    
		require(IERC20(powerToken).balanceOf(msg.sender) >= _amount, "Insufficient power token balance");
		require(popslotOf(msg.sender) + _amount >= MINIMUM_POP, "Your amount is lower than the minimum amount allowed to pop");
		require(IERC20(powerToken).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance given to contract yet to spend by user");
		
		info.users[msg.sender].poptime = now;
		info.totalPopping += _amount;
		info.users[msg.sender].popslot += _amount;
		
		info.users[msg.sender].scaledPayout += int256(_amount * info.scaledPayoutPerToken); 
		IERC20(powerToken).transferFrom(msg.sender, address(this), _amount);      // Transfer liquidity tokens from the sender to this contract
		
        emit POPCORNEvent(msg.sender, address(this), _amount);
	}
	
	    
	
	function _ditchcorns(uint256 _amount) internal {
	    
		require(popslotOf(msg.sender) >= _amount, "You currently do not have up to that amount popping");
		
		info.totalPopping -= _amount;
		info.users[msg.sender].popslot -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);
		
		require(IERC20(powerToken).transfer(msg.sender, _amount), "Transaction failed");
        emit DITCHEvent(address(this), msg.sender, _amount);
		
	}
		
		
	function Takecorns() external returns (uint256) {
		    
		uint256 _dividends = cornsOf(msg.sender);
		require(_dividends >= 0, "you do not have any corn yet");
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		
		require(IERC20(popcornToken).transfer(msg.sender, _dividends), "Transaction Failed");    // Transfer dividends to msg.sender
		emit PooppingRewardEvent(msg.sender, address(this), _dividends);
		
		return _dividends;
	    
		    
	}
		
		
 
    function scaledPower(uint _amount) external onlypopcornTokenoroperators returns(bool){
            
    		info.scaledPayoutPerToken += _amount * FLOAT_SCALAR / info.totalPopping;
    		infocheck = info.scaledPayoutPerToken;
    		return true;
            
    }
    
   
        
    function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
              (uint l, uint h) = fullMul (x, y);
              assert (h < z);
              uint mm = mulmod (x, y, z);
              if (mm > l) h -= 1;
              l -= mm;
              uint pow2 = z & -z;
              z /= pow2;
              l /= pow2;
              l += h * ((-pow2) / pow2 + 1);
              uint r = 1;
              r *= 2 - z * r;
              r *= 2 - z * r;
              r *= 2 - z * r;
              r *= 2 - z * r;
              r *= 2 - z * r;
              r *= 2 - z * r;
              r *= 2 - z * r;
              r *= 2 - z * r;
              return l * r;
    }
        
    function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
              uint mm = mulmod (x, y, uint (-1));
              l = x * y;
              h = mm - l;
              if (mm < l) h -= 1;
    }
 
    
}