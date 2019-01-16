pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/CoinPledge.sol

/// @title CoinPledge
/// @author Igor Yalovoy
/// @notice Reach your goals and have fun with friends
/// @dev All function calls are currently implement without side effects
/// @web: ylv.io
/// @email: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="70041f30091c065e191f">[email&#160;protected]</a>
/// @gitHub: https://github.com/ylv-io/coinpledge/tree/master
/// @twitter: https://twitter.com/ylv_io

// Proofs:
// Public commitment as a motivator for weight loss (https://onlinelibrary.wiley.com/doi/pdf/10.1002/mar.20316)


pragma solidity ^0.4.24;



contract CoinPledge is Ownable {

  using SafeMath for uint256;

  uint constant daysToResolve = 7 days;
  uint constant bonusPercentage = 50;
  uint constant serviceFeePercentage = 10;
  uint constant minBonus = 1 finney;

  struct Challenge {
    address user;
    string name;
    uint value;
    address mentor;
    uint startDate;
    uint time;
    uint mentorFee;

    bool successed;
    bool resolved;
  }

  struct User {
    address addr;
    string name;
  }

  // Events
  event NewChallenge(
    uint indexed challengeId,
    address indexed user,
    string name,
    uint value,
    address indexed mentor,
    uint startDate,
    uint time,
    uint mentorFee
  );

  event ChallengeResolved(
    uint indexed challengeId,
    address indexed user,
    address indexed mentor,
    bool decision
  );

  event BonusFundChanged(
    address indexed user,
    uint value
  );

  event NewUsername(
    address indexed addr,
    string name
  );


  event Donation(
    string name,
    string url,
    uint value,
    uint timestamp
  );

  /// @notice indicated is game over or not
  bool public isGameOver;

  /// @notice All Challenges
  Challenge[] public challenges;

  mapping(uint => address) public challengeToUser;
  mapping(address => uint) public userToChallengeCount;

  mapping(uint => address) public challengeToMentor;
  mapping(address => uint) public mentorToChallengeCount;

  /// @notice All Users
  mapping(address => User) public users;
  address[] public allUsers;
  mapping(string => address) private usernameToAddress;
  
  /// @notice User&#39;s bonuses
  mapping(address => uint) public bonusFund;

  /// @notice Can access only if game is not over
  modifier gameIsNotOver() {
    require(!isGameOver, "Game should be not over");
    _;
  }

  /// @notice Can access only if game is over
  modifier gameIsOver() {
    require(isGameOver, "Game should be over");
    _;
  }

  /// @notice Get Bonus Fund For User
  function getBonusFund(address user)
  external
  view
  returns(uint) {
    return bonusFund[user];
  }

  /// @notice Get Users Lenght
  function getUsersCount()
  external
  view
  returns(uint) {
    return allUsers.length;
  }

  /// @notice Get Challenges For User
  function getChallengesForUser(address user)
  external
  view
  returns(uint[]) {
    require(userToChallengeCount[user] > 0, "Has zero challenges");

    uint[] memory result = new uint[](userToChallengeCount[user]);
    uint counter = 0;
    for (uint i = 0; i < challenges.length; i++) {
      if (challengeToUser[i] == user)
      {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  /// @notice Get Challenges For Mentor
  function getChallengesForMentor(address mentor)
  external
  view
  returns(uint[]) {
    require(mentorToChallengeCount[mentor] > 0, "Has zero challenges");

    uint[] memory result = new uint[](mentorToChallengeCount[mentor]);
    uint counter = 0;
    for (uint i = 0; i < challenges.length; i++) {
      if (challengeToMentor[i] == mentor)
      {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
  
  /// @notice Ends game
  function gameOver()
  external
  gameIsNotOver
  onlyOwner {
    isGameOver = true;
  }

  /// @notice Set Username
  function setUsername(string name)
  external
  gameIsNotOver {
    require(bytes(name).length > 2, "Provide a name longer than 2 chars");
    require(bytes(name).length <= 32, "Provide a name shorter than 33 chars");
    require(users[msg.sender].addr == address(0x0), "You already have a name");
    require(usernameToAddress[name] == address(0x0), "Name already taken");

    users[msg.sender] = User(msg.sender, name);
    usernameToAddress[name] = msg.sender;
    allUsers.push(msg.sender);

    emit NewUsername(msg.sender, name);
  }

  /// @notice Creates Challenge
  function createChallenge(string name, string mentor, uint time, uint mentorFee)
  external
  payable
  gameIsNotOver
  returns (uint retId) {
    require(msg.value >= 0.01 ether, "Has to stake more than 0.01 ether");
    require(mentorFee >= 0 ether, "Can&#39;t be negative");
    require(mentorFee <= msg.value, "Can&#39;t be bigger than stake");
    require(bytes(mentor).length > 0, "Has to be a mentor");
    require(usernameToAddress[mentor] != address(0x0), "Mentor has to be registered");
    require(time > 0, "Time has to be greater than zero");

    address mentorAddr = usernameToAddress[mentor];

    require(msg.sender != mentorAddr, "Can&#39;t be mentor to yourself");

    uint startDate = block.timestamp;
    uint id = challenges.push(Challenge(msg.sender, name, msg.value, mentorAddr, startDate, time, mentorFee, false, false)) - 1;

    challengeToUser[id] = msg.sender;
    userToChallengeCount[msg.sender]++;

    challengeToMentor[id] = mentorAddr;
    mentorToChallengeCount[mentorAddr]++;

    emit NewChallenge(id, msg.sender, name, msg.value, mentorAddr, startDate, time, mentorFee);

    return id;
  }

  /// @notice Resolves Challenge
  function resolveChallenge(uint challengeId, bool decision)
  external
  gameIsNotOver {
    Challenge storage challenge = challenges[challengeId];
    
    require(challenge.resolved == false, "Challenge already resolved.");

    // if more time passed than endDate + daysToResolve, then user can resolve himself
    if(block.timestamp < (challenge.startDate + challenge.time + daysToResolve))
      require(challenge.mentor == msg.sender, "You are not the mentor for this challenge.");
    else require((challenge.user == msg.sender) || (challenge.mentor == msg.sender), "You are not the user or mentor for this challenge.");

    uint mentorFee;
    uint serviceFee;
    
    address user = challengeToUser[challengeId];
    address mentor = challengeToMentor[challengeId];

    // write decision
    challenge.successed = decision;
    challenge.resolved = true;

    uint remainingValue = challenge.value;

    // mentor & service fee
    if(challenge.mentorFee > 0) {
      serviceFee = challenge.mentorFee.div(100).mul(serviceFeePercentage);
      mentorFee = challenge.mentorFee.div(100).mul(100 - serviceFeePercentage);
    }
    
    if(challenge.mentorFee > 0)
      remainingValue = challenge.value.sub(challenge.mentorFee);

    uint valueToPay;

    if(decision) {
      // value to pay back to user
      valueToPay = remainingValue;
      // credit bouns if any
      uint currentBonus = bonusFund[user];
      if(currentBonus > 0)
      {
        uint bonusValue = bonusFund[user].div(100).mul(bonusPercentage);
        if(currentBonus <= minBonus)
          bonusValue = currentBonus;
        bonusFund[user] -= bonusValue;
        emit BonusFundChanged(user, bonusFund[user]);

        valueToPay += bonusValue;
      }
    }
    else {
      bonusFund[user] += remainingValue;
      emit BonusFundChanged(user, bonusFund[user]);
    }

    // pay back to the challenger
    if(valueToPay > 0)
      user.transfer(valueToPay);

    if(mentorFee > 0)
      mentor.transfer(mentorFee);

    if(serviceFee > 0)
      owner().transfer(serviceFee);

    emit ChallengeResolved(challengeId, user, mentor, decision);
  }

  function withdraw()
  external
  gameIsOver {
    require(bonusFund[msg.sender] > 0, "You do not have any funds");

    uint funds = bonusFund[msg.sender];
    bonusFund[msg.sender] = 0;
    msg.sender.transfer(funds);
  }

  function donate(string name, string url)
  external
  payable
  gameIsNotOver {
    owner().transfer(msg.value);
    emit Donation(name, url, msg.value, block.timestamp);
  }
}