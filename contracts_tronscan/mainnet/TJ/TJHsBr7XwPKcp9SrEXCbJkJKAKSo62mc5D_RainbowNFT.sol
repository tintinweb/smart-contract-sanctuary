//SourceUnit: RNFT.sol

pragma solidity ^0.5.8;

import "./TRC20.sol";

contract Token {
    function approve(address _spender, uint256 _value) public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    function transfer(address _to, uint256 _value) public returns (bool success){}
    function balanceOf(address _owner) public view returns (uint256 balance) {}
    function totalSupply() public view returns (uint theTotalSupply){}
    function allowance(address _owner, address _spender) public view returns (uint remaining){}
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RainbowNFT is TRC20 {
    address public  token_burn;
    uint256 public  day_output;
    uint256 public  max_num;
    address public  burn_address;
    uint public  burn_ratio;
    uint public  withdraw_fee_ratio;
    address payable public  fee_address;

    struct InvestAmount {
        address token;
        uint amount;
    }

    mapping(address => InvestAmount) public invests;
    mapping(address => uint) public tokenPrices;

    event SetFrozenAccount(address indexed from);
    event Withdraw(address token, address user, uint amount, address to);
    event Invest(uint force, uint ratio, address token, uint price);
    event WithdrawCapital(uint _capital, uint fee, uint ratio,address token);

    constructor(
        address init_address
    ) public {
        owner = msg.sender;
        administrator = msg.sender;
        _totalSupply = _totalSupply * 10 ** uint256(decimals);
        balances[init_address] = _totalSupply;
        emit Transfer(msg.sender, init_address, _totalSupply);
    }

    function changeOwner(address payable _add) public returns (bool success) {
        require(msg.sender == owner);
        require(_add != address(0));
        owner = _add;
        return true;
    }

    function changeAdministrator(address payable _add) public returns (bool success) {
        require(msg.sender == owner);
        require(_add != address(0));
        administrator = _add;
        return true;
    }

    function setFrozenAccount(address payable _add) public returns (bool success) {
        require(msg.sender == owner || msg.sender == administrator);
        require(_add != address(0));
        frozenAccount[_add] = true;
        emit SetFrozenAccount(_add);
        return true;
    }

    function setFrozenAccountFalse(address payable _add) public returns (bool success) {
        require(msg.sender == owner || msg.sender == administrator);
        require(_add != address(0));
        frozenAccount[_add] = false;
        return true;
    }


    function setBurn(address _token_burn, address _burn_address,address payable _fee_address) public returns (bool success) {
        require(msg.sender == owner || msg.sender == administrator);
        token_burn = _token_burn;
        burn_address = _burn_address;
        fee_address  =  _fee_address;
        return true;
    }


    function AddTokenPrices(address _token, uint _price) public returns (bool){
        require(msg.sender == owner || msg.sender == administrator);
        tokenPrices[_token] = _price;
        return true;
    }

    function deleteTokenPrices(address _token) public returns (bool) {
        require(msg.sender == owner || msg.sender == administrator);
        delete tokenPrices[_token];
        return true;
    }

    function setOutputAndTotal(uint256 _day_output, uint256 _max_num) public returns (bool){
        require(msg.sender == owner || msg.sender == administrator);
        day_output = _day_output;
        max_num = _max_num;
        return true;
    }

    function setRatio(uint _burn_ratio,uint256 _withdraw_fee_ratio) public returns (bool){
        require(msg.sender == owner || msg.sender == administrator);
        burn_ratio = _burn_ratio;
        withdraw_fee_ratio =  _withdraw_fee_ratio;
        return true;
    }

    function DayOutput() public returns (bool success) {
        require(msg.sender == owner || msg.sender == administrator);
        uint256 ts_amount = 0;
        if ((max_num - _totalSupply) > day_output) {
            ts_amount = day_output;
        } else {
            ts_amount = max_num - _totalSupply;
        }
        require(ts_amount > 0, "End of contract output");
        _totalSupply = _totalSupply.add(ts_amount);
        balances[address(this)] = balances[address(this)].add(ts_amount);
        emit Transfer(msg.sender, address(this), ts_amount);
        return true;
    }

    function invest(uint256 _force, uint256 _ratio, address _token) public returns (bool){
        require(_force >= 10 * 10 ** uint(decimals), "TRC20: The invest hash_rate is wrong");
        require(_ratio == burn_ratio, "TRC20: The invest ratio is wrong");
        require(tokenPrices[_token] != 0, "TRC20: Contract address error");
        uint invest_amount = _force.mul(100 - _ratio).div(tokenPrices[_token]);
        require(invest_amount > 0, "TRC20: The invset_amount is wrong");
        Token(_token).transferFrom(msg.sender, address(this), invest_amount);
        invests[msg.sender] = InvestAmount(_token,invest_amount);
        Token(token_burn).transferFrom(msg.sender, burn_address, _force.mul(_ratio).div(100));
        emit Invest(_force, _ratio, _token, tokenPrices[_token]);
        return true;
    }

    function withdrawCapital()  public  returns (bool){
        uint _capital = invests[msg.sender].amount;
        require(_capital > 0, "TRC20: The Principal of investment is wrong");
        uint _fee = _capital.mul(withdraw_fee_ratio).mul(tokenPrices[invests[msg.sender].token]).div(10000);
        require(_fee > 0, "TRC20: The Fee is wrong");
        Token(token_burn).transferFrom(msg.sender,fee_address, _fee);
        Token(invests[msg.sender].token).transfer(msg.sender, _capital);
        emit WithdrawCapital(_capital, _fee, withdraw_fee_ratio,invests[msg.sender].token);
        delete invests[msg.sender];
        return true;
    }

    function setCapital(address _address,address _token, uint _capital) public returns (bool) {
        require(msg.sender == owner || msg.sender == administrator, "TRC20:Permission denied");
        invests[_address] = InvestAmount(_token,_capital);
        return true;
    }

    function capitalOf(address _address) public view returns (address token, uint invest_amount) {
        token = invests[_address].token;
        invest_amount = invests[_address].amount;
    }

    function withdrawToken(address _token, address _add, uint256 _amount) public returns (bool){
        require(msg.sender == owner || msg.sender == administrator);
        Token(_token).transfer(_add, _amount);
        emit Withdraw(_token, msg.sender, _amount, _add);
        return true;
    }

    function withdraw(address payable _add, uint256 _amount) public returns (bool){
        require(msg.sender == owner || msg.sender == administrator);
        require(_add.send(_amount));
        emit Withdraw(owner, msg.sender, _amount, _add);
        return true;
    }

}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;

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

//SourceUnit: TRC20.sol

pragma solidity ^0.5.8;

import "./SafeMath.sol";

contract TRC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract TRC20Basic is TRC20Events {
    function totalSupply() public view returns (uint theTotalSupply){}
    function balanceOf(address _owner) public view returns (uint balance){}
    function transfer(address _to, uint _value) public returns (bool success){}
    function transferFrom(address _from, address _to, uint _value) public returns (bool success){}
    function approve(address _spender, uint _value) public returns (bool success){}
    function allowance(address _owner, address _spender) public view returns (uint remaining){}
}

contract TRC20 is TRC20Basic {
    using SafeMath for uint;
    address payable public  owner;
    address payable public  administrator;
    string  public  name = "RainbowNFT";
    string  public  symbol = "RNFT";
    uint8   public  decimals = 6;
    uint256 public  _totalSupply = 21000;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) public frozenAccount;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(!frozenAccount[msg.sender] && !frozenAccount[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(!frozenAccount[_from] && !frozenAccount[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}