pragma solidity >=0.5.0;

contract Token {
   
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TRToken is Token {

    string  public name = "TR Token";
    string  public symbol = "TRT";
    uint8 public decimals = 0;
    string  public version = "TRT Token v1.0";
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


     constructor (uint256 _initialSupply) public {
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {return false;}
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {return false;}
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract TrustRank is TRToken{   
    
    enum UserAction { None, Created, UpVote, DownVote }
    

    struct ClaimDetail {
        int credibilityScore;
        address claimCreatorId;
        address[] upVotersList;           
        address[] downVotersList;
    }

    
    struct StoryDetail {
        mapping (bytes12 => ClaimDetail) claimList; //Claim Detail claimId => claimDetail
        bytes12[] claimIds;
        uint claimsCount;
        mapping (address => UserAction) users; // A user can perform only one action(addClaim,Vote) in a story
        bytes12 channelId;
        uint expiry;
        uint sponsorTokens;
        address storyCreator;
    }
    
    uint public UP_VOTE_TOKENS = 2;
    uint public DOWN_VOTE_TOKENS = 2;
    uint public CREATE_CLAIM_TOKENS = 10;

   
    int public UP_VOTE_TRUST_RANK = 1; 
    int public DOWN_VOTE_TRUST_RANK = 1;
    int public CREATE_CLAIM_TRUST_RANK = 5;
    


    address payable owner;  
    mapping (address => mapping (bytes12 => int)) public userTrustRank; // Users channel wise Trust Rank (userId => channelId => trustRank)
    mapping (bytes12 => StoryDetail) public storiesDetail;  // Story Detail (storyId => storyDetail)


    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier sufficientTokensForAction(uint _tokens) {
        require(transfer(owner,_tokens),"Insufficient No of TR Tokens for this action");
        _;
    }

    modifier storyExpiry(bytes12 _storyId) {
        require (now < storiesDetail[_storyId].expiry,"Story has been expired");
        _;
    }

    modifier alreayActionOnStory(bytes12 _storyId, address _userAddress) {
        require (storiesDetail[_storyId].users[_userAddress] != UserAction.None,"Alredy perform action on this");
        _;
    }

    constructor (uint256 totalSupply) TRToken (totalSupply) public {
        owner = msg.sender;
    }
    
    function changeOwner(address payable _user) public onlyOwner {
        owner = _user;
    }

    function updateUserTrustRankForMultipleChannels(address _userId, bytes12[] memory _channelIdsList, int[] memory _pointsList) public onlyOwner {   
        for (uint i = 0; i < _channelIdsList.length; i++) {
            userTrustRank[_userId][_channelIdsList[i]] = _pointsList[i];
        }
    }
    
    function addStory(bytes12 _storyId, bytes12 _channelId, uint _sponsorTokens, uint expiryTime) public  sufficientTokensForAction(_sponsorTokens){
        storiesDetail[_storyId].channelId = _channelId;
        storiesDetail[_storyId].expiry = expiryTime;
        storiesDetail[_storyId].claimsCount = 0;
        storiesDetail[_storyId].storyCreator = msg.sender;
        storiesDetail[_storyId].sponsorTokens = _sponsorTokens;
    }

    function addClaim(bytes12 _storyId, bytes12 _claimId) public sufficientTokensForAction(CREATE_CLAIM_TOKENS) storyExpiry(_storyId) alreayActionOnStory(_storyId,msg.sender) {   
        storiesDetail[_storyId].claimsCount += 1;
        storiesDetail[_storyId].claimIds.push(_claimId);
        storiesDetail[_storyId].claimList[_claimId].claimCreatorId = msg.sender;
        storiesDetail[_storyId].claimList[_claimId].credibilityScore += userTrustRank[msg.sender][storiesDetail[_storyId].channelId];
    }
    
    function upVote(bytes12 _storyId, bytes12 _claimId) public sufficientTokensForAction(UP_VOTE_TOKENS) storyExpiry(_storyId) alreayActionOnStory(_storyId,msg.sender){   
        storiesDetail[_storyId].claimList[_claimId].upVotersList.push(msg.sender);
        storiesDetail[_storyId].claimList[_claimId].credibilityScore += userTrustRank[msg.sender][storiesDetail[_storyId].channelId];
    }
    
    function downVote(bytes12 _storyId, bytes12 _claimId) public sufficientTokensForAction(DOWN_VOTE_TOKENS) storyExpiry(_storyId) alreayActionOnStory(_storyId,msg.sender){
        storiesDetail[_storyId].claimList[_claimId].downVotersList.push(msg.sender);
        storiesDetail[_storyId].claimList[_claimId].credibilityScore -= userTrustRank[msg.sender][storiesDetail[_storyId].channelId];
    }
    
    function updateTrustRankAfterStoryExpiry (bytes12 _storyId) public onlyOwner {

        bytes12 highestCredibilityScoreClaimId;
        int maxCredbilityScore = 0;
        for (uint i = 0 ; i < storiesDetail[_storyId].claimsCount ; i++) {
      
            if (storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].credibilityScore > 0) {
                if(maxCredbilityScore < storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].credibilityScore){
                    maxCredbilityScore = storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].credibilityScore;
                    highestCredibilityScoreClaimId = storiesDetail[_storyId].claimIds[i];
                }
                userTrustRank[storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].claimCreatorId][storiesDetail[_storyId].channelId] += CREATE_CLAIM_TRUST_RANK;
                transfer(storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].claimCreatorId,CREATE_CLAIM_TOKENS);
                for (uint j = 0; j < storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].upVotersList.length; j++) {
                    userTrustRank[storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].upVotersList[j]][storiesDetail[_storyId].channelId] += UP_VOTE_TRUST_RANK;
                transfer(storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].upVotersList[j],UP_VOTE_TOKENS);
                }
                for (uint k = 0; k < storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].downVotersList.length; k++) {
                    userTrustRank[storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].downVotersList[k]][storiesDetail[_storyId].channelId] -= DOWN_VOTE_TRUST_RANK;
                }
            } else { // credibilityScore <= 0
                userTrustRank[storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].claimCreatorId][storiesDetail[_storyId].channelId] -= CREATE_CLAIM_TRUST_RANK;
                for ( uint l = 0; l < storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].upVotersList.length; l++) {
                    userTrustRank[storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].upVotersList[l]][storiesDetail[_storyId].channelId] -= UP_VOTE_TRUST_RANK;
                }
                for ( uint m = 0; m < storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].downVotersList.length; m++) {
                    userTrustRank[storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].downVotersList[m]][storiesDetail[_storyId].channelId] += DOWN_VOTE_TRUST_RANK;
                    transfer(storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimIds[i]].downVotersList[m],DOWN_VOTE_TOKENS);
                }
            }
        }

        distributeFinancialAward(_storyId,maxCredbilityScore,highestCredibilityScoreClaimId);

    }

    function distributeFinancialAward (bytes12 _storyId, int _credibilityScore, bytes12 _claimId) private {
        if(_credibilityScore <=0 ) { // if no claim found with credibilityScore > 0 then return all tokens to story creator
            transfer(storiesDetail[_storyId].storyCreator,storiesDetail[_storyId].sponsorTokens);
        } else {                                      //Ratio claim Creator : upvoters   5:1   // 1 for each voters
            uint sumOfRatio = 5 + storiesDetail[_storyId].claimList[_claimId].upVotersList.length;
            uint claimCreatorAward = (storiesDetail[_storyId].sponsorTokens - (storiesDetail[_storyId].sponsorTokens % sumOfRatio)) /sumOfRatio * 5;
            uint oneUpvoterAward = (storiesDetail[_storyId].sponsorTokens - (storiesDetail[_storyId].sponsorTokens % sumOfRatio)) /sumOfRatio;
            transfer(storiesDetail[_storyId].claimList[_claimId].claimCreatorId, claimCreatorAward);
             for (uint n = 0; n < storiesDetail[_storyId].claimList[_claimId].upVotersList.length; n++) {
                   transfer(storiesDetail[_storyId].claimList[_claimId].upVotersList[n],oneUpvoterAward);
                }
        }
    }

    function getCredibilityScoreOfClaim (bytes12 _storyId, bytes12 _claimId) public view returns (int) {
        return storiesDetail[_storyId].claimList[_claimId].credibilityScore;
    }

    function getStoryExpiryTime (bytes12 _storyId) public view returns (uint) {
        return storiesDetail[_storyId].expiry;
    }

    function getClaimsCountForStory(bytes12 _storyId) public view returns (uint) {
        return storiesDetail[_storyId].claimsCount;
    }

    function getUpVoteCount(bytes12 _storyId, bytes12 _claimId) public view returns (uint) {
        return storiesDetail[_storyId].claimList[_claimId].upVotersList.length;
    }

    function getDownVoteCount(bytes12 _storyId, bytes12 _claimId) public view returns (uint) {
        return storiesDetail[_storyId].claimList[_claimId].downVotersList.length;
    }

    function getUserActionOnStory (bytes12 _storyId, address _userAddress) public view returns (string memory _action) {
        if(storiesDetail[_storyId].users[_userAddress] == UserAction.None){
            _action = "None";
        }
        else if(storiesDetail[_storyId].users[_userAddress] == UserAction.Created){
            _action =  "Created";
        }
        else if(storiesDetail[_storyId].users[_userAddress] == UserAction.UpVote){
            _action =  "UpVote";
        }
        else if(storiesDetail[_storyId].users[_userAddress] == UserAction.DownVote){
            _action =  "DownVote";
        }
    }
}