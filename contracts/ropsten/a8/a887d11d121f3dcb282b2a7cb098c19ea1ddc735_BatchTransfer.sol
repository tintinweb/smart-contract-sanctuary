pragma solidity ^0.4.23;

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

contract BatchTransfer {
  using SafeMath for uint256;

  address public owner;
  uint256 public totalTransfer;
  uint256 public totalAddresses;
  uint256 public totalTransactions;

  event Transfers(address indexed from, uint256 indexed value, uint256 indexed count);
  
  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function batchTransfer(address[] _addresses) public payable {
    require (msg.value > 0 && _addresses.length > 0);
    totalTransfer = totalTransfer.add(msg.value);
    totalAddresses = totalAddresses.add(_addresses.length);
    totalTransactions++;
    for (uint i = 0; i < _addresses.length; i++) {
      _addresses[i].transfer(msg.value.div(_addresses.length));
    }
    emit Transfers(msg.sender,msg.value,_addresses.length);
  }

  function withdraw() public restricted {
    address contractAddress = this;
    owner.transfer(contractAddress.balance);
  }

  function () payable public {
    msg.sender.transfer(msg.value);
  }  
}