pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import './../interfaces/ICompetition.sol';
import './../interfaces/IToken.sol';
import './CompetitionStorage.sol';
import './AccessControlRci.sol';
import './standard/proxy/utils/Initializable.sol';

/**
 * @title RCI Tournament(Competition) Contract
 * @author Rocket Capital Investment Pte Ltd
 * @dev This contract manages registration and reward payouts for the RCI Tournament.
 * @dev IPFS hash format: Hash Identifier (2 bytes), Actual Hash (May eventually take on other formats but currently 32 bytes)
 *
 */
contract Competition is AccessControlRci, ICompetition, CompetitionStorage, Initializable {

    constructor(){}

    function initialize(uint256 stakeThreshold_, uint256 rewardsThreshold_, address tokenAddress_)
    external
    initializer
    {
        require(tokenAddress_ != address(0), "No token address found.");
        _initializeRciAdmin();
        _stakeThreshold = stakeThreshold_;
        _rewardsThreshold = rewardsThreshold_;
        _token = IToken(tokenAddress_);
        _challengeCounter = 0;
        _challenges[_challengeCounter].phase = 4;
        _challengeRewardsPercentageInWei = 20e16;
        _tournamentRewardsPercentageInWei = 60e16;
    }

    /**
    PARTICIPANT WRITE METHODS
    **/

    function increaseStake(address staker, uint256 amountToken)
    external override
    returns (bool success)
    {
        uint32 challengeNumber = _challengeCounter;
        require(msg.sender == address(_token), "Competition - increaseStake: Please call this function via the token contract.");
        require(_challenges[challengeNumber].phase != 2, "Competition - increaseStake: Please wait for the staking period to unlock before modifying your stake.");

        uint256 currentBal = _stakes[staker];
        if (_challenges[challengeNumber].submitterInfo[staker].submission != bytes32(0)){
            _challenges[challengeNumber].submitterInfo[staker].staked = currentBal + amountToken;
        }

        _stakes[staker] = currentBal + amountToken;
        _currentTotalStaked += amountToken;

        success = true;

        emit StakeIncreased(staker, amountToken);
    }

    function decreaseStake(address staker, uint256 amountToken)
    external override
    returns (bool success)
    {
        uint32 challengeNumber = _challengeCounter;
        require(msg.sender == address(_token), "Competition - decreaseStake: Please call this function via the token contract.");
        require(_challenges[_challengeCounter].phase != 2, "Competition - decreaseStake: Please wait for the staking period to unlock before modifying your stake.");

        uint256 currentBal = _stakes[staker];
        require(amountToken <= currentBal, "Competition - decreaseStake: Insufficient funds for withdrawal.");

        if (_challenges[challengeNumber].submitterInfo[staker].submission != bytes32(0)){
            require((currentBal - amountToken) >= _stakeThreshold, "Competition - decreaseStake: You may not lower your stake below the threshold while you have an existing submission.");
            _challenges[challengeNumber].submitterInfo[staker].staked = currentBal - amountToken;
        }

        _stakes[staker] = currentBal - amountToken;
        _currentTotalStaked -= amountToken;
        success = _token.transfer(staker, amountToken);

        emit StakeDecreased(staker, amountToken);
    }

    function submitNewPredictions(bytes32 submissionHash)
    external override
    returns (uint32 challengeNumber)
    {
        uint256 currentBal = _stakes[msg.sender];
        require(currentBal >= _stakeThreshold, "Competition - submitNewPredictions: Stake is below threshold.");
        challengeNumber = _updateSubmission(bytes32(0), submissionHash);
        EnumerableSet.add(_challenges[challengeNumber].submitters, msg.sender);
        _challenges[challengeNumber].submitterInfo[msg.sender].staked = currentBal;
    }

    function updateSubmission(bytes32 oldSubmissionHash, bytes32 newSubmissionHash)
    external override
    returns (uint32 challengeNumber)
    {
        require(oldSubmissionHash != bytes32(0), "Competition - updateSubmission: Must have pre-existing submission.");
        challengeNumber = _updateSubmission(oldSubmissionHash, newSubmissionHash);

        if (newSubmissionHash == bytes32(0)){
            EnumerableSet.remove(_challenges[challengeNumber].submitters, msg.sender);
            _challenges[challengeNumber].submitterInfo[msg.sender].staked = 0;
        }
    }

    function _updateSubmission(bytes32 oldSubmissionHash, bytes32 newSubmissionHash)
    private
    returns (uint32 challengeNumber)
    {
        challengeNumber = _challengeCounter;
        require(_challenges[challengeNumber].phase == 1, "Competition - updateSubmission: Not available for submissions.");
        require(oldSubmissionHash != newSubmissionHash, "Competition - updateSubmission: Cannot update with the same hash as before.");
        require(_challenges[challengeNumber].submitterInfo[msg.sender].submission == oldSubmissionHash,
                "Competition - updateSubmission: Clash in existing submission hash.");
        _challenges[challengeNumber].submitterInfo[msg.sender].submission = newSubmissionHash;

        emit SubmissionUpdated(challengeNumber, msg.sender, newSubmissionHash);
    }

    /**
    ORGANIZER WRITE METHODS
    **/
    function updateMessage(string calldata newMessage)
    external override onlyAdmin
    returns (bool success)
    {
        _message = newMessage;
        success = true;

        emit MessageUpdated();
    }

    function updateDeadlines(uint32 challengeNumber, uint256 index, uint256 timestamp)
    external override onlyAdmin
    returns (bool success)
    {
        success = _updateDeadlines(challengeNumber, index, timestamp);
    }

    function _updateDeadlines(uint32 challengeNumber, uint256 index, uint256 timestamp)
    private
    returns (bool success)
    {
        _challenges[challengeNumber].deadlines[index] = timestamp;
        success = true;
    }

    function updateRewardsThreshold(uint256 newThreshold)
    external override onlyAdmin
    returns (bool success)
    {
        _rewardsThreshold = newThreshold;
        success = true;

        emit RewardsThresholdUpdated(newThreshold);
    }

    function updateStakeThreshold(uint256 newStakeThreshold)
    external override onlyAdmin
    returns (bool success)
    {
        _stakeThreshold = newStakeThreshold;
        success = true;

        emit StakeThresholdUpdated(newStakeThreshold);
    }

    function updateChallengeRewardsPercentageInWei(uint256 newPercentage)
    external override onlyAdmin
    returns (bool success)
    {
        _challengeRewardsPercentageInWei = newPercentage;
        success = true;

        emit ChallengeRewardsPercentageInWeiUpdated(newPercentage);
    }

    function updateTournamentRewardsPercentageInWei(uint256 newPercentage)
    external override onlyAdmin
    returns (bool success)
    {
        _tournamentRewardsPercentageInWei = newPercentage;
        success = true;

        emit TournamentRewardsPercentageInWeiUpdated(newPercentage);
    }


    function updatePrivateKey(uint32 challengeNumber, bytes32 newKeyHash)
    external override onlyAdmin
    returns (bool success)
    {
        _challenges[challengeNumber].privateKey = newKeyHash;
        success = true;

        emit PrivateKeyUpdated(newKeyHash);
    }

    function openChallenge(bytes32 datasetHash, bytes32 keyHash, uint256 submissionCloseDeadline, uint256 nextChallengeDeadline)
    external override onlyAdmin
    returns (bool success)
    {
        uint32 challengeNumber = _challengeCounter;
        require(_challenges[challengeNumber].phase == 4, "Competition - openChallenge: Previous phase is incomplete.");
        require(_competitionPool >= _rewardsThreshold, "Competiton - openChallenge: Not enough rewards.");

        challengeNumber++;

        _challenges[challengeNumber].phase = 1;
        _challengeCounter = challengeNumber;

        _updateDataset(challengeNumber, bytes32(0), datasetHash);
        _updateKey(challengeNumber, bytes32(0), keyHash);

        _currentChallengeRewardsBudget = _competitionPool * _challengeRewardsPercentageInWei/(1e18);
        _currentTournamentRewardsBudget = _competitionPool * _tournamentRewardsPercentageInWei/(1e18);
        _currentStakingRewardsBudget = _competitionPool - _currentChallengeRewardsBudget - _currentTournamentRewardsBudget;

        _updateDeadlines(challengeNumber, 0, submissionCloseDeadline);
        _updateDeadlines(challengeNumber, 1, nextChallengeDeadline);

        success = true;

        emit ChallengeOpened(challengeNumber);
    }

    function updateDataset(bytes32 oldDatasetHash, bytes32 newDatasetHash)
    external override onlyAdmin
    returns (bool success)
    {
        uint32 challengeNumber = _challengeCounter;
        require(_challenges[challengeNumber].phase == 1, "Competition - updateDataset: Challenge is closed.");
        require(oldDatasetHash != bytes32(0), "Competition - updateDataset: Must have pre-existing dataset.");
        success = _updateDataset(challengeNumber, oldDatasetHash, newDatasetHash);
    }

    function updateKey(bytes32 oldKeyHash, bytes32 newKeyHash)
    external override onlyAdmin
    returns (bool success)
    {
        uint32 challengeNumber = _challengeCounter;
        require(_challenges[challengeNumber].phase == 1, "Competition - updateKey: Challenge is closed.");
        require(oldKeyHash != bytes32(0), "Competition - updateKey: Must have pre-existing key.");
        success = _updateKey(challengeNumber, oldKeyHash, newKeyHash);
    }

    function _updateDataset(uint32 challengeNumber, bytes32 oldDatasetHash, bytes32 newDatasetHash)
    private
    returns (bool success)
    {
        require(oldDatasetHash != newDatasetHash, "Competition - updateDataset: Cannot update with the same hash as before.");
        require(_challenges[challengeNumber].dataset == oldDatasetHash, "Competition - updateDataset: Incorrect old dataset reference.");
        _challenges[challengeNumber].dataset = newDatasetHash;
        success = true;

        emit DatasetUpdated(challengeNumber, oldDatasetHash, newDatasetHash);
    }

    function _updateKey(uint32 challengeNumber, bytes32 oldKeyHash, bytes32 newKeyHash)
    private
    returns (bool success)
    {
        require(oldKeyHash != newKeyHash, "Competition - _updateKey: Cannot update with the same hash as before.");
        require(_challenges[challengeNumber].key == oldKeyHash, "Competition - _updateKey: Incorrect old key reference.");
        _challenges[challengeNumber].key = newKeyHash;
        success = true;

        emit KeyUpdated(challengeNumber, oldKeyHash, newKeyHash);
    }

    function closeSubmission()
    external override onlyAdmin
    returns (bool success)
    {
        uint32 challengeNumber = _challengeCounter;
        require(_challenges[challengeNumber].phase == 1, "Competition - closeSubmission: Challenge in unexpected state.");
        _challenges[challengeNumber].phase = 2;
        success = true;

        emit SubmissionClosed(challengeNumber);
    }

    function submitResults(bytes32 resultsHash)
    external override onlyAdmin
    returns (bool success)
    {
        success = _updateResults(bytes32(0), resultsHash);
    }

    function updateResults(bytes32 oldResultsHash, bytes32 newResultsHash)
    external override onlyAdmin
    returns (bool success)
    {
        require(oldResultsHash != bytes32(0), "Competition - updateResults: Must have pre-existing results.");
        success = _updateResults(oldResultsHash, newResultsHash);
    }

    function _updateResults(bytes32 oldResultsHash, bytes32 newResultsHash)
    private
    returns (bool success)
    {
        require(oldResultsHash != newResultsHash, "Competition - updateResults: Cannot update with the same hash as before.");
        uint32 challengeNumber = _challengeCounter;
        require(_challenges[challengeNumber].phase >= 3, "Competition - updateResults: Challenge in unexpected state.");
        require(_challenges[challengeNumber].results == oldResultsHash, "Competition - updateResults: Clash in existing results hash.");
        _challenges[challengeNumber].results = newResultsHash;
        success = true;

        emit ResultsUpdated(challengeNumber, oldResultsHash, newResultsHash);
    }

    function payRewards(address[] calldata submitters, uint256[] calldata stakingRewards, uint256[] calldata challengeRewards, uint256[] calldata tournamentRewards)
    external override onlyAdmin
    returns (bool success)
    {
        success = _payRewards(_challengeCounter, submitters, stakingRewards, challengeRewards, tournamentRewards);
    }

    function _payRewards(uint32 challengeNumber, address[] calldata submitters, uint256[] calldata stakingRewards, uint256[] calldata challengeRewards, uint256[] calldata tournamentRewards)
    private
    returns (bool success)
    {
        require(_challenges[challengeNumber].phase >= 3, "Competition - payRewards: Challenge is in unexpected state.");
        require((submitters.length == stakingRewards.length) &&
            (submitters.length == challengeRewards.length) &&
            (submitters.length == tournamentRewards.length),
            "Competition - payRewards: Number of submitters and rewards are different.");

        uint256 totalStakingAmount;
        uint256 totalChallengeAmount;
        uint256 totalTournamentAmount;

        for (uint i = 0; i < submitters.length; i++)
        {
            // read directly from the list since the list is already in memory(calldata), and to avoid stack too deep errors.
            totalStakingAmount += stakingRewards[i];
            totalChallengeAmount += challengeRewards[i];
            totalTournamentAmount += tournamentRewards[i];

            _paySingleAddress(challengeNumber, submitters[i], stakingRewards[i], challengeRewards[i], tournamentRewards[i]);
        }

        // allow for reverting on underflow
        _currentStakingRewardsBudget -= totalStakingAmount;
        _currentChallengeRewardsBudget -= totalChallengeAmount;
        _currentTournamentRewardsBudget -= totalTournamentAmount;

        _competitionPool -= totalStakingAmount + totalChallengeAmount + totalTournamentAmount;
        _currentTotalStaked += totalStakingAmount + totalChallengeAmount + totalTournamentAmount;
        success = true;

        _logRewardsPaid(challengeNumber, totalStakingAmount, totalChallengeAmount, totalTournamentAmount);
    }

    function _paySingleAddress(uint32 challengeNumber, address submitter, uint256 stakingReward, uint256 challengeReward, uint256 tournamentReward)
    private
    {
        _stakes[submitter] += stakingReward + challengeReward + tournamentReward;

        if (stakingReward > 0){
            _challenges[challengeNumber].submitterInfo[submitter].stakingRewards += stakingReward;
        }

        if (challengeReward > 0){
            _challenges[challengeNumber].submitterInfo[submitter].challengeRewards += challengeReward;
        }

        if (tournamentReward > 0){
            _challenges[challengeNumber].submitterInfo[submitter].tournamentRewards += tournamentReward;
        }

        emit RewardsPayment(challengeNumber, submitter, stakingReward, challengeReward, tournamentReward);
    }

    function _logRewardsPaid(uint32 challengeNumber, uint256 totalStakingAmount, uint256 totalChallengeAmount, uint256 totalTournamentAmount)
    private
    {
        emit TotalRewardsPaid(challengeNumber, totalStakingAmount, totalChallengeAmount, totalTournamentAmount);
    }

    function updateChallengeAndTournamentScores(uint32 challengeNumber, address[] calldata participants, uint256[] calldata challengeScores, uint256[] calldata tournamentScores)
    external override onlyAdmin
    returns (bool success)
    {
        require(_challenges[challengeNumber].phase >= 3, "Competition - updateChallengeAndTournamentScores: Challenge is in unexpected state.");
        require((participants.length == challengeScores.length) && (participants.length == tournamentScores.length), "Competition - updateChallengeAndTournamentScores: Number of participants and scores are different.");

        for (uint i = 0; i < participants.length; i++)
        {
        // read directly from the list since the list is already in memory(calldata), and to avoid stack too deep errors.

            _challenges[challengeNumber].submitterInfo[participants[i]].challengeScores = challengeScores[i];
            _challenges[challengeNumber].submitterInfo[participants[i]].tournamentScores = tournamentScores[i];
        }

        success = true;

        emit ChallengeAndTournamentScoresUpdated(challengeNumber);
    }

    function updateInformationBatch(uint32 challengeNumber, address[] calldata participants, uint256 itemNumber, uint[] calldata values)
    external override onlyAdmin
    returns (bool success)
    {
        require(_challenges[challengeNumber].phase >= 3, "Competition - updateInformationBatch: Challenge is in unexpected state.");
        require(participants.length == values.length, "Competition - updateInformationBatch: Number of participants and values are different.");

        for (uint i = 0; i < participants.length; i++)
        {
            _challenges[challengeNumber].submitterInfo[participants[i]].info[itemNumber] = values[i];
        }
        success = true;

        emit BatchInformationUpdated(challengeNumber, itemNumber);
    }

    function advanceToPhase(uint8 phase)
    external override onlyAdmin
    returns (bool success)
    {
        uint32 challengeNumber = _challengeCounter;
        require((2 < phase) && (phase < 5), "Competition - advanceToPhase: You may only use this method for advancing to phases 3 or 4." );
        require((phase-1) == _challenges[challengeNumber].phase, "Competition - advanceToPhase: You may only advance to the next phase.");
        _challenges[challengeNumber].phase = phase;

        success = true;
    }

    function moveRemainderToPool()
    external override onlyAdmin
    returns (bool success)
    {
        require(_challenges[_challengeCounter].phase == 4, "Competition - moveRemainderToPool: PLease wait for the challenge to complete before sponsoring.");
        uint256 remainder = getRemainder();
        require(remainder > 0, "Competition - moveRemainderToPool: No remainder to move.");
        _competitionPool += remainder;
        success = true;

        emit RemainderMovedToPool(remainder);
    }

    /**
    READ METHODS
    **/

    function getCompetitionPool()
    view external override
    returns (uint256 competitionPool)
    {
        competitionPool = _competitionPool;
    }

    function getRewardsThreshold()
    view external override
    returns (uint256 rewardsThreshold)
    {
        rewardsThreshold = _rewardsThreshold;
    }

    function getCurrentTotalStaked()
    view external override
    returns (uint256 currentTotalStaked)
    {
        currentTotalStaked = _currentTotalStaked;
    }

    function getCurrentStakingRewardsBudget()
    view external override
    returns (uint256 currentStakingRewardsBudget)
    {
        currentStakingRewardsBudget = _currentStakingRewardsBudget;
    }

    function getCurrentChallengeRewardsBudget()
    view external override
    returns (uint256 currentChallengeRewardsBudget)
    {
        currentChallengeRewardsBudget = _currentChallengeRewardsBudget;
    }

    function getCurrentTournamentRewardsBudget()
    view external override
    returns (uint256 currentTournamentRewardsBudget)
    {
        currentTournamentRewardsBudget = _currentTournamentRewardsBudget;
    }

    function getChallengeRewardsPercentageInWei()
    view external override
    returns (uint256 challengeRewardsPercentageInWei)
    {
        challengeRewardsPercentageInWei = _challengeRewardsPercentageInWei;
    }

    function getTournamentRewardsPercentageInWei()
    view external override
    returns (uint256 tournamentRewardsPercentageInWei)
    {
        tournamentRewardsPercentageInWei = _tournamentRewardsPercentageInWei;
    }

    function getLatestChallengeNumber()
    view external override
    returns (uint32 latestChallengeNumber)
    {
        latestChallengeNumber = _challengeCounter;
    }

    function getDatasetHash(uint32 challengeNumber)
    view external override
    returns (bytes32 dataset)
    {
        dataset = _challenges[challengeNumber].dataset;
    }

    function getResultsHash(uint32 challengeNumber)
    view external override
    returns (bytes32 results)
    {
        results = _challenges[challengeNumber].results;
    }

    function getKeyHash(uint32 challengeNumber)
    view external override
    returns (bytes32 key)
    {
        key = _challenges[challengeNumber].key;
    }

    function getPrivateKeyHash(uint32 challengeNumber)
    view external override
    returns (bytes32 privateKey)
    {
        privateKey = _challenges[challengeNumber].privateKey;
    }

    function getSubmissionCounter(uint32 challengeNumber)
    view external override
    returns (uint256 submissionCounter)
    {
        submissionCounter = EnumerableSet.length(_challenges[challengeNumber].submitters);
    }

    function getSubmitters(uint32 challengeNumber, uint256 startIndex, uint256 endIndex)
    view external override
    returns (address[] memory)
    {
        address[] memory submitters = new address[](endIndex - startIndex);
        EnumerableSet.AddressSet storage submittersSet = _challenges[challengeNumber].submitters;
        for (uint i = startIndex; i < endIndex; i++) {
            submitters[i - startIndex] = (EnumerableSet.at(submittersSet, i));
        }

        return submitters;
    }

    function getPhase(uint32 challengeNumber)
    view external override
    returns (uint8 phase)
    {
        phase = _challenges[challengeNumber].phase;
    }

    function getStakeThreshold()
    view external override
    returns (uint256 stakeThreshold)
    {
        stakeThreshold = _stakeThreshold;
    }

    function getStake(address participant)
    view external override
    returns (uint256 stake)
    {
        stake = _stakes[participant];
    }

    function getTokenAddress()
    view external override
    returns (address tokenAddress)
    {
        tokenAddress = address(_token);
    }

    function getSubmission(uint32 challengeNumber, address participant)
    view external override
    returns (bytes32 submissionHash)
    {
        submissionHash = _challenges[challengeNumber].submitterInfo[participant].submission;
    }

    function getStakedAmountForChallenge(uint32 challengeNumber, address participant)
    view external override
    returns (uint256 staked)
    {
        staked = _challenges[challengeNumber].submitterInfo[participant].staked;
    }

    function getStakingRewards(uint32 challengeNumber, address participant)
    view external override
    returns (uint256 stakingRewards)
    {
        stakingRewards = _challenges[challengeNumber].submitterInfo[participant].stakingRewards;
    }

    function getChallengeRewards(uint32 challengeNumber, address participant)
    view external override
    returns (uint256 challengeRewards)
    {
        challengeRewards = _challenges[challengeNumber].submitterInfo[participant].challengeRewards;
    }

    function getTournamentRewards(uint32 challengeNumber, address participant)
    view external override
    returns (uint256 tournamentRewards)
    {
        tournamentRewards = _challenges[challengeNumber].submitterInfo[participant].tournamentRewards;
    }

    function getOverallRewards(uint32 challengeNumber, address participant)
    view external override
    returns (uint256 overallRewards)
    {
        overallRewards =
        _challenges[challengeNumber].submitterInfo[participant].stakingRewards
        + _challenges[challengeNumber].submitterInfo[participant].challengeRewards
        + _challenges[challengeNumber].submitterInfo[participant].tournamentRewards;
    }

    function getChallengeScores(uint32 challengeNumber, address participant)
    view external override
    returns (uint256 challengeScores)
    {
        challengeScores = _challenges[challengeNumber].submitterInfo[participant].challengeScores;
    }

    function getTournamentScores(uint32 challengeNumber, address participant)
    view external override
    returns (uint256 tournamentScores)
    {
        tournamentScores = _challenges[challengeNumber].submitterInfo[participant].tournamentScores;
    }

    function getInformation(uint32 challengeNumber, address participant, uint256 itemNumber)
    view external override
    returns (uint value)
    {
        value = _challenges[challengeNumber].submitterInfo[participant].info[itemNumber];
    }

    function getDeadlines(uint32 challengeNumber, uint256 index)
    external view override
    returns (uint256 deadline)
    {
        deadline = _challenges[challengeNumber].deadlines[index];
    }

    function getRemainder()
    public view override
    returns (uint256 remainder)
    {
        remainder = _token.balanceOf(address(this)) - _currentTotalStaked - _competitionPool;
    }

    function getMessage()
    external view override
    returns (string memory message)
    {
        message = _message;
    }

    /**
    METHODS CALLABLE BY BOTH ADMIN AND PARTICIPANTS.
    **/

    function sponsor(uint256 amountToken)
    external override
    returns (bool success)
    {
        require(_challenges[_challengeCounter].phase == 4, "Competition - sponsor: PLease wait for the challenge to complete before sponsoring.");
        uint256 currentCompPoolAmt = _competitionPool;
        _competitionPool = currentCompPoolAmt + amountToken;
        success = _token.transferFrom(msg.sender, address(this), amountToken);

        emit Sponsor(msg.sender, amountToken, currentCompPoolAmt + amountToken);
    }
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

interface ICompetition{


    /**
    PARTICIPANT WRITE METHODS
    **/

    /**
    * @dev Called by anyone ONLY VIA THE ERC20 TOKEN CONTRACT to increase their stake.
    * @param staker The address of the staker that wants to increase their stake.
    * @param amountToken The amount to add to their stake.
    * @return success True if the operation completed successfully.
    **/
    function increaseStake(address staker, uint256 amountToken) external returns (bool success);

    /**
    * @dev Called by anyone ONLY VIA THE ERC20 TOKEN CONTRACT to decrease their stake.
    * @param staker The address of the staker that wants to withdraw their stake.
    * @param amountToken Number of tokens to withdraw.
    * @return success True if the operation completed successfully.
    **/
    function decreaseStake(address staker, uint256 amountToken) external returns (bool success);

    /**
    * @dev Called by participant to make a new prediction submission for the current challenge.
    * @dev Will be successful if the participant's stake is above the staking threshold.
    * @param submissionHash IPFS reference hash of submission. This is the IPFS CID less the 1220 prefix.
    * @return challengeNumber Challenge that this submission was made for.
    **/
    function submitNewPredictions(bytes32 submissionHash) external returns (uint32 challengeNumber);

    /**
    * @dev Called by participant to modify prediction submission for the current challenge.
    * @param oldSubmissionHash IPFS reference hash of previous submission. This is the IPFS CID less the 1220 prefix.
    * @param newSubmissionHash IPFS reference hash of new submission. This is the IPFS CID less the 1220 prefix.
    * @return challengeNumber Challenge that this submission was made for.
    **/
    function updateSubmission(bytes32 oldSubmissionHash, bytes32 newSubmissionHash) external returns (uint32 challengeNumber);

    /**
    ORGANIZER WRITE METHODS
    **/

    /**
    * @dev Called only by authorized admin to update the current broadcast message.
    * @param newMessage New broadcast message.
    * @return success True if the operation completed successfully.
    **/
    function updateMessage(string calldata newMessage) external  returns (bool success);

    /**
    * @dev Called only by authorized admin to update one of the deadlines for this challenge.
    * @param challengeNumber Challenge to perform the update for.
    * @param index Deadline index to update.
    * @param timestamp Deadline timestamp in milliseconds.
    * @return success True if the operation completed successfully.
    **/
    function updateDeadlines(uint32 challengeNumber, uint256 index, uint256 timestamp) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the minimum amount required in the competition rewards pool to open a new challenge.
    * @param newThreshold New minimum amount for opening new challenge.
    * @return success True if the operation completed successfully.
    **/
    function updateRewardsThreshold(uint256 newThreshold) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the minimum stake amount required to take part in the competition.
    * @param newStakeThreshold New stake threshold amount in wei.
    * @return success True if the operation completed successfully.
    **/
    function updateStakeThreshold(uint256 newStakeThreshold) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the percentage of the competition rewards pool allocated to the challenge rewards budget.
    * @param newPercentage New percentage amount in wei.
    * @return success True if the operation completed successfully.
    **/
    function updateChallengeRewardsPercentageInWei(uint256 newPercentage) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the percentage of the competition rewards pool allocated to the tournament rewards budget.
    * @param newPercentage New percentage amount in wei.
    * @return success True if the operation completed successfully.
    **/
    function updateTournamentRewardsPercentageInWei(uint256 newPercentage) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the private key for this challenge. This should be done at the end of the challenge.
    * @param challengeNumber Challenge to perform the update for.
    * @param newKeyHash IPFS reference cid where private key is stored.
    * @return success True if the operation completed successfully.
    **/
    function updatePrivateKey(uint32 challengeNumber, bytes32 newKeyHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to start allowing staking for a new challenge.
    * @param datasetHash IPFS reference hash where dataset for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param keyHash IPFS reference hash where the key for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param submissionCloseDeadline Timestamp of the time where submissions will be closed.
    * @param nextChallengeDeadline Timestamp where ths challenge will be closed and the next challenge opened.
    * @return success True if the operation completed successfully.
    **/
    function openChallenge(bytes32 datasetHash, bytes32 keyHash, uint256 submissionCloseDeadline, uint256 nextChallengeDeadline) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the IPFS reference for the dataset of a particular challenge.
    * @param oldDatasetHash IPFS reference hash where previous dataset for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param newDatasetHash IPFS reference hash where new dataset for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function updateDataset(bytes32 oldDatasetHash, bytes32 newDatasetHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the IPFS reference for the key of a particular challenge.
    * @param oldKeyHash IPFS reference hash where previous key for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param newKeyHash IPFS reference hash where new key for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function updateKey(bytes32 oldKeyHash, bytes32 newKeyHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to stop allowing submissions for a particular challenge.
    * @return success True if the operation completed successfully.
    **/
    function closeSubmission() external returns (bool success);

    /**
    * @dev Called only by authorized admin to submit the IPFS reference for the results of a particular challenge.
    * @param resultsHash IPFS reference hash where results for this challenge are stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function submitResults(bytes32 resultsHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the IPFS reference for the results of the current challenge.
    * @param oldResultsHash IPFS reference hash where previous results for this challenge are stored. This is the IPFS CID less the 1220 prefix.
    * @param newResultsHash IPFS reference hash where new results for this challenge are stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function updateResults(bytes32 oldResultsHash, bytes32 newResultsHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to move rewards from the competition pool to the winners' competition internal balances based on results from the current challenge.
    * @dev Note that the size of the array parameters passed in to this function is limited by the block gas limit.
    * @dev This function allows for the payout to be split into chunks by calling it repeatedly.
    * @param submitters List of addresses that made submissions for the challenge.
    * @param stakingRewards List of corresponding amount of tokens in wei given to each submitter for the staking rewards portion.
    * @param challengeRewards List of corresponding amount of tokens in wei won by each submitter for the challenge rewards portion.
    * @param tournamentRewards List of corresponding amount of tokens in wei won by each submitter for the tournament rewards portion.
    * @return success True if operation completes successfully.
    **/
    function payRewards(address[] calldata submitters, uint256[] calldata stakingRewards, uint256[] calldata challengeRewards, uint256[] calldata tournamentRewards) external returns (bool success);

    /**
    * @dev Provides the same function as above but allows for challenge number to be specified.
    * @dev Note that the size of the array parameters passed in to this function is limited by the block gas limit.
    * @dev This function allows for the update to be split into chunks by calling it repeatedly.
    * @param challengeNumber Challenge to make updates for.
    * @param participants List of participants' addresses.
    * @param challengeScores List of corresponding challenge scores.
    * @param tournamentScores List of corresponding tournament scores.
    * @return success True if operation completes successfully.
    **/
    function updateChallengeAndTournamentScores(uint32 challengeNumber, address[] calldata participants, uint256[] calldata challengeScores, uint256[] calldata tournamentScores) external returns (bool success);

    /**
    * @dev Called only by authorized admin to do a batch update of an additional information item for a list of participants for a given challenge.
    * @param challengeNumber Challenge to update information for.
    * @param participants List of participant' addresses.
    * @param itemNumber Item to update for.
    * @param values List of corresponding values to store.
    * @return success True if operation completes successfully.
    **/
    function updateInformationBatch(uint32 challengeNumber, address[] calldata participants, uint256 itemNumber, uint[] calldata values) external returns (bool success);

    /**
    * @dev Called only by an authorized admin to advance to the next phase.
    * @dev Due to the block gas limit rewards payments may need to be split up into multiple function calls.
    * @dev In other words, payStakingRewards and payChallengeAndTournamentRewards may need to be called multiple times to complete all required payments.
    * @dev This function is used to advance to phase 3 after staking rewards payments have complemted or to phase 4 after challenge and tournament rewards payments have completed.
    * @param phase The phase to advance to.
    * @return success True if the operation completed successfully.
    **/
    function advanceToPhase(uint8 phase) external returns (bool success);

    /**
    * @dev Called only by an authorized admin, to move any tokens sent to this contract without using the 'sponsor' or 'setStake'/'increaseStake' methods into the competition pool.
    * @return success True if the operation completed successfully.
    **/
    function moveRemainderToPool() external returns (bool success);

    /**
    READ METHODS
    **/

    /**
    * @dev Called by anyone to check minimum amount required to open a new challenge.
    * @return challengeRewardsThreshold Amount of tokens in wei the competition pool must contain to open a new challenge.
    **/
    function getRewardsThreshold() view external returns (uint256 challengeRewardsThreshold);

    /**
    * @dev Called by anyone to check amount pooled into this contract.
    * @return competitionPool Amount of tokens in the competition pool in wei.
    **/
    function getCompetitionPool() view external returns (uint256 competitionPool);

    /**
    * @dev Called by anyone to check the current total amount staked.
    * @return currentTotalStaked Amount of tokens currently staked in wei.
    **/
    function getCurrentTotalStaked() view external returns (uint256 currentTotalStaked);

    /**
    * @dev Called by anyone to check the staking rewards budget allocation for the current challenge.
    * @return currentStakingRewardsBudget Budget for staking rewards in wei.
    **/
    function getCurrentStakingRewardsBudget() view external returns (uint256 currentStakingRewardsBudget);

    /**
    * @dev Called by anyone to check the challenge rewards budget for the current challenge.
    * @return currentChallengeRewardsBudget Budget for challenge rewards payment in wei.
    **/
    function getCurrentChallengeRewardsBudget() view external returns (uint256 currentChallengeRewardsBudget);

    /**
    * @dev Called by anyone to check the tournament rewards budget for the current challenge.
    * @return currentTournamentRewardsBudget Budget for tournament rewards payment in wei.
    **/
    function getCurrentTournamentRewardsBudget() view external returns (uint256 currentTournamentRewardsBudget);

    /**
    * @dev Called by anyone to check the percentage of the total competition reward pool allocated for the challenge reward for this challenge.
    * @return challengeRewardsPercentageInWei Percentage for challenge reward budget in wei.
    **/
    function getChallengeRewardsPercentageInWei() view external returns (uint256 challengeRewardsPercentageInWei);

    /**
    * @dev Called by anyone to check the percentage of the total competition reward pool allocated for the tournament reward for this challenge.
    * @return tournamentRewardsPercentageInWei Percentage for tournament reward budget in wei.
    **/
    function getTournamentRewardsPercentageInWei() view external returns (uint256 tournamentRewardsPercentageInWei);

    /**
    * @dev Called by anyone to get the number of the latest challenge.
    * @dev As the challenge number begins from 1, this is also the total number of challenges created in this competition.
    * @return latestChallengeNumber Latest challenge created.
    **/
    function getLatestChallengeNumber() view external returns (uint32 latestChallengeNumber);

    /**
    * @dev Called by anyone to obtain the dataset hash for this particular challenge.
    * @param challengeNumber The challenge to get the dataset hash of.
    * @return dataset IPFS hash where the dataset of this particular challenge is stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getDatasetHash(uint32 challengeNumber) view external returns (bytes32 dataset);

    /**
    * @dev Called by anyone to obtain the results hash for this particular challenge.
    * @param challengeNumber The challenge to get the results hash of.
    * @return results IPFS hash where results of this particular challenge are stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getResultsHash(uint32 challengeNumber) view external returns (bytes32 results);

    /**
    * @dev Called by anyone to obtain the key hash for this particular challenge.
    * @param challengeNumber The challenge to get the key hash of.
    * @return key IPFS hash where results of this particular challenge are stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getKeyHash(uint32 challengeNumber) view external returns (bytes32 key);

    /**
    * @dev Called by anyone to obtain the private key hash for this particular challenge.
    * @param challengeNumber The challenge to get the key hash of.
    * @return privateKey IPFS hash where results of this particular challenge are stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getPrivateKeyHash(uint32 challengeNumber) view external returns (bytes32 privateKey);

    /**
    * @dev Called by anyone to obtain the number of submissions made for this particular challenge.
    * @param challengeNumber The challenge to get the submission counter of.
    * @return submissionCounter Number of submissions made.
    **/
    function getSubmissionCounter(uint32 challengeNumber) view external returns (uint256 submissionCounter);

    /**
    * @dev Called by anyone to obtain the list of submitters for this particular challenge.
    * @dev Submitters refer to participants that have made submissions for this particular challenge.
    * @param challengeNumber The challenge to get the submitters list of.
    * @param startIndex The challenge to get the submitters list of.
    * @param endIndex The challenge to get the submitters list of.
    * @return List of submitter addresses.
    **/
    function getSubmitters(uint32 challengeNumber, uint256 startIndex, uint256 endIndex) view external returns (address[] memory);

    /**
    * @dev Called by anyone to obtain the phase number for this particular challenge.
    * @param challengeNumber The challenge to get the phase of.
    * @return phase The phase that this challenge is in.
    **/
    function getPhase(uint32 challengeNumber) view external returns (uint8 phase);

    /**
    * @dev Called by anyone to obtain the minimum amount of stake required to participate in the competition.
    * @return stakeThreshold Minimum stake amount in wei.
    **/
    function getStakeThreshold() view external returns (uint256 stakeThreshold);

    /**
    * @dev Called by anyone to obtain the stake amount in wei of a particular address.
    * @param participant Address to query token balance of.
    * @return stake Token balance of given address in wei.
    **/
    function getStake(address participant) view external returns (uint256 stake);

    /**
    * @dev Called by anyone to obtain the smart contract address of the ERC20 token used in this competition.
    * @return tokenAddress ERC20 Token smart contract address.
    **/
    function getTokenAddress() view external returns (address tokenAddress);

    /**
    * @dev Called by anyone to get submission hash of a participant for a challenge.
    * @param challengeNumber Challenge index to check on.
    * @param participant Address of participant to check on.
    * @return submissionHash IPFS reference hash of participant's prediction submission for this challenge. This is the IPFS CID less the 1220 prefix.
    **/
    function getSubmission(uint32 challengeNumber, address participant) view external returns (bytes32 submissionHash);

    /**
    * @dev Called by anyone to check the stakes locked for this participant in a particular challenge.
    * @param challengeNumber Challenge to get the stakes locked of.
    * @param participant Address of participant to check on.
    * @return staked Amount of tokens locked for this challenge for this participant.
    **/
    function getStakedAmountForChallenge(uint32 challengeNumber, address participant) view external returns (uint256 staked);

    /**
    * @dev Called by anyone to check the staking rewards given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the staking rewards given of.
    * @param participant Address of participant to check on.
    * @return stakingRewards Amount of staking rewards given to this participant for this challenge.
    **/
    function getStakingRewards(uint32 challengeNumber, address participant) view external returns (uint256 stakingRewards);

    /**
    * @dev Called by anyone to check the challenge rewards given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the challenge rewards given of.
    * @param participant Address of participant to check on.
    * @return challengeRewards Amount of challenge rewards given to this participant for this challenge.
    **/
    function getChallengeRewards(uint32 challengeNumber, address participant) view external returns (uint256 challengeRewards);

    /**
    * @dev Called by anyone to check the tournament rewards given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the tournament rewards given of.
    * @param participant Address of participant to check on.
    * @return tournamentRewards Amount of tournament rewards given to this participant for this challenge.
    **/
    function getTournamentRewards(uint32 challengeNumber, address participant) view external returns (uint256 tournamentRewards);

    /**
    * @dev Called by anyone to check the overall rewards (staking + challenge + tournament rewards) given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the overall rewards given of.
    * @param participant Address of participant to check on.
    * @return overallRewards Amount of overall rewards given to this participant for this challenge.
    **/
    function getOverallRewards(uint32 challengeNumber, address participant) view external returns (uint256 overallRewards);

    /**
    * @dev Called by anyone to check get the challenge score of this participant for this challenge.
    * @param challengeNumber Challenge to get the participant's challenge score of.
    * @param participant Address of participant to check on.
    * @return challengeScores The challenge score of this participant for this challenge.
    **/
    function getChallengeScores(uint32 challengeNumber, address participant) view external returns (uint256 challengeScores);

    /**
    * @dev Called by anyone to check get the tournament score of this participant for this challenge.
    * @param challengeNumber Challenge to get the participant's tournament score of..
    * @param participant Address of participant to check on.
    * @return tournamentScores The tournament score of this participant for this challenge.
    **/
    function getTournamentScores(uint32 challengeNumber, address participant) view external returns (uint256 tournamentScores);

    /**
    * @dev Called by anyone to check the additional information for this participant in a particular challenge.
    * @param challengeNumber Challenge to get the additional information of.
    * @param participant Address of participant to check on.
    * @param itemNumber Additional information item to check on.
    * @return value Value of this additional information item for this participant for this challenge.
    **/
    function getInformation(uint32 challengeNumber, address participant, uint256 itemNumber) view external returns (uint value);

    /**
    * @dev Called by anyone to retrieve one of the deadlines for this challenge.
    * @param challengeNumber Challenge to get the deadline of.
    * @param index Index of the deadline to retrieve.
    * @return deadline Deadline in milliseconds.
    **/
    function getDeadlines(uint32 challengeNumber, uint256 index)
    external view returns (uint256 deadline);

    /**
    * @dev Called by anyone to check the amount of tokens that have been sent to this contract but are not recorded as a stake or as part of the competition rewards pool.
    * @return remainder The amount of tokens held by this contract that are not recorded as a stake or as part of the competition rewards pool.
    **/
    function getRemainder() external view returns (uint256 remainder);

    /**
    * @dev Called by anyone to get the current broadcast message.
    * @return message Current message being broadcasted.
    **/
    function getMessage() external returns (string memory message);

    /**
    METHODS CALLABLE BY BOTH ADMIN AND PARTICIPANTS.
    **/

    /**
    * @dev Called by a sponsor to send tokens to the contract's competition pool. This pool is used for payouts to challenge winners.
    * @dev This performs an ERC20 transfer so the msg sender will need to grant approval to this contract before calling this function.
    * @param amountToken The amount to send to the the competition pool.
    * @return success True if the operation completed successfully.
    **/
    function sponsor(uint256 amountToken) external returns (bool success);

    /**
    EVENTS
    **/

    event StakeIncreased(address indexed sender, uint256 indexed amount);

    event StakeDecreased(address indexed sender, uint256 indexed amount);

    event SubmissionUpdated(uint32 indexed challengeNumber, address indexed participantAddress, bytes32 indexed newSubmissionHash);

    event MessageUpdated();

    event RewardsThresholdUpdated(uint256 indexed newRewardsThreshold);

    event StakeThresholdUpdated(uint256 indexed newStakeThreshold);

    event ChallengeRewardsPercentageInWeiUpdated(uint256 indexed newPercentage);

    event TournamentRewardsPercentageInWeiUpdated(uint256 indexed newPercentage);

    event PrivateKeyUpdated(bytes32 indexed newPrivateKeyHash);

    event ChallengeOpened(uint32 indexed challengeNumber);

    event DatasetUpdated(uint32 indexed challengeNumber, bytes32 indexed oldDatasetHash, bytes32 indexed newDatasetHash);

    event KeyUpdated(uint32 indexed challengeNumber, bytes32 indexed oldKeyHash, bytes32 indexed newKeyHash);

    event SubmissionClosed(uint32 indexed challengeNumber);

    event ResultsUpdated(uint32 indexed challengeNumber, bytes32 indexed oldResultsHash, bytes32 indexed newResultsHash);

    event RewardsPayment(uint32 challengeNumber, address indexed submitter, uint256 stakingReward, uint256 indexed challengeReward, uint256 indexed tournamentReward);

    event TotalRewardsPaid(uint32 challengeNumber, uint256 indexed totalStakingAmount, uint256 indexed totalChallengeAmount, uint256 indexed totalTournamentAmount);

    event ChallengeAndTournamentScoresUpdated(uint32 indexed challengeNumber);

    event BatchInformationUpdated(uint32 indexed challengeNumber, uint256 indexed itemNumber);

    event RemainderMovedToPool(uint256 indexed remainder);

    event Sponsor(address indexed sponsorAddress, uint256 indexed sponsorAmount, uint256 indexed poolTotal);
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

/**
 * @dev Interface for interacting with Token.sol.
 */
interface IToken {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function increaseStake(address target, uint256 amountToken) external returns (bool success);
    
    function decreaseStake(address target, uint256 amountToken) external returns (bool success);
    
    function setStake(address target, uint256 amountToken) external returns (bool success);

    function getStake(address target, address staker) external view returns (uint256 stake);

    function authorizeCompetition(address competitionAddress) external;

    function revokeCompetition(address competitionAddress) external;

    function competitionIsAuthorized(address competitionAddress) external view returns (bool authorized);
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import '../interfaces/IToken.sol';
import "./standard/utils/structs/EnumerableSet.sol";


/**
 * @title RCI Tournament(Competition) Contract
 * @author Rocket Capital Investment Pte Ltd
**/

contract CompetitionStorage {

    struct Information{
        bytes32 submission;
        uint256 staked;
        uint256 stakingRewards;
        uint256 challengeRewards;
        uint256 tournamentRewards;
        uint256 challengeScores;
        uint256 tournamentScores;
        mapping(uint256 => uint) info;
    }

    struct Challenge{
        bytes32 dataset;
        bytes32 results;
        bytes32 key;
        bytes32 privateKey;
        uint8 phase;
        mapping(address => Information) submitterInfo;
        mapping(uint256 => uint256) deadlines;
        EnumerableSet.AddressSet submitters;
    }

    IToken internal _token;
    uint32 internal _challengeCounter;
    uint256 internal _stakeThreshold;
    uint256 internal _competitionPool;
    uint256 internal _rewardsThreshold;
    uint256 internal _currentTotalStaked;
    uint256 internal _currentStakingRewardsBudget;
    uint256 internal _currentChallengeRewardsBudget;
    uint256 internal _currentTournamentRewardsBudget;
    uint256 internal _challengeRewardsPercentageInWei;
    uint256 internal _tournamentRewardsPercentageInWei;
    string internal _message;
    mapping(address => uint256) internal _stakes;
    mapping(uint32 => Challenge) internal _challenges;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import './standard/access/AccessControl.sol';

abstract contract AccessControlRci is AccessControl{
    bytes32 public constant RCI_MAIN_ADMIN = keccak256('RCI_MAIN_ADMIN');
    bytes32 public constant RCI_CHILD_ADMIN = keccak256('RCI_CHILD_ADMIN');

    modifier onlyMainAdmin()
    {
        require(hasRole(RCI_MAIN_ADMIN, msg.sender), "Caller is unauthorized.");
        _;
    }

    modifier onlyAdmin()
    {
        require(hasRole(RCI_CHILD_ADMIN, msg.sender), "Caller is unauthorized.");
        _;
    }

    function _initializeRciAdmin()
    internal
    {
        _setupRole(RCI_MAIN_ADMIN, msg.sender);
        _setRoleAdmin(RCI_MAIN_ADMIN, RCI_MAIN_ADMIN);

        _setupRole(RCI_CHILD_ADMIN, msg.sender);
        _setRoleAdmin(RCI_CHILD_ADMIN, RCI_MAIN_ADMIN);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
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
  }
}