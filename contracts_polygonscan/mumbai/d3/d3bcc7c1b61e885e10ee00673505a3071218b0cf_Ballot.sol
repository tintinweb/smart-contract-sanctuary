/**
 *Submitted for verification at polygonscan.com on 2021-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC721 {
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * @dev Interface of the Ownable modifier handling contract ownership
 */
abstract contract Ownable {
    /**
    * @dev The owner of the contract
    */
    address payable internal _owner;
    
    /**
    * @dev The new owner of the contract (for ownership swap)
    */
    address payable internal _potentialNewOwner;
 
    /**
     * @dev Emitted when ownership of the contract has been transferred and is set by 
     * a call to {AcceptOwnership}.
    */
    event OwnershipTransferred(address payable indexed from, address payable indexed to, uint date);
 
    /**
     * @dev Sets the owner upon contract creation
     **/
    constructor() {
      _owner = payable(msg.sender);
    }
  
    modifier onlyOwner() {
      require(msg.sender == _owner);
      _;
    }
  
    function transferOwnership(address payable newOwner) external onlyOwner {
      _potentialNewOwner = newOwner;
    }
  
    function acceptOwnership() external {
      require(msg.sender == _potentialNewOwner);
      emit OwnershipTransferred(_owner, _potentialNewOwner, block.timestamp);
      _owner = _potentialNewOwner;
    }
  
    function getOwner() view external returns(address){
        return _owner;
    }
  
    function getPotentialNewOwner() view external returns(address){
        return _potentialNewOwner;
    }
}

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot is Ownable {
    
    struct Topic {
        bool exists;
        string question;
        uint256 startBlock;
        uint256 endBlock;
    }
   
    IERC721 private _governanceToken;
    
    mapping(uint256 => Topic) private _votingTopics;
    mapping(uint256 => uint256[]) private _votes;
    mapping(uint256 => mapping(uint256 => bool)) private _votingHistory;
    
    uint256 _votingTopicId = 1;

    constructor(address governanceToken)
    {
        _governanceToken = IERC721(governanceToken);
    }
    
    function addVotingTopic(string memory question, uint256 startBlock, uint256 endBlock) public onlyOwner returns(uint256 votingTopicId){
        votingTopicId = _votingTopicId;
        _votingTopics[_votingTopicId] = Topic(true, question, startBlock, endBlock);
        _votingTopicId = votingTopicId + 1;
        return votingTopicId;
    }
    
    function removeVotingTopic(uint256 topicId) public onlyOwner{
        Topic storage topic = _votingTopics[topicId];
        require(topic.exists, "Topic doesn't exist");
        topic.exists = false;
        topic.question = "";
        topic.startBlock = 0;
        topic.endBlock = 0;
    }
    
    function closeVote(uint256 topicId) public onlyOwner{
        Topic storage topic = _votingTopics[topicId];
        require(topic.exists, "Topic doesn't exist");
        topic.endBlock = block.number;
    }
    
    function vote(uint256 topicId, uint256[] memory tokenIds) public{
       Topic memory topic = _votingTopics[topicId];
       require(topic.exists, "Topic doesn't exist");
       require(tokenIds.length > 0, "No tokens to vote with have been supplied");
       
       uint256[] storage selectedVote = _votes[topicId];
       
       for(uint256 i = 0;i<tokenIds.length;i++){
           require(_governanceToken.ownerOf(tokenIds[i]) == msg.sender, "Caller does not own one or more of the token ids supplied");
           require(_votingHistory[topicId][tokenIds[i]] == false, "One or more of the token ids supplied has already been used");
           selectedVote.push(tokenIds[i]);
       }
    }
}