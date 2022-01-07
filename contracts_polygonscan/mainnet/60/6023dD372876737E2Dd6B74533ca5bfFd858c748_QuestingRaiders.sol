//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract QuestingRaiders is Ownable, Pausable, IERC721Receiver {

  address raidersAddress;

  mapping(uint => bool) public onQuest;
  mapping(address => bool) approvedQuests;
  mapping(address => uint[]) public ownedRaiders;
  mapping(uint => address) public raiderQuest;

  constructor(address _raiders) {
    raidersAddress = _raiders;
  }

  // ---------- HELPERS ----------

  function raiders() internal view returns(IERC721) {
    return IERC721(raidersAddress);
  }

  function removeRaider(uint _raider, address _owner) internal {
    uint raiderIndex; 
    for (uint i = 0; i < ownedRaiders[_owner].length - 1; i++) {
      if (ownedRaiders[_owner][i] == _raider) {
        raiderIndex = i;
      }
    }

    uint length = ownedRaiders[_owner].length;

    ownedRaiders[_owner][raiderIndex] = ownedRaiders[_owner][length - 1]; // change the index to the last item in the array
    delete ownedRaiders[_owner][length - 1];
    ownedRaiders[_owner].pop();
  }

  // ---------- MODIFIERS ----------

  modifier onlyQuest {
    require(approvedQuests[msg.sender] == true);
    _;
  }

  // ---------- PRIMARY FUNCTIONS ----------

  function startQuest(uint _raiderId, address _owner) onlyQuest public whenNotPaused {
    require(onQuest[_raiderId] == false, "This Raider is already on a Quest!");
    onQuest[_raiderId] = true;
    ownedRaiders[_owner].push(_raiderId);
    raiderQuest[_raiderId] = msg.sender;
    raiders().safeTransferFrom(_owner, address(this), _raiderId);
  }

  function endQuest(uint _raiderId, address _owner) onlyQuest public whenNotPaused {
    require(onQuest[_raiderId] == true, "This Raider is not on a Quest!");
    onQuest[_raiderId] = false;
    removeRaider(_raiderId, _owner);
    raiders().safeTransferFrom(address(this), _owner, _raiderId);
  }


  // ----------- ADMIN ONLY ----------

  function addQuest(address _quest) onlyOwner public whenNotPaused {
    approvedQuests[_quest] = true;
  }

  function removeQuest(address _quest) onlyOwner public whenNotPaused {
    approvedQuests[_quest] = false;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function emergencyRemoveRaider(uint _raiderId) public onlyOwner {
    raiders().safeTransferFrom(address(this), msg.sender, _raiderId);
  }

  function emergencyBulkRemoveRaiders(uint _startIndex, uint _endIndex) public onlyOwner {
    for (uint i = _startIndex; i <= _endIndex; i++ ) {
      raiders().safeTransferFrom(address(this), msg.sender, i);
    }
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  // ----------- VIEW FUNCTIONS ----------

  function getOwnedRaiders(address _address) public view returns(uint[] memory) {
    return ownedRaiders[_address];
  }
}