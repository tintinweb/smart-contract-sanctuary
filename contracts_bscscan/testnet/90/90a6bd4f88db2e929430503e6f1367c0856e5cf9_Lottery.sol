/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

pragma solidity ^0.4.17;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require (msg.value == .01 ether);
        players.push(msg.sender);
    }

    function random() private view returns (uint256){
        return uint(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public restricted {
         uint256 index = random() % players.length;
            players[index].transfer(this.balance * 9 / 100);
            msg.sender.transfer(this.balance);
            players  = new address[](0);
    }

    function getPlayers() public view returns(address[]){
        return players;
    }
    function getPrize() public view returns(uint256){
       return this.balance;
    }
    

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}