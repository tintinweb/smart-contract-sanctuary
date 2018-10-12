pragma solidity ^0.4.24;


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
 * @title HouseAdmin
 * @dev The HouseAdmin contract has a signer address and a croupier address, and provides basic authorization control
 *      functions, this simplifies the implementation of "user permissions"
 */
contract HouseAdmin is Ownable {
  address public signer;
  address public croupier;

  event SignerTransferred(address indexed previousSigner, address indexed newSigner);
  event CroupierTransferred(address indexed previousCroupier, address indexed newCroupier);

  /**
   * @dev Throws if called by any account other than the signer or owner
   */
  modifier onlySigner() {
    require(msg.sender == signer || msg.sender == owner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the croupier or owner
   */
  modifier onlyCroupier() {
    require(msg.sender == croupier || msg.sender == owner);
    _;
  }

  /**
   * @dev The Signable constructor sets the original `signer` of the contract to the sender
   *      account
   */
  constructor() public {
    signer = msg.sender;
    croupier = msg.sender;
  }

  /**
   * @dev Allows the current signer to transfer control of the contract to a newSigner
   * @param _newSigner The address to transfer signership to
   */
  function transferSigner(address _newSigner) public onlySigner {
    _transferSigner(_newSigner);
  }

  /**
   * @dev Allows the current croupier to transfer control of the contract to a newCroupier
   * @param _newCroupier The address to transfer croupiership to
   */
  function transferCroupier(address _newCroupier) public onlyCroupier {
    _transferSigner(_newCroupier);
  }

  /**
   * @dev Transfers control of the contract to a newSigner.
   * @param _newSigner The address to transfer signership to.
   */
  function _transferSigner(address _newSigner) internal {
    require(_newSigner != address(0));
    emit SignerTransferred(signer, _newSigner);
    signer = _newSigner;
  }

  /**
   * @dev Transfers control of the contract to a newCroupier.
   * @param _newCroupier The address to transfer croupiership to.
   */
  function _transferCroupier(address _newCroupier) internal {
    require(_newCroupier != address(0));
    emit CroupierTransferred(croupier, _newCroupier);
    croupier = _newCroupier;
  }
}


contract Casino is Ownable, HouseAdmin {
  using SafeMath for uint;

  uint constant HOUSE_EDGE_PERCENT = 1;
  uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

  uint constant BET_AMOUNT_MIN = 0.01 ether;
  uint constant BET_AMOUNT_MAX = 1000 ether;

  uint constant BET_EXPIRATION_BLOCKS = 250;

  uint constant MAX_MASKABLE_MODULO = 40;
  uint constant MAX_BET_MASK = 2 ** MAX_MASKABLE_MODULO;

  // population count
  uint constant POPCOUNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
  uint constant POPCOUNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
  uint constant POPCOUNT_MODULO = 0x3F;

  uint public bankFund;

  struct Bet {
    uint8 modulo;
    uint64 choice;
    uint amount;
    uint winAmount;
    uint placeBlockNumber;
    bool isActive;
    address player;
  }

  mapping (uint => Bet) public bets;

  event LogParticipant(address indexed player, uint indexed modulo, uint choice, uint amount, uint commit);
  event LogClosedBet(address indexed player, uint indexed modulo, uint choice, uint reveal, uint result, uint amount, uint winAmount);
  event LogDistributeReward(address indexed addr, uint reward);
  event LogRecharge(address indexed addr, uint amount);
  event LogRefund(address indexed addr, uint amount);
  event LogDealerWithdraw(address indexed addr, uint amount);

  constructor() payable public {
    owner = msg.sender;
  }

  function placeBet(uint _choice, uint _modulo, uint _expiredBlockNumber, uint _commit, uint8 _v, bytes32 _r, bytes32 _s) payable external {
    Bet storage bet = bets[_commit];

    uint amount = msg.value;

    require(bet.player == address(0), "this bet is already exist");
    require(block.number <= _expiredBlockNumber, &#39;this bet has expired&#39;);
    require(amount >= BET_AMOUNT_MIN && amount <= BET_AMOUNT_MAX, &#39;bet amount out of range&#39;);

    // verify the signer and _expiredBlockNumber
    bytes32 msgHash = keccak256(abi.encodePacked(_expiredBlockNumber, _commit));
    require(ecrecover(msgHash, _v, _r, _s) == signer, "incorrect signer");

    uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;
    if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
      houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
    }

    uint populationCount;
    if (_modulo < MAX_MASKABLE_MODULO) {
      require(_choice < MAX_BET_MASK, "choice too large");
      populationCount = (_choice * POPCOUNT_MULT & POPCOUNT_MASK) % POPCOUNT_MODULO;
      require(populationCount < _modulo, "winning rate out of range");
    } else {
      require(_choice < _modulo, "choice large than modulo");
      populationCount = _choice;
    }

    uint winAmount = (amount - houseEdge).mul(_modulo) / populationCount;
    // lock winAmount into this contract. Make sure contract is solvent
    bankFund = bankFund.add(winAmount);

    require(bankFund <= address(this).balance, &#39;contract balance is not enough&#39;);

    bet.choice = uint64(_choice);
    bet.player = msg.sender;
    bet.placeBlockNumber = block.number;
    bet.amount = amount;
    bet.winAmount = winAmount;
    bet.isActive = true;
    bet.modulo = uint8(_modulo);

    emit LogParticipant(msg.sender, _modulo, _choice, amount, _commit);
  }

  function closeBet(uint _reveal) external onlyCroupier {
    uint commit = uint(keccak256(abi.encodePacked(_reveal)));
    Bet storage bet = bets[commit];

    require(bet.isActive, &#39;this bet is not active&#39;);

    uint amount = bet.amount;
    uint placeBlockNumber = bet.placeBlockNumber;
    uint modulo = bet.modulo;
    uint winAmount = 0;
    uint choice = bet.choice;
    address player = bet.player;

    require(block.number > placeBlockNumber, &#39;close bet block number is too low&#39;);
    require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, &#39;the block number is too low to query&#39;);

    uint result = uint(keccak256(abi.encodePacked(_reveal, blockhash(placeBlockNumber)))) % modulo;

    if (modulo <= MAX_MASKABLE_MODULO) {
      if (2 ** result & choice != 0) {
        winAmount = bet.winAmount;
        player.transfer(winAmount);
        emit LogDistributeReward(player, winAmount);
      }
    } else {
      if (result < choice) {
        winAmount = bet.winAmount;
        player.transfer(winAmount);
        emit LogDistributeReward(player, winAmount);
      }
    }

    // release winAmount deposit
    bankFund = bankFund.sub(bet.winAmount);
    bet.isActive = false;

    emit LogClosedBet(player, modulo, choice, _reveal, result, amount, winAmount);
  }

  function refundBet(uint _commit) external onlyCroupier {
    Bet storage bet = bets[_commit];

    uint amount = bet.amount;
    uint placeBlockNumber = bet.placeBlockNumber;
    address player = bet.player;

    require(bet.isActive, &#39;this bet is not active&#39;);
    require(block.number > placeBlockNumber + BET_EXPIRATION_BLOCKS, &#39;this bet has not expired&#39;);

    player.transfer(amount);
    // release winAmount deposit
    bankFund = bankFund.sub(bet.winAmount);
    bet.isActive = false;

    emit LogRefund(player, amount);
  }

  /**
   * @dev in order to let more people participant
   */
  function recharge() public payable {
    emit LogRecharge(msg.sender, msg.value);
  }

  /**
   * @dev owner can withdraw the remain ether
   */
  function withdraw(uint _amount) external onlyOwner {
    require(_amount <= address(this).balance - bankFund, &#39;cannot withdraw amount greater than (balance - bankFund)&#39;);
    owner.transfer(_amount);
    emit LogDealerWithdraw(owner, _amount);
  }

  /**
   * @dev get the balance which can be used
   */
  function getAvailableBalance() view public returns (uint) {
    return address(this).balance - bankFund;
  }
}