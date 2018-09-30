pragma solidity ^0.4.25;

contract Approvable {

    mapping(address => bool) public approved;

    constructor () public {
        approved[msg.sender] = true;
    }

    function approve(address _address) public onlyApproved {
        require(_address != address(0));
        approved[_address] = true;
    }

    function revokeApproval(address _address) public onlyApproved {
        require(_address != address(0));
        approved[_address] = false;
    }

    modifier onlyApproved() {
        require(approved[msg.sender]);
        _;
    }
}

contract DIDToken is Approvable {

    using SafeMath for uint256;

    event LogIssueDID(address indexed to, uint256 numDID);
    event LogDecrementDID(address indexed to, uint256 numDID);
    event LogExchangeDIDForEther(address indexed to, uint256 numDID);
    event LogInvestEtherForDID(address indexed to, uint256 numWei);

    address[] public DIDHoldersArray;

    address public PullRequestsAddress;
    address public DistenseAddress;

    uint256 public investmentLimitAggregate  = 100000 ether;  // This is the max DID all addresses can receive from depositing ether
    uint256 public investmentLimitAddress = 100 ether;  // This is the max DID any address can receive from Ether deposit
    uint256 public investedAggregate = 1 ether;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    struct DIDHolder {
        uint256 balance;
        uint256 netContributionsDID;    // essentially the number of DID remaining for calculating how much ether an account may invest
        uint256 DIDHoldersIndex;
        uint256 weiInvested;
        uint256 tasksCompleted;
    }
    mapping (address => DIDHolder) public DIDHolders;

    constructor () public {
        name = "Distense DID";
        symbol = "DID";
        totalSupply = 0;
        decimals = 18;
    }

    function issueDID(address _recipient, uint256 _numDID) public onlyApproved returns (bool) {
        require(_recipient != address(0));
        require(_numDID > 0);

        _numDID = _numDID * 1 ether;
        totalSupply = SafeMath.add(totalSupply, _numDID);
        
        uint256 balance = DIDHolders[_recipient].balance;
        DIDHolders[_recipient].balance = SafeMath.add(balance, _numDID);

        //  If is a new DIDHolder, set their position in DIDHoldersArray
        if (DIDHolders[_recipient].DIDHoldersIndex == 0) {
            uint256 index = DIDHoldersArray.push(_recipient) - 1;
            DIDHolders[_recipient].DIDHoldersIndex = index;
        }

        emit LogIssueDID(_recipient, _numDID);

        return true;
    }

    function decrementDID(address _address, uint256 _numDID) external onlyApproved returns (uint256) {
        require(_address != address(0));
        require(_numDID > 0);

        uint256 numDID = _numDID * 1 ether;
        require(SafeMath.sub(DIDHolders[_address].balance, numDID) >= 0);
        require(SafeMath.sub(totalSupply, numDID ) >= 0);

        totalSupply = SafeMath.sub(totalSupply, numDID);
        DIDHolders[_address].balance = SafeMath.sub(DIDHolders[_address].balance, numDID);

        //  If DIDHolder has exchanged all of their DID remove from DIDHoldersArray
        //  For minimizing blockchain size and later client query performance
        if (DIDHolders[_address].balance == 0) {
            deleteDIDHolderWhenBalanceZero(_address);
        }

        emit LogDecrementDID(_address, numDID);

        return DIDHolders[_address].balance;
    }

    function exchangeDIDForEther(uint256 _numDIDToExchange)
        external
    returns (uint256) {

        uint256 numDIDToExchange = _numDIDToExchange * 1 ether;
        uint256 netContributionsDID = getNumContributionsDID(msg.sender);
        require(netContributionsDID >= numDIDToExchange);

        Distense distense = Distense(DistenseAddress);
        uint256 DIDPerEther = distense.getParameterValueByTitle(distense.didPerEtherParameterTitle());

        require(numDIDToExchange < totalSupply);

        uint256 numWeiToIssue = calculateNumWeiToIssue(numDIDToExchange, DIDPerEther);
        address contractAddress = this;
        require(contractAddress.balance >= numWeiToIssue, "DIDToken contract must have sufficient wei");

        //  Adjust number of DID owned first
        DIDHolders[msg.sender].balance = SafeMath.sub(DIDHolders[msg.sender].balance, numDIDToExchange);
        DIDHolders[msg.sender].netContributionsDID = SafeMath.sub(DIDHolders[msg.sender].netContributionsDID, numDIDToExchange);
        totalSupply = SafeMath.sub(totalSupply, numDIDToExchange);

        msg.sender.transfer(numWeiToIssue);

        if (DIDHolders[msg.sender].balance == 0) {
            deleteDIDHolderWhenBalanceZero(msg.sender);
        }
        emit LogExchangeDIDForEther(msg.sender, numDIDToExchange);

        return DIDHolders[msg.sender].balance;
    }

    function investEtherForDID() external payable returns (uint256) {
        require(getNumWeiAddressMayInvest(msg.sender) >= msg.value);
        require(investedAggregate < investmentLimitAggregate);

        Distense distense = Distense(DistenseAddress);
        uint256 DIDPerEther = SafeMath.div(distense.getParameterValueByTitle(distense.didPerEtherParameterTitle()), 1 ether);

        uint256 numDIDToIssue = calculateNumDIDToIssue(msg.value, DIDPerEther);
        require(DIDHolders[msg.sender].netContributionsDID >= numDIDToIssue);
        totalSupply = SafeMath.add(totalSupply, numDIDToIssue);
        DIDHolders[msg.sender].balance = SafeMath.add(DIDHolders[msg.sender].balance, numDIDToIssue);
        DIDHolders[msg.sender].netContributionsDID = SafeMath.sub(DIDHolders[msg.sender].netContributionsDID, numDIDToIssue);

        DIDHolders[msg.sender].weiInvested += msg.value;
        investedAggregate = investedAggregate + msg.value;

        emit LogIssueDID(msg.sender, numDIDToIssue);
        emit LogInvestEtherForDID(msg.sender, msg.value);

        return DIDHolders[msg.sender].balance;
    }

    function incrementDIDFromContributions(address _contributor, uint256 _reward) onlyApproved public {
        uint256 weiReward = _reward * 1 ether;
        DIDHolders[_contributor].netContributionsDID = SafeMath.add(DIDHolders[_contributor].netContributionsDID, weiReward);
    }

    function incrementTasksCompleted(address _contributor) onlyApproved public returns (bool) {
        DIDHolders[_contributor].tasksCompleted++;
        return true;
    }

    function pctDIDOwned(address _address) external view returns (uint256) {
        return SafeMath.percent(DIDHolders[_address].balance, totalSupply, 20);
    }

    function getNumWeiAddressMayInvest(address _contributor) public view returns (uint256) {

        uint256 DIDFromContributions = DIDHolders[_contributor].netContributionsDID;
        require(DIDFromContributions > 0);
        uint256 netUninvestedEther = SafeMath.sub(investmentLimitAddress, DIDHolders[_contributor].weiInvested);
        require(netUninvestedEther > 0);

        Distense distense = Distense(DistenseAddress);
        uint256 DIDPerEther = distense.getParameterValueByTitle(distense.didPerEtherParameterTitle());

        return (DIDFromContributions * 1 ether) / DIDPerEther;
    }

    function rewardContributor(address _contributor, uint256 _reward) external onlyApproved returns (bool) {
        uint256 reward = SafeMath.div(_reward, 1 ether);
        bool issued = issueDID(_contributor, reward);
        if (issued) incrementDIDFromContributions(_contributor, reward);
        incrementTasksCompleted(_contributor);
    }

    function getWeiAggregateMayInvest() public view returns (uint256) {
        return SafeMath.sub(investmentLimitAggregate, investedAggregate);
    }

    function getNumDIDHolders() external view returns (uint256) {
        return DIDHoldersArray.length;
    }

    function getAddressBalance(address _address) public view returns (uint256) {
        return DIDHolders[_address].balance;
    }

    function getNumContributionsDID(address _address) public view returns (uint256) {
        return DIDHolders[_address].netContributionsDID;
    }

    function getWeiInvested(address _address) public view returns (uint256) {
        return DIDHolders[_address].weiInvested;
    }

    function calculateNumDIDToIssue(uint256 msgValue, uint256 DIDPerEther) public pure returns (uint256) {
        return SafeMath.mul(msgValue, DIDPerEther);
    }

    function calculateNumWeiToIssue(uint256 _numDIDToExchange, uint256 _DIDPerEther) public pure returns (uint256) {
        _numDIDToExchange = _numDIDToExchange * 1 ether;
        return SafeMath.div(_numDIDToExchange, _DIDPerEther);
    }

    function deleteDIDHolderWhenBalanceZero(address holder) internal {
        if (DIDHoldersArray.length > 1) {
            address lastElement = DIDHoldersArray[DIDHoldersArray.length - 1];
            DIDHoldersArray[DIDHolders[holder].DIDHoldersIndex] = lastElement;
            DIDHoldersArray.length--;
            delete DIDHolders[holder];
        }
    }

    function deleteDIDHolder(address holder) public onlyApproved {
        if (DIDHoldersArray.length > 1) {
            address lastElement = DIDHoldersArray[DIDHoldersArray.length - 1];
            DIDHoldersArray[DIDHolders[holder].DIDHoldersIndex] = lastElement;
            DIDHoldersArray.length--;
            delete DIDHolders[holder];
        }
    }

    function setDistenseAddress(address _distenseAddress) onlyApproved public  {
        DistenseAddress = _distenseAddress;
    }

}

contract Distense is Approvable {

    using SafeMath for uint256;

    address public DIDTokenAddress;

    /*
      Distense&#39; votable parameters
      Parameter is the perfect word` for these: "a numerical or other measurable factor forming one of a set
      that defines a system or sets the conditions of its operation".
    */

    //  Titles are what uniquely identify parameters, so query by titles when iterating with clients
    bytes32[] public parameterTitles;

    struct Parameter {
        bytes32 title;
        uint256 value;
        mapping(address => Vote) votes;
    }

    struct Vote {
        address voter;
        uint256 lastVoted;
    }

    mapping(bytes32 => Parameter) public parameters;

    Parameter public votingIntervalParameter;
    bytes32 public votingIntervalParameterTitle = &#39;votingInterval&#39;;

    Parameter public pctDIDToDetermineTaskRewardParameter;
    bytes32 public pctDIDToDetermineTaskRewardParameterTitle = &#39;pctDIDToDetermineTaskReward&#39;;

    Parameter public pctDIDRequiredToMergePullRequest;
    bytes32 public pctDIDRequiredToMergePullRequestTitle = &#39;pctDIDRequiredToMergePullRequest&#39;;

    Parameter public maxRewardParameter;
    bytes32 public maxRewardParameterTitle = &#39;maxReward&#39;;

    Parameter public numDIDRequiredToApproveVotePullRequestParameter;
    bytes32 public numDIDRequiredToApproveVotePullRequestParameterTitle = &#39;numDIDReqApproveVotePullRequest&#39;;

    Parameter public numDIDRequiredToTaskRewardVoteParameter;
    bytes32 public numDIDRequiredToTaskRewardVoteParameterTitle = &#39;numDIDRequiredToTaskRewardVote&#39;;

    Parameter public minNumberOfTaskRewardVotersParameter;
    bytes32 public minNumberOfTaskRewardVotersParameterTitle = &#39;minNumberOfTaskRewardVoters&#39;;

    Parameter public numDIDRequiredToAddTaskParameter;
    bytes32 public numDIDRequiredToAddTaskParameterTitle = &#39;numDIDRequiredToAddTask&#39;;

    Parameter public defaultRewardParameter;
    bytes32 public defaultRewardParameterTitle = &#39;defaultReward&#39;;

    Parameter public didPerEtherParameter;
    bytes32 public didPerEtherParameterTitle = &#39;didPerEther&#39;;

    Parameter public votingPowerLimitParameter;
    bytes32 public votingPowerLimitParameterTitle = &#39;votingPowerLimit&#39;;

    event LogParameterValueUpdate(bytes32 title, uint256 value);

    constructor (address _DIDTokenAddress) public {

        DIDTokenAddress = _DIDTokenAddress;

        // Launch Distense with some votable parameters
        // that can be later updated by contributors
        // Current values can be found at https://disten.se/parameters

        // Percentage of DID that must vote on a proposal for it to be approved and payable
        pctDIDToDetermineTaskRewardParameter = Parameter({
            title : pctDIDToDetermineTaskRewardParameterTitle,
            //     Every hard-coded int except for dates and numbers (not percentages) pertaining to ether or DID are decimals to two decimal places
            //     So this is 15.00%
            value: 15 * 1 ether
        });
        parameters[pctDIDToDetermineTaskRewardParameterTitle] = pctDIDToDetermineTaskRewardParameter;
        parameterTitles.push(pctDIDToDetermineTaskRewardParameterTitle);


        pctDIDRequiredToMergePullRequest = Parameter({
            title : pctDIDRequiredToMergePullRequestTitle,
            value: 10 * 1 ether
        });
        parameters[pctDIDRequiredToMergePullRequestTitle] = pctDIDRequiredToMergePullRequest;
        parameterTitles.push(pctDIDRequiredToMergePullRequestTitle);


        votingIntervalParameter = Parameter({
            title : votingIntervalParameterTitle,
            value: 1296000 * 1 ether// 15 * 86400 = 1.296e+6
        });
        parameters[votingIntervalParameterTitle] = votingIntervalParameter;
        parameterTitles.push(votingIntervalParameterTitle);


        maxRewardParameter = Parameter({
            title : maxRewardParameterTitle,
            value: 2000 * 1 ether
        });
        parameters[maxRewardParameterTitle] = maxRewardParameter;
        parameterTitles.push(maxRewardParameterTitle);


        numDIDRequiredToApproveVotePullRequestParameter = Parameter({
            title : numDIDRequiredToApproveVotePullRequestParameterTitle,
            //     100 DID
            value: 100 * 1 ether
        });
        parameters[numDIDRequiredToApproveVotePullRequestParameterTitle] = numDIDRequiredToApproveVotePullRequestParameter;
        parameterTitles.push(numDIDRequiredToApproveVotePullRequestParameterTitle);


        // This parameter is the number of DID an account must own to vote on a task&#39;s reward
        // The task reward is the number of DID payable upon successful completion and approval of a task

        // This parameter mostly exists to get the percentage of DID that have voted higher per voter
        //   as looping through voters to determineReward()s is gas-expensive.

        // This parameter also limits attacks by noobs that want to mess with Distense.
        numDIDRequiredToTaskRewardVoteParameter = Parameter({
            title : numDIDRequiredToTaskRewardVoteParameterTitle,
            // 100
            value: 100 * 1 ether
        });
        parameters[numDIDRequiredToTaskRewardVoteParameterTitle] = numDIDRequiredToTaskRewardVoteParameter;
        parameterTitles.push(numDIDRequiredToTaskRewardVoteParameterTitle);


        minNumberOfTaskRewardVotersParameter = Parameter({
            title : minNumberOfTaskRewardVotersParameterTitle,
            //     7
            value: 7 * 1 ether
        });
        parameters[minNumberOfTaskRewardVotersParameterTitle] = minNumberOfTaskRewardVotersParameter;
        parameterTitles.push(minNumberOfTaskRewardVotersParameterTitle);


        numDIDRequiredToAddTaskParameter = Parameter({
            title : numDIDRequiredToAddTaskParameterTitle,
            //     100
            value: 100 * 1 ether
        });
        parameters[numDIDRequiredToAddTaskParameterTitle] = numDIDRequiredToAddTaskParameter;
        parameterTitles.push(numDIDRequiredToAddTaskParameterTitle);


        defaultRewardParameter = Parameter({
            title : defaultRewardParameterTitle,
            //     100
            value: 100 * 1 ether
        });
        parameters[defaultRewardParameterTitle] = defaultRewardParameter;
        parameterTitles.push(defaultRewardParameterTitle);


        didPerEtherParameter = Parameter({
            title : didPerEtherParameterTitle,
            //     1000
            value: 200 * 1 ether
        });
        parameters[didPerEtherParameterTitle] = didPerEtherParameter;
        parameterTitles.push(didPerEtherParameterTitle);

        votingPowerLimitParameter = Parameter({
            title : votingPowerLimitParameterTitle,
            //     20.00%
            value: 20 * 1 ether
        });
        parameters[votingPowerLimitParameterTitle] = votingPowerLimitParameter;
        parameterTitles.push(votingPowerLimitParameterTitle);

    }

    function getParameterValueByTitle(bytes32 _title) public view returns (uint256) {
        return parameters[_title].value;
    }

    /**
        Function called when contributors vote on parameters at /parameters url
        In the client there are: max and min buttons and a text input

        @param _title name of parameter title the DID holder is voting on.  This must be one of the hardcoded titles in this file.
        @param _voteValue integer in percentage effect.  For example if the current value of a parameter is 20, and the voter votes 24, _voteValue
        would be 20, for a 20% increase.

        If _voteValue is 1 it&#39;s a max upvote, if -1 max downvote. Maximum votes, as just mentioned, affect parameter values by
        max(percentage of DID owned by the voter, value of the votingLimit parameter).
        If _voteValue has a higher absolute value than 1, the user has voted a specific value not maximum up or downvote.
        In that case we update the value to the voted value if the value would affect the parameter value less than their percentage DID ownership.
          If they voted a value that would affect the parameter&#39;s value by more than their percentage DID ownership we affect the value by their percentage DID ownership.
    */
    function voteOnParameter(bytes32 _title, int256 _voteValue)
        public
        votingIntervalReached(msg.sender, _title)
        returns
    (uint256) {

        DIDToken didToken = DIDToken(DIDTokenAddress);
        uint256 votersDIDPercent = didToken.pctDIDOwned(msg.sender);
        require(votersDIDPercent > 0);

        uint256 currentValue = getParameterValueByTitle(_title);

        //  For voting power purposes, limit the pctDIDOwned to the maximum of the Voting Power Limit parameter or the voter&#39;s percentage ownership
        //  of DID
        uint256 votingPowerLimit = getParameterValueByTitle(votingPowerLimitParameterTitle);

        uint256 limitedVotingPower = votersDIDPercent > votingPowerLimit ? votingPowerLimit : votersDIDPercent;

        uint256 update;
        if (
            _voteValue == 1 ||  // maximum upvote
            _voteValue == - 1 || // minimum downvote
            _voteValue > int(limitedVotingPower) || // vote value greater than votingPowerLimit
            _voteValue < - int(limitedVotingPower)  // vote value greater than votingPowerLimit absolute value
        ) {
            update = (limitedVotingPower * currentValue) / (100 * 1 ether);
        } else if (_voteValue > 0) {
            update = SafeMath.div((uint(_voteValue) * currentValue), (1 ether * 100));
        } else if (_voteValue < 0) {
            int256 adjustedVoteValue = (-_voteValue); // make the voteValue positive and convert to on-chain decimals
            update = uint((adjustedVoteValue * int(currentValue))) / (100 * 1 ether);
        } else revert(); //  If _voteValue is 0 refund gas to voter

        if (_voteValue > 0)
            currentValue = SafeMath.add(currentValue, update);
        else
            currentValue = SafeMath.sub(currentValue, update);

        updateParameterValue(_title, currentValue);
        updateLastVotedOnParameter(_title, msg.sender);
        emit LogParameterValueUpdate(_title, currentValue);

        return currentValue;
    }

    function getParameterByTitle(bytes32 _title) public view returns (bytes32, uint256) {
        Parameter memory param = parameters[_title];
        return (param.title, param.value);
    }

    function getNumParameters() public view returns (uint256) {
        return parameterTitles.length;
    }

    function updateParameterValue(bytes32 _title, uint256 _newValue) internal returns (uint256) {
        Parameter storage parameter = parameters[_title];
        parameter.value = _newValue;
        return parameter.value;
    }

    function updateLastVotedOnParameter(bytes32 _title, address voter) internal returns (bool) {
        Parameter storage parameter = parameters[_title];
        parameter.votes[voter].lastVoted = now;
    }

    function setDIDTokenAddress(address _didTokenAddress) public onlyApproved {
        DIDTokenAddress = _didTokenAddress;
    }

    modifier votingIntervalReached(address _voter, bytes32 _title) {
        Parameter storage parameter = parameters[_title];
        uint256 lastVotedOnParameter = parameter.votes[_voter].lastVoted * 1 ether;
        require((now * 1 ether) >= lastVotedOnParameter + getParameterValueByTitle(votingIntervalParameterTitle));
        _;
    }
}

contract Tasks is Approvable {

    using SafeMath for uint256;

    address public DIDTokenAddress;
    address public DistenseAddress;

    bytes32[] public taskIds;

    enum RewardStatus { TENTATIVE, DETERMINED, PAID }

    struct Task {
        string title;
        address createdBy;
        uint256 reward;
        RewardStatus rewardStatus;
        uint256 pctDIDVoted;
        uint64 numVotes;
        mapping(address => bool) rewardVotes;
        uint256 taskIdsIndex;   // for easy later deletion to minimize query time and blockchain size
    }

    mapping(bytes32 => Task) tasks;
    mapping(bytes32 => bool) tasksTitles;

    event LogAddTask(bytes32 taskId, string title);
    event LogTaskRewardVote(bytes32 taskId, uint256 reward, uint256 pctDIDVoted);
    event LogTaskRewardDetermined(bytes32 taskId, uint256 reward);

    constructor (address _DIDTokenAddress, address _DistenseAddress) public {
        DIDTokenAddress = _DIDTokenAddress;
        DistenseAddress = _DistenseAddress;
    }

    function addTask(bytes32 _taskId, string _title) external hasEnoughDIDToAddTask returns
        (bool) {

        bytes32 titleBytes32 = keccak256(abi.encodePacked(_title));
        require(!tasksTitles[titleBytes32], "Task title already exists");

        Distense distense = Distense(DistenseAddress);

        tasks[_taskId].createdBy = msg.sender;
        tasks[_taskId].title = _title;
        tasks[_taskId].reward = distense.getParameterValueByTitle(distense.defaultRewardParameterTitle());
        tasks[_taskId].rewardStatus = RewardStatus.TENTATIVE;

        taskIds.push(_taskId);
        tasksTitles[titleBytes32] = true;
        tasks[_taskId].taskIdsIndex = taskIds.length - 1;
        emit LogAddTask(_taskId, _title);

        return true;
    }

    function getTaskById(bytes32 _taskId) external view returns (
        string,
        address,
        uint256,
        Tasks.RewardStatus,
        uint256,
        uint64
    ) {

        Task memory task = tasks[_taskId];
        return (
            task.title,
            task.createdBy,
            task.reward,
            task.rewardStatus,
            task.pctDIDVoted,
            task.numVotes
        );

    }

    function taskExists(bytes32 _taskId) external view returns (bool) {
        return tasks[_taskId].createdBy != 0;
    }

    function getNumTasks() external view returns (uint256) {
        return taskIds.length;
    }

    function taskRewardVote(bytes32 _taskId, uint256 _reward) external returns (bool) {

        DIDToken didToken = DIDToken(DIDTokenAddress);
        uint256 balance = didToken.getAddressBalance(msg.sender);
        Distense distense = Distense(DistenseAddress);

        Task storage task = tasks[_taskId];

        require(_reward >= 0);

        //  Essentially refund the remaining gas if user&#39;s vote will have no effect
        require(task.reward != (_reward * 1 ether));

        // Don&#39;t let the voter vote if the reward has already been determined
        require(task.rewardStatus != RewardStatus.DETERMINED);

        //  Has the voter already voted on this task?
        require(!task.rewardVotes[msg.sender]);

        //  Does the voter own at least as many DID as the reward their voting for?
        //  This ensures new contributors don&#39;t have too much sway over the issuance of new DID.
        require(balance > distense.getParameterValueByTitle(distense.numDIDRequiredToTaskRewardVoteParameterTitle()));

        //  Require the reward to be less than or equal to the maximum reward parameter,
        //  which basically is a hard, floating limit on the number of DID that can be issued for any single task
        require((_reward * 1 ether) <= distense.getParameterValueByTitle(distense.maxRewardParameterTitle()));

        task.rewardVotes[msg.sender] = true;

        uint256 pctDIDOwned = didToken.pctDIDOwned(msg.sender);
        task.pctDIDVoted = task.pctDIDVoted + pctDIDOwned;

        //  Get the current votingPowerLimit
        uint256 votingPowerLimit = distense.getParameterValueByTitle(distense.votingPowerLimitParameterTitle());
        //  For voting purposes, limit the pctDIDOwned
        uint256 limitedVotingPower = pctDIDOwned > votingPowerLimit ? votingPowerLimit : pctDIDOwned;

        uint256 difference;
        uint256 update;

        if ((_reward * 1 ether) > task.reward) {
            difference = SafeMath.sub((_reward * 1 ether), task.reward);
            update = (limitedVotingPower * difference) / (1 ether * 100);
            task.reward += update;
        } else {
            difference = SafeMath.sub(task.reward, (_reward * 1 ether));
            update = (limitedVotingPower * difference) / (1 ether * 100);
            task.reward -= update;
        }

        task.numVotes++;

        uint256 pctDIDVotedThreshold = distense.getParameterValueByTitle(
            distense.pctDIDToDetermineTaskRewardParameterTitle()
        );

        uint256 minNumVoters = distense.getParameterValueByTitle(
            distense.minNumberOfTaskRewardVotersParameterTitle()
        );

        if (task.pctDIDVoted > pctDIDVotedThreshold || task.numVotes > SafeMath.div(minNumVoters, 1 ether)) {
            emit LogTaskRewardDetermined(_taskId, task.reward);
            task.rewardStatus = RewardStatus.DETERMINED;
        }

        return true;

    }

    function getTaskReward(bytes32 _taskId) external view returns (uint256) {
        return tasks[_taskId].reward;
    }

    function getTaskRewardAndStatus(bytes32 _taskId) external view returns (uint256, RewardStatus) {
        return (
            tasks[_taskId].reward,
            tasks[_taskId].rewardStatus
        );
    }

    function setTaskRewardPaid(bytes32 _taskId) external onlyApproved returns (RewardStatus) {
        tasks[_taskId].rewardStatus = RewardStatus.PAID;
        return tasks[_taskId].rewardStatus;
    }

    //  Allow deleting of PAID taskIds to minimize blockchain size & query time on client
    //  taskIds are memorialized in the form of events/logs, so this doesn&#39;t truly delete them,
    //  it just prevents them from slowing down query times
    function deleteTask(bytes32 _taskId) external onlyApproved returns (bool) {
        Task storage task = tasks[_taskId];

        if (task.rewardStatus == RewardStatus.PAID) {
            uint256 index = tasks[_taskId].taskIdsIndex;
            delete taskIds[index];
            delete tasks[_taskId];

            // Move the last element to the deleted index.  If we don&#39;t do this there are no efficiencies and the index will still still be
            // iterated over on the client
            uint256 taskIdsLength = taskIds.length;
            if (taskIdsLength > 1) {
                bytes32 lastElement = taskIds[taskIdsLength - 1];
                taskIds[index] = lastElement;
                taskIds.length--;
            }
            return true;
        }
        return false;
    }

    modifier hasEnoughDIDToAddTask() {
        DIDToken didToken = DIDToken(DIDTokenAddress);
        uint256 balance = didToken.getAddressBalance(msg.sender);

        Distense distense = Distense(DistenseAddress);
        uint256 numDIDRequiredToAddTask = distense.getParameterValueByTitle(
            distense.numDIDRequiredToAddTaskParameterTitle()
        );
        require(balance >= numDIDRequiredToAddTask);
        _;
    }

    function setDIDTokenAddress(address _DIDTokenAddress) public onlyApproved {
        DIDTokenAddress = _DIDTokenAddress;
    }

    function setDistenseAddress(address _DistenseAddress) public onlyApproved {
        DistenseAddress = _DistenseAddress;
    }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }


  function percent(uint numerator, uint denominator, uint precision) public pure
  returns(uint quotient) {

    // caution, check safe-to-multiply here
    uint _numerator  = numerator * 10 ** (precision + 1);

    // with rounding of last digit
    uint _quotient =  ((_numerator / denominator) + 5) / 10;
    return _quotient;
  }

}