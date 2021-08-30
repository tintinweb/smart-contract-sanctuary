/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

error PRBProxy__TargetZeroAddress();
error PRBProxy__TargetInvalid(address target);

contract PRBProxy {
    function execute(address target, bytes memory data)
        external
        payable
        returns (bytes memory response)
    {
        // Check that the target is not the zero address.
        if (target == address(0)) {
            revert PRBProxy__TargetZeroAddress();
        }

        // Check that the target is a valid contract.
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(target)
        }
        if (codeSize == 0) {
            revert PRBProxy__TargetInvalid(target);
        }

        assembly {
            // Delegate call to the target contract, but ensure that there will remain enough gas.
            let stipend := sub(gas(), 5000)
            let succeeded := delegatecall(stipend, target, add(data, 0x20), mload(data), 0, 0)
            let returnDataSize := returndatasize()

            // TODO: explain this
            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(returnDataSize, 0x20), 0x1f), not(0x1f))))
            mstore(response, returnDataSize)
            returndatacopy(add(response, 0x20), 0, returnDataSize)

            // Check if the delegatecall failed, and revert if it did.
            switch iszero(succeeded)
            case 1 {
                revert(add(response, 0x20), returnDataSize)
            }
        }
    }
}