/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Post-Transfer Hooks storage for Tangle
/// @dev This is a Diamond Storage implementation described in EIP-2535.
library SLib {

    enum PTHCutAction {Add, Replace, Remove}
    struct S {
        string[] signatures;
        mapping(string => uint) signatureIndex;
        mapping(string => PTH) hooks;
    }
    struct PTH {
        string signature;
        uint8 forwardNumber;
    }
    struct PTHCut_ {
        PTHCutAction action;
        PTH hook;
    }
    /// @notice Records all Post-Transfer Hook changes
    event PTHCut(PTHCut_[] pthCuts);

    function getS() internal pure returns (S storage s) {
        bytes32 storagePosition = keccak256("Tangle.PostTransferHooks");
        assembly { s.slot := storagePosition }
    }

}

/// @title Post-Transfer Hooks for Tangle
/// @author Brad Brown
/// @notice Stores and provides information related to Tangle's Post-Transfer
/// Hooks, (calls that are executed after each Tangle Transfer).
contract PostTransferHooks {

    mapping(bytes4 => address) private _0;
    address private owner;

    function addHook(SLib.PTH memory hook) internal {
        SLib.S storage s = SLib.getS();
        require(!signatureExists(hook.signature), "pth add");
        s.signatureIndex[hook.signature] = s.signatures.length;
        s.signatures.push(hook.signature);
        s.hooks[hook.signature] = hook;
    }

    function removeHook(SLib.PTH memory hook) internal {
        SLib.S storage s = SLib.getS();
        require(signatureExists(hook.signature), "pth remove");
        string memory lastSignature = s.signatures[s.signatures.length - 1];
        if (keccak256(bytes(lastSignature)) != keccak256(bytes(hook.signature))) {
            s.signatureIndex[lastSignature] = s.signatureIndex[hook.signature];
            s.signatures[s.signatureIndex[hook.signature]] = lastSignature;
        }
        s.signatureIndex[hook.signature] = 0;
        s.signatures.pop();
    }
    
    function replaceHook(SLib.PTH memory hook) internal {
        SLib.S storage s = SLib.getS();
        require(
            signatureExists(hook.signature) && 
            s.hooks[hook.signature].forwardNumber != hook.forwardNumber
            , "pth replace"
        );
        s.hooks[hook.signature] = hook;
    }

    function signatureExists(string memory signature) internal view returns (bool) {
        SLib.S storage s = SLib.getS();
        if (s.signatures.length == 0)
            return false;
        if (
            s.signatureIndex[signature] > 0 ||
            keccak256(bytes(s.signatures[0])) == keccak256(bytes(signature))
        )
            return true;
        return false;
    }

    /// @notice Add/change/remove any number of Post-Transfer Hooks
    /// @param pthCuts Contains Post-Transfer Hooks and if they're being
    /// added or removed
    function pthCut(
        SLib.PTHCut_[] calldata pthCuts
    ) external {
        require(msg.sender == owner, "pthCut");
        bool changesMade = false;
        for (uint i = 0; i < pthCuts.length; i++) {
            SLib.PTHCut_ memory pthCut_ = pthCuts[i];
            if (pthCut_.action == SLib.PTHCutAction.Add) {
                addHook(pthCut_.hook);
                if (!changesMade) changesMade = true;
            }
            if (pthCut_.action == SLib.PTHCutAction.Replace) {
                replaceHook(pthCut_.hook);
                if (!changesMade) changesMade = true;
            }
            if (pthCut_.action == SLib.PTHCutAction.Remove) {
                removeHook(pthCut_.hook);
                if (!changesMade) changesMade = true;
            }
        }
        if (changesMade) emit SLib.PTHCut(pthCuts);
    }

    /// @notice Gets all Post-Transfer Hooks
    /// @return A list of all Post-Transfer Hooks
    function postTransferHooks()
        external
        view
        returns (SLib.PTH[] memory)
    {
        SLib.S storage s = SLib.getS();
        SLib.PTH[] memory pths = new SLib.PTH[](s.signatures.length);
        for (uint i = 0; i < s.signatures.length; i++) {
            pths[i] = s.hooks[s.signatures[i]];
        }
        return pths;
    }

    /// @notice Executes all Post-Transfer Hooks.
    /// @param sender The sender of the transfer
    /// @param receiver The receiver of the transfer
    /// @param value The value of the transfer
    function executePostTransferHooks(
        address sender,
        address receiver,
        uint value
    ) external {
        require(msg.sender == address(this), "executePostTransferHooks");
        SLib.S storage s = SLib.getS();
        for (uint i = 0; i < s.signatures.length; i++) {
            SLib.PTH memory pth = s.hooks[s.signatures[i]];
            uint forwardNumber = pth.forwardNumber;
            string memory sig = pth.signature;
            assembly {
                let len := 0x4
                let ptr := mload(0x40)
                mstore(ptr, keccak256(add(sig, 0x20), mload(sig)))
                if and(forwardNumber, 1) {
                    mstore(add(ptr, len), sender)
                    len := add(len, 0x20)
                }
                if and(forwardNumber, 2) {
                    mstore(add(ptr, len), receiver)
                    len := add(len, 0x20)
                }
                if and(forwardNumber, 4) {
                    mstore(add(ptr, len), value)
                    len := add(len, 0x20)
                }
                mstore(0x40, add(ptr, len))
                let result := call(gas(), address(), 0, ptr, len, 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                    case 0 { revert(0, returndatasize()) }
                    default {}
            }
        }
    }

}