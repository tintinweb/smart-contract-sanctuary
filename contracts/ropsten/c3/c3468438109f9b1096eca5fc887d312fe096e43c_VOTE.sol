/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity ^0.4.26;

// import "./safemath.sol";
// import "./erc20.sol";
// import "./ownable.sol";


library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
}


contract Ownable {
    // address public owner;
    address[] public list_owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        list_owner.push(msg.sender);
    }
    
    modifier onlyListOwner() {
        bool checkower = false;
        for(uint i=0 ; i<list_owner.length ; i++){
            if(list_owner[i] == msg.sender){
                checkower = true;
            }
            if(checkower){
                break;
            }
        }
        require(checkower, "Address is not onwer");
        _;
    }
    
    function addowner(address newOwner) public onlyListOwner{
        if(list_owner.length < 5){
            list_owner.push(newOwner);
        }
    }
  
    function transferOwnership(address newOwner) public onlyListOwner {
        for(uint i=0 ; i<list_owner.length ; i++){
            if(list_owner[i] == msg.sender){
                list_owner[i] = newOwner;
                break;
            }
        }
    }
}


// contract ERC721 {
//   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
//   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

//   function balanceOf(address _owner) public view returns (uint256 _balance);
//   function ownerOf(uint256 _tokenId) public view returns (address _owner);
//   function transfer(address _to, uint256 _tokenId) public;
//   function approve(address _to, uint256 _tokenId) public;
//   function takeOwnership(uint256 _tokenId) public;
// }

contract VOTE is Ownable {
  using SafeMath for uint256;


  uint cooldownTime = 1 days;
  uint public totaltopicid;
  struct Vote {
    string topic;
    address creater;
    uint point;
    uint checkpoint;
    uint stepcheckpoint;
    uint timeout;
    address[] addressVoted;
  }

  Vote[] public vote;
  
    
  mapping (uint => address) public topicidToOwner;
  mapping (address => uint) ownerVoteCount;
  

  function CreateVote(string memory _name, uint _checkpoint, uint _stepcheckpoint, uint _timeout) public  {
    require(_timeout > now + 1 minutes, "Input timeout more 1 minutes.");
    address[] addressVoted_buf;
    addressVoted_buf.length  = 0;
    addressVoted_buf.push(address(0));
    totaltopicid = vote.push(Vote(_name,msg.sender,0,_checkpoint,_stepcheckpoint,_timeout,addressVoted_buf)).sub(1);
    
    topicidToOwner[totaltopicid] = msg.sender;
    ownerVoteCount[msg.sender] = ownerVoteCount[msg.sender].add(1);
  }
  
  function VoteTopicid(uint _id) public {
    require(_id <= totaltopicid, "Can not find this topic id.");
    require(CheckCondition(_id), "This address voted.");
    vote[_id].point = vote[_id].point.add(1);
    vote[_id].addressVoted.push(msg.sender);
  }
  
  function CheckCondition(uint _id) view returns (bool){
      require(!(now > vote[_id].timeout), "Topic timeout.");
      require(!((vote[_id].point >= vote[_id].checkpoint) && (vote[_id].stepcheckpoint == 0)), "Vote complete.");
      bool check = true;
      for(uint i;i<vote[_id].addressVoted.length;i++){
          if(msg.sender == vote[_id].addressVoted[i]){
              check = false;
          }
      }
      return check;
  }
  
  
  function GetPiont(uint _id) public view returns (uint256){
      return vote[_id].point;
  }
  
  function GetAddressVoted(uint _id) public view returns (address[]){
      return vote[_id].addressVoted;
  }

  function Nowtime() public view returns (uint) {
        return now;
  }
  
  function test(uint _id) public view returns (uint){
    return vote[_id].timeout;
  }

//   function _generateRandomNFT(string _str) public returns (uint) {
//     uint rand = uint(keccak256(_str,block.difficulty,block.timestamp,now,1));
//     return rand;
//   }
  
  
//   function _voteTopicid(uint _id) private view returns (uint) {
//     vote
//     return ;
//   }
  
//   function _createVote(string _name, uint _timeout) internal {

//   }

//   function createRandomNFT(string _name) public {
//     require(ownerVoteCount[msg.sender] == 0);
//     uint randNFT = _generateRandom(_name);
//     randNFT = randNFT - randNFT % 100;
//     _createVote(_name, randNFT);
//   }
  
//   modifier onlyOwnerOf(uint _tokenIdId) {
//     require(msg.sender == nftToOwner[_tokenIdId]);
//     _;
//   }
}


// contract NFTOwnership is NFT,ERC721 {

//   using SafeMath for uint256;

//   mapping (uint => address) nftApprovals;

//   function balanceOf(address _owner) public view returns (uint256 _balance) {
//     return ownerNFTCount[_owner];
//   }

//   function ownerOf(uint256 _tokenId) public view returns (address _owner) {
//     return nftToOwner[_tokenId];
//   }

//   function _transfer(address _from, address _to, uint256 _tokenId) private {
//     ownerNFTCount[_to] = ownerNFTCount[_to].add(1);
//     ownerNFTCount[msg.sender] = ownerNFTCount[msg.sender].sub(1);
//     nftToOwner[_tokenId] = _to;
//     Transfer(_from, _to, _tokenId);
//   }

//   function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
//     _transfer(msg.sender, _to, _tokenId);
//   }

//   function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
//     nftApprovals[_tokenId] = _to;
//     Approval(msg.sender, _to, _tokenId);
//   }

//   function takeOwnership(uint256 _tokenId) public {
//     require(nftApprovals[_tokenId] == msg.sender);
//     address owner = ownerOf(_tokenId);
//     _transfer(owner, msg.sender, _tokenId);
//   }
// }