/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GnGOwnable {
    address public guardianAddress;
    address public governorAddress;
    
    event GuardianTransferred(address indexed oldGuardianAddress, address indexed newGuardianAddress);
    event GovernorTransferred(address indexed oldGuardianAddress, address indexed newGuardianAddress);
    
    constructor() public{
        guardianAddress = msg.sender;
    }
    
    modifier onlyGovOrGur{
        require(msg.sender == governorAddress || msg.sender == guardianAddress, "caller is not governor or guardian");
        _;
    }
    
    modifier onlyGuardian {
        require(msg.sender == guardianAddress, "caller is not guardian");
        _;
    }
    
    
    function transferGuardian(address newGuardianAddress) public onlyGovOrGur {
        emit GuardianTransferred(guardianAddress, newGuardianAddress);
        guardianAddress = newGuardianAddress;
    }
    
    function transferGovernor(address newGovernorAddress) public onlyGovOrGur {
        emit GuardianTransferred(governorAddress, newGovernorAddress);
        governorAddress = newGovernorAddress;
    }
}

interface ICourtStake{
    function blockWithdraw(address account,uint256 time) external;
    function getUserPower(address account) external view returns(uint256);
}

contract CourtStakeDummy is ICourtStake{
    mapping(address =>uint256) public powerDB;
    function blockWithdraw(address account,uint256 time) external{
        
    }
    function getUserPower(address account) external view returns(uint256){
        return powerDB[account];
    }
    function setUserPower(address account, uint256 power) external returns(uint256){
        powerDB[account] = power;
    }
}

contract OROracleInfo is GnGOwnable {

    struct QuestionStruct {
        uint256 qid;
        uint256 minPower;
        uint256 minOptionalERC20Holding;
        uint256 reward;
        uint256 rewardDistriputedEquallyPerc;
        uint256 votersCount;
        uint256 createdTime;
        uint256 endTime;
        address creator;
        address optionalERC20Address;
        string question;
        string description;
        uint256[] votesCounts;
        uint256[] votesPower;
        uint256[] optionalTokenHolding;
        uint256[] categoriesIndices;
        string[] choices;
        
        
    }

    struct KnownAccountStruct {
        address account;
        bool allowed;
        uint256 minReward;
        uint256 fees;
        string name;
    }
    
    struct UserVoteInfo{
        bool voteFlag;
        uint256 power;
        uint8 choice;
    }

    IERC20 public ROOM = IERC20(0x460A9872c00f01172d9efE9a3d6971475212517b);//TODO
    uint256 public gMinPowerToVote =1; //TODO

    bool public anonymousProposerAllowed = true; //TODO
    uint256 public anonymousFees; //TODO
    uint256 public anonymousMinReward = 5; //TODO

    
    
    uint256 public minQuestionDuration; //TODO
    uint256 public maxQuestionDuration = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ;//TODO
    
    uint256 public minEquallyDistriputedRewardPerc = 0; //TODO
    uint256 public maxEquallyDistriputedRewardPerc = 100; //TODO
    
    uint256 public feesCollected;

    QuestionStruct[] public questions;

    KnownAccountStruct[] public knownAccounts;
    mapping(address => uint256) proposersIDMap;
    
    mapping(uint256 => mapping(address => UserVoteInfo)) public userVoteInfoPerQuestion;
    mapping(uint256 => mapping(address => uint256)) public userClaimedRewardPerQuestion;

    mapping(address => uint256[]) public userPendingRewards;
    
    
    mapping(address => uint256) public userClaimedRewards;
    
    mapping(uint256 => uint256) public totalVotePowerPerQuestion;
   
    
    mapping(address => bool) public categoriesModifyPermission;
    
    address public courtStakeAddress =  0xEDAa6c4d4f4923ab7B7bB8027839DF7728012095;
    bool blockWithdrawCourtFlag = true;
    
    string[] public categories;
    
    event QuestionCreated(address indexed creator, uint256 indexed qid);
    event Vote(uint256 indexed qid, uint8 choice);

    constructor() public {
        addProposer(address(this), 0, 0, "");
    }

    function createQuestion(string memory question, string[] memory choices, uint256 reward, uint256 rewardDistriputedEquallyPerc,uint256 duration, uint256 minPowerAboveDefault, address optionalERC20Address, uint256 minOptionalERC20Holding, uint256[] memory categoriesIndices, string memory description) public returns (uint256 qid) {
        address account = msg.sender;
        uint256 proposerID = proposersIDMap[account];
        uint256 fees;
        
       
        if(optionalERC20Address != address(0) ){
            require(IERC20(optionalERC20Address).balanceOf(address(this)) >= 0, "check optinal IERC20 address");
        }
        
        require(duration >= minQuestionDuration, "Question Duration is less than minimum duration");
        require(duration <= maxQuestionDuration, "Question duration is greater than maximum duration");
        
        require(rewardDistriputedEquallyPerc >= minEquallyDistriputedRewardPerc, "The reward distriputed equally percentage is less than the minmum");
        require(rewardDistriputedEquallyPerc <= maxEquallyDistriputedRewardPerc, "The reward distriputed equally percentage is greater than the maximum ");
        
        {
        // 
        uint256 minReward;
        
        if (proposerID == 0) {
            require(anonymousProposerAllowed == true, "anonymous proposer is not allowed");
            minReward = anonymousMinReward;
            fees = anonymousFees;

        } else {
            require(knownAccounts[proposerID].allowed == true, "account suspended");
            fees = knownAccounts[proposerID].fees;
            minReward = knownAccounts[proposerID].minReward;
        }
        
        require(reward >= minReward, "Reward less than minimum reward");
        }
        
        ROOM.transferFrom(account, address(this), fees);
        feesCollected += fees;

        ROOM.transferFrom(account, address(this), reward);

        return _createQuestion(question, choices, reward, rewardDistriputedEquallyPerc, duration, minPowerAboveDefault, optionalERC20Address, minOptionalERC20Holding, categoriesIndices, description);
    }
    
    function _createQuestion(string memory question, string[] memory choices, uint256 reward, uint256 rewardDistriputedEquallyPerc, uint256 duration, uint256 minPowerAboveDefault, address optionalERC20Address, uint256 minOptionalERC20Holding, uint256[] memory categoriesIndices, string memory description) internal returns (uint256 qid){
        require(choices.length >= 2, "choices must be at least 2");
        
        qid = questions.length;

        questions.push(QuestionStruct({
            optionalERC20Address : optionalERC20Address,
            minOptionalERC20Holding : minOptionalERC20Holding,
            minPower : gMinPowerToVote + minPowerAboveDefault,
            qid : questions.length,
            creator : msg.sender,
            reward : reward,
            question : question,
            choices : choices,
            votesCounts : new uint256[](choices.length),
            votesPower : new uint256[](choices.length),
            optionalTokenHolding : new uint256[](choices.length),
            createdTime : block.timestamp,
            endTime : getCurrentTime() + duration,
            votersCount : 0,
            categoriesIndices: categoriesIndices,
            description: description,
            rewardDistriputedEquallyPerc: rewardDistriputedEquallyPerc
        }));
        
        emit QuestionCreated(msg.sender,qid);
    }


    function vote(uint256 qid, uint8 choice) public {
        require(userVoteInfoPerQuestion[qid][msg.sender].voteFlag == false, "User already voted for this question");
        userVoteInfoPerQuestion[qid][msg.sender].voteFlag = true;

        require(questions[qid].endTime > getCurrentTime(), "Question has reached end time");
        userVoteInfoPerQuestion[qid][msg.sender].choice = choice;
        
        // No Transfer for room or the optional token, just check how much the user is holding

        if (questions[qid].optionalERC20Address != address(0)) {
            uint256 optionalTokenBalance = IERC20(questions[qid].optionalERC20Address).balanceOf(msg.sender);
            require(optionalTokenBalance >= questions[qid].minOptionalERC20Holding, "User does not hold minimum optional room");
            questions[qid].optionalTokenHolding[choice] += optionalTokenBalance;
        }

        uint256 userPower = ICourtStake(courtStakeAddress).getUserPower(msg.sender);
        require(userPower >= questions[qid].minPower, "The user does not have minimum power to vote");
        
        userVoteInfoPerQuestion[qid][msg.sender].power = userPower;
        
        questions[qid].votesPower[choice] += userPower;
        questions[qid].votersCount++;
        questions[qid].votesCounts[choice]++;
        
        totalVotePowerPerQuestion[qid] += userPower;

        userPendingRewards[msg.sender].push(qid);
        
        if(blockWithdrawCourtFlag){
            ICourtStake(courtStakeAddress).blockWithdraw(msg.sender,questions[qid].endTime);
        }
        
        emit Vote(qid,choice);
    }

    function claimRewards() public {
        address account = msg.sender;

        int256 pendingVotedIndex = int256(userPendingRewards[account].length - 1);
        
        uint256 claimableRewards = 0;
        uint256 cTime = getCurrentTime();
        for (pendingVotedIndex; pendingVotedIndex >= 0; pendingVotedIndex--) {
            uint256 qid = userPendingRewards[account][uint256(pendingVotedIndex)];
            

            // if current time > question end time , then its reward are claimable 
            if (cTime > questions[qid].endTime) {
                
                ( , uint256 qClaimableRewards, uint256 qClaimedRewards) = getRewardInfoForQuestion(account,qid);
                
                if(qClaimedRewards == 0){
                    claimableRewards += qClaimableRewards;
                }
                userClaimedRewardPerQuestion[qid][account] = qClaimableRewards;
                
                // delete the question from pendingVotedIndex: by replace the current value by last value in the array, and remove last value
                userPendingRewards[account][uint256(pendingVotedIndex)] = userPendingRewards[account][userPendingRewards[account].length - 1];
                userPendingRewards[account].length--;
            }
        }

        userClaimedRewards[account] += claimableRewards;
        
        require(claimableRewards > 0, "no rewards to claim");

        ROOM.transfer(account, claimableRewards);
    }
    
    function claimQuestionRewards(uint256 qid) public {
        address account = msg.sender;

        int256 pendingVotedIndex = int256(userPendingRewards[account].length - 1);
        
        uint256 claimableRewards = 0;
        uint256 cTime = getCurrentTime();
        for (pendingVotedIndex; pendingVotedIndex >= 0; pendingVotedIndex--) {
            uint256 qid2 = userPendingRewards[account][uint256(pendingVotedIndex)];
            
            if(qid2 == qid)
            {
                require(cTime > questions[qid].endTime, "question still not reach end time");
                
                ( , uint256 qClaimableRewards, uint256 qClaimedRewards) = getRewardInfoForQuestion(account,qid);
                
                if(qClaimedRewards == 0){
                    claimableRewards += qClaimableRewards;
                }
                userClaimedRewardPerQuestion[qid][account] = qClaimableRewards;
                
                // delete the question from pendingVotedIndex: by replace the current value by last value in the array, and remove last value
                userPendingRewards[account][uint256(pendingVotedIndex)] = userPendingRewards[account][userPendingRewards[account].length - 1];
                userPendingRewards[account].length--;
            
            }
        }

        userClaimedRewards[account] += claimableRewards;
        
        require(claimableRewards > 0, "no rewards to claim");

        ROOM.transfer(account, claimableRewards);
    }

    function getRewardsInfo(address account) public view returns (uint256 expectedRewards, uint256 claimableRewards, uint256 claimedRewards) {

        int256 pendingVotedIndex = int256(userPendingRewards[account].length - 1);

        for (pendingVotedIndex; pendingVotedIndex >= 0; pendingVotedIndex--) {
            uint256 qid = userPendingRewards[account][uint256(pendingVotedIndex)];

            (uint256 qExpectedRewards, uint256 qClaimableRewards, ) = getRewardInfoForQuestion(account, qid);
            expectedRewards+=qExpectedRewards;
            claimableRewards+=qClaimableRewards;
        }
        
        claimedRewards = userClaimedRewards[account];
    }
    
    function getRewardInfoForQuestion(address account, uint256 qid) public view returns (uint256 expectedRewards, uint256 claimableRewards, uint256 claimedRewards){
        
        if(userVoteInfoPerQuestion[qid][msg.sender].voteFlag != true){
            return (0,0,0);
        }
        
        claimedRewards = userClaimedRewardPerQuestion[qid][account] ;
        
        if(claimedRewards >0){
            return (expectedRewards,claimableRewards,claimedRewards);
        }
        
        uint256 qReward = questions[qid].reward;
        
        uint256 qEquallyDistributedReward = qReward * questions[qid].rewardDistriputedEquallyPerc / 100;
        if( qEquallyDistributedReward > qReward){
            qEquallyDistributedReward = qReward;
        }
        
        uint256 userReward = qEquallyDistributedReward / questions[qid].votersCount;
        
        uint256 qPowerReward = qReward - qEquallyDistributedReward;
        
        userReward += ( qPowerReward * userVoteInfoPerQuestion[qid][account].power / totalVotePowerPerQuestion[qid]);
        
        
        if(getCurrentTime() < questions[qid].endTime){
            expectedRewards = userReward;
        }else{
            claimableRewards = userReward;
        }
        
    }

    function getQuestionsCount() public view returns (uint256) {
        return questions.length;
    }

    function getAllQuestions() public view returns (QuestionStruct[] memory) {
        return questions;
    }

    function getQuestionInfo(uint256 qid) public view returns (QuestionStruct memory) {
        return questions[qid];
    }

    function getChoices(uint256 qid) public view returns (string[] memory) {
        return questions[qid].choices;
    }

    function getQuestion(uint256 qid) public view returns (string memory question, string memory description, string[] memory choices) {
        question = questions[qid].question;
        choices = questions[qid].choices;
        description = questions[qid].description;
    }

    function getQuestionResult(uint256 qid) public view returns (uint256[] memory votes, uint256[] memory votesPower) {
        votes = questions[qid].votesCounts;
        votesPower = questions[qid].votesPower;
    }

    function getAccountInfo(address account) public view returns (KnownAccountStruct memory) {
        if (proposersIDMap[account] != 0) {
            return knownAccounts[proposersIDMap[account]];
        }
    }

    // configurations

    function addProposer(address account, uint256 minReward, uint256 fees, string memory name) public onlyGovOrGur {
        require(proposersIDMap[account] == 0, "address already added");

        proposersIDMap[account] = knownAccounts.length;

        knownAccounts.push(KnownAccountStruct({
        account : account,
        allowed : true,
        minReward : minReward,
        fees : fees,
        name : name
        }));

    }

    function updateProposer(address account, uint256 minReward, uint256 fees, bool allowed, string memory name) public onlyGovOrGur {
        uint256 proposerID = proposersIDMap[account];
        require(proposerID != 0, "account does not exist");

        knownAccounts[proposerID].minReward = minReward;
        knownAccounts[proposerID].fees = fees;
        knownAccounts[proposerID].allowed = allowed;
        knownAccounts[proposerID].name = name;

    }

    function setRoomAddress(address newAddress) public onlyGovOrGur {
        ROOM = IERC20(newAddress);
    }

    function setGMinPowerToVote(uint256 newMin) public onlyGovOrGur {
        gMinPowerToVote = newMin;
    }

    function setAnonymousProposerAllowed(bool allowedFlag) public onlyGovOrGur {
        anonymousProposerAllowed = allowedFlag;
    }

    function setAnonymousFees(uint256 newFees) public onlyGovOrGur {
        anonymousFees = newFees;
    }

    function setAnonymousMinReward(uint256 newMinReward) public onlyGovOrGur {
        anonymousMinReward = newMinReward;
    }

    function transferCollectedFees() public onlyGovOrGur {
        ROOM.transfer(msg.sender, feesCollected);
        feesCollected = 0;
    }
    
    function addCategory(string memory category) public {
        require(categoriesModifyPermission[msg.sender] == true, "user has no permission to add category");
        categories.push(category);
    }
    
    function modifyCategory(uint256 cid, string memory category) public {
        require(categoriesModifyPermission[msg.sender] == true, "user has no permission to modify category");
        require(cid < categories.length, "cid is not found");
        
        categories[cid] = category;
    }
    
    function setCategoriesModifyPermission(address account, bool permissionFlag) public onlyGovOrGur{
        categoriesModifyPermission[account] = permissionFlag;
    }
    
    function getAllCategories() public view returns(string[] memory){
        return categories;
    }
    
    function getCategoriesCount() public view returns(uint256){
        return categories.length;
    }
    
    function getCategories(uint256[] memory cids) public view returns(string[] memory categoriesStr){
        categoriesStr = new string[](cids.length);
        for(uint256 indx=0;indx<cids.length;indx++){
            categoriesStr[indx] = categories[indx];
        }
    }
    
    function getUserVote(uint256 qid, address account) public view returns(UserVoteInfo memory){
        return userVoteInfoPerQuestion[qid][account];
    }
    
    function setCourtStakeAddress(address newAddrerss) public onlyGovOrGur{
        courtStakeAddress = newAddrerss;
    }
    
    function setBlockWithdrawCourtFlag(bool newValue) public onlyGovOrGur{
        blockWithdrawCourtFlag = newValue;
    }
    
    function setMinQuestionDuration(uint256 duration) public onlyGovOrGur{
        minQuestionDuration = duration;
    }
    
    function setMaxQuestionDuration(uint256 duration) public onlyGovOrGur{
        maxQuestionDuration = duration;
    }
    
    function setMinEquallyDistriputedRewardPerc(uint256 perc) public onlyGovOrGur{
        require(perc <= 100, "perc is greater than 100");
        minEquallyDistriputedRewardPerc = perc;
    }
    
    function setMaxEquallyDistriputedRewardPerc(uint256 perc) public onlyGovOrGur{
        require(perc <= 100, "perc is greater than 100");
        maxEquallyDistriputedRewardPerc = perc;
    }
    
    function setQuestionEquallyDistriputedRewardPerc(uint256 qid,uint256 perc) public onlyGovOrGur{
        require(perc <= 100, "perc is greater than 100");
        require(questions[qid].endTime > getCurrentTime(), "can not change ereward distriputed equally perc for ended question");
        
        questions[qid].rewardDistriputedEquallyPerc = perc;
    }
    
    function setQuestionEndTime(uint256 qid, uint256 time) public onlyGovOrGur{
        require(questions[qid].endTime > getCurrentTime(), "can not change end time for ended question");
        questions[qid].endTime = time;
    }
    
    // recover any tokens send to this contract ( for emergancey, or tokens send by mistake)
    function retrieveToken(IERC20 tokenAddress, uint256 amount) public onlyGovOrGur{
        
        if(amount == 0){
            amount = tokenAddress.balanceOf(address(this));
        }
        tokenAddress.transfer(msg.sender, amount);
    }


    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }
}

contract OROracleInfoForTest is OROracleInfo {
    uint256 public currentTime = block.timestamp;

    function increaseTime(uint256 t) public {
        currentTime += t;
    }

    function getCurrentTime() public view returns (uint256) {
        //return block.timestamp;
        return currentTime;
    }
}