pragma solidity ^0.4.13;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract WhiteListRegistry is Ownable {

    mapping (address => WhiteListInfo) public whitelist;
    using SafeMath for uint;

    struct WhiteListInfo {
        bool whiteListed;
        uint minCap;
        uint maxCap;
    }

    event AddedToWhiteList(
        address contributor,
        uint minCap,
        uint maxCap
    );

    event RemovedFromWhiteList(
        address _contributor
    );

    function addToWhiteList(address _contributor, uint _minCap, uint _maxCap) public onlyOwner {
        require(_contributor != address(0));
        whitelist[_contributor] = WhiteListInfo(true, _minCap, _maxCap);
        AddedToWhiteList(_contributor, _minCap, _maxCap);
    }

    function removeFromWhiteList(address _contributor) public onlyOwner {
        require(_contributor != address(0));
        delete whitelist[_contributor];
        RemovedFromWhiteList(_contributor);
    }

    function isWhiteListed(address _contributor) public view returns(bool) {
        return whitelist[_contributor].whiteListed;
    }

    function isAmountAllowed(address _contributor, uint _amount) public view returns(bool) {
       return whitelist[_contributor].maxCap >= _amount && whitelist[_contributor].minCap <= _amount && isWhiteListed(_contributor);
    }

}