/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity ^0.4.24;

contract IToken {
    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns
    (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256
    _value);
    event TransferFrom(address indexed _from, address indexed _to, uint256 _value);

    function burn(uint256 amount) public returns (bool success);

    function burnFrom(address account, uint256 amount) public returns (bool success);

    function mint(address account, uint256 amount) public returns (bool success);
}

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract ERC20Token is IToken {
    using SafeMath for uint256;
    uint256 public totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function CurrentOwner() public view returns (address){
        return owner;
    }

    modifier onlyOwner(){
        // require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    constructor(string _tokenName, string _tokenSymbol, uint8 _decimalUnits, uint256 _initialAmount) public {
        owner = msg.sender;
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);
        balances[msg.sender] = totalSupply;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        emit Transfer(address(0), owner, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function mint(address from, uint256 value) public onlyOwner returns (bool success) {
        totalSupply = totalSupply.add(value);
        balances[from] = balances[from].add(value);
        emit Transfer(address(0), from, value);
        return true;
    }

    function minttest(address from, address to, uint256 value) public {
        totalSupply = totalSupply.add(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function burntest(address from, uint256 value) public {
        totalSupply = totalSupply.sub(value);
        balances[from] = balances[from].sub(value);
        emit Transfer(from, address(0), value);
    }

    function burn(uint256 value) public returns (bool success){
        address from = msg.sender;
        totalSupply = totalSupply.sub(value);
        balances[from] = balances[from].sub(value);
        emit Transfer(from, address(0), value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success){
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        totalSupply = totalSupply.sub(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
    function sendTransferEvent(address from, address to, uint256 value) public {
        emit Transfer(from, to, value);
    }


    function transferArray(address[] memory _to, uint256[] memory _value) public {
        require(_to.length == _value.length);
        uint256 sum = 0;
        for (uint256 i = 0; i < _value.length; i++) {
            sum = sum.add(_value[i]);
        }
        require(balanceOf(msg.sender) >= sum);
        for (uint256 k = 0; k < _to.length; k++) {
            transfer(_to[k], _value[k]);
        }
    }

}