// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "../interfaces/INXMMaster.sol";
import "../interfaces/IMCR.sol";

interface Token {
  function balanceOf(address) external view returns (uint);
}

contract Monitor {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  INXMMaster immutable master;

  constructor(INXMMaster _master) {
    master = _master;
  }

  function getBalance(address target, address token) public view returns (uint) {

    if (token == ETH) {
      return target.balance;
    }
    return Token(token).balanceOf(target);
  }

  function getInternalContractBalance(bytes2 code, address token) public view returns (uint) {
    return getBalance(master.getLatestAddress(code), token);
  }

  function getTimeSinceLastMCRUpdate() public view returns (uint) {
    return block.timestamp - uint(IMCR(master.getLatestAddress("MC")).lastUpdateTime());
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface INXMMaster {

  function tokenAddress() external view returns (address);

  function owner() external view returns (address);

  function masterInitialized() external view returns (bool);

  function isInternal(address _add) external view returns (bool);

  function isPause() external view returns (bool check);

  function isOwner(address _add) external view returns (bool);

  function isMember(address _add) external view returns (bool);

  function checkIsAuthToGoverned(address _add) external view returns (bool);

  function dAppLocker() external view returns (address _add);

  function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress);

  function upgradeMultipleContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses
  ) external;

  function removeContracts(bytes2[] calldata contractCodesToRemove) external;

  function addNewInternalContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses,
    uint[] calldata _types
  ) external;

  function updateOwnerParameters(bytes8 code, address payable val) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMCR {

  function updateMCRInternal(uint poolValueInEth, bool forceUpdate) external;
  function getMCR() external view returns (uint);


  function maxMCRFloorIncrement() external view returns (uint24);

  function mcrFloor() external view returns (uint112);
  function mcr() external view returns (uint112);
  function desiredMCR() external view returns (uint112);
  function lastUpdateTime() external view returns (uint32);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}