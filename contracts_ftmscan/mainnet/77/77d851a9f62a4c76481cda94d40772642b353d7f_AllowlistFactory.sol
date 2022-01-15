/**
 *Submitted for verification at FtmScan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*******************************************************
 *                      Interfaces
 *******************************************************/
interface IAllowlist {
  function initialize(string memory, address) external;
}

/*******************************************************
 *                   Main Contract Logic
 *******************************************************/
contract AllowlistFactory {
  address public allowlistTemplateAddress;

  constructor(address _allowlistTemplateAddress) {
    allowlistTemplateAddress = _allowlistTemplateAddress;
  }

  /**
   * @notice Clone and initialize a new allowlist
   * @param allowlistName The name of the allowlist (cannot be changed)
   * @param ownerAddress The address of the new allowlist owner
   * @return allowlistAddress The addresse of the new allowlist
   */
  function cloneAllowlist(string memory allowlistName, address ownerAddress)
    public
    returns (address allowlistAddress)
  {
    allowlistAddress = _cloneAllowlist();
    IAllowlist(allowlistAddress).initialize(allowlistName, ownerAddress);
  }

  /**
   * @notice Clone and initialize a new allowlist, setting owner to self
   * @param allowlistName The name of the allowlist (cannot be changed)
   * @return allowlistAddress The addresse of the new allowlist
   */
  function cloneAllowlist(string memory allowlistName)
    public
    returns (address allowlistAddress)
  {
    allowlistAddress = _cloneAllowlist();
    IAllowlist(allowlistAddress).initialize(allowlistName, msg.sender);
  }

  /**
   * @notice Clones the allowlist using EIP-1167 template during new protocol registration
   */
  function _cloneAllowlist() internal returns (address allowlistAddress) {
    bytes20 templateAddress = bytes20(allowlistTemplateAddress);
    assembly {
      let clone := mload(0x40)
      mstore(
        clone,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(clone, 0x14), templateAddress)
      mstore(
        add(clone, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )
      allowlistAddress := create(0, clone, 0x37)
    }
  }
}