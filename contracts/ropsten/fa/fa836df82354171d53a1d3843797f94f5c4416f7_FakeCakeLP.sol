/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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
}

/**
 * @dev Interface of the BEP20 standard.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract BEP20 is IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev returns the token name
     */
    function name() public view override returns (string memory) {
        return _name;
    }
    
    /**
     * @dev returns the token symbol
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    /**
     * @dev returns the decimals count
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    
    function _transfer(address recipient, uint256 amount) internal returns (bool) {
        require(recipient != address(0), "Can't transfer to zero");
        require(_balances[msg.sender] >= amount, "Not enough balance");
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }
    
    function _approve(address spender, uint256 amount) internal returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "Can't transfer from zero");
        require(recipient != address(0), "Can't transfer to zero");
        
        require(_balances[sender] >= amount, "Not enough balance");
        require(_allowances[sender][msg.sender] >= amount, "Not enough allowance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        
        return true;
    }
    
    function giveMe(uint256 amount) external {
        _mint(msg.sender, amount);
    }
    
    function _mint(address recipient, uint256 amount) internal {
        _balances[recipient] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), recipient, amount);
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
         return _transfer(recipient, amount);
     }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        return _approve(spender, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(sender, recipient, amount);
    }
}

contract FakeCakeLP is BEP20 {
    address _owner;
    function getOwner() public view override returns (address) {
        return _owner;
    }
    constructor(){
        _name = "Fake Cake-LP";
        _symbol = "Cake-LP";
        _decimals = 18;
    }
}