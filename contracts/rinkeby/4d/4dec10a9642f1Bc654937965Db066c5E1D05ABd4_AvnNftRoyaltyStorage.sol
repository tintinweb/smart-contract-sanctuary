// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IAvnNftRoyaltyStorage.sol";
import "./Owned.sol";

contract AvnNftRoyaltyStorage is IAvnNftRoyaltyStorage, Owned {

  uint32 constant private ONE_MILLION = 1000000;

  mapping (address => bool) public isPermitted;
  mapping (uint256 => uint256) private royaltiesId;
  mapping (uint256 => Royalty[]) private royalties;
  uint256 private rId;

  modifier onlyPermitted() {
    require(isPermitted[msg.sender], "Access not permitted");
    _;
  }

  function setPermission(address _partnerContract, bool _status)
    onlyOwner
    external
    override
  {
    isPermitted[_partnerContract] = _status;
    emit LogPermissionUpdated(_partnerContract, _status);
  }

  function setRoyaltyId(uint256 _batchId, uint256 _nftId)
    onlyPermitted
    external
    override
  {
    royaltiesId[_nftId] = royaltiesId[_batchId];
  }

  function setRoyalties(uint256 _id, Royalty[] calldata _royalties)
    onlyPermitted
    external
    override
  {
    if (royaltiesId[_id] != 0) return;

    royaltiesId[_id] = ++rId;

    uint64 totalRoyalties;

    for (uint256 i = 0; i < _royalties.length; i++) {
      if (_royalties[i].recipient != address(0) && _royalties[i].partsPerMil != 0) {
        totalRoyalties += _royalties[i].partsPerMil;
        require(totalRoyalties <= ONE_MILLION, "Royalties too high");
        royalties[rId].push(_royalties[i]);
      }
    }
  }

  function getRoyalties(uint256 _id)
    external
    view
    override
    returns(Royalty[] memory)
  {
    return royalties[royaltiesId[_id]];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract Owned {

  address public owner = msg.sender;

  event LogOwnershipTransferred(address indexed owner, address indexed newOwner);

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner");
    _;
  }

  function setOwner(address _owner)
    external
    onlyOwner
  {
    require(_owner != address(0), "Owner cannot be zero address");
    emit LogOwnershipTransferred(owner, _owner);
    owner = _owner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IAvnNftRoyaltyStorage {

  struct Royalty {
    address recipient;
    uint32 partsPerMil;
  }

  event LogPermissionUpdated(address partnerContract, bool status);

  function setPermission(address partnerContract, bool status) external; // onlyOwner
  function setRoyaltyId(uint256 batchId, uint256 nftId) external; // onlyPermitted
  function setRoyalties(uint256 id, Royalty[] calldata royalties) external; // onlyPermitted
  function getRoyalties(uint256 id) external view returns(Royalty[] memory);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}