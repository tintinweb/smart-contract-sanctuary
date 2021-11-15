// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./core/lifecycle/Initializable.sol";
import "./core/math/MathLib.sol";
import "./core/math/SafeMathLib.sol";
import "./IMetaheroDAO.sol";
import "./MetaheroToken.sol";


/**
 * @title Metahero DAO
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract MetaheroDAO is Initializable, IMetaheroDAO {
  using MathLib for uint256;
  using SafeMathLib for uint256;

  struct Settings {
    uint256 minVotingPeriod;
    uint256 snapshotWindow;
  }

  struct Proposal {
    uint256 snapshotId;
    bytes callData;
    uint256 startsAt;
    uint256 endsAt;
    bool processed;
    uint256 votesMinPercentage;
    uint256 votesMinWeight;
    uint256 votesYesWeight;
    uint256 votesNoWeight;
    uint256 votesCount;
    mapping (address => uint8) votes; // 1 - yes, 2 - no
  }

  struct WeightsHistory {
    uint256[] weights;
    uint256[] snapshotIds;
  }

  // globals

  uint256 private constant MAX_VOTES_MIN_PERCENTAGE = 75; // 75%

  /**
   * @return operator address
   */
  address public operator;

  /**
   * @return token address
   */
  MetaheroToken public token;

  /**
   * @return settings object
   */
  Settings public settings;

  mapping(uint256 => Proposal) private proposals;
  mapping(address => WeightsHistory) private membersWeightsHistory;
  WeightsHistory private totalWeightsHistory;
  uint256 private proposalCounter;
  uint256 private snapshotBaseTimestamp;

  // events

  /**
   * @dev Emitted the contract is initialized
   * @param token token address
   * @param operator operator address
   * @param minVotingPeriod min voting period
   * @param snapshotWindow snapshot window
   * @param snapshotBaseTimestamp snapshot base timestamp
   */
  event Initialized(
    address token,
    address operator,
    uint256 minVotingPeriod,
    uint256 snapshotWindow,
    uint256 snapshotBaseTimestamp
  );

  /**
   * @dev Emitted the proposal is created
   * @param proposalId proposal id
   * @param callData token call data
   * @param snapshotId snapshot id
   * @param startsAt starts at
   * @param endsAt ends at
   * @param votesMinPercentage votes min percentage
   * @param votesMinWeight votes min weight
   */
  event ProposalCreated(
    uint256 proposalId,
    uint256 snapshotId,
    bytes callData,
    uint256 startsAt,
    uint256 endsAt,
    uint256 votesMinPercentage,
    uint256 votesMinWeight
  );

  /**
   * @dev Emitted the proposal is processed
   * @param proposalId proposal id
   * @param votesYesWeight votes yes weight
   * @param votesNoWeight votes no weight
   */
  event ProposalProcessed(
    uint256 proposalId,
    uint256 votesYesWeight,
    uint256 votesNoWeight
  );

  /**
   * @dev Emitted the vote is submitted
   * @param proposalId proposal id
   * @param member member address
   * @param vote where `1` eq yes and `2` eq no
   */
  event VoteSubmitted(
    uint256 proposalId,
    address member,
    uint8 vote
  );

  // modifiers

  /**
   * @dev Throws if msg.sender is not the operator
   */
  modifier onlyOperator() {
    require(
      msg.sender == operator,
      "MetaheroDAO#1" // msg.sender is not the operator
    );

    _;
  }

  /**
   * @dev Throws if msg.sender is not the token
   */
  modifier onlyToken() {
    require(
      msg.sender == address(token),
      "MetaheroDAO#2" // msg.sender is not the token
    );

    _;
  }

  /**
   * @dev Public constructor
   */
  constructor ()
    public
    Initializable()
  {
    //
  }

  // external functions

  /**
   * @dev Initializes the contract
   * @param token_ token address
   * @param operator_ custom operator address
   * @param minVotingPeriod min voting period
   * @param snapshotWindow snapshot window
   */
  function initialize(
    address token_,
    address operator_,
    uint256 minVotingPeriod,
    uint256 snapshotWindow
  )
    external
    onlyInitializer
  {
    require(
      token_ != address(0),
      "MetaheroDAO#3" // token is the zero address
    );

    require(
      minVotingPeriod != 0,
      "MetaheroDAO#4" // min voting period is zero
    );

    require(
      snapshotWindow != 0,
      "MetaheroDAO#5" // snapshot window is zero
    );

    token = MetaheroToken(token_);

    if (operator_ == address(0)) {
      operator_ = token.owner();
    }

    operator = operator_;

    settings.minVotingPeriod = minVotingPeriod;
    settings.snapshotWindow = snapshotWindow;

    snapshotBaseTimestamp = block.timestamp; // solhint-disable-line not-rely-on-time

    emit Initialized(
      token_,
      operator_,
      minVotingPeriod,
      snapshotWindow,
      snapshotBaseTimestamp
    );
  }

  /**
   * @notice Called by a token to sync a dao member
   * @param member member address
   * @param memberWeight member weight
   * @param totalWeight all members weight
   */
  function syncMember(
    address member,
    uint256 memberWeight,
    uint256 totalWeight
  )
    external
    onlyToken
    override
  {
    uint256 snapshotId = _getSnapshotIdAt(block.timestamp); // solhint-disable-line not-rely-on-time

    _setMemberWeight(
      member,
      memberWeight,
      snapshotId
    );

    _setTotalWeight(
      totalWeight,
      snapshotId
    );
  }

  /**
   * @notice Called by a token to sync a dao members
   * @param memberA member A address
   * @param memberAWeight member A weight
   * @param memberB member B address
   * @param memberBWeight member B weight
   * @param totalWeight all members weight
   */
  function syncMembers(
    address memberA,
    uint256 memberAWeight,
    address memberB,
    uint256 memberBWeight,
    uint256 totalWeight
  )
    external
    onlyToken
    override
  {
    uint256 snapshotId = _getSnapshotIdAt(block.timestamp); // solhint-disable-line not-rely-on-time

    _setMemberWeight(
      memberA,
      memberAWeight,
      snapshotId
    );

    _setMemberWeight(
      memberB,
      memberBWeight,
      snapshotId
    );

    _setTotalWeight(
      totalWeight,
      snapshotId
    );
  }

  /**
   * @dev Removes token lp fees
   */
  function removeTokenLPFees()
    external
    onlyOperator
  {
    (
      MetaheroToken.Fees memory burnFees,
      MetaheroToken.Fees memory lpFees,
      MetaheroToken.Fees memory rewardsFees,
    ) = token.settings();

    require(
      lpFees.sender != 0 ||
      lpFees.recipient != 0,
      "MetaheroDAO#6" // already removed
    );

    token.updateFees(
      MetaheroToken.Fees(
        burnFees.sender.add(lpFees.sender),
        burnFees.recipient.add(lpFees.recipient)
      ),
      MetaheroToken.Fees(0, 0), // remove lp fees
      rewardsFees
    );
  }

  /**
   * @dev Excludes token account
   * @param account account address
   * @param excludeSenderFromFee exclude sender from fee
   * @param excludeRecipientFromFee exclude recipient from fee
   */
  function excludeTokenAccount(
    address account,
    bool excludeSenderFromFee,
    bool excludeRecipientFromFee
  )
    external
    onlyOperator
  {
    token.excludeAccount(
      account,
      excludeSenderFromFee,
      excludeRecipientFromFee
    );
  }

  /**
   * @dev Creates proposal
   * @param callData token call data
   * @param startsIn starts in
   * @param endsIn ends in
   * @param votesMinPercentage votes min percentage
   */
  function createProposal(
    bytes calldata callData,
    uint256 startsIn,
    uint256 endsIn,
    uint256 votesMinPercentage
  )
    external
    onlyOperator
  {
    require(
      endsIn > startsIn,
      "MetaheroDAO#7" // `ends in` should be higher than `starts in`
    );

    require(
      endsIn.sub(startsIn) >= settings.minVotingPeriod,
      "MetaheroDAO#8" // voting period is too short
    );

    proposalCounter++;

    uint256 proposalId = proposalCounter;
    uint256 snapshotId = _getSnapshotIdAt(block.timestamp); // solhint-disable-line not-rely-on-time
    uint256 startsAt = startsIn.add(block.timestamp); // solhint-disable-line not-rely-on-time
    uint256 endsAt = endsIn.add(block.timestamp); // solhint-disable-line not-rely-on-time
    uint256 votesMinWeight;

    if (votesMinPercentage != 0) {
      require(
        votesMinPercentage <= MAX_VOTES_MIN_PERCENTAGE,
        "MetaheroDAO#9" // invalid votes min percentage
      );

      votesMinWeight = _getTotalWeightOnSnapshot(
        snapshotId
      ).percent(votesMinPercentage);
    }

    proposals[proposalId].snapshotId = snapshotId;
    proposals[proposalId].callData = callData;
    proposals[proposalId].startsAt = startsAt;
    proposals[proposalId].endsAt = endsAt;
    proposals[proposalId].votesMinPercentage = votesMinPercentage;
    proposals[proposalId].votesMinWeight = votesMinWeight;

    emit ProposalCreated(
      proposalId,
      snapshotId,
      callData,
      startsAt,
      endsAt,
      votesMinPercentage,
      votesMinWeight
    );
  }

  /**
   * @dev Processes proposal
   * @param proposalId proposal id
   */
  function processProposal(
    uint256 proposalId
  )
    external
  {
    Proposal memory proposal = proposals[proposalId];

    require(
      proposal.snapshotId != 0,
      "MetaheroDAO#10" // proposal not found
    );

    require(
      proposal.endsAt <= block.timestamp, // solhint-disable-line not-rely-on-time
      "MetaheroDAO#11"
    );

    require(
      !proposal.processed,
      "MetaheroDAO#12" // already processed
    );

    if (
      proposal.callData.length > 0 &&
      proposal.votesYesWeight > proposal.votesNoWeight &&
      proposal.votesYesWeight >= proposal.votesMinWeight
    ) {
      (bool success, ) = address(token).call(proposal.callData); // solhint-disable-line avoid-low-level-calls

      require(
        success,
        "MetaheroDAO#13" // call failed
      );
    }

    proposals[proposalId].processed = true;

    emit ProposalProcessed(
      proposalId,
      proposal.votesYesWeight,
      proposal.votesNoWeight
    );
  }

  /**
   * @dev Submits vote
   * @param proposalId proposal id
   * @param vote where `1` eq yes and `2` eq no
   */
  function submitVote(
    uint256 proposalId,
    uint8 vote
  )
    external
  {
    Proposal memory proposal = proposals[proposalId];

    require(
      proposal.snapshotId != 0,
      "MetaheroDAO#14" // proposal not found
    );

    require(
      proposal.startsAt <= block.timestamp, // solhint-disable-line not-rely-on-time
      "MetaheroDAO#15"
    );

    require(
      proposal.endsAt > block.timestamp, // solhint-disable-line not-rely-on-time
      "MetaheroDAO#16"
    );

    require(
      vote == 1 ||
      vote == 2,
      "MetaheroDAO#17"
    );

    require(
      proposals[proposalId].votes[msg.sender] == 0,
      "MetaheroDAO#18"
    );

    uint256 memberWeight = _getMemberWeightOnSnapshot(
      msg.sender,
      proposal.snapshotId
    );

    require(
      memberWeight != 0,
      "MetaheroDAO#19"
    );

    if (vote == 1) { // yes vote
      proposals[proposalId].votesYesWeight = proposal.votesYesWeight.add(
        memberWeight
      );
    }

    if (vote == 2) { // no vote
      proposals[proposalId].votesNoWeight = proposal.votesNoWeight.add(
        memberWeight
      );
    }

    proposals[proposalId].votesCount = proposal.votesCount.add(1);
    proposals[proposalId].votes[msg.sender] = vote;

    emit VoteSubmitted(
      proposalId,
      msg.sender,
      vote
    );
  }

  // external functions (views)

  function getProposal(
    uint256 proposalId
  )
    external
    view
    returns (
      uint256 snapshotId,
      bytes memory callData,
      uint256 startsAt,
      uint256 endsAt,
      bool processed,
      uint256 votesMinPercentage,
      uint256 votesMinWeight,
      uint256 votesYesWeight,
      uint256 votesNoWeight,
      uint256 votesCount
    )
  {
    {
      snapshotId = proposals[proposalId].snapshotId;
      callData = proposals[proposalId].callData;
      startsAt = proposals[proposalId].startsAt;
      endsAt = proposals[proposalId].endsAt;
      processed = proposals[proposalId].processed;
      votesMinPercentage = proposals[proposalId].votesMinPercentage;
      votesMinWeight = proposals[proposalId].votesMinWeight;
      votesYesWeight = proposals[proposalId].votesYesWeight;
      votesNoWeight = proposals[proposalId].votesNoWeight;
      votesCount = proposals[proposalId].votesCount;
    }

    return (
      snapshotId,
      callData,
      startsAt,
      endsAt,
      processed,
      votesMinPercentage,
      votesMinWeight,
      votesYesWeight,
      votesNoWeight,
      votesCount
    );
  }

  function getMemberProposalVote(
    address member,
    uint256 proposalId
  )
    external
    view
    returns (uint8)
  {
    return proposals[proposalId].votes[member];
  }

  function getCurrentSnapshotId()
    external
    view
    returns (uint256)
  {
    return _getSnapshotIdAt(block.timestamp); // solhint-disable-line not-rely-on-time
  }

  function getSnapshotIdAt(
    uint256 timestamp
  )
    external
    view
    returns (uint256)
  {
    return _getSnapshotIdAt(timestamp);
  }

  function getCurrentMemberWeight(
    address member
  )
    external
    view
    returns (uint256)
  {
    return _getMemberWeightOnSnapshot(
      member,
      _getSnapshotIdAt(block.timestamp) // solhint-disable-line not-rely-on-time
    );
  }

  function getMemberWeightOnSnapshot(
    address member,
    uint256 snapshotId
  )
    external
    view
    returns (uint256)
  {
    return _getMemberWeightOnSnapshot(
      member,
      snapshotId
    );
  }

  function getCurrentTotalWeight()
    external
    view
    returns (uint256)
  {
    return _getTotalWeightOnSnapshot(
      _getSnapshotIdAt(block.timestamp) // solhint-disable-line not-rely-on-time
    );
  }

  function getTotalWeightOnSnapshot(
    uint256 snapshotId
  )
    external
    view
    returns (uint256)
  {
    return _getTotalWeightOnSnapshot(
      snapshotId
    );
  }

  // private functions

  function _setMemberWeight(
    address member,
    uint256 memberWeight,
    uint256 snapshotId
  )
    private
  {
    uint256 snapshotIdsLen = membersWeightsHistory[member].snapshotIds.length;

    if (snapshotIdsLen == 0) {
      membersWeightsHistory[member].weights.push(memberWeight);
      membersWeightsHistory[member].snapshotIds.push(snapshotId);
    } else {
      uint256 snapshotIdsLastIndex = snapshotIdsLen - 1;

      if (
        membersWeightsHistory[member].snapshotIds[snapshotIdsLastIndex] == snapshotId
      ) {
        membersWeightsHistory[member].weights[snapshotIdsLastIndex] = memberWeight;
      } else {
        membersWeightsHistory[member].weights.push(memberWeight);
        membersWeightsHistory[member].snapshotIds.push(snapshotId);
      }
    }
  }

  function _setTotalWeight(
    uint256 totalWeight,
    uint256 snapshotId
  )
    private
  {
    uint256 snapshotIdsLen = totalWeightsHistory.snapshotIds.length;

    if (snapshotIdsLen == 0) {
      totalWeightsHistory.weights.push(totalWeight);
      totalWeightsHistory.snapshotIds.push(snapshotId);
    } else {
      uint256 snapshotIdsLastIndex = snapshotIdsLen - 1;

      if (
        totalWeightsHistory.snapshotIds[snapshotIdsLastIndex] == snapshotId
      ) {
        totalWeightsHistory.weights[snapshotIdsLastIndex] = totalWeight;
      } else {
        totalWeightsHistory.weights.push(totalWeight);
        totalWeightsHistory.snapshotIds.push(snapshotId);
      }
    }
  }

  // private functions (views)

  function _getSnapshotIdAt(
    uint256 timestamp
  )
    private
    view
    returns (uint256)
  {
    return snapshotBaseTimestamp >= timestamp
      ? 0
      : timestamp.sub(
        snapshotBaseTimestamp
      ).div(
        settings.snapshotWindow
      ).add(1);
  }

  function _getMemberWeightOnSnapshot(
    address member,
    uint256 snapshotId
  )
    private
    view
    returns (uint256 result)
  {
    WeightsHistory memory weightsHistory = membersWeightsHistory[member];
    uint len = weightsHistory.snapshotIds.length;

    if (len != 0) {
      for (uint pos = 1 ; pos <= len ; pos++) {
        uint index = len - pos;

        if (weightsHistory.snapshotIds[index] <= snapshotId) {
          result = membersWeightsHistory[member].weights[index];
          break;
        }
      }
    } else {
      (
        ,
        uint256 holdingBalance,
        uint256 totalRewards
      ) = token.getBalanceSummary(member);

      if (totalRewards != 0) {
        result = holdingBalance;
      }
    }

    return result;
  }

  function _getTotalWeightOnSnapshot(
    uint256 snapshotId
  )
    private
    view
    returns (uint256 result)
  {
    uint len = totalWeightsHistory.snapshotIds.length;

    if (len != 0) {
      for (uint pos = 1 ; pos <= len ; pos++) {
        uint index = len - pos;

        if (totalWeightsHistory.snapshotIds[index] <= snapshotId) {
          result = totalWeightsHistory.weights[index];
          break;
        }
      }
    } else {
      (
        ,
        uint256 totalHolding,
        ,
      ) = token.summary();

      result = totalHolding;
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Initializable
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Initializable {
  address private initializer;

  // modifiers

  /**
   * @dev Throws if msg.sender is not the initializer
   */
  modifier onlyInitializer() {
    require(
      initializer != address(0),
      "Initializable#1" // already initialized
    );

    require(
      msg.sender == initializer,
      "Initializable#2" // msg.sender is not the initializer
    );

    /// @dev removes initializer
    initializer = address(0);

    _;
  }

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    initializer = msg.sender;
  }

  // external functions (views)

  /**
   * @notice Checks if contract is initialized
   * @return true when contract is initialized
   */
  function initialized()
    external
    view
    returns (bool)
  {
    return initializer == address(0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMathLib.sol";


/**
 * @title Math library
 *
 * @author Stanisław Głogowski <[email protected]>
 */
library MathLib {
  using SafeMathLib for uint256;

  // internal functions (pure)

  /**
   * @notice Calcs a x p / 100
   */
  function percent(
    uint256 a,
    uint256 p
  )
    internal
    pure
    returns (uint256 result)
  {
    if (a != 0 && p != 0) {
      result = a.mul(p).div(100);
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Safe math library
 *
 * @notice Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/5fe8f4e93bd1d4f5cc9a6899d7f24f5ffe4c14aa/contracts/math/SafeMath.sol
 */
library SafeMathLib {
  // internal functions (pure)

  /**
   * @notice Calcs a + b
   */
  function add(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = a + b;

    require(
      c >= a,
      "SafeMathLib#1"
    );

    return c;
  }

  /**
   * @notice Calcs a - b
   */
  function sub(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    require(
      b <= a,
      "SafeMathLib#2"
    );

    return a - b;
  }

  /**
   * @notice Calcs a x b
   */
  function mul(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256 result)
  {
    if (a != 0 && b != 0) {
      result = a * b;

      require(
        result / a == b,
        "SafeMathLib#3"
      );
    }

    return result;
  }

  /**
   * @notice Calcs a / b
   */
  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    require(
      b != 0,
      "SafeMathLib#4"
    );

    return a / b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Metahero DAO interface
 *
 * @author Stanisław Głogowski <[email protected]>
 */
interface IMetaheroDAO {
  // external functions

  /**
   * @notice Called by a token to sync a dao member
   * @param member member address
   * @param memberWeight member weight
   * @param totalWeight all members weight
   */
  function syncMember(
    address member,
    uint256 memberWeight,
    uint256 totalWeight
  )
    external;

  /**
   * @notice Called by a token to sync a dao members
   * @param memberA member A address
   * @param memberAWeight member A weight
   * @param memberB member B address
   * @param memberBWeight member B weight
   * @param totalWeight all members weight
   */
  function syncMembers(
    address memberA,
    uint256 memberAWeight,
    address memberB,
    uint256 memberBWeight,
    uint256 totalWeight
  )
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./core/access/Controlled.sol";
import "./core/access/Owned.sol";
import "./core/erc20/ERC20.sol";
import "./core/lifecycle/Initializable.sol";
import "./core/math/MathLib.sol";
import "./core/math/SafeMathLib.sol";
import "./IMetaheroDAO.sol";
import "./MetaheroLPM.sol";


/**
 * @title Metahero token
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract MetaheroToken is Controlled, Owned, ERC20, Initializable {
  using MathLib for uint256;
  using SafeMathLib for uint256;

  struct Fees {
    uint256 sender; // percent from sender
    uint256 recipient; // percent from recipient
  }

  struct Settings {
    Fees burnFees; // fee taken and burned
    Fees lpFees; // fee taken and added to the liquidity pool manager
    Fees rewardsFees; // fee taken and added to rewards
    uint256 minTotalSupply; // min amount of tokens total supply
  }

  struct Summary {
    uint256 totalExcluded; // total held by excluded accounts
    uint256 totalHolding; // total held by holder accounts
    uint256 totalRewards; // total rewards
    uint256 totalSupply; // total supply
  }

  struct ExcludedAccount {
    bool exists; // true if exists
    bool excludeSenderFromFee; // removes the fee from all sender accounts on incoming transfers
    bool excludeRecipientFromFee; // removes the fee from all recipient accounts on outgoing transfers
  }

  // globals

  uint256 private constant MAX_FEE = 30; // max sum of all fees - 30%

  // metadata

  string private constant TOKEN_NAME = "Metahero";
  string private constant TOKEN_SYMBOL = "HERO";
  uint8 private constant TOKEN_DECIMALS = 18; // 0.000000000000000000

  /**
   * @return dao address
   */
  IMetaheroDAO public dao;

  /**
   * @return liquidity pool manager address
   */
  MetaheroLPM public lpm;

  /**
   * @return settings object
   */
  Settings public settings;

  /**
   * @return summary object
   */
  Summary public summary;

  /**
   * @return return true when presale is finished
   */
  bool public presaleFinished;

  mapping (address => uint256) private accountBalances;
  mapping (address => mapping (address => uint256)) private accountAllowances;
  mapping (address => ExcludedAccount) private excludedAccounts;

  // events

  /**
   * @dev Emitted when the contract is initialized
   * @param burnFees burn fees
   * @param lpFees liquidity pool fees
   * @param rewardsFees rewards fees
   * @param minTotalSupply min total supply
   * @param lpm liquidity pool manager address
   * @param controller controller address
   */
  event Initialized(
    Fees burnFees,
    Fees lpFees,
    Fees rewardsFees,
    uint256 minTotalSupply,
    address lpm,
    address controller
  );

  /**
   * @dev Emitted when the dao is updated
   * @param dao dao address
   */
  event DAOUpdated(
    address dao
  );

  /**
   * @dev Emitted when fees are updated
   * @param burnFees burn fees
   * @param lpFees liquidity pool fees
   * @param rewardsFees rewards fees
   */
  event FeesUpdated(
    Fees burnFees,
    Fees lpFees,
    Fees rewardsFees
  );

  /**
   * @dev Emitted when the presale is finished
   */
  event PresaleFinished();

  /**
   * @dev Emitted when account is excluded
   * @param account account address
   * @param excludeSenderFromFee exclude sender from fee
   * @param excludeRecipientFromFee exclude recipient from fee
   */
  event AccountExcluded(
    address indexed account,
    bool excludeSenderFromFee,
    bool excludeRecipientFromFee
  );

  /**
   * @dev Emitted when total rewards amount is updated
   * @param totalRewards total rewards amount
   */
  event TotalRewardsUpdated(
    uint256 totalRewards
  );

  // modifiers

  /**
   * @dev Throws if msg.sender is not the dao
   */
  modifier onlyDAO() {
    require(
      msg.sender == address(dao),
      "MetaheroToken#1" // msg.sender is not the dao
    );

    _;
  }

  /**
   * @dev Throws if msg.sender is not the excluded account
   */
  modifier onlyExcludedAccount() {
    require(
      excludedAccounts[msg.sender].exists,
      "MetaheroToken#2" // msg.sender is not the excluded account
    );

    _;
  }

  /**
   * @dev Public constructor
   */
  constructor ()
    public
    Controlled()
    Owned()
    ERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS) // sets metadata
    Initializable()
  {
    //
  }

  // external functions

  /**
   * @dev Initializes the contract
   * @param burnFees burn fees
   * @param lpFees liquidity pool fees
   * @param rewardsFees rewards fees
   * @param minTotalSupply min total supply
   * @param lpm_ liquidity pool manager address
   * @param controller_ controller address
   * @param totalSupply_ total supply
   */
  function initialize(
    Fees memory burnFees,
    Fees memory lpFees,
    Fees memory rewardsFees,
    uint256 minTotalSupply,
    address payable lpm_,
    address controller_,
    uint256 totalSupply_,
    address[] calldata excludedAccounts_
  )
    external
    onlyInitializer
  {
    _verifyFees(burnFees, lpFees, rewardsFees);

    settings.burnFees = burnFees;
    settings.lpFees = lpFees;
    settings.rewardsFees = rewardsFees;
    settings.minTotalSupply = minTotalSupply;

    if (
      lpFees.sender != 0 ||
      lpFees.recipient != 0
    ) {
      require(
        lpm_ != address(0),
        "MetaheroToken#3" // lpm is the zero address
      );

      lpm = MetaheroLPM(lpm_);
    }

    _initializeController(controller_);

    emit Initialized(
      burnFees,
      lpFees,
      rewardsFees,
      minTotalSupply,
      lpm_,
      controller_
    );

    // excludes owner account
    _excludeAccount(msg.sender, true, true);

    if (totalSupply_ != 0) {
      _mint(
        msg.sender,
        totalSupply_
      );
    }

    // adds predefined excluded accounts
    uint256 excludedAccountsLen = excludedAccounts_.length;

    for (uint256 index; index < excludedAccountsLen; index++) {
      _excludeAccount(excludedAccounts_[index], false, false);
    }
  }

  /**
   * @dev Sets the dao
   * @param dao_ dao address
   */
  function setDAO(
    address dao_
  )
    external
    onlyOwner
  {
    require(
      dao_ != address(0),
      "MetaheroToken#4" // dao is the zero address
    );

    dao = IMetaheroDAO(dao_);

    emit DAOUpdated(
      dao_
    );

    // makes a dao an owner
    _setOwner(dao_);
  }

  /**
   * @dev Updates fees
   * @param burnFees burn fees
   * @param lpFees liquidity pool fees
   * @param rewardsFees rewards fees
   */
  function updateFees(
    Fees memory burnFees,
    Fees memory lpFees,
    Fees memory rewardsFees
  )
    external
    onlyDAO // only for dao
  {
    _verifyFees(burnFees, lpFees, rewardsFees);

    settings.burnFees = burnFees;
    settings.lpFees = lpFees;
    settings.rewardsFees = rewardsFees;

    emit FeesUpdated(
      burnFees,
      lpFees,
      rewardsFees
    );
  }

  /**
   * @dev Set the presale as finished
   */
  function setPresaleAsFinished()
    external
    onlyOwner
  {
    require(
      !presaleFinished,
      "MetaheroToken#5" // the presale is already finished
    );

    presaleFinished = true;

    emit PresaleFinished();
  }

  /**
   * @dev Excludes account
   * @param account account address
   * @param excludeSenderFromFee exclude sender from fee
   * @param excludeRecipientFromFee exclude recipient from fee
   */
  function excludeAccount(
    address account,
    bool excludeSenderFromFee,
    bool excludeRecipientFromFee
  )
    external
    onlyOwner
  {
    _excludeAccount(
      account,
      excludeSenderFromFee,
      excludeRecipientFromFee
    );
  }

  /**
   * @dev Approve spending limit
   * @param spender spender address
   * @param amount spending limit
   */
  function approve(
    address spender,
    uint256 amount
  )
    external
    override
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      amount
    );

    return true;
  }

  /**
   * @dev Mints tokens to recipient
   * @param recipient recipient address
   * @param amount tokens amount
   */
  function mintTo(
    address recipient,
    uint256 amount
  )
    external
    onlyController
  {
    _mint(
      recipient,
      amount
    );
  }

  /**
   * @dev Burns tokens from msg.sender
   * @param amount tokens amount
   */
  function burn(
    uint256 amount
  )
    external
    onlyExcludedAccount
  {
    _burn(
      msg.sender,
      amount
    );
  }

  /**
   * @dev Burns tokens from sender
   * @param sender sender address
   * @param amount tokens amount
   */
  function burnFrom(
    address sender,
    uint256 amount
  )
    external
    onlyController
  {
    _burn(
      sender,
      amount
    );
  }

  /**
   * @dev Transfers tokens to recipient
   * @param recipient recipient address
   * @param amount tokens amount
   */
  function transfer(
    address recipient,
    uint256 amount
  )
    external
    override
    returns (bool)
  {
    _transfer(
      msg.sender,
      recipient,
      amount
    );

    return true;
  }

  /**
   * @dev Transfers tokens from sender to recipient
   * @param sender sender address
   * @param recipient recipient address
   * @param amount tokens amount
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  )
    external
    override
    returns (bool)
  {
    _transfer(
      sender,
      recipient,
      amount
    );

    uint256 allowance = accountAllowances[sender][msg.sender];

    require(
      allowance >= amount,
      "MetaheroToken#6"  // amount exceeds allowance
    );

    _approve( // update allowance
      sender,
      msg.sender,
      allowance.sub(amount)
    );

    return true;
  }

  // external functions (views)

  /**
   * @dev Gets excluded account
   * @param account account address
   */
  function getExcludedAccount(
    address account
  )
    external
    view
    returns (
      bool exists,
      bool excludeSenderFromFee,
      bool excludeRecipientFromFee
    )
  {
    return (
      excludedAccounts[account].exists,
      excludedAccounts[account].excludeSenderFromFee,
      excludedAccounts[account].excludeRecipientFromFee
    );
  }

  /**
   * @dev Gets total supply
   * @return total supply
   */
  function totalSupply()
    external
    view
    override
    returns (uint256)
  {
    return summary.totalSupply;
  }

  /**
   * @dev Gets allowance
   * @param owner owner address
   * @param spender spender address
   * @return allowance
   */
  function allowance(
    address owner,
    address spender
  )
    external
    view
    override
    returns (uint256)
  {
    return accountAllowances[owner][spender];
  }

  /**
   * @dev Gets balance of
   * @param account account address
   * @return result account balance
   */
  function balanceOf(
    address account
  )
    external
    view
    override
    returns (uint256 result)
  {
    result = accountBalances[account].add(
      _calcRewards(account)
    );

    return result;
  }

  /**
   * @dev Gets balance summary
   * @param account account address
   */
  function getBalanceSummary(
    address account
  )
    external
    view
    returns (
      uint256 totalBalance,
      uint256 holdingBalance,
      uint256 totalRewards
    )
  {
    holdingBalance = accountBalances[account];
    totalRewards = _calcRewards(account);
    totalBalance = holdingBalance.add(totalRewards);

    return (totalBalance, holdingBalance, totalRewards);
  }

  // private functions

  function _excludeAccount(
    address account,
    bool excludeSenderFromFee,
    bool excludeRecipientFromFee
  )
    private
  {
    require(
      account != address(0),
      "MetaheroToken#7" // account is the zero address
    );

    // if already excluded
    if (excludedAccounts[account].exists) {
      require(
        excludedAccounts[account].excludeSenderFromFee != excludeSenderFromFee ||
        excludedAccounts[account].excludeRecipientFromFee != excludeRecipientFromFee,
        "MetaheroToken#8" // does not update exclude account
      );

      excludedAccounts[account].excludeSenderFromFee = excludeSenderFromFee;
      excludedAccounts[account].excludeRecipientFromFee = excludeRecipientFromFee;
    } else {
      require(
        accountBalances[account] == 0,
        "MetaheroToken#9" // can not exclude holder account
      );

      excludedAccounts[account].exists = true;
      excludedAccounts[account].excludeSenderFromFee = excludeSenderFromFee;
      excludedAccounts[account].excludeRecipientFromFee = excludeRecipientFromFee;
    }

    emit AccountExcluded(
      account,
      excludeSenderFromFee,
      excludeRecipientFromFee
    );
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  )
    private
  {
    require(
      spender != address(0),
      "MetaheroToken#11" // spender is the zero address
    );

    accountAllowances[owner][spender] = amount;

    emit Approval(
      owner,
      spender,
      amount
    );
  }

  function _mint(
    address recipient,
    uint256 amount
  )
    private
  {
    require(
      recipient != address(0),
      "MetaheroToken#12" // recipient is the zero address
    );

    require(
      amount != 0,
      "MetaheroToken#13" // amount is zero
    );

    summary.totalSupply = summary.totalSupply.add(amount);

    // if exclude account
    if (excludedAccounts[recipient].exists) {
      summary.totalExcluded = summary.totalExcluded.add(amount);

      accountBalances[recipient] = accountBalances[recipient].add(amount);
    } else {
      _updateHoldingBalance(
        recipient,
        accountBalances[recipient].add(amount),
        summary.totalHolding.add(amount)
      );
    }

    _emitTransfer(
      address(0),
      recipient,
      amount
    );
  }

  function _burn(
    address sender,
    uint256 amount
  )
    private
  {
    require(
      sender != address(0),
      "MetaheroToken#14" // sender is the zero address
    );

    require(
      amount != 0,
      "MetaheroToken#15" // amount is zero
    );

    require(
      accountBalances[sender] >= amount,
      "MetaheroToken#16" // amount exceeds sender balance
    );

    uint256 totalSupply_ = summary.totalSupply.sub(amount);

    if (settings.minTotalSupply != 0) {
      require(
        totalSupply_ >= settings.minTotalSupply,
        "MetaheroToken#17" // new total supply exceeds min total supply
      );
    }

    summary.totalSupply = totalSupply_;

    // if exclude account
    if (excludedAccounts[sender].exists) {
      summary.totalExcluded = summary.totalExcluded.sub(amount);

      accountBalances[sender] = accountBalances[sender].sub(amount);
    } else {
      _updateHoldingBalance(
        sender,
        accountBalances[sender].sub(amount),
        summary.totalHolding.sub(amount)
      );
    }

    _emitTransfer(
      sender,
      address(0),
      amount
    );
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    require(
      sender != address(0),
      "MetaheroToken#18" // sender is the zero address
    );

    require(
      recipient != address(0),
      "MetaheroToken#19" // recipient is the zero address
    );

    if (sender == recipient) { // special transfer type
      _syncLP(); // sync only LP

      _emitTransfer(
        sender,
        recipient,
        0
      );
    } else {
      require(
        excludedAccounts[sender].exists ||
        presaleFinished,
        "MetaheroToken#20" // presale not finished yet
      );

      require(
        amount != 0,
        "MetaheroToken#21" // amount is zero
      );

      if (
        !excludedAccounts[sender].exists &&
        !excludedAccounts[recipient].exists
      ) {
        _transferBetweenHolderAccounts(
          sender,
          recipient,
          amount
        );
      } else if (
        excludedAccounts[sender].exists &&
        !excludedAccounts[recipient].exists
      ) {
        _transferFromExcludedAccount(
          sender,
          recipient,
          amount
        );
      } else if (
        !excludedAccounts[sender].exists &&
        excludedAccounts[recipient].exists
      ) {
        _transferToExcludedAccount(
          sender,
          recipient,
          amount
        );
      } else {
        _transferBetweenExcludedAccounts(
          sender,
          recipient,
          amount
        );
      }
    }
  }

  function _transferBetweenHolderAccounts(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    uint256 senderAmount;
    uint256 senderBurnFee;
    uint256 senderLpFee;

    uint256 recipientAmount;
    uint256 recipientBurnFee;
    uint256 recipientLpFee;

    uint256 totalFee;

    {
      uint256 totalSupply_ = summary.totalSupply;

      // calc fees for sender and recipient
      {
        uint256 senderTotalFee;
        uint256 recipientTotalFee;

        (
          senderTotalFee,
          senderBurnFee,
          senderLpFee
        ) = _calcTransferSenderFees(amount);

        (
          totalSupply_,
          senderTotalFee,
          senderBurnFee
        ) = _matchTotalSupplyWithFees(totalSupply_, senderTotalFee, senderBurnFee);

        (
          recipientTotalFee,
          recipientBurnFee,
          recipientLpFee
        ) = _calcTransferRecipientFees(amount);

        (
          totalSupply_,
          recipientTotalFee,
          recipientBurnFee
        ) = _matchTotalSupplyWithFees(totalSupply_, recipientTotalFee, recipientBurnFee);

        totalFee = senderTotalFee.add(recipientTotalFee);
        senderAmount = amount.add(senderTotalFee);
        recipientAmount = amount.sub(recipientTotalFee);
      }

      // appends total rewards
      if (summary.totalRewards != 0) {
        uint256 totalHoldingWithRewards = summary.totalHolding.add(
          summary.totalRewards
        );

        senderAmount = senderAmount.mul(summary.totalHolding).div(
          totalHoldingWithRewards
        );
        recipientAmount = recipientAmount.mul(summary.totalHolding).div(
          totalHoldingWithRewards
        );
        totalFee = totalFee.mul(summary.totalHolding).div(
          totalHoldingWithRewards
        );
      }

      require(
        accountBalances[sender] >= senderAmount,
        "MetaheroToken#22" // amount exceeds sender balance
      );

      summary.totalSupply = totalSupply_;

      // reduce local vars
      senderAmount = accountBalances[sender].sub(senderAmount);
      recipientAmount = accountBalances[recipient].add(recipientAmount);

      _updateHoldingBalances(
        sender,
        senderAmount,
        recipient,
        recipientAmount,
        summary.totalHolding.sub(totalFee)
      );

      _increaseTotalLP(senderLpFee.add(recipientLpFee));
    }

    // emits events

    {
      _emitTransfer(
        sender,
        recipient,
        amount
      );

      _emitTransfer(
        sender,
        address(0),
        senderBurnFee
      );

      _emitTransfer(
        sender,
        address(lpm),
        senderLpFee
      );

      _emitTransfer(
        recipient,
        address(0),
        recipientBurnFee
      );

      _emitTransfer(
        recipient,
        address(lpm),
        recipientLpFee
      );

      _updateTotalRewards();

      _syncLP();
    }
  }

  function _transferFromExcludedAccount(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    require(
      accountBalances[sender] >= amount,
      "MetaheroToken#23" // amount exceeds sender balance
    );

    (
      bool shouldSyncLPBefore,
      bool shouldSyncLPAfter
    ) = _canSyncLP(
      sender,
      address(0)
    );

    if (shouldSyncLPBefore) {
      lpm.syncLP();
    }

    uint256 recipientTotalFee;
    uint256 recipientBurnFee;
    uint256 recipientLPFee;

    uint256 totalSupply_ = summary.totalSupply;

    // when sender does not remove the fee from the recipient
    if (!excludedAccounts[sender].excludeRecipientFromFee) {
      (
        recipientTotalFee,
        recipientBurnFee,
        recipientLPFee
      ) = _calcTransferRecipientFees(amount);

      (
        totalSupply_,
        recipientTotalFee,
        recipientBurnFee
      ) = _matchTotalSupplyWithFees(totalSupply_, recipientTotalFee, recipientBurnFee);
    }

    uint256 recipientAmount = amount.sub(recipientTotalFee);

    summary.totalSupply = totalSupply_;
    summary.totalExcluded = summary.totalExcluded.sub(amount);

    accountBalances[sender] = accountBalances[sender].sub(amount);

    _updateHoldingBalance(
      recipient,
      accountBalances[recipient].add(recipientAmount),
      summary.totalHolding.add(recipientAmount)
    );

    _increaseTotalLP(recipientLPFee);

    // emits events

    _emitTransfer(
      sender,
      recipient,
      amount
    );

    _emitTransfer(
      recipient,
      address(0),
      recipientBurnFee
    );

    _emitTransfer(
      recipient,
      address(lpm),
      recipientLPFee
    );

    _updateTotalRewards();

    if (shouldSyncLPAfter) {
      lpm.syncLP();
    }
  }

  function _transferToExcludedAccount(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    (
      bool shouldSyncLPBefore,
      bool shouldSyncLPAfter
    ) = _canSyncLP(
      address(0),
      recipient
    );

    if (shouldSyncLPBefore) {
      lpm.syncLP();
    }

    uint256 senderTotalFee;
    uint256 senderBurnFee;
    uint256 senderLpFee;

    uint256 totalSupply_ = summary.totalSupply;

    // when recipient does not remove the fee from the sender
    if (!excludedAccounts[recipient].excludeSenderFromFee) {
      (
        senderTotalFee,
        senderBurnFee,
        senderLpFee
      ) = _calcTransferSenderFees(amount);

      (
        totalSupply_,
        senderTotalFee,
        senderBurnFee
      ) = _matchTotalSupplyWithFees(totalSupply_, senderTotalFee, senderBurnFee);
    }

    uint256 senderAmount = amount.add(senderTotalFee);

    // append total rewards
    if (summary.totalRewards != 0) {
      uint256 totalHoldingWithRewards = summary.totalHolding.add(
        summary.totalRewards
      );

      senderAmount = senderAmount.mul(summary.totalHolding).div(
        totalHoldingWithRewards
      );
    }

    require(
      accountBalances[sender] >= senderAmount,
      "MetaheroToken#24" // amount exceeds sender balance
    );

    summary.totalSupply = totalSupply_;
    summary.totalExcluded = summary.totalExcluded.add(amount);

    accountBalances[recipient] = accountBalances[recipient].add(amount);

    _updateHoldingBalance(
      sender,
      accountBalances[sender].sub(senderAmount),
      summary.totalHolding.sub(senderAmount)
    );

    _increaseTotalLP(senderLpFee);

    // emits events

    _emitTransfer(
      sender,
      recipient,
      amount
    );

    _emitTransfer(
      sender,
      address(0),
      senderBurnFee
    );

    _emitTransfer(
      sender,
      address(lpm),
      senderLpFee
    );

    _updateTotalRewards();

    if (shouldSyncLPAfter) {
      lpm.syncLP();
    }
  }

  function _transferBetweenExcludedAccounts(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    require(
      accountBalances[sender] >= amount,
      "MetaheroToken#25" // amount exceeds sender balance
    );

    (
      bool shouldSyncLPBefore,
      bool shouldSyncLPAfter
    ) = _canSyncLP(
      address(0),
      recipient
    );

    if (shouldSyncLPBefore) {
      lpm.syncLP();
    }

    accountBalances[sender] = accountBalances[sender].sub(amount);
    accountBalances[recipient] = accountBalances[recipient].add(amount);

    _emitTransfer(
      sender,
      recipient,
      amount
    );

    if (shouldSyncLPAfter) {
      lpm.syncLP();
    }
  }

  function _updateHoldingBalance(
    address holder,
    uint256 holderBalance,
    uint256 totalHolding
  )
    private
  {
    accountBalances[holder] = holderBalance;
    summary.totalHolding = totalHolding;

    if (address(dao) != address(0)) { // if dao is not the zero address
      dao.syncMember(
        holder,
        holderBalance,
        totalHolding
      );
    }
  }

  function _updateHoldingBalances(
    address holderA,
    uint256 holderABalance,
    address holderB,
    uint256 holderBBalance,
    uint256 totalHolding
  )
    private
  {
    accountBalances[holderA] = holderABalance;
    accountBalances[holderB] = holderBBalance;
    summary.totalHolding = totalHolding;

    if (address(dao) != address(0)) { // if dao is not the zero address
      dao.syncMembers(
        holderA,
        holderABalance,
        holderB,
        holderBBalance,
        totalHolding
      );
    }
  }

  function _emitTransfer(
    address sender,
    address recipient,
    uint256 amount
  )
    private
  {
    if (amount != 0) { // when amount is not zero
      emit Transfer(
        sender,
        recipient,
        amount
      );
    }
  }

  function _increaseTotalLP(
    uint256 amount
  )
    private
  {
    if (amount != 0) { // when amount is not zero
      accountBalances[address(lpm)] = accountBalances[address(lpm)].add(amount);

      summary.totalExcluded = summary.totalExcluded.add(amount);
    }
  }

  function _syncLP()
    private
  {
    if (address(lpm) != address(0)) { // if lpm is not the zero address
      lpm.syncLP();
    }
  }

  function _updateTotalRewards()
    private
  {
    // totalRewards = totalSupply - totalExcluded - totalHolding
    uint256 totalRewards = summary.totalSupply
    .sub(summary.totalExcluded)
    .sub(summary.totalHolding);

    if (totalRewards != summary.totalRewards) {
      summary.totalRewards = totalRewards;

      emit TotalRewardsUpdated(
        totalRewards
      );
    }
  }

  // private functions (views)

  function _matchTotalSupplyWithFees(
    uint256 totalSupply_,
    uint256 totalFee,
    uint256 burnFee
  )
    private
    view
    returns (uint256, uint256, uint256)
  {
    if (burnFee != 0) {
      uint256 newTotalSupply = totalSupply_.sub(burnFee);

      if (newTotalSupply >= settings.minTotalSupply) {
        totalSupply_ = newTotalSupply;
      } else  { // turn of burn fee
        totalFee = totalFee.sub(burnFee);
        burnFee = 0;
      }
    }

    return (totalSupply_, totalFee, burnFee);
  }


  function _canSyncLP(
    address sender,
    address recipient
  )
    private
    view
    returns (
      bool shouldSyncLPBefore,
      bool shouldSyncLPAfter
    )
  {
    if (address(lpm) != address(0)) { // if lpm is not the zero address
      (shouldSyncLPBefore, shouldSyncLPAfter) = lpm.canSyncLP(
        sender,
        recipient
      );
    }

    return (shouldSyncLPBefore, shouldSyncLPAfter);
  }

  function _calcRewards(
    address account
  )
    private
    view
    returns (uint256 result)
  {
    if (
      !excludedAccounts[account].exists && // only for holders
      summary.totalRewards != 0
    ) {
      result = summary.totalRewards
        .mul(accountBalances[account])
        .div(summary.totalHolding);
    }

    return result;
  }

  function _calcTransferSenderFees(
    uint256 amount
  )
    private
    view
    returns (
      uint256 totalFee,
      uint256 burnFee,
      uint256 lpFee
    )
  {
    uint256 rewardsFee = amount.percent(settings.rewardsFees.sender);

    lpFee = amount.percent(settings.lpFees.sender);
    burnFee = amount.percent(settings.burnFees.sender);

    totalFee = lpFee.add(rewardsFee).add(burnFee);

    return (totalFee, burnFee, lpFee);
  }

  function _calcTransferRecipientFees(
    uint256 amount
  )
    private
    view
    returns (
      uint256 totalFee,
      uint256 burnFee,
      uint256 lpFee
    )
  {
    uint256 rewardsFee = amount.percent(settings.rewardsFees.recipient);

    lpFee = amount.percent(settings.lpFees.recipient);
    burnFee = amount.percent(settings.burnFees.recipient);

    totalFee = lpFee.add(rewardsFee).add(burnFee);

    return (totalFee, burnFee, lpFee);
  }

  // private functions (pure)

  function _verifyFees(
    Fees memory burnFees,
    Fees memory lpFees,
    Fees memory rewardsFees
  )
    private
    pure
  {
    uint256 totalFee = burnFees.sender.add(
      burnFees.recipient
    ).add(
      lpFees.sender.add(lpFees.recipient)
    ).add(
      rewardsFees.sender.add(rewardsFees.recipient)
    );

    require(
      totalFee <= MAX_FEE,
      "MetaheroToken#26" // the total fee is too high
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Controlled
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Controlled {
  /**
   * @return controller address
   */
  address public controller;

  // modifiers

  /**
   * @dev Throws if msg.sender is not the controller
   */
  modifier onlyController() {
    require(
      msg.sender == controller,
      "Controlled#1" // msg.sender is not the controller
    );

    _;
  }

  // events

  /**
   * @dev Emitted when the controller is updated
   * @param controller new controller address
   */
  event ControllerUpdated(
    address controller
  );

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    //
  }

  // internal functions

  function _initializeController(
    address controller_
  )
    internal
  {
    controller = controller_;
  }

  function _setController(
    address controller_
  )
    internal
  {
    require(
      controller_ != address(0),
      "Controlled#2" // controller is the zero address
    );

    require(
      controller_ != controller,
      "Controlled#3" // does not update the controller
    );

    controller = controller_;

    emit ControllerUpdated(
      controller_
    );
  }

  function _removeController()
    internal
  {
    require(
      controller != address(0),
      "Controlled#4" // controller is the zero address
    );

    controller = address(0);

    emit ControllerUpdated(
      address(0)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Owned
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Owned {
  /**
   * @return owner address
   */
  address public owner;

  // modifiers

  /**
   * @dev Throws if msg.sender is not the owner
   */
  modifier onlyOwner() {
    require(
      msg.sender == owner,
      "Owned#1" // msg.sender is not the owner
    );

    _;
  }

  // events

  /**
   * @dev Emitted when the owner is updated
   * @param owner new owner address
   */
  event OwnerUpdated(
    address owner
  );

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    owner = msg.sender;
  }

  // external functions

  /**
   * @notice Sets a new owner
   * @param owner_ owner address
   */
  function setOwner(
    address owner_
  )
    external
    onlyOwner
  {
    _setOwner(owner_);
  }

  // internal functions

  function _setOwner(
    address owner_
  )
    internal
  {
    require(
      owner_ != address(0),
      "Owned#2" // owner is the zero address
    );

    require(
      owner_ != owner,
      "Owned#3" // does not update the owner
    );

    owner = owner_;

    emit OwnerUpdated(
      owner_
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";


/**
 * @title ERC20 abstract token
 *
 * @author Stanisław Głogowski <[email protected]>
 */
abstract contract ERC20 is IERC20 {
  string public override name;
  string public override symbol;
  uint8 public override decimals;

  /**
   * @dev Internal constructor
   * @param name_ name
   * @param symbol_ symbol
   * @param decimals_ decimals amount
   */
  constructor (
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  )
    internal
  {
    name = name_;
    symbol = symbol_;
    decimals = decimals_;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./core/access/Lockable.sol";
import "./core/access/Owned.sol";
import "./core/lifecycle/Initializable.sol";
import "./core/math/SafeMathLib.sol";
import "./MetaheroToken.sol";


/**
 * @title Metahero abstract liquidity pool manager
 *
 * @author Stanisław Głogowski <[email protected]>
 */
abstract contract MetaheroLPM is Lockable, Owned, Initializable {
  using SafeMathLib for uint256;

  /**
   * @return token address
   */
  MetaheroToken public token;

  // modifiers

  /**
   * @dev Throws if msg.sender is not the token
   */
  modifier onlyToken() {
    require(
      msg.sender == address(token),
      "MetaheroLPM#1" // msg.sender is not the token
    );

    _;
  }

  // events

  /**
   * @dev Emitted when tokens from the liquidity pool are burned
   * @param amount burnt amount
   */
  event LPBurnt(
    uint256 amount
  );

  /**
   * @dev Internal constructor
   */
  constructor ()
    internal
    Lockable()
    Owned()
    Initializable()
  {
    //
  }

  // external functions

  /**
   * @notice Syncs liquidity pool
   */
  function syncLP()
    external
    onlyToken
    lock
  {
    _syncLP();
  }

  /**
   * @notice Burns tokens from the liquidity pool
   * @param amount tokens amount
   */
  function burnLP(
    uint256 amount
  )
    external
    onlyOwner
    lockOrThrowError
  {
    require(
      amount != 0,
      "MetaheroLPM#2" // amount is zero
    );

    _burnLP(amount);

    emit LPBurnt(
      amount
    );
  }

  // external functions (views)

  function canSyncLP(
    address sender,
    address recipient
  )
    external
    view
    virtual
    returns (
      bool shouldSyncLPBefore,
      bool shouldSyncLPAfter
    );

  // internal functions

  function _initialize(
    address token_
  )
    internal
  {
    require(
      token_ != address(0),
      "MetaheroLPM#3" // token is the zero address
    );

    token = MetaheroToken(token_);
  }

  function _syncLP()
    internal
    virtual;

  function _burnLP(
    uint256 amount
  )
    internal
    virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title ERC20 token interface
 *
 * @notice See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface IERC20 {
  // events

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  // external functions

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (bool);

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (bool);

  // external functions (views)

  function totalSupply()
    external
    view
    returns (uint256);

  function balanceOf(
    address owner
  )
    external
    view
    returns (uint256);

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (uint256);

  // external functions (pure)

  function name()
    external
    pure
    returns (string memory);

  function symbol()
    external
    pure
    returns (string memory);

  function decimals()
    external
    pure
    returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Lockable
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Lockable {
  /**
   * @return true when contract is locked
   */
  bool public locked;

  // modifiers


  /**
   * @dev Calls only when contract is unlocked
   */
  modifier lock() {
    if (!locked) {
      locked = true;

      _;

      locked = false;
    }
  }

  /**
   * @dev Throws if contract is locked
   */
  modifier lockOrThrowError() {
    require(
      !locked,
      "Lockable#1" // contract is locked
    );

    locked = true;

    _;

    locked = false;
  }

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    //
  }
}

