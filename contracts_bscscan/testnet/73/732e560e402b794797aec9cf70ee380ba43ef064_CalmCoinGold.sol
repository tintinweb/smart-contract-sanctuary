/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.6.2;
// File: openzeppelin-eth\contracts\math\SafeMath.sol
/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }
  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }
  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
// File: zos-lib\contracts\Initializable.sol
pragma solidity ^0.6.2;

contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;
  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;
  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;
    _;
    initializing = wasInitializing;
  }
  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address()) }
    return cs == 0;
  }
  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ____gap;
}
// File: openzeppelin-eth\contracts\ownership\Ownable.sol
pragma solidity ^0.6.2;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
  address  _owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function initialize(address sender) public virtual  initializer {
    _owner = sender;
  }
  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address ) {
    return _owner;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  uint256[50] private ____gap;
}

// File: openzeppelin-eth\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.6.2;
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  function mint(address to, uint256 value) external returns(bool);

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
}

// File: openzeppelin-eth\contracts\token\ERC20\ERC20Detailed.sol

pragma solidity ^0.6.2;

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
 abstract contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string memory ) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string memory ) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ____gap;
}

pragma solidity 0.6.2;
/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}
pragma solidity 0.6.2;
/**
 * @title  ERC20 token
 * @dev This is part of an implementation of the Calm Coin Gold .
 *      CalmCoin Gold  is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      CalmCoinGold balances are internally represented with a hidden denomination, 'gons'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'gons' and the public 'fragments'.
 */
contract CalmCoinGold is ERC20Detailed, Ownable {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of gons that equals 1 fragment.
    //    The inverse rate must not be used--TOTAL_GONS is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert gons to fragments instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Gon balances converted into Fragments are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x Fragments to address 'B'. A's resulting external balance will
    //   be decreased by precisely x Fragments, and B's external balance will be precisely
    //   increased by x Fragments.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);

    
    bool private rebasePausedDeprecated;
    bool private tokenPausedDeprecated;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 50 * 10*6 * 10*DECIMALS;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 public constant MAX_SUPPLY = ~uint256(0);  // (2^128) - 1
    address public ContingencyFund = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;

    
 mapping(address=> uint256) public escrow;
 address admin=0xD59b8EEd06C11e792610e88D2c7fef60692a334B;
    modifier onlyAdmin() {
    require(msg.sender == admin, "onlyAdmin: caller is not the admin");
    _;
  } 


 function escrowTransfer(address to) onlyAdmin public{
     require(escrow[to]>0, "escrow wallet is empty");
     _gonBalances[to] = _gonBalances[to].add(escrow[to]);
     escrow[to] = 0;
  }
 
 
 
 function escrowmint(address to) onlyAdmin public {
    _gonBalances[to] = _gonBalances[to].add(escrow[to]);
    _totalSupply = _totalSupply.add(escrow[to]);
     escrow[to] = 0;
  }
  
  function escrowBurn(address account) onlyAdmin public{
      _gonBalances[account] = _gonBalances[account].sub(escrow[account]);
       _totalSupply = _totalSupply.sub(escrow[account]);
       escrow[account] = 0;
 }
  
 
 
 function mint(address to, uint256 amount)onlyOwner override external returns (bool) {
    _mint(to, amount);
    return true;
  }
// mapping (address => uint256) private _gonBalances;
function _mint(address account, uint256 amount) internal {
    require(account != address(0), " mint to the zero address");
    _gonBalances[account] = _gonBalances[account].add(amount);
    _totalSupply = _totalSupply.add(amount);
    escrow[account] = escrow[account].add(amount);
   
    emit Transfer(address(0), account, amount);
  }
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");
   _gonBalances[account] = _gonBalances[account].sub(amount);
   
    _totalSupply = _totalSupply.sub(amount);
    escrow[account] = escrow[account].add(amount);
    emit Transfer(account, address(0), amount);
  }
  /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
function burn(uint256 amount) public returns (bool) {
  _burn(msg.sender, amount);
   return true;
  }
     /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function _rebase(uint256 epoch, int256 supplyDelta)
        internal
       // onlyMonetaryPolicy
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        // From this point forward, _gonsPerFragment is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _gonsPerFragment
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_GONS - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // _totalSupply = TOTAL_GONS.div(_gonsPerFragment)

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }
    function propertyListing(uint256 propertyValue) onlyOwner public  returns(bool){
uint256 newPropertyValue = (propertyValue *11/10);
        _mint(owner(), newPropertyValue);
        return true;
    }
function propertyBuy(uint256 purchasePercentage, address recipient, address sender,uint256 propertyValue )onlyOwner public returns(bool){
     uint256 toUser= (purchasePercentage * propertyValue * 1/100);
     uint256 toContingencyFund =(purchasePercentage * 1/10 * propertyValue *1/100);
    transfer (recipient, toUser);

    transfer(ContingencyFund, toContingencyFund);
      return true;

}
    uint deployTime = now;
    uint twoYearRebase = block.timestamp;
   // uint sixMonths_of_deployTime = deployTime+183 days ;
    uint sixMonths_of_deployTime = deployTime+120 seconds;
   // uint threeMonths_of_deployTime = deployTime+92 days ;
   uint threeMonths_of_deployTime = deployTime + 240 seconds ;
   // uint eighteenMonths_of_deployTime = deployTime+548 days;
   uint eighteenMonths_of_deployTime = deployTime+ 360 seconds;
   // uint twoYears_of_deployTime = deployTime+730 days ;
    uint twoYears_of_deployTime = deployTime+420 seconds ;

    bool threeMonthRebaseDone=false;
    bool sixMonthRebaseDone=false;
   uint RebaseDate = 2871713745;

   ///>timestamp.now+183 days <= timestamp.now+548 days //>6 months and less than  or equal to  18 months, rebase in 3 months

   function rebaseStd(uint256 epoch, int256 supplyDelta)
        external
       // onlyMonetaryPolicy
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        // From this point forward, _gonsPerFragment is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _gonsPerFragment
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_GONS - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // _totalSupply = TOTAL_GONS.div(_gonsPerFragment)

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }
  function rebase() public  returns (bool ){
  require (block.timestamp >= sixMonths_of_deployTime );
  uint256 _epoch;
  int256 delta;
   if(block.timestamp >= sixMonths_of_deployTime && block.timestamp <= eighteenMonths_of_deployTime && threeMonthCompleted() ){
     _rebase( _epoch, delta);
     RebaseDate = block.timestamp;
     return true;
  }
 // if(difference(block.timestamp and twoyearRebase) > 730 days)
if (difference())
{
  _rebase(_epoch,delta);
  uint twoYearRebase = block.timestamp;
  }

  if(!sixMonthRebaseDone){
  _rebase(_epoch,delta);
  sixMonthRebaseDone=true;
  RebaseDate= block.timestamp;
  return true;
  }
  else {return false;

  }}

function difference ()public view returns (bool){
uint difference= (block.timestamp - twoYears_of_deployTime);
//if (difference > 730 days){
    if(difference > 420 seconds )
{return true;
}
else
return false;

}


 function threeMonthCompleted () public view returns(bool) {
 uint diff = RebaseDate - block.timestamp;
// if (diff > 90 ) {
    if(diff>240 seconds) {
return true;
}
else
return false;

 }

    function initialize(address owner_)
        public
       override  initializer
    {
        ERC20Detailed.initialize("Calm Coin Gold", "CCG", uint8(DECIMALS));
        Ownable.initialize(owner_);

        rebasePausedDeprecated = false;
        tokenPausedDeprecated = false;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[owner_] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit Transfer(address(0x0), owner_, _totalSupply);
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply()
        public
        view override
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        view override
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        validRecipient(to) override
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        escrow[to] = escrow[to] + gonValue;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        view override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        validRecipient(to)  override
        returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
_allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
}

     // enable owner to add more ether
contract Gold is  IERC20, CalmCoinGold{
    /* * @notice We usually require to know who are all the stakeholders.
     */
      address[] internal stakeholders;
     IERC20 public reward;
    //  constructor(IERC20 _reward) public{
    //reward = _reward;
   //}
   /* * @notice The stakes for each stakeholder.
    */

   /* * @notice The accumulated rewards for each stakeholder.
    */

    mapping(address => uint256) public stakes;

   function rewards(address stakeholder) public view returns(uint256){
      return reward.balanceOf(stakeholder);
   }


  function isStakeholder(address _address)public view returns(bool, uint256)
  {
      for (uint256 s = 0; s < stakeholders.length; s += 1){
          if (_address == stakeholders[s]) return (true, s);
      }
      return (false, 0);
  }
  function addStakeholder(address _stakeholder)internal
  {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
      if(!_isStakeholder)
      stakeholders.push(_stakeholder);
  }

   function removeStakeholder(address _stakeholder)internal
   {
    (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
          stakeholders[s] = stakeholders[stakeholders.length - 1];
          stakeholders.pop();
      }
   }

   function createStake(uint256 _stake)public
   {
       _burn(msg.sender, _stake);
       if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
       stakes[msg.sender] = stakes[msg.sender].add(_stake);
   }
   /**
    * @notice A method for a stakeholder to remove a stake.
    * @param _stake The size of the stake to be removed.
    */
   function removeStake(uint256 _stake)public
   {
       stakes[msg.sender] = stakes[msg.sender].sub(_stake);
       if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
       _mint(msg.sender, _stake);
   }

     function distributeRewards()public onlyOwner
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
          // address stakeholder = stakeholders[s];
            uint256 silver = calculateReward(stakeholders[s]);
           //rewards[stakeholder] = rewards[stakeholder].add(reward);
           reward.mint(stakeholders[s], silver);
       }
   }
  /**
    * @notice A simple method that calculates the rewards for each stakeholder.
    * @param _stakeholder The stakeholder to calculate rewards for.
    *  subtract Withdrawal Fee = G%
    */
   function calculateReward(address _stakeholder)view internal returns(uint256)
   {
       return stakes[_stakeholder];
   }
   /**
    * @notice A method to allow a stakeholder to withdraw his rewards.
    */
//   function withdrawReward()public
//   {
//       uint256 reward = rewards[msg.sender]-WITHDRAW_FEE;
//       rewards[msg.sender] = 0;
//       _mint(msg.sender, reward);
//   }

}
contract Contingency is CalmCoinGold {

//address public fundwallet;
//address public escrow;

uint256 rent;

constructor()public{

//fundwallet = _fundwallet;
}

mapping(address=>uint256) public fundBal;

function addfund() onlyOwner payable public{
    fundBal[ContingencyFund]+=msg.value;
}

function sold(address newOwner) onlyOwner public{
    require(balanceOf(newOwner) > 0, "sell the property holdings first");
    fundBal[owner()] += fundBal[ContingencyFund];
    fundBal[ContingencyFund] = 0;
    // _transferOwnership(newOwner);
}

function Rented(uint256 _rent)onlyOwner public{
    rent = _rent;
    CalmCoinGold.transfer(ContingencyFund, fundBal[ContingencyFund]);
    fundBal[ContingencyFund] = 0;
}

function useFund(uint256 amount) onlyOwner public{
    fundBal[ContingencyFund] = fundBal[ContingencyFund] - amount;
     CalmCoinGold.transfer(_owner, amount);
}

function highMaintenance() onlyOwner public {
    require(balanceOf(ContingencyFund)/6> 0, "should have 6 months highMaintenance fund");
    require(rent > (balanceOf(ContingencyFund)/6), "monthly rent should be greater than monthly maintanance charge");
    uint amount = rent*10/100;
    CalmCoinGold.transferFrom(ContingencyFund, owner(), amount);
}

function singleHome() onlyOwner public {
    require(balanceOf(ContingencyFund)/6> 0, "should have 6 months highMaintenance fund");
    require(rent > (balanceOf(ContingencyFund)/6), "monthly rent should be greater than monthly maintanance charge");
    uint amount = rent*6/100;
    CalmCoinGold.transferFrom(ContingencyFund, owner(), amount);
}
// function goldTtoken (address user) public view returns(uint256){
//     return CalmCoinGold.balanceOf(user);
// }
}
contract Loan {
     //address payable Loan;
     //address payable newLoan;
    address payable public lender;
    address payable  public borrower;
    CalmCoinGold public token;
    uint256 public collateralAmount;
    uint256 public payoffAmount;
    uint256 public dueDate;

    constructor (
        address payable _lender,
        address payable  _borrower,
        CalmCoinGold _token,
        uint256 _collateralAmount,
        uint256 _payoffAmount,
        uint256 loanDuration
    )
        public payable
    {
        lender = _lender;
        borrower = _borrower;
        token = _token;
        collateralAmount = _collateralAmount;
        payoffAmount = _payoffAmount;
        dueDate = now + loanDuration;
    }

    event LoanPaid();

    function payLoan() public payable {
        require(now <= dueDate);
        require(msg.value == payoffAmount);

        require(token.transfer(borrower, collateralAmount));
        emit LoanPaid();
        selfdestruct(lender);
    }

    function repossess() public {
        require(now > dueDate);

        require(token.transfer(lender, collateralAmount));
        selfdestruct(lender);
    }
}



contract Mortal is Ownable {
    
}

contract PawnShop is Gold {
    struct Rational {
        uint256 numerator;
        uint256 denominator;
    }

    CalmCoinGold public token;
    Rational public loanWeiPerUnit;
    Rational public payoffWeiPerUnit;
    uint256 public loanDuration;
    address payable owner_;

    constructor (
        address  payable lender,
        CalmCoinGold _token,
        uint256 loanNumerator,
        uint256 loanDenominator,
        uint256 payoffNumerator,
        uint256 payoffDenominator,
        uint256 _loanDuration
    )
        public
        payable
    {
        owner_ = lender;
        token = _token;
        loanWeiPerUnit = Rational(loanNumerator, loanDenominator);
        payoffWeiPerUnit = Rational(payoffNumerator, payoffDenominator);
        loanDuration = _loanDuration;
    }

    function multiply(Rational storage r, uint256 x) internal  view returns (uint256) {
        if (x == 0) { return 0; }
        uint256 v = x * r.numerator;
        assert(v / x == r.numerator);  // avoid overflow
        return v / r.denominator;
    }

    event LoanCreated(
        Loan  loan,
        address  payable indexed borrower,
        CalmCoinGold token,
        uint256 tokenAmount,
        uint256 etherDue,
        uint256 dueDate
    );

    function pawnTokens(uint256 unitQuantity) public {
        uint256 totalLoan = multiply(loanWeiPerUnit, unitQuantity);
        uint256 totalPayoff = multiply(payoffWeiPerUnit, unitQuantity);
        Loan loan =  new Loan (owner_, msg.sender, token, unitQuantity, totalPayoff, loanDuration);
         if (stakes[msg.sender]  >=unitQuantity){
       require(token.transferFrom(msg.sender, address(loan), unitQuantity));
        msg.sender.transfer(totalLoan);

        emit LoanCreated(loan, msg.sender, token, unitQuantity, totalPayoff,
            now+loanDuration);
    }}
//address  payable owner = msg.sender;
    mapping(address => uint256) balance;
  
  function kill() public onlyOwner {
        selfdestruct(msg.sender);
    }
    
  
    function deposit() public payable {
        
          
    }
}