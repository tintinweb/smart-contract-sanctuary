pragma solidity ^0.4.24;

contract Token {
   
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TRToken is Token {

    string  public name = "TR Token";
    string  public symbol = "TRT";
    uint8 public decimals = 4;
    string  public version = "TRT Token v1.0";
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


    function TRToken (uint256 _initialSupply) public {
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

     function () {
        //if ether is sent to this address, send it back.
        throw;
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {return false;}
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {return false;}
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}
contract TrustRank {   
    
    struct ClaimDetail 
    {
        int credibilityScore;
        address claimCreatorId;
        address[] upVotersList;           
        address[] downVotersList;         
    }

    struct StoryDetail
    {
        //Claim Detail claimId => claimDetail
        mapping (uint => ClaimDetail) claimList;
        uint claimsCount;
        uint channelId;
    }
    
    TRToken public tokenContract;
    address admin;
    // Users channel wise Trust Rank (userId => channelId => trustRank)
    mapping (address => mapping (uint => int)) public userTrustRank;
    // Story Detail (storyId => storyDetail)
    mapping (uint => StoryDetail) public storiesDetail;

    constructor(TRToken _tokenContract) public 
    {
        tokenContract = _tokenContract;
        admin = msg.sender;
    }
    
    function UpdateUserTrustRankForMultipleChannels(address _userId,uint[] _channelIdsList, int[] _pointsList) public
    {   
        require(msg.sender == admin,"Only admin can update trustRank for user");
        for (uint i = 0; i < _channelIdsList.length; i++) {
            userTrustRank[_userId][_channelIdsList[i]] = _pointsList[i];
        }
    }
    
    function AddStory(uint _storyId, uint _channelId, uint _sponserTokens) public
    {
        require(tokenContract.transfer(admin,_sponserTokens),"Insufficient No of Trust Rank Tokens");
        storiesDetail[_storyId].channelId = _channelId;
        storiesDetail[_storyId].claimsCount = 0;
    }

    function AddClaim(uint _storyId) public
    {   
        require(tokenContract.transfer(admin,10),"Insufficient No of Trust Rank Tokens");
        storiesDetail[_storyId].claimsCount += 1;
        storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimsCount].claimCreatorId = msg.sender;
        storiesDetail[_storyId].claimList[storiesDetail[_storyId].claimsCount].credibilityScore += userTrustRank[msg.sender][storiesDetail[_storyId].channelId];
    }
    
    function UpVote(uint _storyId, uint _claimId) public
    {   
        require(tokenContract.transfer(admin,2),"Insufficient No of Trust Rank Tokens");
        storiesDetail[_storyId].claimList[_claimId].upVotersList.push(msg.sender);
        storiesDetail[_storyId].claimList[_claimId].credibilityScore += userTrustRank[msg.sender][storiesDetail[_storyId].channelId];
    }
    
    function DownVote(uint _storyId, uint _claimId) public
    {   
        require(tokenContract.transfer(admin,2),"Insufficient No of Trust Rank Tokens");
        storiesDetail[_storyId].claimList[_claimId].downVotersList.push(msg.sender);
        storiesDetail[_storyId].claimList[_claimId].credibilityScore -= userTrustRank[msg.sender][storiesDetail[_storyId].channelId];
    }
    
    function UpdateTrustRankAfterStoryExpiry (uint _storyId) public
    {
        require(msg.sender == admin,"Only admin can update trustRank for user");
        for( uint i = 0 ; i < storiesDetail[_storyId].claimsCount ; i++)
        {
            if( storiesDetail[_storyId].claimList[i].credibilityScore > 0)
            {
                userTrustRank[storiesDetail[_storyId].claimList[i].claimCreatorId][storiesDetail[_storyId].channelId] += 5;
                require(tokenContract.transfer(storiesDetail[_storyId].claimList[i].claimCreatorId,10),"Insufficient No of Trust Rank Tokens");
                for( uint j = 0; j < storiesDetail[_storyId].claimList[i].upVotersList.length; j++)
                {
                    userTrustRank[storiesDetail[_storyId].claimList[i].upVotersList[j]][storiesDetail[_storyId].channelId] += 1;
                    require(tokenContract.transfer(storiesDetail[_storyId].claimList[i].upVotersList[j],2),"Insufficient No of Trust Rank Tokens");
                }
                for( uint k = 0; k < storiesDetail[_storyId].claimList[i].downVotersList.length; k++)
                {
                    userTrustRank[storiesDetail[_storyId].claimList[i].downVotersList[k]][storiesDetail[_storyId].channelId] -= 1;
                }
            }
            else
            {
                userTrustRank[storiesDetail[_storyId].claimList[i].claimCreatorId][storiesDetail[_storyId].channelId] -= 5;
                for( uint l = 0; l < storiesDetail[_storyId].claimList[i].upVotersList.length; l++)
                {
                    userTrustRank[storiesDetail[_storyId].claimList[i].upVotersList[l]][storiesDetail[_storyId].channelId] -= 1;
                }
                for( uint m = 0; m < storiesDetail[_storyId].claimList[i].downVotersList.length; m++)
                {
                    userTrustRank[storiesDetail[_storyId].claimList[i].downVotersList[m]][storiesDetail[_storyId].channelId] += 1;
                    require(tokenContract.transfer(storiesDetail[_storyId].claimList[i].downVotersList[m],2),"Insufficient No of Trust Rank Tokens");
               
                }
            }
        }
    }

    function DistributeFinancialAward (address [] _usersId , uint [] _noOfTokens) public
    {
        require (_usersId.length == _noOfTokens.length, "Arrays length are not same");
        require (msg.sender == admin, "Only admin can distribute tokens");
        for(uint i = 0 ; i < _usersId.length ; i++)
        {
            require(tokenContract.transfer(_usersId[i],_noOfTokens[i]),"Insufficient No of Trust Rank Tokens");
        }
    }
}