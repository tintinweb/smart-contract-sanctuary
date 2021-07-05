// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

contract ModuleProxyFactory {
    event ModuleProxyCreation(address proxy);

    uint32 public nonce = 1;

    function createProxy(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let proxy := mload(0x40)
            mstore(
                proxy,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(proxy, 0x14), targetBytes)
            mstore(
                add(proxy, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, proxy, 0x37)
        }

        emit ModuleProxyCreation(result);
    }

    function deployModule(address masterCopy, bytes memory initializer)
        public
        returns (address proxy)
    {
        proxy = createProxy(masterCopy);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if eq(
                call(
                    gas(),
                    proxy,
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

{
  "optimizer": {
    "enabled": false,
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}