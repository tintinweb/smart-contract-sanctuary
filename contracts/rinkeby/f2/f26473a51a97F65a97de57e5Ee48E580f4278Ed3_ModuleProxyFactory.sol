/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

// @TODO: Cesar's opinion: This is the way we should import external modules
// currently it's not working because there are redundant declarations
// i.e: Enum or Executor - Making the compile script to fail
// Hence, forcing us to create the lib & interfaces folders

// import "@gnosis/dao-module/contracts/DaoModule.sol";
// import "@gnosis/AMBModule/contracts/AMBModule.sol";
// import "@gnosis/SafeDelay/contracts/DelayModule.sol";

contract ModuleProxyFactory {
    event ModuleProxyCreation(address proxy);

    uint32 public nonce = 1;

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }

        emit ModuleProxyCreation(result);
    }

    function deployModule(address singleton, bytes memory initializer)
        public
        returns (address clone)
    {
        clone = createClone(singleton);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if eq(
                call(
                    gas(),
                    clone,
                    0,
                    add(initializer, 0x20),
                    mload(initializer),
                    0,
                    0
                ),
                0
            ) {
                revert(0, 0)
            }
        }
        nonce++;
    }
}