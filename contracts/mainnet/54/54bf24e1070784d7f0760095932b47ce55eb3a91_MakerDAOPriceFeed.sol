pragma solidity 0.4.24;

// File: contracts/interfaces/EthPriceFeedI.sol

interface EthPriceFeedI {
    function getUnit() external view returns(string);
    function getRate() external view returns(uint256);
    function getLastTimeUpdated() external view returns(uint256); 
}

// File: contracts/interfaces/ReadableI.sol

// https://github.com/makerdao/feeds/blob/master/src/abi/readable.json

pragma solidity 0.4.24;

interface ReadableI {

    // We only care about these functions
    function peek() external view returns(bytes32, bool);
    function read() external view returns(bytes32);

    // function owner() external view returns(address);
    // function zzz() external view returns(uint256);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

// File: contracts/MakerDAOPriceFeed.sol

contract MakerDAOPriceFeed is Ownable, EthPriceFeedI {
    using SafeMath for uint256;
    
    uint256 public constant RATE_THRESHOLD_PERCENTAGE = 10;
    uint256 public constant MAKERDAO_FEED_MULTIPLIER = 10**36;

    ReadableI public makerDAOMedianizer;

    uint256 private weiPerUnitRate;

    uint256 private lastTimeUpdated; 
    
    event RateUpdated(uint256 _newRate, uint256 _timeUpdated);

    modifier isValidRate(uint256 _weiPerUnitRate) {
        require(validRate(_weiPerUnitRate));
        _;
    }

    constructor(ReadableI _makerDAOMedianizer) public {
        require(_makerDAOMedianizer != address(0));
        makerDAOMedianizer = _makerDAOMedianizer;

        weiPerUnitRate = convertToRate(_makerDAOMedianizer.read());
        lastTimeUpdated = now;
    }
    
    /// @dev Receives rate from outside oracle
    /// @param _weiPerUnitRate calculated off chain and received in the contract
    function updateRate(uint256 _weiPerUnitRate) 
        external 
        onlyOwner
        isValidRate(_weiPerUnitRate)
    {
        weiPerUnitRate = _weiPerUnitRate;

        lastTimeUpdated = now; 

        emit RateUpdated(_weiPerUnitRate, now);
    }

    function getUnit()
        external
        view 
        returns(string)
    {
        return "USD";
    }

    /// @dev View function to see the rate stored in the contract.
    function getRate() 
        public 
        view 
        returns(uint256)
    {
        return weiPerUnitRate; 
    }

    /// @dev View function to see that last time that the rate was updated. 
    function getLastTimeUpdated()
        public
        view
        returns(uint256)
    {
        return lastTimeUpdated;
    }

    /// @dev Checks that a rate is valid.
    /// @param _weiPerUnitRate The rate to check
    /// @return True iff the rate is valid
    function validRate(uint256 _weiPerUnitRate) public view returns(bool) {
        if (_weiPerUnitRate == 0) return false;

        (bytes32 value, bool valid) = makerDAOMedianizer.peek();

        // If the value from the medianizer is not valid, use the current rate as reference
        uint256 currentRate = valid ? convertToRate(value) : weiPerUnitRate;

        // Get the difference
        uint256 diff = _weiPerUnitRate < currentRate ?  currentRate.sub(_weiPerUnitRate) : _weiPerUnitRate.sub(currentRate);

        return diff <= currentRate.mul(RATE_THRESHOLD_PERCENTAGE).div(100);
    }

    /// @dev Transforms a bytes32 value taken from MakerDAO&#39;s Medianizer contract into wei per usd rate
    /// @param _fromMedianizer Value taken from MakerDAO&#39;s Medianizer contract
    /// @return The wei per usd rate
    function convertToRate(bytes32 _fromMedianizer) internal pure returns(uint256) {
        uint256 value = uint256(_fromMedianizer);
        return MAKERDAO_FEED_MULTIPLIER.div(value);
    }
}