pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

contract TrustRank {   
    
    enum ClaimAction
    {
        none,
        upvote,
        downvote,
        created
    }
    
    struct UserTrustRank
    {
        int pointsAtStart;
        bool IsExist;
        int points;
    }
    
    struct UserClaimDetail
    {
        int points;
        ClaimAction action;
    }
    
    struct User
    {
        address id;
        string name;
        string icon;
        mapping (string => UserTrustRank) trustRankDetail;  //String = channel name     This is the channel-wise list of trust ranks
        mapping (uint => UserClaimDetail) userClaimList;    //uint = claim ID
    }

    struct Claim 
    {
        uint id;
        string title;
        string description;
        int credibilityScore;
        uint256 date;
        address ownerId;
        address[] upVoteList;           // an array of user IDs that have up voted this claim
        address[] downVoteList;         // an array of user IDs that have down voted this claim
        uint life;
        bool expired;
        string channel;
    }
    
    uint public usersCount;             //  REDUNDANT -> Please remove
    uint public claimsCount;
    address admin;
    mapping (address => User) public userList;
    mapping (uint => Claim) public claimList;
    Claim[] public allClaims; 
    string[] public channelList ;  
    
    constructor() public {
        channelList.push("");
        channelList.push("Overall");
        channelList.push("ICO");
        channelList.push("Technology");
        channelList.push("Sports");
        channelList.push("Politics-US");
        channelList.push("");
        
        admin = msg.sender;
        addUser(msg.sender, "Super Admin", "Technology", 100, "icons8-user-male-50.png");
        addNewChannelAndRankofuser(msg.sender, "Politics-US", 50);
      //  addUser(0xBd3a650424A16Ce32a9A66CFc49F5f1f999699B6, "Asim Iqbal", "Overall", 0, "icons8-businessman-48.png");
      // addUser(0x45BFd0eA306944efEcc17259A8f4020c83125F83, "Ahamd Zafarr", "Overall", 999, "icons8-user-male-48.png");

        addClaim("This claim is the first one I ever made",
            "Basically, what we are trying to show here is that the claims made here are ranked on their correctness or soundness through majority voting and credibility of voters",
             60, channelList[3]);

        addClaim("How much wood would a wood chuck chuck",
            "How much wood would a wood chuck chuck if a wood chuck could chuck wood",
             60, channelList[5]);
    }
    
    // function addUser(address user, string name, string channel, int initPoints, string icon) public {
    function addUser(address user, string name, string channel, int initPoints, string icon) public {
        // address user = address(uAddr);
        require(msg.sender == admin, "Only admin can add new user");        
        require((userList[user].id == 0),"The user is already registered");
        
        userList[user].id = user;
        userList[user].name = name;
        userList[user].trustRankDetail[channel].pointsAtStart = initPoints;
        userList[user].trustRankDetail[channel].points = initPoints;
        userList[user].trustRankDetail[channel].IsExist = true;
        userList[user].icon = string(abi.encodePacked("/images/", icon));
        usersCount++;        
    }
    
    function addNewChannelAndRankofuser(address user,string channelName, int points) public
    {   
        require(msg.sender == admin,"Only admin can add new channle and trustRank");        
        require(!(userList[user].id == 0),"The user is not registered");
        
        userList[user].trustRankDetail[channelName].pointsAtStart = points;
        userList[user].trustRankDetail[channelName].points = points;
        userList[user].trustRankDetail[channelName].IsExist = true;
        
    }
    
    function addClaim(string claimTitle, string claimDescription, uint life, string channelName) public
    {   
        require(!(userList[msg.sender].id == 0),"The user is not registered");

        claimList[claimsCount].id = claimsCount;
        claimList[claimsCount].title = claimTitle;
        claimList[claimsCount].description = claimDescription;
        claimList[claimsCount].date = now;
        claimList[claimsCount].life = life;
        claimList[claimsCount].ownerId = msg.sender;
        claimList[claimsCount].expired = false;
        claimList[claimsCount].channel = channelName;
        claimList[claimsCount].credibilityScore += userList[msg.sender].trustRankDetail[claimList[claimsCount].channel].points;
        claimsCount++;
        userList[msg.sender].userClaimList[claimsCount].action=ClaimAction.created;
    }
    
    function upvote(uint claimId, int score) public
    {   
        require(!(userList[msg.sender].id == 0),"The user is not registered");        
        require((userList[msg.sender].userClaimList[claimId].action == ClaimAction.none),"The user has already voted on this claim");
        require((claimList[claimId].ownerId != msg.sender),"Owner cannot upVote");
        
        
        claimList[claimId].upVoteList.push(userList[msg.sender].id);
        claimList[claimId].credibilityScore += userList[msg.sender].trustRankDetail[claimList[claimId].channel].points;
        userList[msg.sender].userClaimList[claimId].action = ClaimAction.upvote; 
    }
    
    function downvote(uint claimId, int score) public
    {   
        require(!(userList[msg.sender].id == 0),"The user is not registered");        
        require((userList[msg.sender].userClaimList[claimId].action == ClaimAction.none),"The user has already voted on this claim");
        require((claimList[claimId].ownerId != msg.sender),"Owner cannot downVote");
        
        claimList[claimId].downVoteList.push(userList[msg.sender].id);
        claimList[claimId].credibilityScore -= userList[msg.sender].trustRankDetail[claimList[claimId].channel].points;
        userList[msg.sender].userClaimList[claimId].action = ClaimAction.downvote; 
  
    }

    function getClaimData1(uint index) public returns ( string, string, uint256, string, string,int )
    {
        return(claimList[index].title,
        claimList[index].description,
        claimList[index].date,
        userList[claimList[index].ownerId].name,
        userList[claimList[index].ownerId].icon,
        claimList[index].credibilityScore
        );
    }
    function getClaimData2(uint index) public returns ( uint, uint, uint, uint, bool, string)
    {
        return(claimList[index].upVoteList.length,
        claimList[index].downVoteList.length,
        claimList[index].id,
        claimList[index].life,
        claimList[index].expired,
        claimList[index].channel
        );
    }
    function getClaimData3(uint index) public returns (int)
    {
        return userList[claimList[index].ownerId].trustRankDetail[claimList[index].channel].points;
    }

    function append(string b, string c, string d) internal pure returns (string) 
    {
        return string(abi.encodePacked(b, "~", c, "~", d));
    }   

    function checkClaimExpiry ( ) public
    {
        for ( uint i = 0 ; i < claimsCount ; i++ )
        {
            if ( ( claimList[i].date + claimList[i].life ) < now && !claimList[i].expired )
            {
                claimList[i].expired = true;
                updateTrustRank (i);
            }
        }
    } 

    function updateTrustRank ( uint i) public
    {
        if(claimList[i].credibilityScore > 0 )
        {
            userList[claimList[i].ownerId].trustRankDetail[claimList[i].channel].points+=5;
        }
        else if(claimList[i].credibilityScore < 0 )
        {
            userList[claimList[i].ownerId].trustRankDetail[claimList[i].channel].points-=5;
        }

        
        for (uint j =0; j < claimList[i].upVoteList.length; j++)
        {
            if(claimList[i].credibilityScore > 0 )
            {
                userList[claimList[i].upVoteList[j]].trustRankDetail[claimList[i].channel].points +=1;
            }
            else if(claimList[i].credibilityScore < 0 )
            {
                userList[claimList[i].upVoteList[j]].trustRankDetail[claimList[i].channel].points -=1;
            }
        }
        for (uint k =0; k < claimList[i].downVoteList.length ; k++)
        {
            if(claimList[i].credibilityScore > 0 )
            {
                userList[claimList[i].downVoteList[j]].trustRankDetail[claimList[i].channel].points -=1;
            }
            else if(claimList[i].credibilityScore < 0 )
            {
                userList[claimList[i].downVoteList[j]].trustRankDetail[claimList[i].channel].points +=1;
            }
        }

    }

    function checkAdmin ( ) public constant returns (bool)
    {
        if (msg.sender == admin) return true ;
        return false ;
    }

    function getChannelList ( ) public constant returns ( string[] )
    {
        return channelList ;
    }

}