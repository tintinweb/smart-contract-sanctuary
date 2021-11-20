pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Roles.sol";
import "./interfaces/ILithiumPricing.sol";
import "./interfaces/ILithiumReward.sol";

/**
 * @title LithiumPricing
 */
contract LithiumPricing is ILithiumPricing,Initializable, Roles {

  struct Question {
    address owner; // question creator
    uint256 id; // uinique identifier
    uint256 categoryId; // related category id
    string description; // explanation of asset to price ex 'The price of LITH will be higher then'
    uint256[] answerSet; // the list of possible answers
    uint256[] answerSetTotalStaked; // the total staked for each answer
    uint256 bounty; // to bounty offered by the questions creator in LITH tokens
    uint256 totalStaked; // the sum of AnswerSetTotals in LITH token
    uint256 endTime; // the time answering ends relative to block.timestamp
    uint256 pricingTime;//Indicate when the asset should be priced for
    uint256 finalAnswerIndex;//Final answer index  of a question
    uint256 finalAnswerValue;//Final answer vaule of question 
    uint256 startTime; //startTime for answering question
    StatusCalculated isAnswerCalculated;//answer calculated status will be Updated by LithiumCordinator once deadline passed
    QuestionType questionType;//Type of a question can be one of two (Pricing  or  GroundTruth )
  }

  struct QuestionGroup {
    uint256 id;
    uint256[] questionIds;
    uint16 minimumRequiredAnswer;
  }

  struct Answer {
    address answerer; // the answer creator
    uint256 questionId; // the id of the question being answered
    uint256 stakeAmount; // the amount to stake in LITH token for the answer
    uint16 answerIndex; // the index of the chosen answer in the question.answerSet
    AnswerStatus status; // the status of the Answer, Unclaimed or Claimed
  }
  struct AnswerGroup {
    address answerer; // the answer creator
    uint256 questionGroupId; // the id of the questions being answered
    uint256[] stakeAmounts; // the amount to stake in LITH token for the answersSetsGroup
    uint16[] answerIndexes; // the index of the chosen answer in the question.answerSet
    uint256 rewardAmount;//reward rate can be negative,zero or positive
    AnswerStatus status; // the status of the AnswerSets, Unclaimed or Claimed
    StatusCalculated isRewardCalculated;//rewardcalculated status for answergroup
  }

  IERC20 LithiumToken;
  ILithiumReward lithiumReward;

  uint8 minAnswerSetLength ;
  uint8 maxAnswerSetLength ;

  bytes32[] public categories; 

  Question[] questions;
  QuestionGroup[] public questionGroups;

  struct QuestionBid{
    uint256 bidAmount;
    bool isBidRefunded;
  }

  //questionId -> nodeAddress -> QuestionBid
  mapping (uint256 => mapping (address => QuestionBid)) public questionBids;

  address constant public NULL_ADDRESS=address(0);

  // questionId => answerer => Answer
  mapping(uint256 => mapping(address => Answer)) public answers;

  // questionGroupId =>  answerer => AnswerGroup
  mapping(uint256=> mapping(address => AnswerGroup)) public answerGroups;

  mapping (address => mapping(uint256=>uint256)) userReputationScores;
  
  // minimumStake put by wisdom nodes when answering question
  uint256 public minimumStake;

  function initialize() public initializer override {
    Roles.initialize();
    _addCategory("preIPO");
    minAnswerSetLength = 2;
    maxAnswerSetLength = 2;
  }


    /**
    * @dev Checks if an answer set is valid
    *
    * A valid answer set must have at least one value greater than zero and
    * must be in ascending order
    * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
    *
    * Emits a {Sent} event.
    *
    * Requirements
    *
    * - the caller must have at least `amount` tokens.
    * - `recipient` cannot be the zero address.
    * - if `recipient` is a contract, it must implement the {IERC777Recipient}
    * interface.
    */
  function isValidAnswerSet(uint256[] memory answerSet) internal view {
    require(minAnswerSetLength <= answerSet.length && answerSet.length <= maxAnswerSetLength, "Answer Set length invalid");
    require(answerSet[0] == 0,"AnswerSets must starts with 0");
    for (uint256 i = 1; i < answerSet.length; i++) {
      require(answerSet[i] > answerSet[i-1], "Answers must be in ascending order");        
    }
  }

  // Get question data
  function getQuestion (
    uint256 _id
  ) external view  returns (
    Question memory
  ) {
    Question storage question = questions[_id];
    return question;
    }

  //Get questionIds from questionGroups

  function getQuestionIds(uint256 questiongroupId
   ) external view returns (uint256[] memory){
     return questionGroups[questiongroupId].questionIds;
   }

  //Get all data for question and about the answer  with questionId _id and answr submitter as _answerer
  function getAnswer (
    uint256 _questionId,
    address _answerer
  ) external view override returns (
    address answerer,
    uint256 questionId,
    uint16 answerIndex,
    uint256 stakeAmount,
    AnswerStatus status
  ) {
    Answer storage answer = answers[_questionId][_answerer];
    answerer = answer.answerer;
    questionId = answer.questionId;
    answerIndex = answer.answerIndex;
    stakeAmount = answer.stakeAmount;
    status = answer.status;
  }

    //Get all data for question and about the answer  with questionId _id and answr submitter as _answerer
  function getAnswerGroup (
    uint256 _groupId,
    address _answerer
  ) external view override returns (
    address answerer,
    uint256 questionGroupId,
    uint16[] memory answerIndexes,
    uint256 stakeAmount,
    AnswerStatus status,
    uint256 rewardAmount,
    StatusCalculated isRewardCalculated
  ) {
    AnswerGroup storage answerGroup  = answerGroups[_groupId][_answerer];
    for(uint256 i=0; i< answerGroup.stakeAmounts.length; i++){
      stakeAmount += answerGroup.stakeAmounts[i];
    }
    answerer = answerGroup.answerer;
    questionGroupId = answerGroup.questionGroupId;
    answerIndexes = answerGroup.answerIndexes;
    status = answerGroup.status;
    rewardAmount = answerGroup.rewardAmount;
    isRewardCalculated = answerGroup.isRewardCalculated;
  }

//get staked amount for Question with id _questionId
//Remember it will exclude the bounty that were offer by wisdom node
  function getAnswerSetTotals (
    uint256 questionId
  ) external view override returns (
    uint256[] memory
  ) {
    return questions[questionId].answerSetTotalStaked;
  }

  //Get all possible answer for a question with id _questionId

  function getAnswerSet (
    uint256 questionId
  ) external view override returns (
    uint256[] memory
  ) {
    return questions[questionId].answerSet;
  }

  //get total staked amount for Question group 
  //remember it include totalStakedLithToken +Bounty for question group

  function getRewardTotal (
    uint256 groupId
  ) external view override returns (
    uint256
  ) {
    uint256[] memory questionIds = questionGroups[groupId].questionIds;
    uint256 totalRewardPerGroup;
    for (uint256 i = 0; i < questionIds.length; i++) {
      Question storage question = questions[i];
      totalRewardPerGroup += question.bounty + question.totalStaked;
    }

    return totalRewardPerGroup;
  }

  //get reputation of a user  with user address user category id  categoryId 

  function getRepuation(address user,uint256 categoryId)public view returns(uint256){
    return userReputationScores[user][categoryId];
  }


    /**
  * @dev Adds new category
  *
  */
  function _addCategory(string memory _label) internal {
    bytes32 hash = keccak256(abi.encodePacked(_label));
    categories.push(hash);
    emit CategoryAdded(categories.length - 1,  _label);
  }


  /**
  * @dev Adds a Question to contract storage.
  * the `categoryId` is the id for the related category
  * the `bounty` is amount of tokens the questioner is offering for pricing information
  * the `description` is a description of the asset to price, ex 'The price of LITH token will be higher then'
  * the `endtime` is when all voting stops and votes are tallied and payouts become eligible relative to the block.timestamp
  * the `answerSet` is an array of values that represent equal to or greater than prices in usd
  *   Each answer except for the last represents the statement 'equal to or greather than the selected value and less than the next value in the array'
  *   with the last value representing the statement 'equal to or greater than the selected value'
  *   For example, an answerSet for the questions 'Will the price of the dow be greater or less than $35,000'
  *   would be [0,35000]
  *   An answerSet for the question 'Will the price of the dow be less then $35,000, between $35,000 and $37,000, or greater than $37,000'
  *   would be [0,35000,37000]
  *
  * Emits a { QuestionCreated } event.
  *
  * Requirements
  *
  * - the caller must have at least `bounty` tokens.
  * - the answer set must be valid (see isValidAnswerSet).
  * - the `endtime` must be in the future
  * - the category id must be valid
  */
  function _createQuestion(
    uint16 categoryId,
    uint256 bounty,
    uint256 pricingTime,
    uint256 endTime,
    QuestionType questionType,
    string memory description,
    uint256[] memory answerSet,
    uint256 startTime
  ) internal {
    require(endTime > block.timestamp, "Endtime must be in the future");
    require(startTime >= block.timestamp && startTime <= endTime , "startTime must be less than end time and current time");
    require(pricingTime > endTime,"Pricing time of asset must be greater than endtime");
    require(LithiumToken.balanceOf(msg.sender) >= bounty, "Insufficient balance");
    require(categories[categoryId] != 0, "Invalid categoryId");
    isValidAnswerSet(answerSet);

    LithiumToken.transferFrom(msg.sender, address(this), bounty);
    uint256 id = questions.length;
    uint256[] memory answerSetTotalStaked = new uint256[](answerSet.length);
    Question memory question;
    question.id = id;
    question.categoryId = categoryId;
    question.bounty = bounty;
    question.owner = msg.sender;
    question.description = description;
    question.answerSet = answerSet;
    question.answerSetTotalStaked = answerSetTotalStaked;
    question.endTime = endTime;
    question.pricingTime = pricingTime;
    question.questionType = questionType;
    question.startTime = startTime;
    questions.push(question);

    questionBids[id][msg.sender] = QuestionBid(bounty,false);

    emit QuestionCreated(
      id,
      bounty,
      pricingTime,
      endTime,
      categoryId,
      question.owner,
      description,
      answerSet, 
      questionType,
      startTime
    );
  }

   /**
  * @dev Adds an Answer to contract storage.
  * the `questionId` is the id of the question being answered
  * the `stakeAmount` is the amount of LITH the answerer wants to stake on the answer
  * and it will be added to totalStake for the question
  * and the answerSetTotal for the `answerIndex`
  * the `answerIndex` is the index of the answer in the question.answerSet
  *
  * Emits a { QuestionAnswered } event.
  *
  * Requirements
  *
  * - the caller must have at least `stakeAmount` tokens.
  * - `stakeAmount` must be greater than zero.
  * - the answerIndex must correspond to a valid answer(see isValidAnswerSet).
  * - the `endtime` must be in the future
  */
  function answerQuestion(
    uint256 _questionId,
    uint256 _stakeAmount,
    uint16 _answerIndex
  ) internal {
    require(_questionId < questions.length, "Invalid question id");
    Question storage question = questions[_questionId];
    require(question.startTime <= block.timestamp, "Answering question is not started yet");
    require(question.endTime > block.timestamp, "Question is not longer active");
    require(_answerIndex <= question.answerSet.length, "Invalid answer index");
    require(_stakeAmount >= minimumStake, "Stake amount must be greater than minimumStake");
    require(LithiumToken.balanceOf(msg.sender) >= _stakeAmount, "Insufficient balance");
    require(answers[_questionId][msg.sender].answerer == address(0) ,"User has already answered this question");
    LithiumToken.transferFrom(msg.sender, address(this), _stakeAmount);
    Answer memory answer;
    answer.answerer = msg.sender;
    answer.questionId = _questionId;
    answer.answerIndex = _answerIndex;
    answer.stakeAmount = _stakeAmount;
    answers[_questionId][msg.sender] = answer;
    question.totalStaked = question.totalStaked + _stakeAmount;
    question.answerSetTotalStaked[_answerIndex] = question.answerSetTotalStaked[_answerIndex] + _stakeAmount;
    emit QuestionAnswered(_questionId, msg.sender, _stakeAmount, _answerIndex);
  }

 /**
  * @dev Allow users to claim a reward for an questionGroup id
  * the `_questionGroupId` is the id of the questionGroup to claim the reward .
  * The reward amount is determined by the LithiumReward contract
  * Emits a { RewardClaimed } event.
  */

  function _claimReward (
    uint256 _questionGroupId
  ) internal returns(uint256 reward ){
    require(_questionGroupId < questionGroups.length, "Invalid question group id");
    AnswerGroup  storage answerGroup = answerGroups[_questionGroupId][msg.sender];
    require(answerGroup.status == AnswerStatus.Unclaimed, "Group Rewards have already been claimed");
    require(answerGroup.isRewardCalculated == StatusCalculated.Calculated,"Reward not calculated yet");
    reward = lithiumReward.getReward(_questionGroupId,msg.sender);
    if (reward > 0) {
      LithiumToken.transfer(msg.sender, reward);
    }
    answerGroup.status = AnswerStatus.Claimed;
    emit RewardClaimed(_questionGroupId, msg.sender, reward);
  }

  function _increaseBid(uint256 questionId,uint256 lithBidAmount) internal{
    require(questionId < questions.length, "Invalid question id");
    require(lithBidAmount > 0,"Bidding amount must be greater than 0");
    Question storage question = questions[questionId];
    require(question.startTime > block.timestamp, "Answering question time started ");
    question.bounty = question.bounty + lithBidAmount;
    QuestionBid storage questionBid = questionBids[questionId][msg.sender];
    questionBid.bidAmount = questionBid.bidAmount + lithBidAmount;
    emit BidReceived(questionId,msg.sender,lithBidAmount);
  }

  /**
  * @dev public interface to add a new category
  *
  * Requirements
  *
  * - the caller must be an admin.
  */
  function addCategory(string memory _label) public {
    require(isAdmin(msg.sender), "Must be admin");
    require(bytes(_label).length != 0, "Category label can't be null");
    _addCategory(_label);
  }

  /**
  * @dev Sets the address of the LithiumToken.
  *
  * Requirements
  *
  * - the caller must be an admin.
  */
  function setLithiumTokenAddress(address _tokenAddress) public {
    require(isAdmin(msg.sender), "Must be admin to set token address");
    require(_tokenAddress != NULL_ADDRESS,"Token Address can't be null");
    LithiumToken = IERC20(_tokenAddress);
    emit SetLithiumTokenAddress(address(LithiumToken));
  }

  /**
  * @dev Sets the address of the LithiumReward.
  *
  */
  function setLithiumRewardAddress(address _rewardAddress) public {
    require(isAdmin(msg.sender), "Must be admin to set token address");
    require(_rewardAddress != NULL_ADDRESS,"Reward Address can't be null");
    lithiumReward = ILithiumReward(_rewardAddress);
    emit SetLithiumRewardAddress(address(lithiumReward));
  }

 /**
  * @dev Allow Lithium Coordinator to submit final answer value and its index 
  * the `questionIds` is the  array of question id  
  * the `finalAnswerIndex` is the array  for final answer index of questionIds
  * the `finalAnswerValue` is the array  for final answer value of questionIds
  * Requirements
  *
  * - the caller must be admin of this contract
  * - endtime must be passed for all  question 
  * - the length of the array arguments must be equal
  * - rewards can't be updated again with same question id
  * - question id must be valid 
  */
  function updateFinalAnswerStatus(uint256[] memory questionIds, uint256[] memory finalAnswerIndexes,uint256[] memory finalAnswerValues, StatusCalculated[] memory answerStatuses)external override{
    require(isAdmin(msg.sender),"Must be admin");
    require(questionIds.length != 0, "question IDs length must be greater than zero");
    require(questionIds.length == finalAnswerIndexes.length && questionIds.length == finalAnswerValues.length && questionIds.length == answerStatuses.length,"argument array length mismatch"); 
    for(uint256 i=0;i< questionIds.length ;i++)
    {
    uint256 questionId = questionIds[i];
    require(questionId < questions.length, "Invalid question id");
    require(answerStatuses[i] != StatusCalculated.NotCalculated, "Not allowed to updated status  Notcalculated");
    Question storage question = questions[questionId];
    require(question.endTime <= block.timestamp, "Question is still active and Final Answer status can't be updated");
    require(question.isAnswerCalculated == StatusCalculated.NotCalculated,"Answer is already calculated");
    question.finalAnswerIndex = finalAnswerIndexes[i];
    question.finalAnswerValue = finalAnswerValues[i];
    question.isAnswerCalculated = answerStatuses[i];
    }
    emit FinalAnswerCalculatedStatus(questionIds,finalAnswerIndexes,finalAnswerValues,answerStatuses);
  }

   /**
  * @dev Allow Lithium Coordinator to update the reputation score of wisdom nodes
  * Emits a { ReputationUpdated } event.
  *
  * Requirements
  *
  * - the caller must be admin of this contract
  * - the length of the array arguments must be equal
  * - the categoryIds must all be valid
  */
  function updateReputation(address[] memory addressesToUpdate,uint256[] memory categoryIds,uint256[] memory  reputationScores) external  override{
    require(isAdmin(msg.sender), "Must be admin");
    require(addressesToUpdate.length != 0, "address length must be greater than zero");
    require(addressesToUpdate.length == categoryIds.length && categoryIds.length == reputationScores.length, "argument array length mismatch"); 
    for (uint256 i = 0; i < addressesToUpdate.length; i++) {
      require(categoryIds[i] < categories.length,"invalid categoryId");
      userReputationScores[addressesToUpdate[i]][categoryIds[i]] += reputationScores[i];
    }
    emit ReputationUpdated(addressesToUpdate,categoryIds,reputationScores);
  }

  /**
  * @dev Allow Lithium Coordinator to update the MinimumStake 
  * Emits a { MinimumStakeUpdated} event.
  *
  * Requirements
  *
  * - the caller must be admin of this contract
  */
  function updateMinimumStake(uint256 _minimumStake)external override {
    require(isAdmin(msg.sender), "Must be admin");
    minimumStake =_minimumStake;
    emit MinimumStakeUpdated(minimumStake);
  }


/**
  * @dev Allow Lithium Coordinator to update the answer group rewrads
  * the `addressesToUpdate` is the  array of wisdom node  addresses 
  * the `groupIds` is the array of answer group id for respective wisdom node address
  * the `rewardAmounts` is the array of final rewards for respective wisdom node address
  * Requirements
  *
  * - the caller must be admin of this contract
  * - the length of the array arguments must be equal
  * - answer must be calculated for groupids(all question id that belong in groupIds)
  * - rewards can't be updated again with same question id
  * - question id must be valid 
  */
  function updateGroupRewardAmounts(address[] memory addressesToUpdate,uint256[] memory groupIds, uint256[] memory rewardAmounts) external override{
    require(isAdmin(msg.sender), "Must be admin");
    require(addressesToUpdate.length == groupIds.length && addressesToUpdate.length == rewardAmounts.length,"Array mismatch");
    for (uint256 i = 0; i < groupIds.length; i++) {
      uint256[] memory questionIds = questionGroups[groupIds[i]].questionIds;
      for(uint256 j=0 ; j<questionIds.length ; j++){
         Question storage question = questions[questionIds[j]];
         require(question.isAnswerCalculated != StatusCalculated.NotCalculated,"Answer is not yet calculated");
      }
      AnswerGroup  storage answerGroup = answerGroups[groupIds[i]][addressesToUpdate[i]];
      require(answerGroup.answerer == addressesToUpdate[i] ,"Not valid answerer");
      answerGroup.rewardAmount = rewardAmounts[i];
      answerGroup.isRewardCalculated = StatusCalculated.Calculated;
    }
    emit GroupRewardUpdated(addressesToUpdate,groupIds,rewardAmounts);
  }

  /**
  * @dev external interface for _createQuestion method
  * the `categoryId` is the id for the related category
  * the `bounty` is amount of tokens the questioner is offering for pricing information
  * the `description` is a description of the asset to price, ex 'The price of LITH token will be higher then'
  * the `endtime` is when all voting stops and votes are tallied and payouts become eligible relative to the block.timestamp
  * the `answerSet` is an array of values that represent equal to or greater than prices in usd
  *   Each answer except for the last represents the statement 'equal to or greather than the selected value and less than the next value in the array'
  *   with the last value representing the statement 'equal to or greater than the selected value'
  *   For example, an answerSet for the questions 'Will the price of the dow be greater or less than $35,000'
  *   would be [0,35000]
  *   An answerSet for the question 'Will the price of the dow be less then $35,000, between $35,000 and $37,000, or greater than $37,000'
  *   would be [0,35000,37000]
  */
  function createQuestion(
    uint16 categoryId,
    uint256 bounty,
    uint256 pricingTime,
    uint256 endTime,
    QuestionType questionType,
    string memory description,
    uint256[] memory answerSet,
    uint256 startTime
  ) external override {
    require(isAdmin(msg.sender),"Must be Admin");
    _createQuestion(
      categoryId,
      bounty,
      pricingTime,
      endTime,
      questionType,
      description,
      answerSet,
      startTime
    );
  }

    /**
  * @dev Given an array of question values creates a Question for each one and a QuestionSet for the entire array
  *
  * Emits a { QuestionGroupCreated } event.
  *
  */
  function createQuestionGroup(
    uint16[] memory categoryIds,
    uint256[] memory bounties,
    uint256[] memory pricingTimes,
    uint256[] memory endTimes,
    QuestionType[] memory questionTypes,
    string[] memory descriptions,
    uint256[][] memory answerSets,
    uint256[] memory startTimes,
    uint16 minimumRequiredAnswer
  ) external override {
    require(isAdmin(msg.sender),"Must be Admin");
    require(
      categoryIds.length == bounties.length
      && categoryIds.length == pricingTimes.length
      && categoryIds.length == endTimes.length
      && categoryIds.length == questionTypes.length
      && categoryIds.length == descriptions.length
      && categoryIds.length == answerSets.length
      && categoryIds.length == startTimes.length,
      "Array mismatch");

    // get the pending id for the initial question in the set
    uint256 initialQuestionId = questions.length;
    uint256[] memory questionIds = new uint256[](categoryIds.length);

    for (uint256 i = 0; i < categoryIds.length; i++) {
      _createQuestion(
        categoryIds[i],
        bounties[i],
        pricingTimes[i],
        endTimes[i],
        questionTypes[i],
        descriptions[i],
        answerSets[i],
        startTimes[i]
      );
      questionIds[i] = initialQuestionId + i;
    }

    QuestionGroup memory questionGroup;
    questionGroup.id = questionGroups.length;
    questionGroup.questionIds = questionIds;
    questionGroup.minimumRequiredAnswer = minimumRequiredAnswer;
    questionGroups.push(questionGroup);

    emit QuestionGroupCreated(questionGroup.id, msg.sender, questionGroup.questionIds, questionGroup.minimumRequiredAnswer);
  }

  function answerQuestions (
    uint256 questionGroupId,
    uint256[] memory stakeAmounts,
    uint16[] memory answerIndexes
  ) external override {
    require(questionGroupId < questionGroups.length, "Invalid question group id");
    uint256[] memory questionIds = questionGroups[questionGroupId].questionIds;
    require(questionIds.length == stakeAmounts.length && questionIds.length == answerIndexes.length,"Array mismatch");
    for (uint256 i = 0; i < questionIds.length; i++) {
      answerQuestion(questionIds[i], stakeAmounts[i], answerIndexes[i]);
    }
    AnswerGroup memory answersGroup;
    answersGroup.answerer = msg.sender;
    answersGroup.questionGroupId = questionGroupId;
    answersGroup.answerIndexes = answerIndexes;
    answersGroup.stakeAmounts = stakeAmounts;
    answerGroups[questionGroupId][msg.sender] = answersGroup;
    emit AnswerGroupSetSubmitted(msg.sender,questionGroupId);
  }
 
  /**
  * @dev Allow users to claim rewards for answered questions
  * the `questionGroupIds` is the ids of the question groupss to claim the rewards for
  *
  * Requirements
  *
  * - the caller must have answered the questions
  */
  function claimRewards (
    uint256[] memory questionGroupIds
  ) external override {
    for (uint256 i = 0; i < questionGroupIds.length; i++) {
      _claimReward(questionGroupIds[i]);
    }
  }

  /**
  * @dev Allow users to increase bid amount on specific question id
  * the `questionId` is the ids of the questions  to increase bid on the question
  * with Bidding amount lithBidAmount
  *
  */

  function increaseBid( 
    uint256 questionId,
    uint256 lithBidAmount
  ) external override{
    LithiumToken.transferFrom(msg.sender, address(this), lithBidAmount);
    _increaseBid(questionId, lithBidAmount);
  }

  /**
  * @dev Allow admin to refund node address with reward amount for question id
  * the `questionIds` is the array of question id for which refund amount to be updated
  * the `nodeAddresses` is the addresses of node which they bid amount on getting answers
  * the `refundAmounts` is the array of refund amount with respect to nodeAddresses
  */

  function refundBids(
    uint256[] memory questionIds,
    address[] memory nodeAddresses,
    uint256[] memory refundAmounts
  ) external override{
    require(isAdmin(msg.sender), "Must be admin");
    require(questionIds.length == nodeAddresses.length && questionIds.length == refundAmounts.length ,"argument array length mismatch");
    require(nodeAddresses.length > 0,"There must be at least 1 node address will be refunded");
    for (uint256 i = 0; i < questionIds.length; i++) {
      Question storage question = questions[i];
      require(question.startTime <= block.timestamp, "Question starting time has not passed yet");
      QuestionBid storage questionBid = questionBids[questionIds[i]][nodeAddresses[i]];
      bool isRefunded = questionBid.isBidRefunded;
      require(!isRefunded,"Wsidom node already refunded");
      uint256 userBidAmount = questionBid.bidAmount;
      require(userBidAmount >= refundAmounts[i],"Refund amount is more  than user bid amount");
      questionBid.isBidRefunded = true;
      questionBid.bidAmount = userBidAmount - refundAmounts[i];
      question.bounty = question.bounty - refundAmounts[i];
      if(refundAmounts[i] > 0 ){
        LithiumToken.transfer(nodeAddresses[i],refundAmounts[i]);
      }
      emit BidRefunded(questionIds[i],nodeAddresses[i],refundAmounts[i]);
    }
  }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// contracts/Roles.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Roles is AccessControlUpgradeable {

    function initialize() public virtual initializer{
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isAdmin(address _addr) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _addr);
    }

    function grantAdminRole(address _addr) public {
        grantRole(DEFAULT_ADMIN_ROLE, _addr);
    }

    function revokeAdminRole(address _addr) public {
        revokeRole(DEFAULT_ADMIN_ROLE, _addr);
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
    uint256[] questionIds,
    uint256[] answerIndexes,
    uint256[] answerValues,
    StatusCalculated[] answerStatuses
  );

  event SetLithiumRewardAddress(
    address rewardAddress
  );

  event SetLithiumTokenAddress(
    address lithiumTokenAddress
  );

  event GroupRewardUpdated(address[] addressesToUpdate,uint256[] groupIds,uint256[] rewardAmounts);

  event BidReceived(uint256 questionId,address bidder,uint256 bidAmount);

  event BidRefunded(uint256 questionId, address nodeAddress,uint256 refundAmount);

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


/* External Functions */

  function updateFinalAnswerStatus(
   uint256[] memory questionIds, 
   uint256[] memory finalAnswerIndexes,
   uint256[] memory finalAnswerValues,
   StatusCalculated[] memory answerStatuses
    )external;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}