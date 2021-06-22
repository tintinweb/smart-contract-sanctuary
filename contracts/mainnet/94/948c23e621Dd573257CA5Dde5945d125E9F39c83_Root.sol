// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./UpgradeableProxy.sol";

contract Root is UpgradeableProxy, Ownable {
    constructor(
        address _owner,
        address _logic,
        bytes memory _data
    ) UpgradeableProxy(_logic, _data) Ownable() {
        transferOwnership(_owner);
    }

    function upgradeTo(address _new) external onlyOwner {
        _upgradeTo(_new);
    }
}