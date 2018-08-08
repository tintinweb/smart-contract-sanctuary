pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract token { function transfer(address receiver, uint amount){  } }

contract SendTokensContract is Ownable {
  using SafeMath for uint;
  mapping (address => uint) public bals;
  mapping (address => uint) public releaseTimes;
  mapping (address => bytes32[]) public referenceCodes;
  mapping (bytes32 => address[]) public referenceAddresses;
  address public addressOfTokenUsedAsReward;
  token tokenReward;

  event TokensSent
    (address to, uint256 value, uint256 timeStamp, bytes32 referenceCode);

  function setTokenReward(address _tokenContractAddress) public onlyOwner {
    tokenReward = token(_tokenContractAddress);
    addressOfTokenUsedAsReward = _tokenContractAddress;
  }

  function sendTokens(address _to, 
    uint _value, 
    uint _timeStamp, 
    bytes32 _referenceCode) public onlyOwner {
    bals[_to] = bals[_to].add(_value);
    releaseTimes[_to] = _timeStamp;
    referenceCodes[_to].push(_referenceCode);
    referenceAddresses[_referenceCode].push(_to);
    emit TokensSent(_to, _value, _timeStamp, _referenceCode);
  }

  function getReferenceCodesOfAddress(address _addr) public constant 
  returns (bytes32[] _referenceCodes) {
    return referenceCodes[_addr];
  }

  function getReferenceAddressesOfCode(bytes32 _code) public constant
  returns (address[] _addresses) {
    return referenceAddresses[_code];
  }

  function withdrawTokens() public {
    require(bals[msg.sender] > 0);
    require(now >= releaseTimes[msg.sender]);
    tokenReward.transfer(msg.sender,bals[msg.sender]);
    bals[msg.sender] = 0;
  }
}