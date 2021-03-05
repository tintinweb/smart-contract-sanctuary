// SPDX-License-Identifier: No License
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SocialBets is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;

    // Type definitions
    enum BetStates {WaitingParty2, WaitingFirstVote, WaitingSecondVote, WaitingMediator}
    enum BetCancellationReasons {Party2Timeout, VotesTimeout, Tie, MediatorTimeout, MediatorCancelled}
    enum BetFinishReasons {AnswersMatched, MediatorFinished}
    enum Answers {Unset, FirstPartyWins, SecondPartyWins, Tie}
    struct Bet {
        string metadata;
        address payable firstParty;
        address payable secondParty;
        address payable mediator;
        uint256 firstBetValue;
        uint256 secondBetValue;
        uint256 mediatorFee;
        uint256 secondPartyTimeframe;
        uint256 resultTimeframe;
        BetStates state;
        Answers firstPartyAnswer; // answers: 0 - unset, 1 - first party wins, 2 - second party wins, 3 - tie
        Answers secondPartyAnswer;
    }

    // Storage

    //betId => bet
    mapping(uint256 => Bet) public bets;

    // user => active bets[]
    mapping(address => uint256[]) public firstPartyActiveBets;
    // user => (betId => bet index in the active bets[])
    mapping(address => mapping(uint256 => uint256)) public firstPartyActiveBetsIndexes;
    // user => active bets[]
    mapping(address => uint256[]) public secondPartyActiveBets;
    // user => (betId => bet index in the active bets[])
    mapping(address => mapping(uint256 => uint256)) public secondPartyActiveBetsIndexes;
    // user => active bets[]
    mapping(address => uint256[]) public mediatorActiveBets;
    // user => (betId => bet index in the active bets[])
    mapping(address => mapping(uint256 => uint256)) public mediatorActiveBetsIndexes;

    // fee value collected fot the owner to withdraw
    uint256 public collectedFee;

    // Storage: Admin Settings
    uint256 public minBetValue;
    // bet creation fee
    uint256 public feePercentage;
    // mediator settings
    address payable public defaultMediator;
    uint256 public defaultMediatorFee;
    uint256 public mediationTimeLimit = 7 days;

    // Constants
    uint256 public constant FEE_DECIMALS = 2;
    uint256 public constant FEE_PERCENTAGE_DIVISION = 10000;
    uint256 public constant MEDIATOR_FEE_DIVISION = 10000;

    // Events

    event NewBetCreated(
        uint256 indexed _betId,
        address indexed _firstParty,
        address indexed _secondParty,
        string _metadata,
        address _mediator,
        uint256 _mediatorFee,
        uint256 _firstBetValue,
        uint256 _secondBetValue,
        uint256 _secondPartyTimeframe,
        uint256 _resultTimeframe
    );

    event SecondPartyParticipated(uint256 indexed _betId, address indexed _firstParty, address indexed _secondParty);

    event Voted(uint256 indexed _betId, address indexed _voter, Answers indexed _answer);

    event WaitingMediator(uint256 indexed _betId, address indexed _mediator);

    event Finished(uint256 indexed _betId, address indexed _winner, BetFinishReasons indexed _reason, uint256 _reward);

    event Cancelled(uint256 indexed _betId, BetCancellationReasons indexed _reason);

    event Completed(
        address indexed _firstParty,
        address indexed _secondParty,
        address indexed _mediator,
        uint256 _betId
    );

    //Constructor
    constructor(
        uint256 _feePercentage,
        uint256 _minBetValue,
        uint256 _defaultMediatorFee,
        address payable _defaultMediator
    ) public {
        require(_feePercentage <= FEE_PERCENTAGE_DIVISION, "Bad fee");
        require(_defaultMediatorFee <= MEDIATOR_FEE_DIVISION, "Bad mediator fee");
        require(_defaultMediator != address(0) && !_defaultMediator.isContract(), "Bad mediator");
        minBetValue = _minBetValue;
        feePercentage = _feePercentage;
        defaultMediatorFee = _defaultMediatorFee;
        defaultMediator = _defaultMediator;
    }

    // Modifiers

    /**
     * @dev Checks if bet exists in the bet mapping
     */
    modifier onlyExistingBet(uint256 _betId) {
        require(isBetExists(_betId), "Bet doesn't exist");
        _;
    }

    /**
     * @dev Checks is sender isn't contract
     * [IMPORTANT]
     * ====
     * This modifier will allow the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    modifier onlyNotContract() {
        require(!msg.sender.isContract(), "Contracts are prohibited");
        _;
    }

    // Getters

    /**
     * @dev Returns first party active bets
     */
    function getFirstPartyActiveBets(address _firstParty) external view returns (uint256[] memory betsIds) {
        betsIds = firstPartyActiveBets[_firstParty];
    }

    /**
     * @dev Returns second party active bets
     */
    function getSecondPartyActiveBets(address _secondParty) external view returns (uint256[] memory betsIds) {
        betsIds = secondPartyActiveBets[_secondParty];
    }

    /**
     * @dev Returns mediator active bets
     */
    function getMediatorActiveBets(address _mediator) external view returns (uint256[] memory betsIds) {
        betsIds = mediatorActiveBets[_mediator];
    }

    /**
     * @dev Returns bet ID calculated from constant bet properties
     */
    function calculateBetId(
        string memory _metadata,
        address _firstParty,
        uint256 _firstBetValue,
        uint256 _secondBetValue,
        uint256 _secondPartyTimeframe,
        uint256 _resultTimeframe
    ) public pure returns (uint256 betId) {
        betId = uint256(
            keccak256(
                abi.encode(
                    _metadata,
                    _firstParty,
                    _firstBetValue,
                    _secondBetValue,
                    _secondPartyTimeframe,
                    _resultTimeframe
                )
            )
        );
    }

    /**
     * @dev Check if bet exists
     */
    function isBetExists(uint256 _betId) public view returns (bool isExists) {
        isExists = bets[_betId].firstParty != address(0);
    }

    /**
     * @dev Returns fee value from bet values
     */
    function calculateFee(uint256 _firstBetValue, uint256 _secondBetValue) public view returns (uint256 fee) {
        fee = _firstBetValue.add(_secondBetValue).mul(feePercentage).div(FEE_PERCENTAGE_DIVISION);
    }

    /**
     * @dev Returns mediator fee value
     */
    function calculateMediatorFee(uint256 _betId) public view returns (uint256 mediatorFeeValue) {
        Bet storage bet = bets[_betId];
        mediatorFeeValue = bet.firstBetValue.add(bet.secondBetValue).mul(bet.mediatorFee).div(MEDIATOR_FEE_DIVISION);
    }

    // Admin functionality

    /**
     * @dev Set new min bet value
     */
    function setMinBetValue(uint256 _minBetValue) external onlyOwner {
        minBetValue = _minBetValue;
    }

    /**
     * @dev Set new fee percentage
     */
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= FEE_PERCENTAGE_DIVISION, "Bad fee");
        feePercentage = _feePercentage;
    }

    /**
     * @dev Set new default mediator fee
     */
    function setDefaultMediatorFee(uint256 _defaultMediatorFee) external onlyOwner {
        require(_defaultMediatorFee <= MEDIATOR_FEE_DIVISION, "Bad mediator fee");
        defaultMediatorFee = _defaultMediatorFee;
    }

    /**
     * @dev Set new default mediator
     */
    function setDefaultMediator(address payable _defaultMediator) external onlyOwner {
        require(_defaultMediator != address(0) && !_defaultMediator.isContract(), "Bad mediator");
        defaultMediator = _defaultMediator;
    }

    /**
     * @dev Set new mediation time limit
     */
    function setMediationTimeLimit(uint256 _mediationTimeLimit) external onlyOwner {
        require(_mediationTimeLimit > 0, "Bad mediationTimeLimit");
        mediationTimeLimit = _mediationTimeLimit;
    }

    /**
     * @dev Pause the contract. This will disable new bet creation functionality
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract. This will enable new bet creation functionality
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraws collected fee
     */
    function withdrawFee() external onlyOwner {
        require(collectedFee > 0, "No fee to withdraw");
        uint256 callValue = collectedFee;
        collectedFee = 0;
        (bool success, ) = msg.sender.call{value:callValue}("");
        require(success, "Transfer failed");
    }

    // Users functionality

    /**
     * @dev Creates new bet with specified characteristics. msg.sender will be set as the first party,
     *      so creation needs to be payed with first party bet value + fee.
     */
    function createBet(
        string memory _metadata,
        address payable _secondParty,
        address payable _mediator,
        uint256 _mediatorFee,
        uint256 _firstBetValue,
        uint256 _secondBetValue,
        uint256 _secondPartyTimeframe,
        uint256 _resultTimeframe
    ) external payable whenNotPaused onlyNotContract nonReentrant returns (uint256 betId) {
        require(_firstBetValue >= minBetValue && _secondBetValue >= minBetValue, "Too small bet value");
        require(_secondPartyTimeframe > now, "2nd party timeframe < now");
        require(_resultTimeframe > now, "Result timeframe < now");
        require(_resultTimeframe > _secondPartyTimeframe, "Result < 2nd party timeframe");
        require(
            msg.sender != _secondParty &&
                msg.sender != _mediator &&
                (_secondParty != _mediator || _secondParty == address(0)),
            "Bad mediator or second party"
        );
        uint256 fee = calculateFee(_firstBetValue, _secondBetValue);
        require(msg.value == _firstBetValue.add(fee), "Bad eth value");
        collectedFee = collectedFee.add(fee);

        betId = calculateBetId(
            _metadata,
            msg.sender,
            _firstBetValue,
            _secondBetValue,
            _secondPartyTimeframe,
            _resultTimeframe
        );
        require(!isBetExists(betId), "Bet already exists");

        Bet storage newBet = bets[betId];
        newBet.metadata = _metadata;
        newBet.firstParty = msg.sender;
        newBet.secondParty = _secondParty;

        if (_mediator == address(0) || _mediator == defaultMediator) {
            newBet.mediator = defaultMediator;
            newBet.mediatorFee = defaultMediatorFee;
        } else {
            newBet.mediator = _mediator;
            require(_mediatorFee <= MEDIATOR_FEE_DIVISION, "Bad mediator fee");
            newBet.mediatorFee = _mediatorFee;
        }
        newBet.firstBetValue = _firstBetValue;
        newBet.secondBetValue = _secondBetValue;
        newBet.secondPartyTimeframe = _secondPartyTimeframe;
        newBet.resultTimeframe = _resultTimeframe;

        firstPartyActiveBets[msg.sender].push(betId);
        firstPartyActiveBetsIndexes[msg.sender][betId] = firstPartyActiveBets[msg.sender].length.sub(1);

        emit NewBetCreated(
            betId,
            newBet.firstParty,
            newBet.secondParty,
            newBet.metadata,
            newBet.mediator,
            newBet.mediatorFee,
            newBet.firstBetValue,
            newBet.secondBetValue,
            newBet.secondPartyTimeframe,
            newBet.resultTimeframe
        );
    }

    /**
     * @dev Second party participating function. Cancels bet if party 2 is late for participating
     */
    function participate(uint256 _betId)
        external
        payable
        onlyExistingBet(_betId)
        onlyNotContract
        nonReentrant
        returns (bool success)
    {
        Bet storage bet = bets[_betId];
        require(bet.state == BetStates.WaitingParty2, "Party 2 already joined");
        require(msg.sender != bet.firstParty && msg.sender != bet.mediator, "You are first party or mediator");
        require(bet.secondParty == address(0) || bet.secondParty == msg.sender, "Private bet");
        require(msg.value == bet.secondBetValue, "Bad eth value");

        if (bet.secondPartyTimeframe > now) {
            success = true;
            bet.secondParty = msg.sender;
            bet.state = BetStates.WaitingFirstVote;

            secondPartyActiveBets[msg.sender].push(_betId);
            secondPartyActiveBetsIndexes[msg.sender][_betId] = secondPartyActiveBets[msg.sender].length.sub(1);

            emit SecondPartyParticipated(_betId, bet.firstParty, bet.secondParty);
        } else {
            success = false;
            cancelBet(_betId, BetCancellationReasons.Party2Timeout);
            (bool transferSuccess, ) = msg.sender.call{value: msg.value}("");
            require(transferSuccess, "Transfer failed");
        }
    }

    /**
     * @dev First and second partie's function for setting answer.
     *      If answer waiting time has expired and nobody set the answer then bet cancels.
     *      If one party didn't set the answer before timeframe the bet waits for mediator.
     */
    function vote(uint256 _betId, Answers _answer) external nonReentrant onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];

        require(_answer != Answers.Unset, "Wrong answer");
        require(
            bet.state == BetStates.WaitingFirstVote || bet.state == BetStates.WaitingSecondVote,
            "Bet isn't waiting for votes"
        );
        require(msg.sender == bet.firstParty || msg.sender == bet.secondParty, "You aren't participating");

        if (bet.resultTimeframe < now) {
            if (bet.state == BetStates.WaitingFirstVote) {
                cancelBet(_betId, BetCancellationReasons.VotesTimeout);
                return;
            } else {
                bet.state = BetStates.WaitingMediator;

                addMediatorActiveBet(bet.mediator, _betId);

                emit WaitingMediator(_betId, bet.mediator);
                return;
            }
        }

        if (bet.firstParty == msg.sender && bet.firstPartyAnswer == Answers.Unset) {
            bet.firstPartyAnswer = _answer;
        } else if (bet.secondParty == msg.sender && bet.secondPartyAnswer == Answers.Unset) {
            bet.secondPartyAnswer = _answer;
        } else {
            revert("You can't change your answer");
        }
        emit Voted(_betId, msg.sender, _answer);

        if (bet.state == BetStates.WaitingFirstVote) {
            bet.state = BetStates.WaitingSecondVote;
            return;
        } else {
            if (bet.firstPartyAnswer != bet.secondPartyAnswer) {
                bet.state = BetStates.WaitingMediator;

                addMediatorActiveBet(bet.mediator, _betId);

                emit WaitingMediator(_betId, bet.mediator);
                return;
            } else {
                finishBet(_betId, bet.firstPartyAnswer, BetFinishReasons.AnswersMatched);
            }
        }
    }

    /**
     * @dev Mediator's setting an answer function. If mediating time has expired
     *      then bet will be cancelled
     */
    function mediate(uint256 _betId, Answers _answer) external nonReentrant onlyNotContract onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];
        require(_answer != Answers.Unset, "Wrong answer");
        require(bet.state == BetStates.WaitingMediator, "Bet isn't waiting for mediator");
        require(bet.mediator == msg.sender, "You can't mediate this bet");

        if (now > bet.resultTimeframe && now.sub(bet.resultTimeframe) > mediationTimeLimit) {
            cancelBet(_betId, BetCancellationReasons.MediatorTimeout);
            return;
        }

        payToMediator(_betId);
        finishBet(_betId, _answer, BetFinishReasons.MediatorFinished);
    }

    // Management handlers

    /**
     * @dev Checks secondPartyTimeframe. Cancels bet if party 2 is late for participating
     */
    function party2TimeoutHandler(uint256 _betId) external nonReentrant onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];
        require(bet.state == BetStates.WaitingParty2, "Bet isn't waiting for party 2");
        require(bet.secondPartyTimeframe <= now, "There is no timeout");
        cancelBet(_betId, BetCancellationReasons.Party2Timeout);
    }

    /**
     * @dev Checks bet's resultTimeframe. If answer waiting time has expired and nobody set the answer then bet cancels.
     *      If one party didn't set the answer before timeframe the bet waits for mediator.
     */
    function votesTimeoutHandler(uint256 _betId) external nonReentrant onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];
        require(
            bet.state == BetStates.WaitingFirstVote || bet.state == BetStates.WaitingSecondVote,
            "Bet isn't waiting for votes"
        );
        require(bet.resultTimeframe < now, "There is no timeout");

        if (bet.state == BetStates.WaitingFirstVote) {
            cancelBet(_betId, BetCancellationReasons.VotesTimeout);
            return;
        } else {
            bet.state = BetStates.WaitingMediator;

            addMediatorActiveBet(bet.mediator, _betId);

            emit WaitingMediator(_betId, bet.mediator);
            return;
        }
    }

    /**
     * @dev Checks mediator timeframe (resultTimeframe + mediationTimeLimit) and cancels bet if time has expired
     */
    function mediatorTimeoutHandler(uint256 _betId) external nonReentrant onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];
        require(bet.state == BetStates.WaitingMediator, "Bet isn't waiting for mediator");
        require(now > bet.resultTimeframe && now.sub(bet.resultTimeframe) > mediationTimeLimit, "There is no timeout");
        cancelBet(_betId, BetCancellationReasons.MediatorTimeout);
    }

    //Internals

    /**
     * @dev Finish bet and pay to the winner or cancel if tie
     */
    function finishBet(
        uint256 _betId,
        Answers _answer,
        BetFinishReasons _reason
    ) internal {
        Bet storage bet = bets[_betId];
        address payable firstParty = bet.firstParty;
        address payable mediator = bet.mediator;
        address payable secondParty = bet.secondParty;
        uint256 firstBetValue = bet.firstBetValue;
        uint256 secondBetValue = bet.secondBetValue;
        address payable winner;
        uint256 mediatorFeeValue = 0;
        if (_reason == BetFinishReasons.MediatorFinished) {
            mediatorFeeValue = calculateMediatorFee(_betId);

            deleteMediatorActiveBet(mediator, _betId);
        }
        if (_answer == Answers.FirstPartyWins) {
            winner = firstParty;
        } else if (_answer == Answers.SecondPartyWins) {
            winner = secondParty;
        } else {
            if (_reason == BetFinishReasons.MediatorFinished) {
                cancelBet(_betId, BetCancellationReasons.MediatorCancelled);
            } else {
                cancelBet(_betId, BetCancellationReasons.Tie);
            }
            return;
        }

        delete bets[_betId];

        deleteFirstPartyActiveBet(firstParty, _betId);
        deleteSecondPartyActiveBet(secondParty, _betId);

        (bool success, ) = winner.call{value: firstBetValue.add(secondBetValue).sub(mediatorFeeValue)}("");
        require(success, "Transfer failed");
        emit Finished(_betId, winner, _reason, firstBetValue.add(secondBetValue).sub(mediatorFeeValue));
        emit Completed(firstParty, secondParty, mediator, _betId);
    }

    /**
     * @dev Cancel bet and return money to the parties.
     */
    function cancelBet(uint256 _betId, BetCancellationReasons _reason) internal {
        Bet storage bet = bets[_betId];
        uint256 mediatorFeeValue = 0;
        address payable mediator = bet.mediator;

        if (_reason == BetCancellationReasons.MediatorCancelled) {
            mediatorFeeValue = calculateMediatorFee(_betId);
        }

        if (_reason == BetCancellationReasons.MediatorTimeout) {
            deleteMediatorActiveBet(mediator, _betId);
        }

        address payable firstParty = bet.firstParty;
        address payable secondParty = bet.secondParty;
        bool isSecondPartyParticipating = bet.state != BetStates.WaitingParty2;
        uint256 firstBetValue = bet.firstBetValue;
        uint256 secondBetValue = bet.secondBetValue;

        delete bets[_betId];
        uint256 firstPartyMediatorFeeValue = mediatorFeeValue.div(2);

        (bool success, ) = firstParty.call{value: firstBetValue.sub(firstPartyMediatorFeeValue)}("");
        require(success, "Transfer failed");
        deleteFirstPartyActiveBet(firstParty, _betId);

        if (isSecondPartyParticipating) {
            (success, ) = secondParty.call{value: secondBetValue.sub(mediatorFeeValue.sub(firstPartyMediatorFeeValue))}(
                ""
            );
            require(success, "Transfer failed");
            deleteSecondPartyActiveBet(secondParty, _betId);
        }
        emit Cancelled(_betId, _reason);
        emit Completed(firstParty, secondParty, mediator, _betId);
    }

    /**
     * @dev Add new active bet to mediator
     */
    function addMediatorActiveBet(address _mediator, uint256 _betId) internal {
        mediatorActiveBets[_mediator].push(_betId);
        mediatorActiveBetsIndexes[_mediator][_betId] = mediatorActiveBets[_mediator].length.sub(1);
    }

    /**
     * @dev Delete active bet from mediator's active bet's
     */
    function deleteMediatorActiveBet(address _mediator, uint256 _betId) internal {
        if (mediatorActiveBets[_mediator].length == 0) return;
        uint256 index = mediatorActiveBetsIndexes[_mediator][_betId];
        delete mediatorActiveBetsIndexes[_mediator][_betId];
        uint256 lastIndex = mediatorActiveBets[_mediator].length.sub(1);
        if (lastIndex != index) {
            uint256 movedBet = mediatorActiveBets[_mediator][lastIndex];
            mediatorActiveBetsIndexes[_mediator][movedBet] = index;
            mediatorActiveBets[_mediator][index] = mediatorActiveBets[_mediator][lastIndex];
        }
        mediatorActiveBets[_mediator].pop();
    }

    /**
     * @dev Delete active bet from first partie's active bet's
     */
    function deleteFirstPartyActiveBet(address _firstParty, uint256 _betId) internal {
        if (firstPartyActiveBets[_firstParty].length == 0) return;
        uint256 index = firstPartyActiveBetsIndexes[_firstParty][_betId];
        delete firstPartyActiveBetsIndexes[_firstParty][_betId];
        uint256 lastIndex = firstPartyActiveBets[_firstParty].length.sub(1);
        if (lastIndex != index) {
            uint256 movedBet = firstPartyActiveBets[_firstParty][lastIndex];
            firstPartyActiveBetsIndexes[_firstParty][movedBet] = index;
            firstPartyActiveBets[_firstParty][index] = firstPartyActiveBets[_firstParty][lastIndex];
        }
        firstPartyActiveBets[_firstParty].pop();
    }

    /**
     * @dev Delete active bet from second partie's active bet's
     */
    function deleteSecondPartyActiveBet(address _secondParty, uint256 _betId) internal {
        if (secondPartyActiveBets[_secondParty].length == 0) return;
        uint256 index = secondPartyActiveBetsIndexes[_secondParty][_betId];
        delete secondPartyActiveBetsIndexes[_secondParty][_betId];
        uint256 lastIndex = secondPartyActiveBets[_secondParty].length.sub(1);
        if (lastIndex != index) {
            uint256 movedBet = secondPartyActiveBets[_secondParty][lastIndex];
            secondPartyActiveBetsIndexes[_secondParty][movedBet] = index;
            secondPartyActiveBets[_secondParty][index] = secondPartyActiveBets[_secondParty][lastIndex];
        }
        secondPartyActiveBets[_secondParty].pop();
    }

    /**
     * @dev Transfers mediator fee to the mediator
     */
    function payToMediator(uint256 _betId) internal {
        Bet storage bet = bets[_betId];
        uint256 value = calculateMediatorFee(_betId);
        (bool success, ) = bet.mediator.call{value: value}("");
        require(success, "Transfer failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}