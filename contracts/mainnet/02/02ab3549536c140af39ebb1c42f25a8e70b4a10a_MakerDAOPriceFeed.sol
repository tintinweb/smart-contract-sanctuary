pragma solidity 0.4.23;

// File: contracts/interfaces/EthPriceFeedI.sol

interface EthPriceFeedI {
    function updateRate(uint256 _weiPerUnitRate) external;
    function getRate() external view returns(uint256);
    function getLastTimeUpdated() external view returns(uint256); 
}

// File: contracts/interfaces/ReadableI.sol

// https://github.com/makerdao/feeds/blob/master/src/abi/readable.json

pragma solidity 0.4.23;

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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

    constructor(ReadableI _makerDAOMedianizer) {
        require(_makerDAOMedianizer != address(0));
        makerDAOMedianizer = _makerDAOMedianizer;

        weiPerUnitRate = convertToRate(_makerDAOMedianizer.read());
        lastTimeUpdated = now;
    }
    
    /// @dev Receives rate from outside oracle
    /// @param _weiPerUnitRate calculated off chain and received to the contract
    function updateRate(uint256 _weiPerUnitRate) 
        external 
        onlyOwner
        isValidRate(_weiPerUnitRate)
    {
        weiPerUnitRate = _weiPerUnitRate;

        lastTimeUpdated = now; 

        emit RateUpdated(_weiPerUnitRate, now);
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

    function validRate(uint256 _weiPerUnitRate) public view returns(bool) {
        if (_weiPerUnitRate == 0) return false;
        bytes32 value;
        bool valid;
        (value, valid) = makerDAOMedianizer.peek();

        // If the value from the medianizer is not valid, use the current rate as reference
        uint256 currentRate = valid ? convertToRate(value) : weiPerUnitRate;

        // Get the difference
        uint256 diff = _weiPerUnitRate < currentRate ?  currentRate.sub(_weiPerUnitRate) : _weiPerUnitRate.sub(currentRate);

        return diff <= currentRate.mul(RATE_THRESHOLD_PERCENTAGE).div(100);
    }

    function convertToRate(bytes32 _fromMedianizer) internal pure returns(uint256) {
        uint256 value = uint256(_fromMedianizer);
        return MAKERDAO_FEED_MULTIPLIER.div(value);
    }
}