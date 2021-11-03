//SourceUnit: toc.sol

pragma solidity ^0.5.17;


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

contract TOC {
    using SafeMath for uint256;
    
    string public constant name = "technical - operation - community";
    string public constant symbol = "TOC";
    uint256 public constant decimals = 18;
    uint256 public constant totalSupply = 2100000*10**decimals;
    uint256 public startTime = 1623772800;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    
    address private _blackAddress = address(0);
    address private _feeAddress = address(0x41f239348463938c6ba4cf3db2ac773217f3f8e57c);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor(address _moveAddr) public {
      require(_moveAddr != address(0), "_moveAddress is a zero address");
      balances[_moveAddr] = totalSupply;
      emit Transfer(address(0), _moveAddr, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256) {
      return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
      require((balances[msg.sender] >= _value), "not enough balance !");
      (uint256 _amount,uint256 _fee) = getVFee(_value);
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_amount);
      balances[_blackAddress] = balances[_blackAddress].add(_fee);
      balances[_feeAddress] = balances[_feeAddress].add(_fee);
      emit Transfer(msg.sender, _to, _amount);
      emit Transfer(msg.sender,_blackAddress,_fee);
      emit Transfer(msg.sender,_feeAddress,_fee);
      return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "not enough allowed balance");
      (uint256 _amount,uint256 _fee) = getVFee(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_amount);
      balances[_blackAddress] = balances[_blackAddress].add(_fee);
      balances[_feeAddress] = balances[_feeAddress].add(_fee);
      emit Transfer(_from, _to, _amount);
      emit Transfer(_from,_blackAddress,_fee);
      emit Transfer(_from,_feeAddress,_fee);
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
    
    function batchTransfer(address payable[] memory _users, uint256[] memory _amounts) public returns (bool){
        require(_users.length == _amounts.length,"not same length");
        for(uint256 i = 0; i < _users.length; i++){
            transfer(_users[i], _amounts[i]);
        }
        return true;
    }
    
    function getFee() public view returns(uint256){
        uint256 timeNow = block.timestamp;
        uint256 first = 62 days;
        uint256 timeGo = timeNow.sub(startTime);
        if (timeGo < first){
            return 1e18;
        }
        timeGo = timeGo.sub(first);
        uint256 timeLength = 163 days;
        uint256 lengthNumber = timeGo.div(timeLength).add(1);
        return uint256(1e18).div(2**lengthNumber);
    }
    
    function getVFee(uint256 _value) public view returns(uint256,uint256){
        uint256 fee = getFee();
        require(_value >= fee,"value to low");
        return(_value.sub(fee),fee.div(2));
    }
  }