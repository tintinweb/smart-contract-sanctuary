pragma solidity ^0.8.0;

import "./interfaces/ILithiumPricing.sol";
import "./interfaces/ILithiumReward.sol";

/**
 * @title LithiumReward
 * Calculates the reward for a question answer.
 */
contract LithiumReward is ILithiumReward {
 
  ILithiumPricing lithiumPricing;

  constructor (address _pricingAddress) {
    lithiumPricing = ILithiumPricing(_pricingAddress);
  }
 
  function calculateReward(uint256 userStake,uint256 rewardAmount) internal pure returns (uint256) {
    return userStake * rewardAmount;
  }
  
  //get reward per answerGroup
  function getReward(
    uint256 _groupId,
    address _answerer
  ) external view override returns (
    uint256
  ) {

    ( address answerer,
      ,
      ,
      ,
      ,
      uint256 rewardAmount,
      
    ) = lithiumPricing.getAnswerGroup(_groupId, _answerer);
    
    require(answerer != address(0),"User haven't submit answer");
    uint256 rewardValue = rewardAmount;

    return rewardValue;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title The interface for LithiumPricing
 * @notice The LithiumPricing facilitates creating Questions and Giving Answer asynchronously
 *
 */
interface ILithiumPricing {

  /* Structs */

 
  struct Multihash {
    bytes32 digest;
    uint8 hashFunction;
    uint8 size;
  }

  /* events */

  event QuestionCreated (
    uint256 id,
    uint256 bounty,
    uint256 pricingTime,
    uint256 endTime,
    uint16 categoryId,
    address owner,
    string description,
    uint256[] answerSet,
    QuestionType questionType,
    uint256 startTime
  );

  event QuestionGroupCreated (
    uint256 id,
    address owner,
    uint256[] questionIds,
    uint16 minimumRequiredAnswers
  );

  event QuestionAnswered (
    uint256 questionId,
    address indexed answerer,
    uint256 stakeAmount,
    uint16 answerIndex
  );

  event AnswerGroupSetSubmitted (
  address answerer,
  uint256 questionSetId
);

  event MinimumStakeUpdated(uint256 minimumStake);

  event RewardClaimed(uint256 questionGroupId, address answerer, uint256 rewardAmount);

  event ReputationUpdated(address[] addressesToUpdate,uint256[] categoryIds,uint256[] reputationScores);

  event CategoryAdded(
    uint256 id,
    string label
  );

  event FinalAnswerCalculatedStatus(
    uint256 questionId,
    bytes32 digest,
    uint8 hashFunction,
    uint8 size,
    StatusCalculated answerStatus
  );

  event SetLithiumRewardAddress(
    address rewardAddress
  );

  event SetLithiumTokenAddress(
    address lithiumTokenAddress
  );

  event GroupRewardUpdated(address[] addressesToUpdate,uint256[] groupIds,uint256[] rewardAmounts);

  event BidReceived(uint256 questionId,address indexed bidder,uint256 bidAmount);

  event BidRefunded(uint256 questionId, address nodeAddress,uint256 refundAmount);

  event RevealTiersUpdated(uint16[] revealTiers);

  event QuestionAnswerAdded(
    uint256 questionId,
    bytes32 digest,
    uint8 hashFunction,
    uint8 size
  );

  /** Datatypes */
  enum AnswerStatus { Unclaimed, Claimed }
  //Invalid is for if answer can't be calculated
  enum StatusCalculated{NotCalculated, Calculated, Invalid}
  enum QuestionType{ Pricing, GroundTruth }
  /** Getter Functions */

 

  /**
    * @dev Returns an Answer.
    */
  function getAnswer (
    uint256 _questionId,
    address _answerer
  ) external view returns (
    address answerer,
    uint256 questionId,
    uint16 answerIndex,
    uint256 stakeAmount,
    AnswerStatus status
  );

 function getAnswerGroup (
    uint256 _groupId,
    address _answerer
  ) external view returns (
    address answerer,
    uint256 questionGroupId,
    uint16[] memory answerIndexes,
    uint256 stakeAmount,
    AnswerStatus status,
    uint256 rewardAmount,
    StatusCalculated isRewardCalculated
  ) ;
  
  function getAnswerSetTotals (
    uint256 questionId
  ) external view returns (
    uint256[] memory
  );

  function getAnswerSet (
    uint256 _questionId
  ) external view returns (
    uint256[] memory
  );

  function getRewardTotal (
    uint256 _questionId
  ) external view returns (
    uint256
  );

  function getRevealTiers (
  ) external view returns (
    uint16[] memory
  );


/* External Functions */

  function updateValidAnswerStatus(
    uint256[] memory  questionIds, 
    Multihash[] memory _answerHashes
  ) external;

  function updateInvalidAnswerStatus(
    uint256[] memory  questionIds
  ) external;

  function addAnswerHash(
    uint256[] memory  questionIds, 
    Multihash[] memory _answerHashes 
  ) external;

  function updateReputation(
    address[] memory addressesToUpdate,
    uint256[] memory categoryIds,
    uint256[] memory  reputationScores
  ) external;
  
  function updateMinimumStake (
    uint256 minimumStake
    )external;

  function updateGroupRewardAmounts(
    address[] memory addressesToUpdate,
    uint256[] memory groupIds, 
    uint256[] memory rewardAmounts
    ) external;


  
  function createQuestion (
    uint16 categoryId,
    uint256 bounty,
    uint256 pricingTime,
    uint256 endTime,
    QuestionType questionType,
    string memory description,
    uint256[] memory answerSet,
    uint256 startTime
  ) external;

  function createQuestionGroup (
    uint16[] memory categoryIds,
    uint256[] memory bounties,
    uint256[] memory pricingTimes,
    uint256[] memory endTimes,
    QuestionType[] memory questionTypes,
    string[] memory descriptions,
    uint256[][] memory answerSets,
    uint256[] memory startTimes,
    uint16 minimumRequiredAnswer
  ) external;

  function answerQuestions (
    uint256 questionGroupId,
    uint256[] memory stakeAmounts,
    uint16[] memory answerIndexes
  ) external;

  function claimRewards (
    uint256[] memory questionGroupIds
  ) external ;

  function increaseBid(
    uint256 questionId ,
    uint256 lithBidAmount
  ) external ;


  function refundBids (
    uint256[] memory questionIds,
    address[] memory nodeAddresses,
    uint256[] memory refundAmounts
  ) external ;

  function updateRevealTiers (
    uint16[] memory _revealTiers
  ) external;
}

pragma solidity ^0.8.0;

/**
 * @title LithiumReward
 * @notice Calculates the reward for a question answer.
 */
interface ILithiumReward {
 
  /** Getter Functions */
  
  function getReward (
    uint256 _questionId,
    address _answerer
  ) external view returns (
    uint256
  );

}