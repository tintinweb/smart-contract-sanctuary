/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

abstract contract Ownable {

  address owner;


  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
      require(owner == msg.sender, "Ownable: caller is not the owner");
      _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
      owner = newOwner;
  }
  
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

abstract contract Finalizable {

  bool isFinalized;

  modifier notFinalized() {
    require(!isFinalized, "Finalizable: isFinalized");
    _;
  }
  
}

contract ProposalV1 is Ownable, Finalizable {
  
  struct RTSRecord {
    uint index;
    address voter;
    string vote;
    uint balance;
  }

  struct Voter {
    string vote;
    uint balance;
  }
  
  event VoteCasted();
  event Updated();
  
  mapping(address=>Voter) public voterByAddress;
  address[] public voterAddresses;
  
  string public text; // Should have information on estimated time the voting will be finalized

  uint public minRequiredBalance;

  IERC20 public constant token = IERC20(0x3C00F8FCc8791fa78DAA4A480095Ec7D475781e2); // replace with deployed token address
  
  uint public updateBlockNumber;  
  
  // 10000000000000000 = 10,000,000
  constructor(string memory _text, uint _minRequiredBalance) {
    updateBlockNumber = block.number;
    text = _text;
    minRequiredBalance = _minRequiredBalance;
  }

  function cast(string memory vote) public notFinalized {
    require(!isFinalized, "proposal is finalized");
    uint balance = token.balanceOf(msg.sender);
    require(balance >= minRequiredBalance, "minimum balance not valid");
    Voter storage voter = voterByAddress[msg.sender];
    if(voter.balance == 0) voterAddresses.push(msg.sender);
    voter.balance = balance;
    voter.vote = vote;
    emit VoteCasted();
  }

  function update() public onlyOwner notFinalized {
    require(!isFinalized, "proposal is finalized");
    updateBlockNumber = block.number;
    uint numVoters = getNumVoters();
    for(uint i = 0; i < numVoters; ++i) voterByAddress[voterAddresses[i]].balance = token.balanceOf(voterAddresses[i]);
  }

  function finalize() public onlyOwner notFinalized {
    update();
    isFinalized = true;
  }

  function getRTS() public view returns (RTSRecord[] memory records) {
    uint numVoters = getNumVoters();
    records = new RTSRecord[](numVoters);
    for(uint i = 0; i < numVoters; ++i) {
      address addr = voterAddresses[i];
      records[i] = RTSRecord(i, addr, voterByAddress[addr].vote, isFinalized ? voterByAddress[addr].balance : token.balanceOf(addr));
    }
  }

  function getNumVoters() public view returns (uint) { return voterAddresses.length; }

}