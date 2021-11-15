//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IOwnerOnlyApprover.sol";

/**
 * @title Owner Only Approver
 * @notice Control token transferability
 * @dev Only the owner can send or receive tokens. A caller contract must have owner() function returning owner address of it.
 * @author David Lee
 */

interface IOwnerOnlyApproverCaller {
  function owner() external view returns (address);
}

contract OwnerOnlyApprover is IOwnerOnlyApprover {
  /**
   * @notice Returns token transferability
   * @dev Mint and burn transactions are always allowed
   * @param _from sender address
   * @param _to beneficiary address
   * @return (bool) true - allowance, false - denial
   */
  function checkTransfer(address _from, address _to) external view override returns (bool) {
    address owner = IOwnerOnlyApproverCaller(msg.sender).owner();

    return (_from == address(0) || _to == address(0)) ? true : (_from == owner || _to == owner) ? true : false;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IOwnerOnlyApprover {
  function checkTransfer(address _from, address _to) external view returns (bool);
}

