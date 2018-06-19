pragma solidity ^0.4.0;

contract Dealer {

    address public pitboss;
    uint public constant ceiling = 0.25 ether;

    event Deposit(address indexed _from, uint _value);

    function Dealer() public {
      pitboss = msg.sender;
    }

    function () public payable {
      Deposit(msg.sender, msg.value);
    }

    modifier pitbossOnly {
      require(msg.sender == pitboss);
      _;
    }

    function cashout(address winner, uint amount) public pitbossOnly {
      winner.transfer(amount);
    }

    function overflow() public pitbossOnly {
      require (this.balance > ceiling);
      pitboss.transfer(this.balance - ceiling);
    }

    function kill() public pitbossOnly {
      selfdestruct(pitboss);
    }

}