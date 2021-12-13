// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
}

struct Verification {
    address INITIATOR;
    uint256 ID;
    uint256 BLOCK_NUMBER;
    uint256 REWARD_AMOUNT;
    uint256 REWARD_WALLET_AMOUNT;
    uint256 SCORE;
    string QUESTION;
    string[] ANSWERS;
    uint256 NUMBER_OF_ANSWER_SLOTS;
    address[] PARTICIPATORS;
    address[] WINNERS;
    address[] LOOSERS;
    string DATA;
    uint256 QUESTION_ID;
    uint256 STATUS;
    uint256 CDT_PER_QUESTION;
}

struct Participation {
    uint256 VERIFICATION_ID;
    uint256 REWARD_AMOUNT;
    uint256 BURNT_WARRANTY;
}

struct Validator {
    address WALLET;
    uint256 AMOUNT;
    uint256 WARRANTY_AMOUNT;
    uint256 LOCKED_WARRANTY_AMOUNT;
    uint256 BURNT_WARRANTY;
    Participation[] PARTICICATIONS;
}

struct QuestionWithAnswer {
    uint256 ID;
    string QUESTION;
    string[] ANSWERS;
    string ANSWER;
}

struct Answer {
    address WALLET;
    string ANSWER;
}

library Numeric {
    function isNumeric(string memory _value) internal pure returns (bool _ret) {
        bytes memory _bytesValue = bytes(_value);
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            if (uint8(_bytesValue[i]) < 48 && uint8(_bytesValue[i]) > 57) {
                return false;
            }
        }
        return true;
    }
}

/**
 * @dev Implementation of the {CheckDot Smart Contract Verification} Contract Version 1
 * 
 * Simple schema representation:
 *
 * o------o       o--------------------o       o------------o
 * | ASKs | ----> | Validators answers | ----> | Evaluation |
 * o------o       o--------------------o       o------------o
 *
 */
contract CheckDotVerificationProtocolContract {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using Numeric for string;

    /**
     * @dev Manager of the contract.
     */
    address private _owner;

    /**
     * @dev Address of the CDT token hash: {CDT address}.
     */
    IERC20 private _cdtToken;

    struct VerificationSettings {
        uint256 MAX_CAP;
        uint256 MIN_CAP;
        uint256 CDT_PER_QUESTION;
        /**
        * @dev Percentage of Decentralized fees: 1% (0.5% for CheckDot - 0.5% are burnt).
        */
        uint256 SERVICE_FEE;
    }

    struct VerificationStatistics {
        uint256 TOTAL_CDT_BURNT;
        uint256 TOTAL_CDT_FEE;
        uint256 TOTAL_CDT_WARRANTY;
    }

    VerificationSettings public _settings;

    VerificationStatistics public _statistics;

    uint256 private _checkDotCollectedFeesAmount = 0;

    // MAPPING

    uint256 private                                _verificationsIndex;
    mapping(uint256 => Verification) private       _verifications;
    mapping(uint256 => Answer[]) private           _verificationsAnswers;
    mapping(address => Validator) private          _validators;
    mapping(uint256 => QuestionWithAnswer) private _questions;

    event NewVerification(uint256 id, address initiator);
    event UpdateVerification(uint256 id, address initiator);

    constructor(address cdtTokenAddress) {
        require(msg.sender != address(0), "Deploy from the zero address");
        _verificationsIndex = 1;
        _cdtToken = IERC20(cdtTokenAddress);
        _owner = msg.sender;
        _settings.CDT_PER_QUESTION = 10**18;
        _settings.MIN_CAP = 5;
        _settings.MAX_CAP = 500;
        _settings.SERVICE_FEE = 1;
    }

    /**
     * @dev Check that the transaction sender is the CDT owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can do this action");
        _;
    }

    // Global SECTION
    
    function getVerificationsLength() public view returns (uint256) {
        return _verificationsIndex;
    }

    function getSettings() public view returns (VerificationSettings memory) {
        return _settings;
    }

    function getStatistics() public view returns (VerificationStatistics memory) {
        return _statistics;
    }

    // VIEW SECTION

    function getMyValidator() public view returns (Validator memory) {
        Validator storage validator = _validators[msg.sender];
        
        return validator;
    }

    function getVerification(uint256 verificationIndex) public view returns (Verification memory) {
        require(verificationIndex < _verificationsIndex, "Verification not found");
        
        return _verifications[verificationIndex];
    }

    function getVerifications(int256 page, int256 pageSize) public view returns (Verification[] memory) {
        uint256 verificationLength = getVerificationsLength();
        int256 queryStartVerificationIndex = int256(verificationLength).sub(pageSize.mul(page)).add(pageSize).sub(1);
        require(queryStartVerificationIndex >= 0, "Out of bounds");
        int256 queryEndVerificationIndex = queryStartVerificationIndex.sub(pageSize);
        if (queryEndVerificationIndex < 0) {
            queryEndVerificationIndex = 0;
        }
        int256 currentVerificationIndex = queryStartVerificationIndex;
        require(uint256(currentVerificationIndex) <= verificationLength.sub(1), "Out of bounds");
        Verification[] memory results = new Verification[](uint256(currentVerificationIndex - queryEndVerificationIndex));
        uint256 index = 0;

        for (currentVerificationIndex; currentVerificationIndex > queryEndVerificationIndex; currentVerificationIndex--) {
            uint256 currentVerificationIndexAsUnsigned = uint256(currentVerificationIndex);
            if (currentVerificationIndexAsUnsigned <= verificationLength.sub(1)) {
                results[index] = _verifications[currentVerificationIndexAsUnsigned];
            }
            index++;
        }
        return results;
    }

    // END VIEW SECTION

    // PROTOCOL SECTION
    function addWarranty(uint256 amount) public {
        Validator storage validator = _validators[msg.sender];

        require(_cdtToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(_cdtToken.transferFrom(msg.sender, address(this), amount) == true, "Error transfer");
        validator.WALLET = msg.sender;
        validator.WARRANTY_AMOUNT += amount;
    }

    function init(uint256 questionId, string calldata data, uint256 numberOfAnswerCap) public {
        QuestionWithAnswer storage question = _questions[questionId];

        require(question.ID == questionId, "Question not found");
        require(bytes(data).length <= 2000, "Top long data length");
        require(numberOfAnswerCap >= _settings.MIN_CAP && numberOfAnswerCap <= _settings.MAX_CAP, "Invalid cap");

        uint256 rewardsAmount = _settings.CDT_PER_QUESTION.mul(numberOfAnswerCap);
        uint256 checkDotFees = rewardsAmount.mul(_settings.SERVICE_FEE).div(100);
        uint256 transactionCost = checkDotFees + rewardsAmount;

        require(_cdtToken.balanceOf(msg.sender) >= transactionCost, "Insufficient balance");
        require(_cdtToken.transferFrom(msg.sender, address(this), transactionCost) == true, "Error transfer");
        require(_cdtToken.burn(checkDotFees.div(2)) == true, "Error burn");
        _statistics.TOTAL_CDT_BURNT += checkDotFees.div(2);
        _statistics.TOTAL_CDT_FEE += checkDotFees;
        _checkDotCollectedFeesAmount += checkDotFees.div(2);
        uint256 index = _verificationsIndex++;
        Verification storage ask = _verifications[index];

        ask.INITIATOR = msg.sender;
        ask.ID = index;
        ask.BLOCK_NUMBER = block.number;
        ask.REWARD_AMOUNT = rewardsAmount;
        ask.REWARD_WALLET_AMOUNT = rewardsAmount;
        ask.NUMBER_OF_ANSWER_SLOTS = numberOfAnswerCap;
        ask.DATA = data;
        ask.QUESTION = question.QUESTION;
        for (uint i = 0; i < question.ANSWERS.length; i++) {
            ask.ANSWERS.push(question.ANSWERS[i]);
        }
        ask.QUESTION_ID = questionId;
        ask.STATUS = 1;
        ask.CDT_PER_QUESTION = _settings.CDT_PER_QUESTION;

        emit NewVerification(ask.ID, ask.INITIATOR);
    }

    function reply(
        uint256 verificationIndex,
        string calldata answer
    ) public {
        Validator storage validator = _validators[msg.sender];

        require(verificationIndex < _verificationsIndex, "Verification not found");
        Verification storage ask = _verifications[verificationIndex];
        Answer[] storage answers = _verificationsAnswers[verificationIndex];

        require(validator.WARRANTY_AMOUNT >= ask.CDT_PER_QUESTION, "Not Eligible");
        require(ask.STATUS == 1, "Ended");
        require(ask.INITIATOR != msg.sender, "Not authorized");
        require(answers.length < ask.NUMBER_OF_ANSWER_SLOTS, "Ended");
        for (uint256 i = 0; i < ask.PARTICIPATORS.length; i++) {
            require(msg.sender != ask.PARTICIPATORS[i], "Not authorized");
        }

        ask.PARTICIPATORS.push(msg.sender);
        answers.push(Answer(msg.sender, answer));
        validator.WARRANTY_AMOUNT -= ask.CDT_PER_QUESTION;
        validator.LOCKED_WARRANTY_AMOUNT += ask.CDT_PER_QUESTION;
        if (answers.length >= ask.NUMBER_OF_ANSWER_SLOTS) {
            ask.STATUS = 2;
        }
        emit UpdateVerification(ask.ID, ask.INITIATOR);
    }

    function evaluate(uint256 _verificationIndex) public {
        require(_verificationIndex < _verificationsIndex, "Verification not found");
        Verification storage ask = _verifications[_verificationIndex];
        require(ask.STATUS == 2, "Not authorized");

        Answer[] storage answers = _verificationsAnswers[_verificationIndex];
        QuestionWithAnswer storage question = _questions[ask.QUESTION_ID];
        bool dot = false;
        uint256 guaranteeToBurn = 0;
        uint256 sameResponseCount = 0;
        // Loop on answers
        for (uint256 o = 0; o < answers.length; o++) {
            // Total count of identical answers
            sameResponseCount = 0;
            for (uint256 o2 = 0; o2 < answers.length; o2++) {
                if (keccak256(bytes(answers[o2].ANSWER)) == keccak256(bytes(answers[o].ANSWER))) { // Qx
                    sameResponseCount += 1;
                }
            }
            // If the total amount of identical answers is superior to the threshold the answer is valid
            if (sameResponseCount.mul(100).div(answers.length) >= 70) {
                for (uint256 o2 = 0; o2 < answers.length; o2++) {
                    if (keccak256(bytes(answers[o2].ANSWER)) == keccak256(bytes(answers[o].ANSWER))) {
                        ask.WINNERS.push(answers[o2].WALLET);
                    } else {
                        ask.LOOSERS.push(answers[o2].WALLET);
                    }
                }
                // Save score if response is valid
                if (keccak256(bytes(question.ANSWER)) == keccak256(bytes("Numeric")) && answers[o].ANSWER.isNumeric()) {
                    dot = true;
                } else if (keccak256(bytes(question.ANSWER)) == keccak256(bytes(answers[o].ANSWER))) {
                    dot = true;
                }
                break ;
            }
        }
        if (dot == true) {
            ask.SCORE = sameResponseCount.mul(100).div(answers.length);
            ask.STATUS = 3;
            // Burnt the locked warranties for the losers
            for (uint i = 0; i < ask.LOOSERS.length; i++) {
                Validator storage validator = _validators[ask.LOOSERS[i]];

                validator.LOCKED_WARRANTY_AMOUNT -= ask.CDT_PER_QUESTION;
                validator.WARRANTY_AMOUNT += ask.CDT_PER_QUESTION.div(2);
                validator.BURNT_WARRANTY += ask.CDT_PER_QUESTION.div(2);
                guaranteeToBurn += ask.CDT_PER_QUESTION.div(2);
                validator.PARTICICATIONS.push(Participation(ask.ID, 0, ask.CDT_PER_QUESTION.div(2)));
            }
            // Add rewards to the winners.
            for (uint i = 0; i < ask.WINNERS.length; i++) {
                Validator storage validator = _validators[ask.WINNERS[i]];

                uint256 validatorRewards = ask.REWARD_AMOUNT.div(ask.WINNERS.length);
                validator.AMOUNT += validatorRewards;
                validator.LOCKED_WARRANTY_AMOUNT -= _settings.CDT_PER_QUESTION;
                validator.WARRANTY_AMOUNT += _settings.CDT_PER_QUESTION;
                validator.PARTICICATIONS.push(Participation(ask.ID, validatorRewards, 0));
                ask.REWARD_WALLET_AMOUNT -= validatorRewards;
            }
            if (guaranteeToBurn > 0) {
                require(_cdtToken.burn(guaranteeToBurn) == true, "Error burn");
                _statistics.TOTAL_CDT_BURNT += guaranteeToBurn;
            }
        } else {
            ask.SCORE = 0;
            ask.STATUS = 4;
            for (uint i = 0; i < ask.PARTICIPATORS.length; i++) {
                Validator storage validator = _validators[ask.PARTICIPATORS[i]];
                
                validator.WARRANTY_AMOUNT += ask.CDT_PER_QUESTION;
                validator.LOCKED_WARRANTY_AMOUNT -= ask.CDT_PER_QUESTION;
            }
            require(_cdtToken.transfer(ask.INITIATOR, ask.REWARD_WALLET_AMOUNT) == true, "Error transfer");
            ask.REWARD_AMOUNT = 0;
        }

        emit UpdateVerification(ask.ID, ask.INITIATOR);
    }

    function claimRewards() public {
        Validator storage validator = _validators[msg.sender];

        require(validator.AMOUNT > 0, "Insufficient balance");
        require(_cdtToken.transfer(validator.WALLET, validator.AMOUNT) == true, "Error transfer");
        validator.AMOUNT = 0;
    }

    function withdrawAll() public {
        Validator storage validator = _validators[msg.sender];
        uint256 amount = validator.AMOUNT + validator.WARRANTY_AMOUNT;

        require(amount > 0, "Insufficient balance");
        require(_cdtToken.transfer(validator.WALLET, amount) == true, "Error transfer");
        validator.AMOUNT = 0;
        validator.WARRANTY_AMOUNT = 0;
    }

    // SETTINGS SECTION

    function setCdtPerQuestion(uint256 _amount) public onlyOwner {
        _settings.CDT_PER_QUESTION = _amount;
    }

    function setMaxCap(uint256 _value) public onlyOwner {
        _settings.MAX_CAP = _value;
    }

    function setMinCap(uint256 _value) public onlyOwner {
        _settings.MIN_CAP = _value;
    }

    function getQuestion(uint256 id) public view onlyOwner returns (QuestionWithAnswer memory) {
        return _questions[id];
    }

    function setQuestion(uint256 id, string calldata question, string[] calldata answers, string calldata answer) public onlyOwner {
        QuestionWithAnswer storage questionWithAnswer = _questions[id];
        
        questionWithAnswer.ID = id;
        questionWithAnswer.QUESTION = question;
        for (uint256 i = 0; i < answers.length; i++) {
            questionWithAnswer.ANSWERS.push(answers[i]);
        }
        questionWithAnswer.ANSWER = answer;
    }

    function claimFees() public onlyOwner {
        require(_checkDotCollectedFeesAmount > 0, "Empty");
        require(_cdtToken.transfer(_owner, _checkDotCollectedFeesAmount) == true, "Error transfer");
        _checkDotCollectedFeesAmount = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}