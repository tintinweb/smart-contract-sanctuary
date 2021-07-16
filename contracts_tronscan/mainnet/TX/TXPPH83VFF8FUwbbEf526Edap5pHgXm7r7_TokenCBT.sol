//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
}

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

//SourceUnit: TokenCBT.sol

pragma solidity ^0.5.8;
import "./SafeMath.sol";

contract TokenCBT {
    using SafeMath for uint256;

    // Public variables of the token
    string public name;
    string public symbol;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // 2020-11-01 00:00:00 UTC epoch
    uint256 private start = 1604016000; 
    uint256 public lastIssueTime = 1604016000;
    uint256 private lastMonth = 1604016000;
    uint256 private oneDay = 1 days;
    uint256 private daysInMonth = 30;
    uint256 public issueIndex = 0;
    uint256 public issueBase;

    address public owner;
    address public rewarder;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    // This notifies ownership transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // This notifies rewarder changed
    event RewarderChanged(address indexed previousRewarder, address indexed newRewarder);


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        address _rewarder
    ) public {
        totalSupply = 10000000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        name = "Online Token";                                   // Set the name for display purposes
        symbol = "OLT";                               // Set the symbol for display purposes

        // initialSupply to rewarder
        issueBase = totalSupply;
        owner = msg.sender;
        rewarder = _rewarder;
        balanceOf[rewarder] = totalSupply;
        emit RewarderChanged(address(0), rewarder);
        emit OwnershipTransferred(address(0), owner);
        emit Transfer(address(0), rewarder, totalSupply);
    }

    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * Change rewarder of the contract to a new account (`newRewarder`).
     * Can only be called by the current owner.
     */
    function changeRewarder(address _newRewarder) public onlyOwner {
        emit RewarderChanged(rewarder, _newRewarder);
        rewarder = _newRewarder;
    }


    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        
        _checkIssue();

        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0));

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, allowance[_from][msg.sender].sub(_value));
        return true;
    }


    /**
        * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
        * Beware that changing an allowance with this method brings the risk that someone may use both the old
        * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
        * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
        * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        * @param spender The address which will spend the funds.
        * @param value The amount of tokens to be spent.
        */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Approve an address to spend another addresses' tokens.
    * @param _owner The address that owns the tokens.
    * @param _spender The address that will spend the tokens.
    * @param _value The number of tokens that can be spent.
    */
    function _approve(address _owner, address _spender, uint256 _value) internal {
        require(_spender != address(0));
        require(_owner != address(0));

        allowance[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /** 
     * Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "CBT: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balanceOf[_account] = balanceOf[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

    /**
     * check whether need issue new token
     * new token issue every day 
     *
     */
    function _checkIssue() internal {
        if (issueIndex >= daysInMonth.mul(123)) {
            return;
        }

        // issue when needed
        if (now > lastIssueTime) {
            lastIssueTime = lastIssueTime.add(oneDay);
            uint256 rate = increaseRate(issueIndex);
            uint256 amount = issueBase.mul(rate).div(100).sub(issueBase).div(daysInMonth);
            _mint(rewarder, amount);
            issueIndex = issueIndex.add(1);
        }

        // change issue base
        if (lastIssueTime.sub(lastMonth) >= oneDay.mul(daysInMonth)) {
            lastMonth = oneDay.mul(daysInMonth).add(lastMonth);
            issueBase = totalSupply;
        }
    }

    /**
     * Get IncreaseRate by month index
     *
     * @param _index the month index, start from 0
     * @return increaseRate 100%
     */
    function increaseRate(uint256 _index) public view returns (uint256 rate) {
        if (_index < daysInMonth.mul(6)) {
            return 110;
        } else if (_index < daysInMonth.mul(18)) {
            return 108;
        } else if (_index < daysInMonth.mul(42)) {
            return 105;
        } else if (_index < daysInMonth.mul(78)) {
            return 103;
        } else if (_index < daysInMonth.mul(123)) {
            return 102;
        } else {
            return 100;
        }
    }
}