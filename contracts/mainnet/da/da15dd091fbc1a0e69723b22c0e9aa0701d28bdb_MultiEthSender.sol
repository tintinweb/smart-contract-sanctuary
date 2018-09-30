pragma solidity ^0.4.23;

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

contract MultiEthSender {
    using SafeMath for uint256;
    address public owner;

    event Send(uint256 _amount, address indexed _receiver);

    modifier onlyOwner () {
        if (msg.sender == owner) _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function multiSendEth(uint256 amount, address[] list) public payable onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        uint256 total = amount.mul(uint256(list.length));
        if (total > balance) {
            return false;
        }
        for (uint i = 0; i < list.length; i++) {
            list[i].transfer(amount);
            // emit Send(amount, list[i]);
            // another way to write log
            bytes32 _id = 0x5ce4017cdf5be6a02f39ba5d91777cf13a304b9e024d038bca26189d148feeb9;
            log2(
                bytes32(amount),
                _id,
                bytes32(list[i])
            );
        }
        return true;
    }

    function () public payable {}
}