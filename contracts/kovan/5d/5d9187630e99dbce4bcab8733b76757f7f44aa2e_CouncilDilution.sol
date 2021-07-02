// File contracts/Owned.sol

pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// File @openzeppelin/contracts/math/[email protected]

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File contracts/SafeDecimalMath.sol

pragma solidity ^0.5.16;

// Libraries

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// File contracts/CouncilDilution.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.16;

pragma experimental ABIEncoderV2;

/**
@title A contract that allows for the dilution of Spartan Council voting weights
@author @andytcf
 */
contract CouncilDilution is Owned {
    using SafeDecimalMath for uint;

    /* SCCP configurable values */

    // @notice How many seats on the Spartan Council
    uint public numOfSeats;

    // @notice The length of a proposal (SCCP/SIP) voting period
    uint public proposalPeriod;

    /* Global variables */

    // @notice The ipfs hash of the latest Spartan Council election proposal
    string public latestElectionHash;

    struct ElectionLog {
        // @notice The ipfs hash of a particular Spartan Council election proposal
        string electionHash;
        // @notice A mapping of the votes allocated to each of the Spartan Council members
        mapping(address => uint) votesForMember;
        // @notice A mapping to check whether an address was an elected Council member in this election
        mapping(address => bool) councilMembers;
        // @notice The timestamp which the election log was stored
        uint created;
    }

    struct ProposalLog {
        // @notice The ipfs hash of a particular SCCP/SIP proposal
        string proposalHash;
        // @notice The election hash of the current epoch when the proposal was made
        string electionHash;
        //  @notice The timestamp which the voting period begins
        uint start;
        // @notice The timestamp which the voting period of the proposal ends
        uint end;
        // @notice A boolean value to check whether a proposal log exists
        bool exist;
    }

    struct DilutionReceipt {
        // @notice The ipfs hash of the proposal which the dilution happened on
        string proposalHash;
        // @notice The address of the council member diluted
        address memberDiluted;
        // @notice The total amount in which the council member was diluted by
        uint totalDilutionValue;
        // @notice A list of dilutors
        address[] dilutors;
        // @notice A mapping to show the value of dilution per dilutor
        mapping(address => uint) voterDilutions;
        // @notice A flag value to check whether a dilution exist
        bool exist;
    }

    // @notice Given a election hash, return the ElectionLog struct associated
    mapping(string => ElectionLog) public electionHashToLog;

    // @notice Given a voter address and a council member address, return the delegated vote weight for the most recent Spartan Council election
    mapping(address => mapping(address => uint)) public latestDelegatedVoteWeight;

    // @notice Given a council member address, return the total delegated vote weight for the most recent Spartan Council election
    mapping(address => uint) public latestVotingWeight;

    // @notice Given a propoal hash and a voting address, find out the member the user has voted for
    mapping(string => mapping(address => address)) public electionMemberVotedFor;

    // @notice Given a proposal hash and a voting address, find if a member has diluted
    mapping(string => mapping(address => bool)) public hasAddressDilutedForProposal;

    // @notice Given a proposal hash (SCCP/SIP), return the ProposalLog struct associated
    mapping(string => ProposalLog) public proposalHashToLog;

    // @notice Given a proposal hash and a council member, return the DilutionReceipt if it exists
    mapping(string => mapping(address => DilutionReceipt)) public proposalHashToMemberDilution;

    /* Events */

    // @notice An event emitted when a new ElectionLog is created
    event ElectionLogged(
        string electionHash,
        address[] nominatedCouncilMembers,
        address[] voters,
        address[] nomineesVotedFor,
        uint[] assignedVoteWeights
    );

    // @notice An event emitted when a new ProposalLog is created
    event ProposalLogged(string proposalHash, string electionHash, uint start, uint end);

    // @notice An event emitted when a new DilutionReceipt is created
    event DilutionCreated(
        string proposalHash,
        address memberDiluted,
        uint totalDilutionValueBefore,
        uint totalDilutionValueAfter
    );

    // @notice An event emitted when a DilutionReceipt is modified
    event DilutionModified(
        string proposalHash,
        address memberDiluted,
        uint totalDilutionValueBefore,
        uint totalDilutionValueAfter
    );

    // @notice An event emitted when the number of council seats is modified
    event SeatsModified(uint previousNumberOfSeats, uint newNumberOfSeats);

    // @notice An event emitted when the proposal period is modified
    event ProposalPeriodModified(uint previousProposalPeriod, uint newProposalPeriod);

    /* */

    // @notice Initialises the contract with a X number of council seats and a proposal period of 3 days
    constructor(uint _numOfSeats) public Owned(msg.sender) {
        numOfSeats = _numOfSeats;
        proposalPeriod = 3 days;
    }

    /* Mutative Functions */

    /**
    @notice A function to create a new ElectionLog, this is called to record the result of a Spartan Council election
    @param electionHash The ipfs hash of the Spartan Council election proposal to log
    @param nominatedCouncilMembers The array of the successful Spartan Council nominees addresses, must be the same length as the numOfSeats
    @param voters An ordered array of all the voter's addresses corresponding to `nomineesVotedFor`, `assignedVoteWeights`
    @param nomineesVotedFor An ordered array of all the nominee address that received votes corresponding to `voters`, `assignedVoteWeights`
    @param assignedVoteWeights An ordered array of the voting weights corresponding to `voters`, `nomineesVotedFor`
    @return electionHash
     */
    function logElection(
        string memory electionHash,
        address[] memory nominatedCouncilMembers,
        address[] memory voters,
        address[] memory nomineesVotedFor,
        uint[] memory assignedVoteWeights
    ) public onlyOwner() returns (string memory) {
        require(bytes(electionHash).length > 0, "empty election hash provided");
        require(voters.length > 0, "empty voters array provided");
        require(nomineesVotedFor.length > 0, "empty nomineesVotedFor array provided");
        require(assignedVoteWeights.length > 0, "empty assignedVoteWeights array provided");
        require(nominatedCouncilMembers.length == numOfSeats, "invalid number of council members");

        ElectionLog memory newElectionLog = ElectionLog(electionHash, now);

        electionHashToLog[electionHash] = newElectionLog;

        // store the voting history for calculating the allocated voting weights
        for (uint i = 0; i < voters.length; i++) {
            latestDelegatedVoteWeight[voters[i]][nomineesVotedFor[i]] = assignedVoteWeights[i];
            latestVotingWeight[nomineesVotedFor[i]] = latestVotingWeight[nomineesVotedFor[i]] + assignedVoteWeights[i];
            electionMemberVotedFor[electionHash][voters[i]] = nomineesVotedFor[i];
        }

        // store the total weight of each successful council member
        for (uint j = 0; j < nominatedCouncilMembers.length; j++) {
            electionHashToLog[electionHash].votesForMember[nominatedCouncilMembers[j]] = latestVotingWeight[
                nominatedCouncilMembers[j]
            ];
            electionHashToLog[electionHash].councilMembers[nominatedCouncilMembers[j]] = true;
        }

        latestElectionHash = electionHash;

        emit ElectionLogged(electionHash, nominatedCouncilMembers, voters, nomineesVotedFor, assignedVoteWeights);

        return electionHash;
    }

    /**
    @notice A function to created a new ProposalLog, this is called to record SCCP/SIPS created and allow for dilution to occur per proposal.
    @param proposalHash the ipfs hash of the proposal to be logged
    @return proposalHash
     */
    function logProposal(string memory proposalHash) public returns (string memory) {
        require(!proposalHashToLog[proposalHash].exist, "proposal hash is not unique");
        require(bytes(proposalHash).length > 0, "proposal hash must not be empty");

        uint start = now;

        uint end = start + proposalPeriod;

        ProposalLog memory newProposalLog = ProposalLog(proposalHash, latestElectionHash, start, end, true);

        proposalHashToLog[proposalHash] = newProposalLog;

        emit ProposalLogged(proposalHash, latestElectionHash, start, end);

        return proposalHash;
    }

    /**
    @notice  A function to dilute a council member's voting weight for a particular proposal
    @param proposalHash the ipfs hash of the proposal to be logged
    @param memberToDilute the address of the member to dilute
     */
    function dilute(string memory proposalHash, address memberToDilute) public {
        require(memberToDilute != address(0), "member to dilute must be a valid address");
        require(
            electionHashToLog[latestElectionHash].councilMembers[memberToDilute],
            "member to dilute must be a nominated council member"
        );
        require(proposalHashToLog[proposalHash].exist, "proposal does not exist");
        require(
            latestDelegatedVoteWeight[msg.sender][memberToDilute] > 0,
            "sender has not delegated voting weight for member"
        );
        require(now < proposalHashToLog[proposalHash].end, "dilution can only occur within the proposal voting period");
        require(hasAddressDilutedForProposal[proposalHash][msg.sender] == false, "sender has already diluted");

        if (proposalHashToMemberDilution[proposalHash][memberToDilute].exist) {
            DilutionReceipt storage receipt = proposalHashToMemberDilution[proposalHash][memberToDilute];

            uint originalTotalDilutionValue = receipt.totalDilutionValue;

            receipt.dilutors.push(msg.sender);
            receipt.voterDilutions[msg.sender] = latestDelegatedVoteWeight[msg.sender][memberToDilute];
            receipt.totalDilutionValue = receipt.totalDilutionValue + latestDelegatedVoteWeight[msg.sender][memberToDilute];

            hasAddressDilutedForProposal[proposalHash][msg.sender] = true;

            emit DilutionCreated(
                proposalHash,
                receipt.memberDiluted,
                originalTotalDilutionValue,
                receipt.totalDilutionValue
            );
        } else {
            address[] memory dilutors;
            DilutionReceipt memory newDilutionReceipt = DilutionReceipt(proposalHash, memberToDilute, 0, dilutors, true);

            proposalHashToMemberDilution[proposalHash][memberToDilute] = newDilutionReceipt;

            uint originalTotalDilutionValue = proposalHashToMemberDilution[proposalHash][memberToDilute].totalDilutionValue;

            proposalHashToMemberDilution[proposalHash][memberToDilute].dilutors.push(msg.sender);

            proposalHashToMemberDilution[proposalHash][memberToDilute].voterDilutions[
                msg.sender
            ] = latestDelegatedVoteWeight[msg.sender][memberToDilute];

            proposalHashToMemberDilution[proposalHash][memberToDilute].totalDilutionValue = latestDelegatedVoteWeight[
                msg.sender
            ][memberToDilute];

            hasAddressDilutedForProposal[proposalHash][msg.sender] = true;

            emit DilutionCreated(
                proposalHash,
                memberToDilute,
                originalTotalDilutionValue,
                proposalHashToMemberDilution[proposalHash][memberToDilute].totalDilutionValue
            );
        }
    }

    /**
    @notice  A function that allows a voter to undo a dilution
    @param proposalHash the ipfs hash of the proposal to be logged
    @param memberToUndilute the address of the member to undilute
     */
    function invalidateDilution(string memory proposalHash, address memberToUndilute) public {
        require(memberToUndilute != address(0), "member to undilute must be a valid address");
        require(proposalHashToLog[proposalHash].exist, "proposal does not exist");
        require(
            proposalHashToMemberDilution[proposalHash][memberToUndilute].exist,
            "dilution receipt does not exist for this member and proposal hash"
        );
        require(
            proposalHashToMemberDilution[proposalHash][memberToUndilute].voterDilutions[msg.sender] > 0 &&
                hasAddressDilutedForProposal[proposalHash][msg.sender] == true,
            "voter has no dilution weight"
        );
        require(now < proposalHashToLog[proposalHash].end, "undo dilution can only occur within the proposal voting period");

        address caller = msg.sender;

        DilutionReceipt storage receipt = proposalHashToMemberDilution[proposalHash][memberToUndilute];

        uint originalTotalDilutionValue = receipt.totalDilutionValue;

        uint voterDilutionValue = receipt.voterDilutions[msg.sender];

        hasAddressDilutedForProposal[proposalHash][msg.sender] = false;

        for (uint i = 0; i < receipt.dilutors.length; i++) {
            if (receipt.dilutors[i] == caller) {
                receipt.dilutors[i] = receipt.dilutors[receipt.dilutors.length - 1];
                break;
            }
        }

        receipt.dilutors.pop();

        receipt.voterDilutions[msg.sender] = 0;
        receipt.totalDilutionValue = receipt.totalDilutionValue - voterDilutionValue;

        emit DilutionModified(proposalHash, receipt.memberDiluted, originalTotalDilutionValue, receipt.totalDilutionValue);
    }

    /* Views */

    /**
    @notice   A view function that checks which proposalHashes exist on the contract and return them
    @param proposalHashes a array of hashes to check validity against
    @return a array with elements either empty or with the valid proposal hash
     */
    function getValidProposals(string[] memory proposalHashes) public view returns (string[] memory) {
        string[] memory validHashes = new string[](proposalHashes.length);

        for (uint i = 0; i < proposalHashes.length; i++) {
            string memory proposalHash = proposalHashes[i];
            if (proposalHashToLog[proposalHash].exist) {
                validHashes[i] = (proposalHashToLog[proposalHash].proposalHash);
            }
        }

        return validHashes;
    }

    /**
    @notice A view function that calculates the council member voting weight for a proposal after any dilution penalties
    @param proposalHash the ipfs hash of the proposal to check dilution against
    @param councilMember the council member to check diluted weight for 
    @return the calculated diluted ratio (1e18)
     */
    function getDilutedWeightForProposal(string memory proposalHash, address councilMember) public view returns (uint) {
        require(proposalHashToLog[proposalHash].exist, "proposal does not exist");

        string memory electionHash = proposalHashToLog[proposalHash].electionHash;

        require(electionHashToLog[electionHash].councilMembers[councilMember], "address must be a nominated council member");

        uint originalWeight = electionHashToLog[electionHash].votesForMember[councilMember];
        uint penaltyValue = proposalHashToMemberDilution[proposalHash][councilMember].totalDilutionValue;

        return (originalWeight - penaltyValue).divideDecimal(originalWeight);
    }

    /**
    @notice A view helper function to get the dilutors for a particular DilutionReceipt
    @param proposalHash the ipfs hash of the proposal to get the dilution receipt for
    @param memberDiluted the council member to get the dilution array for
    @return a list of the voters addresses who have diluted this member for this proposal
     */
    function getDilutorsForDilutionReceipt(string memory proposalHash, address memberDiluted)
        public
        view
        returns (address[] memory)
    {
        return proposalHashToMemberDilution[proposalHash][memberDiluted].dilutors;
    }

    /**
    @notice A view helper function to get the weighting of a voter's dilution for a DilutionReceipt
    @param proposalHash the ipfs hash of the proposal to get the dilution receipt for
    @param memberDiluted the council member to check dilution weighting against
    @param voter the voter address to get the dilution weighting for
    @return the dilution weight of the voter, for a specific proposal and council member
     */
    function getVoterDilutionWeightingForDilutionReceipt(
        string memory proposalHash,
        address memberDiluted,
        address voter
    ) public view returns (uint) {
        return proposalHashToMemberDilution[proposalHash][memberDiluted].voterDilutions[voter];
    }

    /* Restricted Functions */

    /**
    @notice A function that can only be called by the OWNER that changes the number of seats on the Spartan Council
    @param _numOfSeats the number of seats to set the numOfSeats to
     */
    function modifySeats(uint _numOfSeats) public onlyOwner() {
        require(_numOfSeats > 0, "number of seats must be greater than zero");
        uint oldNumOfSeats = numOfSeats;
        numOfSeats = _numOfSeats;

        emit SeatsModified(oldNumOfSeats, numOfSeats);
    }

    /**
    @notice A function that can only be called by the owner that changes the proposal voting period length
    @param _proposalPeriod the proposal perod in seconds, to set the proposalPeriod variable to
     */
    function modifyProposalPeriod(uint _proposalPeriod) public onlyOwner() {
        uint oldProposalPeriod = proposalPeriod;
        proposalPeriod = _proposalPeriod;

        emit ProposalPeriodModified(oldProposalPeriod, proposalPeriod);
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}