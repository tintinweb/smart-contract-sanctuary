pragma solidity ^0.4.22;

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

contract Raffle {
  using SafeMath for uint;

  address public owner;
  address[] private players;

  constructor() public {
    owner = msg.sender;
  }

  function buy() external payable {
      require(msg.value >= 0.01 ether, "Not enough ether to buy!");
      uint numberOfEntries = msg.value.div(0.01 ether);
      for (uint index = 0; index < numberOfEntries; index++) {
          players.push(msg.sender);
      }
  }

  function getPlayers() external view returns (address[]) {
      return players;
  }

  modifier onlyOwner() {
      require(msg.sender == owner, "Only owner can call this");
      _;
  } 

  function pickWinner() external onlyOwner {
      require(players.length > 0, "No players");

      uint index = random() % players.length;
      players[index].transfer(address(this).balance);
      players = new address[](0);
  }

  function random() private view returns (uint) {
      return uint(keccak256(block.difficulty, now, players));
  }
}