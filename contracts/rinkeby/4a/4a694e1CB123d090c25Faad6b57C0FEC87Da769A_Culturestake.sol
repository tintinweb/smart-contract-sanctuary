pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import './Admin.sol';
import './Question.sol';
import "./Proxy.sol";

/// @title Culturestake admin hub
/// @author Sarah Friend @ana0
/// @notice Deploys questions and manages festivals and voting booths within the culturestake system
contract Culturestake is Admin {
  using SafeMath for uint256;

  mapping (bytes32 => Festival) festivals;
  mapping (bytes32 => QuestionStruct) questions;
  mapping (address => VotingBooth) votingBooths;
  mapping (address => bool) public questionsByAddress;
  address public questionMasterCopy;
  address public voteRelayer;

  struct VotingBooth {
    bool inited;
    bool deactivated;
    bytes32 festival;
    mapping (uint256 => bool) nonces;
  }

  struct Festival {
    bool inited;
    bool deactivated;
    uint256 startTime;
    uint256 endTime;
  }

  struct QuestionStruct {
    bool inited;
    bool deactivated;
    address contractAddress;
    bytes32 festival;
    uint256 maxVoteTokens;
  }

  event InitQuestion(bytes32 indexed question, bytes32 indexed festival, address indexed questionAddress);
  event InitFestival(bytes32 indexed festival, uint256 startTime, uint256 endTime);
  event InitVotingBooth(bytes32 indexed festival, address indexed boothAddress);

  event DeactivateQuestion(bytes32 indexed question);
  event DeactivateFestival(bytes32 indexed festival);
  event DeactivateVotingBooth(address indexed boothAddress);

  event ProxyCreation(Proxy proxy);

  /// @return True if the caller is a question contract deployed by this admin hub
  modifier onlyQuestions() {
      require(questionsByAddress[msg.sender], "Method can only be called by questions");
      _;
  }

  /// @dev The owners array is used in the Admin contract this inherits from
  /// @param _owners An array of all addresses that have admin permissions over this contract
  /// @param _questionMasterCopy The address of the master copy that holds the logic for each question
  constructor(address[] memory _owners, address _questionMasterCopy) public Admin(_owners) {
    questionMasterCopy = _questionMasterCopy;
  }

  /// @dev Provided the setup parameters of a question contract don't change, the logic on future questions can be updated
  /// @param _newQuestionMasterCopy The address of the master copy to use for new questions
  function setQuestionMasterCopy(address _newQuestionMasterCopy) public authorized {
    questionMasterCopy = _newQuestionMasterCopy;
  }

  /// @dev The vote relayer is the server key that sends votes to question contracts. It should be cycled periodically and must be set before any votes can take place
  /// @param _newVoteRelayer The address of the new vote relayer
  function setVoteRelayer(address _newVoteRelayer) public authorized {
    voteRelayer = _newVoteRelayer;
  }

  /// @dev Used by question contracts to validate the vote relayer
  /// @param _sender The address being challenged
  /// @return True if the address given is the current vote relayer
  function isVoteRelayer(address _sender) public view returns (bool) {
    return _sender == voteRelayer;
  }

  /// @dev Used by server to validate vote data
  /// @param _festival The festival chain id
  /// @return True if the festival is currently open for voting
  function isActiveFestival(bytes32 _festival) public view returns (bool) {
    // case festival has not been inited
    if (!festivals[_festival].inited) return false;
    // case festival has been manually deactivated
    if (festivals[_festival].deactivated) return false;
    // case festival hasn't started
    if (festivals[_festival].startTime > block.timestamp) return false;
    // case festival has ended
    if (festivals[_festival].endTime < block.timestamp) return false;
    return true;
  }

  /// @dev Used by server to validate vote data - the booth signs the answers array and a nonce
  /// @param _festival The festival chain id
  /// @param _answers An array of answer ids
  /// @param _nonce A random number added to the answers array by the booth - prevents a booth signature from being used for more than one vote package
  /// @param sigV Booth signature data
  /// @param sigR Booth signature data
  /// @param sigS Booth signature data
  /// @return True if the signature provided is a signature of an active booth, signing the correct data, and active on the claimed festival
  function checkBoothSignature(
    bytes32 _festival,
    bytes32[] memory _answers,
    uint256 _nonce,
    uint8 sigV,
    bytes32 sigR,
    bytes32 sigS
  ) public view returns (address) {
      bytes32 h = getHash(_answers, _nonce);
      address addressFromSig = ecrecover(h, sigV, sigR, sigS);
      // case is not a booth
      if (!votingBooths[addressFromSig].inited) return address(0);
      // case was manually deactivated
      if (votingBooths[addressFromSig].deactivated) return address(0);
      // case is from the wrong festival
      if (!(votingBooths[addressFromSig].festival == _festival)) return address(0);
      // case nonce has been used
      if (!isValidVotingNonce(addressFromSig, _nonce)) return address(0);
      return addressFromSig;
  }

  /// @param _answers An array of answer ids
  /// @param _nonce A random number added to the answers array by the booth
  /// @return Keccak sha3 of the packed answers array and nonce
  function getHash(
    bytes32[] memory _answers,
    uint256 _nonce
  ) public pure returns (bytes32) {
    return keccak256(abi.encode(_answers, _nonce));
  }

  /// @dev Destructive method that burns the nonce
  /// @param _booth The booth using the nonce (nonces are stored per booth)
  /// @param _nonce The nonce
  function _burnNonce(address _booth, uint256 _nonce) internal {
    votingBooths[_booth].nonces[_nonce] = true;
  }

  /// @dev Destructive method that burns the nonce - marked onlyQuestions to prevent griefing
  /// @param _booth The booth using the nonce (nonces are stored per booth)
  /// @param _nonce The nonce
  function burnNonce(address _booth, uint256 _nonce) public onlyQuestions {
    _burnNonce(_booth, _nonce);
  }

  /// @dev Registers a voting booth with this contract
  /// @param _festival The festival chain is
  /// @param _booth The booth address
  function initVotingBooth(
    bytes32 _festival,
    address _booth
  ) public authorized {
      // booth are only for one festival
      require(festivals[_festival].inited, 'Festival must be inited');
      // booths are one-time use
      require(!votingBooths[_booth].inited, 'Voting booths can only be inited once');
      votingBooths[_booth].inited = true;
      votingBooths[_booth].festival = _festival;
      emit InitVotingBooth(_festival, _booth);
  }

  /// @dev Destructive method, signatures from deactivated booths can not be used to vote
  /// @param _booth The booth address
  function deactivateVotingBooth(address _booth) public authorized {
    votingBooths[_booth].deactivated = true;
    emit DeactivateVotingBooth(_booth);
  }

  /// @dev Getter for a voting booth struct
  /// @param _booth The booth address
  /// @return Bool for if the booth was initialized
  /// @return Bool for the if the booth was deactivated
  /// @return Chain id of the festival the booth was registered to
  function getVotingBooth(address _booth) public view returns (bool, bool, bytes32) {
    return (votingBooths[_booth].inited, votingBooths[_booth].deactivated, votingBooths[_booth].festival);
  }

  /// @dev Used by the server to validate vote data
  /// @param _booth The booth address
  /// @param _nonce The nonce
  /// @return True if the challenged booth has not used this nonce
  function isValidVotingNonce(address _booth, uint256 _nonce) public view returns (bool) {
    return (!votingBooths[_booth].nonces[_nonce]);
  }

  /// @dev Creates a festival
  /// @param _festival The chain id of the festival
  /// @param _startTime Timestamp for festival start
  /// @param _endTime Timestamp for festival end
  function initFestival(
    bytes32 _festival,
    uint256 _startTime,
    uint256 _endTime
  ) public authorized {
    // this method can only be called once per festival chain id
    require(!festivals[_festival].inited, 'Festival must be inited');
    require(_startTime >= block.timestamp);
    require(_endTime > _startTime);
    festivals[_festival].inited = true;
    festivals[_festival].startTime = _startTime;
    festivals[_festival].endTime = _endTime;
    emit InitFestival(_festival, _startTime, _endTime);
  }

  /// @dev Destructive method, questions from deactivated festivals cannot be voted on
  /// @param _festival The chain id of the festival
  function deactivateFestival(bytes32 _festival) public authorized {
    festivals[_festival].deactivated = true;
    emit DeactivateFestival(_festival);
  }

  /// @dev Getter for a festival struct
  /// @param _festival The chain id of the festival
  /// @return Bool for if the festival was initialized
  /// @return Bool for the if the festival was deactivated
  /// @return Timestamp for festival start time
  /// @return Timestamp for festival end time
  function getFestival(bytes32 _festival) public view returns (bool, bool, uint256, uint256) {
    return (
      festivals[_festival].inited,
      festivals[_festival].deactivated,
      festivals[_festival].startTime,
      festivals[_festival].endTime
    );
  }

  /// @dev Destructive method, deactivated questions cannot be voted on and do not pass the onlyQuestions modifier
  /// @param _question The question chain id
  function deactivateQuestion(bytes32 _question) public authorized {
    questions[_question].deactivated = true;
    questionsByAddress[questions[_question].contractAddress] = false;
    emit DeactivateQuestion(_question);
  }

  /// @dev Deploys a question contract
  /// @param _question The question chain id
  /// @param _maxVoteTokens The amount of vote tokens given to each voter per answer
  /// @param _festival The festival chain id
  function initQuestion(
    bytes32 _question,
    uint256 _maxVoteTokens,
    bytes32 _festival
  ) public authorized {
    require(festivals[_festival].inited, 'Festival must be inited');
    // this method can only be called once per question chain id
    require(!questions[_question].inited, 'This question can only be inited once');

    // encode the data used in the question setup method
    bytes memory data = abi.encodeWithSelector(
      0x2fa97de7, address(this), _question, _maxVoteTokens, _festival
    );

    // question contracts are a proxy of question master copy
    Proxy questionContract = createProxy(data);
    // store the question so it can be looked up by address in the onlyQuestions modifier
    questionsByAddress[address(questionContract)] = true;

    // store the question struct
    questions[_question].inited = true;
    questions[_question].festival = _festival;
    questions[_question].contractAddress = address(questionContract);
    questions[_question].maxVoteTokens = _maxVoteTokens;

    emit InitQuestion(_question, _festival, address(questionContract));
  }

  /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
  /// @param data Payload for message call sent to new proxy contract.
  /// @return The created proxy
  function createProxy(bytes memory data)
      internal
      returns (Proxy proxy)
  {
      proxy = new Proxy(questionMasterCopy);
      if (data.length > 0)
          // solium-disable-next-line security/no-inline-assembly
          assembly {
              if eq(call(gas, proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
          }
      emit ProxyCreation(proxy);
  }

  /// @dev Getter for a question struct
  /// @param _question The question chain is
  /// @return Bool for if the booth was initialized
  /// @return Bool for if the booth was deactivated
  /// @return The address of the question contract
  /// @return The festival chain id the question is associated with
  /// @return The maximum tokens given in this question per answer
  function getQuestion(bytes32 _question) public view returns (bool, bool, address, bytes32, uint256) {
    return (
      questions[_question].inited,
      questions[_question].deactivated,
      questions[_question].contractAddress,
      questions[_question].festival,
      questions[_question].maxVoteTokens
    );
  }
}

pragma solidity ^0.5.0;

contract CulturestakeI {
    function burnNonce(address, uint256) public;
    function isOwner(address) public view returns (bool);
    function isVoteRelayer(address) public view returns (bool);
    function questionsByAddress(address) public returns (bool);
    function isActiveFestival(bytes32) public returns (bool);
    function getQuestion(bytes32) public view returns (bool, bool, address, bytes32, uint256);
}

pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import './interfaces/CulturestakeI.sol';

contract Question {
  address private masterCopy;

  using SafeMath for uint256;

  address public admin;
  bytes32 public id;
  bytes32 public festival;
  uint256 public maxVoteTokens;
  uint256 public votes;
  bool public configured;
  mapping (bytes32 => Answer) answers;
  mapping (address => bool) public hasVoted;

  struct Answer {
    bool inited;
    bool deactivated;
    bytes32 answer;
    uint256 votePower;
    uint256 voteTokens;
    uint256 votes;
  }

  event InitAnswer(bytes32 questionId, bytes32 indexed answer);
  event DeactivateAnswer(bytes32 questionId, bytes32 indexed answer);
  event Vote(
    bytes32 questionId,
    bytes32 indexed answer,
    uint256 voteTokens,
    uint256 votePower,
    uint256 votes,
    address booth,
    uint256 nonce
  );

  /// @dev Asserts that the caller is an admin of the culturestake hub
  modifier authorized() {
      require(CulturestakeI(admin).isOwner(msg.sender), "Must be an admin" );
      _;
  }

  /// @dev Asserts that the caller is the vote relayer in the culturestake hub
  modifier onlyVoteRelayer() {
      require(CulturestakeI(admin).isVoteRelayer(msg.sender), "Must be the vote relayer" );
      _;
  }

  /// @dev Sets the main configuration params of the question - this is done primarily to avoid modifying the formally verified proxy
  /// @param _admin Address set automatically to be the culturestake hub that deployed this question
  /// @param _question The question chain id
  /// @param _maxVoteTokens The amount of vote tokens given to each voter per answer
  /// @param _festival The festival chain id the question is associated with
  /// @return Bool for if the booth was initialized
  function setup(
    address _admin,
    bytes32 _question,
    uint256 _maxVoteTokens,
    bytes32 _festival
  ) public {
    // method can only be called once
    require(!configured, "This question has already been configured");
    admin = _admin;
    id = _question;
    maxVoteTokens = _maxVoteTokens;
    festival = _festival;
    configured = true;
  }

  /// @dev Calls to culturestake hub to check that this question hasn't been shut down
  /// @return True if this question has not been manually deactivated
  function thisQuestionIsActive() public view returns (bool) {
    (, bool deactivated, , , ) = CulturestakeI(admin).getQuestion(id);
    return !deactivated;
  }

  /// @dev Registers a new answer for this question
  /// @param _answer The answer chain id
  function initAnswer(bytes32 _answer) public authorized {
    require(configured, "Question must be configured");
    require(thisQuestionIsActive(), "Question must be active");
    answers[_answer].inited = true;
    answers[_answer].answer = _answer;
    emit InitAnswer(id, _answer);
  }

  /// @dev Destructive method, removes an answer from voting
  /// @param _answer The answer chain id
  function deactivateAnswer(bytes32 _answer) public authorized {
    require(configured, "Question must be configured");
    answers[_answer].deactivated = true;
    emit DeactivateAnswer(id, _answer);
  }

  /// @dev Getter for a answer struct
  /// @param _answer The answer chain is
  /// @return Bool for if the answer was initialized
  /// @return Bool for if the answer was deactivated
  /// @return The total vote power this answer received
  /// @return The total vote tokens this answer received
  /// @return The total users who engaged with this answer
  function getAnswer(bytes32 _answer) public view returns (bool, bool, uint256, uint256, uint256) {
    return (
      answers[_answer].inited,
      answers[_answer].deactivated,
      answers[_answer].votePower,
      answers[_answer].voteTokens,
      answers[_answer].votes
    );
  }

  /// @dev Records a vote without checking the voting booth signature on chain, can only be called by vote relayer
  /// @param _answers An array of the answer chain ids
  /// @param _answers An array of the vote tokens awarded to each answer, in the same order
  /// @param _answers An array of the vote powers awarded to each answer, in the same order
  /// @param _answers The address of the booth that the vote was placed at
  /// @param _answers The nonce that this vote used
  function recordUnsignedVote(
    bytes32[] memory _answers,
    uint256[] memory _voteTokens,
    uint256[] memory _votePowers,
    address _booth,
    uint256 _nonce
  ) public onlyVoteRelayer returns (bool) {
    require(configured, "Question must be configured");
    // this method assumes most checks have been done by an admin
    for (uint i = 0; i < _answers.length; i++) {
      answers[_answers[i]].votes = answers[_answers[i]].votes.add(1);
      answers[_answers[i]].voteTokens = answers[_answers[i]].voteTokens.add(_voteTokens[i]);
      answers[_answers[i]].votePower = answers[_answers[i]].votePower.add(_votePowers[i]);
      // the first time a nonce is used it is burned, but the vote relayer can still transit the other
      // half of the vote package because this vote method will not fail if nonce has already
      // been burned. This means further vote sttempts sent to the server will fail, but the
      // rest of the current vote can still be completed
      CulturestakeI(admin).burnNonce(_booth, _nonce);
      emit Vote(id, _answers[i], _voteTokens[i], _votePowers[i], answers[_answers[i]].votes, _booth, _nonce);
    }
    return true;
  }
}

pragma solidity >=0.5.0 <0.7.0;

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <[email protected]>
interface IProxy {
    function masterCopy() external view returns (address);
}

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract Proxy {

    // masterCopy always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal masterCopy;

    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    function ()
        external
        payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}

pragma solidity ^0.5.0;

contract Admin {
    event AddedOwner(address owner);
    event RemovedOwner(address owner);

    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 ownerCount;

    constructor(address[] memory _owners) public {
        setupOwners(_owners);
    }

    modifier authorized() {
        require(isOwner(msg.sender), "Method can only be called by owner");
        _;
    }

    function setupOwners(address[] memory _owners)
        internal
    {
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "Duplicate owner address provided");
            owners[currentOwner] = owner;
            currentOwner = owner;
            emit AddedOwner(owner);
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
    }

    function addOwner(address owner)
        public
        authorized
    {
        // Owner address cannot be null.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "Address is already an owner");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
    }

    function removeOwner(address prevOwner, address owner)
        public
        authorized
    {
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == owner, "Invalid prevOwner, owner pair provided");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
    }

    function swapOwner(address prevOwner, address oldOwner, address newOwner)
        public
        authorized
    {
        // Owner address cannot be null.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS, "Invalid owner address provided");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "Address is already an owner");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == oldOwner, "Invalid prevOwner, owner pair provided");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    function isOwner(address owner)
        public
        view
        returns (bool)
    {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    function getOwners()
        public
        view
        returns (address[] memory)
    {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while(currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index ++;
        }
        return array;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}