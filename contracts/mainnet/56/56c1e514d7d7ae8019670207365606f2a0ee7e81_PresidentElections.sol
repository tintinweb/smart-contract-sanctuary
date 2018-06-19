pragma solidity ^0.4.18;

library Search {
  function indexOf(uint32[] storage self, uint32 value) public view returns (uint32) {
    for (uint32 i = 0; i < self.length; i++) {
      if (self[i] == value) return i;
    }
    return uint32(- 1);
  }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
}

contract PresidentElections {
  address owner;

  using SafeMath for uint;

  struct Candidate {
    uint32 id;
    address owner;
    uint256 votes;
  }
  uint end = 1521406800;
  mapping(address => uint) votes;
  mapping(uint32 => Candidate) candidates;
  using Search for uint32[];
  uint32[] candidate_ids;
  uint constant price = 0.01 ether;
  uint public create_price = 0.1 ether;
  uint constant percent = 10;

  enum Candidates {
    NULL,
    Baburin,
    Grudinin,
    Zhirinovsky,
    Putin,
    Sobchak,
    Suraykin,
    Titov,
    Yavlinsky
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier isCandidate(uint32 candidate) {
    require(candidates[candidate].id > 0);
    _;
  }

  modifier isNotVoted() {
    require(votes[msg.sender] == 0);
    _;
  }

  modifier voteIsOn() {
    require(now < end);
    _;
  }

  function PresidentElections() public {
    owner = msg.sender;
    _add(uint32(Candidates.Baburin), owner);
    _add(uint32(Candidates.Grudinin), owner);
    _add(uint32(Candidates.Zhirinovsky), owner);
    _add(uint32(Candidates.Putin), owner);
    _add(uint32(Candidates.Sobchak), owner);
    _add(uint32(Candidates.Suraykin), owner);
    _add(uint32(Candidates.Titov), owner);
    _add(uint32(Candidates.Yavlinsky), owner);
  }

  function _add(uint32 candidate, address sender) private {
    require(candidates[candidate].id == 0);

    candidates[candidate] = Candidate(candidate, sender, 0);
    candidate_ids.push(candidate);
  }

  function isFinished() constant public returns (bool) {
    return now > end;
  }

  function isVoted() constant public returns (bool) {
    return votes[msg.sender] > 0;
  }

  function vote(uint32 candidate) public payable isCandidate(candidate) voteIsOn isNotVoted returns (bool) {
    require(msg.value == price);

    votes[msg.sender] = candidate;
    candidates[candidate].votes += 1;

    if( candidates[candidate].owner != owner ) {
      owner.transfer(msg.value.mul(100 - percent).div(100));
      candidates[candidate].owner.transfer(msg.value.mul(percent).div(100));
    } else {
      owner.transfer(msg.value);
    }

    return true;
  }

  function add(uint32 candidate) public payable voteIsOn returns (bool) {
    require(msg.value == create_price);

    _add(candidate, msg.sender);

    owner.transfer(msg.value);

    return true;
  }

  function getCandidates() public view returns (uint32[]) {
    return candidate_ids;
  }

  function getVotes() public view returns (uint256[]) {
    uint256[] memory v = new uint256[](candidate_ids.length);
    for(uint i = 0; i < candidate_ids.length; i++ ) {
      v[i] = candidates[candidate_ids[i]].votes;
    }
    return v;
  }

  function setCreatePrice(uint _price) public onlyOwner {
    create_price = _price;
  }
}