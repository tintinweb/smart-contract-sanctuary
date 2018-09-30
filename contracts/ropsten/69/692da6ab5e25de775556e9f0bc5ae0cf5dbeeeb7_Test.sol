pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Test {
    using SafeMath for uint256;
    
    uint256 public kickOff;
    
    uint256[] periods;
    uint8[] percentages;
    
    constructor() public {
        kickOff = 0;
        
        periods.push(120);
        periods.push(180);
        periods.push(240);
        periods.push(320);
        periods.push(380);
        
        percentages.push(5);
        percentages.push(10);
        percentages.push(15);
        percentages.push(20);
        percentages.push(50);
    }
    
    function start() public returns (bool) {
        kickOff = now + 60 * 5;
    }
    
    function getUnlockedPercentage() public view returns (uint256, uint256) {
        if (kickOff == 0 ||
            kickOff > now)
        {
            return (100, 123);
        }
        
        uint256 unlockedPercentage = 0;
        for (uint256 i = 0; i < periods.length; i++) {
            if (kickOff + periods[i] <= now) {
                unlockedPercentage = unlockedPercentage.add(percentages[i]);
            }
        }
        
        if (unlockedPercentage > 100) {
            return (0, 123);
        }
        
        return (100 - unlockedPercentage, ((now - kickOff) / 60));
    }
    
    function getPeriods() public view returns (uint256[]) {
        return periods;
    }
    
    function getPercentages() public view returns (uint8[]) {
        return percentages;
    }
    
    function getNow() public view returns (uint256) {
        return now;
    }
}