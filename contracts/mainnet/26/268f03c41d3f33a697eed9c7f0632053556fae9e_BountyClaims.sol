pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/BountyClaims.sol

contract BountyClaims is Ownable {
  using SafeMath for uint256;

  ERC20 public token;

  address public wallet;

  mapping(address => uint256) bountyTokens;

  event Claim(
    address indexed beneficiary,
    uint256 amount
  );

  function BountyClaims(
    ERC20 _token,
    address _wallet) public
  {
    require(_token != address(0));
    require(_wallet != address(0));
    token = _token;
    wallet = _wallet;
  }

  function() external payable {
    claimToken(msg.sender);
  }

  function setUsersBounty(address[] _beneficiaries, uint256[] _amounts) external onlyOwner {
    for (uint i = 0; i < _beneficiaries.length; i++) {
      bountyTokens[_beneficiaries[i]] = _amounts[i];
    }
  }

  function setGroupBounty(address[] _beneficiaries, uint256 _amount) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      bountyTokens[_beneficiaries[i]] = _amount;
    }
  }

  function getUserBounty(address _beneficiary) public view returns (uint256) {
    return  bountyTokens[_beneficiary];
  }

  function claimToken(address _beneficiary) public payable {
    uint256 amount = bountyTokens[_beneficiary];
    require(amount > 0);
    bountyTokens[_beneficiary] = 0;
    require(token.transferFrom(wallet, _beneficiary, amount));
    emit Claim(_beneficiary, amount);
  }
}