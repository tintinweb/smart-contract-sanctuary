pragma solidity 0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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


interface IERC20 {
    function transfer(address to, uint value) external returns (bool ok);
    function balanceOf(address _owner) external view returns (uint256 balance);
}


contract Airdrop is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public cap;
    uint256 public individualCap;
    uint256 public totalAlloctedToken;
    mapping (address => uint256) airdropContribution;

    function Airdrop(
        IERC20 _tokenAddr,
        uint256 _cap,
        uint256 _individualCap
    )
        public
    {
        token = _tokenAddr;
        cap = _cap;
        individualCap = _individualCap;
    }

    function drop(address[] _recipients, uint256[] _amount) 
        external 
        onlyOwner returns (bool) 
    {
        require(_recipients.length == _amount.length);
        
        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0));
            require(individualCap >= airdropContribution[_recipients[i]].add(_amount[i]));
            require(cap >= totalAlloctedToken.add(_amount[i]));
            airdropContribution[_recipients[i]] = airdropContribution[_recipients[i]].add(_amount[i]);
            totalAlloctedToken = totalAlloctedToken.add(_amount[i]);
            token.transfer(_recipients[i], _amount[i]);
        }
        return true;
    }
}