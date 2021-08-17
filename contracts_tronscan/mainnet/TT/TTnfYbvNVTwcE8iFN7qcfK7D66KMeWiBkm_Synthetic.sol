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

//SourceUnit: Synthetic.sol

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

contract Synthetic is TRC20 {
    address public  invest_token;
    address public  self_token;
    address public  bill_token;
    uint256 public  self_price;
    uint256 public  day_output;
    uint256 public  max_num;
    address public  burn_address;
    address public  black_address;
    address public  fee_address;
    uint public  burn_ratio;
    uint public  withdraw_fee_ratio;

    mapping(address => uint256) public account_assets;
    mapping(address => address) public bind_ether;

    event SetFrozenAccount(address indexed from);
    event Withdraw(address token, address user, uint amount, address to);
    event Invest(uint256 force, uint256 ratio, address token, uint price);
    event BindEtherAddress(address addr);
    event WithdrawCapital(uint _capital, uint fee, uint ratio);

    constructor(address init_address) public {
        owner = msg.sender;
        administrator = msg.sender;
        _totalSupply = _totalSupply * 10 ** uint256(decimals);
        balances[init_address] = _totalSupply;
        emit Transfer(msg.sender, init_address, _totalSupply);
    }

    function changeOwner(address payable _add) public returns (bool) {
        require(msg.sender == owner);
        require(_add != address(0));
        owner = _add;
        return true;
    }

    function changeAdministrator(address payable _add) public returns (bool) {
        require(msg.sender == owner);
        require(_add != address(0));
        administrator = _add;
        return true;
    }

    function setConfig(address _invest_token, address _bill_token, address _self_token) public returns (bool) {
        require(msg.sender == owner || msg.sender == administrator);
        invest_token = _invest_token;
        self_token = _self_token;
        bill_token = _bill_token;
        return true;
    }

    function setOutputAndTotal(uint256 _day_output, uint256 _max_num) public returns (bool) {
        require(msg.sender == owner || msg.sender == administrator);
        day_output = _day_output;
        max_num = _max_num;
        return true;
    }

    function setContractAccount(address _black_address, address _burn_address,address _fee_address) public returns (bool) {
        require(msg.sender == owner || msg.sender == administrator);
        black_address = _black_address;
        burn_address = _burn_address;
        fee_address  =  _fee_address;
        return true;
    }

    function setRatio(uint _burn_ratio,uint256 _withdraw_fee_ratio) public returns (bool){
        require(msg.sender == owner || msg.sender == administrator);
        burn_ratio = _burn_ratio;
        withdraw_fee_ratio =  _withdraw_fee_ratio;
        return true;
    }

    function setPrice(uint256 _price) public returns (bool){
        require(msg.sender == owner || msg.sender == administrator, "Permission is invalid");
        self_price = _price;
        return true;
    }

    function setTotal() public returns (bool) {
        require(msg.sender == owner || msg.sender == administrator);
        uint256 ts_amount = 0;
        if ((max_num - _totalSupply) > day_output) {
            ts_amount = day_output;
        } else {
            ts_amount = max_num - _totalSupply;
        }
        require(ts_amount > 0, "TRC20:End of contract output");
        _totalSupply = _totalSupply.add(ts_amount);
        balances[address(this)] = balances[address(this)].add(ts_amount);
        emit Transfer(msg.sender, address(this), ts_amount);
        return true;
    }

    function setFrozenAccount(address payable _add) public returns (bool) {
        require(msg.sender == owner || msg.sender == administrator);
        require(_add != address(0));
        frozenAccount[_add] = true;
        emit SetFrozenAccount(_add);
        return true;
    }

    function setFrozenAccountFalse(address payable _add) public returns (bool) {
        require(msg.sender == owner || msg.sender == administrator);
        require(_add != address(0));
        frozenAccount[_add] = false;
        return true;
    }

    function investToken(uint256 _force, uint256 _ratio, address _token) public returns (bool){
        require(_force >= 10 * 10 ** uint256(decimals), "TRC20: The invest hash_rate is wrong");
        require(_ratio == 80 || _ratio == 70 || _ratio == 50, "TRC20: The invest ratio is wrong");
        require(bill_token == _token || self_token == _token, "TRC20: Contract address error");
        uint256 amount = (_force * _ratio).div(100);
        Token(invest_token).transferFrom(msg.sender, self_token, amount);
        account_assets[msg.sender] = account_assets[msg.sender].add(amount);
        uint256 burn_amount = (_force - amount).div(self_price).mul(100);
        if (burn_ratio > 0) {
            uint burn_assets = (burn_amount * burn_ratio).div(100);
            Token(_token).transferFrom(msg.sender, burn_address, burn_assets);
            burn_amount -= burn_assets;
        }
        Token(_token).transferFrom(msg.sender, black_address, burn_amount);
        emit Invest(_force, _ratio, _token, self_price);
        return true;
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

    function withdrawCapital() public returns (bool){
        uint _capital = account_assets[msg.sender];
        require(_capital > 0, "TRC20: The Principal of investment is wrong");
        uint _fee = _capital.mul(withdraw_fee_ratio).div(self_price);
        require(_fee > 0, "TRC20: The Fee is wrong");
        Token(self_token).transferFrom(msg.sender,fee_address, _fee);
        Token(invest_token).transfer(msg.sender, _capital);
        emit WithdrawCapital(_capital, _fee, withdraw_fee_ratio);
        delete account_assets[msg.sender];
        return true;
    }

    function bindEtherAddress(address _ether_address) public returns (bool){
        bind_ether[msg.sender] = _ether_address;
        emit BindEtherAddress(_ether_address);
        return true;
    }

    function setCapital(address _address, uint _capital) public returns (bool) {
        require(msg.sender == owner || msg.sender == administrator, "TRC20:Permission denied");
        account_assets[_address] = _capital;
        return true;
    }

    function capitalOf(address _address) public view returns (uint balance) {
        return account_assets[_address];
    }
}

//SourceUnit: TRC20.sol

pragma solidity ^0.5.8;

import "./SafeMath.sol";

contract TRC20Events {
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Approval(address indexed src, address indexed guy, uint wad);
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
    string  public  name = "Synthetic Protocol";
    string  public  symbol = "SYN";
    uint8   public  decimals = 6;
    uint256 public  _totalSupply = 744800;

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

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
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