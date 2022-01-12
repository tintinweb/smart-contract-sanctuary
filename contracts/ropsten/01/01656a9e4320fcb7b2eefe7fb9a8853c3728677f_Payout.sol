/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Payout {
    address private owner;
    address[] private spenders;
    mapping(address => bool) private spendersMap;

    modifier isOwner(){
        require(msg.sender == owner, "For Owner only");
        _;
    }

    modifier isOwnerOrSpender(){
        require(spendersMap[msg.sender] || msg.sender == owner, "For Owner or Spender only");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address newOwner) external isOwner {
        owner = newOwner;
    }

    function setSpenders(address[] calldata newSpenders) external isOwner {
        for (uint i=0; i<spenders.length; i++) {
            spendersMap[spenders[i]] = false;
        }
        for (uint i=0; i<newSpenders.length; i++) {
            spendersMap[newSpenders[i]] = true;
        }
        spenders = newSpenders;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getSpenders() external view returns (address[] memory) {
        return spenders;
    }

    function payoutERC20Batch(address[] calldata tokens, address[] calldata recipients, uint[] calldata amounts) external isOwnerOrSpender {
        require(tokens.length == amounts.length && amounts.length == recipients.length, "Different arguments length");
        for (uint i=0; i<tokens.length; i++) {
            safeTransfer(tokens[i], recipients[i], amounts[i]);
        }
    }

    function payoutETHBatch(address payable[] calldata recipients, uint[] calldata amounts) external isOwnerOrSpender {
        require(recipients.length == amounts.length, "Different arguments length");
        for (uint i=0; i<recipients.length; i++) {
            safeTransferETH(recipients[i], amounts[i]);
        }
    }


    // https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol
    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    function safeTransfer(address token, address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }
        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
    
    receive() external payable {

    }
}