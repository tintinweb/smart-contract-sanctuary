// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { TransferHelper } from "./libraries/TransferHelper.sol";

import { FinderInterface } from "./interfaces/FinderInterface.sol";
import { IConditionalTokens } from "./interfaces/IConditionalTokens.sol";
import { OptimisticOracleInterface } from "./interfaces/OptimisticOracleInterface.sol";
import { AddressWhitelistInterface } from "./interfaces/AddressWhitelistInterface.sol";

/// @title UmaConditionalTokensBinaryAdapter
/// @notice Enables Conditional Token resolution via UMA's Optimistic Oracle
contract UmaConditionalTokensBinaryAdapter is ReentrancyGuard {
    /// @notice Auth
    mapping(address => uint256) public wards;

    /// @notice Authorizes a user
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit AuthorizedUser(usr);
    }

    /// @notice Deauthorizes a user
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit DeauthorizedUser(usr);
    }

    event AuthorizedUser(address indexed usr);
    event DeauthorizedUser(address indexed usr);

    /// @notice - Authorization modifier
    modifier auth() {
        require(wards[msg.sender] == 1, "Adapter/not-authorized");
        _;
    }

    /// @notice Conditional Tokens
    IConditionalTokens public immutable conditionalTokenContract;

    /// @notice UMA Finder address
    address public umaFinder;

    /// @notice Unique query identifier for the Optimistic Oracle
    bytes32 public constant identifier = "YES_OR_NO_QUERY";

    /// @notice Time period after which an authorized user can emergency resolve a condition
    uint256 public constant emergencySafetyPeriod = 2 days;

    struct QuestionData {
        // Unix timestamp(in seconds) at which a market can be resolved
        uint256 resolutionTime;
        // Reward offered to a successful proposer
        uint256 reward;
        // Additional bond required by Optimistic oracle proposers and disputers
        uint256 proposalBond;
        // Flag marking the block number when a question was settled
        uint256 settled;
        // Request timestmap, set when a request is made to the Optimistic Oracle
        uint256 requestTimestamp;
        // Admin Resolution timestamp, set when a market is flagged for admin resolution
        uint256 adminResolutionTimestamp;
        // Flag marking whether a question can be resolved early
        bool earlyResolutionEnabled;
        // Flag marking whether a question is resolved
        bool resolved;
        // Flag marking whether a question is paused
        bool paused;
        // ERC20 token address used for payment of rewards, proposal bonds and fees
        address rewardToken;
        // Data used to resolve a condition
        bytes ancillaryData;
    }

    /// @notice Mapping of questionID to QuestionData
    mapping(bytes32 => QuestionData) public questions;

    /*
    ////////////////////////////////////////////////////////////////////
                            EVENTS 
    ////////////////////////////////////////////////////////////////////
    */

    /// @notice Emitted when the UMA Finder is changed
    event NewFinderAddress(address oldFinder, address newFinder);

    /// @notice Emitted when a questionID is initialized
    event QuestionInitialized(
        bytes32 indexed questionID,
        bytes ancillaryData,
        uint256 resolutionTime,
        address rewardToken,
        uint256 reward,
        uint256 proposalBond,
        bool earlyResolutionEnabled
    );

    /// @notice Emitted when a questionID is updated
    event QuestionUpdated(
        bytes32 indexed questionID,
        bytes ancillaryData,
        uint256 resolutionTime,
        address rewardToken,
        uint256 reward,
        uint256 proposalBond,
        bool earlyResolutionEnabled
    );

    /// @notice Emitted when a question is paused by an authorized user
    event QuestionPaused(bytes32 questionID);

    /// @notice Emitted when a question is unpaused by an authorized user
    event QuestionUnpaused(bytes32 questionID);

    /// @notice Emitted when a question is flagged by an admin for emergency resolution
    event QuestionFlaggedForAdminResolution(bytes32 questionID);

    /// @notice Emitted when resolution data is requested from the Optimistic Oracle
    event ResolutionDataRequested(
        address indexed requestor,
        uint256 indexed requestTimestamp,
        bytes32 indexed questionID,
        bytes32 identifier,
        bytes ancillaryData,
        address rewardToken,
        uint256 reward,
        uint256 proposalBond,
        bool earlyResolution
    );

    /// @notice Emitted when a question is reset
    event QuestionReset(bytes32 indexed questionID);

    /// @notice Emitted when a question is settled
    event QuestionSettled(bytes32 indexed questionID, int256 indexed settledPrice, bool indexed earlyResolution);

    /// @notice Emitted when a question is resolved
    event QuestionResolved(bytes32 indexed questionID, bool indexed emergencyReport);

    constructor(address conditionalTokenAddress, address umaFinderAddress) {
        wards[msg.sender] = 1;
        emit AuthorizedUser(msg.sender);
        conditionalTokenContract = IConditionalTokens(conditionalTokenAddress);
        umaFinder = umaFinderAddress;
    }

    /*
    ////////////////////////////////////////////////////////////////////
                            PUBLIC 
    ////////////////////////////////////////////////////////////////////
    */

    /// @notice Initializes a question on the Adapter to report on
    /// @param questionID               - The unique questionID of the question
    /// @param ancillaryData            - Data used to resolve a question
    /// @param resolutionTime           - Timestamp after which the Adapter can resolve a question
    /// @param rewardToken              - ERC20 token address used for payment of rewards and fees
    /// @param reward                   - Reward offered to a successful proposer
    /// @param proposalBond             - Bond required to be posted by a price proposer and disputer
    /// @param earlyResolutionEnabled   - Determines whether a question can be resolved early
    function initializeQuestion(
        bytes32 questionID,
        bytes memory ancillaryData,
        uint256 resolutionTime,
        address rewardToken,
        uint256 reward,
        uint256 proposalBond,
        bool earlyResolutionEnabled
    ) public {
        require(!isQuestionInitialized(questionID), "Adapter::initializeQuestion: Question already initialized");
        require(resolutionTime > 0, "Adapter::initializeQuestion: resolutionTime must be positive");
        require(supportedToken(rewardToken), "Adapter::unsupported reward token");

        questions[questionID] = QuestionData({
            ancillaryData: ancillaryData,
            resolutionTime: resolutionTime,
            rewardToken: rewardToken,
            reward: reward,
            proposalBond: proposalBond,
            earlyResolutionEnabled: earlyResolutionEnabled,
            resolved: false,
            paused: false,
            settled: 0,
            requestTimestamp: 0,
            adminResolutionTimestamp: 0
        });

        emit QuestionInitialized(
            questionID,
            ancillaryData,
            resolutionTime,
            rewardToken,
            reward,
            proposalBond,
            earlyResolutionEnabled
        );
    }

    /// @notice Checks whether or not a question can start the resolution process
    /// @param questionID - The unique questionID of the question
    function readyToRequestResolution(bytes32 questionID) public view returns (bool) {
        // Ensure question has been initialized
        if (!isQuestionInitialized(questionID)) {
            return false;
        }
        QuestionData storage questionData = questions[questionID];

        // Ensure resolution data has not already been requested for the question
        if (resolutionDataRequested(questionData)) {
            return false;
        }

        // Ensure the question is not already resolved
        if (questionData.resolved) {
            return false;
        }

        // If early resolution is enabled, do not restrict resolution to after resolution time
        if (questionData.earlyResolutionEnabled) {
            return true;
        }
        // Ensure that current time is after resolution time
        return block.timestamp > questionData.resolutionTime;
    }

    /// @notice Request resolution data from the Optimistic Oracle
    /// @param questionID - The unique questionID of the question
    function requestResolutionData(bytes32 questionID) public nonReentrant {
        require(
            readyToRequestResolution(questionID),
            "Adapter::requestResolutionData: Question not ready to be resolved"
        );
        QuestionData storage questionData = questions[questionID];
        require(!questionData.paused, "Adapter::requestResolutionData: Question is paused");

        _requestResolution(questionID, questionData);
    }

    /// @notice Requests data from the Optimistic Oracle
    /// @param questionID   - The unique questionID of the question
    /// @param questionData - The questionData of the question
    function _requestResolution(bytes32 questionID, QuestionData storage questionData) internal {
        // Update request timestamp
        questionData.requestTimestamp = block.timestamp;

        // Request a price
        _requestPrice(
            msg.sender,
            identifier,
            questionData.requestTimestamp,
            questionData.ancillaryData,
            questionData.rewardToken,
            questionData.reward,
            questionData.proposalBond
        );

        emit ResolutionDataRequested(
            msg.sender,
            questionData.requestTimestamp,
            questionID,
            identifier,
            questionData.ancillaryData,
            questionData.rewardToken,
            questionData.reward,
            questionData.proposalBond,
            questionData.earlyResolutionEnabled && questionData.requestTimestamp < questionData.resolutionTime
        );
    }

    /// @notice Request a price from the Optimistic Oracle
    /// @dev Transfers reward token from the requestor if non-zero reward is specified
    function _requestPrice(
        address requestor,
        bytes32 priceIdentifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        address rewardToken,
        uint256 reward,
        uint256 bond
    ) internal {
        // Fetch the optimistic oracle
        OptimisticOracleInterface optimisticOracle = getOptimisticOracle();

        // If non-zero reward, pay for the price request by transferring rewardToken from the requestor
        if (reward > 0) {
            TransferHelper.safeTransferFrom(rewardToken, requestor, address(this), reward);

            // Approve the OO to transfer the reward token from the Adapter
            if (IERC20(rewardToken).allowance(address(this), address(optimisticOracle)) < type(uint256).max) {
                TransferHelper.safeApprove(rewardToken, address(optimisticOracle), type(uint256).max);
            }
        }

        // Send a price request to the Optimistic oracle
        optimisticOracle.requestPrice(priceIdentifier, timestamp, ancillaryData, IERC20(rewardToken), reward);

        // Update the proposal bond on the Optimistic oracle if necessary
        if (bond > 0) {
            optimisticOracle.setBond(priceIdentifier, timestamp, ancillaryData, bond);
        }
    }

    /// @notice Checks whether a questionID is ready to be settled
    /// @param questionID - The unique questionID of the question
    function readyToSettle(bytes32 questionID) public view returns (bool) {
        if (!isQuestionInitialized(questionID)) {
            return false;
        }
        QuestionData storage questionData = questions[questionID];
        // Ensure resolution data has been requested for question
        if (resolutionDataRequested(questionData) == false) {
            return false;
        }
        // Ensure question has not been resolved
        if (questionData.resolved == true) {
            return false;
        }
        // Ensure question has not been settled
        if (questionData.settled != 0) {
            return false;
        }

        OptimisticOracleInterface optimisticOracle = getOptimisticOracle();

        return
            optimisticOracle.hasPrice(
                address(this),
                identifier,
                questionData.requestTimestamp,
                questionData.ancillaryData
            );
    }

    /// @notice Settle/finalize the resolution data of a question
    /// @notice If the OO returns the ignore price, this method resets the question, allowing new price requests
    /// @param questionID - The unique questionID of the question
    function settle(bytes32 questionID) public {
        require(readyToSettle(questionID), "Adapter::settle: questionID is not ready to be settled");
        QuestionData storage questionData = questions[questionID];
        require(!questionData.paused, "Adapter::settle: Question is paused");

        return _settle(questionID, questionData);
    }

    function _settle(bytes32 questionID, QuestionData storage questionData) internal {
        OptimisticOracleInterface optimisticOracle = getOptimisticOracle();

        int256 proposedPrice = optimisticOracle
            .getRequest(address(this), identifier, questionData.requestTimestamp, questionData.ancillaryData)
            .proposedPrice;

        // NOTE: If the proposed price is the ignore price, reset the question, allowing new resolution requests
        if (proposedPrice == ignorePrice()) {
            _resetQuestion(questionID, questionData, optimisticOracle);
            return;
        }

        // Set the settled block number
        questionData.settled = block.number;

        // Settle the price
        int256 settledPrice = optimisticOracle.settleAndGetPrice(
            identifier,
            questionData.requestTimestamp,
            questionData.ancillaryData
        );
        emit QuestionSettled(questionID, settledPrice, questionData.requestTimestamp < questionData.resolutionTime);
    }

    function _resetQuestion(
        bytes32 questionID,
        QuestionData storage questionData,
        OptimisticOracleInterface optimisticOracle
    ) internal {
        optimisticOracle.settleAndGetPrice(identifier, questionData.requestTimestamp, questionData.ancillaryData);
        questionData.requestTimestamp = 0;
        emit QuestionReset(questionID);
    }

    /// @notice Retrieves the expected payout of a settled question
    /// @param questionID - The unique questionID of the question
    function getExpectedPayouts(bytes32 questionID) public view returns (uint256[] memory) {
        require(isQuestionInitialized(questionID), "Adapter::getExpectedPayouts: questionID is not initialized");
        QuestionData storage questionData = questions[questionID];

        require(
            resolutionDataRequested(questionData),
            "Adapter::getExpectedPayouts: resolutionData has not been requested"
        );
        require(!questionData.resolved, "Adapter::getExpectedPayouts: questionID is already resolved");
        require(questionData.settled > 0, "Adapter::getExpectedPayouts: questionID is not settled");
        require(!questionData.paused, "Adapter::getExpectedPayouts: Question is paused");

        // Fetches resolution data from OO
        int256 resolutionData = getExpectedResolutionData(questionData);

        // Payouts: [YES, NO]
        uint256[] memory payouts = new uint256[](2);

        // Valid prices are 0, 0.5 and 1
        require(
            resolutionData == 0 || resolutionData == 0.5 ether || resolutionData == 1 ether,
            "Adapter::reportPayouts: Invalid resolution data"
        );

        if (resolutionData == 0) {
            // NO: Report [Yes, No] as [0, 1]
            payouts[0] = 0;
            payouts[1] = 1;
        } else if (resolutionData == 0.5 ether) {
            // UNKNOWN: Report [Yes, No] as [1, 1], 50/50
            payouts[0] = 1;
            payouts[1] = 1;
        } else {
            // YES: Report [Yes, No] as [1, 0]
            payouts[0] = 1;
            payouts[1] = 0;
        }
        return payouts;
    }

    function getExpectedResolutionData(QuestionData storage questionData) internal view returns (int256) {
        return
            getOptimisticOracle()
                .getRequest(address(this), identifier, questionData.requestTimestamp, questionData.ancillaryData)
                .resolvedPrice;
    }

    /// @notice Resolves a question
    /// @param questionID - The unique questionID of the question
    function reportPayouts(bytes32 questionID) public {
        QuestionData storage questionData = questions[questionID];

        // Payouts: [YES, NO]
        // getExpectedPayouts verifies that questionID is settled and can be resolved
        uint256[] memory payouts = getExpectedPayouts(questionID);

        require(
            block.number > questionData.settled,
            "Adapter::reportPayouts: Attempting to settle and reportPayouts in the same block"
        );

        questionData.resolved = true;
        conditionalTokenContract.reportPayouts(questionID, payouts);
        emit QuestionResolved(questionID, false);
    }

    /*
    ////////////////////////////////////////////////////////////////////
                            AUTHORIZED ONLY FUNCTIONS 
    ////////////////////////////////////////////////////////////////////
    */

    /// @notice Allows an authorized user to update a question
    /// @param questionID             - The unique questionID of the question
    /// @param ancillaryData          - Data used to resolve a question
    /// @param resolutionTime         - Timestamp after which the Adapter can resolve a question
    /// @param rewardToken            - ERC20 token address used for payment of rewards and fees
    /// @param reward                 - Reward offered to a successful proposer
    /// @param proposalBond           - Bond required to be posted by a price proposer and disputer
    /// @param earlyResolutionEnabled - Determines whether a question can be resolved early
    function updateQuestion(
        bytes32 questionID,
        bytes memory ancillaryData,
        uint256 resolutionTime,
        address rewardToken,
        uint256 reward,
        uint256 proposalBond,
        bool earlyResolutionEnabled
    ) external auth {
        require(isQuestionInitialized(questionID), "Adapter::updateQuestion: Question not initialized");
        require(resolutionTime > 0, "Adapter::updateQuestion: resolutionTime must be positive");
        require(supportedToken(rewardToken), "Adapter::unsupported reward token");
        require(questions[questionID].settled == 0, "Adapter::updateQuestion: Question is already settled");

        questions[questionID] = QuestionData({
            ancillaryData: ancillaryData,
            resolutionTime: resolutionTime,
            rewardToken: rewardToken,
            reward: reward,
            proposalBond: proposalBond,
            earlyResolutionEnabled: earlyResolutionEnabled,
            resolved: false,
            paused: false,
            settled: 0,
            requestTimestamp: 0,
            adminResolutionTimestamp: 0
        });

        emit QuestionUpdated(
            questionID,
            ancillaryData,
            resolutionTime,
            rewardToken,
            reward,
            proposalBond,
            earlyResolutionEnabled
        );
    }

    /// @notice Flags a market for emergency resolution in an emergency
    /// @param questionID - The unique questionID of the question
    function flagQuestionForEmergencyResolution(bytes32 questionID) external auth {
        require(
            isQuestionInitialized(questionID),
            "Adapter::flagQuestionForEarlyResolution: questionID is not initialized"
        );

        require(
            !isQuestionFlaggedForEmergencyResolution(questionID),
            "Adapter::emergencyReportPayouts: questionID is already flagged for emergency resolution"
        );

        questions[questionID].adminResolutionTimestamp = block.timestamp + emergencySafetyPeriod;
        emit QuestionFlaggedForAdminResolution(questionID);
    }

    /// @notice Allows an authorized user to report payouts in an emergency
    /// @param questionID - The unique questionID of the question
    /// @param payouts - Array of position payouts for the referenced question
    function emergencyReportPayouts(bytes32 questionID, uint256[] calldata payouts) external auth {
        require(isQuestionInitialized(questionID), "Adapter::emergencyReportPayouts: questionID is not initialized");

        require(
            isQuestionFlaggedForEmergencyResolution(questionID),
            "Adapter::emergencyReportPayouts: questionID is not flagged for emergency resolution"
        );

        require(
            block.timestamp > questions[questionID].adminResolutionTimestamp,
            "Adapter::emergencyReportPayouts: safety period has not passed"
        );

        require(payouts.length == 2, "Adapter::emergencyReportPayouts: payouts must be binary");

        QuestionData storage questionData = questions[questionID];

        questionData.resolved = true;
        conditionalTokenContract.reportPayouts(questionID, payouts);
        emit QuestionResolved(questionID, true);
    }

    /// @notice Allows an authorized user to pause market resolution in an emergency
    /// @param questionID - The unique questionID of the question
    function pauseQuestion(bytes32 questionID) external auth {
        require(isQuestionInitialized(questionID), "Adapter::pauseQuestion: questionID is not initialized");
        QuestionData storage questionData = questions[questionID];

        questionData.paused = true;
        emit QuestionPaused(questionID);
    }

    /// @notice Allows an authorized user to unpause market resolution in an emergency
    /// @param questionID - The unique questionID of the question
    function unPauseQuestion(bytes32 questionID) external auth {
        require(isQuestionInitialized(questionID), "Adapter::unPauseQuestion: questionID is not initialized");
        QuestionData storage questionData = questions[questionID];
        questionData.paused = false;
        emit QuestionUnpaused(questionID);
    }

    /// @notice Allows an authorized user to update the UMA Finder address
    /// @param newFinderAddress - The new finder address
    function setFinderAddress(address newFinderAddress) external auth {
        emit NewFinderAddress(umaFinder, newFinderAddress);
        umaFinder = newFinderAddress;
    }

    /*
    ////////////////////////////////////////////////////////////////////
                            UTILITY FUNCTIONS 
    ////////////////////////////////////////////////////////////////////
    */

    /// @notice Utility function that atomically prepares a question on the Conditional Tokens contract
    ///         and initializes it on the Adapter
    /// @dev Prepares the condition using the Adapter as the oracle and a fixed outcomeSlotCount
    /// @param questionID               - The unique questionID of the question
    /// @param ancillaryData            - Data used to resolve a question
    /// @param resolutionTime           - Timestamp after which the Adapter can resolve a question
    /// @param rewardToken              - ERC20 token address used for payment of rewards and fees
    /// @param reward                   - Reward offered to a successful proposer
    /// @param proposalBond             - Bond required to be posted by a price proposer and disputer
    /// @param earlyResolutionEnabled   - Determines whether a question can be resolved early
    function prepareAndInitialize(
        bytes32 questionID,
        bytes memory ancillaryData,
        uint256 resolutionTime,
        address rewardToken,
        uint256 reward,
        uint256 proposalBond,
        bool earlyResolutionEnabled
    ) public {
        conditionalTokenContract.prepareCondition(address(this), questionID, 2);
        initializeQuestion(
            questionID,
            ancillaryData,
            resolutionTime,
            rewardToken,
            reward,
            proposalBond,
            earlyResolutionEnabled
        );
    }

    /// @notice Utility function that verifies if a question is initialized
    /// @param questionID - The unique questionID
    function isQuestionInitialized(bytes32 questionID) public view returns (bool) {
        return questions[questionID].resolutionTime > 0;
    }

    function isQuestionFlaggedForEmergencyResolution(bytes32 questionID) public view returns (bool) {
        return questions[questionID].adminResolutionTimestamp > 0;
    }

    // Checks if a request has been sent to the Optimistic Oracle
    function resolutionDataRequested(QuestionData storage questionData) internal view returns (bool) {
        return questionData.requestTimestamp > 0;
    }

    /// @notice Price that indicates that the OO does not have a valid price yet
    function ignorePrice() public pure returns (int256) {
        return type(int256).min;
    }

    function getOptimisticOracleAddress() internal view returns (address) {
        return FinderInterface(umaFinder).getImplementationAddress("OptimisticOracle");
    }

    function getOptimisticOracle() internal view returns (OptimisticOracleInterface) {
        return OptimisticOracleInterface(getOptimisticOracleAddress());
    }

    function getCollateralWhitelistAddress() internal view returns (address) {
        return FinderInterface(umaFinder).getImplementationAddress("CollateralWhitelist");
    }

    function supportedToken(address token) internal view returns (bool) {
        return AddressWhitelistInterface(getCollateralWhitelistAddress()).isOnWhitelist(token);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TransferHelper
/// @author Uniswap: https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "STE");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IConditionalTokens {
    /// @dev Emitted upon the successful preparation of a condition.
    /// @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    event ConditionPreparation(
        bytes32 indexed conditionId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint256 outcomeSlotCount
    );

    event ConditionResolution(
        bytes32 indexed conditionId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint256 outcomeSlotCount,
        uint256[] payoutNumerators
    );

    /// @dev Emitted when a position is successfully split.
    event PositionSplit(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 indexed conditionId,
        uint256[] partition,
        uint256 amount
    );
    /// @dev Emitted when positions are successfully merged.
    event PositionsMerge(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 indexed conditionId,
        uint256[] partition,
        uint256 amount
    );
    event PayoutRedemption(
        address indexed redeemer,
        IERC20 indexed collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 conditionId,
        uint256[] indexSets,
        uint256 payout
    );

    /// Mapping key is an condition ID. Value represents numerators of the payout vector associated with the condition. This array is initialized with a length equal to the outcome slot count. E.g. Condition with 3 outcomes [A, B, C] and two of those correct [0.5, 0.5, 0]. In Ethereum there are no decimal values, so here, 0.5 is represented by fractions like 1/2 == 0.5. That's why we need numerator and denominator values. Payout numerators are also used as a check of initialization. If the numerators array is empty (has length zero), the condition was not created/prepared. See getOutcomeSlotCount.
    function payoutNumerators(bytes32) external returns (uint256[] memory);

    /// Denominator is also used for checking if the condition has been resolved. If the denominator is non-zero, then the condition has been resolved.
    function payoutDenominator(bytes32) external returns (uint256);

    /// @dev This function prepares a condition by initializing a payout vector associated with the condition.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function prepareCondition(
        address oracle,
        bytes32 questionId,
        uint256 outcomeSlotCount
    ) external;

    /// @dev Called by the oracle for reporting results of conditions. Will set the payout vector for the condition with the ID ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``, where oracle is the message sender, questionId is one of the parameters of this function, and outcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
    /// @param questionId The question ID the oracle is answering for
    /// @param payouts The oracle's answer
    function reportPayouts(bytes32 questionId, uint256[] calldata payouts) external;

    /// @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. Otherwise, this contract will burn `amount` stake held by the message sender in the position being split worth of EIP 1155 tokens. Regardless, if successful, `amount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert. The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
    /// @param collateralToken The address of the positions' backing collateral token.
    /// @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
    /// @param conditionId The ID of the condition to split on.
    /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param amount The amount of collateral or stake to split.
    function splitPosition(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    function mergePositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    function redeemPositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata indexSets
    ) external;

    /// @dev Gets the outcome slot count of a condition.
    /// @param conditionId ID of the condition.
    /// @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
    function getOutcomeSlotCount(bytes32 conditionId) external view returns (uint256);

    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getConditionId(
        address oracle,
        bytes32 questionId,
        uint256 outcomeSlotCount
    ) external pure returns (bytes32);

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256 indexSet
    ) external view returns (bytes32);

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, bytes32 collectionId) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface OptimisticOracleInterface {
    // Struct representing a price request.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external returns (uint256 totalBond);

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external returns (uint256 totalBond);

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external view returns (Request memory);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (uint256 payout);

    /**
     * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
     * or settleable. Note: this method is not view so that this call may actually settle the price request if it
     * hasn't been settled.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return resolved price.
     */
    function settleAndGetPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (int256);

    /**
     * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return true if price has resolved or settled, false otherwise.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface AddressWhitelistInterface {
    function addToWhitelist(address newElement) external;

    function removeFromWhitelist(address newElement) external;

    function isOnWhitelist(address newElement) external view returns (bool);

    function getWhitelist() external view returns (address[] memory);
}