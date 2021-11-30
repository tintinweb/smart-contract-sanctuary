/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/token/ERC20.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/lib/os/SafeERC20.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/SafeERC20.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;



library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), approveCallData);
    }

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata) private returns (bool) {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
            // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                // Only return success if returned data was true
                // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }
}

// File: contracts/lib/os/SafeMath.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: contracts/lib/os/SafeMath64.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath64.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


/**
 * @title SafeMath64
 * @dev Math operations for uint64 with safety checks that revert on error
 */
library SafeMath64 {
    string private constant ERROR_ADD_OVERFLOW = "MATH64_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH64_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH64_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH64_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint256 c = uint256(_a) * uint256(_b);
        require(c < 0x010000000000000000, ERROR_MUL_OVERFLOW); // 2**64 (less gas this way)

        return uint64(c);
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint64 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint64 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: contracts/lib/os/Uint256Helpers.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/Uint256Helpers.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


library Uint256Helpers {
    uint256 private constant MAX_UINT8 = uint8(-1);
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_UINT8_NUMBER_TOO_BIG = "UINT8_NUMBER_TOO_BIG";
    string private constant ERROR_UINT64_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint8(uint256 a) internal pure returns (uint8) {
        require(a <= MAX_UINT8, ERROR_UINT8_NUMBER_TOO_BIG);
        return uint8(a);
    }

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_UINT64_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// File: contracts/arbitration/IArbitrator.sol

pragma solidity ^0.5.8;



interface IArbitrator {
    /**
    * @dev Create a dispute over the Arbitrable sender with a number of possible rulings
    * @param _possibleRulings Number of possible rulings allowed for the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identification number
    */
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata) external returns (uint256);

    /**
    * @dev Submit evidence for a dispute
    * @param _disputeId Id of the dispute in the Protocol
    * @param _submitter Address of the account submitting the evidence
    * @param _evidence Data submitted for the evidence related to the dispute
    */
    function submitEvidence(uint256 _disputeId, address _submitter, bytes calldata _evidence) external;

    /**
    * @dev Close the evidence period of a dispute
    * @param _disputeId Identification number of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(uint256 _disputeId) external;

    /**
    * @notice Rule dispute #`_disputeId` if ready
    * @param _disputeId Identification number of the dispute to be ruled
    * @return subject Arbitrable instance associated to the dispute
    * @return ruling Ruling number computed for the given dispute
    */
    function rule(uint256 _disputeId) external returns (address subject, uint256 ruling);

    /**
    * @dev Tell the dispute fees information to create a dispute
    * @return recipient Address where the corresponding dispute fees must be transferred to
    * @return feeToken ERC20 token used for the fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getDisputeFees() external view returns (address recipient, ERC20 feeToken, uint256 feeAmount);
}

// File: contracts/arbitration/IArbitrable.sol

pragma solidity ^0.5.8;



contract IArbitrable {
    /**
    * @dev Emitted when an IArbitrable instance's dispute is ruled by an IArbitrator
    * @param arbitrator IArbitrator instance ruling the dispute
    * @param disputeId Identification number of the dispute being ruled by the arbitrator
    * @param ruling Ruling given by the arbitrator
    */
    event Ruled(IArbitrator indexed arbitrator, uint256 indexed disputeId, uint256 ruling);
}

// File: contracts/disputes/IDisputeManager.sol

pragma solidity ^0.5.8;




interface IDisputeManager {
    enum DisputeState {
        PreDraft,
        Adjudicating,
        Ruled
    }

    enum AdjudicationState {
        Invalid,
        Committing,
        Revealing,
        Appealing,
        ConfirmingAppeal,
        Ended
    }

    /**
    * @dev Create a dispute to be drafted in a future term
    * @param _subject Arbitrable instance creating the dispute
    * @param _possibleRulings Number of possible rulings allowed for the drafted jurors to vote on the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identification number
    */
    function createDispute(IArbitrable _subject, uint8 _possibleRulings, bytes calldata _metadata) external returns (uint256);

    /**
    * @dev Submit evidence for a dispute
    * @param _subject Arbitrable instance submitting the dispute
    * @param _disputeId Identification number of the dispute receiving new evidence
    * @param _submitter Address of the account submitting the evidence
    * @param _evidence Data submitted for the evidence of the dispute
    */
    function submitEvidence(IArbitrable _subject, uint256 _disputeId, address _submitter, bytes calldata _evidence) external;

    /**
    * @dev Close the evidence period of a dispute
    * @param _subject IArbitrable instance requesting to close the evidence submission period
    * @param _disputeId Identification number of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(IArbitrable _subject, uint256 _disputeId) external;

    /**
    * @dev Draft jurors for the next round of a dispute
    * @param _disputeId Identification number of the dispute to be drafted
    */
    function draft(uint256 _disputeId) external;

    /**
    * @dev Appeal round of a dispute in favor of a certain ruling
    * @param _disputeId Identification number of the dispute being appealed
    * @param _roundId Identification number of the dispute round being appealed
    * @param _ruling Ruling appealing a dispute round in favor of
    */
    function createAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;

    /**
    * @dev Confirm appeal for a round of a dispute in favor of a ruling
    * @param _disputeId Identification number of the dispute confirming an appeal of
    * @param _roundId Identification number of the dispute round confirming an appeal of
    * @param _ruling Ruling being confirmed against a dispute round appeal
    */
    function confirmAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;

    /**
    * @dev Compute the final ruling for a dispute
    * @param _disputeId Identification number of the dispute to compute its final ruling
    * @return subject Arbitrable instance associated to the dispute
    * @return finalRuling Final ruling decided for the given dispute
    */
    function computeRuling(uint256 _disputeId) external returns (IArbitrable subject, uint8 finalRuling);

    /**
    * @dev Settle penalties for a round of a dispute
    * @param _disputeId Identification number of the dispute to settle penalties for
    * @param _roundId Identification number of the dispute round to settle penalties for
    * @param _jurorsToSettle Maximum number of jurors to be slashed in this call
    */
    function settlePenalties(uint256 _disputeId, uint256 _roundId, uint256 _jurorsToSettle) external;

    /**
    * @dev Claim rewards for a round of a dispute for juror
    * @dev For regular rounds, it will only reward winning jurors
    * @param _disputeId Identification number of the dispute to settle rewards for
    * @param _roundId Identification number of the dispute round to settle rewards for
    * @param _juror Address of the juror to settle their rewards
    */
    function settleReward(uint256 _disputeId, uint256 _roundId, address _juror) external;

    /**
    * @dev Settle appeal deposits for a round of a dispute
    * @param _disputeId Identification number of the dispute to settle appeal deposits for
    * @param _roundId Identification number of the dispute round to settle appeal deposits for
    */
    function settleAppealDeposit(uint256 _disputeId, uint256 _roundId) external;

    /**
    * @dev Tell the amount of token fees required to create a dispute
    * @return feeToken ERC20 token used for the fees
    * @return feeAmount Total amount of fees to be paid for a dispute at the given term
    */
    function getDisputeFees() external view returns (ERC20 feeToken, uint256 feeAmount);

    /**
    * @dev Tell information of a certain dispute
    * @param _disputeId Identification number of the dispute being queried
    * @return subject Arbitrable subject being disputed
    * @return possibleRulings Number of possible rulings allowed for the drafted jurors to vote on the dispute
    * @return state Current state of the dispute being queried: pre-draft, adjudicating, or ruled
    * @return finalRuling The winning ruling in case the dispute is finished
    * @return lastRoundId Identification number of the last round created for the dispute
    * @return createTermId Identification number of the term when the dispute was created
    */
    function getDispute(uint256 _disputeId) external view
        returns (IArbitrable subject, uint8 possibleRulings, DisputeState state, uint8 finalRuling, uint256 lastRoundId, uint64 createTermId);

    /**
    * @dev Tell information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @return draftTerm Term from which the requested round can be drafted
    * @return delayedTerms Number of terms the given round was delayed based on its requested draft term id
    * @return jurorsNumber Number of jurors requested for the round
    * @return selectedJurors Number of jurors already selected for the requested round
    * @return settledPenalties Whether or not penalties have been settled for the requested round
    * @return collectedTokens Amount of juror tokens that were collected from slashed jurors for the requested round
    * @return coherentJurors Number of jurors that voted in favor of the final ruling in the requested round
    * @return state Adjudication state of the requested round
    */
    function getRound(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 draftTerm,
            uint64 delayedTerms,
            uint64 jurorsNumber,
            uint64 selectedJurors,
            uint256 jurorFees,
            bool settledPenalties,
            uint256 collectedTokens,
            uint64 coherentJurors,
            AdjudicationState state
        );

    /**
    * @dev Tell appeal-related information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @return maker Address of the account appealing the given round
    * @return appealedRuling Ruling confirmed by the appealer of the given round
    * @return taker Address of the account confirming the appeal of the given round
    * @return opposedRuling Ruling confirmed by the appeal taker of the given round
    */
    function getAppeal(uint256 _disputeId, uint256 _roundId) external view
        returns (address maker, uint64 appealedRuling, address taker, uint64 opposedRuling);

    /**
    * @dev Tell information related to the next round due to an appeal of a certain round given.
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round requesting the appeal details of
    * @return nextRoundStartTerm Term ID from which the next round will start
    * @return nextRoundJurorsNumber Jurors number for the next round
    * @return newDisputeState New state for the dispute associated to the given round after the appeal
    * @return feeToken ERC20 token used for the next round fees
    * @return jurorFees Total amount of fees to be distributed between the winning jurors of the next round
    * @return totalFees Total amount of fees for a regular round at the given term
    * @return appealDeposit Amount to be deposit of fees for a regular round at the given term
    * @return confirmAppealDeposit Total amount of fees for a regular round at the given term
    */
    function getNextRoundDetails(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 nextRoundStartTerm,
            uint64 nextRoundJurorsNumber,
            DisputeState newDisputeState,
            ERC20 feeToken,
            uint256 totalFees,
            uint256 jurorFees,
            uint256 appealDeposit,
            uint256 confirmAppealDeposit
        );

    /**
    * @dev Tell juror-related information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @param _juror Address of the juror being queried
    * @return weight Juror weight drafted for the requested round
    * @return rewarded Whether or not the given juror was rewarded based on the requested round
    */
    function getJuror(uint256 _disputeId, uint256 _roundId, address _juror) external view returns (uint64 weight, bool rewarded);
}

// File: contracts/lib/PctHelpers.sol

pragma solidity ^0.5.8;



library PctHelpers {
    using SafeMath for uint256;

    uint256 internal constant PCT_BASE = 10000; // ‱ (1 / 10,000)
    uint256 internal constant PCT_BASE_HIGH_PRECISION = 1e18; // 100%

    function isValid(uint16 _pct) internal pure returns (bool) {
        return _pct <= PCT_BASE;
    }

    function isValidHighPrecision(uint256 _pct) internal pure returns (bool) {
        return _pct <= PCT_BASE_HIGH_PRECISION;
    }

    function pct(uint256 self, uint16 _pct) internal pure returns (uint256) {
        return self.mul(uint256(_pct)) / PCT_BASE;
    }

    function pct256(uint256 self, uint256 _pct) internal pure returns (uint256) {
        return self.mul(_pct) / PCT_BASE;
    }

    function pctHighPrecision(uint256 self, uint256 _pct) internal pure returns (uint256) {
        return self.mul(_pct) / PCT_BASE_HIGH_PRECISION;
    }

    function pctIncrease(uint256 self, uint16 _pct) internal pure returns (uint256) {
        // No need for SafeMath: for addition note that `PCT_BASE` is lower than (2^256 - 2^16)
        return self.mul(PCT_BASE + uint256(_pct)) / PCT_BASE;
    }
}

// File: contracts/voting/ICRVotingOwner.sol

pragma solidity ^0.5.8;


interface ICRVotingOwner {
    /**
    * @dev Ensure votes can be committed for a vote instance, revert otherwise
    * @param _voteId ID of the vote instance to request the weight of a voter for
    */
    function ensureCanCommit(uint256 _voteId) external;

    /**
    * @dev Ensure a certain voter can commit votes for a vote instance, revert otherwise
    * @param _voteId ID of the vote instance to request the weight of a voter for
    * @param _voter Address of the voter querying the weight of
    */
    function ensureCanCommit(uint256 _voteId, address _voter) external;

    /**
    * @dev Ensure a certain voter can reveal votes for vote instance, revert otherwise
    * @param _voteId ID of the vote instance to request the weight of a voter for
    * @param _voter Address of the voter querying the weight of
    * @return Weight of the requested juror for the requested vote instance
    */
    function ensureCanReveal(uint256 _voteId, address _voter) external returns (uint64);
}

// File: contracts/voting/ICRVoting.sol

pragma solidity ^0.5.8;



interface ICRVoting {
    /**
    * @dev Create a new vote instance
    * @dev This function can only be called by the CRVoting owner
    * @param _voteId ID of the new vote instance to be created
    * @param _possibleOutcomes Number of possible outcomes for the new vote instance to be created
    */
    function create(uint256 _voteId, uint8 _possibleOutcomes) external;

    /**
    * @dev Get the winning outcome of a vote instance
    * @param _voteId ID of the vote instance querying the winning outcome of
    * @return Winning outcome of the given vote instance or refused in case it's missing
    */
    function getWinningOutcome(uint256 _voteId) external view returns (uint8);

    /**
    * @dev Get the tally of an outcome for a certain vote instance
    * @param _voteId ID of the vote instance querying the tally of
    * @param _outcome Outcome querying the tally of
    * @return Tally of the outcome being queried for the given vote instance
    */
    function getOutcomeTally(uint256 _voteId, uint8 _outcome) external view returns (uint256);

    /**
    * @dev Tell whether an outcome is valid for a given vote instance or not
    * @param _voteId ID of the vote instance to check the outcome of
    * @param _outcome Outcome to check if valid or not
    * @return True if the given outcome is valid for the requested vote instance, false otherwise
    */
    function isValidOutcome(uint256 _voteId, uint8 _outcome) external view returns (bool);

    /**
    * @dev Get the outcome voted by a voter for a certain vote instance
    * @param _voteId ID of the vote instance querying the outcome of
    * @param _voter Address of the voter querying the outcome of
    * @return Outcome of the voter for the given vote instance
    */
    function getVoterOutcome(uint256 _voteId, address _voter) external view returns (uint8);

    /**
    * @dev Tell whether a voter voted in favor of a certain outcome in a vote instance or not
    * @param _voteId ID of the vote instance to query if a voter voted in favor of a certain outcome
    * @param _outcome Outcome to query if the given voter voted in favor of
    * @param _voter Address of the voter to query if voted in favor of the given outcome
    * @return True if the given voter voted in favor of the given outcome, false otherwise
    */
    function hasVotedInFavorOf(uint256 _voteId, uint8 _outcome, address _voter) external view returns (bool);

    /**
    * @dev Filter a list of voters based on whether they voted in favor of a certain outcome in a vote instance or not
    * @param _voteId ID of the vote instance to be checked
    * @param _outcome Outcome to filter the list of voters of
    * @param _voters List of addresses of the voters to be filtered
    * @return List of results to tell whether a voter voted in favor of the given outcome or not
    */
    function getVotersInFavorOf(uint256 _voteId, uint8 _outcome, address[] calldata _voters) external view returns (bool[] memory);
}

// File: contracts/treasury/ITreasury.sol

pragma solidity ^0.5.8;



interface ITreasury {
    /**
    * @dev Assign a certain amount of tokens to an account
    * @param _token ERC20 token to be assigned
    * @param _to Address of the recipient that will be assigned the tokens to
    * @param _amount Amount of tokens to be assigned to the recipient
    */
    function assign(ERC20 _token, address _to, uint256 _amount) external;

    /**
    * @dev Withdraw a certain amount of tokens
    * @param _token ERC20 token to be withdrawn
    * @param _to Address of the recipient that will receive the tokens
    * @param _amount Amount of tokens to be withdrawn from the sender
    */
    function withdraw(ERC20 _token, address _to, uint256 _amount) external;
}

// File: contracts/registry/IJurorsRegistry.sol

pragma solidity ^0.5.8;



interface IJurorsRegistry {

    /**
    * @dev Assign a requested amount of juror tokens to a juror
    * @param _juror Juror to add an amount of tokens to
    * @param _amount Amount of tokens to be added to the available balance of a juror
    */
    function assignTokens(address _juror, uint256 _amount) external;

    /**
    * @dev Burn a requested amount of juror tokens
    * @param _amount Amount of tokens to be burned
    */
    function burnTokens(uint256 _amount) external;

    /**
    * @dev Draft a set of jurors based on given requirements for a term id
    * @param _params Array containing draft requirements:
    *        0. bytes32 Term randomness
    *        1. uint256 Dispute id
    *        2. uint64  Current term id
    *        3. uint256 Number of seats already filled
    *        4. uint256 Number of seats left to be filled
    *        5. uint64  Number of jurors required for the draft
    *        6. uint16  Permyriad of the minimum active balance to be locked for the draft
    *
    * @return jurors List of jurors selected for the draft
    * @return length Size of the list of the draft result
    */
    function draft(uint256[7] calldata _params) external returns (address[] memory jurors, uint256 length);

    /**
    * @dev Slash a set of jurors based on their votes compared to the winning ruling
    * @param _termId Current term id
    * @param _jurors List of juror addresses to be slashed
    * @param _lockedAmounts List of amounts locked for each corresponding juror that will be either slashed or returned
    * @param _rewardedJurors List of booleans to tell whether a juror's active balance has to be slashed or not
    * @return Total amount of slashed tokens
    */
    function slashOrUnlock(uint64 _termId, address[] calldata _jurors, uint256[] calldata _lockedAmounts, bool[] calldata _rewardedJurors)
        external
        returns (uint256 collectedTokens);

    /**
    * @dev Try to collect a certain amount of tokens from a juror for the next term
    * @param _juror Juror to collect the tokens from
    * @param _amount Amount of tokens to be collected from the given juror and for the requested term id
    * @param _termId Current term id
    * @return True if the juror has enough unlocked tokens to be collected for the requested term, false otherwise
    */
    function collectTokens(address _juror, uint256 _amount, uint64 _termId) external returns (bool);

    /**
    * @dev Lock a juror's withdrawals until a certain term ID
    * @param _juror Address of the juror to be locked
    * @param _termId Term ID until which the juror's withdrawals will be locked
    */
    function lockWithdrawals(address _juror, uint64 _termId) external;

    /**
    * @dev Tell the active balance of a juror for a given term id
    * @param _juror Address of the juror querying the active balance of
    * @param _termId Term ID querying the active balance for
    * @return Amount of active tokens for juror in the requested past term id
    */
    function activeBalanceOfAt(address _juror, uint64 _termId) external view returns (uint256);

    /**
    * @dev Tell the total amount of active juror tokens at the given term id
    * @param _termId Term ID querying the total active balance for
    * @return Total amount of active juror tokens at the given term id
    */
    function totalActiveBalanceAt(uint64 _termId) external view returns (uint256);
}

// File: contracts/lib/os/IsContract.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/IsContract.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

// File: contracts/lib/os/TimeHelpers.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/TimeHelpers.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;



contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

// File: contracts/court/clock/IClock.sol

pragma solidity ^0.5.8;


interface IClock {
    /**
    * @dev Ensure that the current term of the clock is up-to-date
    * @return Identification number of the current term
    */
    function ensureCurrentTerm() external returns (uint64);

    /**
    * @dev Transition up to a certain number of terms to leave the clock up-to-date
    * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
    * @return Identification number of the term ID after executing the heartbeat transitions
    */
    function heartbeat(uint64 _maxRequestedTransitions) external returns (uint64);

    /**
    * @dev Ensure that a certain term has its randomness set
    * @return Randomness of the current term
    */
    function ensureCurrentTermRandomness() external returns (bytes32);

    /**
    * @dev Tell the last ensured term identification number
    * @return Identification number of the last ensured term
    */
    function getLastEnsuredTermId() external view returns (uint64);

    /**
    * @dev Tell the current term identification number. Note that there may be pending term transitions.
    * @return Identification number of the current term
    */
    function getCurrentTermId() external view returns (uint64);

    /**
    * @dev Tell the number of terms the clock should transition to be up-to-date
    * @return Number of terms the clock should transition to be up-to-date
    */
    function getNeededTermTransitions() external view returns (uint64);

    /**
    * @dev Tell the information related to a term based on its ID
    * @param _termId ID of the term being queried
    * @return startTime Term start time
    * @return randomnessBN Block number used for randomness in the requested term
    * @return randomness Randomness computed for the requested term
    * @return celesteTokenTotalSupply Total supply of the Celeste token
    */
    function getTerm(uint64 _termId) external view returns (uint64 startTime, uint64 randomnessBN, bytes32 randomness, uint256 celesteTokenTotalSupply);

    /**
    * @dev Tell the randomness of a term even if it wasn't computed yet
    * @param _termId Identification number of the term being queried
    * @return Randomness of the requested term
    */
    function getTermRandomness(uint64 _termId) external view returns (bytes32);

    /**
    * @dev Tell the total supply of the celeste token at a specific term
    * @param _termId Identification number of the term being queried
    * @return Total supply of celeste token
    */
    function getTermTokenTotalSupply(uint64 _termId) external view returns (uint256);
}

// File: contracts/court/clock/CourtClock.sol

pragma solidity ^0.5.8;






contract CourtClock is IClock, TimeHelpers {
    using SafeMath64 for uint64;

    string private constant ERROR_TERM_DOES_NOT_EXIST = "CLK_TERM_DOES_NOT_EXIST";
    string private constant ERROR_TERM_DURATION_TOO_LONG = "CLK_TERM_DURATION_TOO_LONG";
    string private constant ERROR_TERM_RANDOMNESS_NOT_YET = "CLK_TERM_RANDOMNESS_NOT_YET";
    string private constant ERROR_TERM_RANDOMNESS_UNAVAILABLE = "CLK_TERM_RANDOMNESS_UNAVAILABLE";
    string private constant ERROR_BAD_FIRST_TERM_START_TIME = "CLK_BAD_FIRST_TERM_START_TIME";
    string private constant ERROR_TOO_MANY_TRANSITIONS = "CLK_TOO_MANY_TRANSITIONS";
    string private constant ERROR_INVALID_TRANSITION_TERMS = "CLK_INVALID_TRANSITION_TERMS";
    string private constant ERROR_CANNOT_DELAY_STARTED_COURT = "CLK_CANNOT_DELAY_STARTED_COURT";
    string private constant ERROR_CANNOT_DELAY_PAST_START_TIME = "CLK_CANNOT_DELAY_PAST_START_TIME";

    // Maximum number of term transitions a callee may have to assume in order to call certain functions that require the Court being up-to-date
    uint64 internal constant MAX_AUTO_TERM_TRANSITIONS_ALLOWED = 1;

    // Max duration in seconds that a term can last
    uint64 internal constant MAX_TERM_DURATION = 365 days;

    // Max time until first term starts since contract is deployed
    uint64 internal constant MAX_FIRST_TERM_DELAY_PERIOD = 2 * MAX_TERM_DURATION;

    struct Term {
        uint64 startTime;              // Timestamp when the term started
        uint64 randomnessBN;           // Block number for entropy
        bytes32 randomness;            // Entropy from randomnessBN block hash
        uint256 celesteTokenTotalSupply;
    }

    // Duration in seconds for each term of the Court
    uint64 private termDuration;

    // Last ensured term id
    uint64 private termId;

    // List of Court terms indexed by id
    mapping (uint64 => Term) private terms;

    event Heartbeat(uint64 previousTermId, uint64 currentTermId);
    event StartTimeDelayed(uint64 previousStartTime, uint64 currentStartTime);

    /**
    * @dev Ensure a certain term has already been processed
    * @param _termId Identification number of the term to be checked
    */
    modifier termExists(uint64 _termId) {
        require(_termId <= termId, ERROR_TERM_DOES_NOT_EXIST);
        _;
    }

    /**
    * @dev Constructor function
    * @param _termParams Array containing:
    *        0. _termDuration Duration in seconds per term
    *        1. _firstTermStartTime Timestamp in seconds when the court will open (to give time for juror on-boarding)
    */
    constructor(uint64[2] memory _termParams, ERC20 _celesteToken) public {
        uint64 _termDuration = _termParams[0];
        uint64 _firstTermStartTime = _termParams[1];

        require(_termDuration < MAX_TERM_DURATION, ERROR_TERM_DURATION_TOO_LONG);
        require(_firstTermStartTime >= getTimestamp64() + _termDuration, ERROR_BAD_FIRST_TERM_START_TIME);
        require(_firstTermStartTime <= getTimestamp64() + MAX_FIRST_TERM_DELAY_PERIOD, ERROR_BAD_FIRST_TERM_START_TIME);

        termDuration = _termDuration;

        // No need for SafeMath: we already checked values above
        terms[0].startTime = _firstTermStartTime - _termDuration;
        terms[0].celesteTokenTotalSupply = _celesteToken.totalSupply();
    }

    /**
    * @notice Ensure that the current term of the Court is up-to-date. If the Court is outdated by more than `MAX_AUTO_TERM_TRANSITIONS_ALLOWED`
    *         terms, the heartbeat function must be called manually instead.
    * @return Identification number of the current term
    */
    function ensureCurrentTerm() external returns (uint64) {
        return _ensureCurrentTerm();
    }

    /**
    * @notice Transition up to `_maxRequestedTransitions` terms
    * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
    * @return Identification number of the term ID after executing the heartbeat transitions
    */
    function heartbeat(uint64 _maxRequestedTransitions) external returns (uint64) {
        return _heartbeat(_maxRequestedTransitions);
    }

    /**
    * @notice Ensure that a certain term has its randomness set. As we allow to draft disputes requested for previous terms, if there
    *      were mined more than 256 blocks for the current term, the blockhash of its randomness BN is no longer available, given
    *      round will be able to be drafted in the following term.
    * @return Randomness of the current term
    */
    function ensureCurrentTermRandomness() external returns (bytes32) {
        // If the randomness for the given term was already computed, return
        uint64 currentTermId = termId;
        Term storage term = terms[currentTermId];
        bytes32 termRandomness = term.randomness;
        if (termRandomness != bytes32(0)) {
            return termRandomness;
        }

        // Compute term randomness
        bytes32 newRandomness = _computeTermRandomness(currentTermId);
        require(newRandomness != bytes32(0), ERROR_TERM_RANDOMNESS_UNAVAILABLE);
        term.randomness = newRandomness;
        return newRandomness;
    }

    /**
    * @dev Tell the term duration of the Court
    * @return Duration in seconds of the Court term
    */
    function getTermDuration() external view returns (uint64) {
        return termDuration;
    }

    /**
    * @dev Tell the last ensured term identification number
    * @return Identification number of the last ensured term
    */
    function getLastEnsuredTermId() external view returns (uint64) {
        return _lastEnsuredTermId();
    }

    /**
    * @dev Tell the current term identification number. Note that there may be pending term transitions.
    * @return Identification number of the current term
    */
    function getCurrentTermId() external view returns (uint64) {
        return _currentTermId();
    }

    /**
    * @dev Tell the number of terms the Court should transition to be up-to-date
    * @return Number of terms the Court should transition to be up-to-date
    */
    function getNeededTermTransitions() external view returns (uint64) {
        return _neededTermTransitions();
    }

    /**
    * @dev Tell the information related to a term based on its ID. Note that if the term has not been reached, the
    *      information returned won't be computed yet. This function allows querying future terms that were not computed yet.
    * @param _termId ID of the term being queried
    * @return startTime Term start time
    * @return randomnessBN Block number used for randomness in the requested term
    * @return randomness Randomness computed for the requested term
    * @return celesteTokenTotalSupply Total supply of the Celeste token
    */
    function getTerm(uint64 _termId) external view returns (uint64 startTime, uint64 randomnessBN, bytes32 randomness, uint256 celesteTokenTotalSupply) {
        Term storage term = terms[_termId];
        return (term.startTime, term.randomnessBN, term.randomness, term.celesteTokenTotalSupply);
    }

    /**
    * @dev Tell the randomness of a term even if it wasn't computed yet
    * @param _termId Identification number of the term being queried
    * @return Randomness of the requested term
    */
    function getTermRandomness(uint64 _termId) external view termExists(_termId) returns (bytes32) {
        return _computeTermRandomness(_termId);
    }

    /**
    * @dev Tell the total supply of the celeste token at a specific term
    * @param _termId Identification number of the term being queried
    * @return Total supply of celeste token
    */
    function getTermTokenTotalSupply(uint64 _termId) external view termExists(_termId) returns (uint256) {
        return terms[_termId].celesteTokenTotalSupply;
    }

    /**
    * @dev Internal function to ensure that the current term of the Court is up-to-date. If the Court is outdated by more than
    *      `MAX_AUTO_TERM_TRANSITIONS_ALLOWED` terms, the heartbeat function must be called manually.
    * @return Identification number of the resultant term ID after executing the corresponding transitions
    */
    function _ensureCurrentTerm() internal returns (uint64) {
        // Check the required number of transitions does not exceeds the max allowed number to be processed automatically
        uint64 requiredTransitions = _neededTermTransitions();
        require(requiredTransitions <= MAX_AUTO_TERM_TRANSITIONS_ALLOWED, ERROR_TOO_MANY_TRANSITIONS);

        // If there are no transitions pending, return the last ensured term id
        if (uint256(requiredTransitions) == 0) {
            return termId;
        }

        // Process transition if there is at least one pending
        return _heartbeat(requiredTransitions);
    }

    /**
    * @dev Internal function to transition the Court terms up to a requested number of terms
    * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
    * @return Identification number of the resultant term ID after executing the requested transitions
    */
    function _heartbeat(uint64 _maxRequestedTransitions) internal returns (uint64) {
        // Transition the minimum number of terms between the amount requested and the amount actually needed
        uint64 neededTransitions = _neededTermTransitions();
        uint256 transitions = uint256(_maxRequestedTransitions < neededTransitions ? _maxRequestedTransitions : neededTransitions);
        require(transitions > 0, ERROR_INVALID_TRANSITION_TERMS);

        uint64 blockNumber = getBlockNumber64();
        uint64 previousTermId = termId;
        uint64 currentTermId = previousTermId;
        for (uint256 transition = 1; transition <= transitions; transition++) {
            // Term IDs are incremented by one based on the number of time periods since the Court started. Since time is represented in uint64,
            // even if we chose the minimum duration possible for a term (1 second), we can ensure terms will never reach 2^64 since time is
            // already assumed to fit in uint64.
            Term storage previousTerm = terms[currentTermId++];
            Term storage currentTerm = terms[currentTermId];
            (ERC20 feeToken,,,,,, uint256[4] memory jurorsParams) = _getConfig(currentTermId);
            _onTermTransitioned(currentTermId);

            // Set the start time of the new term. Note that we are using a constant term duration value to guarantee
            // equally long terms, regardless of heartbeats.
            currentTerm.startTime = previousTerm.startTime.add(termDuration);

            // In order to draft a random number of jurors in a term, we use a randomness factor for each term based on a
            // block number that is set once the term has started. Note that this information could not be known beforehand.
            currentTerm.randomnessBN = blockNumber + 1;

            // We check if the feeTokenTotalSupply is set, which means this networks feeToken doesn't have an accurate
            // totalSupply so we will use the hardcoded value
            currentTerm.celesteTokenTotalSupply = jurorsParams[3] > 0 ? jurorsParams[3] : feeToken.totalSupply();
        }

        termId = currentTermId;
        emit Heartbeat(previousTermId, currentTermId);
        return currentTermId;
    }

    /**
    * @dev Internal function to delay the first term start time only if it wasn't reached yet
    * @param _newFirstTermStartTime New timestamp in seconds when the court will open
    */
    function _delayStartTime(uint64 _newFirstTermStartTime) internal {
        require(_currentTermId() == 0, ERROR_CANNOT_DELAY_STARTED_COURT);

        Term storage term = terms[0];
        uint64 currentFirstTermStartTime = term.startTime.add(termDuration);
        require(_newFirstTermStartTime > currentFirstTermStartTime, ERROR_CANNOT_DELAY_PAST_START_TIME);

        // No need for SafeMath: we already checked above that `_newFirstTermStartTime` > `currentFirstTermStartTime` >= `termDuration`
        term.startTime = _newFirstTermStartTime - termDuration;
        emit StartTimeDelayed(currentFirstTermStartTime, _newFirstTermStartTime);
    }

    /**
    * @dev Internal function to notify when a term has been transitioned. This function must be overridden to provide custom behavior.
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _onTermTransitioned(uint64 _termId) internal;

    /**
    * @dev Internal function to tell the last ensured term identification number
    * @return Identification number of the last ensured term
    */
    function _lastEnsuredTermId() internal view returns (uint64) {
        return termId;
    }

    /**
    * @dev Internal function to tell the current term identification number. Note that there may be pending term transitions.
    * @return Identification number of the current term
    */
    function _currentTermId() internal view returns (uint64) {
        return termId.add(_neededTermTransitions());
    }

    /**
    * @dev Internal function to tell the number of terms the Court should transition to be up-to-date
    * @return Number of terms the Court should transition to be up-to-date
    */
    function _neededTermTransitions() internal view returns (uint64) {
        // Note that the Court is always initialized providing a start time for the first-term in the future. If that's the case,
        // no term transitions are required.
        uint64 currentTermStartTime = terms[termId].startTime;
        if (getTimestamp64() < currentTermStartTime) {
            return uint64(0);
        }

        // No need for SafeMath: we already know that the start time of the current term is in the past
        return (getTimestamp64() - currentTermStartTime) / termDuration;
    }

    /**
    * @dev Internal function to compute the randomness that will be used to draft jurors for the given term. This
    *      function assumes the given term exists. To determine the randomness factor for a term we use the hash of a
    *      block number that is set once the term has started to ensure it cannot be known beforehand. Note that the
    *      hash function being used only works for the 256 most recent block numbers.
    * @param _termId Identification number of the term being queried
    * @return Randomness computed for the given term
    */
    function _computeTermRandomness(uint64 _termId) internal view returns (bytes32) {
        Term storage term = terms[_termId];
        require(getBlockNumber64() > term.randomnessBN, ERROR_TERM_RANDOMNESS_NOT_YET);
        return blockhash(term.randomnessBN);
    }

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *         1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *         2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @return maxRulingOptions Max number of selectable outcomes for each dispute
    * @return roundParams Array containing durations of phases of a dispute and other params for rounds:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    *         5. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *         6. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *         7. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         8. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return jurorsParams Array containing params for juror registry:
    *         0. minActiveBalance Minimum amount of juror tokens that can be activated
    *         1. minMaxPctTotalSupply The min max percent of the total supply a juror can activate, applied for total supply active stake
    *         2. maxMaxPctTotalSupply The max max percent of the total supply a juror can activate, applied for 0 active stake
    *         3. feeTokenTotalSupply Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do

    */
    function _getConfig(uint64 _termId) internal view returns (
        ERC20 feeToken,
        uint256[3] memory fees,
        uint8 maxRulingOptions,
        uint64[9] memory roundParams,
        uint16[2] memory pcts,
        uint256[2] memory appealCollateralParams,
        uint256[4] memory jurorsParams
    );
}

// File: contracts/court/config/IConfig.sol

pragma solidity ^0.5.8;



interface IConfig {

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *         1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *         2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @return maxRulingOptions Max number of selectable outcomes for each dispute
    * @return roundParams Array containing durations of phases of a dispute and other params for rounds:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    *         5. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *         6. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *         7. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         8. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return jurorsParams Array containing params for juror registry:
    *         0. minActiveBalance Minimum amount of juror tokens that can be activated
    *         1. minMaxPctTotalSupply The min max percent of the total supply a juror can activate, applied for total supply active stake
    *         2. maxMaxPctTotalSupply The max max percent of the total supply a juror can activate, applied for 0 active stake
    *         3. feeTokenTotalSupply Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do
    */
    function getConfig(uint64 _termId) external view
        returns (
            ERC20 feeToken,
            uint256[3] memory fees,
            uint8 maxRulingOptions,
            uint64[9] memory roundParams,
            uint16[2] memory pcts,
            uint256[2] memory appealCollateralParams,
            uint256[4] memory jurorsParams
        );

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per juror to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (ERC20 feeToken, uint256 draftFee, uint16 penaltyPct);

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Term querying the min active balance config of
    * @return Minimum amount of tokens jurors have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256);

    /**
    * @dev Tell whether a certain holder accepts automatic withdrawals of tokens or not
    * @return True if the given holder accepts automatic withdrawals of their tokens, false otherwise
    */
    function areWithdrawalsAllowedFor(address _holder) external view returns (bool);
}

// File: contracts/court/config/CourtConfigData.sol

pragma solidity ^0.5.8;



contract CourtConfigData {

    struct Config {
        FeesConfig fees;                        // Full fees-related config
        DisputesConfig disputes;                // Full disputes-related config
        JurorsConfig jurors;                    // Full juror-related config
    }

    struct FeesConfig {
        ERC20 token;                            // ERC20 token to be used for the fees of the Court
        uint16 finalRoundReduction;             // Permyriad of fees reduction applied for final appeal round (‱ - 1/10,000)
        uint256 jurorFee;                       // Amount of tokens paid to draft a juror to adjudicate a dispute
        uint256 draftFee;                       // Amount of tokens paid per round to cover the costs of drafting jurors
        uint256 settleFee;                      // Amount of tokens paid per round to cover the costs of slashing jurors
    }

    struct DisputesConfig {
        uint8 maxRulingOptions;                 // Max number of ruling options selectable by jurors for a dispute
        uint64 evidenceTerms;                   // Max submitting evidence period duration in terms
        uint64 commitTerms;                     // Committing period duration in terms
        uint64 revealTerms;                     // Revealing period duration in terms
        uint64 appealTerms;                     // Appealing period duration in terms
        uint64 appealConfirmTerms;              // Confirmation appeal period duration in terms
        uint16 penaltyPct;                      // Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
        uint64 firstRoundJurorsNumber;          // Number of jurors drafted on first round
        uint64 appealStepFactor;                // Factor in which the jurors number is increased on each appeal
        uint64 finalRoundLockTerms;             // Period a coherent juror in the final round will remain locked
        uint256 maxRegularAppealRounds;         // Before the final appeal
        uint256 appealCollateralFactor;         // Permyriad multiple of dispute fees required to appeal a preliminary ruling (‱ - 1/10,000)
        uint256 appealConfirmCollateralFactor;  // Permyriad multiple of dispute fees required to confirm appeal (‱ - 1/10,000)
    }

    struct JurorsConfig {
        uint256 minActiveBalance;               // Minimum amount of tokens jurors have to activate to participate in the Court
        uint256 minMaxPctTotalSupply;           // Minimum max percent of the total supply a juror can activate, applied for total supply active stake
        uint256 maxMaxPctTotalSupply;           // Maximum max percent of the total supply a juror can activate, applied for 0 active stake
        uint256 feeTokenTotalSupply;            // Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do
    }

    struct DraftConfig {
        ERC20 feeToken;                         // ERC20 token to be used for the fees of the Court
        uint16 penaltyPct;                      // Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
        uint256 draftFee;                       // Amount of tokens paid per round to cover the costs of drafting jurors
    }
}

// File: contracts/court/config/CourtConfig.sol

pragma solidity ^0.5.8;







contract CourtConfig is IConfig, CourtConfigData {
    using SafeMath64 for uint64;
    using PctHelpers for uint256;

    string private constant ERROR_TOO_OLD_TERM = "CONF_TOO_OLD_TERM";
    string private constant ERROR_RULING_OPTIONS_LESS_THAN_MIN = "CONF_RULING_OPTIONS_LESS_THAN_MIN";
    string private constant ERROR_RULING_OPTIONS_MORE_THAN_MAX = "CONF_RULING_OPTIONS_MORE_THAN_MAX";
    string private constant ERROR_INVALID_PENALTY_PCT = "CONF_INVALID_PENALTY_PCT";
    string private constant ERROR_INVALID_FINAL_ROUND_REDUCTION_PCT = "CONF_INVALID_FINAL_ROUND_RED_PCT";
    string private constant ERROR_INVALID_MAX_APPEAL_ROUNDS = "CONF_INVALID_MAX_APPEAL_ROUNDS";
    string private constant ERROR_LARGE_ROUND_PHASE_DURATION = "CONF_LARGE_ROUND_PHASE_DURATION";
    string private constant ERROR_BAD_INITIAL_JURORS_NUMBER = "CONF_BAD_INITIAL_JURORS_NUMBER";
    string private constant ERROR_BAD_APPEAL_STEP_FACTOR = "CONF_BAD_APPEAL_STEP_FACTOR";
    string private constant ERROR_ZERO_COLLATERAL_FACTOR = "CONF_ZERO_COLLATERAL_FACTOR";
    string private constant ERROR_ZERO_MIN_ACTIVE_BALANCE = "CONF_ZERO_MIN_ACTIVE_BALANCE";
    string private constant ERROR_MIN_MAX_TOTAL_SUPPLY_ZERO = "CONF_MIN_MAX_TOTAL_SUPPLY_ZERO";
    string private constant ERROR_INVALID_MAX_MAX_TOTAL_SUPPLY_PCT = "CONF_INVALID_MAX_MAX_TOTAL_SUPPLY_PCT";
    string private constant ERROR_MIN_MORE_THAN_MAX_ACTIVE_PCT = "CONF_MIN_MORE_THAN_MAX_ACTIVE_PCT";

    // Max number of terms that each of the different adjudication states can last (if lasted 1h, this would be a year)
    uint64 internal constant MAX_ADJ_STATE_DURATION = 8670;

    // Cap the max number of regular appeal rounds
    uint256 internal constant MAX_REGULAR_APPEAL_ROUNDS_LIMIT = 10;

    // Future term ID in which a config change has been scheduled
    uint64 private configChangeTermId;

    // List of all the configs used in the Court
    Config[] private configs;

    // List of configs indexed by id
    mapping (uint64 => uint256) private configIdByTerm;

    // Holders opt-in config for automatic withdrawals
    mapping (address => bool) private withdrawalsAllowed;

    event NewConfig(uint64 fromTermId, uint64 courtConfigId);
    event AutomaticWithdrawalsAllowedChanged(address indexed holder, bool allowed);

    /**
    * @dev Constructor function
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *        1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *        2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @param _maxRulingOptions Max number of selectable outcomes for each dispute
    * @param _roundParams Array containing durations of phases of a dispute and other params for rounds:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    *        5. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *        6. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *        7. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        8. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @param _jurorsParams Array containing params for juror registry:
    *        0. minActiveBalance Minimum amount of juror tokens that can be activated
    *        1. minMaxPctTotalSupply The min max percent of the total supply a juror can activate, applied for total supply active stake
    *        2. maxMaxPctTotalSupply The max max percent of the total supply a juror can activate, applied for 0 active stake
    *        3. feeTokenTotalSupply Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do
    */
    constructor(
        ERC20 _feeToken,
        uint256[3] memory _fees,
        uint8 _maxRulingOptions,
        uint64[9] memory _roundParams,
        uint16[2] memory _pcts,
        uint256[2] memory _appealCollateralParams,
        uint256[4] memory _jurorsParams
    )
        public
    {
        // Leave config at index 0 empty for non-scheduled config changes
        configs.length = 1;
        _setConfig(
            0,
            0,
            _feeToken,
            _fees,
            _maxRulingOptions,
            _roundParams,
            _pcts,
            _appealCollateralParams,
            _jurorsParams
        );
    }

    /**
    * @notice Set the automatic withdrawals config for the sender to `_allowed`
    * @param _allowed Whether or not the automatic withdrawals are allowed by the sender
    */
    function setAutomaticWithdrawals(bool _allowed) external {
        withdrawalsAllowed[msg.sender] = _allowed;
        emit AutomaticWithdrawalsAllowedChanged(msg.sender, _allowed);
    }

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *         1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *         2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @return maxRulingOptions Max number of selectable outcomes for each dispute
    * @return roundParams Array containing durations of phases of a dispute and other params for rounds:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    *         5. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *         6. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *         7. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         8. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return jurorsParams Array containing params for juror registry:
    *         0. minActiveBalance Minimum amount of juror tokens that can be activated
    *         1. minMaxPctTotalSupply The min max percent of the total supply a juror can activate, applied for total supply active stake
    *         2. maxMaxPctTotalSupply The max max percent of the total supply a juror can activate, applied for 0 active stake
    *         3. feeTokenTotalSupply Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do
    */
    function getConfig(uint64 _termId) external view
        returns (
            ERC20 feeToken,
            uint256[3] memory fees,
            uint8 maxRulingOptions,
            uint64[9] memory roundParams,
            uint16[2] memory pcts,
            uint256[2] memory appealCollateralParams,
            uint256[4] memory jurorsParams
        );

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per juror to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (ERC20 feeToken, uint256 draftFee, uint16 penaltyPct);

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Term querying the min active balance config of
    * @return Minimum amount of tokens jurors have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256);

    /**
    * @dev Tell whether a certain holder accepts automatic withdrawals of tokens or not
    * @param _holder Address of the token holder querying if withdrawals are allowed for
    * @return True if the given holder accepts automatic withdrawals of their tokens, false otherwise
    */
    function areWithdrawalsAllowedFor(address _holder) external view returns (bool) {
        return withdrawalsAllowed[_holder];
    }

    /**
    * @dev Tell the term identification number of the next scheduled config change
    * @return Term identification number of the next scheduled config change
    */
    function getConfigChangeTermId() external view returns (uint64) {
        return configChangeTermId;
    }

    /**
    * @dev Internal to make sure to set a config for the new term, it will copy the previous term config if none
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _ensureTermConfig(uint64 _termId) internal {
        // If the term being transitioned had no config change scheduled, keep the previous one
        uint256 currentConfigId = configIdByTerm[_termId];
        if (currentConfigId == 0) {
            uint256 previousConfigId = configIdByTerm[_termId.sub(1)];
            configIdByTerm[_termId] = previousConfigId;
        }
    }

    /**
    * @dev Assumes that sender it's allowed (either it's from governor or it's on init)
    * @param _termId Identification number of the current Court term
    * @param _fromTermId Identification number of the term in which the config will be effective at
    * @param _feeToken Address of the token contract that is used to pay for fees.
    * @param _fees Array containing:
    *        0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *        1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *        2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @param _maxRulingOptions Max number of selectable outcomes for each dispute
    * @param _roundParams Array containing durations of phases of a dispute and other params for rounds:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    *        5. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *        6. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *        7. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        8. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @param _jurorsParams Array containing params for juror registry:
    *        0. minActiveBalance Minimum amount of juror tokens that can be activated
    *        1. minMaxPctTotalSupply The min max percent of the total supply a juror can activate, applied for total supply active stake
    *        2. maxMaxPctTotalSupply The max max percent of the total supply a juror can activate, applied for 0 active stake
    *        3. feeTokenTotalSupply Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do
    */
    function _setConfig(
        uint64 _termId,
        uint64 _fromTermId,
        ERC20 _feeToken,
        uint256[3] memory _fees,
        uint8 _maxRulingOptions,
        uint64[9] memory _roundParams,
        uint16[2] memory _pcts,
        uint256[2] memory _appealCollateralParams,
        uint256[4] memory _jurorsParams
    )
        internal
    {
        // If the current term is not zero, changes must be scheduled at least after the current period.
        // No need to ensure delays for on-going disputes since these already use their creation term for that.
        require(_termId == 0 || _fromTermId > _termId, ERROR_TOO_OLD_TERM);

        require(_maxRulingOptions >= 2, ERROR_RULING_OPTIONS_LESS_THAN_MIN);
        // Ruling options 0, 1 and 2 are reserved for special cases.
        require(_maxRulingOptions <= uint8(-1) - 3, ERROR_RULING_OPTIONS_MORE_THAN_MAX);

        // Make sure appeal collateral factors are greater than zero
        require(_appealCollateralParams[0] > 0 && _appealCollateralParams[1] > 0, ERROR_ZERO_COLLATERAL_FACTOR);

        // Make sure the given penalty and final round reduction pcts are not greater than 100%
        require(PctHelpers.isValid(_pcts[0]), ERROR_INVALID_PENALTY_PCT);
        require(PctHelpers.isValid(_pcts[1]), ERROR_INVALID_FINAL_ROUND_REDUCTION_PCT);

        // Disputes must request at least one juror to be drafted initially
        require(_roundParams[5] > 0, ERROR_BAD_INITIAL_JURORS_NUMBER);

        // Prevent that further rounds have zero jurors
        require(_roundParams[6] > 0, ERROR_BAD_APPEAL_STEP_FACTOR);

        // Make sure the max number of appeals allowed does not reach the limit
        uint256 _maxRegularAppealRounds = _roundParams[7];
        bool isMaxAppealRoundsValid = _maxRegularAppealRounds > 0 && _maxRegularAppealRounds <= MAX_REGULAR_APPEAL_ROUNDS_LIMIT;
        require(isMaxAppealRoundsValid, ERROR_INVALID_MAX_APPEAL_ROUNDS);

        // Make sure each adjudication round phase duration is valid
        for (uint i = 0; i < 5; i++) {
            require(_roundParams[i] > 0 && _roundParams[i] < MAX_ADJ_STATE_DURATION, ERROR_LARGE_ROUND_PHASE_DURATION);
        }

        // Make sure min active balance is not zero
        require(_jurorsParams[0] > 0, ERROR_ZERO_MIN_ACTIVE_BALANCE);
        // Make sure min max pct of total supply active balance is not zero
        require(_jurorsParams[1] > 0, ERROR_MIN_MAX_TOTAL_SUPPLY_ZERO);
        // Make sure the max max pct of total supply active balance is less than 100%
        require(PctHelpers.isValidHighPrecision(_jurorsParams[2]), ERROR_INVALID_MAX_MAX_TOTAL_SUPPLY_PCT);
        // Make sure min max pct of total supply active balance is less than the max max pct of total supply active balance
        require(_jurorsParams[1] < _jurorsParams[2], ERROR_MIN_MORE_THAN_MAX_ACTIVE_PCT);

        // If there was a config change already scheduled, reset it (in that case we will overwrite last array item).
        // Otherwise, schedule a new config.
        if (configChangeTermId > _termId) {
            configIdByTerm[configChangeTermId] = 0;
        } else {
            configs.length++;
        }

        uint64 courtConfigId = uint64(configs.length - 1);
        Config storage config = configs[courtConfigId];

        config.fees = FeesConfig({
            token: _feeToken,
            jurorFee: _fees[0],
            draftFee: _fees[1],
            settleFee: _fees[2],
            finalRoundReduction: _pcts[1]
        });

        config.disputes = DisputesConfig({
            maxRulingOptions: _maxRulingOptions,
            evidenceTerms: _roundParams[0],
            commitTerms: _roundParams[1],
            revealTerms: _roundParams[2],
            appealTerms: _roundParams[3],
            appealConfirmTerms: _roundParams[4],
            penaltyPct: _pcts[0],
            firstRoundJurorsNumber: _roundParams[5],
            appealStepFactor: _roundParams[6],
            maxRegularAppealRounds: _maxRegularAppealRounds,
            finalRoundLockTerms: _roundParams[8],
            appealCollateralFactor: _appealCollateralParams[0],
            appealConfirmCollateralFactor: _appealCollateralParams[1]
        });

        config.jurors = JurorsConfig({
            minActiveBalance: _jurorsParams[0],
            minMaxPctTotalSupply: _jurorsParams[1],
            maxMaxPctTotalSupply: _jurorsParams[2],
            feeTokenTotalSupply: _jurorsParams[3]
        });

        configIdByTerm[_fromTermId] = courtConfigId;
        configChangeTermId = _fromTermId;

        emit NewConfig(_fromTermId, courtConfigId);
    }

    /**
    * @dev Internal function to get the Court config for a given term
    * @param _termId Identification number of the term querying the Court config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *         1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *         2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @return maxRulingOptions Max number of selectable outcomes for each dispute
    * @return roundParams Array containing durations of phases of a dispute and other params for rounds:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    *         5. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *         6. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *         7. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         8. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return jurorsParams Array containing params for juror registry:
    *         0. minActiveBalance Minimum amount of juror tokens that can be activated
    *         1. minMaxPctTotalSupply The min max percent of the total supply a juror can activate, applied for total supply active stake
    *         2. maxMaxPctTotalSupply The max max percent of the total supply a juror can activate, applied for 0 active stake
    *         3. feeTokenTotalSupply Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do
    */
    function _getConfigAt(uint64 _termId, uint64 _lastEnsuredTermId) internal view
        returns (
            ERC20 feeToken,
            uint256[3] memory fees,
            uint8 maxRulingOptions,
            uint64[9] memory roundParams,
            uint16[2] memory pcts,
            uint256[2] memory appealCollateralParams,
            uint256[4] memory jurorsParams
        )
    {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);

        FeesConfig storage feesConfig = config.fees;
        feeToken = feesConfig.token;
        fees = [feesConfig.jurorFee, feesConfig.draftFee, feesConfig.settleFee];

        DisputesConfig storage disputesConfig = config.disputes;
        maxRulingOptions = disputesConfig.maxRulingOptions;
        roundParams = [
            disputesConfig.evidenceTerms,
            disputesConfig.commitTerms,
            disputesConfig.revealTerms,
            disputesConfig.appealTerms,
            disputesConfig.appealConfirmTerms,
            disputesConfig.firstRoundJurorsNumber,
            disputesConfig.appealStepFactor,
            uint64(disputesConfig.maxRegularAppealRounds),
            disputesConfig.finalRoundLockTerms
        ];
        pcts = [disputesConfig.penaltyPct, feesConfig.finalRoundReduction];
        appealCollateralParams = [disputesConfig.appealCollateralFactor, disputesConfig.appealConfirmCollateralFactor];

        JurorsConfig storage jurorsConfig = config.jurors;
        jurorsParams = [
            jurorsConfig.minActiveBalance,
            jurorsConfig.minMaxPctTotalSupply,
            jurorsConfig.maxMaxPctTotalSupply,
            jurorsConfig.feeTokenTotalSupply
        ];
    }

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per juror to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    */
    function _getDraftConfig(uint64 _termId,  uint64 _lastEnsuredTermId) internal view
        returns (ERC20 feeToken, uint256 draftFee, uint16 penaltyPct)
    {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);
        return (config.fees.token, config.fees.draftFee, config.disputes.penaltyPct);
    }

    /**
    * @dev Internal function to get the min active balance config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Minimum amount of juror tokens that can be activated at the given term
    */
    function _getMinActiveBalance(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (uint256) {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);
        return config.jurors.minActiveBalance;
    }

    /**
    * @dev Internal function to get the Court config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Court config for the given term
    */
    function _getConfigFor(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (Config storage) {
        uint256 id = _getConfigIdFor(_termId, _lastEnsuredTermId);
        return configs[id];
    }

    /**
    * @dev Internal function to get the Court config ID for a given term
    * @param _termId Identification number of the term querying the Court config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Identification number of the config for the given terms
    */
    function _getConfigIdFor(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (uint256) {
        // If the given term is lower or equal to the last ensured Court term, it is safe to use a past Court config
        if (_termId <= _lastEnsuredTermId) {
            return configIdByTerm[_termId];
        }

        // If the given term is in the future but there is a config change scheduled before it, use the incoming config
        uint64 scheduledChangeTermId = configChangeTermId;
        if (scheduledChangeTermId <= _termId) {
            return configIdByTerm[scheduledChangeTermId];
        }

        // If no changes are scheduled, use the Court config of the last ensured term
        return configIdByTerm[_lastEnsuredTermId];
    }
}

// File: contracts/court/controller/Controller.sol

pragma solidity ^0.5.8;





contract Controller is IsContract, CourtClock, CourtConfig {
    string private constant ERROR_SENDER_NOT_GOVERNOR = "CTR_SENDER_NOT_GOVERNOR";
    string private constant ERROR_INVALID_GOVERNOR_ADDRESS = "CTR_INVALID_GOVERNOR_ADDRESS";
    string private constant ERROR_IMPLEMENTATION_NOT_CONTRACT = "CTR_IMPLEMENTATION_NOT_CONTRACT";
    string private constant ERROR_INVALID_IMPLS_INPUT_LENGTH = "CTR_INVALID_IMPLS_INPUT_LENGTH";

    address private constant ZERO_ADDRESS = address(0);

    // DisputeManager module ID - keccak256(abi.encodePacked("DISPUTE_MANAGER"))
    bytes32 internal constant DISPUTE_MANAGER = 0x14a6c70f0f6d449c014c7bbc9e68e31e79e8474fb03b7194df83109a2d888ae6;

    // Treasury module ID - keccak256(abi.encodePacked("TREASURY"))
    bytes32 internal constant TREASURY = 0x06aa03964db1f7257357ef09714a5f0ca3633723df419e97015e0c7a3e83edb7;

    // Voting module ID - keccak256(abi.encodePacked("VOTING"))
    bytes32 internal constant VOTING = 0x7cbb12e82a6d63ff16fe43977f43e3e2b247ecd4e62c0e340da8800a48c67346;

    // JurorsRegistry module ID - keccak256(abi.encodePacked("JURORS_REGISTRY"))
    bytes32 internal constant JURORS_REGISTRY = 0x3b21d36b36308c830e6c4053fb40a3b6d79dde78947fbf6b0accd30720ab5370;

    // Subscriptions module ID - keccak256(abi.encodePacked("SUBSCRIPTIONS"))
    bytes32 internal constant SUBSCRIPTIONS = 0x2bfa3327fe52344390da94c32a346eeb1b65a8b583e4335a419b9471e88c1365;

    // BrightIDRegister module ID - keccak256(abi.encodePacked("BRIGHTID_REGISTER"))
    bytes32 internal constant BRIGHTID_REGISTER = 0xc8d8a5444a51ecc23e5091f18c4162834512a4bc5cae72c637db45c8c37b3329;

    /**
    * @dev Governor of the whole system. Set of three addresses to recover funds, change configuration settings and setup modules
    */
    struct Governor {
        address funds;      // This address can be unset at any time. It is allowed to recover funds from the ControlledRecoverable modules
        address config;     // This address is meant not to be unset. It is allowed to change the different configurations of the whole system
        address feesUpdater;// This is a second address that can update the config. It is expected to be used with a price oracle for updating fees
        address modules;    // This address can be unset at any time. It is allowed to plug/unplug modules from the system
    }

    // Governor addresses of the system
    Governor private governor;

    // List of modules registered for the system indexed by ID
    mapping (bytes32 => address) internal modules;

    event ModuleSet(bytes32 id, address addr);
    event FundsGovernorChanged(address previousGovernor, address currentGovernor);
    event ConfigGovernorChanged(address previousGovernor, address currentGovernor);
    event FeesUpdaterChanged(address previousFeesUpdater, address currentFeesUpdater);
    event ModulesGovernorChanged(address previousGovernor, address currentGovernor);

    /**
    * @dev Ensure the msg.sender is the funds governor
    */
    modifier onlyFundsGovernor {
        require(msg.sender == governor.funds, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the config governor
    */
    modifier onlyConfigGovernor {
        require(msg.sender == governor.config, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the config governor or the fees updater
    */
    modifier onlyConfigGovernorOrFeesUpdater {
        require(msg.sender == governor.config || msg.sender == governor.feesUpdater, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the modules governor
    */
    modifier onlyModulesGovernor {
        require(msg.sender == governor.modules, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Constructor function
    * @param _termParams Array containing:
    *        0. _termDuration Duration in seconds per term
    *        1. _firstTermStartTime Timestamp in seconds when the court will open (to give time for juror on-boarding)
    * @param _governors Array containing:
    *        0. _fundsGovernor Address of the funds governor
    *        1. _configGovernor Address of the config governor
    *        2. _feesUpdater Address of the price feesUpdater
    *        3. _modulesGovernor Address of the modules governor
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *        1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *        2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @param _maxRulingOptions Max number of selectable outcomes for each dispute
    * @param _roundParams Array containing durations of phases of a dispute and other params for rounds:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    *        5. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *        6. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *        7. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        8. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked to each drafted jurors (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Permyriad multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Permyriad multiple of dispute fees required to confirm appeal
    * @param _jurorsParams Array containing params for jurors:
    *        0. minActiveBalance Minimum amount of juror tokens that can be activated
    *        1. minMaxPctTotalSupply The min max percent of the total supply a juror can activate, applied for total supply active stake
    *        2. maxMaxPctTotalSupply The max max percent of the total supply a juror can activate, applied for 0 active stake
    *        3. feeTokenTotalSupply Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do
    */
    constructor(
        uint64[2] memory _termParams,
        address[4] memory _governors,
        ERC20 _feeToken,
        uint256[3] memory _fees,
        uint8 _maxRulingOptions,
        uint64[9] memory _roundParams,
        uint16[2] memory _pcts,
        uint256[2] memory _appealCollateralParams,
        uint256[4] memory _jurorsParams
    )
        public
        CourtClock(_termParams, _feeToken)
        CourtConfig(_feeToken, _fees, _maxRulingOptions, _roundParams, _pcts, _appealCollateralParams, _jurorsParams)
    {
        _setFundsGovernor(_governors[0]);
        _setConfigGovernor(_governors[1]);
        _setFeesUpdater(_governors[2]);
        _setModulesGovernor(_governors[3]);
    }

    /**
    * @notice Change Court configuration params
    * @param _fromTermId Identification number of the term in which the config will be effective at
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *        1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *        2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @param _maxRulingOptions Max number of selectable outcomes for each dispute
    * @param _roundParams Array containing durations of phases of a dispute and other params for rounds:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    *        5. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *        6. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *        7. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        8. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked to each drafted jurors (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Permyriad multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Permyriad multiple of dispute fees required to confirm appeal
    * @param _jurorsParams Array containing params for jurors:
    *        0. minActiveBalance Minimum amount of juror tokens that can be activated
    *        1. minMaxPctTotalSupply The min max percent of the total supply a juror can activate, applied for total supply active stake
    *        2. maxMaxPctTotalSupply The max max percent of the total supply a juror can activate, applied for 0 active stake
    *        3. feeTokenTotalSupply Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do
    */
    function setConfig(
        uint64 _fromTermId,
        ERC20 _feeToken,
        uint256[3] calldata _fees,
        uint8 _maxRulingOptions,
        uint64[9] calldata _roundParams,
        uint16[2] calldata _pcts,
        uint256[2] calldata _appealCollateralParams,
        uint256[4] calldata _jurorsParams
    )
        external
        onlyConfigGovernorOrFeesUpdater
    {
        uint64 currentTermId = _ensureCurrentTerm();
        _setConfig(
            currentTermId,
            _fromTermId,
            _feeToken,
            _fees,
            _maxRulingOptions,
            _roundParams,
            _pcts,
            _appealCollateralParams,
            _jurorsParams
        );
    }

    /**
    * @notice Delay the Court start time to `_newFirstTermStartTime`
    * @param _newFirstTermStartTime New timestamp in seconds when the court will open
    */
    function delayStartTime(uint64 _newFirstTermStartTime) external onlyConfigGovernor {
        _delayStartTime(_newFirstTermStartTime);
    }

    /**
    * @notice Change funds governor address to `_newFundsGovernor`
    * @param _newFundsGovernor Address of the new funds governor to be set
    */
    function changeFundsGovernor(address _newFundsGovernor) external onlyFundsGovernor {
        require(_newFundsGovernor != ZERO_ADDRESS, ERROR_INVALID_GOVERNOR_ADDRESS);
        _setFundsGovernor(_newFundsGovernor);
    }

    /**
    * @notice Change config governor address to `_newConfigGovernor`
    * @param _newConfigGovernor Address of the new config governor to be set
    */
    function changeConfigGovernor(address _newConfigGovernor) external onlyConfigGovernor {
        require(_newConfigGovernor != ZERO_ADDRESS, ERROR_INVALID_GOVERNOR_ADDRESS);
        _setConfigGovernor(_newConfigGovernor);
    }

    /**
    * @notice Change fees updater to `_newFeesUpdater`
    * @param _newFeesUpdater Address of the new fees updater to be set
    */
    function changeFeesUpdater(address _newFeesUpdater) external onlyConfigGovernor {
        _setFeesUpdater(_newFeesUpdater);
    }

    /**
    * @notice Change modules governor address to `_newModulesGovernor`
    * @param _newModulesGovernor Address of the new governor to be set
    */
    function changeModulesGovernor(address _newModulesGovernor) external onlyModulesGovernor {
        require(_newModulesGovernor != ZERO_ADDRESS, ERROR_INVALID_GOVERNOR_ADDRESS);
        _setModulesGovernor(_newModulesGovernor);
    }

    /**
    * @notice Remove the funds governor. Set the funds governor to the zero address.
    * @dev This action cannot be rolled back, once the funds governor has been unset, funds cannot be recovered from recoverable modules anymore
    */
    function ejectFundsGovernor() external onlyFundsGovernor {
        _setFundsGovernor(ZERO_ADDRESS);
    }

    /**
    * @notice Remove the modules governor. Set the modules governor to the zero address.
    * @dev This action cannot be rolled back, once the modules governor has been unset, system modules cannot be changed anymore
    */
    function ejectModulesGovernor() external onlyModulesGovernor {
        _setModulesGovernor(ZERO_ADDRESS);
    }

    /**
    * @notice Set module `_id` to `_addr`
    * @param _id ID of the module to be set
    * @param _addr Address of the module to be set
    */
    function setModule(bytes32 _id, address _addr) external onlyModulesGovernor {
        _setModule(_id, _addr);
    }

    /**
    * @notice Set many modules at once
    * @param _ids List of ids of each module to be set
    * @param _addresses List of addressed of each the module to be set
    */
    function setModules(bytes32[] calldata _ids, address[] calldata _addresses) external onlyModulesGovernor {
        require(_ids.length == _addresses.length, ERROR_INVALID_IMPLS_INPUT_LENGTH);

        for (uint256 i = 0; i < _ids.length; i++) {
            _setModule(_ids[i], _addresses[i]);
        }
    }

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *         1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *         2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @return maxRulingOptions Max number of selectable outcomes for each dispute
    * @return roundParams Array containing durations of phases of a dispute and other params for rounds:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    *         5. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *         6. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *         7. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         8. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return jurorsParams Array containing params for juror registry:
    *         0. minActiveBalance Minimum amount of juror tokens that can be activated
    *         1. minMaxPctTotalSupply The min max percent of the total supply a juror can activate, applied for total supply active stake
    *         2. maxMaxPctTotalSupply The max max percent of the total supply a juror can activate, applied for 0 active stake\
    *         3. feeTokenTotalSupply Set for networks that don't have access to the fee token's total supply, set to 0 for networks that do
    */
    function getConfig(uint64 _termId) external view
        returns (
            ERC20 feeToken,
            uint256[3] memory fees,
            uint8 maxRulingOptions,
            uint64[9] memory roundParams,
            uint16[2] memory pcts,
            uint256[2] memory appealCollateralParams,
            uint256[4] memory jurorsParams
        )
    {
        return _getConfig(_termId);
    }

    /**
    * @dev This function overrides one in the CourtClock, giving the CourtClock access to the config.
    */
    function _getConfig(uint64 _termId) internal view
        returns (
            ERC20 feeToken,
            uint256[3] memory fees,
            uint8 maxRulingOptions,
            uint64[9] memory roundParams,
            uint16[2] memory pcts,
            uint256[2] memory appealCollateralParams,
            uint256[4] memory jurorsParams
        )
    {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getConfigAt(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per juror to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (ERC20 feeToken, uint256 draftFee, uint16 penaltyPct) {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getDraftConfig(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Identification number of the term querying the min active balance config of
    * @return Minimum amount of tokens jurors have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256) {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getMinActiveBalance(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the address of the funds governor
    * @return Address of the funds governor
    */
    function getFundsGovernor() external view returns (address) {
        return governor.funds;
    }

    /**
    * @dev Tell the address of the config governor
    * @return Address of the config governor
    */
    function getConfigGovernor() external view returns (address) {
        return governor.config;
    }

    /**
    * @dev Tell the address of the fees updater
    * @return Address of the fees updater
    */
    function getFeesUpdater() external view returns (address) {
        return governor.feesUpdater;
    }

    /**
    * @dev Tell the address of the modules governor
    * @return Address of the modules governor
    */
    function getModulesGovernor() external view returns (address) {
        return governor.modules;
    }

    /**
    * @dev Tell address of a module based on a given ID
    * @param _id ID of the module being queried
    * @return Address of the requested module
    */
    function getModule(bytes32 _id) external view returns (address) {
        return _getModule(_id);
    }

    /**
    * @dev Tell the address of the DisputeManager module
    * @return Address of the DisputeManager module
    */
    function getDisputeManager() external view returns (address) {
        return _getDisputeManager();
    }

    /**
    * @dev Tell the address of the Treasury module
    * @return Address of the Treasury module
    */
    function getTreasury() external view returns (address) {
        return _getModule(TREASURY);
    }

    /**
    * @dev Tell the address of the Voting module
    * @return Address of the Voting module
    */
    function getVoting() external view returns (address) {
        return _getModule(VOTING);
    }

    /**
    * @dev Tell the address of the JurorsRegistry module
    * @return Address of the JurorsRegistry module
    */
    function getJurorsRegistry() external view returns (address) {
        return _getModule(JURORS_REGISTRY);
    }

    /**
    * @dev Tell the address of the Subscriptions module
    * @return Address of the Subscriptions module
    */
    function getSubscriptions() external view returns (address) {
        return _getSubscriptions();
    }

    /**
    * @dev Tell the address of the BrightId register
    * @return Address of the BrightId register
    */
    function getBrightIdRegister() external view returns (address) {
        return _getBrightIdRegister();
    }

    /**
    * @dev Internal function to set the address of the funds governor
    * @param _newFundsGovernor Address of the new config governor to be set
    */
    function _setFundsGovernor(address _newFundsGovernor) internal {
        emit FundsGovernorChanged(governor.funds, _newFundsGovernor);
        governor.funds = _newFundsGovernor;
    }

    /**
    * @dev Internal function to set the address of the config governor
    * @param _newConfigGovernor Address of the new config governor to be set
    */
    function _setConfigGovernor(address _newConfigGovernor) internal {
        emit ConfigGovernorChanged(governor.config, _newConfigGovernor);
        governor.config = _newConfigGovernor;
    }

    /**
    * @dev Internal function to set the address of the fees updater
    * @param _newFeesUpdater Address of the new fees updater to be set
    */
    function _setFeesUpdater(address _newFeesUpdater) internal {
        emit FeesUpdaterChanged(governor.feesUpdater, _newFeesUpdater);
        governor.feesUpdater = _newFeesUpdater;
    }

    /**
    * @dev Internal function to set the address of the modules governor
    * @param _newModulesGovernor Address of the new modules governor to be set
    */
    function _setModulesGovernor(address _newModulesGovernor) internal {
        emit ModulesGovernorChanged(governor.modules, _newModulesGovernor);
        governor.modules = _newModulesGovernor;
    }

    /**
    * @dev Internal function to set a module
    * @param _id Id of the module to be set
    * @param _addr Address of the module to be set
    */
    function _setModule(bytes32 _id, address _addr) internal {
        require(isContract(_addr), ERROR_IMPLEMENTATION_NOT_CONTRACT);
        modules[_id] = _addr;
        emit ModuleSet(_id, _addr);
    }

    /**
    * @dev Internal function to notify when a term has been transitioned
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _onTermTransitioned(uint64 _termId) internal {
        _ensureTermConfig(_termId);
    }

    /**
    * @dev Internal function to tell the address of the DisputeManager module
    * @return Address of the DisputeManager module
    */
    function _getDisputeManager() internal view returns (address) {
        return _getModule(DISPUTE_MANAGER);
    }

    /**
    * @dev Internal function to tell the address of the Subscriptions module
    * @return Address of the Subscriptions module
    */
    function _getSubscriptions() internal view returns (address) {
        return _getModule(SUBSCRIPTIONS);
    }


    /**
    * @dev Internal function to tell the address of the BrightId register
    * @return Address of the BrightId register
    */
    function _getBrightIdRegister() internal view returns (address) {
        return _getModule(BRIGHTID_REGISTER);
    }

    /**
    * @dev Internal function to tell address of a module based on a given ID
    * @param _id ID of the module being queried
    * @return Address of the requested module
    */
    function _getModule(bytes32 _id) internal view returns (address) {
        return modules[_id];
    }
}

// File: contracts/court/config/ConfigConsumer.sol

pragma solidity ^0.5.8;





contract ConfigConsumer is CourtConfigData {
    /**
    * @dev Internal function to fetch the address of the Config module from the controller
    * @return Address of the Config module
    */
    function _courtConfig() internal view returns (IConfig);

    /**
    * @dev Internal function to get the Court config for a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return Court config for the given term
    */
    function _getConfigAt(uint64 _termId) internal view returns (Config memory) {
        (ERC20 _feeToken,
        uint256[3] memory _fees,
        uint8 maxRulingOptions,
        uint64[9] memory _roundParams,
        uint16[2] memory _pcts,
        uint256[2] memory _appealCollateralParams,
        uint256[4] memory _jurorsParams) = _courtConfig().getConfig(_termId);

        Config memory config;

        config.fees = FeesConfig({
            token: _feeToken,
            jurorFee: _fees[0],
            draftFee: _fees[1],
            settleFee: _fees[2],
            finalRoundReduction: _pcts[1]
        });

        config.disputes = DisputesConfig({
            maxRulingOptions: maxRulingOptions,
            evidenceTerms: _roundParams[0],
            commitTerms: _roundParams[1],
            revealTerms: _roundParams[2],
            appealTerms: _roundParams[3],
            appealConfirmTerms: _roundParams[4],
            penaltyPct: _pcts[0],
            firstRoundJurorsNumber: _roundParams[5],
            appealStepFactor: _roundParams[6],
            maxRegularAppealRounds: _roundParams[7],
            finalRoundLockTerms: _roundParams[8],
            appealCollateralFactor: _appealCollateralParams[0],
            appealConfirmCollateralFactor: _appealCollateralParams[1]
        });

        config.jurors = JurorsConfig({
            minActiveBalance: _jurorsParams[0],
            minMaxPctTotalSupply: _jurorsParams[1],
            maxMaxPctTotalSupply: _jurorsParams[2],
            feeTokenTotalSupply: _jurorsParams[3]
        });

        return config;
    }

    /**
    * @dev Internal function to get the draft config for a given term
    * @param _termId Identification number of the term querying the draft config of
    * @return Draft config for the given term
    */
    function _getDraftConfig(uint64 _termId) internal view returns (DraftConfig memory) {
        (ERC20 feeToken, uint256 draftFee, uint16 penaltyPct) = _courtConfig().getDraftConfig(_termId);
        return DraftConfig({ feeToken: feeToken, draftFee: draftFee, penaltyPct: penaltyPct });
    }

    /**
    * @dev Internal function to get the min active balance config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @return Minimum amount of juror tokens that can be activated
    */
    function _getMinActiveBalance(uint64 _termId) internal view returns (uint256) {
        return _courtConfig().getMinActiveBalance(_termId);
    }
}

// File: contracts/brightid/IBrightIdRegister.sol

pragma solidity ^0.5.8;

contract IBrightIdRegister {
    function isVerified(address _brightIdUser) external view returns (bool);
    function hasUniqueUserId(address _brightIdUser) external view returns (bool);
    function uniqueUserId(address _brightIdUser) external view returns (address);
}

// File: contracts/court/controller/Controlled.sol

pragma solidity ^0.5.8;










contract Controlled is IsContract, ConfigConsumer {
    string private constant ERROR_CONTROLLER_NOT_CONTRACT = "CTD_CONTROLLER_NOT_CONTRACT";
    string private constant ERROR_SENDER_NOT_CONTROLLER = "CTD_SENDER_NOT_CONTROLLER";
    string private constant ERROR_SENDER_NOT_CONFIG_GOVERNOR = "CTD_SENDER_NOT_CONFIG_GOVERNOR";
    string private constant ERROR_SENDER_NOT_DISPUTES_MODULE = "CTD_SENDER_NOT_DISPUTES_MODULE";

    // Address of the controller
    Controller internal controller;

    /**
    * @dev Ensure the msg.sender is the controller's config governor
    */
    modifier onlyConfigGovernor {
        require(msg.sender == _configGovernor(), ERROR_SENDER_NOT_CONFIG_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the controller
    */
    modifier onlyController() {
        require(msg.sender == address(controller), ERROR_SENDER_NOT_CONTROLLER);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the DisputeManager module
    */
    modifier onlyDisputeManager() {
        require(msg.sender == address(_disputeManager()), ERROR_SENDER_NOT_DISPUTES_MODULE);
        _;
    }

    /**
    * @dev Constructor function
    * @param _controller Address of the controller
    */
    constructor(Controller _controller) public {
        require(isContract(address(_controller)), ERROR_CONTROLLER_NOT_CONTRACT);
        controller = _controller;
    }

    /**
    * @dev Tell the address of the controller
    * @return Address of the controller
    */
    function getController() external view returns (Controller) {
        return controller;
    }

    /**
    * @dev Internal function to ensure the Court term is up-to-date, it will try to update it if not
    * @return Identification number of the current Court term
    */
    function _ensureCurrentTerm() internal returns (uint64) {
        return _clock().ensureCurrentTerm();
    }

    /**
    * @dev Internal function to fetch the last ensured term ID of the Court
    * @return Identification number of the last ensured term
    */
    function _getLastEnsuredTermId() internal view returns (uint64) {
        return _clock().getLastEnsuredTermId();
    }

    /**
    * @dev Internal function to tell the current term identification number
    * @return Identification number of the current term
    */
    function _getCurrentTermId() internal view returns (uint64) {
        return _clock().getCurrentTermId();
    }

    /**
    * @dev Internal function to fetch the controller's config governor
    * @return Address of the controller's governor
    */
    function _configGovernor() internal view returns (address) {
        return controller.getConfigGovernor();
    }

    /**
    * @dev Internal function to fetch the address of the DisputeManager module from the controller
    * @return Address of the DisputeManager module
    */
    function _disputeManager() internal view returns (IDisputeManager) {
        return IDisputeManager(controller.getDisputeManager());
    }

    /**
    * @dev Internal function to fetch the address of the Treasury module implementation from the controller
    * @return Address of the Treasury module implementation
    */
    function _treasury() internal view returns (ITreasury) {
        return ITreasury(controller.getTreasury());
    }

    /**
    * @dev Internal function to fetch the address of the Voting module implementation from the controller
    * @return Address of the Voting module implementation
    */
    function _voting() internal view returns (ICRVoting) {
        return ICRVoting(controller.getVoting());
    }

    /**
    * @dev Internal function to fetch the address of the Voting module owner from the controller
    * @return Address of the Voting module owner
    */
    function _votingOwner() internal view returns (ICRVotingOwner) {
        return ICRVotingOwner(address(_disputeManager()));
    }

    /**
    * @dev Internal function to fetch the address of the JurorRegistry module implementation from the controller
    * @return Address of the JurorRegistry module implementation
    */
    function _jurorsRegistry() internal view returns (IJurorsRegistry) {
        return IJurorsRegistry(controller.getJurorsRegistry());
    }

    /**
    * @dev Internal function to fetch the address of the BrightId register implementation from the controller
    * @return Address of the BrightId register implementation
    */
    function _brightIdRegister() internal view returns (IBrightIdRegister) {
        return IBrightIdRegister(controller.getBrightIdRegister());
    }

    /**
    * @dev Internal function to fetch the address of the Clock module from the controller
    * @return Address of the Clock module
    */
    function _clock() internal view returns (IClock) {
        return IClock(controller);
    }

    /**
    * @dev Internal function to fetch the address of the Config module from the controller
    * @return Address of the Config module
    */
    function _courtConfig() internal view returns (IConfig) {
        return IConfig(controller);
    }
}

// File: contracts/court/controller/ControlledRecoverable.sol

pragma solidity ^0.5.8;





contract ControlledRecoverable is Controlled {
    using SafeERC20 for ERC20;

    string private constant ERROR_SENDER_NOT_FUNDS_GOVERNOR = "CTD_SENDER_NOT_FUNDS_GOVERNOR";
    string private constant ERROR_INSUFFICIENT_RECOVER_FUNDS = "CTD_INSUFFICIENT_RECOVER_FUNDS";
    string private constant ERROR_RECOVER_TOKEN_FUNDS_FAILED = "CTD_RECOVER_TOKEN_FUNDS_FAILED";

    event RecoverFunds(ERC20 token, address recipient, uint256 balance);

    /**
    * @dev Ensure the msg.sender is the controller's funds governor
    */
    modifier onlyFundsGovernor {
        require(msg.sender == controller.getFundsGovernor(), ERROR_SENDER_NOT_FUNDS_GOVERNOR);
        _;
    }

    /**
    * @dev Constructor function
    * @param _controller Address of the controller
    */
    constructor(Controller _controller) Controlled(_controller) public {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
    * @notice Transfer all `_token` tokens to `_to`
    * @param _token ERC20 token to be recovered
    * @param _to Address of the recipient that will be receive all the funds of the requested token
    */
    function recoverFunds(ERC20 _token, address _to) external onlyFundsGovernor {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, ERROR_INSUFFICIENT_RECOVER_FUNDS);
        require(_token.safeTransfer(_to, balance), ERROR_RECOVER_TOKEN_FUNDS_FAILED);
        emit RecoverFunds(_token, _to, balance);
    }
}

// File: contracts/disputes/DisputeManager.sol

pragma solidity ^0.5.8;















contract DisputeManager is ControlledRecoverable, ICRVotingOwner, IDisputeManager {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using PctHelpers for uint256;
    using Uint256Helpers for uint256;

    // Voting-related error messages
    string private constant ERROR_VOTER_WEIGHT_ZERO = "DM_VOTER_WEIGHT_ZERO";
    string private constant ERROR_SENDER_NOT_VOTING = "DM_SENDER_NOT_VOTING";

    // Disputes-related error messages
    string private constant ERROR_SUBJECT_NOT_DISPUTE_SUBJECT = "DM_SUBJECT_NOT_DISPUTE_SUBJECT";
    string private constant ERROR_EVIDENCE_PERIOD_IS_CLOSED = "DM_EVIDENCE_PERIOD_IS_CLOSED";
    string private constant ERROR_TERM_OUTDATED = "DM_TERM_OUTDATED";
    string private constant ERROR_DISPUTE_DOES_NOT_EXIST = "DM_DISPUTE_DOES_NOT_EXIST";
    string private constant ERROR_INVALID_RULING_OPTIONS = "DM_INVALID_RULING_OPTIONS";
    string private constant ERROR_DEPOSIT_FAILED = "DM_DEPOSIT_FAILED";
    string private constant ERROR_BAD_MAX_DRAFT_BATCH_SIZE = "DM_BAD_MAX_DRAFT_BATCH_SIZE";

    // Rounds-related error messages
    string private constant ERROR_ROUND_IS_FINAL = "DM_ROUND_IS_FINAL";
    string private constant ERROR_ROUND_DOES_NOT_EXIST = "DM_ROUND_DOES_NOT_EXIST";
    string private constant ERROR_INVALID_ADJUDICATION_STATE = "DM_INVALID_ADJUDICATION_STATE";
    string private constant ERROR_ROUND_ALREADY_DRAFTED = "DM_ROUND_ALREADY_DRAFTED";
    string private constant ERROR_DRAFT_TERM_NOT_REACHED = "DM_DRAFT_TERM_NOT_REACHED";
    string private constant ERROR_ROUND_NOT_APPEALED = "DM_ROUND_NOT_APPEALED";
    string private constant ERROR_INVALID_APPEAL_RULING = "DM_INVALID_APPEAL_RULING";

    // Settlements-related error messages
    string private constant ERROR_PREV_ROUND_NOT_SETTLED = "DM_PREVIOUS_ROUND_NOT_SETTLED";
    string private constant ERROR_ROUND_ALREADY_SETTLED = "DM_ROUND_ALREADY_SETTLED";
    string private constant ERROR_ROUND_NOT_SETTLED = "DM_ROUND_PENALTIES_NOT_SETTLED";
    string private constant ERROR_JUROR_ALREADY_REWARDED = "DM_JUROR_ALREADY_REWARDED";
    string private constant ERROR_WONT_REWARD_NON_VOTER_JUROR = "DM_WONT_REWARD_NON_VOTER_JUROR";
    string private constant ERROR_WONT_REWARD_INCOHERENT_JUROR = "DM_WONT_REWARD_INCOHERENT_JUROR";
    string private constant ERROR_ROUND_APPEAL_ALREADY_SETTLED = "DM_APPEAL_ALREADY_SETTLED";

    // Minimum possible rulings for a dispute
    uint8 internal constant MIN_RULING_OPTIONS = 2;

    // Precision factor used to improve rounding when computing weights for the final round
    uint256 internal constant FINAL_ROUND_WEIGHT_PRECISION = 1000;

    // Mask used to decode vote IDs
    uint256 internal constant VOTE_ID_MASK = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    struct Dispute {
        IArbitrable subject;           // Arbitrable associated to a dispute
        uint64 createTermId;           // Term ID when the dispute was created
        uint8 possibleRulings;         // Number of possible rulings jurors can vote for each dispute
        uint8 finalRuling;             // Winning ruling of a dispute
        DisputeState state;            // State of a dispute: pre-draft, adjudicating, or ruled
        AdjudicationRound[] rounds;    // List of rounds for each dispute
    }

    struct AdjudicationRound {
        uint64 draftTermId;            // Term from which the jurors of a round can be drafted
        uint64 jurorsNumber;           // Number of jurors drafted for a round
        bool settledPenalties;         // Whether or not penalties have been settled for a round
        uint256 jurorFees;             // Total amount of fees to be distributed between the winning jurors of a round
        address[] jurors;              // List of jurors drafted for a round
        mapping (address => JurorState) jurorsStates; // List of states for each drafted juror indexed by address
        uint64 delayedTerms;           // Number of terms a round was delayed based on its requested draft term id
        uint64 selectedJurors;         // Number of jurors selected for a round, to allow drafts to be batched
        uint64 coherentJurors;         // Number of drafted jurors that voted in favor of the dispute final ruling
        uint64 settledJurors;          // Number of jurors whose rewards were already settled
        uint256 collectedTokens;       // Total amount of tokens collected from losing jurors
        Appeal appeal;                 // Appeal-related information of a round
    }

    struct JurorState {
        uint64 weight;                 // Weight computed for a juror on a round
        bool rewarded;                 // Whether or not a drafted juror was rewarded
    }

    struct Appeal {
        address maker;                 // Address of the appealer
        uint8 appealedRuling;          // Ruling appealing in favor of
        address taker;                 // Address of the one confirming an appeal
        uint8 opposedRuling;           // Ruling opposed to an appeal
        bool settled;                  // Whether or not an appeal has been settled
    }

    struct DraftParams {
        uint256 disputeId;            // Identification number of the dispute to be drafted
        uint256 roundId;              // Identification number of the round to be drafted
        uint64 termId;                // Identification number of the current term of the Court
        bytes32 draftTermRandomness;  // Randomness of the term in which the dispute was requested to be drafted
        DraftConfig config;           // Draft config of the Court at the draft term
    }

    struct NextRoundDetails {
        uint64 startTerm;              // Term ID from which the next round will start
        uint64 jurorsNumber;           // Jurors number for the next round
        DisputeState newDisputeState;  // New state for the dispute associated to the given round after the appeal
        ERC20 feeToken;                // ERC20 token used for the next round fees
        uint256 totalFees;             // Total amount of fees to be distributed between the winning jurors of the next round
        uint256 jurorFees;             // Total amount of fees for a regular round at the given term
        uint256 appealDeposit;         // Amount to be deposit of fees for a regular round at the given term
        uint256 confirmAppealDeposit;  // Total amount of fees for a regular round at the given term
    }

    // Max jurors to be drafted in each batch. To prevent running out of gas. We allow to change it because max gas per tx can vary
    // As a reference, drafting 100 jurors from a small tree of 4 would cost ~2.4M. Drafting 500, ~7.75M.
    uint64 public maxJurorsPerDraftBatch;

    // List of all the disputes created in the Court
    Dispute[] internal disputes;

    event DisputeStateChanged(uint256 indexed disputeId, DisputeState indexed state);
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, bytes evidence);
    event EvidencePeriodClosed(uint256 indexed disputeId, uint64 indexed termId);
    event NewDispute(uint256 indexed disputeId, IArbitrable indexed subject, uint64 indexed draftTermId, uint64 jurorsNumber, bytes metadata);
    event JurorDrafted(uint256 indexed disputeId, uint256 indexed roundId, address indexed juror);
    event RulingAppealed(uint256 indexed disputeId, uint256 indexed roundId, uint8 ruling);
    event RulingAppealConfirmed(uint256 indexed disputeId, uint256 indexed roundId, uint64 indexed draftTermId, uint256 jurorsNumber);
    event RulingComputed(uint256 indexed disputeId, uint8 indexed ruling);
    event PenaltiesSettled(uint256 indexed disputeId, uint256 indexed roundId, uint256 collectedTokens);
    event RewardSettled(uint256 indexed disputeId, uint256 indexed roundId, address juror, uint256 tokens, uint256 fees);
    event AppealDepositSettled(uint256 indexed disputeId, uint256 indexed roundId);
    event MaxJurorsPerDraftBatchChanged(uint64 previousMaxJurorsPerDraftBatch, uint64 currentMaxJurorsPerDraftBatch);

    /**
    * @dev Ensure the msg.sender is the CR Voting module
    */
    modifier onlyVoting() {
        ICRVoting voting = _voting();
        require(msg.sender == address(voting), ERROR_SENDER_NOT_VOTING);
        _;
    }

    /**
    * @dev Ensure a dispute exists
    * @param _disputeId Identification number of the dispute to be ensured
    */
    modifier disputeExists(uint256 _disputeId) {
        _checkDisputeExists(_disputeId);
        _;
    }

    /**
    * @dev Ensure a dispute round exists
    * @param _disputeId Identification number of the dispute to be ensured
    * @param _roundId Identification number of the dispute round to be ensured
    */
    modifier roundExists(uint256 _disputeId, uint256 _roundId) {
        _checkRoundExists(_disputeId, _roundId);
        _;
    }

    /**
    * @dev Constructor function
    * @param _controller Address of the controller
    * @param _maxJurorsPerDraftBatch Max number of jurors to be drafted per batch
    * @param _skippedDisputes Number of disputes to be skipped
    */
    constructor(Controller _controller, uint64 _maxJurorsPerDraftBatch, uint256 _skippedDisputes) ControlledRecoverable(_controller) public {
        // No need to explicitly call `Controlled` constructor since `ControlledRecoverable` is already doing it
        _setMaxJurorsPerDraftBatch(_maxJurorsPerDraftBatch);
        _skipDisputes(_skippedDisputes);
    }

    /**
    * @notice Create a dispute over `_subject` with `_possibleRulings` possible rulings
    * @param _subject Arbitrable instance creating the dispute
    * @param _possibleRulings Number of possible rulings allowed for the drafted jurors to vote on the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identification number
    */
    function createDispute(IArbitrable _subject, uint8 _possibleRulings, bytes calldata _metadata) external onlyController returns (uint256) {
        uint64 termId = _ensureCurrentTerm();
        Config memory config = _getConfigAt(termId);
        require(_possibleRulings >= MIN_RULING_OPTIONS && _possibleRulings <= config.disputes.maxRulingOptions, ERROR_INVALID_RULING_OPTIONS);

        // Create the dispute
        uint256 disputeId = disputes.length++;
        Dispute storage dispute = disputes[disputeId];
        dispute.subject = _subject;
        dispute.possibleRulings = _possibleRulings;
        dispute.createTermId = termId;

        uint64 jurorsNumber = config.disputes.firstRoundJurorsNumber;
        uint64 draftTermId = termId.add(config.disputes.evidenceTerms);
        emit NewDispute(disputeId, _subject, draftTermId, jurorsNumber, _metadata);

        // Create first adjudication round of the dispute
        (ERC20 feeToken, uint256 jurorFees, uint256 totalFees) = _getRegularRoundFees(config.fees, jurorsNumber);
        _createRound(disputeId, DisputeState.PreDraft, draftTermId, jurorsNumber, jurorFees);

        // Pay round fees and return dispute id
        _depositAmount(address(_subject), feeToken, totalFees);
        return disputeId;
    }

    /**
    * @notice Submit evidence for a dispute #`_disputeId`
    * @param _subject Arbitrable instance submitting the dispute
    * @param _disputeId Identification number of the dispute receiving new evidence
    * @param _submitter Address of the account submitting the evidence
    * @param _evidence Data submitted for the evidence of the dispute
    */
    function submitEvidence(IArbitrable _subject, uint256 _disputeId, address _submitter, bytes calldata _evidence)
        external onlyController disputeExists(_disputeId)
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.subject == _subject, ERROR_SUBJECT_NOT_DISPUTE_SUBJECT);
        emit EvidenceSubmitted(_disputeId, _submitter, _evidence);
    }

    /**
    * @notice Close the evidence period of dispute #`_disputeId`
    * @param _subject IArbitrable instance requesting to close the evidence submission period
    * @param _disputeId Identification number of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(IArbitrable _subject, uint256 _disputeId)
        external onlyController roundExists(_disputeId, 0)
    {
        Dispute storage dispute = disputes[_disputeId];
        AdjudicationRound storage round = dispute.rounds[0];
        require(dispute.subject == _subject, ERROR_SUBJECT_NOT_DISPUTE_SUBJECT);

        // Check current term is within the evidence submission period
        uint64 termId = _ensureCurrentTerm();
        uint64 newDraftTermId = termId.add(1);
        require(newDraftTermId < round.draftTermId, ERROR_EVIDENCE_PERIOD_IS_CLOSED);

        // Update the draft term of the first round to the next term
        round.draftTermId = newDraftTermId;
        emit EvidencePeriodClosed(_disputeId, termId);
    }

    /**
    * @notice Draft jurors for the next round of dispute #`_disputeId`
    * @param _disputeId Identification number of the dispute to be drafted
    */
    function draft(uint256 _disputeId) external disputeExists(_disputeId) {
        // Drafts can only be computed when the Court is up-to-date. Note that forcing a term transition won't work since the term randomness
        // is always based on the next term which means it won't be available anyway.
        IClock clock = _clock();
        uint64 requiredTransitions = _clock().getNeededTermTransitions();
        require(uint256(requiredTransitions) == 0, ERROR_TERM_OUTDATED);
        uint64 currentTermId = _getLastEnsuredTermId();

        // Ensure dispute has not been drafted yet
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.state == DisputeState.PreDraft, ERROR_ROUND_ALREADY_DRAFTED);

        // Ensure draft term randomness can be computed for the current block number
        uint256 roundId = dispute.rounds.length - 1;
        AdjudicationRound storage round = dispute.rounds[roundId];
        uint64 draftTermId = round.draftTermId;
        require(draftTermId <= currentTermId, ERROR_DRAFT_TERM_NOT_REACHED);
        bytes32 draftTermRandomness = clock.ensureCurrentTermRandomness();

        // Draft jurors for the given dispute and reimburse fees
        DraftConfig memory config = _getDraftConfig(draftTermId);
        bool draftEnded = _draft(round, _buildDraftParams(_disputeId, roundId, currentTermId, draftTermRandomness, config));

        // If the drafting is over, update its state
        if (draftEnded) {
            // No need for SafeMath: we ensured `currentTermId` is greater than or equal to `draftTermId` above
            round.delayedTerms = currentTermId - draftTermId;
            dispute.state = DisputeState.Adjudicating;
            emit DisputeStateChanged(_disputeId, DisputeState.Adjudicating);
        }
    }

    /**
    * @notice Appeal round #`_roundId` of dispute #`_disputeId` in favor of ruling `_ruling`
    * @param _disputeId Identification number of the dispute being appealed
    * @param _roundId Identification number of the dispute round being appealed
    * @param _ruling Ruling appealing a dispute round in favor of
    */
    function createAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external roundExists(_disputeId, _roundId) {
        // Ensure current term and check that the given round can be appealed.
        // Note that if there was a final appeal the adjudication state will be 'Ended'.
        Dispute storage dispute = disputes[_disputeId];
        Config memory config = _getDisputeConfig(dispute);
        _ensureAdjudicationState(dispute, _roundId, AdjudicationState.Appealing, config.disputes);

        // Ensure that the ruling being appealed in favor of is valid and different from the current winning ruling
        ICRVoting voting = _voting();
        uint256 voteId = _getVoteId(_disputeId, _roundId);
        uint8 roundWinningRuling = voting.getWinningOutcome(voteId);
        require(roundWinningRuling != _ruling && voting.isValidOutcome(voteId, _ruling), ERROR_INVALID_APPEAL_RULING);

        // Update round appeal state
        AdjudicationRound storage round = dispute.rounds[_roundId];
        Appeal storage appeal = round.appeal;
        appeal.maker = msg.sender;
        appeal.appealedRuling = _ruling;
        emit RulingAppealed(_disputeId, _roundId, _ruling);

        // Pay appeal deposit
        NextRoundDetails memory nextRound = _getNextRoundDetails(round, _roundId, config);
        _depositAmount(msg.sender, nextRound.feeToken, nextRound.appealDeposit);
    }

    /**
    * @notice Confirm appeal for round #`_roundId` of dispute #`_disputeId` in favor of ruling `_ruling`
    * @param _disputeId Identification number of the dispute confirming an appeal of
    * @param _roundId Identification number of the dispute round confirming an appeal of
    * @param _ruling Ruling being confirmed against a dispute round appeal
    */
    function confirmAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external roundExists(_disputeId, _roundId) {
        // Ensure current term and check that the given round is appealed and can be confirmed.
        // Note that if there was a final appeal the adjudication state will be 'Ended'.
        Dispute storage dispute = disputes[_disputeId];
        Config memory config = _getDisputeConfig(dispute);
        _ensureAdjudicationState(dispute, _roundId, AdjudicationState.ConfirmingAppeal, config.disputes);

        // Ensure that the ruling being confirmed in favor of is valid and different from the appealed ruling
        AdjudicationRound storage round = dispute.rounds[_roundId];
        Appeal storage appeal = round.appeal;
        uint256 voteId = _getVoteId(_disputeId, _roundId);
        require(appeal.appealedRuling != _ruling && _voting().isValidOutcome(voteId, _ruling), ERROR_INVALID_APPEAL_RULING);

        // Create a new adjudication round for the dispute
        NextRoundDetails memory nextRound = _getNextRoundDetails(round, _roundId, config);
        DisputeState newDisputeState = nextRound.newDisputeState;
        uint256 newRoundId = _createRound(_disputeId, newDisputeState, nextRound.startTerm, nextRound.jurorsNumber, nextRound.jurorFees);

        // Update previous round appeal state
        appeal.taker = msg.sender;
        appeal.opposedRuling = _ruling;
        emit RulingAppealConfirmed(_disputeId, newRoundId, nextRound.startTerm, nextRound.jurorsNumber);

        // Pay appeal confirm deposit
        _depositAmount(msg.sender, nextRound.feeToken, nextRound.confirmAppealDeposit);
    }

    /**
    * @notice Compute the final ruling for dispute #`_disputeId`
    * @param _disputeId Identification number of the dispute to compute its final ruling
    * @return subject Arbitrable instance associated to the dispute
    * @return finalRuling Final ruling decided for the given dispute
    */
    function computeRuling(uint256 _disputeId) external disputeExists(_disputeId) returns (IArbitrable subject, uint8 finalRuling) {
        Dispute storage dispute = disputes[_disputeId];
        subject = dispute.subject;

        Config memory config = _getDisputeConfig(dispute);
        finalRuling = _ensureFinalRuling(dispute, _disputeId, config);

        if (dispute.state != DisputeState.Ruled) {
            dispute.state = DisputeState.Ruled;
            emit RulingComputed(_disputeId, finalRuling);
        }
    }

    /**
    * @notice Settle penalties for round #`_roundId` of dispute #`_disputeId`
    * @dev In case of a regular round, all the drafted jurors that didn't vote in favor of the final ruling of the given dispute will be slashed.
    *      In case of a final round, jurors are slashed when voting, thus it is considered these rounds settled at once. Rewards have to be
    *      manually claimed through `settleReward` which will return pre-slashed tokens for the winning jurors of a final round as well.
    * @param _disputeId Identification number of the dispute to settle penalties for
    * @param _roundId Identification number of the dispute round to settle penalties for
    * @param _jurorsToSettle Maximum number of jurors to be slashed in this call. It can be set to zero to slash all the losing jurors of the
    *        given round. This argument is only used when settling regular rounds.
    */
    function settlePenalties(uint256 _disputeId, uint256 _roundId, uint256 _jurorsToSettle) external roundExists(_disputeId, _roundId) {
        // Enforce that rounds are settled in order to avoid one round without incentive to settle. Even if there is a settle fee
        // it may not be big enough and all jurors in the round could be slashed.
        Dispute storage dispute = disputes[_disputeId];
        require(_roundId == 0 || dispute.rounds[_roundId - 1].settledPenalties, ERROR_PREV_ROUND_NOT_SETTLED);

        // Ensure given round has not been fully settled yet
        AdjudicationRound storage round = dispute.rounds[_roundId];
        require(!round.settledPenalties, ERROR_ROUND_ALREADY_SETTLED);

        // Ensure the final ruling of the given dispute is already computed
        Config memory config = _getDisputeConfig(dispute);
        uint8 finalRuling = _ensureFinalRuling(dispute, _disputeId, config);

        // Set the number of jurors that voted in favor of the final ruling if we haven't started settling yet
        uint256 voteId = _getVoteId(_disputeId, _roundId);
        if (round.settledJurors == 0) {
            // Note that we are safe to cast the tally of a ruling to uint64 since the highest value a ruling can have is equal to the jurors
            // number for regular rounds or to the total active balance of the registry for final rounds, and both are ensured to fit in uint64.
            ICRVoting voting = _voting();
            round.coherentJurors = uint64(voting.getOutcomeTally(voteId, finalRuling));
        }

        ITreasury treasury = _treasury();
        ERC20 feeToken = config.fees.token;
        if (_isRegularRound(_roundId, config)) {
            // For regular appeal rounds we compute the amount of locked tokens that needs to get burned in batches.
            // The callers of this function will get rewarded in this case.
            uint256 jurorsSettled = _settleRegularRoundPenalties(round, voteId, finalRuling, config.disputes.penaltyPct, _jurorsToSettle, config.jurors.minActiveBalance);
            treasury.assign(feeToken, msg.sender, config.fees.settleFee.mul(jurorsSettled));
        } else {
            // For the final appeal round, there is no need to settle in batches since, to guarantee scalability,
            // all the tokens are collected from jurors when they vote, and those jurors who
            // voted in favor of the winning ruling can claim their collected tokens back along with their reward.
            // Note that the caller of this function is not being reimbursed.
            round.settledPenalties = true;
        }

        if (round.settledPenalties) {
            uint256 collectedTokens = round.collectedTokens;
            emit PenaltiesSettled(_disputeId, _roundId, collectedTokens);
            _burnCollectedTokensIfNecessary(dispute, round, _roundId, treasury, feeToken, collectedTokens);
        }
    }

    /**
    * @notice Claim reward for round #`_roundId` of dispute #`_disputeId` for juror `_juror`
    * @dev For regular rounds, it will only reward winning jurors
    * @param _disputeId Identification number of the dispute to settle rewards for
    * @param _roundId Identification number of the dispute round to settle rewards for
    * @param _juror Address of the juror to settle their rewards
    */
    function settleReward(uint256 _disputeId, uint256 _roundId, address _juror) external roundExists(_disputeId, _roundId) {
        // Ensure dispute round penalties are settled first
        Dispute storage dispute = disputes[_disputeId];
        AdjudicationRound storage round = dispute.rounds[_roundId];
        require(round.settledPenalties, ERROR_ROUND_NOT_SETTLED);

        // Ensure given juror was not rewarded yet and was drafted for the given round
        JurorState storage jurorState = round.jurorsStates[_juror];
        require(!jurorState.rewarded, ERROR_JUROR_ALREADY_REWARDED);
        require(uint256(jurorState.weight) > 0, ERROR_WONT_REWARD_NON_VOTER_JUROR);
        jurorState.rewarded = true;

        // Check if the given juror has voted in favor of the final ruling of the dispute in this round
        ICRVoting voting = _voting();
        uint256 voteId = _getVoteId(_disputeId, _roundId);
        require(voting.hasVotedInFavorOf(voteId, dispute.finalRuling, _juror), ERROR_WONT_REWARD_INCOHERENT_JUROR);

        uint256 collectedTokens = round.collectedTokens;
        IJurorsRegistry jurorsRegistry = _jurorsRegistry();

        // Distribute the collected tokens of the jurors that were slashed weighted by the winning jurors. Note that we are penalizing jurors
        // that refused intentionally their vote for the final round.
        uint256 rewardTokens;
        if (collectedTokens > 0) {
            // Note that the number of coherent jurors has to be greater than zero since we already ensured the juror has voted in favor of the
            // final ruling, therefore there will be at least one coherent juror and divisions below are safe.
            rewardTokens = _getRoundWeightedAmount(round, jurorState, collectedTokens);
            jurorsRegistry.assignTokens(_juror, rewardTokens);
        }

        // Reward the winning juror with fees
        Config memory config = _getDisputeConfig(dispute);
        // Note that the number of coherent jurors has to be greater than zero since we already ensured the juror has voted in favor of the
        // final ruling, therefore there will be at least one coherent juror and divisions below are safe.
        uint256 rewardFees = _getRoundWeightedAmount(round, jurorState, round.jurorFees);
        _treasury().assign(config.fees.token, _juror, rewardFees);

        // Set the lock for final round
        if (!_isRegularRound(_roundId, config)) {
            // Round end term ID (as it's final there's no draft delay nor appeal) plus the lock period
            DisputesConfig memory disputesConfig = config.disputes;
            jurorsRegistry.lockWithdrawals(
                _juror,
                round.draftTermId + disputesConfig.commitTerms + disputesConfig.revealTerms + disputesConfig.finalRoundLockTerms
            );
        }

        emit RewardSettled(_disputeId, _roundId, _juror, rewardTokens, rewardFees);
    }

    /**
    * @notice Settle appeal deposits for round #`_roundId` of dispute #`_disputeId`
    * @param _disputeId Identification number of the dispute to settle appeal deposits for
    * @param _roundId Identification number of the dispute round to settle appeal deposits for
    */
    function settleAppealDeposit(uint256 _disputeId, uint256 _roundId) external roundExists(_disputeId, _roundId) {
        // Ensure dispute round penalties are settled first
        Dispute storage dispute = disputes[_disputeId];
        AdjudicationRound storage round = dispute.rounds[_roundId];
        require(round.settledPenalties, ERROR_ROUND_NOT_SETTLED);

        // Ensure given round was appealed and has not been settled yet
        Appeal storage appeal = round.appeal;
        require(_existsAppeal(appeal), ERROR_ROUND_NOT_APPEALED);
        require(!appeal.settled, ERROR_ROUND_APPEAL_ALREADY_SETTLED);
        appeal.settled = true;
        emit AppealDepositSettled(_disputeId, _roundId);

        // Load next round details
        Config memory config = _getDisputeConfig(dispute);
        NextRoundDetails memory nextRound = _getNextRoundDetails(round, _roundId, config);
        ERC20 feeToken = nextRound.feeToken;
        uint256 totalFees = nextRound.totalFees;
        uint256 appealDeposit = nextRound.appealDeposit;
        uint256 confirmAppealDeposit = nextRound.confirmAppealDeposit;

        // If the appeal wasn't confirmed, return the entire deposit to appeal maker
        ITreasury treasury = _treasury();
        if (!_isAppealConfirmed(appeal)) {
            treasury.assign(feeToken, appeal.maker, appealDeposit);
            return;
        }

        // If the appeal was confirmed and there is a winner, we transfer the total deposit to that party. Otherwise, if the final ruling wasn't
        // selected by any of the appealing parties or no juror voted in the in favor of the possible outcomes, we split it between both parties.
        // Note that we are safe to access the dispute final ruling, since we already ensured that round penalties were settled.
        uint8 finalRuling = dispute.finalRuling;
        uint256 totalDeposit = appealDeposit.add(confirmAppealDeposit);
        if (appeal.appealedRuling == finalRuling) {
            treasury.assign(feeToken, appeal.maker, totalDeposit.sub(totalFees));
        } else if (appeal.opposedRuling == finalRuling) {
            treasury.assign(feeToken, appeal.taker, totalDeposit.sub(totalFees));
        } else {
            uint256 feesRefund = totalFees / 2;
            treasury.assign(feeToken, appeal.maker, appealDeposit.sub(feesRefund));
            treasury.assign(feeToken, appeal.taker, confirmAppealDeposit.sub(feesRefund));
        }
    }

    /**
    * @notice Ensure votes can be committed for vote #`_voteId`, revert otherwise
    * @dev This function will ensure the current term of the Court and revert in case votes cannot still be committed
    * @param _voteId ID of the vote instance to request the weight of a voter for
    */
    function ensureCanCommit(uint256 _voteId) external {
        (Dispute storage dispute, uint256 roundId) = _decodeVoteId(_voteId);
        Config memory config = _getDisputeConfig(dispute);

        // Ensure current term and check that votes can still be committed for the given round
        _ensureAdjudicationState(dispute, roundId, AdjudicationState.Committing, config.disputes);
    }

    /**
    * @notice Ensure `voter` can commit votes for vote #`_voteId`, revert otherwise
    * @dev This function will ensure the current term of the Court and revert in case the given voter is not allowed to commit votes
    * @param _voteId ID of the vote instance to request the weight of a voter for
    * @param _voter Address of the voter querying the weight of
    */
    function ensureCanCommit(uint256 _voteId, address _voter) external onlyVoting {
        (Dispute storage dispute, uint256 roundId) = _decodeVoteId(_voteId);
        Config memory config = _getDisputeConfig(dispute);

        // Ensure current term and check that votes can still be committed for the given round
        _ensureAdjudicationState(dispute, roundId, AdjudicationState.Committing, config.disputes);
        uint64 weight = _computeJurorWeight(dispute, roundId, _voter, config);
        require(weight > 0, ERROR_VOTER_WEIGHT_ZERO);
    }

    /**
    * @notice Ensure `voter` can reveal votes for vote #`_voteId`, revert otherwise
    * @dev This function will ensure the current term of the Court and revert in case votes cannot still be revealed
    * @param _voteId ID of the vote instance to request the weight of a voter for
    * @param _voter Address of the voter querying the weight of
    * @return Weight of the requested juror for the requested dispute's round
    */
    function ensureCanReveal(uint256 _voteId, address _voter) external returns (uint64) {
        (Dispute storage dispute, uint256 roundId) = _decodeVoteId(_voteId);
        Config memory config = _getDisputeConfig(dispute);

        // Ensure current term and check that votes can still be revealed for the given round
        _ensureAdjudicationState(dispute, roundId, AdjudicationState.Revealing, config.disputes);
        AdjudicationRound storage round = dispute.rounds[roundId];
        return _getJurorWeight(round, _voter);
    }

    /**
    * @notice Sets the global configuration for the max number of jurors to be drafted per batch to `_maxJurorsPerDraftBatch`
    * @param _maxJurorsPerDraftBatch Max number of jurors to be drafted per batch
    */
    function setMaxJurorsPerDraftBatch(uint64 _maxJurorsPerDraftBatch) external onlyConfigGovernor {
        _setMaxJurorsPerDraftBatch(_maxJurorsPerDraftBatch);
    }

    /**
    * @dev Tell the amount of token fees required to create a dispute
    * @return feeToken ERC20 token used for the fees
    * @return totalFees Total amount of fees for a regular round at the given term
    */
    function getDisputeFees() external view returns (ERC20 feeToken, uint256 totalFees) {
        uint64 currentTermId = _getCurrentTermId();
        Config memory config = _getConfigAt(currentTermId);
        (feeToken,, totalFees) = _getRegularRoundFees(config.fees, config.disputes.firstRoundJurorsNumber);
    }

    /**
    * @dev Tell information of a certain dispute
    * @param _disputeId Identification number of the dispute being queried
    * @return subject Arbitrable subject being disputed
    * @return possibleRulings Number of possible rulings allowed for the drafted jurors to vote on the dispute
    * @return state Current state of the dispute being queried: pre-draft, adjudicating, or ruled
    * @return finalRuling The winning ruling in case the dispute is finished
    * @return lastRoundId Identification number of the last round created for the dispute
    * @return createTermId Identification number of the term when the dispute was created
    */
    function getDispute(uint256 _disputeId) external view disputeExists(_disputeId)
        returns (IArbitrable subject, uint8 possibleRulings, DisputeState state, uint8 finalRuling, uint256 lastRoundId, uint64 createTermId)
    {
        Dispute storage dispute = disputes[_disputeId];

        subject = dispute.subject;
        possibleRulings = dispute.possibleRulings;
        state = dispute.state;
        finalRuling = dispute.finalRuling;
        createTermId = dispute.createTermId;
        // If a dispute exists, it has at least one round
        lastRoundId = dispute.rounds.length - 1;
    }

    /**
    * @dev Tell information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @return draftTerm Term from which the requested round can be drafted
    * @return delayedTerms Number of terms the given round was delayed based on its requested draft term id
    * @return jurorsNumber Number of jurors requested for the round
    * @return selectedJurors Number of jurors already selected for the requested round
    * @return settledPenalties Whether or not penalties have been settled for the requested round
    * @return collectedTokens Amount of juror tokens that were collected from slashed jurors for the requested round
    * @return coherentJurors Number of jurors that voted in favor of the final ruling in the requested round
    * @return state Adjudication state of the requested round
    */
    function getRound(uint256 _disputeId, uint256 _roundId) external view roundExists(_disputeId, _roundId)
        returns (
            uint64 draftTerm,
            uint64 delayedTerms,
            uint64 jurorsNumber,
            uint64 selectedJurors,
            uint256 jurorFees,
            bool settledPenalties,
            uint256 collectedTokens,
            uint64 coherentJurors,
            AdjudicationState state
        )
    {
        Dispute storage dispute = disputes[_disputeId];
        state = _adjudicationStateAt(dispute, _roundId, _getCurrentTermId(), _getDisputeConfig(dispute).disputes);

        AdjudicationRound storage round = dispute.rounds[_roundId];
        draftTerm = round.draftTermId;
        delayedTerms = round.delayedTerms;
        jurorsNumber = round.jurorsNumber;
        selectedJurors = round.selectedJurors;
        jurorFees = round.jurorFees;
        settledPenalties = round.settledPenalties;
        coherentJurors = round.coherentJurors;
        collectedTokens = round.collectedTokens;
    }

    /**
    * @dev Tell appeal-related information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @return maker Address of the account appealing the given round
    * @return appealedRuling Ruling confirmed by the appealer of the given round
    * @return taker Address of the account confirming the appeal of the given round
    * @return opposedRuling Ruling confirmed by the appeal taker of the given round
    */
    function getAppeal(uint256 _disputeId, uint256 _roundId) external view roundExists(_disputeId, _roundId)
        returns (address maker, uint64 appealedRuling, address taker, uint64 opposedRuling)
    {
        Appeal storage appeal = disputes[_disputeId].rounds[_roundId].appeal;

        maker = appeal.maker;
        appealedRuling = appeal.appealedRuling;
        taker = appeal.taker;
        opposedRuling = appeal.opposedRuling;
    }

    /**
    * @dev Tell information related to the next round due to an appeal of a certain round given.
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round requesting the appeal details of
    * @return nextRoundStartTerm Term ID from which the next round will start
    * @return nextRoundJurorsNumber Jurors number for the next round
    * @return newDisputeState New state for the dispute associated to the given round after the appeal
    * @return feeToken ERC20 token used for the next round fees
    * @return jurorFees Total amount of fees to be distributed between the winning jurors of the next round
    * @return totalFees Total amount of fees for a regular round at the given term
    * @return appealDeposit Amount to be deposit of fees for a regular round at the given term
    * @return confirmAppealDeposit Total amount of fees for a regular round at the given term
    */
    function getNextRoundDetails(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 nextRoundStartTerm,
            uint64 nextRoundJurorsNumber,
            DisputeState newDisputeState,
            ERC20 feeToken,
            uint256 totalFees,
            uint256 jurorFees,
            uint256 appealDeposit,
            uint256 confirmAppealDeposit
        )
    {
        _checkRoundExists(_disputeId, _roundId);

        Dispute storage dispute = disputes[_disputeId];
        Config memory config = _getDisputeConfig(dispute);
        require(_isRegularRound(_roundId, config), ERROR_ROUND_IS_FINAL);

        AdjudicationRound storage round = dispute.rounds[_roundId];
        NextRoundDetails memory nextRound = _getNextRoundDetails(round, _roundId, config);
        return (
            nextRound.startTerm,
            nextRound.jurorsNumber,
            nextRound.newDisputeState,
            nextRound.feeToken,
            nextRound.totalFees,
            nextRound.jurorFees,
            nextRound.appealDeposit,
            nextRound.confirmAppealDeposit
        );
    }

    /**
    * @dev Tell juror-related information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @param _juror Address of the juror being queried
    * @return weight Juror weight drafted for the requested round
    * @return rewarded Whether or not the given juror was rewarded based on the requested round
    */
    function getJuror(uint256 _disputeId, uint256 _roundId, address _juror) external view roundExists(_disputeId, _roundId)
        returns (uint64 weight, bool rewarded)
    {
        Dispute storage dispute = disputes[_disputeId];
        AdjudicationRound storage round = dispute.rounds[_roundId];
        Config memory config = _getDisputeConfig(dispute);

        if (_isRegularRound(_roundId, config)) {
            weight = _getJurorWeight(round, _juror);
        } else {
            IJurorsRegistry jurorsRegistry = _jurorsRegistry();
            uint256 activeBalance = jurorsRegistry.activeBalanceOfAt(_juror, round.draftTermId);
            weight = _getMinActiveBalanceMultiple(activeBalance, config.jurors.minActiveBalance);
        }

        rewarded = round.jurorsStates[_juror].rewarded;
    }

    /**
    * @dev Internal function to create a new round for a given dispute
    * @param _disputeId Identification number of the dispute to create a new round for
    * @param _disputeState New state for the dispute to be changed
    * @param _draftTermId Term ID when the jurors for the new round will be drafted
    * @param _jurorsNumber Number of jurors to be drafted for the new round
    * @param _jurorFees Total amount of fees to be shared between the winning jurors of the new round
    * @return Identification number of the new dispute round
    */
    function _createRound(uint256 _disputeId, DisputeState _disputeState, uint64 _draftTermId, uint64 _jurorsNumber, uint256 _jurorFees) internal
        returns (uint256)
    {
        // Update dispute state
        Dispute storage dispute = disputes[_disputeId];
        dispute.state = _disputeState;

        // Create new requested round
        uint256 roundId = dispute.rounds.length++;
        AdjudicationRound storage round = dispute.rounds[roundId];
        round.draftTermId = _draftTermId;
        round.jurorsNumber = _jurorsNumber;
        round.jurorFees = _jurorFees;

        // Create new vote for the new round
        ICRVoting voting = _voting();
        uint256 voteId = _getVoteId(_disputeId, roundId);
        voting.create(voteId, dispute.possibleRulings);
        return roundId;
    }

    /**
    * @dev Internal function to ensure the adjudication state of a certain dispute round. This function will make sure the court term is updated.
    *      This function assumes the given round exists.
    * @param _dispute Dispute to be checked
    * @param _roundId Identification number of the dispute round to be checked
    * @param _state Expected adjudication state for the given dispute round
    * @param _config Config at the draft term ID of the given dispute
    */
    function _ensureAdjudicationState(Dispute storage _dispute, uint256 _roundId, AdjudicationState _state, DisputesConfig memory _config)
        internal
    {
        uint64 termId = _ensureCurrentTerm();
        AdjudicationState roundState = _adjudicationStateAt(_dispute, _roundId, termId, _config);
        require(roundState == _state, ERROR_INVALID_ADJUDICATION_STATE);
    }

    /**
    * @dev Internal function to ensure the final ruling of a dispute. It will compute it only if missing.
    * @param _dispute Dispute to ensure its final ruling
    * @param _disputeId Identification number of the dispute to ensure its final ruling
    * @param _config Config at the draft term ID of the given dispute
    * @return Number of the final ruling ensured for the given dispute
    */
    function _ensureFinalRuling(Dispute storage _dispute, uint256 _disputeId, Config memory _config) internal returns (uint8) {
        // Check if there was a final ruling already cached
        if (uint256(_dispute.finalRuling) > 0) {
            return _dispute.finalRuling;
        }

        // Ensure current term and check that the last adjudication round has ended.
        // Note that there will always be at least one round.
        uint256 lastRoundId = _dispute.rounds.length - 1;
        _ensureAdjudicationState(_dispute, lastRoundId, AdjudicationState.Ended, _config.disputes);

        // If the last adjudication round was appealed but no-one confirmed it, the final ruling is the outcome the
        // appealer vouched for. Otherwise, fetch the winning outcome from the voting app of the last round.
        AdjudicationRound storage lastRound = _dispute.rounds[lastRoundId];
        Appeal storage lastAppeal = lastRound.appeal;
        bool isRoundAppealedAndNotConfirmed = _existsAppeal(lastAppeal) && !_isAppealConfirmed(lastAppeal);
        uint8 finalRuling = isRoundAppealedAndNotConfirmed
            ? lastAppeal.appealedRuling
            : _voting().getWinningOutcome(_getVoteId(_disputeId, lastRoundId));

        // Store the winning ruling as the final decision for the given dispute
        _dispute.finalRuling = finalRuling;
        return finalRuling;
    }

    /**
    * @dev Internal function to slash all the jurors drafted for a round that didn't vote in favor of the final ruling of a dispute. Note that
    *      the slashing can be batched handling the maximum number of jurors to be slashed on each call.
    * @param _round Round to slash the non-winning jurors of
    * @param _voteId Identification number of the voting associated to the given round
    * @param _finalRuling Winning ruling of the dispute corresponding to the given round
    * @param _penaltyPct Per ten thousand of the minimum active balance of a juror to be slashed
    * @param _jurorsToSettle Maximum number of jurors to be slashed in this call. It can be set to zero to slash all the losing jurors of the round.
    * @param _minActiveBalance Minimum amount of juror tokens that can be activated
    * @return Number of jurors slashed for the given round
    */
    function _settleRegularRoundPenalties(
        AdjudicationRound storage _round,
        uint256 _voteId,
        uint8 _finalRuling,
        uint16 _penaltyPct,
        uint256 _jurorsToSettle,
        uint256 _minActiveBalance
    )
        internal
        returns (uint256)
    {
        uint64 termId = _ensureCurrentTerm();
        // The batch starts where the previous one ended, stored in _round.settledJurors
        uint256 roundSettledJurors = _round.settledJurors;
        // Compute the amount of jurors that are going to be settled in this batch, which is returned by the function for fees calculation
        // Initially we try to reach the end of the jurors array
        uint256 batchSettledJurors = _round.jurors.length.sub(roundSettledJurors);

        // If the requested amount of jurors is not zero and it is lower that the remaining number of jurors to be settled for the given round,
        // we cap the number of jurors that are going to be settled in this batch to the requested amount. If not, we know we have reached the
        // last batch and we are safe to mark round penalties as settled.
        if (_jurorsToSettle > 0 && batchSettledJurors > _jurorsToSettle) {
            batchSettledJurors = _jurorsToSettle;
        } else {
            _round.settledPenalties = true;
        }

        // Update the number of round settled jurors.
        _round.settledJurors = uint64(roundSettledJurors.add(batchSettledJurors));

        // Prepare the list of jurors and penalties to either be slashed or returned based on their votes for the given round
        IJurorsRegistry jurorsRegistry = _jurorsRegistry();
        address[] memory jurors = new address[](batchSettledJurors);
        uint256[] memory penalties = new uint256[](batchSettledJurors);
        for (uint256 i = 0; i < batchSettledJurors; i++) {
            address juror = _round.jurors[roundSettledJurors + i];
            jurors[i] = juror;
            penalties[i] = _minActiveBalance.pct(_penaltyPct).mul(_round.jurorsStates[juror].weight);
        }

        // Check which of the jurors voted in favor of the final ruling of the dispute in this round. Ask the registry to slash or unlocked the
        // locked active tokens of each juror depending on their vote, and finally store the total amount of slashed tokens.
        bool[] memory jurorsInFavor = _voting().getVotersInFavorOf(_voteId, _finalRuling, jurors);
        _round.collectedTokens = _round.collectedTokens.add(jurorsRegistry.slashOrUnlock(termId, jurors, penalties, jurorsInFavor));
        return batchSettledJurors;
    }

    /**
    * @dev Internal function to compute the juror weight for a dispute's round
    * @param _dispute Dispute to calculate the juror's weight of
    * @param _roundId ID of the dispute's round to calculate the juror's weight of
    * @param _juror Address of the juror to calculate the weight of
    * @param _config Config at the draft term ID of the given dispute
    * @return Computed weight of the requested juror for the final round of the given dispute
    */
    function _computeJurorWeight(Dispute storage _dispute, uint256 _roundId, address _juror, Config memory _config) internal returns (uint64) {
        AdjudicationRound storage round = _dispute.rounds[_roundId];

        return _isRegularRound(_roundId, _config)
            ? _getJurorWeight(round, _juror)
            : _computeJurorWeightForFinalRound(_config, round, _juror);
    }

    /**
    * @dev Internal function to compute the juror weight for the final round. Note that for a final round the weight of
    *      each juror is equal to the number of times the min active balance the juror has. This function will try to
    *      collect said amount from the active balance of a juror, acting as a lock to allow them to vote.
    * @param _config Court config to calculate the juror's weight
    * @param _round Dispute round to calculate the juror's weight for
    * @param _juror Address of the juror to calculate the weight of
    * @return Weight of the requested juror for the final round of the given dispute
    */
    function _computeJurorWeightForFinalRound(Config memory _config, AdjudicationRound storage _round, address _juror) internal
        returns (uint64)
    {
        // Fetch active balance and multiples of the min active balance from the registry
        IJurorsRegistry jurorsRegistry = _jurorsRegistry();
        uint256 activeBalance = jurorsRegistry.activeBalanceOfAt(_juror, _round.draftTermId);
        uint64 weight = _getMinActiveBalanceMultiple(activeBalance, _config.jurors.minActiveBalance);

        // If the juror weight for the last round is zero, return zero
        if (weight == 0) {
            return uint64(0);
        }

        // To guarantee scalability of the final round, since all jurors may vote, we try to collect the amount of
        // active tokens that needs to be locked for each juror when they try to commit their vote.
        uint256 weightedPenalty = activeBalance.pct(_config.disputes.penaltyPct);

        // If it was not possible to collect the amount to be locked, return 0 to prevent juror from voting
        if (!jurorsRegistry.collectTokens(_juror, weightedPenalty, _getLastEnsuredTermId())) {
            return uint64(0);
        }

        // If it was possible to collect the amount of active tokens to be locked, update the final round state
        _round.jurorsStates[_juror].weight = weight;
        _round.collectedTokens = _round.collectedTokens.add(weightedPenalty);

        return weight;
    }

    /**
    * @dev Sets the global configuration for the max number of jurors to be drafted per batch
    * @param _maxJurorsPerDraftBatch Max number of jurors to be drafted per batch
    */
    function _setMaxJurorsPerDraftBatch(uint64 _maxJurorsPerDraftBatch) internal {
        require(_maxJurorsPerDraftBatch > 0, ERROR_BAD_MAX_DRAFT_BATCH_SIZE);
        emit MaxJurorsPerDraftBatchChanged(maxJurorsPerDraftBatch, _maxJurorsPerDraftBatch);
        maxJurorsPerDraftBatch = _maxJurorsPerDraftBatch;
    }

    /**
    * @dev Internal function to execute a deposit of tokens from an account to the Court treasury contract
    * @param _from Address transferring the amount of tokens
    * @param _token ERC20 token to execute a transfer from
    * @param _amount Amount of tokens to be transferred from the address transferring the funds to the Court treasury
    */
    function _depositAmount(address _from, ERC20 _token, uint256 _amount) internal {
        if (_amount > 0) {
            ITreasury treasury = _treasury();
            require(_token.safeTransferFrom(_from, address(treasury), _amount), ERROR_DEPOSIT_FAILED);
        }
    }

    /**
    * @dev Internal function to get the stored juror weight for a round. Note that the weight of a juror is:
    *      - For a regular round: the number of times a juror was picked for the round round.
    *      - For a final round: the relative active stake of a juror's state over the total active tokens, only set after the juror has voted.
    * @param _round Dispute round to calculate the juror's weight of
    * @param _juror Address of the juror to calculate the weight of
    * @return Weight of the requested juror for the given round
    */
    function _getJurorWeight(AdjudicationRound storage _round, address _juror) internal view returns (uint64) {
        return _round.jurorsStates[_juror].weight;
    }

    /**
    * @dev Internal function to tell information related to the next round due to an appeal of a certain round given. This function assumes
    *      given round can be appealed and that the given round ID corresponds to the given round pointer.
    * @param _round Round requesting the appeal details of
    * @param _roundId Identification number of the round requesting the appeal details of
    * @param _config Config at the draft term of the given dispute
    * @return Next round details
    */
    function _getNextRoundDetails(AdjudicationRound storage _round, uint256 _roundId, Config memory _config) internal view
        returns (NextRoundDetails memory)
    {
        NextRoundDetails memory nextRound;
        DisputesConfig memory disputesConfig = _config.disputes;

        // Next round start term is current round end term
        uint64 delayedDraftTerm = _round.draftTermId.add(_round.delayedTerms);
        uint64 currentRoundAppealStartTerm = delayedDraftTerm.add(disputesConfig.commitTerms).add(disputesConfig.revealTerms);
        nextRound.startTerm = currentRoundAppealStartTerm.add(disputesConfig.appealTerms).add(disputesConfig.appealConfirmTerms);

        // Compute next round settings depending on if it will be the final round or not
        if (_roundId >= disputesConfig.maxRegularAppealRounds.sub(1)) {
            // If the next round is the final round, no draft is needed.
            nextRound.newDisputeState = DisputeState.Adjudicating;
            // The number of jurors will be the number of times the minimum stake is held in the registry,
            // multiplied by a precision factor to help with division rounding.
            // Total active balance is guaranteed to never be greater than `2^64 * minActiveBalance / FINAL_ROUND_WEIGHT_PRECISION`.
            // Thus, the jurors number for a final round will always fit in uint64.
            IJurorsRegistry jurorsRegistry = _jurorsRegistry();
            uint256 totalActiveBalance = jurorsRegistry.totalActiveBalanceAt(nextRound.startTerm);
            uint64 jurorsNumber = _getMinActiveBalanceMultiple(totalActiveBalance, _config.jurors.minActiveBalance);
            nextRound.jurorsNumber = jurorsNumber;
            // Calculate fees for the final round using the appeal start term of the current round
            (nextRound.feeToken, nextRound.jurorFees, nextRound.totalFees) = _getFinalRoundFees(_config.fees, jurorsNumber);
        } else {
            // For a new regular rounds we need to draft jurors
            nextRound.newDisputeState = DisputeState.PreDraft;
            // The number of jurors will be the number of jurors of the current round multiplied by an appeal factor
            nextRound.jurorsNumber = _getNextRegularRoundJurorsNumber(_round, disputesConfig);
            // Calculate fees for the next regular round using the appeal start term of the current round
            (nextRound.feeToken, nextRound.jurorFees, nextRound.totalFees) = _getRegularRoundFees(_config.fees, nextRound.jurorsNumber);
        }

        // Calculate appeal collateral
        nextRound.appealDeposit = nextRound.totalFees.pct256(disputesConfig.appealCollateralFactor);
        nextRound.confirmAppealDeposit = nextRound.totalFees.pct256(disputesConfig.appealConfirmCollateralFactor);
        return nextRound;
    }

    /**
    * @dev Internal function to calculate the jurors number for the next regular round of a given round. This function assumes Court term is
    *      up-to-date, that the next round of the one given is regular, and the given config corresponds to the draft term of the given round.
    * @param _round Round querying the jurors number of its next round
    * @param _config Disputes config at the draft term of the first round of the dispute
    * @return Jurors number for the next regular round of the given round
    */
    function _getNextRegularRoundJurorsNumber(AdjudicationRound storage _round, DisputesConfig memory _config) internal view returns (uint64) {
        // Jurors number are increased by a step factor on each appeal
        uint64 jurorsNumber = _round.jurorsNumber.mul(_config.appealStepFactor);
        // Make sure it's odd to enforce avoiding a tie. Note that it can happen if any of the jurors don't vote anyway.
        if (uint256(jurorsNumber) % 2 == 0) {
            jurorsNumber++;
        }
        return jurorsNumber;
    }

    /**
    * @dev Internal function to tell adjudication state of a round at a certain term. This function assumes the given round exists.
    * @param _dispute Dispute querying the adjudication round of
    * @param _roundId Identification number of the dispute round querying the adjudication round of
    * @param _termId Identification number of the term to be used for the different round phases durations
    * @param _config Disputes config at the draft term ID of the given dispute
    * @return Adjudication state of the requested dispute round for the given term
    */
    function _adjudicationStateAt(Dispute storage _dispute, uint256 _roundId, uint64 _termId, DisputesConfig memory _config) internal view
        returns (AdjudicationState)
    {
        AdjudicationRound storage round = _dispute.rounds[_roundId];

        // If the dispute is ruled or the given round is not the last one, we consider it ended
        uint256 numberOfRounds = _dispute.rounds.length;
        if (_dispute.state == DisputeState.Ruled || _roundId < numberOfRounds.sub(1)) {
            return AdjudicationState.Ended;
        }

        // If given term is before the actual term when the last round was finally drafted, then the last round adjudication state is invalid
        uint64 draftFinishedTermId = round.draftTermId.add(round.delayedTerms);
        if (_dispute.state == DisputeState.PreDraft || _termId < draftFinishedTermId) {
            return AdjudicationState.Invalid;
        }

        // If given term is before the reveal start term of the last round, then jurors are still allowed to commit votes for the last round
        uint64 revealStartTerm = draftFinishedTermId.add(_config.commitTerms);
        if (_termId < revealStartTerm) {
            return AdjudicationState.Committing;
        }

        // If given term is before the appeal start term of the last round, then jurors are still allowed to reveal votes for the last round
        uint64 appealStartTerm = revealStartTerm.add(_config.revealTerms);
        if (_termId < appealStartTerm) {
            return AdjudicationState.Revealing;
        }

        // If the max number of appeals has been reached, then the last round is the final round and can be considered ended
        bool maxAppealReached = numberOfRounds > _config.maxRegularAppealRounds;
        if (maxAppealReached) {
            return AdjudicationState.Ended;
        }

        // If the last round was not appealed yet, check if the confirmation period has started or not
        bool isLastRoundAppealed = _existsAppeal(round.appeal);
        uint64 appealConfirmationStartTerm = appealStartTerm.add(_config.appealTerms);
        if (!isLastRoundAppealed) {
            // If given term is before the appeal confirmation start term, then the last round can still be appealed. Otherwise, it is ended.
            if (_termId < appealConfirmationStartTerm) {
                return AdjudicationState.Appealing;
            } else {
                return AdjudicationState.Ended;
            }
        }

        // If the last round was appealed and the given term is before the appeal confirmation end term, then the last round appeal can still be
        // confirmed. Note that if the round being checked was already appealed and confirmed, it won't be the last round, thus it will be caught
        // above by the first check and considered 'Ended'.
        uint64 appealConfirmationEndTerm = appealConfirmationStartTerm.add(_config.appealConfirmTerms);
        if (_termId < appealConfirmationEndTerm) {
            return AdjudicationState.ConfirmingAppeal;
        }

        // If non of the above conditions have been met, the last round is considered ended
        return AdjudicationState.Ended;
    }

    /**
    * @dev Internal function to get the Court config used for a dispute
    * @param _dispute Dispute querying the Court config of
    * @return Court config used for the given dispute
    */
    function _getDisputeConfig(Dispute storage _dispute) internal view returns (Config memory) {
        // Note that it is safe to access a Court config directly for a past term
        return _getConfigAt(_dispute.createTermId);
    }

    /**
    * @dev Internal function to check if a certain appeal exists
    * @param _appeal Appeal to be checked
    * @return True if the given appeal has a maker address associated to it, false otherwise
    */
    function _existsAppeal(Appeal storage _appeal) internal view returns (bool) {
        return _appeal.maker != address(0);
    }

    /**
    * @dev Internal function to check if a certain appeal has been confirmed
    * @param _appeal Appeal to be checked
    * @return True if the given appeal was confirmed, false otherwise
    */
    function _isAppealConfirmed(Appeal storage _appeal) internal view returns (bool) {
        return _appeal.taker != address(0);
    }

    /**
    * @dev Internal function to check if a certain dispute exists, it reverts if it doesn't
    * @param _disputeId Identification number of the dispute to be checked
    */
    function _checkDisputeExists(uint256 _disputeId) internal view {
        require(_disputeId < disputes.length, ERROR_DISPUTE_DOES_NOT_EXIST);
    }

    /**
    * @dev Internal function to check if a certain dispute round exists, it reverts if it doesn't
    * @param _disputeId Identification number of the dispute to be checked
    * @param _roundId Identification number of the dispute round to be checked
    */
    function _checkRoundExists(uint256 _disputeId, uint256 _roundId) internal view {
        _checkDisputeExists(_disputeId);
        require(_roundId < disputes[_disputeId].rounds.length, ERROR_ROUND_DOES_NOT_EXIST);
    }

    /**
    * @dev Internal function to get the dispute round of a certain vote identification number
    * @param _voteId Identification number of the vote querying the dispute round of
    * @return dispute Dispute for the given vote
    * @return roundId Identification number of the dispute round for the given vote
    */
    function _decodeVoteId(uint256 _voteId) internal view returns (Dispute storage dispute, uint256 roundId) {
        uint256 disputeId = _voteId >> 128;
        roundId = _voteId & VOTE_ID_MASK;
        _checkRoundExists(disputeId, roundId);
        dispute = disputes[disputeId];
    }

    /**
    * @dev Internal function to get the identification number of the vote of a certain dispute round
    * @param _disputeId Identification number of the dispute querying the vote ID of
    * @param _roundId Identification number of the dispute round querying the vote ID of
    * @return Identification number of the vote of the requested dispute round
    */
    function _getVoteId(uint256 _disputeId, uint256 _roundId) internal pure returns (uint256) {
        return (_disputeId << 128) + _roundId;
    }

    /**
    * @dev Assumes round.coherentJurors is greater than zero
    * @param _round Round which the weighted amount is computed for
    * @param _jurorState Juror with state which the weighted amount is computed for
    * @param _amount Amount to be weighted
    * @return Weighted amount for a juror in a round in relation to total amount of coherent jurors
    */
    function _getRoundWeightedAmount(
        AdjudicationRound storage _round,
        JurorState storage _jurorState,
        uint256 _amount
    )
        internal
        view
        returns (uint256)
    {
        return _amount.mul(_jurorState.weight) / _round.coherentJurors;
    }

    /**
    * @dev Internal function to get fees information for regular rounds for a certain term. This function assumes Court term is up-to-date.
    * @param _config Court config to use in order to get fees
    * @param _jurorsNumber Number of jurors participating in the round being queried
    * @return feeToken ERC20 token used for the fees
    * @return jurorFees Total amount of fees to be distributed between the winning jurors of a round
    * @return totalFees Total amount of fees for a regular round at the given term
    */
    function _getRegularRoundFees(FeesConfig memory _config, uint64 _jurorsNumber) internal pure
        returns (ERC20 feeToken, uint256 jurorFees, uint256 totalFees)
    {
        feeToken = _config.token;
        // For regular rounds the fees for each juror is constant and given by the config of the round
        jurorFees = uint256(_jurorsNumber).mul(_config.jurorFee);
        // The total fees for regular rounds also considers the number of drafts and settles
        uint256 draftAndSettleFees = (_config.draftFee.add(_config.settleFee)).mul(uint256(_jurorsNumber));
        totalFees = jurorFees.add(draftAndSettleFees);
    }

    /**
    * @dev Internal function to get fees information for final rounds for a certain term. This function assumes Court term is up-to-date.
    * @param _config Court config to use in order to get fees
    * @param _jurorsNumber Number of jurors participating in the round being queried
    * @return feeToken ERC20 token used for the fees
    * @return jurorFees Total amount of fees corresponding to the jurors at the given term
    * @return totalFees Total amount of fees for a final round at the given term
    */
    function _getFinalRoundFees(FeesConfig memory _config, uint64 _jurorsNumber) internal pure
        returns (ERC20 feeToken, uint256 jurorFees, uint256 totalFees)
    {
        feeToken = _config.token;
        // For final rounds, the jurors number is computed as the number of times the registry's minimum active balance is held in the registry
        // itself, multiplied by a precision factor. To avoid requesting a huge amount of fees, a final round discount is applied for each juror.
        jurorFees = (uint256(_jurorsNumber).mul(_config.jurorFee) / FINAL_ROUND_WEIGHT_PRECISION).pct(_config.finalRoundReduction);
        // There is no draft and no extra settle fees considered for final rounds
        totalFees = jurorFees;
    }

    /**
    * @dev Internal function to tell whether a round is regular or final. This function assumes the given round exists.
    * @param _roundId Identification number of the round to be checked
    * @param _config Court config to use in order to check if the given round is regular or final
    * @return True if the given round is regular, false in case its a final round
    */
    function _isRegularRound(uint256 _roundId, Config memory _config) internal pure returns (bool) {
        return _roundId < _config.disputes.maxRegularAppealRounds;
    }

    /**
    * @dev Calculate the number of times that an amount contains the min active balance (multiplied by precision).
    *      Used to get the juror weight for the final round. Note that for the final round the weight of
    *      each juror is equal to the number of times the min active balance the juror has, multiplied by a precision
    *      factor to deal with division rounding.
    * @param _activeBalance Juror's or total active balance
    * @param _minActiveBalance Minimum amount of juror tokens that can be activated
    * @return Number of times that the active balance contains the min active balance (multiplied by precision)
    */
    function _getMinActiveBalanceMultiple(uint256 _activeBalance, uint256 _minActiveBalance) internal pure returns (uint64) {
        // Note that jurors may not reach the minimum active balance since some might have been slashed. If that occurs,
        // these jurors cannot vote in the final round.
        if (_activeBalance < _minActiveBalance) {
            return 0;
        }

        // Otherwise, return the times the active balance of the juror fits in the min active balance, multiplying
        // it by a round factor to ensure a better precision rounding.
        return (FINAL_ROUND_WEIGHT_PRECISION.mul(_activeBalance) / _minActiveBalance).toUint64();
    }

    /**
    * @dev Private function to build params to call for a draft. It assumes the given data is correct.
    * @param _disputeId Identification number of the dispute to be drafted
    * @param _roundId Identification number of the round to be drafted
    * @param _termId Identification number of the current term of the Court
    * @param _draftTermRandomness Randomness of the term in which the dispute was requested to be drafted
    * @param _config Draft config of the Court at the draft term
    * @return Draft params object
    */
    function _buildDraftParams(uint256 _disputeId, uint256 _roundId, uint64 _termId, bytes32 _draftTermRandomness, DraftConfig memory _config)
        private
        pure
        returns (DraftParams memory)
    {
        return DraftParams({
            disputeId: _disputeId,
            roundId: _roundId,
            termId: _termId,
            draftTermRandomness: _draftTermRandomness,
            config: _config
        });
    }

    /**
    * @dev Private function to draft jurors for a given dispute and round. It assumes the given data is correct.
    * @param _round Round of the dispute to be drafted
    * @param _draftParams Draft params to be used for the draft
    * @return True if all the requested jurors for the given round were drafted, false otherwise
    */
    function _draft(AdjudicationRound storage _round, DraftParams memory _draftParams) private returns (bool) {
        uint64 jurorsNumber = _round.jurorsNumber;
        uint64 selectedJurors = _round.selectedJurors;
        uint64 maxJurorsPerBatch = maxJurorsPerDraftBatch;
        uint64 jurorsToBeDrafted = jurorsNumber.sub(selectedJurors);
        // Draft the min number of jurors between the one requested by the sender and the one requested by the sender
        uint64 requestedJurors = jurorsToBeDrafted < maxJurorsPerBatch ? jurorsToBeDrafted : maxJurorsPerBatch;

        // Pack draft params
        uint256[7] memory params = [
            uint256(_draftParams.draftTermRandomness),
            _draftParams.disputeId,
            uint256(_draftParams.termId),
            uint256(selectedJurors),
            uint256(requestedJurors),
            uint256(jurorsNumber),
            uint256(_draftParams.config.penaltyPct)
        ];

        // Draft jurors for the requested round
        IJurorsRegistry jurorsRegistry = _jurorsRegistry();
        (address[] memory jurors, uint256 draftedJurors) = jurorsRegistry.draft(params);

        // Update round with drafted jurors information
        uint64 newSelectedJurors = selectedJurors.add(uint64(draftedJurors));
        _round.selectedJurors = newSelectedJurors;
        _updateRoundDraftedJurors(_draftParams.disputeId, _draftParams.roundId, _round, jurors, draftedJurors);
        bool draftEnded = newSelectedJurors == jurorsNumber;

        // Transfer fees corresponding to the actual number of drafted jurors
        uint256 draftFees = _draftParams.config.draftFee.mul(draftedJurors);
        _treasury().assign(_draftParams.config.feeToken, msg.sender, draftFees);
        return draftEnded;
    }

    /**
    * @dev Private function to update the drafted jurors' weight for the given round
    * @param _disputeId Identification number of the dispute being drafted
    * @param _roundId Identification number of the round being drafted
    * @param _round Adjudication round that was drafted
    * @param _jurors List of jurors addresses that were drafted for the given round
    * @param _draftedJurors Number of jurors that were drafted for the given round. Note that this number may not necessarily be equal to the
    *        given list of jurors since the draft could potentially return less jurors than the requested amount.
    */
    function _updateRoundDraftedJurors(
        uint256 _disputeId,
        uint256 _roundId,
        AdjudicationRound storage _round,
        address[] memory _jurors,
        uint256 _draftedJurors
    )
        private
    {
        for (uint256 i = 0; i < _draftedJurors; i++) {
            address juror = _jurors[i];
            JurorState storage jurorState = _round.jurorsStates[juror];

            // If the juror was already registered in the list, then don't add it twice
            if (uint256(jurorState.weight) == 0) {
                _round.jurors.push(juror);
            }

            jurorState.weight = jurorState.weight.add(1);
            emit JurorDrafted(_disputeId, _roundId, juror);
        }
    }

    /**
    * @dev Private function to burn the collected for a certain round in case there were no coherent jurors
    * @param _dispute Dispute to settle penalties for
    * @param _round Dispute round to settle penalties for
    * @param _roundId Identification number of the dispute round to settle penalties for
    * @param _courtTreasury Treasury module to refund the corresponding juror fees
    * @param _feeToken ERC20 token to be used for the fees corresponding to the draft term of the given dispute round
    * @param _collectedTokens Amount of tokens collected during the given dispute round
    */
    function _burnCollectedTokensIfNecessary(
        Dispute storage _dispute,
        AdjudicationRound storage _round,
        uint256 _roundId,
        ITreasury _courtTreasury,
        ERC20 _feeToken,
        uint256 _collectedTokens
    )
        private
    {
        // If there was at least one juror voting in favor of the winning ruling, return
        if (_round.coherentJurors > 0) {
            return;
        }

        // Burn all the collected tokens of the jurors to be slashed. Note that this will happen only when there were no jurors voting
        // in favor of the final winning outcome. Otherwise, these will be re-distributed between the winning jurors in `settleReward`
        // instead of being burned.
        if (_collectedTokens > 0) {
            IJurorsRegistry jurorsRegistry = _jurorsRegistry();
            jurorsRegistry.burnTokens(_collectedTokens);
        }

        // Reimburse juror fees to the Arbtirable subject for round 0 or to the previous appeal parties for other rounds.
        // Note that if the given round is not the first round, we can ensure there was an appeal in the previous round.
        if (_roundId == 0) {
            _courtTreasury.assign(_feeToken, address(_dispute.subject), _round.jurorFees);
        } else {
            uint256 refundFees = _round.jurorFees / 2;
            Appeal storage triggeringAppeal = _dispute.rounds[_roundId - 1].appeal;
            _courtTreasury.assign(_feeToken, triggeringAppeal.maker, refundFees);
            _courtTreasury.assign(_feeToken, triggeringAppeal.taker, refundFees);
        }
    }

    /**
    * @dev Private function only used in the constructor to skip a given number of disputes
    * @param _skippedDisputes Number of disputes to be skipped
    */
    function _skipDisputes(uint256 _skippedDisputes) private {
        assert(disputes.length == 0);
        disputes.length = _skippedDisputes;
    }
}