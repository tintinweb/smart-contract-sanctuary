pragma solidity ^0.4.24;

contract CryptoBeautyVoting {

  event Won(address indexed _winner, uint256 _value);
  bool votingStart = false;
  uint32 private restartTime;
  uint32 private readyTime;
  uint256 private votePrice;
  address[] private arrOfVoters;
  uint256[] private arrOfBeautyIdMatchedVoters;
  address private owner;
  
  constructor() public {
    owner = msg.sender;
    restartTime = 7 days;
    readyTime = uint32(now + restartTime);
    votePrice = 0.002 ether;
  }

  /* Modifiers */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

   /* Owner */
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  function withdrawAll () onlyOwner() public {
    owner.transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }

  function getCurrentBalance() public view returns (uint256 balance) {
      return address(this).balance;
  }

  /* Voting */
  function startVoting() onlyOwner() public {
    votingStart = true;
  }

  function stopVoting() onlyOwner() public {
    votingStart = false;
  }

  function changeRestarTime(uint32 _rTime) onlyOwner() public {
    restartTime = _rTime;
  }

  function changevotePrice(uint256 _votePrice) onlyOwner() public {
    votePrice = _votePrice;
  }

  function _isReady() internal view returns (bool) {
    return (readyTime <= now);
  }

  function _isOne(address _voter) private view returns (bool) {
    uint256 j = 0;
    for(uint256 i = 0; i < arrOfVoters.length; i++) {
      if(keccak256(abi.encodePacked(arrOfVoters[i])) == keccak256(abi.encodePacked(_voter)))
      {
        j++;
      }
    }
    if(j == 0) {
      return true;
    } else {
      return false;
    }
  }

  function vote(uint256 _itemId) payable public {
    require(votingStart);
    require(msg.value >= votePrice);
    require(!isContract(msg.sender));
    require(msg.sender != address(0));
    require(_isOne(msg.sender));

    arrOfVoters.push(msg.sender);
    arrOfBeautyIdMatchedVoters.push(_itemId);
  }

  function getVoteResult() onlyOwner() public view returns (address[], uint256[]) {
    require(_isReady());
    return (arrOfVoters, arrOfBeautyIdMatchedVoters);
  }

  function voteResultPublish(address[] _winner, uint256[] _value) onlyOwner() public {
    require(votingStart);
    votingStart = false;
    for (uint256 i = 0; i < _winner.length; i++) {
     _winner[i].transfer(_value[i]);
     emit Won(_winner[i], _value[i]);
    }
  }

  function clear() onlyOwner() public {
    delete arrOfVoters;
    delete arrOfBeautyIdMatchedVoters;
    readyTime = uint32(now + restartTime);
    votingStart = true;
  }
  function getRestarTime() public view returns (uint32) {
    return restartTime;
  }

  function getVotingStatus() public view returns (bool) {
    return votingStart;
  }

  function getVotePrice() public view returns (uint256) {
    return votePrice;
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
}