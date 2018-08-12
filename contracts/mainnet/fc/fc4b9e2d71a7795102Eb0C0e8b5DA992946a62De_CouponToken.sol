pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract CouponTokenConfig {
    string public constant name = "Coupon Chain Token"; 
    string public constant symbol = "CCT";
    uint8 public constant decimals = 18;

    uint256 internal constant DECIMALS_FACTOR = 10 ** uint(decimals);
    uint256 internal constant TOTAL_COUPON_SUPPLY = 1000000000 * DECIMALS_FACTOR;

    uint8 constant USER_NONE = 0;
    uint8 constant USER_FOUNDER = 1;
    uint8 constant USER_BUYER = 2;
    uint8 constant USER_BONUS = 3;

}

//contract CouponToken is MintableToken {
contract CouponToken is StandardToken, Ownable, CouponTokenConfig {
    using SafeMath for uint256;

    // Start time of the Sale-lot 4
    uint256 public startTimeOfSaleLot4;

    // End time of Sale
    uint256 public endSaleTime;

    // Address of CouponTokenSale contract
    address public couponTokenSaleAddr;

    // Address of CouponTokenBounty contract
    address public couponTokenBountyAddr;

    // Address of CouponTokenCampaign contract
    address public couponTokenCampaignAddr;


    // List of User for Vesting Period 
    mapping(address => uint8) vestingUsers;

    /*
     *
     * E v e n t s
     *
     */
    event Mint(address indexed to, uint256 tokens);

    /*
     *
     * M o d i f i e r s
     *
     */

    modifier canMint() {
        require(
            couponTokenSaleAddr == msg.sender ||
            couponTokenBountyAddr == msg.sender ||
            couponTokenCampaignAddr == msg.sender);
        _;
    }

    modifier onlyCallFromCouponTokenSale() {
        require(msg.sender == couponTokenSaleAddr);
        _;
    }

    modifier onlyIfValidTransfer(address sender) {
        require(isTransferAllowed(sender) == true);
        _;
    }

    modifier onlyCallFromTokenSaleOrBountyOrCampaign() {
        require(
            msg.sender == couponTokenSaleAddr ||
            msg.sender == couponTokenBountyAddr ||
            msg.sender == couponTokenCampaignAddr);
        _;
    }


    /*
     *
     * C o n s t r u c t o r
     *
     */
    constructor() public {
        balances[msg.sender] = 0;
    }


    /*
     *
     * F u n c t i o n s
     *
     */
    /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
    function mint(address _to, uint256 _amount) canMint public {
        
        require(totalSupply_.add(_amount) <= TOTAL_COUPON_SUPPLY);

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    /*
     * Transfer token from message sender to another
     *
     * @param to: Destination address
     * @param value: Amount of Coupon token to transfer
     */
    function transfer(address to, uint256 value)
        public
        onlyIfValidTransfer(msg.sender)
        returns (bool) {
        return super.transfer(to, value);
    }

    /*
     * Transfer token from &#39;from&#39; address to &#39;to&#39; addreess
     *
     * @param from: Origin address
     * @param to: Destination address
     * @param value: Amount of Coupon Token to transfer
     */
    function transferFrom(address from, address to, uint256 value)
        public
        onlyIfValidTransfer(from)
        returns (bool){

        return super.transferFrom(from, to, value);
    }

    function setContractAddresses(
        address _couponTokenSaleAddr,
        address _couponTokenBountyAddr,
        address _couponTokenCampaignAddr)
        external
        onlyOwner
    {
        couponTokenSaleAddr = _couponTokenSaleAddr;
        couponTokenBountyAddr = _couponTokenBountyAddr;
        couponTokenCampaignAddr = _couponTokenCampaignAddr;
    }


    function setSalesEndTime(uint256 _endSaleTime) 
        external
        onlyCallFromCouponTokenSale  {
        endSaleTime = _endSaleTime;
    }

    function setSaleLot4StartTime(uint256 _startTime)
        external
        onlyCallFromCouponTokenSale {
        startTimeOfSaleLot4 = _startTime;
    }


    function setFounderUser(address _user)
        public
        onlyCallFromCouponTokenSale {
        // Add vesting user as Founder
        vestingUsers[_user] = USER_FOUNDER;
    }

    function setSalesUser(address _user)
        public
        onlyCallFromCouponTokenSale {
        // Add vesting user under sales purchase
        vestingUsers[_user] = USER_BUYER;
    }

    function setBonusUser(address _user) 
        public
        onlyCallFromTokenSaleOrBountyOrCampaign {
        // Set this user as who got bonus
        vestingUsers[_user] = USER_BONUS;
    }

    function isTransferAllowed(address _user)
        internal view
        returns (bool) {
        bool retVal = true;
        if(vestingUsers[_user] == USER_FOUNDER) {
            if(endSaleTime == 0 ||                // See whether sale is over?
                (now < (endSaleTime + 730 days))) // 2 years
                retVal = false;
        }
        else if(vestingUsers[_user] == USER_BUYER || vestingUsers[_user] == USER_BONUS) {
            if(startTimeOfSaleLot4 == 0 ||              // See if the SaleLot4 started?
                (now < (startTimeOfSaleLot4 + 90 days)))
                retVal = false;
        }
        return retVal;
    }
}