/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.5.17;


// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
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

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath64.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
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

/*
 * SPDX-License-Identifier:    MIT
 */
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _who) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/SafeERC20.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
library SafeERC20 {
    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the provided token and expects it to be already
    *      verified as a contract.
    */
    function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            _token.transfer.selector,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the provided token and expects it to be already
    *      verified as a contract.
    */
    function safeTransferFrom(IERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
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
    *      Note that this makes an external call to the provided token and expects it to be already
    *      verified as a contract.
    */
    function safeApprove(IERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
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

library PctHelpers {
    using SafeMath for uint256;

    uint256 internal constant PCT_BASE = 10000; // ‱ (1 / 10,000)

    function isValid(uint16 _pct) internal pure returns (bool) {
        return _pct <= PCT_BASE;
    }

    function pct(uint256 self, uint16 _pct) internal pure returns (uint256) {
        return self.mul(uint256(_pct)) / PCT_BASE;
    }

    function pct256(uint256 self, uint256 _pct) internal pure returns (uint256) {
        return self.mul(_pct) / PCT_BASE;
    }

    function pctIncrease(uint256 self, uint16 _pct) internal pure returns (uint256) {
        // No need for SafeMath: for addition note that `PCT_BASE` is lower than (2^256 - 2^16)
        return self.mul(PCT_BASE + uint256(_pct)) / PCT_BASE;
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/Uint256Helpers.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
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

/*
 * SPDX-License-Identifier:    MIT
 */
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
    * @param _disputeId Id of the dispute in the Court
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
    * @return subject Subject associated to the dispute
    * @return ruling Ruling number computed for the given dispute
    */
    function rule(uint256 _disputeId) external returns (address subject, uint256 ruling);

    /**
    * @dev Tell the dispute fees information to create a dispute
    * @return recipient Address where the corresponding dispute fees must be transferred to
    * @return feeToken ERC20 token used for the fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getDisputeFees() external view returns (address recipient, IERC20 feeToken, uint256 feeAmount);

    /**
    * @dev Tell the payments recipient address
    * @return Address of the payments recipient module
    */
    function getPaymentsRecipient() external view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */
/**
* @dev The Arbitrable instances actually don't require to follow any specific interface.
*      Note that this is actually optional, although it does allow the Court to at least have a way to identify a specific set of instances.
*/
contract IArbitrable {
    /**
    * @dev Emitted when an IArbitrable instance's dispute is ruled by an IArbitrator
    * @param arbitrator IArbitrator instance ruling the dispute
    * @param disputeId Identification number of the dispute being ruled by the arbitrator
    * @param ruling Ruling given by the arbitrator
    */
    event Ruled(IArbitrator indexed arbitrator, uint256 indexed disputeId, uint256 ruling);
}

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
    * @param _possibleRulings Number of possible rulings allowed for the drafted guardians to vote on the dispute
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
    * @dev Draft guardians for the next round of a dispute
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
    * @param _guardiansToSettle Maximum number of guardians to be slashed in this call
    */
    function settlePenalties(uint256 _disputeId, uint256 _roundId, uint256 _guardiansToSettle) external;

    /**
    * @dev Claim rewards for a round of a dispute for guardian
    * @dev For regular rounds, it will only reward winning guardians
    * @param _disputeId Identification number of the dispute to settle rewards for
    * @param _roundId Identification number of the dispute round to settle rewards for
    * @param _guardian Address of the guardian to settle their rewards
    */
    function settleReward(uint256 _disputeId, uint256 _roundId, address _guardian) external;

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
    function getDisputeFees() external view returns (IERC20 feeToken, uint256 feeAmount);

    /**
    * @dev Tell information of a certain dispute
    * @param _disputeId Identification number of the dispute being queried
    * @return subject Arbitrable subject being disputed
    * @return possibleRulings Number of possible rulings allowed for the drafted guardians to vote on the dispute
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
    * @return guardiansNumber Number of guardians requested for the round
    * @return selectedGuardians Number of guardians already selected for the requested round
    * @return settledPenalties Whether or not penalties have been settled for the requested round
    * @return collectedTokens Amount of guardian tokens that were collected from slashed guardians for the requested round
    * @return coherentGuardians Number of guardians that voted in favor of the final ruling in the requested round
    * @return state Adjudication state of the requested round
    */
    function getRound(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 draftTerm,
            uint64 delayedTerms,
            uint64 guardiansNumber,
            uint64 selectedGuardians,
            uint256 guardianFees,
            bool settledPenalties,
            uint256 collectedTokens,
            uint64 coherentGuardians,
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
    * @return nextRoundGuardiansNumber Guardians number for the next round
    * @return newDisputeState New state for the dispute associated to the given round after the appeal
    * @return feeToken ERC20 token used for the next round fees
    * @return guardianFees Total amount of fees to be distributed between the winning guardians of the next round
    * @return totalFees Total amount of fees for a regular round at the given term
    * @return appealDeposit Amount to be deposit of fees for a regular round at the given term
    * @return confirmAppealDeposit Total amount of fees for a regular round at the given term
    */
    function getNextRoundDetails(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 nextRoundStartTerm,
            uint64 nextRoundGuardiansNumber,
            DisputeState newDisputeState,
            IERC20 feeToken,
            uint256 totalFees,
            uint256 guardianFees,
            uint256 appealDeposit,
            uint256 confirmAppealDeposit
        );

    /**
    * @dev Tell guardian-related information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @param _guardian Address of the guardian being queried
    * @return weight Guardian weight drafted for the requested round
    * @return rewarded Whether or not the given guardian was rewarded based on the requested round
    */
    function getGuardian(uint256 _disputeId, uint256 _roundId, address _guardian) external view returns (uint64 weight, bool rewarded);
}

/*
 * SPDX-License-Identifier:    MIT
 */
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
    * @return Weight of the requested guardian for the requested vote instance
    */
    function ensureCanReveal(uint256 _voteId, address _voter) external returns (uint64);
}

/*
 * SPDX-License-Identifier:    MIT
 */
interface ICRVoting {
    /**
    * @dev Create a new vote instance
    * @dev This function can only be called by the CRVoting owner
    * @param _voteId ID of the new vote instance to be created
    * @param _possibleOutcomes Number of possible outcomes for the new vote instance to be created
    */
    function createVote(uint256 _voteId, uint8 _possibleOutcomes) external;

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

/*
 * SPDX-License-Identifier:    MIT
 */
interface ITreasury {
    /**
    * @dev Assign a certain amount of tokens to an account
    * @param _token ERC20 token to be assigned
    * @param _to Address of the recipient that will be assigned the tokens to
    * @param _amount Amount of tokens to be assigned to the recipient
    */
    function assign(IERC20 _token, address _to, uint256 _amount) external;

    /**
    * @dev Withdraw a certain amount of tokens
    * @param _token ERC20 token to be withdrawn
    * @param _from Address withdrawing the tokens from
    * @param _to Address of the recipient that will receive the tokens
    * @param _amount Amount of tokens to be withdrawn from the sender
    */
    function withdraw(IERC20 _token, address _from, address _to, uint256 _amount) external;
}

/*
 * SPDX-License-Identifier:    MIT
 */
interface IGuardiansRegistry {

    /**
    * @dev Assign a requested amount of guardian tokens to a guardian
    * @param _guardian Guardian to add an amount of tokens to
    * @param _amount Amount of tokens to be added to the available balance of a guardian
    */
    function assignTokens(address _guardian, uint256 _amount) external;

    /**
    * @dev Burn a requested amount of guardian tokens
    * @param _amount Amount of tokens to be burned
    */
    function burnTokens(uint256 _amount) external;

    /**
    * @dev Draft a set of guardians based on given requirements for a term id
    * @param _params Array containing draft requirements:
    *        0. bytes32 Term randomness
    *        1. uint256 Dispute id
    *        2. uint64  Current term id
    *        3. uint256 Number of seats already filled
    *        4. uint256 Number of seats left to be filled
    *        5. uint64  Number of guardians required for the draft
    *        6. uint16  Permyriad of the minimum active balance to be locked for the draft
    *
    * @return guardians List of guardians selected for the draft
    * @return length Size of the list of the draft result
    */
    function draft(uint256[7] calldata _params) external returns (address[] memory guardians, uint256 length);

    /**
    * @dev Slash a set of guardians based on their votes compared to the winning ruling
    * @param _termId Current term id
    * @param _guardians List of guardian addresses to be slashed
    * @param _lockedAmounts List of amounts locked for each corresponding guardian that will be either slashed or returned
    * @param _rewardedGuardians List of booleans to tell whether a guardian's active balance has to be slashed or not
    * @return Total amount of slashed tokens
    */
    function slashOrUnlock(uint64 _termId, address[] calldata _guardians, uint256[] calldata _lockedAmounts, bool[] calldata _rewardedGuardians)
        external
        returns (uint256 collectedTokens);

    /**
    * @dev Try to collect a certain amount of tokens from a guardian for the next term
    * @param _guardian Guardian to collect the tokens from
    * @param _amount Amount of tokens to be collected from the given guardian and for the requested term id
    * @param _termId Current term id
    * @return True if the guardian has enough unlocked tokens to be collected for the requested term, false otherwise
    */
    function collectTokens(address _guardian, uint256 _amount, uint64 _termId) external returns (bool);

    /**
    * @dev Lock a guardian's withdrawals until a certain term ID
    * @param _guardian Address of the guardian to be locked
    * @param _termId Term ID until which the guardian's withdrawals will be locked
    */
    function lockWithdrawals(address _guardian, uint64 _termId) external;

    /**
    * @dev Tell the active balance of a guardian for a given term id
    * @param _guardian Address of the guardian querying the active balance of
    * @param _termId Term ID querying the active balance for
    * @return Amount of active tokens for guardian in the requested past term id
    */
    function activeBalanceOfAt(address _guardian, uint64 _termId) external view returns (uint256);

    /**
    * @dev Tell the total amount of active guardian tokens at the given term id
    * @param _termId Term ID querying the total active balance for
    * @return Total amount of active guardian tokens at the given term id
    */
    function totalActiveBalanceAt(uint64 _termId) external view returns (uint256);
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/IsContract.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
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

contract ModuleIds {
    // DisputeManager module ID - keccak256(abi.encodePacked("DISPUTE_MANAGER"))
    bytes32 internal constant MODULE_ID_DISPUTE_MANAGER = 0x14a6c70f0f6d449c014c7bbc9e68e31e79e8474fb03b7194df83109a2d888ae6;

    // GuardiansRegistry module ID - keccak256(abi.encodePacked("GUARDIANS_REGISTRY"))
    bytes32 internal constant MODULE_ID_GUARDIANS_REGISTRY = 0x8af7b7118de65da3b974a3fd4b0c702b66442f74b9dff6eaed1037254c0b79fe;

    // Voting module ID - keccak256(abi.encodePacked("VOTING"))
    bytes32 internal constant MODULE_ID_VOTING = 0x7cbb12e82a6d63ff16fe43977f43e3e2b247ecd4e62c0e340da8800a48c67346;

    // PaymentsBook module ID - keccak256(abi.encodePacked("PAYMENTS_BOOK"))
    bytes32 internal constant MODULE_ID_PAYMENTS_BOOK = 0xfa275b1417437a2a2ea8e91e9fe73c28eaf0a28532a250541da5ac0d1892b418;

    // Treasury module ID - keccak256(abi.encodePacked("TREASURY"))
    bytes32 internal constant MODULE_ID_TREASURY = 0x06aa03964db1f7257357ef09714a5f0ca3633723df419e97015e0c7a3e83edb7;
}

contract ACL {
    string private constant ERROR_BAD_FREEZE = "ACL_BAD_FREEZE";
    string private constant ERROR_ROLE_ALREADY_FROZEN = "ACL_ROLE_ALREADY_FROZEN";
    string private constant ERROR_INVALID_BULK_INPUT = "ACL_INVALID_BULK_INPUT";

    enum BulkOp { Grant, Revoke, Freeze }

    address internal constant FREEZE_FLAG = address(1);
    address internal constant ANY_ADDR = address(-1);

    // List of all roles assigned to different addresses
    mapping (bytes32 => mapping (address => bool)) public roles;

    event Granted(bytes32 indexed id, address indexed who);
    event Revoked(bytes32 indexed id, address indexed who);
    event Frozen(bytes32 indexed id);

    /**
    * @dev Tell whether an address has a role assigned
    * @param _who Address being queried
    * @param _id ID of the role being checked
    * @return True if the requested address has assigned the given role, false otherwise
    */
    function hasRole(address _who, bytes32 _id) public view returns (bool) {
        return roles[_id][_who] || roles[_id][ANY_ADDR];
    }

    /**
    * @dev Tell whether a role is frozen
    * @param _id ID of the role being checked
    * @return True if the given role is frozen, false otherwise
    */
    function isRoleFrozen(bytes32 _id) public view returns (bool) {
        return roles[_id][FREEZE_FLAG];
    }

    /**
    * @dev Internal function to grant a role to a given address
    * @param _id ID of the role to be granted
    * @param _who Address to grant the role to
    */
    function _grant(bytes32 _id, address _who) internal {
        require(!isRoleFrozen(_id), ERROR_ROLE_ALREADY_FROZEN);
        require(_who != FREEZE_FLAG, ERROR_BAD_FREEZE);

        if (!hasRole(_who, _id)) {
            roles[_id][_who] = true;
            emit Granted(_id, _who);
        }
    }

    /**
    * @dev Internal function to revoke a role from a given address
    * @param _id ID of the role to be revoked
    * @param _who Address to revoke the role from
    */
    function _revoke(bytes32 _id, address _who) internal {
        require(!isRoleFrozen(_id), ERROR_ROLE_ALREADY_FROZEN);

        if (hasRole(_who, _id)) {
            roles[_id][_who] = false;
            emit Revoked(_id, _who);
        }
    }

    /**
    * @dev Internal function to freeze a role
    * @param _id ID of the role to be frozen
    */
    function _freeze(bytes32 _id) internal {
        require(!isRoleFrozen(_id), ERROR_ROLE_ALREADY_FROZEN);
        roles[_id][FREEZE_FLAG] = true;
        emit Frozen(_id);
    }

    /**
    * @dev Internal function to enact a bulk list of ACL operations
    */
    function _bulk(BulkOp[] memory _op, bytes32[] memory _id, address[] memory _who) internal {
        require(_op.length == _id.length && _op.length == _who.length, ERROR_INVALID_BULK_INPUT);

        for (uint256 i = 0; i < _op.length; i++) {
            BulkOp op = _op[i];
            if (op == BulkOp.Grant) {
                _grant(_id[i], _who[i]);
            } else if (op == BulkOp.Revoke) {
                _revoke(_id[i], _who[i]);
            } else if (op == BulkOp.Freeze) {
                _freeze(_id[i]);
            }
        }
    }
}

interface IModulesLinker {
    /**
    * @notice Update the implementations of a list of modules
    * @param _ids List of IDs of the modules to be updated
    * @param _addresses List of module addresses to be updated
    */
    function linkModules(bytes32[] calldata _ids, address[] calldata _addresses) external;
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/TimeHelpers.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
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
    */
    function getTerm(uint64 _termId) external view returns (uint64 startTime, uint64 randomnessBN, bytes32 randomness);

    /**
    * @dev Tell the randomness of a term even if it wasn't computed yet
    * @param _termId Identification number of the term being queried
    * @return Randomness of the requested term
    */
    function getTermRandomness(uint64 _termId) external view returns (bytes32);
}

contract CourtClock is IClock, TimeHelpers {
    using SafeMath64 for uint64;

    string private constant ERROR_TERM_DOES_NOT_EXIST = "CLK_TERM_DOES_NOT_EXIST";
    string private constant ERROR_TERM_DURATION_TOO_LONG = "CLK_TERM_DURATION_TOO_LONG";
    string private constant ERROR_TERM_RANDOMNESS_NOT_YET = "CLK_TERM_RANDOMNESS_NOT_YET";
    string private constant ERROR_TERM_RANDOMNESS_UNAVAILABLE = "CLK_TERM_RANDOMNESS_UNAVAILABLE";
    string private constant ERROR_BAD_FIRST_TERM_START_TIME = "CLK_BAD_FIRST_TERM_START_TIME";
    string private constant ERROR_TOO_MANY_TRANSITIONS = "CLK_TOO_MANY_TRANSITIONS";
    string private constant ERROR_INVALID_TRANSITION_TERMS = "CLK_INVALID_TRANSITION_TERMS";
    string private constant ERROR_CANNOT_DELAY_STARTED_COURT = "CLK_CANNOT_DELAY_STARTED_PROT";
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
    *        1. _firstTermStartTime Timestamp in seconds when the court will open (to give time for guardian on-boarding)
    */
    constructor(uint64[2] memory _termParams) public {
        uint64 _termDuration = _termParams[0];
        uint64 _firstTermStartTime = _termParams[1];

        require(_termDuration < MAX_TERM_DURATION, ERROR_TERM_DURATION_TOO_LONG);
        require(_firstTermStartTime >= getTimestamp64() + _termDuration, ERROR_BAD_FIRST_TERM_START_TIME);
        require(_firstTermStartTime <= getTimestamp64() + MAX_FIRST_TERM_DELAY_PERIOD, ERROR_BAD_FIRST_TERM_START_TIME);

        termDuration = _termDuration;

        // No need for SafeMath: we already checked values above
        terms[0].startTime = _firstTermStartTime - _termDuration;
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
    */
    function getTerm(uint64 _termId) external view returns (uint64 startTime, uint64 randomnessBN, bytes32 randomness) {
        Term storage term = terms[_termId];
        return (term.startTime, term.randomnessBN, term.randomness);
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
            _onTermTransitioned(currentTermId);

            // Set the start time of the new term. Note that we are using a constant term duration value to guarantee
            // equally long terms, regardless of heartbeats.
            currentTerm.startTime = previousTerm.startTime.add(termDuration);

            // In order to draft a random number of guardians in a term, we use a randomness factor for each term based on a
            // block number that is set once the term has started. Note that this information could not be known beforehand.
            currentTerm.randomnessBN = blockNumber + 1;
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
    * @dev Internal function to compute the randomness that will be used to draft guardians for the given term. This
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
}

interface IConfig {

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *         1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *         2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return minActiveBalance Minimum amount of tokens guardians have to activate to participate in the Court
    */
    function getConfig(uint64 _termId) external view
        returns (
            IERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        );

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per guardian to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct);

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Term querying the min active balance config of
    * @return Minimum amount of tokens guardians have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256);
}

contract CourtConfigData {
    struct Config {
        FeesConfig fees;                        // Full fees-related config
        DisputesConfig disputes;                // Full disputes-related config
        uint256 minActiveBalance;               // Minimum amount of tokens guardians have to activate to participate in the Court
    }

    struct FeesConfig {
        IERC20 token;                           // ERC20 token to be used for the fees of the Court
        uint16 finalRoundReduction;             // Permyriad of fees reduction applied for final appeal round (‱ - 1/10,000)
        uint256 guardianFee;                    // Amount of tokens paid to draft a guardian to adjudicate a dispute
        uint256 draftFee;                       // Amount of tokens paid per round to cover the costs of drafting guardians
        uint256 settleFee;                      // Amount of tokens paid per round to cover the costs of slashing guardians
    }

    struct DisputesConfig {
        uint64 evidenceTerms;                   // Max submitting evidence period duration in terms
        uint64 commitTerms;                     // Committing period duration in terms
        uint64 revealTerms;                     // Revealing period duration in terms
        uint64 appealTerms;                     // Appealing period duration in terms
        uint64 appealConfirmTerms;              // Confirmation appeal period duration in terms
        uint16 penaltyPct;                      // Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
        uint64 firstRoundGuardiansNumber;       // Number of guardians drafted on first round
        uint64 appealStepFactor;                // Factor in which the guardians number is increased on each appeal
        uint64 finalRoundLockTerms;             // Period a coherent guardian in the final round will remain locked
        uint256 maxRegularAppealRounds;         // Before the final appeal
        uint256 appealCollateralFactor;         // Permyriad multiple of dispute fees required to appeal a preliminary ruling (‱ - 1/10,000)
        uint256 appealConfirmCollateralFactor;  // Permyriad multiple of dispute fees required to confirm appeal (‱ - 1/10,000)
    }

    struct DraftConfig {
        IERC20 feeToken;                         // ERC20 token to be used for the fees of the Court
        uint16 penaltyPct;                      // Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
        uint256 draftFee;                       // Amount of tokens paid per round to cover the costs of drafting guardians
    }
}

contract CourtConfig is IConfig, CourtConfigData {
    using SafeMath64 for uint64;
    using PctHelpers for uint256;

    string private constant ERROR_TOO_OLD_TERM = "CONF_TOO_OLD_TERM";
    string private constant ERROR_INVALID_PENALTY_PCT = "CONF_INVALID_PENALTY_PCT";
    string private constant ERROR_INVALID_FINAL_ROUND_REDUCTION_PCT = "CONF_INVALID_FINAL_ROUND_RED_PCT";
    string private constant ERROR_INVALID_MAX_APPEAL_ROUNDS = "CONF_INVALID_MAX_APPEAL_ROUNDS";
    string private constant ERROR_LARGE_ROUND_PHASE_DURATION = "CONF_LARGE_ROUND_PHASE_DURATION";
    string private constant ERROR_BAD_INITIAL_GUARDIANS_NUMBER = "CONF_BAD_INITIAL_GUARDIAN_NUMBER";
    string private constant ERROR_BAD_APPEAL_STEP_FACTOR = "CONF_BAD_APPEAL_STEP_FACTOR";
    string private constant ERROR_ZERO_COLLATERAL_FACTOR = "CONF_ZERO_COLLATERAL_FACTOR";
    string private constant ERROR_ZERO_MIN_ACTIVE_BALANCE = "CONF_ZERO_MIN_ACTIVE_BALANCE";

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

    event NewConfig(uint64 fromTermId, uint64 courtConfigId);

    /**
    * @dev Constructor function
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *        1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *        2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    constructor(
        IERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance
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
            _roundStateDurations,
            _pcts,
            _roundParams,
            _appealCollateralParams,
            _minActiveBalance
        );
    }

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *         1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *         2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return minActiveBalance Minimum amount of tokens guardians have to activate to participate in the Court
    */
    function getConfig(uint64 _termId) external view
        returns (
            IERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        );

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per guardian to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct);

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Term querying the min active balance config of
    * @return Minimum amount of tokens guardians have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256);

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
    *        0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *        1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *        2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    function _setConfig(
        uint64 _termId,
        uint64 _fromTermId,
        IERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance
    )
        internal
    {
        // If the current term is not zero, changes must be scheduled at least after the current period.
        // No need to ensure delays for on-going disputes since these already use their creation term for that.
        require(_termId == 0 || _fromTermId > _termId, ERROR_TOO_OLD_TERM);

        // Make sure appeal collateral factors are greater than zero
        require(_appealCollateralParams[0] > 0 && _appealCollateralParams[1] > 0, ERROR_ZERO_COLLATERAL_FACTOR);

        // Make sure the given penalty and final round reduction pcts are not greater than 100%
        require(PctHelpers.isValid(_pcts[0]), ERROR_INVALID_PENALTY_PCT);
        require(PctHelpers.isValid(_pcts[1]), ERROR_INVALID_FINAL_ROUND_REDUCTION_PCT);

        // Disputes must request at least one guardian to be drafted initially
        require(_roundParams[0] > 0, ERROR_BAD_INITIAL_GUARDIANS_NUMBER);

        // Prevent that further rounds have zero guardians
        require(_roundParams[1] > 0, ERROR_BAD_APPEAL_STEP_FACTOR);

        // Make sure the max number of appeals allowed does not reach the limit
        uint256 _maxRegularAppealRounds = _roundParams[2];
        bool isMaxAppealRoundsValid = _maxRegularAppealRounds > 0 && _maxRegularAppealRounds <= MAX_REGULAR_APPEAL_ROUNDS_LIMIT;
        require(isMaxAppealRoundsValid, ERROR_INVALID_MAX_APPEAL_ROUNDS);

        // Make sure each adjudication round phase duration is valid
        for (uint i = 0; i < _roundStateDurations.length; i++) {
            require(_roundStateDurations[i] > 0 && _roundStateDurations[i] < MAX_ADJ_STATE_DURATION, ERROR_LARGE_ROUND_PHASE_DURATION);
        }

        // Make sure min active balance is not zero
        require(_minActiveBalance > 0, ERROR_ZERO_MIN_ACTIVE_BALANCE);

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
            guardianFee: _fees[0],
            draftFee: _fees[1],
            settleFee: _fees[2],
            finalRoundReduction: _pcts[1]
        });

        config.disputes = DisputesConfig({
            evidenceTerms: _roundStateDurations[0],
            commitTerms: _roundStateDurations[1],
            revealTerms: _roundStateDurations[2],
            appealTerms: _roundStateDurations[3],
            appealConfirmTerms: _roundStateDurations[4],
            penaltyPct: _pcts[0],
            firstRoundGuardiansNumber: _roundParams[0],
            appealStepFactor: _roundParams[1],
            maxRegularAppealRounds: _maxRegularAppealRounds,
            finalRoundLockTerms: _roundParams[3],
            appealCollateralFactor: _appealCollateralParams[0],
            appealConfirmCollateralFactor: _appealCollateralParams[1]
        });

        config.minActiveBalance = _minActiveBalance;

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
    *         0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *         1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *         2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    function _getConfigAt(uint64 _termId, uint64 _lastEnsuredTermId) internal view
        returns (
            IERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        )
    {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);

        FeesConfig storage feesConfig = config.fees;
        feeToken = feesConfig.token;
        fees = [feesConfig.guardianFee, feesConfig.draftFee, feesConfig.settleFee];

        DisputesConfig storage disputesConfig = config.disputes;
        roundStateDurations = [
            disputesConfig.evidenceTerms,
            disputesConfig.commitTerms,
            disputesConfig.revealTerms,
            disputesConfig.appealTerms,
            disputesConfig.appealConfirmTerms
        ];
        pcts = [disputesConfig.penaltyPct, feesConfig.finalRoundReduction];
        roundParams = [
            disputesConfig.firstRoundGuardiansNumber,
            disputesConfig.appealStepFactor,
            uint64(disputesConfig.maxRegularAppealRounds),
            disputesConfig.finalRoundLockTerms
        ];
        appealCollateralParams = [disputesConfig.appealCollateralFactor, disputesConfig.appealConfirmCollateralFactor];

        minActiveBalance = config.minActiveBalance;
    }

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per guardian to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    */
    function _getDraftConfig(uint64 _termId,  uint64 _lastEnsuredTermId) internal view
        returns (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct)
    {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);
        return (config.fees.token, config.fees.draftFee, config.disputes.penaltyPct);
    }

    /**
    * @dev Internal function to get the min active balance config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Minimum amount of guardian tokens that can be activated at the given term
    */
    function _getMinActiveBalance(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (uint256) {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);
        return config.minActiveBalance;
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

contract Controller is IsContract, ModuleIds, CourtClock, CourtConfig, ACL {
    string private constant ERROR_SENDER_NOT_GOVERNOR = "CTR_SENDER_NOT_GOVERNOR";
    string private constant ERROR_INVALID_GOVERNOR_ADDRESS = "CTR_INVALID_GOVERNOR_ADDRESS";
    string private constant ERROR_MODULE_NOT_SET = "CTR_MODULE_NOT_SET";
    string private constant ERROR_MODULE_ALREADY_ENABLED = "CTR_MODULE_ALREADY_ENABLED";
    string private constant ERROR_MODULE_ALREADY_DISABLED = "CTR_MODULE_ALREADY_DISABLED";
    string private constant ERROR_DISPUTE_MANAGER_NOT_ACTIVE = "CTR_DISPUTE_MANAGER_NOT_ACTIVE";
    string private constant ERROR_CUSTOM_FUNCTION_NOT_SET = "CTR_CUSTOM_FUNCTION_NOT_SET";
    string private constant ERROR_IMPLEMENTATION_NOT_CONTRACT = "CTR_IMPLEMENTATION_NOT_CONTRACT";
    string private constant ERROR_INVALID_IMPLS_INPUT_LENGTH = "CTR_INVALID_IMPLS_INPUT_LENGTH";

    address private constant ZERO_ADDRESS = address(0);

    /**
    * @dev Governor of the whole system. Set of three addresses to recover funds, change configuration settings and setup modules
    */
    struct Governor {
        address funds;      // This address can be unset at any time. It is allowed to recover funds from the ControlledRecoverable modules
        address config;     // This address is meant not to be unset. It is allowed to change the different configurations of the whole system
        address modules;    // This address can be unset at any time. It is allowed to plug/unplug modules from the system
    }

    /**
    * @dev Module information
    */
    struct Module {
        bytes32 id;         // ID associated to a module
        bool disabled;      // Whether the module is disabled
    }

    // Governor addresses of the system
    Governor private governor;

    // List of current modules registered for the system indexed by ID
    mapping (bytes32 => address) internal currentModules;

    // List of all historical modules registered for the system indexed by address
    mapping (address => Module) internal allModules;

    // List of custom function targets indexed by signature
    mapping (bytes4 => address) internal customFunctions;

    event ModuleSet(bytes32 id, address addr);
    event ModuleEnabled(bytes32 id, address addr);
    event ModuleDisabled(bytes32 id, address addr);
    event CustomFunctionSet(bytes4 signature, address target);
    event FundsGovernorChanged(address previousGovernor, address currentGovernor);
    event ConfigGovernorChanged(address previousGovernor, address currentGovernor);
    event ModulesGovernorChanged(address previousGovernor, address currentGovernor);

    /**
    * @dev Ensure the msg.sender is the funds governor
    */
    modifier onlyFundsGovernor {
        require(msg.sender == governor.funds, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the modules governor
    */
    modifier onlyConfigGovernor {
        require(msg.sender == governor.config, ERROR_SENDER_NOT_GOVERNOR);
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
    * @dev Ensure the given dispute manager is active
    */
    modifier onlyActiveDisputeManager(IDisputeManager _disputeManager) {
        require(!_isModuleDisabled(address(_disputeManager)), ERROR_DISPUTE_MANAGER_NOT_ACTIVE);
        _;
    }

    /**
    * @dev Constructor function
    * @param _termParams Array containing:
    *        0. _termDuration Duration in seconds per term
    *        1. _firstTermStartTime Timestamp in seconds when the court will open (to give time for guardian on-boarding)
    * @param _governors Array containing:
    *        0. _fundsGovernor Address of the funds governor
    *        1. _configGovernor Address of the config governor
    *        2. _modulesGovernor Address of the modules governor
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *        1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *        2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked to each drafted guardians (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        1. appealCollateralFactor Permyriad multiple of dispute fees required to appeal a preliminary ruling
    *        2. appealConfirmCollateralFactor Permyriad multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    constructor(
        uint64[2] memory _termParams,
        address[3] memory _governors,
        IERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance
    )
        public
        CourtClock(_termParams)
        CourtConfig(_feeToken, _fees, _roundStateDurations, _pcts, _roundParams, _appealCollateralParams, _minActiveBalance)
    {
        _setFundsGovernor(_governors[0]);
        _setConfigGovernor(_governors[1]);
        _setModulesGovernor(_governors[2]);
    }

    /**
    * @dev Fallback function allows to forward calls to a specific address in case it was previously registered
    *      Note the sender will be always the controller in case it is forwarded
    */
    function () external payable {
        address target = customFunctions[msg.sig];
        require(target != address(0), ERROR_CUSTOM_FUNCTION_NOT_SET);

        // solium-disable-next-line security/no-call-value
        (bool success,) = address(target).call.value(msg.value)(msg.data);
        assembly {
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            let result := success
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    /**
    * @notice Change Court configuration params
    * @param _fromTermId Identification number of the term in which the config will be effective at
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *        1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *        2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked to each drafted guardians (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        1. appealCollateralFactor Permyriad multiple of dispute fees required to appeal a preliminary ruling
    *        2. appealConfirmCollateralFactor Permyriad multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    function setConfig(
        uint64 _fromTermId,
        IERC20 _feeToken,
        uint256[3] calldata _fees,
        uint64[5] calldata _roundStateDurations,
        uint16[2] calldata _pcts,
        uint64[4] calldata _roundParams,
        uint256[2] calldata _appealCollateralParams,
        uint256 _minActiveBalance
    )
        external
        onlyConfigGovernor
    {
        uint64 currentTermId = _ensureCurrentTerm();
        _setConfig(
            currentTermId,
            _fromTermId,
            _feeToken,
            _fees,
            _roundStateDurations,
            _pcts,
            _roundParams,
            _appealCollateralParams,
            _minActiveBalance
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
    * @notice Grant `_id` role to `_who`
    * @param _id ID of the role to be granted
    * @param _who Address to grant the role to
    */
    function grant(bytes32 _id, address _who) external onlyConfigGovernor {
        _grant(_id, _who);
    }

    /**
    * @notice Revoke `_id` role from `_who`
    * @param _id ID of the role to be revoked
    * @param _who Address to revoke the role from
    */
    function revoke(bytes32 _id, address _who) external onlyConfigGovernor {
        _revoke(_id, _who);
    }

    /**
    * @notice Freeze `_id` role
    * @param _id ID of the role to be frozen
    */
    function freeze(bytes32 _id) external onlyConfigGovernor {
        _freeze(_id);
    }

    /**
    * @notice Enact a bulk list of ACL operations
    */
    function bulk(BulkOp[] calldata _op, bytes32[] calldata _id, address[] calldata _who) external onlyConfigGovernor {
        _bulk(_op, _id, _who);
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
    * @notice Set and link many modules at once
    * @param _newModuleIds List of IDs of the new modules to be set
    * @param _newModuleAddresses List of addresses of the new modules to be set
    * @param _newModuleLinks List of IDs of the modules that will be linked in the new modules being set
    * @param _currentModulesToBeSynced List of addresses of current modules to be re-linked to the new modules being set
    */
    function setModules(
        bytes32[] calldata _newModuleIds,
        address[] calldata _newModuleAddresses,
        bytes32[] calldata _newModuleLinks,
        address[] calldata _currentModulesToBeSynced
    )
        external
        onlyModulesGovernor
    {
        // We only care about the modules being set, links are optional
        require(_newModuleIds.length == _newModuleAddresses.length, ERROR_INVALID_IMPLS_INPUT_LENGTH);

        // First set the addresses of the new modules or the modules to be updated
        for (uint256 i = 0; i < _newModuleIds.length; i++) {
            _setModule(_newModuleIds[i], _newModuleAddresses[i]);
        }

        // Then sync the links of the new modules based on the list of IDs specified (ideally the IDs of their dependencies)
        _syncModuleLinks(_newModuleAddresses, _newModuleLinks);

        // Finally sync the links of the existing modules to be synced to the new modules being set
        _syncModuleLinks(_currentModulesToBeSynced, _newModuleIds);
    }

    /**
    * @notice Sync modules for a list of modules IDs based on their current implementation address
    * @param _modulesToBeSynced List of addresses of connected modules to be synced
    * @param _idsToBeSet List of IDs of the modules included in the sync
    */
    function syncModuleLinks(address[] calldata _modulesToBeSynced, bytes32[] calldata _idsToBeSet)
        external
        onlyModulesGovernor
    {
        require(_idsToBeSet.length > 0 && _modulesToBeSynced.length > 0, ERROR_INVALID_IMPLS_INPUT_LENGTH);
        _syncModuleLinks(_modulesToBeSynced, _idsToBeSet);
    }

    /**
    * @notice Disable module `_addr`
    * @dev Current modules can be disabled to allow pausing the court. However, these can be enabled back again, see `enableModule`
    * @param _addr Address of the module to be disabled
    */
    function disableModule(address _addr) external onlyModulesGovernor {
        Module storage module = allModules[_addr];
        _ensureModuleExists(module);
        require(!module.disabled, ERROR_MODULE_ALREADY_DISABLED);

        module.disabled = true;
        emit ModuleDisabled(module.id, _addr);
    }

    /**
    * @notice Enable module `_addr`
    * @param _addr Address of the module to be enabled
    */
    function enableModule(address _addr) external onlyModulesGovernor {
        Module storage module = allModules[_addr];
        _ensureModuleExists(module);
        require(module.disabled, ERROR_MODULE_ALREADY_ENABLED);

        module.disabled = false;
        emit ModuleEnabled(module.id, _addr);
    }

    /**
    * @notice Set custom function `_sig` for `_target`
    * @param _sig Signature of the function to be set
    * @param _target Address of the target implementation to be registered for the given signature
    */
    function setCustomFunction(bytes4 _sig, address _target) external onlyModulesGovernor {
        customFunctions[_sig] = _target;
        emit CustomFunctionSet(_sig, _target);
    }

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *         1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *         2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    */
    function getConfig(uint64 _termId) external view
        returns (
            IERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        )
    {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getConfigAt(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per guardian to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct) {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getDraftConfig(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Identification number of the term querying the min active balance config of
    * @return Minimum amount of tokens guardians have to activate to participate in the Court
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
    * @dev Tell the address of the modules governor
    * @return Address of the modules governor
    */
    function getModulesGovernor() external view returns (address) {
        return governor.modules;
    }

    /**
    * @dev Tell if a given module is active
    * @param _id ID of the module to be checked
    * @param _addr Address of the module to be checked
    * @return True if the given module address has the requested ID and is enabled
    */
    function isActive(bytes32 _id, address _addr) external view returns (bool) {
        Module storage module = allModules[_addr];
        return module.id == _id && !module.disabled;
    }

    /**
    * @dev Tell the current ID and disable status of a module based on a given address
    * @param _addr Address of the requested module
    * @return id ID of the module being queried
    * @return disabled Whether the module has been disabled
    */
    function getModuleByAddress(address _addr) external view returns (bytes32 id, bool disabled) {
        Module storage module = allModules[_addr];
        id = module.id;
        disabled = module.disabled;
    }

    /**
    * @dev Tell the current address and disable status of a module based on a given ID
    * @param _id ID of the module being queried
    * @return addr Current address of the requested module
    * @return disabled Whether the module has been disabled
    */
    function getModule(bytes32 _id) external view returns (address addr, bool disabled) {
        return _getModule(_id);
    }

    /**
    * @dev Tell the information for the current DisputeManager module
    * @return addr Current address of the DisputeManager module
    * @return disabled Whether the module has been disabled
    */
    function getDisputeManager() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_DISPUTE_MANAGER);
    }

    /**
    * @dev Tell the information for  the current GuardiansRegistry module
    * @return addr Current address of the GuardiansRegistry module
    * @return disabled Whether the module has been disabled
    */
    function getGuardiansRegistry() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_GUARDIANS_REGISTRY);
    }

    /**
    * @dev Tell the information for the current Voting module
    * @return addr Current address of the Voting module
    * @return disabled Whether the module has been disabled
    */
    function getVoting() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_VOTING);
    }

    /**
    * @dev Tell the information for the current PaymentsBook module
    * @return addr Current address of the PaymentsBook module
    * @return disabled Whether the module has been disabled
    */
    function getPaymentsBook() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_PAYMENTS_BOOK);
    }

    /**
    * @dev Tell the information for the current Treasury module
    * @return addr Current address of the Treasury module
    * @return disabled Whether the module has been disabled
    */
    function getTreasury() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_TREASURY);
    }

    /**
    * @dev Tell the target registered for a custom function
    * @param _sig Signature of the function being queried
    * @return Address of the target where the function call will be forwarded
    */
    function getCustomFunction(bytes4 _sig) external view returns (address) {
        return customFunctions[_sig];
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
    * @dev Internal function to set the address of the modules governor
    * @param _newModulesGovernor Address of the new modules governor to be set
    */
    function _setModulesGovernor(address _newModulesGovernor) internal {
        emit ModulesGovernorChanged(governor.modules, _newModulesGovernor);
        governor.modules = _newModulesGovernor;
    }

    /**
    * @dev Internal function to set an address as the current implementation for a module
    *      Note that the disabled condition is not affected, if the module was not set before it will be enabled by default
    * @param _id Id of the module to be set
    * @param _addr Address of the module to be set
    */
    function _setModule(bytes32 _id, address _addr) internal {
        require(isContract(_addr), ERROR_IMPLEMENTATION_NOT_CONTRACT);

        currentModules[_id] = _addr;
        allModules[_addr].id = _id;
        emit ModuleSet(_id, _addr);
    }

    /**
    * @dev Internal function to sync the modules for a list of modules IDs based on their current implementation address
    * @param _modulesToBeSynced List of addresses of connected modules to be synced
    * @param _idsToBeSet List of IDs of the modules to be linked
    */
    function _syncModuleLinks(address[] memory _modulesToBeSynced, bytes32[] memory _idsToBeSet) internal {
        address[] memory addressesToBeSet = new address[](_idsToBeSet.length);

        // Load the addresses associated with the requested module ids
        for (uint256 i = 0; i < _idsToBeSet.length; i++) {
            address moduleAddress = _getModuleAddress(_idsToBeSet[i]);
            Module storage module = allModules[moduleAddress];
            _ensureModuleExists(module);
            addressesToBeSet[i] = moduleAddress;
        }

        // Update the links of all the requested modules
        for (uint256 j = 0; j < _modulesToBeSynced.length; j++) {
            IModulesLinker(_modulesToBeSynced[j]).linkModules(_idsToBeSet, addressesToBeSet);
        }
    }

    /**
    * @dev Internal function to notify when a term has been transitioned
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _onTermTransitioned(uint64 _termId) internal {
        _ensureTermConfig(_termId);
    }

    /**
    * @dev Internal function to check if a module was set
    * @param _module Module to be checked
    */
    function _ensureModuleExists(Module storage _module) internal view {
        require(_module.id != bytes32(0), ERROR_MODULE_NOT_SET);
    }

    /**
    * @dev Internal function to tell the information for a module based on a given ID
    * @param _id ID of the module being queried
    * @return addr Current address of the requested module
    * @return disabled Whether the module has been disabled
    */
    function _getModule(bytes32 _id) internal view returns (address addr, bool disabled) {
        addr = _getModuleAddress(_id);
        disabled = _isModuleDisabled(addr);
    }

    /**
    * @dev Tell the current address for a module by ID
    * @param _id ID of the module being queried
    * @return Current address of the requested module
    */
    function _getModuleAddress(bytes32 _id) internal view returns (address) {
        return currentModules[_id];
    }

    /**
    * @dev Tell whether a module is disabled
    * @param _addr Address of the module being queried
    * @return True if the module is disabled, false otherwise
    */
    function _isModuleDisabled(address _addr) internal view returns (bool) {
        return allModules[_addr].disabled;
    }
}

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
        (IERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance) = _courtConfig().getConfig(_termId);

        Config memory config;

        config.fees = FeesConfig({
            token: _feeToken,
            guardianFee: _fees[0],
            draftFee: _fees[1],
            settleFee: _fees[2],
            finalRoundReduction: _pcts[1]
        });

        config.disputes = DisputesConfig({
            evidenceTerms: _roundStateDurations[0],
            commitTerms: _roundStateDurations[1],
            revealTerms: _roundStateDurations[2],
            appealTerms: _roundStateDurations[3],
            appealConfirmTerms: _roundStateDurations[4],
            penaltyPct: _pcts[0],
            firstRoundGuardiansNumber: _roundParams[0],
            appealStepFactor: _roundParams[1],
            maxRegularAppealRounds: _roundParams[2],
            finalRoundLockTerms: _roundParams[3],
            appealCollateralFactor: _appealCollateralParams[0],
            appealConfirmCollateralFactor: _appealCollateralParams[1]
        });

        config.minActiveBalance = _minActiveBalance;

        return config;
    }

    /**
    * @dev Internal function to get the draft config for a given term
    * @param _termId Identification number of the term querying the draft config of
    * @return Draft config for the given term
    */
    function _getDraftConfig(uint64 _termId) internal view returns (DraftConfig memory) {
        (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct) = _courtConfig().getDraftConfig(_termId);
        return DraftConfig({ feeToken: feeToken, draftFee: draftFee, penaltyPct: penaltyPct });
    }

    /**
    * @dev Internal function to get the min active balance config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @return Minimum amount of guardian tokens that can be activated
    */
    function _getMinActiveBalance(uint64 _termId) internal view returns (uint256) {
        return _courtConfig().getMinActiveBalance(_termId);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */
interface IPaymentsBook {
    /**
    * @dev Pay an amount of tokens
    * @param _token Address of the token being paid
    * @param _amount Amount of tokens being paid
    * @param _payer Address paying on behalf of
    * @param _data Optional data
    */
    function pay(address _token, uint256 _amount, address _payer, bytes calldata _data) external payable;
}

contract Controlled is IModulesLinker, IsContract, ModuleIds, ConfigConsumer {
    string private constant ERROR_MODULE_NOT_SET = "CTD_MODULE_NOT_SET";
    string private constant ERROR_INVALID_MODULES_LINK_INPUT = "CTD_INVALID_MODULES_LINK_INPUT";
    string private constant ERROR_CONTROLLER_NOT_CONTRACT = "CTD_CONTROLLER_NOT_CONTRACT";
    string private constant ERROR_SENDER_NOT_ALLOWED = "CTD_SENDER_NOT_ALLOWED";
    string private constant ERROR_SENDER_NOT_CONTROLLER = "CTD_SENDER_NOT_CONTROLLER";
    string private constant ERROR_SENDER_NOT_CONFIG_GOVERNOR = "CTD_SENDER_NOT_CONFIG_GOVERNOR";
    string private constant ERROR_SENDER_NOT_ACTIVE_VOTING = "CTD_SENDER_NOT_ACTIVE_VOTING";
    string private constant ERROR_SENDER_NOT_ACTIVE_DISPUTE_MANAGER = "CTD_SEND_NOT_ACTIVE_DISPUTE_MGR";
    string private constant ERROR_SENDER_NOT_CURRENT_DISPUTE_MANAGER = "CTD_SEND_NOT_CURRENT_DISPUTE_MGR";

    // Address of the controller
    Controller public controller;

    // List of modules linked indexed by ID
    mapping (bytes32 => address) public linkedModules;

    event ModuleLinked(bytes32 id, address addr);

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
    * @dev Ensure the msg.sender is an active DisputeManager module
    */
    modifier onlyActiveDisputeManager() {
        require(controller.isActive(MODULE_ID_DISPUTE_MANAGER, msg.sender), ERROR_SENDER_NOT_ACTIVE_DISPUTE_MANAGER);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the current DisputeManager module
    */
    modifier onlyCurrentDisputeManager() {
        (address addr, bool disabled) = controller.getDisputeManager();
        require(msg.sender == addr, ERROR_SENDER_NOT_CURRENT_DISPUTE_MANAGER);
        require(!disabled, ERROR_SENDER_NOT_ACTIVE_DISPUTE_MANAGER);
        _;
    }

    /**
    * @dev Ensure the msg.sender is an active Voting module
    */
    modifier onlyActiveVoting() {
        require(controller.isActive(MODULE_ID_VOTING, msg.sender), ERROR_SENDER_NOT_ACTIVE_VOTING);
        _;
    }

    /**
    * @dev This modifier will check that the sender is the user to act on behalf of or someone with the required permission
    * @param _user Address of the user to act on behalf of
    */
    modifier authenticateSender(address _user) {
        _authenticateSender(_user);
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
    * @notice Update the implementation links of a list of modules
    * @dev The controller is expected to ensure the given addresses are correct modules
    * @param _ids List of IDs of the modules to be updated
    * @param _addresses List of module addresses to be updated
    */
    function linkModules(bytes32[] calldata _ids, address[] calldata _addresses) external onlyController {
        require(_ids.length == _addresses.length, ERROR_INVALID_MODULES_LINK_INPUT);

        for (uint256 i = 0; i < _ids.length; i++) {
            linkedModules[_ids[i]] = _addresses[i];
            emit ModuleLinked(_ids[i], _addresses[i]);
        }
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
    * @return Address of the controller's config governor
    */
    function _configGovernor() internal view returns (address) {
        return controller.getConfigGovernor();
    }

    /**
    * @dev Internal function to fetch the address of the DisputeManager module
    * @return Address of the DisputeManager module
    */
    function _disputeManager() internal view returns (IDisputeManager) {
        return IDisputeManager(_getLinkedModule(MODULE_ID_DISPUTE_MANAGER));
    }

    /**
    * @dev Internal function to fetch the address of the GuardianRegistry module implementation
    * @return Address of the GuardianRegistry module implementation
    */
    function _guardiansRegistry() internal view returns (IGuardiansRegistry) {
        return IGuardiansRegistry(_getLinkedModule(MODULE_ID_GUARDIANS_REGISTRY));
    }

    /**
    * @dev Internal function to fetch the address of the Voting module implementation
    * @return Address of the Voting module implementation
    */
    function _voting() internal view returns (ICRVoting) {
        return ICRVoting(_getLinkedModule(MODULE_ID_VOTING));
    }

    /**
    * @dev Internal function to fetch the address of the PaymentsBook module implementation
    * @return Address of the PaymentsBook module implementation
    */
    function _paymentsBook() internal view returns (IPaymentsBook) {
        return IPaymentsBook(_getLinkedModule(MODULE_ID_PAYMENTS_BOOK));
    }

    /**
    * @dev Internal function to fetch the address of the Treasury module implementation
    * @return Address of the Treasury module implementation
    */
    function _treasury() internal view returns (ITreasury) {
        return ITreasury(_getLinkedModule(MODULE_ID_TREASURY));
    }

    /**
    * @dev Internal function to tell the address linked for a module based on a given ID
    * @param _id ID of the module being queried
    * @return Linked address of the requested module
    */
    function _getLinkedModule(bytes32 _id) internal view returns (address) {
        address module = linkedModules[_id];
        require(module != address(0), ERROR_MODULE_NOT_SET);
        return module;
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

    /**
    * @dev Ensure that the sender is the user to act on behalf of or someone with the required permission
    * @param _user Address of the user to act on behalf of
    */
    function _authenticateSender(address _user) internal view {
        require(_isSenderAllowed(_user), ERROR_SENDER_NOT_ALLOWED);
    }

    /**
    * @dev Tell whether the sender is the user to act on behalf of or someone with the required permission
    * @param _user Address of the user to act on behalf of
    * @return True if the sender is the user to act on behalf of or someone with the required permission, false otherwise
    */
    function _isSenderAllowed(address _user) internal view returns (bool) {
        return msg.sender == _user || _hasRole(msg.sender);
    }

    /**
    * @dev Tell whether an address holds the required permission to access the requested functionality
    * @param _addr Address being checked
    * @return True if the given address has the required permission to access the requested functionality, false otherwise
    */
    function _hasRole(address _addr) internal view returns (bool) {
        bytes32 roleId = keccak256(abi.encodePacked(address(this), msg.sig));
        return controller.hasRole(_addr, roleId);
    }
}

contract ControlledRecoverable is Controlled {
    using SafeERC20 for IERC20;

    string private constant ERROR_SENDER_NOT_FUNDS_GOVERNOR = "CTD_SENDER_NOT_FUNDS_GOVERNOR";
    string private constant ERROR_INSUFFICIENT_RECOVER_FUNDS = "CTD_INSUFFICIENT_RECOVER_FUNDS";
    string private constant ERROR_RECOVER_TOKEN_FUNDS_FAILED = "CTD_RECOVER_TOKEN_FUNDS_FAILED";

    event RecoverFunds(address token, address recipient, uint256 balance);

    /**
    * @dev Ensure the msg.sender is the controller's funds governor
    */
    modifier onlyFundsGovernor {
        require(msg.sender == controller.getFundsGovernor(), ERROR_SENDER_NOT_FUNDS_GOVERNOR);
        _;
    }

    /**
    * @notice Transfer all `_token` tokens to `_to`
    * @param _token Address of the token to be recovered
    * @param _to Address of the recipient that will be receive all the funds of the requested token
    */
    function recoverFunds(address _token, address payable _to) external payable onlyFundsGovernor {
        uint256 balance;

        if (_token == address(0)) {
            balance = address(this).balance;
            require(_to.send(balance), ERROR_RECOVER_TOKEN_FUNDS_FAILED);
        } else {
            balance = IERC20(_token).balanceOf(address(this));
            require(balance > 0, ERROR_INSUFFICIENT_RECOVER_FUNDS);
            // No need to verify _token to be a contract as we have already checked the balance
            require(IERC20(_token).safeTransfer(_to, balance), ERROR_RECOVER_TOKEN_FUNDS_FAILED);
        }

        emit RecoverFunds(_token, _to, balance);
    }
}

contract DisputeManager is IDisputeManager, ICRVotingOwner, ControlledRecoverable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using PctHelpers for uint256;
    using Uint256Helpers for uint256;

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
    string private constant ERROR_VOTER_WEIGHT_ZERO = "DM_VOTER_WEIGHT_ZERO";
    string private constant ERROR_ROUND_NOT_APPEALED = "DM_ROUND_NOT_APPEALED";
    string private constant ERROR_INVALID_APPEAL_RULING = "DM_INVALID_APPEAL_RULING";

    // Settlements-related error messages
    string private constant ERROR_PREV_ROUND_NOT_SETTLED = "DM_PREVIOUS_ROUND_NOT_SETTLED";
    string private constant ERROR_ROUND_ALREADY_SETTLED = "DM_ROUND_ALREADY_SETTLED";
    string private constant ERROR_ROUND_NOT_SETTLED = "DM_ROUND_PENALTIES_NOT_SETTLED";
    string private constant ERROR_GUARDIAN_ALREADY_REWARDED = "DM_GUARDIAN_ALREADY_REWARDED";
    string private constant ERROR_WONT_REWARD_NON_VOTER_GUARDIAN = "DM_WONT_REWARD_NON_VOTER_GUARD";
    string private constant ERROR_WONT_REWARD_INCOHERENT_GUARDIAN = "DM_WONT_REWARD_INCOHERENT_GUARD";
    string private constant ERROR_ROUND_APPEAL_ALREADY_SETTLED = "DM_APPEAL_ALREADY_SETTLED";

    // Minimum possible rulings for a dispute
    uint8 internal constant MIN_RULING_OPTIONS = 2;

    // Maximum possible rulings for a dispute, equal to minimum limit
    uint8 internal constant MAX_RULING_OPTIONS = MIN_RULING_OPTIONS;

    // Precision factor used to improve rounding when computing weights for the final round
    uint256 internal constant FINAL_ROUND_WEIGHT_PRECISION = 1000;

    // Mask used to decode vote IDs
    uint256 internal constant VOTE_ID_MASK = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    struct Dispute {
        IArbitrable subject;           // Arbitrable associated to a dispute
        uint64 createTermId;           // Term ID when the dispute was created
        uint8 possibleRulings;         // Number of possible rulings guardians can vote for each dispute
        uint8 finalRuling;             // Winning ruling of a dispute
        DisputeState state;            // State of a dispute: pre-draft, adjudicating, or ruled
        AdjudicationRound[] rounds;    // List of rounds for each dispute
    }

    struct AdjudicationRound {
        uint64 draftTermId;            // Term from which the guardians of a round can be drafted
        uint64 guardiansNumber;        // Number of guardians drafted for a round
        bool settledPenalties;         // Whether or not penalties have been settled for a round
        uint256 guardianFees;          // Total amount of fees to be distributed between the winning guardians of a round
        address[] guardians;           // List of guardians drafted for a round
        mapping (address => GuardianState) guardiansStates; // List of states for each drafted guardian indexed by address
        uint64 delayedTerms;           // Number of terms a round was delayed based on its requested draft term id
        uint64 selectedGuardians;      // Number of guardians selected for a round, to allow drafts to be batched
        uint64 coherentGuardians;      // Number of drafted guardians that voted in favor of the dispute final ruling
        uint64 settledGuardians;       // Number of guardians whose rewards were already settled
        uint256 collectedTokens;       // Total amount of tokens collected from losing guardians
        Appeal appeal;                 // Appeal-related information of a round
    }

    struct GuardianState {
        uint64 weight;                 // Weight computed for a guardian on a round
        bool rewarded;                 // Whether or not a drafted guardian was rewarded
    }

    struct Appeal {
        address maker;                 // Address of the appealer
        uint8 appealedRuling;          // Ruling appealing in favor of
        address taker;                 // Address of the one confirming an appeal
        uint8 opposedRuling;           // Ruling opposed to an appeal
        bool settled;                  // Whether or not an appeal has been settled
    }

    struct DraftParams {
        uint256 disputeId;             // Identification number of the dispute to be drafted
        uint256 roundId;               // Identification number of the round to be drafted
        uint64 termId;                 // Identification number of the current term of the Court
        bytes32 draftTermRandomness;   // Randomness of the term in which the dispute was requested to be drafted
        DraftConfig config;            // Draft config of the Court at the draft term
    }

    struct NextRoundDetails {
        uint64 startTerm;              // Term ID from which the next round will start
        uint64 guardiansNumber;        // Guardians number for the next round
        DisputeState newDisputeState;  // New state for the dispute associated to the given round after the appeal
        IERC20 feeToken;               // ERC20 token used for the next round fees
        uint256 totalFees;             // Total amount of fees to be distributed between the winning guardians of the next round
        uint256 guardianFees;          // Total amount of fees for a regular round at the given term
        uint256 appealDeposit;         // Amount to be deposit of fees for a regular round at the given term
        uint256 confirmAppealDeposit;  // Total amount of fees for a regular round at the given term
    }

    // Max guardians to be drafted in each batch. To prevent running out of gas. We allow to change it because max gas per tx can vary
    // As a reference, drafting 100 guardians from a small tree of 4 would cost ~2.4M. Drafting 500, ~7.75M.
    uint64 public maxGuardiansPerDraftBatch;

    // List of all the disputes created in the Court
    Dispute[] internal disputes;

    event DisputeStateChanged(uint256 indexed disputeId, DisputeState indexed state);
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, bytes evidence);
    event EvidencePeriodClosed(uint256 indexed disputeId, uint64 indexed termId);
    event NewDispute(uint256 indexed disputeId, IArbitrable indexed subject, uint64 indexed draftTermId, bytes metadata);
    event GuardianDrafted(uint256 indexed disputeId, uint256 indexed roundId, address indexed guardian);
    event RulingAppealed(uint256 indexed disputeId, uint256 indexed roundId, uint8 ruling);
    event RulingAppealConfirmed(uint256 indexed disputeId, uint256 indexed roundId, uint64 indexed draftTermId);
    event RulingComputed(uint256 indexed disputeId, uint8 indexed ruling);
    event PenaltiesSettled(uint256 indexed disputeId, uint256 indexed roundId, uint256 collectedTokens);
    event RewardSettled(uint256 indexed disputeId, uint256 indexed roundId, address guardian, uint256 tokens, uint256 fees);
    event AppealDepositSettled(uint256 indexed disputeId, uint256 indexed roundId);
    event MaxGuardiansPerDraftBatchChanged(uint64 maxGuardiansPerDraftBatch);

    /**
    * @dev Constructor function
    * @param _controller Address of the controller
    * @param _maxGuardiansPerDraftBatch Max number of guardians to be drafted per batch
    * @param _skippedDisputes Number of disputes to be skipped
    */
    constructor(Controller _controller, uint64 _maxGuardiansPerDraftBatch, uint256 _skippedDisputes) Controlled(_controller) public {
        _setMaxGuardiansPerDraftBatch(_maxGuardiansPerDraftBatch);
        _skipDisputes(_skippedDisputes);
    }

    /**
    * @notice Create a dispute over `_subject` with `_possibleRulings` possible rulings
    * @param _subject Arbitrable instance creating the dispute
    * @param _possibleRulings Number of possible rulings allowed for the drafted guardians to vote on the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identification number
    */
    function createDispute(IArbitrable _subject, uint8 _possibleRulings, bytes calldata _metadata) external onlyController returns (uint256) {
        uint64 termId = _ensureCurrentTerm();
        require(_possibleRulings >= MIN_RULING_OPTIONS && _possibleRulings <= MAX_RULING_OPTIONS, ERROR_INVALID_RULING_OPTIONS);

        // Create the dispute
        uint256 disputeId = disputes.length++;
        Dispute storage dispute = disputes[disputeId];
        dispute.subject = _subject;
        dispute.possibleRulings = _possibleRulings;
        dispute.createTermId = termId;

        Config memory config = _getConfigAt(termId);
        uint64 draftTermId = termId.add(config.disputes.evidenceTerms);
        emit NewDispute(disputeId, _subject, draftTermId, _metadata);

        // Create first adjudication round of the dispute
        uint64 guardiansNumber = config.disputes.firstRoundGuardiansNumber;
        (IERC20 feeToken, uint256 guardianFees, uint256 totalFees) = _getRegularRoundFees(config.fees, guardiansNumber);
        _createRound(disputeId, DisputeState.PreDraft, draftTermId, guardiansNumber, guardianFees);

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
        external
        onlyController
    {
        (Dispute storage dispute, ) = _getDisputeAndRound(_disputeId, 0);
        require(dispute.subject == _subject, ERROR_SUBJECT_NOT_DISPUTE_SUBJECT);
        emit EvidenceSubmitted(_disputeId, _submitter, _evidence);
    }

    /**
    * @notice Close the evidence period of dispute #`_disputeId`
    * @param _subject IArbitrable instance requesting to close the evidence submission period
    * @param _disputeId Identification number of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(IArbitrable _subject, uint256 _disputeId) external onlyController {
        (Dispute storage dispute, AdjudicationRound storage round) = _getDisputeAndRound(_disputeId, 0);
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
    * @notice Draft guardians for the next round of dispute #`_disputeId`
    * @param _disputeId Identification number of the dispute to be drafted
    */
    function draft(uint256 _disputeId) external {
        // Drafts can only be computed when the Court is up-to-date. Note that forcing a term transition won't work since the term randomness
        // is always based on the next term which means it won't be available anyway.
        IClock clock = _clock();
        uint64 requiredTransitions = _clock().getNeededTermTransitions();
        require(uint256(requiredTransitions) == 0, ERROR_TERM_OUTDATED);
        uint64 currentTermId = _getLastEnsuredTermId();

        // Ensure dispute has not been drafted yet
        Dispute storage dispute = _getDispute(_disputeId);
        require(dispute.state == DisputeState.PreDraft, ERROR_ROUND_ALREADY_DRAFTED);

        // Ensure draft term randomness can be computed for the current block number
        uint256 roundId = dispute.rounds.length - 1;
        AdjudicationRound storage round = dispute.rounds[roundId];
        uint64 draftTermId = round.draftTermId;
        require(draftTermId <= currentTermId, ERROR_DRAFT_TERM_NOT_REACHED);
        bytes32 draftTermRandomness = clock.ensureCurrentTermRandomness();

        // Draft guardians for the given dispute and reimburse fees
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
    function createAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external {
        // Ensure current term and check that the given round can be appealed.
        // Note that if there was a final appeal the adjudication state will be 'Ended'.
        (Dispute storage dispute, AdjudicationRound storage round, Config memory config) = _getDisputeAndRoundWithConfig(_disputeId, _roundId);
        _ensureAdjudicationState(dispute, _roundId, AdjudicationState.Appealing, config.disputes);

        // Ensure that the ruling being appealed in favor of is valid and different from the current winning ruling
        ICRVoting voting = _voting();
        uint256 voteId = _getVoteId(_disputeId, _roundId);
        uint8 roundWinningRuling = voting.getWinningOutcome(voteId);
        require(roundWinningRuling != _ruling && voting.isValidOutcome(voteId, _ruling), ERROR_INVALID_APPEAL_RULING);

        // Update round appeal state
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
    function confirmAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external {
        // Ensure current term and check that the given round is appealed and can be confirmed.
        // Note that if there was a final appeal the adjudication state will be 'Ended'.
        (Dispute storage dispute, AdjudicationRound storage round, Config memory config) = _getDisputeAndRoundWithConfig(_disputeId, _roundId);
        _ensureAdjudicationState(dispute, _roundId, AdjudicationState.ConfirmingAppeal, config.disputes);

        // Ensure that the ruling being confirmed in favor of is valid and different from the appealed ruling
        Appeal storage appeal = round.appeal;
        uint256 voteId = _getVoteId(_disputeId, _roundId);
        require(appeal.appealedRuling != _ruling && _voting().isValidOutcome(voteId, _ruling), ERROR_INVALID_APPEAL_RULING);

        // Create a new adjudication round for the dispute
        NextRoundDetails memory nextRound = _getNextRoundDetails(round, _roundId, config);
        DisputeState newDisputeState = nextRound.newDisputeState;
        uint256 newRoundId = _createRound(_disputeId, newDisputeState, nextRound.startTerm, nextRound.guardiansNumber, nextRound.guardianFees);

        // Update previous round appeal state
        appeal.taker = msg.sender;
        appeal.opposedRuling = _ruling;
        emit RulingAppealConfirmed(_disputeId, newRoundId, nextRound.startTerm);

        // Pay appeal confirm deposit
        _depositAmount(msg.sender, nextRound.feeToken, nextRound.confirmAppealDeposit);
    }

    /**
    * @notice Compute the final ruling for dispute #`_disputeId`
    * @param _disputeId Identification number of the dispute to compute its final ruling
    * @return subject Arbitrable instance associated to the dispute
    * @return finalRuling Final ruling decided for the given dispute
    */
    function computeRuling(uint256 _disputeId) external returns (IArbitrable subject, uint8 finalRuling) {
        (Dispute storage dispute, Config memory config) = _getDisputeWithConfig(_disputeId);

        subject = dispute.subject;
        finalRuling = _ensureFinalRuling(dispute, _disputeId, config);

        if (dispute.state != DisputeState.Ruled) {
            dispute.state = DisputeState.Ruled;
            emit RulingComputed(_disputeId, finalRuling);
        }
    }

    /**
    * @notice Settle penalties for round #`_roundId` of dispute #`_disputeId`
    * @dev In case of a regular round, all the drafted guardians that didn't vote in favor of the final ruling of the given dispute will be slashed.
    *      In case of a final round, guardians are slashed when voting, thus it is considered these rounds settled at once. Rewards have to be
    *      manually claimed through `settleReward` which will return pre-slashed tokens for the winning guardians of a final round as well.
    * @param _disputeId Identification number of the dispute to settle penalties for
    * @param _roundId Identification number of the dispute round to settle penalties for
    * @param _guardiansToSettle Maximum number of guardians to be slashed in this call. It can be set to zero to slash all the losing guardians of the
    *        given round. This argument is only used when settling regular rounds.
    */
    function settlePenalties(uint256 _disputeId, uint256 _roundId, uint256 _guardiansToSettle) external {
        // Enforce that rounds are settled in order to avoid one round without incentive to settle. Even if there is a settle fee
        // it may not be big enough and all guardians in the round could be slashed.
        (Dispute storage dispute, AdjudicationRound storage round, Config memory config) = _getDisputeAndRoundWithConfig(_disputeId, _roundId);
        require(_roundId == 0 || dispute.rounds[_roundId - 1].settledPenalties, ERROR_PREV_ROUND_NOT_SETTLED);

        // Ensure given round has not been fully settled yet
        require(!round.settledPenalties, ERROR_ROUND_ALREADY_SETTLED);

        // Ensure the final ruling of the given dispute is already computed
        uint8 finalRuling = _ensureFinalRuling(dispute, _disputeId, config);

        // Set the number of guardians that voted in favor of the final ruling if we haven't started settling yet
        uint256 voteId = _getVoteId(_disputeId, _roundId);
        if (round.settledGuardians == 0) {
            // Note that we are safe to cast the tally of a ruling to uint64 since the highest value a ruling can have is equal to the guardians
            // number for regular rounds or to the total active balance of the registry for final rounds, and both are ensured to fit in uint64.
            ICRVoting voting = _voting();
            round.coherentGuardians = uint64(voting.getOutcomeTally(voteId, finalRuling));
        }

        ITreasury treasury = _treasury();
        IERC20 feeToken = config.fees.token;
        if (_isRegularRound(_roundId, config)) {
            // For regular appeal rounds we compute the amount of locked tokens that needs to get burned in batches.
            // The callers of this function will get rewarded in this case.
            uint256 guardiansSettled = _settleRegularRoundPenalties(round, voteId, finalRuling, config.disputes.penaltyPct, _guardiansToSettle, config.minActiveBalance);
            treasury.assign(feeToken, msg.sender, config.fees.settleFee.mul(guardiansSettled));
        } else {
            // For the final appeal round, there is no need to settle in batches since, to guarantee scalability,
            // all the tokens are collected from guardians when they vote, and those guardians who
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
    * @notice Claim reward for round #`_roundId` of dispute #`_disputeId` for guardian `_guardian`
    * @dev For regular rounds, it will only reward winning guardians
    * @param _disputeId Identification number of the dispute to settle rewards for
    * @param _roundId Identification number of the dispute round to settle rewards for
    * @param _guardian Address of the guardian to settle their rewards
    */
    function settleReward(uint256 _disputeId, uint256 _roundId, address _guardian) external {
        // Ensure dispute round penalties are settled first
        (Dispute storage dispute, AdjudicationRound storage round, Config memory config) = _getDisputeAndRoundWithConfig(_disputeId, _roundId);
        require(round.settledPenalties, ERROR_ROUND_NOT_SETTLED);

        // Ensure given guardian was not rewarded yet and was drafted for the given round
        GuardianState storage guardianState = round.guardiansStates[_guardian];
        require(!guardianState.rewarded, ERROR_GUARDIAN_ALREADY_REWARDED);
        require(uint256(guardianState.weight) > 0, ERROR_WONT_REWARD_NON_VOTER_GUARDIAN);
        guardianState.rewarded = true;

        // Check if the given guardian has voted in favor of the final ruling of the dispute in this round
        ICRVoting voting = _voting();
        uint256 voteId = _getVoteId(_disputeId, _roundId);
        require(voting.hasVotedInFavorOf(voteId, dispute.finalRuling, _guardian), ERROR_WONT_REWARD_INCOHERENT_GUARDIAN);

        uint256 collectedTokens = round.collectedTokens;
        IGuardiansRegistry guardiansRegistry = _guardiansRegistry();

        // Distribute the collected tokens of the guardians that were slashed weighted by the winning guardians. Note that we are penalizing guardians
        // that refused intentionally their vote for the final round.
        uint256 rewardTokens;
        if (collectedTokens > 0) {
            // Note that the number of coherent guardians has to be greater than zero since we already ensured the guardian has voted in favor of the
            // final ruling, therefore there will be at least one coherent guardian and divisions below are safe.
            rewardTokens = _getRoundWeightedAmount(round, guardianState, collectedTokens);
            guardiansRegistry.assignTokens(_guardian, rewardTokens);
        }

        // Reward the winning guardian with fees
        // Note that the number of coherent guardians has to be greater than zero since we already ensured the guardian has voted in favor of the
        // final ruling, therefore there will be at least one coherent guardian and divisions below are safe.
        uint256 rewardFees = _getRoundWeightedAmount(round, guardianState, round.guardianFees);
        _treasury().assign(config.fees.token, _guardian, rewardFees);

        // Set the lock for final round
        if (!_isRegularRound(_roundId, config)) {
            // Round end term ID (as it's final there's no draft delay nor appeal) plus the lock period
            DisputesConfig memory disputesConfig = config.disputes;
            guardiansRegistry.lockWithdrawals(
                _guardian,
                round.draftTermId + disputesConfig.commitTerms + disputesConfig.revealTerms + disputesConfig.finalRoundLockTerms
            );
        }

        emit RewardSettled(_disputeId, _roundId, _guardian, rewardTokens, rewardFees);
    }

    /**
    * @notice Settle appeal deposits for round #`_roundId` of dispute #`_disputeId`
    * @param _disputeId Identification number of the dispute to settle appeal deposits for
    * @param _roundId Identification number of the dispute round to settle appeal deposits for
    */
    function settleAppealDeposit(uint256 _disputeId, uint256 _roundId) external {
        // Ensure dispute round penalties are settled first
        (Dispute storage dispute, AdjudicationRound storage round, Config memory config) = _getDisputeAndRoundWithConfig(_disputeId, _roundId);
        require(round.settledPenalties, ERROR_ROUND_NOT_SETTLED);

        // Ensure given round was appealed and has not been settled yet
        Appeal storage appeal = round.appeal;
        require(_existsAppeal(appeal), ERROR_ROUND_NOT_APPEALED);
        require(!appeal.settled, ERROR_ROUND_APPEAL_ALREADY_SETTLED);
        appeal.settled = true;
        emit AppealDepositSettled(_disputeId, _roundId);

        // Load next round details
        NextRoundDetails memory nextRound = _getNextRoundDetails(round, _roundId, config);
        IERC20 feeToken = nextRound.feeToken;
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
        // selected by any of the appealing parties or no guardian voted in the in favor of the possible outcomes, we split it between both parties.
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
        (Dispute storage dispute, uint256 roundId, Config memory config) = _decodeVoteId(_voteId);

        // Ensure current term and check that votes can still be committed for the given round
        _ensureAdjudicationState(dispute, roundId, AdjudicationState.Committing, config.disputes);
    }

    /**
    * @notice Ensure `voter` can commit votes for vote #`_voteId`, revert otherwise
    * @dev This function will ensure the current term of the Court and revert in case the given voter is not allowed to commit votes
    * @param _voteId ID of the vote instance to request the weight of a voter for
    * @param _voter Address of the voter querying the weight of
    */
    function ensureCanCommit(uint256 _voteId, address _voter) external onlyActiveVoting {
        (Dispute storage dispute, uint256 roundId, Config memory config) = _decodeVoteId(_voteId);

        // Ensure current term and check that votes can still be committed for the given round
        _ensureAdjudicationState(dispute, roundId, AdjudicationState.Committing, config.disputes);
        uint64 weight = _computeGuardianWeight(dispute, roundId, _voter, config);
        require(weight > 0, ERROR_VOTER_WEIGHT_ZERO);
    }

    /**
    * @notice Ensure `voter` can reveal votes for vote #`_voteId`, revert otherwise
    * @dev This function will ensure the current term of the Court and revert in case votes cannot still be revealed
    * @param _voteId ID of the vote instance to request the weight of a voter for
    * @param _voter Address of the voter querying the weight of
    * @return Weight of the requested guardian for the requested dispute's round
    */
    function ensureCanReveal(uint256 _voteId, address _voter) external returns (uint64) {
        (Dispute storage dispute, uint256 roundId, Config memory config) = _decodeVoteId(_voteId);

        // Ensure current term and check that votes can still be revealed for the given round
        _ensureAdjudicationState(dispute, roundId, AdjudicationState.Revealing, config.disputes);
        AdjudicationRound storage round = dispute.rounds[roundId];
        return _getGuardianWeight(round, _voter);
    }

    /**
    * @notice Sets the global configuration for the max number of guardians to be drafted per batch to `_maxGuardiansPerDraftBatch`
    * @param _maxGuardiansPerDraftBatch Max number of guardians to be drafted per batch
    */
    function setMaxGuardiansPerDraftBatch(uint64 _maxGuardiansPerDraftBatch) external onlyConfigGovernor {
        _setMaxGuardiansPerDraftBatch(_maxGuardiansPerDraftBatch);
    }

    /**
    * @dev Tell the amount of token fees required to create a dispute
    * @return feeToken IERC20 token used for the fees
    * @return totalFees Total amount of fees for a regular round at the given term
    */
    function getDisputeFees() external view returns (IERC20 feeToken, uint256 totalFees) {
        uint64 currentTermId = _getCurrentTermId();
        Config memory config = _getConfigAt(currentTermId);
        (feeToken,, totalFees) = _getRegularRoundFees(config.fees, config.disputes.firstRoundGuardiansNumber);
    }

    /**
    * @dev Tell information of a certain dispute
    * @param _disputeId Identification number of the dispute being queried
    * @return subject Arbitrable subject being disputed
    * @return possibleRulings Number of possible rulings allowed for the drafted guardians to vote on the dispute
    * @return state Current state of the dispute being queried: pre-draft, adjudicating, or ruled
    * @return finalRuling The winning ruling in case the dispute is finished
    * @return lastRoundId Identification number of the last round created for the dispute
    * @return createTermId Identification number of the term when the dispute was created
    */
    function getDispute(uint256 _disputeId) external view
        returns (
            IArbitrable subject,
            uint8 possibleRulings,
            DisputeState state,
            uint8 finalRuling,
            uint256 lastRoundId,
            uint64 createTermId
        )
    {
        Dispute storage dispute = _getDispute(_disputeId);

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
    * @return guardiansNumber Number of guardians requested for the round
    * @return selectedGuardians Number of guardians already selected for the requested round
    * @return settledPenalties Whether or not penalties have been settled for the requested round
    * @return collectedTokens Amount of guardian tokens that were collected from slashed guardians for the requested round
    * @return coherentGuardians Number of guardians that voted in favor of the final ruling in the requested round
    * @return state Adjudication state of the requested round
    */
    function getRound(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 draftTerm,
            uint64 delayedTerms,
            uint64 guardiansNumber,
            uint64 selectedGuardians,
            uint256 guardianFees,
            bool settledPenalties,
            uint256 collectedTokens,
            uint64 coherentGuardians,
            AdjudicationState state
        )
    {
        (Dispute storage dispute, AdjudicationRound storage round, Config memory config) = _getDisputeAndRoundWithConfig(_disputeId, _roundId);
        state = _adjudicationStateAt(dispute, _roundId, _getCurrentTermId(), config.disputes);

        draftTerm = round.draftTermId;
        delayedTerms = round.delayedTerms;
        guardiansNumber = round.guardiansNumber;
        selectedGuardians = round.selectedGuardians;
        guardianFees = round.guardianFees;
        settledPenalties = round.settledPenalties;
        coherentGuardians = round.coherentGuardians;
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
    function getAppeal(uint256 _disputeId, uint256 _roundId)
        external
        view
        returns (address maker, uint64 appealedRuling, address taker, uint64 opposedRuling)
    {
        (, AdjudicationRound storage round) = _getDisputeAndRound(_disputeId, _roundId);
        Appeal storage appeal = round.appeal;

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
    * @return nextRoundGuardiansNumber Guardians number for the next round
    * @return newDisputeState New state for the dispute associated to the given round after the appeal
    * @return feeToken ERC20 token used for the next round fees
    * @return guardianFees Total amount of fees to be distributed between the winning guardians of the next round
    * @return totalFees Total amount of fees for a regular round at the given term
    * @return appealDeposit Amount to be deposit of fees for a regular round at the given term
    * @return confirmAppealDeposit Total amount of fees for a regular round at the given term
    */
    function getNextRoundDetails(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 nextRoundStartTerm,
            uint64 nextRoundGuardiansNumber,
            DisputeState newDisputeState,
            IERC20 feeToken,
            uint256 totalFees,
            uint256 guardianFees,
            uint256 appealDeposit,
            uint256 confirmAppealDeposit
        )
    {
        (, AdjudicationRound storage round, Config memory config) = _getDisputeAndRoundWithConfig(_disputeId, _roundId);
        require(_isRegularRound(_roundId, config), ERROR_ROUND_IS_FINAL);

        NextRoundDetails memory nextRound = _getNextRoundDetails(round, _roundId, config);
        return (
            nextRound.startTerm,
            nextRound.guardiansNumber,
            nextRound.newDisputeState,
            nextRound.feeToken,
            nextRound.totalFees,
            nextRound.guardianFees,
            nextRound.appealDeposit,
            nextRound.confirmAppealDeposit
        );
    }

    /**
    * @dev Tell guardian-related information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @param _guardian Address of the guardian being queried
    * @return weight Guardian weight drafted for the requested round
    * @return rewarded Whether or not the given guardian was rewarded based on the requested round
    */
    function getGuardian(uint256 _disputeId, uint256 _roundId, address _guardian)
        external
        view
        returns (uint64 weight, bool rewarded)
    {
        (, AdjudicationRound storage round, Config memory config) = _getDisputeAndRoundWithConfig(_disputeId, _roundId);

        if (_isRegularRound(_roundId, config)) {
            weight = _getGuardianWeight(round, _guardian);
        } else {
            IGuardiansRegistry guardiansRegistry = _guardiansRegistry();
            uint256 activeBalance = guardiansRegistry.activeBalanceOfAt(_guardian, round.draftTermId);
            weight = _getMinActiveBalanceMultiple(activeBalance, config.minActiveBalance);
        }

        rewarded = round.guardiansStates[_guardian].rewarded;
    }

    /**
    * @dev Internal function to create a new round for a given dispute
    * @param _disputeId Identification number of the dispute to create a new round for
    * @param _disputeState New state for the dispute to be changed
    * @param _draftTermId Term ID when the guardians for the new round will be drafted
    * @param _guardiansNumber Number of guardians to be drafted for the new round
    * @param _guardianFees Total amount of fees to be shared between the winning guardians of the new round
    * @return Identification number of the new dispute round
    */
    function _createRound(
        uint256 _disputeId,
        DisputeState _disputeState,
        uint64 _draftTermId,
        uint64 _guardiansNumber,
        uint256 _guardianFees
    )
        internal
        returns (uint256)
    {
        // Update dispute state
        Dispute storage dispute = disputes[_disputeId];
        dispute.state = _disputeState;

        // Create new requested round
        uint256 roundId = dispute.rounds.length++;
        AdjudicationRound storage round = dispute.rounds[roundId];
        round.draftTermId = _draftTermId;
        round.guardiansNumber = _guardiansNumber;
        round.guardianFees = _guardianFees;

        // Create new vote for the new round
        ICRVoting voting = _voting();
        uint256 voteId = _getVoteId(_disputeId, roundId);
        voting.createVote(voteId, dispute.possibleRulings);
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
    * @dev Internal function to slash all the guardians drafted for a round that didn't vote in favor of the final ruling of a dispute. Note that
    *      the slashing can be batched handling the maximum number of guardians to be slashed on each call.
    * @param _round Round to slash the non-winning guardians of
    * @param _voteId Identification number of the voting associated to the given round
    * @param _finalRuling Winning ruling of the dispute corresponding to the given round
    * @param _penaltyPct Per ten thousand of the minimum active balance of a guardian to be slashed
    * @param _guardiansToSettle Maximum number of guardians to be slashed in this call. It can be set to zero to slash all the losing guardians of the round.
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    * @return Number of guardians slashed for the given round
    */
    function _settleRegularRoundPenalties(
        AdjudicationRound storage _round,
        uint256 _voteId,
        uint8 _finalRuling,
        uint16 _penaltyPct,
        uint256 _guardiansToSettle,
        uint256 _minActiveBalance
    )
        internal
        returns (uint256)
    {
        uint64 termId = _ensureCurrentTerm();
        // The batch starts where the previous one ended, stored in _round.settledGuardians
        uint256 roundSettledGuardians = _round.settledGuardians;
        // Compute the amount of guardians that are going to be settled in this batch, which is returned by the function for fees calculation
        // Initially we try to reach the end of the guardians array
        uint256 batchSettledGuardians = _round.guardians.length.sub(roundSettledGuardians);

        // If the requested amount of guardians is not zero and it is lower that the remaining number of guardians to be settled for the given round,
        // we cap the number of guardians that are going to be settled in this batch to the requested amount. If not, we know we have reached the
        // last batch and we are safe to mark round penalties as settled.
        if (_guardiansToSettle > 0 && batchSettledGuardians > _guardiansToSettle) {
            batchSettledGuardians = _guardiansToSettle;
        } else {
            _round.settledPenalties = true;
        }

        // Update the number of round settled guardians.
        _round.settledGuardians = uint64(roundSettledGuardians.add(batchSettledGuardians));

        // Prepare the list of guardians and penalties to either be slashed or returned based on their votes for the given round
        IGuardiansRegistry guardiansRegistry = _guardiansRegistry();
        address[] memory guardians = new address[](batchSettledGuardians);
        uint256[] memory penalties = new uint256[](batchSettledGuardians);
        for (uint256 i = 0; i < batchSettledGuardians; i++) {
            address guardian = _round.guardians[roundSettledGuardians + i];
            guardians[i] = guardian;
            penalties[i] = _minActiveBalance.pct(_penaltyPct).mul(_round.guardiansStates[guardian].weight);
        }

        // Check which of the guardians voted in favor of the final ruling of the dispute in this round. Ask the registry to slash or unlocked the
        // locked active tokens of each guardian depending on their vote, and finally store the total amount of slashed tokens.
        bool[] memory guardiansInFavor = _voting().getVotersInFavorOf(_voteId, _finalRuling, guardians);
        _round.collectedTokens = _round.collectedTokens.add(guardiansRegistry.slashOrUnlock(termId, guardians, penalties, guardiansInFavor));
        return batchSettledGuardians;
    }

    /**
    * @dev Internal function to compute the guardian weight for a dispute's round
    * @param _dispute Dispute to calculate the guardian's weight of
    * @param _roundId ID of the dispute's round to calculate the guardian's weight of
    * @param _guardian Address of the guardian to calculate the weight of
    * @param _config Config at the draft term ID of the given dispute
    * @return Computed weight of the requested guardian for the final round of the given dispute
    */
    function _computeGuardianWeight(
        Dispute storage _dispute,
        uint256 _roundId,
        address _guardian,
        Config memory _config
    )
        internal
        returns (uint64)
    {
        AdjudicationRound storage round = _dispute.rounds[_roundId];

        return _isRegularRound(_roundId, _config)
            ? _getGuardianWeight(round, _guardian)
            : _computeGuardianWeightForFinalRound(_config, round, _guardian);
    }

    /**
    * @dev Internal function to compute the guardian weight for the final round. Note that for a final round the weight of
    *      each guardian is equal to the number of times the min active balance the guardian has. This function will try to
    *      collect said amount from the active balance of a guardian, acting as a lock to allow them to vote.
    * @param _config Court config to calculate the guardian's weight
    * @param _round Dispute round to calculate the guardian's weight for
    * @param _guardian Address of the guardian to calculate the weight of
    * @return Weight of the requested guardian for the final round of the given dispute
    */
    function _computeGuardianWeightForFinalRound(Config memory _config, AdjudicationRound storage _round, address _guardian) internal
        returns (uint64)
    {
        // Fetch active balance and multiples of the min active balance from the registry
        IGuardiansRegistry guardiansRegistry = _guardiansRegistry();
        uint256 activeBalance = guardiansRegistry.activeBalanceOfAt(_guardian, _round.draftTermId);
        uint64 weight = _getMinActiveBalanceMultiple(activeBalance, _config.minActiveBalance);

        // If the guardian weight for the last round is zero, return zero
        if (weight == 0) {
            return uint64(0);
        }

        // To guarantee scalability of the final round, since all guardians may vote, we try to collect the amount of
        // active tokens that needs to be locked for each guardian when they try to commit their vote.
        uint256 weightedPenalty = activeBalance.pct(_config.disputes.penaltyPct);

        // If it was not possible to collect the amount to be locked, return 0 to prevent guardian from voting
        if (!guardiansRegistry.collectTokens(_guardian, weightedPenalty, _getLastEnsuredTermId())) {
            return uint64(0);
        }

        // If it was possible to collect the amount of active tokens to be locked, update the final round state
        _round.guardiansStates[_guardian].weight = weight;
        _round.collectedTokens = _round.collectedTokens.add(weightedPenalty);

        return weight;
    }

    /**
    * @dev Sets the global configuration for the max number of guardians to be drafted per batch
    * @param _maxGuardiansPerDraftBatch Max number of guardians to be drafted per batch
    */
    function _setMaxGuardiansPerDraftBatch(uint64 _maxGuardiansPerDraftBatch) internal {
        require(_maxGuardiansPerDraftBatch > 0, ERROR_BAD_MAX_DRAFT_BATCH_SIZE);
        maxGuardiansPerDraftBatch = _maxGuardiansPerDraftBatch;
        emit MaxGuardiansPerDraftBatchChanged(_maxGuardiansPerDraftBatch);
    }

    /**
    * @dev Internal function to execute a deposit of tokens from an account to the Court treasury contract
    * @param _from Address transferring the amount of tokens
    * @param _token ERC20 token to execute a transfer from
    * @param _amount Amount of tokens to be transferred from the address transferring the funds to the Court treasury
    */
    function _depositAmount(address _from, IERC20 _token, uint256 _amount) internal {
        if (_amount > 0) {
            ITreasury treasury = _treasury();
            // No need to verify _token to be a contract as it's permissioned as the fee token
            require(_token.safeTransferFrom(_from, address(treasury), _amount), ERROR_DEPOSIT_FAILED);
        }
    }

    /**
    * @dev Internal function to get the stored guardian weight for a round. Note that the weight of a guardian is:
    *      - For a regular round: the number of times a guardian was picked for the round round.
    *      - For a final round: the relative active stake of a guardian's state over the total active tokens, only set after the guardian has voted.
    * @param _round Dispute round to calculate the guardian's weight of
    * @param _guardian Address of the guardian to calculate the weight of
    * @return Weight of the requested guardian for the given round
    */
    function _getGuardianWeight(AdjudicationRound storage _round, address _guardian) internal view returns (uint64) {
        return _round.guardiansStates[_guardian].weight;
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
            // The number of guardians will be the number of times the minimum stake is held in the registry,
            // multiplied by a precision factor to help with division rounding.
            // Total active balance is guaranteed to never be greater than `2^64 * minActiveBalance / FINAL_ROUND_WEIGHT_PRECISION`.
            // Thus, the guardians number for a final round will always fit in uint64.
            IGuardiansRegistry guardiansRegistry = _guardiansRegistry();
            uint256 totalActiveBalance = guardiansRegistry.totalActiveBalanceAt(nextRound.startTerm);
            uint64 guardiansNumber = _getMinActiveBalanceMultiple(totalActiveBalance, _config.minActiveBalance);
            nextRound.guardiansNumber = guardiansNumber;
            // Calculate fees for the final round using the appeal start term of the current round
            (nextRound.feeToken, nextRound.guardianFees, nextRound.totalFees) = _getFinalRoundFees(_config.fees, guardiansNumber);
        } else {
            // For a new regular rounds we need to draft guardians
            nextRound.newDisputeState = DisputeState.PreDraft;
            // The number of guardians will be the number of guardians of the current round multiplied by an appeal factor
            nextRound.guardiansNumber = _getNextRegularRoundGuardiansNumber(_round, disputesConfig);
            // Calculate fees for the next regular round using the appeal start term of the current round
            (nextRound.feeToken, nextRound.guardianFees, nextRound.totalFees) = _getRegularRoundFees(_config.fees, nextRound.guardiansNumber);
        }

        // Calculate appeal collateral
        nextRound.appealDeposit = nextRound.totalFees.pct256(disputesConfig.appealCollateralFactor);
        nextRound.confirmAppealDeposit = nextRound.totalFees.pct256(disputesConfig.appealConfirmCollateralFactor);
        return nextRound;
    }

    /**
    * @dev Internal function to calculate the guardians number for the next regular round of a given round. This function assumes Court term is
    *      up-to-date, that the next round of the one given is regular, and the given config corresponds to the draft term of the given round.
    * @param _round Round querying the guardians number of its next round
    * @param _config Disputes config at the draft term of the first round of the dispute
    * @return Guardians number for the next regular round of the given round
    */
    function _getNextRegularRoundGuardiansNumber(AdjudicationRound storage _round, DisputesConfig memory _config)
        internal
        view
        returns (uint64)
    {
        // Guardians number are increased by a step factor on each appeal
        uint64 guardiansNumber = _round.guardiansNumber.mul(_config.appealStepFactor);
        // Make sure it's odd to enforce avoiding a tie. Note that it can happen if any of the guardians don't vote anyway.
        if (uint256(guardiansNumber) % 2 == 0) {
            guardiansNumber++;
        }
        return guardiansNumber;
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

        // If given term is before the reveal start term of the last round, then guardians are still allowed to commit votes for the last round
        uint64 revealStartTerm = draftFinishedTermId.add(_config.commitTerms);
        if (_termId < revealStartTerm) {
            return AdjudicationState.Committing;
        }

        // If given term is before the appeal start term of the last round, then guardians are still allowed to reveal votes for the last round
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
    * @dev Internal function to check if a certain dispute round exists, it reverts if it doesn't
    * @param _dispute Dispute to be checked
    * @param _roundId Identification number of the dispute round to be checked
    */
    function _checkRoundExists(Dispute storage _dispute, uint256 _roundId) internal view {
        require(_roundId < _dispute.rounds.length, ERROR_ROUND_DOES_NOT_EXIST);
    }

    /**
    * @dev Internal function to fetch a dispute
    * @param _disputeId Identification number of the dispute to be fetched
    * @return Dispute instance requested
    */
    function _getDispute(uint256 _disputeId) internal view returns (Dispute storage) {
        require(_disputeId < disputes.length, ERROR_DISPUTE_DOES_NOT_EXIST);
        return disputes[_disputeId];
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
    * @dev Internal function to fetch a dispute and round
    * @param _disputeId Identification number of the dispute to be fetched
    * @param _roundId Identification number of the round to be fetched
    * @return dispute Dispute instance requested
    * @return round Round instance requested
    */
    function _getDisputeAndRound(uint256 _disputeId, uint256 _roundId)
        internal
        view
        returns (Dispute storage dispute, AdjudicationRound storage round)
    {
        dispute = _getDispute(_disputeId);
        _checkRoundExists(dispute, _roundId);
        round = dispute.rounds[_roundId];
    }

    /**
    * @dev Internal function to fetch a dispute with its config
    * @param _disputeId Identification number of the dispute to be fetched
    * @return dispute Dispute instance requested
    * @return config Court config used for the given dispute
    */
    function _getDisputeWithConfig(uint256 _disputeId)
        internal
        view
        returns (Dispute storage dispute, Config memory config)
    {
        dispute = _getDispute(_disputeId);
        config = _getDisputeConfig(dispute);
    }

    /**
    * @dev Internal function to fetch a dispute and round with its config
    * @param _disputeId Identification number of the dispute to be fetched
    * @param _roundId Identification number of the round to be fetched
    * @return dispute Dispute instance requested
    * @return round Round instance requested
    * @return config Court config used for the given dispute
    */
    function _getDisputeAndRoundWithConfig(uint256 _disputeId, uint256 _roundId)
        internal
        view
        returns (Dispute storage dispute, AdjudicationRound storage round, Config memory config)
    {
        (dispute, round) = _getDisputeAndRound(_disputeId, _roundId);
        config = _getDisputeConfig(dispute);
    }

    /**
    * @dev Internal function to get the dispute round of a certain vote identification number
    * @param _voteId Identification number of the vote querying the dispute round of
    * @return dispute Dispute for the given vote
    * @return roundId Identification number of the dispute round for the given vote
    * @return config Court config used for the given dispute
    */
    function _decodeVoteId(uint256 _voteId)
        internal
        view
        returns (Dispute storage dispute, uint256 roundId, Config memory config)
    {
        uint256 disputeId = _voteId >> 128;
        roundId = _voteId & VOTE_ID_MASK;
        dispute = _getDispute(disputeId);
        _checkRoundExists(dispute, roundId);
        config = _getDisputeConfig(dispute);
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
    * @dev Assumes round.coherentGuardians is greater than zero
    * @param _round Round which the weighted amount is computed for
    * @param _guardianState Guardian with state which the weighted amount is computed for
    * @param _amount Amount to be weighted
    * @return Weighted amount for a guardian in a round in relation to total amount of coherent guardians
    */
    function _getRoundWeightedAmount(
        AdjudicationRound storage _round,
        GuardianState storage _guardianState,
        uint256 _amount
    )
        internal
        view
        returns (uint256)
    {
        return _amount.mul(_guardianState.weight) / _round.coherentGuardians;
    }

    /**
    * @dev Internal function to get fees information for regular rounds for a certain term. This function assumes Court term is up-to-date.
    * @param _config Court config to use in order to get fees
    * @param _guardiansNumber Number of guardians participating in the round being queried
    * @return feeToken ERC20 token used for the fees
    * @return guardianFees Total amount of fees to be distributed between the winning guardians of a round
    * @return totalFees Total amount of fees for a regular round at the given term
    */
    function _getRegularRoundFees(FeesConfig memory _config, uint64 _guardiansNumber) internal pure
        returns (IERC20 feeToken, uint256 guardianFees, uint256 totalFees)
    {
        feeToken = _config.token;
        // For regular rounds the fees for each guardian is constant and given by the config of the round
        guardianFees = uint256(_guardiansNumber).mul(_config.guardianFee);
        // The total fees for regular rounds also considers the number of drafts and settles
        uint256 draftAndSettleFees = (_config.draftFee.add(_config.settleFee)).mul(uint256(_guardiansNumber));
        totalFees = guardianFees.add(draftAndSettleFees);
    }

    /**
    * @dev Internal function to get fees information for final rounds for a certain term. This function assumes Court term is up-to-date.
    * @param _config Court config to use in order to get fees
    * @param _guardiansNumber Number of guardians participating in the round being queried
    * @return feeToken ERC20 token used for the fees
    * @return guardianFees Total amount of fees corresponding to the guardians at the given term
    * @return totalFees Total amount of fees for a final round at the given term
    */
    function _getFinalRoundFees(FeesConfig memory _config, uint64 _guardiansNumber) internal pure
        returns (IERC20 feeToken, uint256 guardianFees, uint256 totalFees)
    {
        feeToken = _config.token;
        // For final rounds, the guardians number is computed as the number of times the registry's minimum active balance is held in the registry
        // itself, multiplied by a precision factor. To avoid requesting a huge amount of fees, a final round discount is applied for each guardian.
        guardianFees = (uint256(_guardiansNumber).mul(_config.guardianFee) / FINAL_ROUND_WEIGHT_PRECISION).pct(_config.finalRoundReduction);
        // There is no draft and no extra settle fees considered for final rounds
        totalFees = guardianFees;
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
    *      Used to get the guardian weight for the final round. Note that for the final round the weight of
    *      each guardian is equal to the number of times the min active balance the guardian has, multiplied by a precision
    *      factor to deal with division rounding.
    * @param _activeBalance Guardian's or total active balance
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    * @return Number of times that the active balance contains the min active balance (multiplied by precision)
    */
    function _getMinActiveBalanceMultiple(uint256 _activeBalance, uint256 _minActiveBalance) internal pure returns (uint64) {
        // Note that guardians may not reach the minimum active balance since some might have been slashed. If that occurs,
        // these guardians cannot vote in the final round.
        if (_activeBalance < _minActiveBalance) {
            return 0;
        }

        // Otherwise, return the times the active balance of the guardian fits in the min active balance, multiplying
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
    * @dev Private function to draft guardians for a given dispute and round. It assumes the given data is correct.
    * @param _round Round of the dispute to be drafted
    * @param _draftParams Draft params to be used for the draft
    * @return True if all the requested guardians for the given round were drafted, false otherwise
    */
    function _draft(AdjudicationRound storage _round, DraftParams memory _draftParams) private returns (bool) {
        uint64 guardiansNumber = _round.guardiansNumber;
        uint64 selectedGuardians = _round.selectedGuardians;
        uint64 maxGuardiansPerBatch = maxGuardiansPerDraftBatch;
        uint64 guardiansToBeDrafted = guardiansNumber.sub(selectedGuardians);
        // Draft the min number of guardians between the one requested by the sender and the one requested by the sender
        uint64 requestedGuardians = guardiansToBeDrafted < maxGuardiansPerBatch ? guardiansToBeDrafted : maxGuardiansPerBatch;

        // Pack draft params
        uint256[7] memory params = [
            uint256(_draftParams.draftTermRandomness),
            _draftParams.disputeId,
            uint256(_draftParams.termId),
            uint256(selectedGuardians),
            uint256(requestedGuardians),
            uint256(guardiansNumber),
            uint256(_draftParams.config.penaltyPct)
        ];

        // Draft guardians for the requested round
        IGuardiansRegistry guardiansRegistry = _guardiansRegistry();
        (address[] memory guardians, uint256 draftedGuardians) = guardiansRegistry.draft(params);

        // Update round with drafted guardians information
        uint64 newSelectedGuardians = selectedGuardians.add(uint64(draftedGuardians));
        _round.selectedGuardians = newSelectedGuardians;
        _updateRoundDraftedGuardians(_draftParams.disputeId, _draftParams.roundId, _round, guardians, draftedGuardians);
        bool draftEnded = newSelectedGuardians == guardiansNumber;

        // Transfer fees corresponding to the actual number of drafted guardians
        uint256 draftFees = _draftParams.config.draftFee.mul(draftedGuardians);
        _treasury().assign(_draftParams.config.feeToken, msg.sender, draftFees);
        return draftEnded;
    }

    /**
    * @dev Private function to update the drafted guardians' weight for the given round
    * @param _disputeId Identification number of the dispute being drafted
    * @param _roundId Identification number of the round being drafted
    * @param _round Adjudication round that was drafted
    * @param _guardians List of guardians addresses that were drafted for the given round
    * @param _draftedGuardians Number of guardians that were drafted for the given round. Note that this number may not necessarily be equal to the
    *        given list of guardians since the draft could potentially return less guardians than the requested amount.
    */
    function _updateRoundDraftedGuardians(
        uint256 _disputeId,
        uint256 _roundId,
        AdjudicationRound storage _round,
        address[] memory _guardians,
        uint256 _draftedGuardians
    )
        private
    {
        for (uint256 i = 0; i < _draftedGuardians; i++) {
            address guardian = _guardians[i];
            GuardianState storage guardianState = _round.guardiansStates[guardian];

            // If the guardian was already registered in the list, then don't add it twice
            if (uint256(guardianState.weight) == 0) {
                _round.guardians.push(guardian);
            }

            guardianState.weight = guardianState.weight.add(1);
            emit GuardianDrafted(_disputeId, _roundId, guardian);
        }
    }

    /**
    * @dev Private function to burn the collected for a certain round in case there were no coherent guardians
    * @param _dispute Dispute to settle penalties for
    * @param _round Dispute round to settle penalties for
    * @param _roundId Identification number of the dispute round to settle penalties for
    * @param _courtTreasury Treasury module to refund the corresponding guardian fees
    * @param _feeToken ERC20 token to be used for the fees corresponding to the draft term of the given dispute round
    * @param _collectedTokens Amount of tokens collected during the given dispute round
    */
    function _burnCollectedTokensIfNecessary(
        Dispute storage _dispute,
        AdjudicationRound storage _round,
        uint256 _roundId,
        ITreasury _courtTreasury,
        IERC20 _feeToken,
        uint256 _collectedTokens
    )
        private
    {
        // If there was at least one guardian voting in favor of the winning ruling, return
        if (_round.coherentGuardians > 0) {
            return;
        }

        // Burn all the collected tokens of the guardians to be slashed. Note that this will happen only when there were no guardians voting
        // in favor of the final winning outcome. Otherwise, these will be re-distributed between the winning guardians in `settleReward`
        // instead of being burned.
        if (_collectedTokens > 0) {
            IGuardiansRegistry guardiansRegistry = _guardiansRegistry();
            guardiansRegistry.burnTokens(_collectedTokens);
        }

        // Reimburse guardian fees to the Arbtirable subject for round 0 or to the previous appeal parties for other rounds.
        // Note that if the given round is not the first round, we can ensure there was an appeal in the previous round.
        if (_roundId == 0) {
            _courtTreasury.assign(_feeToken, address(_dispute.subject), _round.guardianFees);
        } else {
            uint256 refundFees = _round.guardianFees / 2;
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