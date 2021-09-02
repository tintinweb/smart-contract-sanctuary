/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract Zap {
    address public owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Zap: caller is not the owner");
        _;
    }

    constructor(address _owner) public {
        owner = _owner;
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) external payable onlyOwner {
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "length mismatch"
        );

        for (uint256 i = 0; i < targets.length; i++) {
            bytes memory callData;

            if (bytes(signatures[i]).length == 0) {
                callData = calldatas[i];
            } else {
                callData = abi.encodePacked(bytes4(keccak256(bytes(signatures[i]))), calldatas[i]);
            }

            // solhint-disable-next-line
            (bool success, bytes memory returndata) = targets[i].call{ value: values[i] }(callData);
            verifyCallResult(success, returndata, "Zap: call failed");
        }
    }

    /// Private Functions

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}