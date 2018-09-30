pragma solidity ^0.4.24;

// <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fb948b9e95819e8b8b9e979295d6889497929f928f82bbcad5cac9d5cb">[email&#160;protected]</a> from NPM

/**
 * @title Signable
 * @dev The Signable contract has an signer address, and provides basic authorization control
 *      functions, this simplifies the implementation of "user permissions"
 */
contract Signable {
  address public signer;

  event SignershipTransferred(address indexed previousSigner, address indexed newSigner);

  /**
   * @dev Throws if called by any account other than the signer
   */
  modifier onlySigner() {
    require(msg.sender == signer);
    _;
  }

  /**
   * @dev The Signable constructor sets the original `signer` of the contract to the sender
   *      account
   */
  constructor() public {
    signer = msg.sender;
  }

  /**
   * @dev Allows the current signer to transfer control of the contract to a newSigner
   * @param _newSigner The address to transfer signership to
   */
  function transferSignership(address _newSigner) public onlySigner {
    _transferSignership(_newSigner);
  }
  
  /**
   * @dev Transfers control of the contract to a newSigner.
   * @param _newSigner The address to transfer signership to.
   */
  function _transferSignership(address _newSigner) internal {
    require(_newSigner != address(0));
    emit SignershipTransferred(signer, _newSigner);
    signer = _newSigner;
  }
}

/**
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

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

contract Casino is Ownable, Signable {

  uint constant HOUSE_EDGE_PERCENT = 2;
  uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

  uint constant BET_AMOUNT_MIN = 0.01 ether;
  uint constant BET_AMOUNT_MAX = 1000 ether;

  uint constant BET_EXPIRATION_BLOCKS = 250;

  uint public betNonce = 0;

  struct Bet {
    uint8 choice;
    uint8 modulo;
    uint  amount;
    uint  winAmount;
    uint  placeBlockNumber;
    address player;
  }
  mapping (uint => Bet) bets;

  event LogParticipant(address indexed player);
  event LogDistributeReward(address indexed addr, uint reward);
  event LogRecharge(address indexed addr, uint amount);

  constructor() public {
    owner = msg.sender;
  }

  function placeBet(uint _choice, uint _modulo, uint _expiredBlockNumber) payable external {
    Bet storage bet = bets[betNonce];

    uint amount = msg.value;

    require(block.number < _expiredBlockNumber, &#39;this bet has expired&#39;);
    require(amount > BET_AMOUNT_MIN && amount < BET_AMOUNT_MAX, &#39;bet amount out of range&#39;);

    uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

    if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
      houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
    }

    uint winAmount = (amount - houseEdge) * _modulo;

    require(winAmount <= address(this).balance, &#39;contract balance is not enough&#39;);

    bet.choice = uint8(_choice);
    bet.player = msg.sender;
    bet.placeBlockNumber = block.number;
    bet.amount = amount;
    bet.winAmount = winAmount;
    bet.modulo = uint8(_modulo);

    betNonce += 1;
  }

  function closeBet(uint _betNonce) external onlyOwner {
    Bet storage bet = bets[_betNonce];

    uint placeBlockNumber = bet.placeBlockNumber;
    uint modulo = bet.modulo;
    uint winAmount = bet.winAmount;
    uint choice = bet.choice;
    address player = bet.player;

    require (block.number > placeBlockNumber, &#39;close bet block number is too low&#39;);
    require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, &#39;the block number is too low to query&#39;);

    uint result = uint(keccak256(abi.encodePacked(now))) % modulo;

    if (choice == result) {
      player.transfer(winAmount);
      emit LogDistributeReward(player, winAmount);
    }
  }

  function refundBet(uint _betNonce) external onlyOwner {
    Bet storage bet = bets[_betNonce];

    uint placeBlockNumber = bet.placeBlockNumber;
    uint amount = bet.amount;
    address player = bet.player;

    require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, &#39;the block number is too low to query&#39;);

    player.transfer(amount);
  }

  /**
   * @dev in order to let more people participant
   */
  function recharge() public payable {
    emit LogRecharge(msg.sender, msg.value);
  }

}