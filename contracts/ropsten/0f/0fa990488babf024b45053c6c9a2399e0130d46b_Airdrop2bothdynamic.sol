pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Token{
    function transfer(address to, uint tokens) public returns (bool success);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
}


/**
 * @title token token initial distribution
 *
 * @dev Distribute purchasers, airdrop, reserve, and founder tokens
 */
contract Airdrop2bothdynamic is Owned {
  using SafeMath for uint256;
  Token public token;
  uint256 private constant decimalFactor = 10**uint256(18);
  // Keeps track of whether or not a 250 token airdrop has been made to a particular address
  mapping (address => bool) public airdrops;
  
  /**
    * @dev Constructor function - Set the token token address
    */
  constructor(address _tokenContractAdd, address _owner) public {
    // takes an address of the existing token contract as parameter
    token = Token(_tokenContractAdd);
    owner = _owner;
  }
  
  /**
    * @dev perform a transfer of allocations
    * @param _recipient is a list of recipients
    */
  function airdropTokens(address[] _recipient, uint256[] _tokens) public onlyOwner{
    uint airdropped;
    for(uint256 i = 0; i< _recipient.length; i++)
    {
        if (!airdrops[_recipient[i]]) {
          airdrops[_recipient[i]] = true;
          require(token.transfer(_recipient[i], _tokens[i] * decimalFactor));
          airdropped = airdropped.add(_tokens[i] * decimalFactor);
        }
    }
  }
}