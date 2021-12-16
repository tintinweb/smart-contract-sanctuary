/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/Quiz.sol



/**
  UNSAFE - DO NOT USE IN PRODUCTION!!!
**/

pragma solidity >=0.8.0 <0.9.0;


contract Quiz {
  using SafeMath for uint256;

  address public owner;
  
  uint256 public startTime;
  uint256 public questionsCount;
  uint256 public minBuyInAmount = 0.1 ether;
  QuizStatus public status;

  mapping(address => mapping(uint256 => Answer)) public userAnsweredQuestions; // tracking answered questions for user
  mapping(uint => Question) public questions;
  mapping(address => bool) public joined; // track if address already joined quiz

  address[] public joinedParticipants;

  struct Answer {
    uint256 optionId;
    bool hasVoted;
  }

  struct Question {
    mapping(uint => string) options;
    string text;
    bytes32 correctAnswerHash;
    uint256 optionsCount;
  }

  enum QuizStatus {
    NotStarted, Active, Finished
  }

  event QuizEvaluated(address indexed winner, uint256 amount);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "caller not owner");
    _;
  }

  modifier activeQuiz() {
    require(status == QuizStatus.Active, "quiz not active");
    _;
  }

  modifier finishedQuiz() {
    require(status == QuizStatus.Finished, "quiz not yet finished");
    _;
  }

  modifier notStartedQuiz() {
    require(status == QuizStatus.NotStarted, "quiz already active or finished");
    _;
  }

  function addQuestion(
    string memory _questionText,
    string[] memory _options,
    bytes32 _correctAnswerHash
  ) public onlyOwner notStartedQuiz {
    // add the question
    Question storage question = questions[questionsCount];
    question.text = _questionText;
    question.correctAnswerHash = _correctAnswerHash;
    questionsCount++;

    // add question options
    for (uint i = 0; i < _options.length; i++) {
      string memory option = _options[i];

      question.options[question.optionsCount] = option;
      question.optionsCount++;
    }
  }

  function activateQuiz() public onlyOwner notStartedQuiz {
    status = QuizStatus.Active;
    startTime = block.timestamp;
  }

  function joinQuiz() public payable activeQuiz {
    require(msg.value == minBuyInAmount, "not enough ETH to join");

    joinedParticipants.push(msg.sender);
    joined[msg.sender] = true;
  }

  function vote(uint256 questionIndex, uint256 optionIndex) public activeQuiz {
    require(joined[msg.sender] == true, "need to join before voting");
    require(userAnsweredQuestions[msg.sender][questionIndex].hasVoted == false, "address already voted");

    userAnsweredQuestions[msg.sender][questionIndex] = Answer({ hasVoted: true, optionId: optionIndex });
  }

  function getQuestionOption(uint256 questionIndex, uint256 optionIndex) public view returns(string memory) {
    return questions[questionIndex].options[optionIndex];
  }

  function finishQuiz() public onlyOwner activeQuiz {
    status = QuizStatus.Finished;
  }

  function evaluateQuiz(uint256[] memory _correctOptions, string memory _salt) public onlyOwner finishedQuiz {
    for (uint256 i = 0; i < _correctOptions.length; i++) {
      uint256 qIdx = i;
      uint256 correctOption = _correctOptions[i];

      bytes32 h = keccak256(abi.encode(qIdx, correctOption, _salt));
      require(h == questions[qIdx].correctAnswerHash, "invalid correct answer hash");
    }

    // TODO add multiple winners
    address winner;
    uint256 winnerScore;

    for (uint256 i = 0; i < joinedParticipants.length; i++) {
      address participant = joinedParticipants[i];
      uint256 score = 0;

      for (uint256 qIdx = 0; qIdx < _correctOptions.length; qIdx++) {
        uint256 correctOption = _correctOptions[qIdx];
        Answer memory participantAnswer = userAnsweredQuestions[participant][qIdx];
        uint256 votedOption = participantAnswer.optionId;

        if (participantAnswer.hasVoted == true && correctOption == votedOption) {
          score++;
        }
      }

      if (score > winnerScore) {
        winner = participant;
        winnerScore = score;
      }
    }

    // there was no winner -> return funds to participants
    if (winner == address(0)) {
      transferFundsToParticipants();
    }

    emit QuizEvaluated(winner, address(this).balance);

    selfdestruct(payable(winner));
  }

  function releaseFunds() public {
    uint256 period = 1 days;
    require(block.timestamp >= startTime.add(period), "can not release funds yet");
    require(joined[msg.sender] == true, "only joined can release funds");

    transferFundsToParticipants();
  }

  function transferFundsToParticipants() private {
    for (uint256 i = 0; i < joinedParticipants.length; i++) {
      address payable participant = payable(joinedParticipants[i]);

      participant.transfer(minBuyInAmount);
    }
  }
}