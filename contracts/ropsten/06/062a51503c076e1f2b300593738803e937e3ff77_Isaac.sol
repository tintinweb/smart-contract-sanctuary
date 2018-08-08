pragma solidity ^0.4.24;

// source : https://github.com/OpenZeppelin/zeppelin-solidity/blob/release/v1.5.0/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// source : https://github.com/OpenZeppelin/zeppelin-solidity/blob/release/v1.5.0/contracts/ownership/Ownable.sol

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
  constructor() public {
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

contract Isaac is Ownable
{
  event fallback_event(uint256 timestamp);
  event withdraw_event(uint256 timestamp);

  using SafeMath for uint256;

  struct Game
  {
    uint256 sc_fees;

    uint256 start_time;
    uint256 end_time;

    uint256 selected_player;
  }

  Game game;

  mapping (address => uint256) public balances;

  address[] players;

  // constructor
  constructor()
  public
  {
    init();
  }

  // init function
  function init()
  internal
  {
    game.sc_fees = 0;
    game.start_time = 0;
    game.end_time = 9999999999;
    game.selected_player = 0;

    for(uint256 i=0 ; i < players.length ; i++)
    {
      address add = players[i];
      balances[add] = 0;
    }

    delete players;
  }

  // fallback function
  function ()
  external payable
  {
      require(now >= game.start_time);

      if(msg.value >= 0.001 ether && now <= game.end_time)
      {
        process_game();
      }
      if(now > game.end_time) // coment for tests
      {
        withdraw();
      }
  }

  // game function
  function process_game()
  internal
  {
    // start & end time
    if(game.start_time == 0)
    {
      game.start_time = now;
      game.end_time = game.start_time + 7 days;     // for prod
      /* game.end_time = game.start_time + 5 minutes;  // for dev */
    }

    if(now >= game.end_time - 1 hours)
    {
      game.end_time = game.end_time + 8 hours;
    }

    // sender balance
    if(balances[msg.sender] == 0)
    {
      players.push(msg.sender);
    }
    balances[msg.sender] += msg.value;

    uint256 _value = msg.value;

    // selected player
    uint256 _delta = _value.div(1000000000000000);
    game.selected_player += _delta;
    game.selected_player = game.selected_player % players.length;

    // sc_fees
    uint256 _fees = _value.mul(2);  // 2% commission
    _fees = _fees.div(100);

    game.sc_fees += _fees;

    emit fallback_event(now);
  }

  // withdraw function
  function withdraw()
  internal
  {
    msg.sender.transfer(msg.value);
    owner.transfer(game.sc_fees);
    players[game.selected_player].transfer(address(this).balance);

    init();

    emit withdraw_event(now);
  }

  function get_time()
  external view
  returns(uint256 date_now)
  {
    return (now);
  }

  function get_start_time()
  external view
  returns(uint256 date_start)
  {
    return (game.start_time);
  }

  function get_end_time()
  external view
  returns(uint256 date_end)
  {
    return (game.end_time);
  }

  function get_game_balance()
  external view
  returns(uint256 balance)
  {
    return (address(this).balance - game.sc_fees);
  }

  function get_game_fees()
  external view
  returns(uint256 fees)
  {
    return (game.sc_fees);
  }

  function get_selected_player()
  external view
  returns(uint256 selected_player)
  {
    return (game.selected_player);
  }

  function player_count()
  external view
  returns (uint256)
  {
    return players.length;
  }

  function get_player_address(uint256 index_)
  external view
  returns (address addr)
  {
    return players[index_];
  }

// pour le test
  function kill()
  external
  onlyOwner
  {
    selfdestruct(owner);
  }
}