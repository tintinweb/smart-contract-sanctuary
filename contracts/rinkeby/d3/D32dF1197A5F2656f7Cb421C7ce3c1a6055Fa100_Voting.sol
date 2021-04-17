/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

interface Membership {
    
    struct MemberDetail {
        uint id;
        bool MemberPaid;
        bool MemberKYC;
        bool Certifier;
        bool Champion;
        string[] Values;
        string Entity;
        uint VotingPoints;
    }

    function isMember(address user) external view returns(bool);
    
    function isVoter(address user) external view returns(bool);
    
    function getVotingPoints(address user) external view returns(uint);
    
    function info(address _add) external view returns(MemberDetail memory);
    
    function subVotingPoints(address _add, uint _val) external;
    
}

contract Voting { 
    
    struct Post {
        address user;
        uint parent;
        string value;
        uint weight;
        uint upvote;
        uint timestamp;
        uint downvote;
        uint votingMechanism;
    }
    
    struct member {
        uint upvotes;
        uint downvotes;
        uint votes;
    }
    
    struct returnPost {
        uint weight;
        address user;
        string value;
        uint upvote;
        uint parent;
        uint timestamp;
        uint downvote;
        uint votingMechanism;
        uint hasUpvoted;
        uint hasDownvoted;
        uint votes;
    }
    
    uint256 id = 0;
    
    
    mapping(uint => Post) public posts;
    mapping(uint => mapping(address => member)) public memberVote;
    
    uint256[] allIDs;
    uint256[] postIDs;
    uint256[] commentIDs;
    
    Membership mem;
    
    address admin;
    
    event pointsDeducted(address, uint, uint);
    
    constructor(Membership _address) public {
        admin = msg.sender;
        mem = _address;
    }

    // modifier onlyOwner() {
    //     require(msg.sender == admin,"You are not an admin");
    //     _;
    // }

    
    modifier arkMember(address user) {
        require(mem.isMember(user),"You are not a member");
        _;
    }
    
    modifier arkVoter(address user) {
        
        require(mem.isVoter(user),"You are not a Voter");
        _;
    }
    
    function getPost(uint _id) public view arkMember(msg.sender) returns(returnPost memory) {
        returnPost memory rpst = returnPost(posts[_id].weight, posts[_id].user, posts[_id].value, posts[_id].upvote, posts[_id].parent, posts[_id].timestamp, posts[_id].downvote, posts[_id].votingMechanism, memberVote[_id][msg.sender].upvotes, memberVote[_id][msg.sender].downvotes, memberVote[_id][msg.sender].votes);
        return rpst;
    } 
    
    function totalPost() public view returns(uint256[] memory) {
        return allIDs;
    }
    
    function totalCmnt() public view returns(uint256[] memory) {
        return commentIDs;
    }
    
    function allPosts() public view returns(uint[] memory) {
        return postIDs;
    }

    function addPost(string memory _value, uint votingMechanism, uint wt) public arkMember(msg.sender) returns(uint) {
        id += 1;
        posts[id].user = msg.sender;
        posts[id].value = _value;
        posts[id].timestamp = now;
        posts[id].weight = wt;
        posts[id].votingMechanism = votingMechanism;
        postIDs.push(id);
        allIDs.push(id);
        return id;
    }
    
    function statusOwner(uint _id) public view returns(address) {
        require(posts[_id].user!=address(0),"Invalid id");
        return posts[_id].user;
    }
    
    function deletePost(uint _id) public {
        require(posts[_id].user == msg.sender,"You are an Imposter");
            posts[_id].user = address(0);
            posts[_id].value = "";
            posts[_id].upvote = 0;
            posts[_id].downvote = 0;
            posts[id].weight = 0;
            posts[_id].parent = 0;
            posts[_id].timestamp = 0;
            posts[_id].votingMechanism = 0;
        
    }
    
    function postComment( uint _parent, string memory _value, uint votingMechanism, uint wt) public arkVoter(msg.sender) {
        id += 1;
        posts[id].user = msg.sender;
        posts[id].parent = _parent;
        posts[id].value = _value; 
        posts[id].upvote = 0;
        posts[id].downvote = 0;
        posts[id].weight = wt;
        posts[id].timestamp = now;
        posts[id].votingMechanism = votingMechanism;
        commentIDs.push(id);
        allIDs.push(id);
    }
    
    function totalPoints(address user) public view returns(uint) {
        return mem.info(user).VotingPoints;
    }
    
    function totalUpvote(address user, uint _id) public arkVoter(user) view returns(uint) {
            return posts[_id].upvote;
    }

    function totalDownvote(address user, uint _id) public arkVoter(user) view returns(uint) {
            return posts[_id].downvote;
    }    
    
    function message(address user, uint _id) public arkMember(user) view returns(string memory) {
            return posts[_id].value;
    }
    
    function totalVote(address user, uint _id) public arkVoter(user) view returns(int) {
            return (int(posts[_id].upvote) - int(posts[_id].downvote));
    }
    
    function getPoints(uint _id) public view returns(uint) {
        if (posts[_id].parent != 0) return (memberVote[posts[_id].parent][msg.sender].votes + posts[_id].weight);
        else return (memberVote[_id][msg.sender].votes  + posts[_id].weight);
    } 

    function upvote(uint _id) public arkVoter(msg.sender) returns(uint) {
        address user = msg.sender;
        require(posts[_id].user != address(0),"Invalid Id");
        require(memberVote[_id][user].downvotes == 0 && memberVote[_id][user].upvotes == 0,"Already Voted");
        uint votingMechanism = posts[_id].votingMechanism;
        uint parent = _id;
        if(posts[_id].parent !=0 ) parent = posts[_id].parent;
        if(votingMechanism == 1){
            // uint postWeight = posts[_id].weight + (posts[_id].weight*memberVote[_id][user].votes);
            memberVote[parent][user].votes += posts[_id].weight;
            upvoteQuadratic(user, _id, memberVote[parent][user].votes);
            emit pointsDeducted(user, _id, memberVote[parent][user].votes);
            return memberVote[parent][user].votes;
        }
        else {
            upvoteQuadratic(user, _id, posts[_id].weight);
            emit pointsDeducted(user, _id, posts[_id].weight);
            memberVote[parent][user].votes += posts[_id].weight;
            return posts[_id].weight;
        }
    }
    
    function downvote(uint _id) public arkVoter(msg.sender) returns(uint) {
        
        address user = msg.sender;
        require(posts[_id].user != address(0),"Invalid Id");
        require(memberVote[_id][user].downvotes == 0 && memberVote[_id][user].upvotes == 0,"Already Voted");
        uint votingMechanism = posts[_id].votingMechanism;
        uint parent = _id;
        if(posts[_id].parent !=0 ) parent = posts[_id].parent;
        if(votingMechanism == 1){
            // uint postWeight = posts[_id].weight + (posts[_id].weight*memberVote[_id][user].votes);
            memberVote[parent][user].votes += posts[_id].weight;
            downvoteQuadratic(user, _id, memberVote[parent][user].votes);
            emit pointsDeducted(user, _id, memberVote[parent][user].votes);
            return memberVote[parent][user].votes;
        }
        else {
            downvoteQuadratic(user, _id, posts[_id].weight);
            memberVote[parent][user].votes += posts[_id].weight;
            emit pointsDeducted(user, _id, posts[_id].weight);
            return posts[_id].weight;
        }
    }
    

    function upvoteQuadratic(address user, uint _id, uint point) internal {
            
        // uint point = vote * vote;
        uint balance = mem.getVotingPoints(user);
        
        if (point > balance) {
            revert("Not enough points");
        }
        
        memberVote[_id][user].upvotes += 1;
       
        
        mem.subVotingPoints(user, point);
        
        posts[_id].upvote += 1;
        
        // if (posts[_id].parent != 0) memberVote[posts[_id].parent][user].votes += 1;
        // else memberVote[_id][user].votes += 1;
    }
    
    function downvoteQuadratic(address user, uint _id, uint point) internal {
        
        // uint point = vote * vote;
        uint balance = mem.getVotingPoints(user);
        
        if (point > balance) {
            revert("Not enough points");
        }
        
        memberVote[_id][user].downvotes += 1 ;
        
        mem.subVotingPoints(user, point);
        
        posts[_id].downvote += 1;
        
        // if (posts[_id].parent != 0) memberVote[posts[_id].parent][user].votes += 1;
        // else memberVote[_id][user].votes += 1;
    }
}