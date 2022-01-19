/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File contracts/Hub.sol

//SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0 < 0.7.0;

contract Hub {
  address public owner;
  mapping(address => address[]) pgs;

  constructor() public {
    owner = msg.sender;
  }

  function addPiggyBank(address _piggyBank) public {
    pgs[msg.sender].push(_piggyBank);
  }

  function piggyBanks() public view returns(uint) {
    return pgs[msg.sender].length;
  }

  function piggies(uint _idx) public view returns(address) {
    return pgs[msg.sender][_idx];
  }

  function transferOwnership(address _pb, address _newOwner) public {
    address[] memory addresses = pgs[msg.sender];
    for(uint i = 0; i < addresses.length; i++) {
      if (addresses[i] == _pb) {
        delete addresses[i];
        break;
      }
    }
    pgs[_newOwner].push(_pb);
    delete pgs[msg.sender];
    pgs[msg.sender] = addresses;
  }
}


// File contracts/Migrations.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}


// File contracts/PiggyBank.sol

//SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0 < 0.7.0;

contract PiggyBank {
  string public name;
  address payable public owner;
  mapping(address => Saving) savings;

  struct Saving {
    uint totalAmount;
    uint times;
  }

  event Deposit(address indexed _from, uint _value);

  constructor(string memory _name) public {
    name = _name;
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'You are not the rightful owner');
    _;
  }

  function deposit() public payable {
    Saving storage saving = savings[msg.sender];
    saving.totalAmount += msg.value;
    saving.times += 1;
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw() public onlyOwner {
    owner.transfer(address(this).balance);
  }

  function depositsByAddress(address _sender) public view returns(uint totalAmount, uint times) {
    Saving storage saving = savings[_sender];
    totalAmount = saving.totalAmount;
    times = saving.times;
  }

  function setOwner(address payable _newOwner) public onlyOwner {
    owner = _newOwner;
  }

  function crash() public onlyOwner {
    selfdestruct(owner);
  }

  function() external payable {
    if(msg.value == 0) withdraw();
    else emit Deposit(msg.sender, msg.value);
  }
}