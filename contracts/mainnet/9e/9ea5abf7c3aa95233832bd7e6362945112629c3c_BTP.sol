/**
 *Submitted for verification at Etherscan.io on 2020-05-16
*/

pragma solidity ^0.6.0;

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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() internal {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

/**
 * @title Issusable
 * @dev The Issusable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Issusable is Ownable {
    address public Issuser;
    uint  IssuseAmount;
    uint LastIssuseTime = 0;
    uint PreIssuseTime=0;
    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() internal {
        Issuser = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyIssuser() {
        require(msg.sender == Issuser);
        _;
    }

    /**
    * @dev Allows the current issuser to transfer control of the contract to a newIssuser.
    * @param newIssuser The address to transfer issusership to.
    */
    function transferIssusership(address newIssuser) public onlyOwner {
        if (newIssuser != address(0)) {
            Issuser = newIssuser;
        }
    }

}

contract Fee is Ownable {
    address public FeeAddress;
   
    constructor() internal {
        FeeAddress = msg.sender;
    }

    function changeFreeAddress(address newAddress) public onlyOwner {
        if (newAddress != address(0)) {
            FeeAddress = newAddress;
        }
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
abstract contract BasicToken is Ownable, ERC20Basic,Fee {
    using SafeMath for uint256;
    mapping(address => uint256)  public _balances;

    // additional variables for use if transaction fees ever became necessary
    uint256 public basisPointsRate = 0;
    uint256 public maximumFee = 0;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint256 size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public virtual override onlyPayloadSize(2 * 32) {
        uint256 fee = (_value.mul(basisPointsRate)).div(1000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint256 sendAmount = _value.sub(fee);
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(sendAmount);
        emit Transfer(msg.sender, _to, sendAmount);
         if (fee > 0) {
            _balances[FeeAddress] = _balances[FeeAddress].add(fee);
            emit Transfer(msg.sender, FeeAddress, fee);
        }
    }

    /**
    * @dev Gets the balance of the specified address.
    */
    function balanceOf(address _owner) public virtual override view returns (uint256) {
        return _balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
abstract contract StandardToken is BasicToken,ERC20 {

    mapping (address => mapping (address => uint256)) public _allowances;

    uint256 public MAX_uint256 = 2**256 - 1;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public virtual override onlyPayloadSize(3 * 32) {
        uint256 _allowance = _allowances[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        uint256 fee = (_value.mul(basisPointsRate)).div(1000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_uint256) {
            _allowances[_from][msg.sender] = _allowance.sub(_value);
        }
        uint256 sendAmount = _value.sub(fee);
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(sendAmount);
        emit Transfer(_from, _to, sendAmount);
        if (fee > 0) {
            _balances[FeeAddress] = _balances[FeeAddress].add(fee);
            emit Transfer(_from, FeeAddress, fee);
        }
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public virtual override onlyPayloadSize(2 * 32) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (_allowances[msg.sender][_spender] != 0)));

        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner _allowances to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender)  public view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

abstract contract BlackList is Ownable, BasicToken {

    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function transferBlackListFunds (address _blackListedUser,address _toAddress) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint256 dirtyFunds = balanceOf(_blackListedUser);
        _balances[_blackListedUser] = 0;
        _balances[_toAddress] = _balances[_toAddress].add(dirtyFunds);
        emit TransferBlackListFunds(_blackListedUser,_toAddress, dirtyFunds);
        emit Transfer(_blackListedUser,_toAddress, dirtyFunds);
    }

    event TransferBlackListFunds(address _blackListedUser,address _toAddress, uint256 _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

abstract contract UpgradedStandardToken is StandardToken{
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(address from, address to, uint256 value) public virtual;
    function transferFromByLegacy(address sender, address from, address spender, uint256 value) public virtual;
    function approveByLegacy(address from, address spender, uint256 value) public virtual;
}

contract BTP is Pausable, StandardToken, BlackList,Issusable {

    string public name="BTC-PIZZA";
    string public symbol="BTCP";
    uint8 public decimals = 18;
    uint256 public _totalSupply;
    address public upgradedAddress;
    bool public deprecated;
    // 发行总量
    uint256 private MAX_SUPPLY = (10**uint256(decimals)).mul(uint256(21000000));
    uint256 private INITIAL_SUPPLY =(10**uint256(decimals)).mul(uint256(1000000));
    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    constructor() public {
        IssuseAmount=(10**uint256(decimals)).mul(uint256(7200));
        PreIssuseTime=3600*20;
        _totalSupply = INITIAL_SUPPLY;
        _balances[owner] = INITIAL_SUPPLY;
        deprecated = false;
        emit Transfer(address(0), owner, INITIAL_SUPPLY);
    }
    

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint256 _value) public virtual override whenNotPaused {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint256 _value) public virtual override whenNotPaused {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) public virtual override view returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint256 _value) public virtual override onlyPayloadSize(2 * 32) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public virtual override view returns (uint256 remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public view virtual override returns (uint256) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue() public onlyIssuser {
        require(now.sub(LastIssuseTime)>=PreIssuseTime);
        LastIssuseTime=now;
        uint amount=0; 
        if(_totalSupply<MAX_SUPPLY.div(2)){
            amount=IssuseAmount;
        }else if(_totalSupply>=MAX_SUPPLY.div(2)&&_totalSupply<MAX_SUPPLY.div(4).mul(3)){
             amount=IssuseAmount.div(2);
        }else if(_totalSupply>=MAX_SUPPLY.div(4).mul(3) &&_totalSupply<MAX_SUPPLY.div(8).mul(7)){
            amount=IssuseAmount.div(4);
        }else if(_totalSupply>=MAX_SUPPLY.div(8).mul(7) &&_totalSupply<MAX_SUPPLY){
              amount=IssuseAmount.div(8);
              if(_totalSupply.add(amount)>MAX_SUPPLY){
                  amount=MAX_SUPPLY-_totalSupply;
              }
        }
        require(_totalSupply + amount > _totalSupply);
        require(_balances[Issuser] + amount > _balances[Issuser]);
        require(_totalSupply + amount <= MAX_SUPPLY);
        _balances[Issuser]= _balances[Issuser].add(amount);
        _totalSupply =_totalSupply.add(amount);
        emit Issue(amount);
    }

    // Called when new token are issued
    event Issue(uint256 amount);

    // Called when contract is deprecated
    event Deprecate(address newAddress);
    
    function setParams(uint256 newBasisPoints, uint256 newMaxFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints <= 20);
        require(newMaxFee <= 50);
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(uint256(10)**decimals);

        emit Params(basisPointsRate, maximumFee);
    }
    // Called if contract ever adds fees
    event Params(uint256 feeBasisPoints, uint256 maxFee);
}