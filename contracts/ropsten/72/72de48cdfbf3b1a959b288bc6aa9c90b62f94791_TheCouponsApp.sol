/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

pragma solidity ^0.4.24;

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

contract TheCouponsApp {
 
    using SafeMath for uint256;

    string public name = "The Coupons App";
    string public symbol = "COUPONS";
    uint8 public decimals = 0;
    uint256 public totalSupply_ = 100000000000;
    uint256 totalDividendPoints = 0;
    uint256 unclaimedDividends = 0;
    uint256 pointMultiplier = 1000000000000000000;
    address owner;

    
    struct account{
         uint256 balance;
         uint256 lastDividendPoints;
     }

    mapping(address => account) public balanceOf;
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );


    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
    );

    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }

    modifier updateDividend(address investor) {
    uint256 owing = dividendsOwing(investor);
    if(owing > 0) {
        unclaimedDividends = unclaimedDividends.sub(owing);
        balanceOf[investor].balance = balanceOf[investor].balance.add(owing);
        balanceOf[investor].lastDividendPoints = totalDividendPoints;
        }
     _;
    }

    constructor () public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender].balance = totalSupply_;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    
    /**
     new dividend = totalDividendPoints - investor's lastDividnedPoint
     ( balance * new dividend ) / points multiplier
    
    **/
    function dividendsOwing(address investor) internal returns(uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(balanceOf[investor].lastDividendPoints);
        return (balanceOf[investor].balance.mul(newDividendPoints)).div(pointMultiplier);
    }

    /**
    
    totalDividendPoints += (amount * pointMultiplier ) / totalSupply_
    **/
    function disburse(uint256 amount)  onlyOwner public{
    totalDividendPoints = totalDividendPoints.add((amount.mul(pointMultiplier)).div(totalSupply_));
    totalSupply_ = totalSupply_.add(amount);
    unclaimedDividends =  unclaimedDividends.add(amount);
    }

    function totalSupply_() public view returns (uint256) {
    return totalSupply_;
    }

   function transfer(address _to, uint256 _value) updateDividend(msg.sender) updateDividend(_to) public returns (bool) {
    require(msg.sender != _to);
    require(_to != address(0));
    require(_value <= balanceOf[msg.sender].balance);
    balanceOf[msg.sender].balance = (balanceOf[msg.sender].balance).sub(_value);
    balanceOf[_to].balance = (balanceOf[_to].balance).add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

 
  function balanceOf(address _owner) public view returns (uint256) {
    return balanceOf[_owner].balance;
  }


   mapping (address => mapping (address => account)) internal allowed;


 
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    updateDividend(_from)
    updateDividend(_to)
    public
    returns (bool)
  {
    require(_to != _from);
    require(_to != address(0));
    require(_value <= balanceOf[_from].balance);
    require(_value <= (allowed[_from][msg.sender]).balance);

    balanceOf[_from].balance = (balanceOf[_from].balance).sub(_value);
    balanceOf[_to].balance = (balanceOf[_to].balance).add(_value);
    (allowed[_from][msg.sender]).balance = (allowed[_from][msg.sender]).balance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    (allowed[msg.sender][_spender]).balance = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return (allowed[_owner][_spender]).balance;
  }

 
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    (allowed[msg.sender][_spender]).balance = (
      (allowed[msg.sender][_spender]).balance.add(_addedValue));
    emit Approval(msg.sender, _spender, (allowed[msg.sender][_spender]).balance);
    return true;
  }

  
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = (allowed[msg.sender][_spender]).balance;
    if (_subtractedValue > oldValue) {
      (allowed[msg.sender][_spender]).balance = 0;
    } else {
      (allowed[msg.sender][_spender]).balance = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, (allowed[msg.sender][_spender]).balance);
    return true;
  }
}