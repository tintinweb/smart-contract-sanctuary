pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: paradigm-subcontract-sdk/contracts/SubContract.sol

contract SubContract {
    using SafeMath for uint;

    string public makerArguments;
    string public takerArguments;

    function participate(bytes32[] makerData, bytes32[] takerData) public returns (bool) { return false; }
    function isValid(bytes32[] makerData) public view returns (bool) { return false; }
    function amountRemaining(bytes32[] makerData) public view returns (uint) { return 0; } //TODO: maybe?
}

// File: contracts/OrderGateway.sol

contract OrderGateway {

    constructor() public {
    }

    event Participation(address indexed subContract, string id);

    function participate(address subContract, string id, bytes32[] makerData, bytes32[] takerData) public returns (bool) {
        emit Participation(subContract, id);
        return SubContract(subContract).participate(makerData, takerData);
    }

    function isValid(address subContract, bytes32[] makerData) public view returns (bool) {
        return SubContract(subContract).isValid(makerData);
    }

    function amountRemaining(address subContract, bytes32[] makerData) public view returns (uint) {
        return SubContract(subContract).amountRemaining(makerData);
    }

    function makerArguments(address subContract) public view returns (string) {
        return SubContract(subContract).makerArguments();
    }

    function takerArguments(address subContract) public view returns (string) {
        return SubContract(subContract).takerArguments();
    }
}