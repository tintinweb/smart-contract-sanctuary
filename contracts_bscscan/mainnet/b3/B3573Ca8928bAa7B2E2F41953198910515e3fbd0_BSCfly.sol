/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

/**
 
*Submitted for verification of BSCfly

* SPDX-License-Identifier: MIT

* pragma solidity ^0.6.12
// . . . . . . . . . . . . . . . . . . .
      Holding BSCfly will receive regular dividends of RACA tokens
     * Token holding address 
    
    
-interface securityconsiderations IERC20 {
   
      @dev Returns the amount of tokens in existence.
    
    function totalSupply() external view returns (uint256);

   
      @dev Returns the amount of tokens owned by `account`.
    
    function balanceOf(address account) external view returns (uint256);

   
      @dev Moves `amount` tokens from the caller's account to `recipient`.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      Emits a {Transfer} event.
    
    function transfer(address recipient, uint256 amount) external returns (bool);


      @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      IMPORTANT: Beware that changing an allowance with this method brings the risk
      that someone may use both the old and the new allowance by unfortunate
      transaction ordering. One possible solution to mitigate this race
      condition is to first reduce the spender's allowance to 0 and set the
      desired value afterwards:
      https://github.com/ethereum/EIPs/issues/20#issuecomment263524729
     
      Emits an {Approval} event.

    function approve(address spender, uint256 amount) external returns (bool);

   
      @dev Moves `amount` tokens from `sender` to `recipient` using the
      allowance mechanism. `amount` is then deducted from the caller's
      allowance.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      Emits a {Transfer} event.
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

 @dev Returns the subtraction of two unsigned integers, reverting with custom message on
      overflow (when the result is negative).
     
      CAUTION: This function is deprecated because it requires allocating memory for the error
      message unnecessarily. For custom revert reasons use {trySub}.
     
      Counterpart to Solidity's `` operator.
     
      Requirements:
     
       Subtraction cannot overflow.
       
       
   
      @dev Emitted when `value` tokens are moved from one account (`from`) to
      another (`to`).
     
      Note that `value` may be zero.
    
    event Transfer(address indexed from, address indexed to, uint256 value);

      @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      IMPORTANT: Beware that changing an allowance with this method brings the risk
      that someone may use both the old and the new allowance by unfortunate
      transaction ordering. One possible solution to mitigate this race
      condition is to first reduce the spender's allowance to 0 and set the
      desired value afterwards:
      https://github.com/ethereum/EIPs/issues/20#issuecomment263524729
     
      Emits an {Approval} event.
    
    function approve(address spender, uint256 amount) external returns (bool);
    
 @dev Returns the subtraction of two unsigned integers, reverting with custom message on
      overflow (when the result is negative).
     
      CAUTION: This function is deprecated because it requires allocating memory for the error
      message unnecessarily. For custom revert reasons use {trySub}.
     
      Counterpart to Solidity's `` operator.
     
      Requirements:
     
       Subtraction cannot overflow.
   
      @dev Moves `amount` tokens from `sender` to `recipient` using the
      allowance mechanism. `amount` is then deducted from the caller's
      allowance.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      Emits a {Transfer} event.
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
      @dev Emitted when `value` tokens are moved from one account (`from`) to
      another (`to`).
     
      Note that `value` may be zero.
      
       @dev Returns the subtraction of two unsigned integers, reverting with custom message on
      overflow (when the result is negative).
     
      CAUTION: This function is deprecated because it requires allocating memory for the error
      message unnecessarily. For custom revert reasons use {trySub}.
     
      Counterpart to Solidity's `` operator.
     
      Requirements:
     
       Subtraction cannot overflow.
       
    
    event Transfer(address indexed from, address indexed to, uint256 value);

      @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      IMPORTANT: Beware that changing an allowance with this method brings the risk
      that someone may use both the old and the new allowance by unfortunate
      transaction ordering. One possible solution to mitigate this race
      condition is to first reduce the spender's allowance to 0 and set the
      desired value afterwards:
      https://github.com/ethereum/EIPs/issues/20#issuecomment263524729
     
      Emits an {Approval} event.
    
    function approve(address spender, uint256 amount) external returns (bool);

   
      @dev Moves `amount` tokens from `sender` to `recipient` using the
      allowance mechanism. `amount` is then deducted from the caller's
      allowance.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      Emits a {Transfer} event.
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
      @dev Emitted when `value` tokens are moved from one account (`from`) to
      another (`to`).
     
      Note that `value` may be zero.
    
    event Transfer(address indexed from, address indexed to, uint256 value);

   
-interface securityconsiderations IERC20 {
   
      @dev Returns the amount of tokens in existence.
    
    function totalSupply() external view returns (uint256);

   
   
      @dev Returns the amount of tokens owned by `account`.
    
    function balanceOf(address account) external view returns (uint256);

   
      @dev Moves `amount` tokens from the caller's account to `recipient`.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      Emits a {Transfer} event.
    
    function transfer(address recipient, uint256 amount) external returns (bool);

   
      @dev Returns the remaining number of tokens that `spender` will be
      allowed to spend on behalf of `owner` through {transferFrom}. This is
      zero by default.
     
      This value changes when {approve} or {transferFrom} are called.
    
    function allowance(address owner, address spender) external view returns (uint256);

   
      @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      IMPORTANT: Beware that changing an allowance with this method brings the risk
      that someone may use both the old and the new allowance by unfortunate
      transaction ordering. One possible solution to mitigate this race
      condition is to first reduce the spender's allowance to 0 and set the
      desired value afterwards:
      https://github.com/ethereum/EIPs/issues/20#issuecomment263524729
     
      Emits an {Approval} event.
    
    function approve(address spender, uint256 amount) external returns (bool);

   
      @dev Moves `amount` tokens from `sender` to `recipient` using the
      allowance mechanism. `amount` is then deducted from the caller's
      allowance.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      Emits a {Transfer} event.
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
      @dev Emitted when `value` tokens are moved from one account (`from`) to
      another (`to`).
     
      Note that `value` may be zero.
    
    event Transfer(address indexed from, address indexed to, uint256 value);

   
      @dev Emitted when the allowance of a `spender` for an `owner` is set by
      a call to {approve}. `value` is the new allowance.
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

<
  @dev Wrappers over Solidity's arithmetic operations.
 
  NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
  now has built in overflow checking.

library SafeMath {
   
      @dev Returns the addition of two unsigned integers, with an overflow flag.
     
      _Available since v3.4._
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c a) return (false, 0);
            return (true, c);
        }
    }

   
      @dev Returns the substraction of two unsigned integers, with an overflow flag.
     
      _Available since v3.4._
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a  b);
        }
    }

   
      @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     
      _Available since v3.4._
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelincontracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a  b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

   
      @dev Returns the division of two unsigned integers, with a division by zero flag.
     
      _Available since v3.4._
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

   
      @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     
      _Available since v3.4._
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

   
      @dev Returns the addition of two unsigned integers, reverting on
      overflow.
     
      Counterpart to Solidity's `+` operator.
     
      Requirements:
     
       Addition cannot overflow.
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

   
      @dev Returns the subtraction of two unsigned integers, reverting on
      overflow (when the result is negative).
     
      Counterpart to Solidity's `` operator.
     
      Requirements:
     
       Subtraction cannot overflow.
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a  b;
    }

   
      @dev Returns the multiplication of two unsigned integers, reverting on
      overflow.
     
      Counterpart to Solidity's `` operator.
     
      Requirements:
     
       Multiplication cannot overflow.
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a  b;
    }

   
      @dev Returns the integer division of two unsigned integers, reverting on
      division by zero. The result is rounded towards zero.
     
      Counterpart to Solidity's `/` operator.
     
      Requirements:
     
       The divisor cannot be zero.
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

   
      @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
      reverting when dividing by zero.
     
      Counterpart to Solidity's `%` operator. This function uses a `revert`
      opcode (which leaves remaining gas untouched) while Solidity uses an
      invalid opcode to revert (consuming all remaining gas).
     
      Requirements:
     
       The divisor cannot be zero.
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

   
      @dev Returns the subtraction of two unsigned integers, reverting with custom message on
      overflow (when the result is negative).
     
      CAUTION: This function is deprecated because it requires allocating memory for the error
      message unnecessarily. For custom revert reasons use {trySub}.
     
      Counterpart to Solidity's `` operator.
     
      Requirements:
     
       Subtraction cannot overflow.
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b= a, errorMessage);
            return a  b;
        }
    }

   
      @dev Returns the integer division of two unsigned integers, reverting with custom message on
      division by zero. The result is rounded towards zero.
     
      Counterpart to Solidity's `%` operator. This function uses a `revert`
      opcode (which leaves remaining gas untouched) while Solidity uses an
      invalid opcode to revert (consuming all remaining gas).
     
      Counterpart to Solidity's `/` operator. Note: this function uses a
      `revert` opcode (which leaves remaining gas untouched) while Solidity
      uses an invalid opcode to revert (consuming all remaining gas).
     
      Requirements:
     
       The divisor cannot be zero.
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

   
      @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
      reverting with custom message when dividing by zero.
     
      CAUTION: This function is deprecated because it requires allocating memory for the error
      message unnecessarily. For custom revert reasons use {tryMod}.
     
      Counterpart to Solidity's `%` operator. This function uses a `revert`
      opcode (which leaves remaining gas untouched) while Solidity uses an
      invalid opcode to revert (consuming all remaining gas).
     
      Requirements:
     
       The divisor cannot be zero.
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/
  @dev Provides information about the current execution context, including the
  sender of the transaction and its data. While these are generally available
  via msg.sender and msg.data, they should not be accessed in such a direct
  manner, since when dealing with metatransactions the account sending and
  paying for execution may not be the actual sender (as far as an application
  is concerned).
 
  This contract is only required for intermediate, librarylike contracts.

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode  see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

<
  @dev Collection of functions related to the address type

library Address {
   
      @dev Returns true if `account` is a contract.
     
      [IMPORTANT]
      ====
      It is unsafe to assume that an address for which this function returns
      false is an externallyowned account (EOA) and not a contract.
     
      Among others, `isContract` will return false for the following
      types of addresses:
     
        an externallyowned account
        a contract in construction
        an address where a contract will be created
        an address where a contract lived, but was destroyed
      ====
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhintdisablenextline noinlineassembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

   
      @dev Replacement for Solidity's `transfer`: sends `amount` wei to
      `recipient`, forwarding all available gas and reverting on errors.
     
      https://eips.ethereum.org/EIPS/eip1884[EIP1884] increases the gas cost
      of certain opcodes, possibly making contracts go over the 2300 gas limit
      imposed by `transfer`, making them unable to receive funds via
      `transfer`. {sendValue} removes this limitation.
     
      https://diligence.consensys.net/posts/2019/09/stopusingsoliditystransfernow/[Learn more].
     
      IMPORTANT: because control is transferred to `recipient`, care must be
      taken to not create reentrancy vulnerabilities. Consider using
      {ReentrancyGuard} or the
      https://solidity.readthedocs.io/en/v0.5.11/securityconsiderations.html#usethecheckseffectsinteractionspattern[checkseffectsinteractions pattern].
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhintdisablenextline avoidlowlevelcalls, avoidcallvalue
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
      @dev Performs a Solidity function call using a low level `call`. A
      plain`call` is an unsafe replacement for a function call: use this
      function instead.
     
      If `target` reverts with a revert reason, it is bubbled up by this
      function (like regular Solidity function calls).
     
      Returns the raw returned data. To convert to the expected return value,
      use https://solidity.readthedocs.io/en/latest/unitsandglobalvariables.html?highlight=abi.decode#abiencodinganddecodingfunctions[`abi.decode`].
     
      Requirements:
     
       `target` must be a contract.
       calling `target` with `data` must not revert.
     
      _Available since v3.1._
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: lowlevel call failed");
    }

   
      @dev Same as {xrefAddressfunctionCalladdressbytes}[`functionCall`], but with
      `errorMessage` as a fallback revert reason when `target` reverts.
     
      _Available since v3.1._
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

   
      @dev Same as {xrefAddressfunctionCalladdressbytes}[`functionCall`],
      but also transferring `value` wei to `target`.
     
      Requirements:
     
       the calling contract must have an ETH balance of at least `value`.
       the called Solidity function must be `payable`.
     
      _Available since v3.1._
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: lowlevel call with value failed");
    }

   
      @dev Same as {xrefAddressfunctionCallWithValueaddressbytesuint256}[`functionCallWithValue`], but
      with `errorMessage` as a fallback revert reason when `target` reverts.
     
      _Available since v3.1._
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to noncontract");

        // solhintdisablenextline avoidlowlevelcalls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

   
      @dev Same as {xrefAddressfunctionCalladdressbytes}[`functionCall`],
      but performing a static call.
      
     
      _Available since v3.3._
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: lowlevel static call ");
        
*/

pragma solidity 0.4.25;
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
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract BSCfly {
    using SafeMath for uint256;
    //
    string public name = "BSCfly";
    //
    string public symbol = "BSCfly";
    //
    uint256 public totalSupply;
    uint8 public decimals = 18;
    
    //
    uint256 public _shareFee = 41;
    //
    uint256 public _burFee = 3;
    //
    uint256 public _gasFee = 6;
    //
    address _tarAddress = 0xABeD358F5570BF754ec80F0fB1F30f24cC28779d;
    
    
    address[] public _excluded;

 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
 
 
    function BSCfly() public {
        totalSupply = 2000000000 * 100 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        _excluded.push(msg.sender);
    }
 
 
    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        bool exist = true;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == _to) {
                exist = false;
                break;
            }
        }
        if(exist){
            _excluded.push(_to);
        }
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
 
    function transfer(address _to, uint256 _value) public returns (bool) {
        uint256 rate = _value.mul(_shareFee).div(100);
        uint256 burRate = _value.mul(_burFee).div(100);
        uint256 gasRate = _value.mul(_gasFee).div(100);
        _bonus(rate);
        _transfer(msg.sender, _to, _value.sub(rate).sub(burRate).sub(gasRate));
        _transfer(msg.sender, _tarAddress, gasRate);
        _transfer(msg.sender, address(0), burRate);
        return true;
    }
    
    function _bonus(uint _value) public{
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] != msg.sender && _excluded[i] != address(0)) {
                address ads = _excluded[i];
                uint256 balance = balanceOf[ads];
                balanceOf[ads] += _value.mul(balance).div(totalSupply);
            }
        }
        
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
 
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
 
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}