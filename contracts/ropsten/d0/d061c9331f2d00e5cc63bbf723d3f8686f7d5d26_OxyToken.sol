/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
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

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

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

contract OxyToken is IERC20 {
    
    using SafeMath for uint256;
    
    string public _name;                    //'Oxy Token';
    string public _symbol;                  //'OXY';
    uint256 public _totalSupply;
    uint256 public _decimals;               //18;    
    address public admin;   
    mapping(address => uint256) public _balanceOf;    
    mapping(address => mapping(address => uint256)) public _allowance;    
    constructor(string memory _Tname, string memory _Tsymbol, uint256 _TtotalSupply, uint256 _Tdecimals) {
        _name = _Tname;
        _symbol = _Tsymbol;
        _totalSupply = _TtotalSupply;
        _decimals = _Tdecimals;
        _balanceOf[msg.sender] = _TtotalSupply;        admin = msg.sender;        
        emit Transfer(address(0), msg.sender, _TtotalSupply);    // Minting amount from the network
    }    function name() public view returns (string memory) {
        return _name;
    }    function symbol() public view returns (string memory) {
        return _symbol;
    }    function decimals() public view returns (uint256) {
        return _decimals;
    }    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }    function balanceOf(address account) override external view returns (uint256) {
        return _balanceOf[account];
    }    
    
    
    function transfer(address _to, uint256 _value) override public returns(bool success) {
        
        require(_to != address(0), "Invalid address");       
        require(_value > 0, "Invalid amount");    
        require(_balanceOf[msg.sender] >= _value, "Insufficient balance");        
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);       
        emit Transfer(msg.sender, _to, _value);     
        return true;
    }    
    
    
    
    
    
    
    function approve(address _spender, uint256 _value) override public returns (bool success) {
        
        
        
        
        
        
        require(_spender != address(0), "Invalid address");        require(_value > 0, "Invalid amount");        require(_balanceOf[msg.sender] >= _value, "Owner doesn't have enough balance to approve");        _allowance[msg.sender][_spender] = _value;        emit Approval(msg.sender, _spender, _value);        return true;
    }    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return _allowance[_owner][_spender];
    }    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(_from != address(0), "Invalid address");        require(_to != address(0), "Invalid address");        require(_value > 0, "Invalid amount");        require(_allowance[_from][msg.sender] >= _value, "You don't have the approval to spend this amount of tokens");        require(_balanceOf[_from] >= _value, "From address doesn't have enough balance to transfer");        _balanceOf[_from] -= _value;
        _balanceOf[_to] += _value;        _allowance[_from][msg.sender] -= _value;        emit Transfer(_from, _to, _value);        return true;
    }    function mint(address to, uint256 value) public {
        require(msg.sender == admin, "Only creator of the contract can mint tokens");        require(value > 0, "Invalid amount to mint");        _totalSupply += value;
        _balanceOf[to] += value;        emit Transfer(address(0), to, value);
    }    function burn(address to, uint256 value) public {
        require(msg.sender == admin, "Only creator of the contract can burn tokens");        require(value > 0, "Invalid amount to burn");        require(_totalSupply > 0, "Total Supply should be greater than 0");        require(value <= _totalSupply, "Value cannot be greater than total supply of tokens");        require(_balanceOf[to] >= value, "Not enough balance to burn");        _totalSupply -= value;
        _balanceOf[to] -= value;        emit Transfer(to, address(0), value);
    }
}