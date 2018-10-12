pragma solidity ^0.4.24;

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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions". This adds two-phase
 * ownership control to OpenZeppelin&#39;s Ownable class. In this model, the original owner 
 * designates a new owner but does not actually transfer ownership. The new owner then accepts 
 * ownership and completes the transfer.
 */
contract Ownable {
  address public owner;
  address public pendingOwner;


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
    pendingOwner = address(0);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    pendingOwner = _newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }


}

/**
* @title CarbonDollarStorage
* @notice Contains necessary storage contracts for CarbonDollar (FeeSheet and StablecoinWhitelist).
*/
contract CarbonDollarStorage is Ownable {
    using SafeMath for uint256;

    /** 
        Mappings
    */
    /* fees for withdrawing to stablecoin, in tenths of a percent) */
    mapping (address => uint256) public fees;
    /** @dev Units for fees are always in a tenth of a percent */
    uint256 public defaultFee;
    /* is the token address referring to a stablecoin/whitelisted token? */
    mapping (address => bool) public whitelist;


    /** 
        Events
    */
    event DefaultFeeChanged(uint256 oldFee, uint256 newFee);
    event FeeChanged(address indexed stablecoin, uint256 oldFee, uint256 newFee);
    event FeeRemoved(address indexed stablecoin, uint256 oldFee);
    event StablecoinAdded(address indexed stablecoin);
    event StablecoinRemoved(address indexed stablecoin);

    /** @notice Sets the default fee for burning CarbonDollar into a whitelisted stablecoin.
        @param _fee The default fee.
    */
    function setDefaultFee(uint256 _fee) public onlyOwner {
        uint256 oldFee = defaultFee;
        defaultFee = _fee;
        if (oldFee != defaultFee)
            emit DefaultFeeChanged(oldFee, _fee);
    }
    
    /** @notice Set a fee for burning CarbonDollar into a stablecoin.
        @param _stablecoin Address of a whitelisted stablecoin.
        @param _fee the fee.
    */
    function setFee(address _stablecoin, uint256 _fee) public onlyOwner {
        uint256 oldFee = fees[_stablecoin];
        fees[_stablecoin] = _fee;
        if (oldFee != _fee)
            emit FeeChanged(_stablecoin, oldFee, _fee);
    }

    /** @notice Remove the fee for burning CarbonDollar into a particular kind of stablecoin.
        @param _stablecoin Address of stablecoin.
    */
    function removeFee(address _stablecoin) public onlyOwner {
        uint256 oldFee = fees[_stablecoin];
        fees[_stablecoin] = 0;
        if (oldFee != 0)
            emit FeeRemoved(_stablecoin, oldFee);
    }

    /** @notice Add a token to the whitelist.
        @param _stablecoin Address of the new stablecoin.
    */
    function addStablecoin(address _stablecoin) public onlyOwner {
        whitelist[_stablecoin] = true;
        emit StablecoinAdded(_stablecoin);
    }

    /** @notice Removes a token from the whitelist.
        @param _stablecoin Address of the ex-stablecoin.
    */
    function removeStablecoin(address _stablecoin) public onlyOwner {
        whitelist[_stablecoin] = false;
        emit StablecoinRemoved(_stablecoin);
    }


    /**
     * @notice Compute the fee that will be charged on a "burn" operation.
     * @param _amount The amount that will be traded.
     * @param _stablecoin The stablecoin whose fee will be used.
     */
    function computeStablecoinFee(uint256 _amount, address _stablecoin) public view returns (uint256) {
        uint256 fee = fees[_stablecoin];
        return computeFee(_amount, fee);
    }

    /**
     * @notice Compute the fee that will be charged on a "burn" operation.
     * @param _amount The amount that will be traded.
     * @param _fee The fee that will be charged, in tenths of a percent.
     */
    function computeFee(uint256 _amount, uint256 _fee) public pure returns (uint256) {
        return _amount.mul(_fee).div(1000);
    }
}