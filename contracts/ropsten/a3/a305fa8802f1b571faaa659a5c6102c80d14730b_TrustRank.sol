pragma solidity ^0.4.24;

contract Token {
   
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

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

     function () {
        //if ether is sent to this address, send it back.
        throw;
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

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract TrustRank {   
    
    struct ClaimDetail {
        int credibilityScore;
        address claimCreatorId;
        address[] upVotersList;           
        address[] downVotersList;         
    }

    struct StoryDetail {
        mapping (bytes12 => ClaimDetail) claimList; //Claim Detail claimId => claimDetail
        uint claimsCount;
        bytes12 channelId;
        uint expiry;
        address storyCreator;
    }
    
    uint public UP_VOTE_TOKENS = 1;
    uint public DOWN_VOTE_TOKENS = 1;
    uint public CREATE_CLAIM_TOKENS = 5;

    TRToken public tokenContract;
    address admin;  
    mapping (address => mapping (bytes12 => int)) public userTrustRank; // Users channel wise Trust Rank (userId => channelId => trustRank)
    mapping (bytes12 => StoryDetail) public storiesDetail;  // Story Detail (storyId => storyDetail)

    constructor (TRToken _tokenContract) public {
        tokenContract = _tokenContract;
        admin = msg.sender;
    }
    
    function updateUserTrustRankForMultipleChannels(address _userId, bytes12[] _channelIdsList, int[] _pointsList) public {   
        require(msg.sender == admin,"Only admin can update trustRank for user");
        for (uint i = 0; i < _channelIdsList.length; i++) {
            userTrustRank[_userId][_channelIdsList[i]] = _pointsList[i];
        }
    }
    
    function addStory(bytes12 _storyId, bytes12 _channelId, uint _sponserTokens, uint expiryTime) public {
        require(tokenContract.transfer(address(this),_sponserTokens),"Insufficient No of Trust Rank Tokens");
        storiesDetail[_storyId].channelId = _channelId;
        storiesDetail[_storyId].expiry = expiryTime;
        storiesDetail[_storyId].claimsCount = 0;
        storiesDetail[_storyId].storyCreator = msg.sender;
    }

    function addClaim(bytes12 _storyId, bytes12 _claimId) public {   
        require(tokenContract.transfer(address(this),CREATE_CLAIM_TOKENS),"Insufficient No of Trust Rank Tokens");
        require (now < storiesDetail[_storyId].expiry,"Story has been expired");
        storiesDetail[_storyId].claimsCount += 1;
        storiesDetail[_storyId].claimList[_claimId].claimCreatorId = msg.sender;
        storiesDetail[_storyId].claimList[_claimId].credibilityScore += userTrustRank[msg.sender][storiesDetail[_storyId].channelId];
    }
    
    function upVote(bytes12 _storyId, bytes12 _claimId) public {   
        require(tokenContract.transfer(address(this),UP_VOTE_TOKENS),"Insufficient No of Trust Rank Tokens");
        require (now < storiesDetail[_storyId].expiry,"Story has been expired");
        storiesDetail[_storyId].claimList[_claimId].upVotersList.push(msg.sender);
        storiesDetail[_storyId].claimList[_claimId].credibilityScore += userTrustRank[msg.sender][storiesDetail[_storyId].channelId];
    }
    
    function downVote(bytes12 _storyId, bytes12 _claimId) public {   
        require(tokenContract.transfer(address(this),DOWN_VOTE_TOKENS),"Insufficient No of Trust Rank Tokens");
        require (now < storiesDetail[_storyId].expiry,"Story has been expired");
        storiesDetail[_storyId].claimList[_claimId].downVotersList.push(msg.sender);
        storiesDetail[_storyId].claimList[_claimId].credibilityScore -= userTrustRank[msg.sender][storiesDetail[_storyId].channelId];
    }
    
    function updateTrustRankAfterStoryExpiry (bytes12 _storyId, bytes12[] _claimsId) public {

        require(msg.sender == admin,"Only admin can update trustRank for user");
        require(storiesDetail[_storyId].claimsCount == _claimsId.length, "Some Claims are missing");
        for (uint i = 0 ; i < storiesDetail[_storyId].claimsCount ; i++) {
      
            if (storiesDetail[_storyId].claimList[_claimsId[i]].credibilityScore > 0) {
                userTrustRank[storiesDetail[_storyId].claimList[_claimsId[i]].claimCreatorId][storiesDetail[_storyId].channelId] += 5;
                for (uint j = 0; j < storiesDetail[_storyId].claimList[_claimsId[i]].upVotersList.length; j++) {
                    userTrustRank[storiesDetail[_storyId].claimList[_claimsId[i]].upVotersList[j]][storiesDetail[_storyId].channelId] += 1;
                }
                for (uint k = 0; k < storiesDetail[_storyId].claimList[_claimsId[i]].downVotersList.length; k++) {
                    userTrustRank[storiesDetail[_storyId].claimList[_claimsId[i]].downVotersList[k]][storiesDetail[_storyId].channelId] -= 1;
                }
            } else { // credibilityScore <= 0
                userTrustRank[storiesDetail[_storyId].claimList[_claimsId[i]].claimCreatorId][storiesDetail[_storyId].channelId] -= 5;
                for ( uint l = 0; l < storiesDetail[_storyId].claimList[_claimsId[i]].upVotersList.length; l++) {
                    userTrustRank[storiesDetail[_storyId].claimList[_claimsId[i]].upVotersList[l]][storiesDetail[_storyId].channelId] -= 1;
                }
                for ( uint m = 0; m < storiesDetail[_storyId].claimList[_claimsId[i]].downVotersList.length; m++) {
                    userTrustRank[storiesDetail[_storyId].claimList[_claimsId[i]].downVotersList[m]][storiesDetail[_storyId].channelId] += 1;
                }
            }
        }
    }

    function distributeFinancialAward (address[] _usersId, uint[] _noOfTokens) public {
        require (_usersId.length == _noOfTokens.length, "Arrays length are not same");
        require (msg.sender == admin, "Only admin can distribute tokens");
        for (uint i = 0 ; i < _usersId.length ; i++) {
            require(tokenContract.transfer(_usersId[i],_noOfTokens[i]),"Insufficient No of Trust Rank Tokens");
        }
    }

    function getcredibilityScore (bytes12 _storyId, bytes12 _claimsId) public view returns (int) {
        return storiesDetail[_storyId].claimList[_claimsId].credibilityScore;
    }

    function getStoryExpiry (bytes12 _storyId) public view returns (uint) {
        return storiesDetail[_storyId].expiry;
    }
}