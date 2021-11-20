/**
 *Submitted for verification at polygonscan.com on 2021-11-19
*/

pragma solidity 0.6.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


contract AxiaSwapContract{
    
    using SafeMath for uint256;
    
//======================================EVENTS=========================================//
    event SwappedInEvent(address indexed staker, address indexed pool, uint amount);
    event SwappedOutEvent(address indexed staker, address indexed pool, uint amount);
    
    
//======================================STAKING POOLS=========================================//
    address public AxiatokenB;
    address public AxiatokenC;
    
    address public administrator;
    
    bool public swapEnabled;
    
   
	
	uint public totalswappedin;
	uint public totalswappedout;
    
    

	
	constructor() public {
	    
        administrator = msg.sender;
        swapEnabled = false;
	}

//======================================ADMINSTRATION=========================================//

	modifier onlyCreator() {
        require(msg.sender == administrator, "Ownable: caller is not the administrator");
        _;
    }
    
    
    
    
    
	 function tokenconfigs(address _axiatokenB, address _axiatokenC) public onlyCreator returns (bool success) {
	    require(_axiatokenB != _axiatokenC, "Insertion of same address is not supported");
	    require(_axiatokenB != address(0) && _axiatokenC != address(0), "Insertion of address(0) is not supported");
        AxiatokenB = _axiatokenB;
        AxiatokenC = _axiatokenC;
        return true;
    }
    
   
	
	
	
	function stakingStatus(bool _status) public onlyCreator {
	require(AxiatokenB != address(0) && AxiatokenC != address(0), "Pool addresses are not yet setup");
	swapEnabled = _status;
    }
    
    
//======================================USER WRITE=========================================//

	function SwapExactAmountofTokenBforTokenC(uint256 _tokens) external {
		_swapIn(_tokens);
	}
	
	function SwapExactAmountofTokenCforTokenB(uint256 _tokens) external {
		_swapOut(_tokens);
	}
    


//======================================ACTION CALLS=========================================//	
	
	function _swapIn(uint256 _amount) internal {
	    
	    require(swapEnabled, "Swapping is not initialized");
	    
		require(IERC20(AxiatokenB).balanceOf(msg.sender) >= _amount, "Insufficient AxiatokenB balance");
		require(IERC20(AxiatokenB).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance given to contract yet to spend by user");
		
		require(IERC20(AxiatokenC).balanceOf(address(this)) >= _amount, "Pool is deficient of enough tokens to execute the swap");
		
		totalswappedin += _amount;
		
		IERC20(AxiatokenB).transferFrom(msg.sender, address(this), _amount); 
		require(IERC20(AxiatokenC).transfer(msg.sender, _amount), "Transaction failed");
		
        emit SwappedInEvent(msg.sender, address(this), _amount);
	}
	
 
	function _swapOut(uint256 _amount) internal {
	    
	    require(swapEnabled, "Swapping is not initialized");
	    
		require(IERC20(AxiatokenC).balanceOf(msg.sender) >= _amount, "Insufficient AxiatokenB balance");
		require(IERC20(AxiatokenC).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance given to contract yet to spend by user");
		
		require(IERC20(AxiatokenB).balanceOf(address(this)) >= _amount, "Pool is deficient of enough tokens to execute the swap");
		
		totalswappedout += _amount;
		
		IERC20(AxiatokenC).transferFrom(msg.sender, address(this), _amount); 
		require(IERC20(AxiatokenB).transfer(msg.sender, _amount), "Transaction failed");
		
        emit SwappedOutEvent(msg.sender, address(this), _amount);
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