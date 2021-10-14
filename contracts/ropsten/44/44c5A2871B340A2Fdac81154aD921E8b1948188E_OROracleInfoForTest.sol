/**
 *Submitted for verification at Etherscan.io on 2021-10-14
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
        address creator;
        uint256 minPower;
        address optionalERC20Address;
        uint256 minOptionalERC20Holding;
        uint256 reward;
        uint256 choicesLen;
        string question;
        string[] choices;
        uint256 votersCount;
        uint256[] votesCounts;
        uint256[] roomHolding;
        uint256[] optionalTokenHolding;
        uint256 createdTime;
        uint256 endTime;
        uint256[] categoriesIndices;
        string description;
    }

    struct KnownAccountStruct {
        address account;
        bool allowed;
        uint256 minReward;
        uint256 fees;
        string name;
    }

    IERC20 public ROOM = IERC20(0x460A9872c00f01172d9efE9a3d6971475212517b);//TODO
    uint256 public gMinPowerToVote; //TODO

    bool public anonymousProposerAllowed = true; //TODO
    uint256 public anonymousFees; //TODO
    uint256 public anonymousMinReward; //TODO

    uint256 public feesCollected;

    QuestionStruct[] public questions;

    KnownAccountStruct[] public knownAccounts;
    mapping(address => uint256) proposersIDMap;

    mapping(uint256 => mapping(address => bool)) public voteCheck;
    mapping(uint256 => mapping(address => uint8)) public userVote;

    mapping(address => uint256[]) userPendingRewards;
    mapping(address => uint256) userClaimedRewards;
    
    mapping(address => bool) categoriesModifyPermission;
    
    address public courtStakeAddress;
    bool blockWithdrawCourtFlag = true;
    
    string[] public categories;
    
    event QuestionCreated(address indexed creator, uint256 indexed qid);
    event Vote(uint256 indexed qid, uint8 choice);

    constructor() public {
        addProposer(address(this), 0, 0, "");
    }

    function createQuestion(string memory question, string[] memory choices, uint256 reward, uint256 endTime, uint256 minPowerAboveDefault, address optionalERC20Address, uint256 minOptionalERC20Holding, uint256[] memory categoriesIndices, string memory description) public returns (uint256 qid) {
        address account = msg.sender;
        uint256 proposerID = proposersIDMap[account];
        uint256 fees;
        uint256 minReward;
        if(optionalERC20Address != address(0) ){
            require(IERC20(optionalERC20Address).balanceOf(address(this)) >= 0, "check optinal IERC20 address");
        }
        
        if (proposerID == 0) {
            require(anonymousProposerAllowed == true, "anonymous proposer is not allowed");
            minReward = anonymousMinReward;
            fees = anonymousFees;

        } else {
            require(knownAccounts[proposerID].allowed == true, "account suspended");
            fees = knownAccounts[proposerID].fees;
            minReward = knownAccounts[proposerID].minReward;
        }
        
        

        ROOM.transferFrom(account, address(this), fees);
        feesCollected += fees;

        ROOM.transferFrom(account, address(this), reward);

        return _createQuestion(question, choices, reward, endTime, minPowerAboveDefault, optionalERC20Address, minOptionalERC20Holding, categoriesIndices, description);
    }
    
    function _createQuestion(string memory question, string[] memory choices, uint256 reward, uint256 endTime, uint256 minPowerAboveDefault, address optionalERC20Address, uint256 minOptionalERC20Holding, uint256[] memory categoriesIndices, string memory description) internal returns (uint256 qid){
        require(choices.length >= 2, "choices must be at least 2");
        uint256[] memory votes = new uint256[](choices.length);
        uint256[] memory votesPower = new uint256[](choices.length);
        uint256[] memory optionalTokenHolding = new uint256[](choices.length);

        qid = questions.length;

        questions.push(QuestionStruct({
            optionalERC20Address : optionalERC20Address,
            minOptionalERC20Holding : minOptionalERC20Holding,
            minPower : gMinPowerToVote + minPowerAboveDefault,
            qid : questions.length,
            creator : msg.sender,
            reward : reward,
            choicesLen : choices.length,
            question : question,
            choices : choices,
            votesCounts : votes,
            roomHolding : votesPower,
            optionalTokenHolding : optionalTokenHolding,
            createdTime : block.timestamp,
            endTime : endTime,
            votersCount : 0,
            categoriesIndices: categoriesIndices,
            description: description
        }));
        
        emit QuestionCreated(msg.sender,qid);
    }


    function vote(uint256 qid, uint8 choice) public {
        require(voteCheck[qid][msg.sender] == false, "User already voted for this question");
        voteCheck[qid][msg.sender] = true;

        uint256 cTime = getCurrentTime();

        require(questions[qid].endTime > cTime, "Question has reached end time");
        userVote[qid][msg.sender] = choice;
        // No Transfer for room or the optional token, just check how much the user is holding

        if (questions[qid].optionalERC20Address != address(0)) {
            uint256 optionalTokenBalance = IERC20(questions[qid].optionalERC20Address).balanceOf(msg.sender);
            require(optionalTokenBalance >= questions[qid].minOptionalERC20Holding, "User does not hold minimum optional room");
            questions[qid].optionalTokenHolding[choice] += optionalTokenBalance;
        }

        //uint256 roomBalance = ROOM.balanceOf(msg.sender);
        //require(roomBalance >= questions[qid].minRoomHolding, "The user does not hold minimum room");
        uint256 userPower = ICourtStake(courtStakeAddress).getUserPower(msg.sender);
        //require(userPower >= )
        questions[qid].roomHolding[choice] += userPower;

        questions[qid].votersCount++;
        questions[qid].votesCounts[choice]++;

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

            uint256 reward = 0;
            reward = questions[qid].reward / questions[qid].votersCount;

            // if current time > question end time , then its reward are claimable 
            if (cTime > questions[qid].endTime) {
                claimableRewards += reward;

                // delete the question from pendingVotedIndex: by replace the current value by last value in the array, and remove last value
                userPendingRewards[account][uint256(pendingVotedIndex)] = userPendingRewards[account][userPendingRewards[account].length - 1];
                userPendingRewards[account].length--;
            }
        }

        userClaimedRewards[account] += claimableRewards;

        ROOM.transfer(account, claimableRewards);
    }

    function getRewardsInfo(address account) public view returns (uint256 expectedRewards, uint256 claimableRewards) {

        int256 pendingVotedIndex = int256(userPendingRewards[account].length - 1);

        uint256 cTime = getCurrentTime();
        for (pendingVotedIndex; pendingVotedIndex >= 0; pendingVotedIndex--) {
            uint256 qid = userPendingRewards[account][uint256(pendingVotedIndex)];

            uint256 reward = 0;
            reward = questions[qid].reward / questions[qid].votersCount;

             // if current time > question end time , then its reward are claimable else its in pending state
            if (cTime >questions[qid].endTime) {
                claimableRewards += reward;
            } else {
                expectedRewards += reward;
            }
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
        votesPower = questions[qid].roomHolding;
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
    
    function getUserVote(uint256 qid, address account) public view returns(bool voteFlag, uint8 choice){
        voteFlag = voteCheck[qid][account];
        choice = userVote[qid][account];
    }
    
    function setCourtStakeAddress(address newAddrerss) public onlyGovOrGur{
        courtStakeAddress = newAddrerss;
    }
    
    function setBlockWithdrawCourtFlag(bool newValue) public onlyGovOrGur{
        blockWithdrawCourtFlag = newValue;
    }


    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }
}

contract OROracleInfoForTest is OROracleInfo {
    uint256 public currentTime = 0;

    function increaseTime(uint256 t) public {
        currentTime += t;
    }

    function getCurrentTime() public view returns (uint256) {
        //return block.timestamp;
        return currentTime;
    }
}