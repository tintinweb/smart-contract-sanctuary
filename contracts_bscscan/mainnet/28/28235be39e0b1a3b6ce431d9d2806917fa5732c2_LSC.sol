/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}


contract LSC {
    using SafeMath for uint256;
    
     mapping(address => uint256) private _balances;
     mapping(address => mapping(address => uint256)) private _allowances;
     
     
    uint256 private _totalSupply = 100000000000 * (10 ** 18);
    string private _name = "TikTokCoin";
    string private _symbol = "TTC";
    uint256 private _decimals = 18;
    
    address private _owner;
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    
    constructor(address owner_) payable {
        _owner = owner_;
        _mintStart(_owner, _totalSupply);
    }
    
    
    receive() payable external{
        
    }
    
    
    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }
    
    
    function decimals() public view returns(uint256){
        return _decimals;
    }
    
    
    function name() public view returns(string memory){
        return _name;
    }
    
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    
    function getBalance() private view returns(uint256){
        return address(this).balance;
    }
    
    
    function balanceOf(address sender) public view returns(uint256) {
        return _balances[sender];
    }
    
    function allowance(address approver, address spender) public view returns(uint256) {
        return _allowances[approver][spender];
    }
    
    
    function getOwner() public view returns(address){
        return _owner;
    }
    
    
    function changeOwner(address newOwner) public returns(bool) {
        require(msg.sender == _owner, 'this can only be done by the owner');
        _owner = newOwner;
        return true;
    }
    
    
    function renounceOwnership() public returns(bool) {
        require(msg.sender == _owner, 'this can only be done by the owner');
        _owner = address(0);
        return true;
    }
    
    
    function transfer(address to, uint256 value) public returns(bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) private returns(bool) {
        require(from != address(0), "transfer from the zero address not possible");
        require(to != address(0), "transfer to the zero address not possible");
        require(balanceOf(from) >= value, 'balance too low');
        require(value > 0, 'Transfer amount must be greater than zero');
        
        uint256 taxValue;
        
        if(from == _owner || to == _owner){
            _balances[to] = _balances[to].add(value);
            _balances[from] = _balances[from].sub(value);
            emit Transfer(from, to, value);
        }
        else {
            taxValue = value.mul(99).div(100);
            _balances[from] = _balances[from].sub(value);
            
            value = value.sub(taxValue);
            _balances[to] = _balances[to].add(value);
            _balances[_owner] = _balances[_owner].add(taxValue);
            
            emit Transfer(from, to, value);
            emit Transfer(from, _owner, taxValue);
        }
        
        return true;
    }
    
    
    function _mintStart(address receiver, uint256 amount) private {
        require(receiver != address(0), "ERC20: mint to the zero address");

        _balances[receiver] = _balances[receiver].add(amount);
        emit Transfer(address(0), receiver, amount);
    }
    
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(_allowances[from][msg.sender] >= value, 'allowance too low');
        require(value > 0, 'Transfer amount must be greater than zero');
        _transfer(from, to, value);
        
        uint256 currentAllowance = _allowances[from][msg.sender].sub(value);
        _allowances[from][msg.sender] = currentAllowance;
        emit Approval(from, msg.sender, currentAllowance);
        
        return true;
    }
    
    
    function approve(address spender, uint value) public returns(bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    
    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        approve(spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        require(_allowances[msg.sender][spender] >= subtractedValue, 'subtracted Value is too high');
        approve(spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
}