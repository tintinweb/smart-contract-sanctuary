pragma solidity ^0.4.24;

// File: contracts/eternal_storage/EternalStorage.sol

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

  mapping(bytes32 => uint256) internal uintStorage;
  mapping(bytes32 => string) internal stringStorage;
  mapping(bytes32 => address) internal addressStorage;
  mapping(bytes32 => bytes) internal bytesStorage;
  mapping(bytes32 => bool) internal boolStorage;
  mapping(bytes32 => int256) internal intStorage;

}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: contracts/test/Token_V0.sol

//import &#39;./DetailedERC20.sol&#39;;

/**
 * @title Token_V0
 * @dev Version 0 of a token to show upgradeability.
 */
contract Token_V0 is EternalStorage {
  using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256) {
    return uintStorage[keccak256("totalSupply")];
  }

  function balanceOf(address owner) public view returns (uint256) {
    return uintStorage[keccak256("balance", owner)];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return uintStorage[keccak256("allowance", owner, spender)];
  }

  function transfer(address to, uint256 value) public {
    bytes32 balanceToHash = keccak256("balance", to);
    bytes32 balanceSenderHash = keccak256("balance", msg.sender);

    require(to != address(0));
    require(uintStorage[balanceSenderHash] >= value);

    uintStorage[balanceSenderHash] = balanceOf(msg.sender).sub(value);
    uintStorage[balanceToHash] = balanceOf(to).add(value);
    Transfer(msg.sender, to, value);
  }

  function transferFrom(address from, address to, uint256 value) public {
    bytes32 balanceToHash = keccak256("balance", to);
    bytes32 balanceFromHash = keccak256("balance", from);
    bytes32 allowanceFromToSenderHash = keccak256("allowance", from, msg.sender);

    require(to != address(0));
    require(uintStorage[balanceFromHash] >= value );
    require(uintStorage[allowanceFromToSenderHash] >= value);

    uintStorage[balanceFromHash] = balanceOf(from).sub(value);
    uintStorage[balanceToHash] = balanceOf(to).add(value);
    uintStorage[allowanceFromToSenderHash] = allowance(from, msg.sender).sub(value);
    Transfer(from, to, value);
  }

  function approve(address spender, uint256 value) public {
    bytes32 allowanceSenderToSpenderHash = keccak256("allowance", msg.sender, spender);
    uintStorage[allowanceSenderToSpenderHash] = value;
    Approval(msg.sender, spender, value);
  }

  function increaseApproval(address spender, uint256 addedValue) public {
    bytes32 allowanceSenderToSpenderHash = keccak256("allowance", msg.sender, spender);
    uintStorage[allowanceSenderToSpenderHash] = allowance(msg.sender, spender).add(addedValue);
    Approval(msg.sender, spender, allowance(msg.sender, spender));
  }

  function decreaseApproval(address spender, uint256 subtractedValue) public {
    uint256 oldValue = allowance(msg.sender, spender);
    bytes32 allowanceSenderToSpenderHash = keccak256("allowance", msg.sender, spender);
    if (subtractedValue > oldValue) {
      uintStorage[allowanceSenderToSpenderHash] = 0;
    } else {
      uintStorage[allowanceSenderToSpenderHash] = oldValue.sub(subtractedValue);
    }
    Approval(msg.sender, spender, allowance(msg.sender, spender));
  }

  function mint(address to, uint256 value) public {
    bytes32 balanceToHash = keccak256("balance", to);
    bytes32 totalSupplyHash = keccak256("totalSupply");

    uintStorage[balanceToHash] = balanceOf(to).add(value);
    uintStorage[totalSupplyHash] = totalSupply().add(value);
    Transfer(0x0, to, value);
  }
}