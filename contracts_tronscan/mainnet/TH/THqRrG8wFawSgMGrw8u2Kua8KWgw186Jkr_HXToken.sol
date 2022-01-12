//SourceUnit: HXToken.sol

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.6;



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

interface iERC20 {

    function totalSupply()external view returns(uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract HXToken is iERC20{

    using SafeMath for uint;

    mapping (address => uint) internal _balances;
    mapping (address => mapping (address => uint)) internal _allowances;

    string public   name;
    string public  symbol;
    uint public  decimals;
    uint public  totalSupply;

    uint public buyRate = 4;
    uint public sellRate = 8;
    uint public transferRate = 2;

    uint[] buyDistribute = [50,50];
    uint[] sellDistribute = [75,25];
    uint[] transferDistribute = [50,50];

    address public feeReceiver;

    address constant public burnAddress = address(0);

    mapping( address => bool ) public inWhiteList;

    address public _owner;

    address public exchange;

     modifier onlyOwner() {
        require(msg.sender == _owner, "admin: wut?");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint _decimals,
        uint _totalSupply,
        address holder,
        address receiver
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** _decimals;
        feeReceiver = receiver;
        _owner = msg.sender;
        inWhiteList[holder] = true;
        _balances[holder] = totalSupply;
        emit Transfer(address(0),holder, totalSupply);
    }

    function setRate(uint _buy,uint _sell)external onlyOwner{
        require(_buy < 100 && _sell < 100,"param error");
        buyRate = _buy;
        sellRate = _sell;
    }

    function setEx(address ex)external onlyOwner{
        exchange = ex;
    }

    function setWhite(address o,bool isIn)external onlyOwner{
        inWhiteList[o] = isIn;
    }

    function balanceOf(address account) external   view returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) external   returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external  view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint value) external   returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external   returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external   returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external   returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        //require(recipient != address(0), "ERC20: transfer to the zero address");

        uint receiveAmount = amount;

        uint burnAmount = 0;
        uint fundsAmount = 0;

        if( exchange != address(0)){

            if( recipient == exchange && !inWhiteList[sender]){
                uint fee = amount * sellRate / 100;
                receiveAmount -= fee;
                burnAmount = fee * sellDistribute[0] / 100;
                fundsAmount = fee * sellDistribute[1] / 100;
            }

            if( sender == exchange && !inWhiteList[recipient]){
                uint fee = amount * buyRate / 100;
                receiveAmount -= fee;
                burnAmount = fee * buyDistribute[0] / 100;
                fundsAmount = fee * buyDistribute[1] / 100;
            }

            if(
                sender != exchange && recipient != exchange
                && !inWhiteList[sender] && !inWhiteList[recipient] ){

                    uint fee = amount * transferRate / 100;
                    receiveAmount -= fee;
                    burnAmount = fee * transferDistribute[0] / 100;
                    fundsAmount = fee * transferDistribute[1] / 100;
            }
        }

        if( burnAmount > 0 ){
            _balances[burnAddress] = _balances[burnAddress].add(burnAmount);
            emit Transfer(sender, burnAddress, burnAmount);
        }

        if( fundsAmount > 0 ){
            _balances[feeReceiver] = _balances[feeReceiver].add(fundsAmount);
            emit Transfer(sender, feeReceiver, fundsAmount);
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(receiveAmount);

        emit Transfer(sender, recipient, receiveAmount);
    }


    function _approve(address owner, address spender, uint value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}