// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface TransparentUpgradeableProxy {
    function upgradeTo(address implementation) external;

    function upgradeToAndCall(address implementation, bytes calldata data) external payable;
}

contract ProxyAdmin {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address internal _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "NOT_AUTHORIZED");
        _;
    }

    constructor(address initialOwner) {
        _owner = initialOwner;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "NOT_AUTHORIZED");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public onlyOwner {
        proxy.upgradeTo(implementation);
    }

    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

