//ExchangeRatesDatabase.sol
pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {

  address public owner;

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

contract ExchangeRatesDatabase is Ownable {


    struct candleStruct {
      uint32 maximum;
      uint32 minimum;
      //uint32 opening;
      uint32 closing;
    }


    event setRateEvent(string _currPair, uint32 _time, uint32 _maximum, uint32 _minimum /*, uint32 _opening */, uint32 _closing );


    address manager;

    mapping (string => mapping (uint64 => candleStruct)) ratesDatabase;


    constructor() public {
        manager = msg.sender;
    }



    modifier onlyOwnerOrManager() {
        require((msg.sender == owner)||(msg.sender == manager));
        _;
    }



    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }


    function setRate(string _currPair, uint32 _time, uint32 _maximum, uint32 _minimum /*, uint32 _opening */, uint32 _closing ) public onlyOwnerOrManager {
        candleStruct memory candle = candleStruct({maximum:_maximum, minimum:_minimum /*, opening:_opening */, closing:_closing });
        ratesDatabase[_currPair][_time] = candle;
    }


    function getRate(string _currPair, uint64 _time ) public constant returns (uint32, uint32 /*, uint32*/, uint32 ) {
        return (ratesDatabase[_currPair][_time].maximum, ratesDatabase[_currPair][_time].minimum /*, ratesDatabase[_currPair][_time].opening*/, ratesDatabase[_currPair][_time].closing );
    }


    function set2Rate(string _currPair1, string _currPair2, uint32 _time, uint32 _maximum1, uint32 _minimum1 /*, uint32 _opening */, uint32 _closing1, uint32 _maximum2, uint32 _minimum2 /*, uint32 _opening */, uint32 _closing2 ) public onlyOwnerOrManager {
        candleStruct memory candle = candleStruct({maximum:_maximum1, minimum:_minimum1 /*, opening:_opening */, closing:_closing1 });
        ratesDatabase[_currPair1][_time] = candle;

        candle = candleStruct({maximum:_maximum2, minimum:_minimum2 /*, opening:_opening */, closing:_closing2 });
        ratesDatabase[_currPair2][_time] = candle;
    }

}