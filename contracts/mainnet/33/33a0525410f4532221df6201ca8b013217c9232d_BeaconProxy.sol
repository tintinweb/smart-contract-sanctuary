/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// File contracts/beacon/IBeacon.sol

pragma solidity ^0.8.0;

interface IBeacon {
    function latestCopy() external view returns(address);
}


// File contracts/beacon/BeaconProxy.sol

pragma solidity ^0.8.0;

contract BeaconProxy {

    bytes32 private constant BEACON_SLOT = keccak256(abi.encodePacked("fairmint.beaconproxy.beacon"));

    constructor() public {
        _setBeacon(msg.sender);
    }

    function _setBeacon(address _beacon) private {
        bytes32 slot = BEACON_SLOT;
        assembly {
            sstore(slot, _beacon)
        }
    }

    function _getBeacon() internal view returns(address beacon) {
        bytes32 slot = BEACON_SLOT;
        assembly {
            beacon := sload(slot)
        }
    }

    function _getMasterCopy() internal view returns(address) {
        IBeacon beacon = IBeacon(_getBeacon());
        return beacon.latestCopy();
    }

    fallback() external payable {
        address copy = _getMasterCopy();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), copy, 0, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch result
            case 0 { revert(0, size) }
            default { return(0, size) }
        }
    }
}