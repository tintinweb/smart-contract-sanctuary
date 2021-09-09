/**
 *Submitted for verification at polygonscan.com on 2021-09-08
*/

// File: contracts/matic/child/interfaces/IUpgradableProxy.sol

pragma solidity ^0.6.12;

interface IUpgradableProxy {
    function updateImplementation(address _newProxyTo) external;
}

// File: contracts/matic/child/interfaces/IStateReceiver.sol

pragma solidity ^0.6.12;

// IStateReceiver represents interface to receive state
interface IStateReceiver {
    function onStateReceive(uint256 stateId, bytes memory data) external;
}

// File: contracts/matic/child/ProxyOwner.sol

pragma solidity ^0.6.12;



contract ProxyOwner is IStateReceiver {

    uint256 currStateId;
    address public proxyAdminAddress;
    address public proxyAddress;

    constructor(address _proxyAddress) public {
        proxyAddress = _proxyAddress;
    }

    modifier onlyStateReceiver {
        require(msg.sender == address(0x0000000000000000000000000000000000001001), "Not state receiver");
        _;
    }

    function onStateReceive(uint256 stateId, bytes memory data) external override onlyStateReceiver {
        require(stateId == currStateId, "state id");
        address newImplementation;
        assembly {
            newImplementation := mload(add(data, 20))
        }
        _upgradeProxyAddress(newImplementation);
        currStateId++;
    }

    function _upgradeProxyAddress(address _newImplementation) private {
        IUpgradableProxy(proxyAddress).updateImplementation(_newImplementation);
    }

}