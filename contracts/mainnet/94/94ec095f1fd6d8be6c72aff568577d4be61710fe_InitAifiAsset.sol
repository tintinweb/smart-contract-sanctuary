pragma solidity ^0.4.23;

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

//-------------------------------------------------------------------------------------------------

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

//-------------------------------------------------------------------------------------------------

contract AifiAsset is Ownable {
  using SafeMath for uint256;

  enum AssetState { Pending, Active, Expired }
  string public assetType;
  uint256 public totalSupply;
  AssetState public state;

  constructor() public {
    state = AssetState.Pending;
  }

  function setState(AssetState _state) public onlyOwner {
    state = _state;
    emit SetStateEvent(_state);
  }

  event SetStateEvent(AssetState indexed state);
}

//-------------------------------------------------------------------------------------------------

contract InitAifiAsset is AifiAsset {
  string public assetType = "DEBT";
  uint public initialSupply = 1000 * 10 ** 18;
  string[] public subjectMatters;
  
  constructor() public {
    totalSupply = initialSupply;
  }

  function addSubjectMatter(string _subjectMatter) public onlyOwner {
    subjectMatters.push(_subjectMatter);
  }

  function updateSubjectMatter(uint _index, string _subjectMatter) public onlyOwner {
    require(_index <= subjectMatters.length);
    subjectMatters[_index] = _subjectMatter;
  }

  function getSubjectMattersSize() public view returns(uint) {
    return subjectMatters.length;
  }
}