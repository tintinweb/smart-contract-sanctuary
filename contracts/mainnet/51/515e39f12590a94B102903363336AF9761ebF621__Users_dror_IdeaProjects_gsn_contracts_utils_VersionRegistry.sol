// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
// solhint-disable not-rely-on-time

import "../interfaces/IVersionRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VersionRegistry is IVersionRegistry, Ownable {

    function addVersion(bytes32 id, bytes32 version, string calldata value) external override onlyOwner {
        require(id != bytes32(0), "missing id");
        require(version != bytes32(0), "missing version");
        emit VersionAdded(id, version, value, block.timestamp);
    }

    function cancelVersion(bytes32 id, bytes32 version, string calldata reason) external override onlyOwner {
        emit VersionCanceled(id, version, reason);
    }
}
