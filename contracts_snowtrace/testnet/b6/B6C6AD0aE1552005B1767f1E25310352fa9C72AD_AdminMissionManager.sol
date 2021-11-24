/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract AdminMissionManager {

    //"https://docs.moralis.io/moralis-server/automatic-transaction-sync/smart-contract-events"
    event PostCreated (bytes32 indexed postId, address indexed postOwner, bytes32 indexed parentId, bytes32 contentId, bytes32 categoryId);
    event ContentAdded (bytes32 indexed contentId, string contentUri);
    event CategoryCreated (bytes32 indexed categoryId, string category);
    event Voted (bytes32 indexed postId, address indexed postOwner, address indexed voter, uint80 reputationPostOwner, uint80 reputationVoter, int40 postVotes, bool up, uint8 reputationAmount);
    // notify UI of User Honesty Status Update
    event Honesty (address indexed user, bool isHonest);

    // this is a post struct allows comments apparently
    struct post {
        address postOwner; // who posted
        bytes32 parentPost; // implement comments
        bytes32 contentId;  // the IPFS metadata?
        bytes32 categoryId; // ?
        int40 votes; // an amount of votes
    }

    // dishonest by default 
    mapping (address => bool) honestUsers;
    // rereference 
    // each user has a total reputation for each category?
    mapping (address => mapping (bytes32 => uint80)) reputationRegistry; 
    mapping (bytes32 => string) categoryRegistry; // category id and string
    mapping (bytes32 => string) contentRegistry; // cID and url at IPFS?
    mapping (bytes32 => post) postRegistry;  // post id to post struct
    mapping (address => mapping (bytes32 => bool)) voteRegistry; // user mapped to postId and voted or not

    /// _parentId could be empty
    /// where w store the content
    /// the category id is the category where the post lives
    function createPost(bytes32 _parentId, string calldata _contentUri, bytes32 _categoryId) external {
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUri));
        // hashes the owner, parent id, and content id (v clever)
        bytes32 _postId = keccak256(abi.encodePacked(_owner,_parentId, _contentId));
        contentRegistry[_contentId] = _contentUri;
        postRegistry[_postId].postOwner = _owner;
        postRegistry[_postId].parentPost = _parentId;
        postRegistry[_postId].contentId = _contentId;
        postRegistry[_postId].categoryId = _categoryId;
        emit ContentAdded(_contentId, _contentUri); // these are how we fetch it in UI
        emit PostCreated (_postId, _owner,_parentId,_contentId,_categoryId); // post struct
    }

    function voteUp(bytes32 _postId, uint8 _reputationAdded) external {
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require (postRegistry[_postId].postOwner != _voter, "you cannot vote your own posts");
        require (voteRegistry[_voter][_postId] == false, "Sender already voted in this post");
        require (validateReputationChange(_voter,_category,_reputationAdded)==true, "This address cannot add this amount of reputation points");
        postRegistry[_postId].votes += 1;
        reputationRegistry[_contributor][_category] += _reputationAdded;
        // this is irreversible, updating the registry for that voter(on this post) already voted
        // we could add a uint 
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, true, _reputationAdded);
    }

    function voteDown(bytes32 _postId, uint8 _reputationTaken) external {
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require (voteRegistry[_voter][_postId] == false, "Sender already voted in this post");
        require (validateReputationChange(_voter,_category,_reputationTaken)==true, "This address cannot take this amount of reputation points");
        postRegistry[_postId].votes >= 1 ? postRegistry[_postId].votes -= 1: postRegistry[_postId].votes = 0;
        reputationRegistry[_contributor][_category] >= _reputationTaken ? reputationRegistry[_contributor][_category] -= _reputationTaken: reputationRegistry[_contributor][_category] =0;
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, false, _reputationTaken);
    }

    // function with logarithmic characteristic (in else)
    // if the reputation is lower than 2, then they can only add one
    // later on can implement this logarithmic weighting or delete and replace with modifier?
    function validateReputationChange(address _sender, bytes32 _categoryId, uint8 _reputationAdded) internal view returns (bool _result){
        uint80 _reputation = reputationRegistry[_sender][_categoryId];
        if (_reputation < 2 ) {
            _reputationAdded == 1 ? _result = true: _result = false;
        }
        // this is the logarithmic, if your rep is 4 you can add 2, 8 can add 4
        else {
            2**_reputationAdded <= _reputation ? _result = true: _result = false;
        }
    }

    // requires access control to admin role
    function addCategory(string calldata _category) external {
        // access control here.
        bytes32 _categoryId = keccak256(abi.encode(_category));
        categoryRegistry[_categoryId] = _category;
        emit CategoryCreated(_categoryId, _category);
    }
    
    function getContent(bytes32 _contentId) public view returns (string memory) {
        return contentRegistry[_contentId];
    }
    
    function getCategory(bytes32 _categoryId) public view returns(string memory) {   
        return categoryRegistry[_categoryId];
    }

    function getReputation(address _address, bytes32 _categoryID) public view returns(uint80) {   
        return reputationRegistry[_address][_categoryID];
    }

    function getPost(bytes32 _postId) public view returns(address, bytes32, bytes32, int72, bytes32) {   
        return (
            postRegistry[_postId].postOwner,
            postRegistry[_postId].parentPost,
            postRegistry[_postId].contentId,
            postRegistry[_postId].votes,
            postRegistry[_postId].categoryId);
    }

    // the admin (deployer, for now) can assign an honesty value to the users.
    function usersHonest(address _userAddress, bool _adminOpinion) public {
        // access control here (otherwise this is an attack vector;)
        honestUsers[_userAddress] = _adminOpinion;
        emit Honesty(_userAddress, _adminOpinion);
        }

}