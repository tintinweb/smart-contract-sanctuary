/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

/*

* @dev This is the Axia Protocol Distributor contract, 
* a part of the protocol where all emissions gets to,
*it handles the distribution to all the involving pools in the protocol.


*/
pragma solidity 0.6.4;

interface IERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

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

interface OSP {
    
   function scaledToken(uint amount) external returns(bool);
   function totalFrozen() external view returns (uint256);
 }

contract Distributor{
    
    using SafeMath for uint256;
    
//======================================EVENTS=========================================//
    event DistributionEvent(address indexed from, address indexed to, uint amount);
    
    
    
//======================================STAKING POOLS=========================================//
    address public Axiatoken;
    address public admin;
	uint public poolAmount;
	uint public amountToEmitAdmin;
	uint public AdminPercent;
	
	address[] public PoolAddress; 
	uint[] public PoolPercent;
	uint totalFrozenTokens = 10;
    
	
	
	constructor() public {
	    
        admin = msg.sender;
	}

//======================================ADMINSTRATION=========================================//

	modifier onlyCreator() {
        require(msg.sender == admin, "Ownable: caller is not the administrator");
        _;
    }
    
    modifier onlyAxiaToken() {
        require(msg.sender == Axiatoken, "Authorization: only token contract can call");
        _;
    }
    
	 function tokenconfigs(address _axiatoken) public onlyCreator returns (bool success) {
	    require(_axiatoken != address(0), "Insertion of address(0) is not supported");
        Axiatoken = _axiatoken;
        return true;
    }
	

//======================================ACTION CALLS=========================================//	
	
	function AddPools(address _address) public onlyCreator returns(bool){
	    PoolAddress.push(_address);
	}
	
	function AddPoolsPercent(uint _percent) public onlyCreator returns(bool){
	    PoolPercent.push(_percent);
	}
	
	function editpoolAmount(uint _i, uint _percent) public onlyCreator returns(bool){
	 
	 PoolPercent[_i] = _percent;
	 
	}
	
	function editpoolAddress(uint _i, address _address) public onlyCreator returns(bool){
	 
	 PoolAddress[_i] = _address;
	 
	}
	
	function doBothAmountandAddress(uint _i, uint _percent, address _address) public onlyCreator returns(bool){
	    PoolAddress[_i] = _address; 
	    PoolPercent[_i] = _percent;
	    
	}
	
	function doBothAmountandAddress(uint _percent) public onlyCreator returns(bool){
	    AdminPercent = _percent; 
	    
	}
	
	
	function totalFrozen() public view returns (uint256) {
		return totalFrozenTokens;
	}
	
    function scaledToken (uint amountToEmit) external onlyAxiaToken returns(bool){
        
        amountToEmitAdmin = mulDiv(amountToEmit, AdminPercent, 10000);
        amountToEmit = amountToEmit - amountToEmitAdmin;
        
        for(uint i=0; i<PoolAddress.length; i++){
        
        poolAmount = mulDiv(amountToEmit, PoolPercent[i], 10000);
        
        OSP(PoolAddress[i]).scaledToken(poolAmount);    
        
        require(IERC20(Axiatoken).transfer(PoolAddress[i], poolAmount), "Transaction failed");
        emit DistributionEvent(address(this), PoolAddress[i], poolAmount);
        
        
    }
    
    
    
    require(IERC20(Axiatoken).transfer(admin, amountToEmitAdmin), "Transaction failed");
    emit DistributionEvent(address(this), admin, amountToEmitAdmin);
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