/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// File: localhost/token/interface/ICloneFactory.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}
// File: localhost/token/createToken/CloneFactory.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;


// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167
contract CloneFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
            add(clone, 0x28),
            0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}