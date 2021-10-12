/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Storage for the Tangle and Reflector Contract
/// @dev This is a Diamond Storage implementation described in EIP-2535.
library SLib {

    enum ReflectCutAction { Add, Replace, Remove }
    struct SInfo {
        string _0;
        string _1;
        uint8 _2;
        uint totalSupply;
        uint piecesPerUnit;
    }
    struct SBalances {
        mapping(address => uint) balances;
        bool _0;
    }
    struct S {
        bytes32 initHash;
        Reflect_[] reflects;
        mapping(address => uint) reflectIndex;
    }
    struct Reflect_ {
        address address_;
        bool flag;
    }
    struct ReflectCut_ {
        ReflectCutAction action;
        Reflect_ reflect_;
    }
    /// @notice Records all reflections
    event Reflect(address from_, uint amount);
    /// @notice Records all reflection changes
    event ReflectCut(ReflectCut_[] reflectCut);

    function getS() internal pure returns (S storage s) {
        string memory id = "Tangle.Reflector";
        bytes32 storagePosition = keccak256(bytes(id));
        assembly {s.slot := storagePosition}
    }

    function getSInfo() internal pure returns (SInfo storage s) {
        bytes32 storagePosition = keccak256("Tangle.Info");
        assembly { s.slot := storagePosition }
    }

    function getSBalances(
        string memory id
    ) internal pure returns (SBalances storage s) {
        bytes32 storagePosition = keccak256(bytes(id));
        assembly { s.slot := storagePosition }
    }

}

/// @title Reflector, reflects tokens from certain addresses to all
/// other addresses
/// @author Brad Brown
/// @notice Reflects tokens from certain addresses to all other
/// addresses
contract Reflector {

    mapping(bytes4 => address) private selectorToAddress;
    address private owner;

    /// @notice Reflects all tokens from each address in the reflects list
    /// to everyone except the addresses in the noReflects list
    function reflect() external {
        require(msg.sender == address(this), "internal");
        SLib.S storage s = SLib.getS();
        if (s.reflects.length == 0) return;
        SLib.SInfo storage sInfo = SLib.getSInfo();
        SLib.SBalances storage sBalances = SLib.getSBalances(getMappingId("balances"));
        uint totalNoReflectBalance;
        uint totalReflectBalance;
        for (uint i = 0; i < s.reflects.length; i++) {
            SLib.Reflect_ memory reflect_ = s.reflects[i];
            if (!reflect_.flag)
                totalNoReflectBalance += sBalances.balances[reflect_.address_];
            if (reflect_.flag) {
                uint reflectAmount = sBalances.balances[reflect_.address_];
                totalReflectBalance += reflectAmount;
                sBalances.balances[reflect_.address_] = 0;
                emit SLib.Reflect(reflect_.address_, reflectAmount / sInfo.piecesPerUnit);
            }
        }
        if (totalReflectBalance == 0) return;
        uint totalSupply = sInfo.totalSupply;
        uint TIP = totalSupply * sInfo.piecesPerUnit - totalNoReflectBalance; // TIP: total included pieces
        uint TUP = TIP - totalReflectBalance; // TUP: total unaffected pieces
        uint newPiecesPerUnit = sInfo.piecesPerUnit * TUP / TIP;
        sInfo.piecesPerUnit = newPiecesPerUnit;
        if (sInfo.piecesPerUnit < 1)
            sInfo.piecesPerUnit = 1;
        for (uint i = 0; i < s.reflects.length; i++) {
            if (!s.reflects[i].flag) {
                uint nrBalance = sBalances.balances[s.reflects[i].address_];
                sBalances.balances[s.reflects[i].address_] = nrBalance * TUP / TIP;
            }
        }
    }

    function addReflect(SLib.Reflect_ memory reflect_) internal {
        SLib.S storage s = SLib.getS();
        require(!reflectExists(reflect_.address_), "reflect add");
        s.reflectIndex[reflect_.address_] = s.reflects.length;
        s.reflects.push(reflect_);
    }

    function removeReflect(SLib.Reflect_ memory reflect_) internal {
        SLib.S storage s = SLib.getS();
        require(reflectExists(reflect_.address_), "reflect remove");
        SLib.Reflect_ memory lastReflect = s.reflects[s.reflects.length - 1];
        address address_ = reflect_.address_;
        address lastReflectAddress = lastReflect.address_;
        if (lastReflectAddress != address_) {
            s.reflectIndex[lastReflectAddress] = s.reflectIndex[address_];
            s.reflects[s.reflectIndex[address_]] = lastReflect;
        }
        s.reflects.pop();
        s.reflectIndex[address_] = 0;
    }

    function replaceReflect(SLib.Reflect_ memory reflect_) internal {
        SLib.S storage s = SLib.getS();
        bool currentFlag = s.reflects[s.reflectIndex[reflect_.address_]].flag;
        require(
            reflectExists(reflect_.address_) &&
            (currentFlag != reflect_.flag),
            "reflect change"
        );
        s.reflects[s.reflectIndex[reflect_.address_]] = reflect_;
    }

    function reflectExists(address address_) internal view returns (bool) {
        SLib.S storage s = SLib.getS();
        if (s.reflects.length == 0)
            return false;
        if (s.reflectIndex[address_] > 0 || s.reflects[0].address_ == address_)
            return true;
        return false;
    }

    /// @notice Add/remove any number of addresses whose funds get reflected
    /// @param reflectCuts ReflectCut[]
    function reflectCut(
        SLib.ReflectCut_[] calldata reflectCuts
    ) external {
        require(msg.sender == owner, "not owner");
        bool changesMade = false;
        for (uint i = 0; i < reflectCuts.length; i++) {
            SLib.ReflectCut_ memory reflectCut_ = reflectCuts[i];
            if (reflectCut_.action == SLib.ReflectCutAction.Add) {
                addReflect(reflectCut_.reflect_);
                if (!changesMade) changesMade = true;
            }
            if (reflectCut_.action == SLib.ReflectCutAction.Replace) {
                replaceReflect(reflectCut_.reflect_);
                if (!changesMade) changesMade = true;
            }
            if (reflectCut_.action == SLib.ReflectCutAction.Remove) {
                removeReflect(reflectCut_.reflect_);
                if (!changesMade) changesMade = true;
            }
        }
        if (changesMade) emit SLib.ReflectCut(reflectCuts);
    }

    /// @notice Gets all addresses whose funds get reflected
    /// @return reflects_ All addresses whose funds are reflected
    function reflects()
        external
        view
        returns (SLib.Reflect_[] memory reflects_)
    {
        return SLib.getS().reflects;
    }
    
    function getMappingId(string memory name)
        internal
        view
        returns (string memory id)
    {
        (bool success, bytes memory result) = address(this).staticcall(
            abi.encodeWithSignature(
                "getId(string)",
                name
            )
        );
        require(success, "getMappingId reflector");
        assembly { id := add(result, 0x40) }
    }

}