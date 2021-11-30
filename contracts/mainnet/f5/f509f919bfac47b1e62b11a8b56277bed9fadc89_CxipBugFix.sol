// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/*______/\\\\__/\_______/\__/\\\\\__/\\\\\\___
 _____/\////////__///\___/\/__/////\///__/\/////////\_
  ___/\/_____________///\\\/________/\_____/\_______/\_
   __/\_________________//\\__________/\_____/\\\\\\/__
    _/\__________________/\\__________/\_____/\/////////____
     _//\_________________/\\\_________/\_____/\_____________
      __///\_____________/\////\_______/\_____/\_____________
       ____////\\\\__/\/___///\__/\\\\\_/\_____________
        _______/////////__///_______///__///////////__///____________*/

/**
 * @title CXIP Custom Bug Fix
 * @author CXIP-Labs
 * @notice This is a custom bug fix for a very specific token/contract.
 * @dev Functions are restricted to specific contract, and specific token.
 */
contract CxipBugFix {

    /**
     * @dev We are leaving constructor empty on purpose. To not disturb any existing data
     */
    constructor() {}

    /**
     * @dev Updating Arweave URI for token id #15
     */
    function fixUriEvanesceToken15 (bytes32 arweave, bytes32 arweave2) public {
        require ((
            msg.sender == 0xa8A7F79c4B7A7613044CA098fe408c40Ca75778d
            || msg.sender == 0xa198FA5db682a2A828A90b42D3Cd938DAcc01ADE
        ), "CXIP: Unauthorized wallet");
        require (
            address (this) == 0x0B8a1ec4891eFBbaC5Bc34046512f0743B63539D,
            "CXIP: Unauthorized contract"
        );
        assembly {
            sstore(
                0x977a47af6886c81cccba9ceb5316ec9b4027c59ac276de3e2cb39ec8af72ee80,
                arweave
            )
            sstore(
                0x977a47af6886c81cccba9ceb5316ec9b4027c59ac276de3e2cb39ec8af72ee81,
                arweave2
            )
        }
    }

    /**
     * @dev Updating token id #15 payload signature, since it's slightly different.
     */
    function fixSignatureEvanesceToken15 (
        bytes32 payloadHash,
        bytes32 payloadSignatureR,
        bytes32 payloadSignatureS,
        bytes32 payloadSignatureV
    ) public {
        require ((
            msg.sender == 0xa8A7F79c4B7A7613044CA098fe408c40Ca75778d
            || msg.sender == 0xa198FA5db682a2A828A90b42D3Cd938DAcc01ADE
        ), "CXIP: Unauthorized wallet");
        require (
            address (this) == 0x0B8a1ec4891eFBbaC5Bc34046512f0743B63539D,
            "CXIP: Unauthorized contract"
        );
        assembly {
            sstore(
                0x977a47af6886c81cccba9ceb5316ec9b4027c59ac276de3e2cb39ec8af72ee7b,
                payloadHash
            )
            sstore(
                0x977a47af6886c81cccba9ceb5316ec9b4027c59ac276de3e2cb39ec8af72ee7c,
                payloadSignatureR
            )
            sstore(
                0x977a47af6886c81cccba9ceb5316ec9b4027c59ac276de3e2cb39ec8af72ee7d,
                payloadSignatureS
            )
            sstore(
                0x977a47af6886c81cccba9ceb5316ec9b4027c59ac276de3e2cb39ec8af72ee7e,
                payloadSignatureV
            )
        }
    }

    /**
     * @dev Public function for anyone to easily check/test storage slot data.
     */
    function getStorageSlot (bytes32 slot) public view returns (bytes32 data) {
        assembly {
            data := sload(slot)
        }
    }

    /**
     * @dev Catching all other functions and delegating them to _defaultFallback.
     */
    receive() external payable {
        _defaultFallback();
    }

    /**
     * @dev Catching all other functions and delegating them to _defaultFallback.
     */
    fallback() external {
        _defaultFallback();
    }

    /**
     * @dev Redirecting to original ERC721 smart contract that was at getERC721CollectionSource.
     * @dev For a quick and gas effective .
     */
    function _defaultFallback() internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                0x0fb6c0de0d3cd2a27941981ea1de878348b26014,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

}