// SPDX-License-Identifier: GPL-3.0
// vim: noai:ts=4:sw=4

pragma solidity 0.8.4;

import './IERC20.sol';
import './VickreyAuction.sol';

///@dev This implementation originally described the following scenario,
///     for demonstration purposes:
//
///          `_jobPoster` --> `workerNode`
///          `_jobPoster` <-- `workerNode`
//
///      It now has some notion of validator / `reviewerNodes`.

///////////////////////////////////////////////////////////////////////////////
// Notes for elsewhere

/*
    Early stopping    - Vickrey Auction, using the SimpleAuction contract?
    Active monitoring - Micropayment channel?
*/

/* 
    `rewardSchedule` is currently thought to be either a:
    - Continuous Reward (TBA: worker is rewarded essentially for descending the gradient)
    - Variable Reward (Early Stopping; kind-of a Boolean pay-off structure: as workers will
        only be rewarded if they have reached a threshold-level of accuracy)
    - Fixed Interval Reward (Active Monitoring)
    - Fixed Ratio Reward (for validators(?); as they will verify a certain number of models
        over a period of time: even if the selection process for them is pseudo-random?)
    ...encoded as a `string` or a series of `bytes`
*/

/* 
    Implement a form of a reputation score that basically updates how off 
    a given `endUser`'s estimation is of their workload's training time 
*/
///////////////////////////////////////////////////////////////////////////////

contract JobFactory {

    VickreyAuction vickreyAuction;

    event JobDescriptionPosted(
        address jobPoster,
        uint id,
        address auctionAddress,
        uint16 estimatedTrainingTime,
        uint32 trainingDatasetSize,
        uint workerReward,
        uint biddingDeadline,
        uint revealDeadline,
        uint64 clientVersion
    );

    event UntrainedModelAndTrainingDatasetShared(
        address indexed jobPoster,
        uint indexed id,
        address indexed workerNode,
        string untrainedModelMagnetLink,
        string trainingDatasetMagnetLink,
        uint64 targetErrorRate
    );

    event TrainedModelShared(
        address indexed jobPoster,
        uint indexed id,
        address indexed workerNode,
        string trainedModelMagnetLink,
        uint64 trainingErrorRate
    );

    event TestingDatasetShared(
        address indexed jobPoster,
        uint indexed id,
        string trainedModelMagnetLink,
        string testingDatasetMagnetLink,
        uint64 targetErrorRate
    );

    event JobApproved(
        address indexed jobPoster,
        uint id,
        address indexed workerNode,
        address indexed validatorNode,
        string trainedModelMagnetLink 
    );

    enum Status {
        PostedJobDescription,
        SharedUntrainedModelAndTrainingDataset,
        SharedTrainedModel,
        SharedTestingDataset,
        ApprovedJob
    }

    // TODO Struct packing
    struct Job {
        uint auctionId;
        Status status;
        uint64 targetErrorRate;
        address workerNode;
        uint64  clientVersion;
    }

    // Client -> Job(s)
    // FIXME: auctionId is per-EVM basis - this is single-threading assumption
    mapping (address => Job[]) public jobs;

    IERC20 public token;

    constructor(
        IERC20 _token,
        address auctionAddress
    ) {
        token = _token;
        vickreyAuction = VickreyAuction(auctionAddress);
    }

    /// @dev This is being called by `_jobPoster`
    //
    /// @notice `address(0)` is being passed to `Job` as a placeholder
    function postJobDescription(
        uint16 _estimatedTrainingTime,
        uint32 _trainingDatasetSize,
        uint64 _targetErrorRate,
        uint _minimumPayout,
        uint _biddingDeadline,
        uint _revealDeadline,
        uint _workerReward,
        uint64 _clientVersion
    ) public {
        // TODO Possible cruft below
        // FIXME
        //uint jobId;
        /* if (jobs[msg.sender].auctionId != 0) {
            jobId = jobs[msg.sender].length - 1;
        } else {
            jobId = 0;
        } */
        uint jobId = jobs[msg.sender].length;
        vickreyAuction.start(
            _minimumPayout,
            _biddingDeadline,
            _revealDeadline,
            _workerReward,
            msg.sender);
        jobs[msg.sender].push(Job(
            jobId,
            Status.PostedJobDescription,
            _targetErrorRate,
            address(0),
            _clientVersion));
        emit JobDescriptionPosted(
            msg.sender,
            jobId,
            address(vickreyAuction),
            _estimatedTrainingTime,
            _trainingDatasetSize,
            _workerReward,
            _biddingDeadline,
            _revealDeadline,
            _clientVersion
        );
    }

    /// @dev This is being called by `_jobPoster`
    //
    /// @notice The untrained model and the training dataset have been encrypted
    ///         with the `workerNode` public key and `_jobPoster` private key
    function shareUntrainedModelAndTrainingDataset(
        uint _id,
        string memory _untrainedModelMagnetLink,
        string memory _trainingDatasetMagnetLink
    ) public {
        // FIXME require(vickreyAuction.ended(),'Auction has not ended');
        require(jobs[msg.sender][_id].status == Status.PostedJobDescription,'Job has not been posted');
        jobs[msg.sender][_id].status = Status.SharedUntrainedModelAndTrainingDataset;
        // TODO Possible cruft below
        //address x;
        //(,,,,,,x,) = vickreyAuction.auctions(_jobPoster,_id);
        //jobs[msg.sender][_id].workerNode = vickreyAuction.auctions(_jobPoster,_id).highestBidder;
        //jobs[msg.sender][_id].workerNode = x;
        (,,,,,,,jobs[msg.sender][_id].workerNode,,) = vickreyAuction.auctions(msg.sender,_id);
        emit UntrainedModelAndTrainingDatasetShared(
            msg.sender,
            _id,
            jobs[msg.sender][_id].workerNode,
            _untrainedModelMagnetLink,
            _trainingDatasetMagnetLink,
            jobs[msg.sender][_id].targetErrorRate
        );
    }

    /// @dev This is being called by `workerNode`
    //
    /// TODO @notice The trained model has been encrypted with the `_jobPoster`s
    ///         public key and `workerNode` private key
    function shareTrainedModel(
        address _jobPoster,
        uint _id,
        string memory _trainedModelMagnetLink,
        uint64 _trainingErrorRate
    ) public {
        require(msg.sender == jobs[_jobPoster][_id].workerNode,'msg.sender must equal workerNode');
        require(jobs[_jobPoster][_id].status == Status.SharedUntrainedModelAndTrainingDataset,'Untrained model and training dataset has not been shared');
        require(jobs[_jobPoster][_id].targetErrorRate >= _trainingErrorRate,'targetErrorRate must be greater or equal to _trainingErrorRate');
        jobs[_jobPoster][_id].status = Status.SharedTrainedModel;
        emit TrainedModelShared(
            _jobPoster,
            _id,
            msg.sender,
            _trainedModelMagnetLink,
            _trainingErrorRate
        );
    }

    /// @dev This is being called by `_jobPoster`
    //
    /// TODO Have `../daemon` look-up the `trainedModelMagnetLink`
    ///      in the logs instead of re-parameterizing it, below.
    function shareTestingDataset(
        uint _id,
        string memory _trainedModelMagnetLink,
        string memory _testingDatasetMagnetLink
    ) public {
        require(jobs[msg.sender][_id].status == Status.SharedTrainedModel,'Trained model has not been shared');
        jobs[msg.sender][_id].status = Status.SharedTestingDataset;
        emit TestingDatasetShared(
            msg.sender,
            _id,
            _trainedModelMagnetLink,
            _testingDatasetMagnetLink,
            jobs[msg.sender][_id].targetErrorRate
        );
    }

    /// @dev This is being called by a validator node
    function approveJob(
        address _jobPoster,
        uint _id,
        string memory _trainedModelMagnetLink
    ) public {
        require(msg.sender != jobs[_jobPoster][_id].workerNode,'msg.sender cannot equal workerNode');
        require(jobs[_jobPoster][_id].status == Status.SharedTestingDataset,'Testing dataset has not been shared');
        jobs[_jobPoster][_id].status = Status.ApprovedJob;
        // TODO Possible cruft below
        // FIXME
        //vickreyAuction.payout(_jobPoster,_id);
        emit JobApproved(
            _jobPoster,
            _id,
            jobs[_jobPoster][_id].workerNode,
            msg.sender,
            _trainedModelMagnetLink             
        );
    }
}