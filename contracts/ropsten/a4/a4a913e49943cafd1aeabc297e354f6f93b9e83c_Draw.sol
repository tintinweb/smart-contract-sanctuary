pragma solidity ^0.4.18;


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




contract Draw is Ownable {

    address[2] private players;
    address public last_winner;
    uint public draw_number;
    uint public slots_left;
    uint private MAX_PLAYERS = players.length;
    uint private counter = 0;
    uint private t0 = now;
    uint private tdelta;
    uint private index;
    uint private owner_balance = 0 finney;

    function Draw() public {
        initGame();
        draw_number = 1;
        last_winner = address(0);
    }

    function initGame() internal {
        counter = 0;
        slots_left = MAX_PLAYERS;
        draw_number++;
        for (uint i = 0; i < players.length; i++) {
            players[i] = address(0);
        }
    }

    function () external payable {
        for (uint i = 0; i < players.length; i++) {
            require(players[i] != msg.sender);
        }
        joinGame();
    }

    function joinGame() public payable {
        require(msg.sender != owner);
        require(msg.value == 100 finney);
        require(counter < MAX_PLAYERS);

        players[counter] = msg.sender;
        counter++;
        slots_left = MAX_PLAYERS - counter;

        if (counter >= MAX_PLAYERS) {
            last_winner = endGame();
        }
    }

    function endGame() internal returns (address winner) {
        require(this.balance - owner_balance >= 200 finney);
        tdelta = now - t0;
        index = uint(tdelta % MAX_PLAYERS);
        t0 = now;
        winner = players[index];
        initGame();
        winner.transfer(195 finney);
        owner_balance = owner_balance + 5 finney;
    }

    function getBalance() public view onlyOwner returns (uint) {
        return owner_balance;
    }

    function withdrawlBalance() public onlyOwner {
        msg.sender.transfer(owner_balance);
        owner_balance = 0;
    }

}