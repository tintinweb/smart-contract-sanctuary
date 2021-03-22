/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

/** 
 * 
 */

pragma solidity 0.5.7;

interface membership {
    
    function isMember(address user) external view returns(bool);
    
    function paymentGetter(address user) external view returns(bool);
    
    function kycGetter(address user) external view returns(bool);
    
}

contract ballot {
    
    struct comment {
        // uint256 id;
        address user;
        uint parent;
        string value;
        uint upvote;
        uint timestamp;
        // uint vote;
        uint downvote;
        // reply rpl;
    }
    
    struct member {
        bool upvoted;
        bool downvoted;
    }
    
    struct post {
        // uint256 id;
        address user;
        string value;
        uint upvote;
        // uint vote;
        uint timestamp;
        uint downvote;
        // comment cmnt;
    }
    
    // struct reply {
    //     uint id;
    //     uint parent;
    //     string value;
    //     uint upvote;
    //     uint vote;
    //     uint downvote;
    //     bool voted;
    // }
    
    uint256 id = 0;
    
    // post pst;
    // comment cmnt;
    // reply rpl;
    
    mapping(uint => post) pst;
    mapping(uint => comment) cmnt;
    mapping(uint => mapping(address => member)) memVote;
    mapping(address => uint256[]) posts;
    
    uint256[] totalpost;
    uint256[] totalcmnt;
    
    membership mem;
    
    constructor(membership _address) public {
        mem = _address;
    }
    
    modifier arkMember(address user) {
        require(mem.isMember(user),"You are not a member");
        _;
    }
    
    modifier arkVoter(address user) {
        require(mem.paymentGetter(user),"You are not Paid");
        require(mem.kycGetter(user),"You are not verified");
        _;
    }
    
    function totalPost() public view returns(uint256[] memory) {
        return totalpost;
    }
    
    function allPost(address user) public view returns(uint[] memory) {
        return posts[user];
    }
    
    function postStatus(address user, string memory _value) public arkMember(user) returns(uint) {
        id += 1;
        pst[id].user = user;
        pst[id].value = _value;
        pst[id].upvote = 0;
        pst[id].downvote = 0;
        pst[id].timestamp = now;
        posts[user].push(id);
        totalpost.push(id);
        return id;
    }
    
    function statusOwner(uint _id) public view returns(address) {
        if (keccak256(bytes(pst[_id].value)) != keccak256(bytes(""))) {
            return pst[_id].user;
        }
        else if (keccak256(bytes(cmnt[_id].value)) != keccak256(bytes(""))) {
            return cmnt[_id].user;
        }
        else {
            revert("Invalid Input");
        }
    }
    
    function deletePost(uint _id) public {
        require(pst[_id].user == msg.sender || cmnt[_id].user == msg.sender,"You are an Imposter");
        if (keccak256(bytes(pst[_id].value)) != keccak256(bytes(""))) {
            pst[_id].user = address(0);
        }
        else {
            cmnt[_id].user = address(0);
        }
    }
    
    function postComment(address user, uint _parent, string memory _value) public arkMember(user) {
        if (((keccak256(bytes(pst[_parent].value))) != (keccak256(bytes("")))) || ((keccak256(bytes(cmnt[_parent].value))) != (keccak256(bytes(""))))) {
                id += 1;
                cmnt[id].user = msg.sender;
                cmnt[id].parent = _parent;
                cmnt[id].value = _value; 
                cmnt[id].upvote = 0;
                cmnt[id].downvote = 0;
                cmnt[id].timestamp = now;
                posts[user].push(id);
                totalcmnt.push(id);
        }
        else {
            revert("Invalid parent");
        }
    }
    
    function totalUpvote(address user, uint _id) public arkVoter(user) view returns(uint) {
        if (pst[_id].upvote == 0) {
            return cmnt[_id].upvote;
        }
        else {
            return pst[_id].upvote;
        }
    }

    function totalDownvote(address user, uint _id) public arkVoter(user) view returns(uint) {
        if (pst[_id].downvote == 0) {
            return cmnt[_id].downvote;
        }
        else {
            return pst[_id].downvote;
        }
    }    
    
    function message(address user, uint _id) public arkMember(user) view returns(string memory) {
        if (keccak256(bytes(pst[_id].value)) != keccak256(bytes(""))) {
            return pst[_id].value;
        }
        else if (keccak256(bytes(cmnt[_id].value)) != keccak256(bytes(""))) {
            return cmnt[_id].value;
        }
        else {
            revert("Invalid Input");
        }
    }
    
    function totalVote(address user, uint _id) public arkVoter(user) view returns(int) {
        if ((pst[_id].upvote==0) && (pst[_id].downvote==0)){
            return (int(cmnt[_id].upvote) - int(cmnt[_id].downvote));
        }
        else {
            return (int(pst[_id].upvote) - int(pst[_id].downvote));
        }
    }
    
    function Upvote(address user, uint _id) public arkVoter(user) {
        if ((memVote[_id][msg.sender].upvoted == false) && (memVote[_id][msg.sender].downvoted == false)){
            memVote[_id][msg.sender].upvoted = true;
            if ((keccak256(bytes(pst[_id].value))) != (keccak256(bytes("")))) {
                pst[_id].upvote += 1;
            }
            else if ((keccak256(bytes(cmnt[_id].value))) != (keccak256(bytes("")))) {
                cmnt[_id].upvote += 1;
            }
            else {
                memVote[_id][msg.sender].upvoted = false;
                revert("Invalid Input");
            }
        }
        else if ((memVote[_id][msg.sender].upvoted == true) && (memVote[_id][msg.sender].downvoted == false)) {
            memVote[_id][msg.sender].upvoted = false;
            if ((keccak256(bytes(pst[_id].value))) != (keccak256(bytes("")))) {
                pst[_id].upvote -= 1;
            }
            else if ((keccak256(bytes(cmnt[_id].value))) != (keccak256(bytes("")))) {
                cmnt[_id].upvote -= 1;
            }
            else {
                memVote[_id][msg.sender].upvoted = true;
                revert("Invalid Input");
            }
        }
        else if ((memVote[_id][msg.sender].upvoted == false) && (memVote[_id][msg.sender].downvoted == true)) {
            memVote[_id][msg.sender].upvoted = true;
            memVote[_id][msg.sender].downvoted = false;
            if ((keccak256(bytes(pst[_id].value))) != (keccak256(bytes("")))) {
                pst[_id].upvote += 1;
                pst[_id].downvote -= 1;
            }
            else if ((keccak256(bytes(cmnt[_id].value))) != (keccak256(bytes("")))) {
                cmnt[_id].upvote += 1;
                cmnt[_id].downvote -= 1;
            }
            else {
                memVote[_id][msg.sender].upvoted = false;
                memVote[_id][msg.sender].downvoted = true;
                revert("Invalid Input");
            }
        }
    }
    
    function Downvote(address user, uint _id) public arkVoter(user) {
        if ((memVote[_id][msg.sender].upvoted == false) && (memVote[_id][msg.sender].downvoted == false)){
            memVote[_id][msg.sender].downvoted = true;
            if ((keccak256(bytes(pst[_id].value))) != (keccak256(bytes("")))) {
                pst[_id].downvote += 1;
            }
            else if ((keccak256(bytes(cmnt[_id].value))) != (keccak256(bytes("")))) {
                cmnt[_id].downvote += 1;
            }
            else {
                memVote[_id][msg.sender].downvoted = false;
                revert("Invalid Input");
            }
        }
        else if ((memVote[_id][msg.sender].upvoted == false) && (memVote[_id][msg.sender].downvoted == true)) {
            memVote[_id][msg.sender].downvoted = false;
            if ((keccak256(bytes(pst[_id].value))) != (keccak256(bytes("")))) {
                pst[_id].downvote -= 1;
            }
            else if ((keccak256(bytes(cmnt[_id].value))) != (keccak256(bytes("")))) {
                cmnt[_id].downvote -= 1;
            }
            else {
                memVote[_id][msg.sender].downvoted = true;
                revert("Invalid Input");
            }
        }
        else if ((memVote[_id][msg.sender].upvoted == true) && (memVote[_id][msg.sender].downvoted == false)) {
            memVote[_id][msg.sender].downvoted = true;
            memVote[_id][msg.sender].upvoted = false;
            if ((keccak256(bytes(pst[_id].value))) != (keccak256(bytes("")))) {
                pst[_id].downvote += 1;
                pst[_id].upvote -= 1;
            }
            else if ((keccak256(bytes(cmnt[_id].value))) != (keccak256(bytes("")))) {
                cmnt[_id].downvote += 1;
                cmnt[_id].upvote -= 1;
            }
            else {
                memVote[_id][msg.sender].upvoted = false;
                memVote[_id][msg.sender].downvoted = true;
                revert("Invalid Input");
            }
        }
    }
}