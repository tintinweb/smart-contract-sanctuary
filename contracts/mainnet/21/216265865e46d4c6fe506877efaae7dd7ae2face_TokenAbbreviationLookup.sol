pragma solidity ^0.4.24;

// (c) copyright SecureVote 2018
// github.com/secure-vote/sv-light-smart-contracts

contract owned {
    address public owner;

    event OwnerChanged(address newOwner);

    modifier only_owner() {
        require(msg.sender == owner, "only_owner: forbidden");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address newOwner) only_owner() external {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
}

contract hasAdmins is owned {
    mapping (uint => mapping (address => bool)) admins;
    uint public currAdminEpoch = 0;
    bool public adminsDisabledForever = false;
    address[] adminLog;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);
    event AdminEpochInc();
    event AdminDisabledForever();

    modifier only_admin() {
        require(adminsDisabledForever == false, "admins must not be disabled");
        require(isAdmin(msg.sender), "only_admin: forbidden");
        _;
    }

    constructor() public {
        _setAdmin(msg.sender, true);
    }

    function isAdmin(address a) view public returns (bool) {
        return admins[currAdminEpoch][a];
    }

    function getAdminLogN() view external returns (uint) {
        return adminLog.length;
    }

    function getAdminLog(uint n) view external returns (address) {
        return adminLog[n];
    }

    function upgradeMeAdmin(address newAdmin) only_admin() external {
        // note: already checked msg.sender has admin with `only_admin` modifier
        require(msg.sender != owner, "owner cannot upgrade self");
        _setAdmin(msg.sender, false);
        _setAdmin(newAdmin, true);
    }

    function setAdmin(address a, bool _givePerms) only_admin() external {
        require(a != msg.sender && a != owner, "cannot change your own (or owner&#39;s) permissions");
        _setAdmin(a, _givePerms);
    }

    function _setAdmin(address a, bool _givePerms) internal {
        admins[currAdminEpoch][a] = _givePerms;
        if (_givePerms) {
            emit AdminAdded(a);
            adminLog.push(a);
        } else {
            emit AdminRemoved(a);
        }
    }

    // safety feature if admins go bad or something
    function incAdminEpoch() only_owner() external {
        currAdminEpoch++;
        admins[currAdminEpoch][msg.sender] = true;
        emit AdminEpochInc();
    }

    // this is internal so contracts can all it, but not exposed anywhere in this
    // contract.
    function disableAdminForever() internal {
        currAdminEpoch++;
        adminsDisabledForever = true;
        emit AdminDisabledForever();
    }
}

contract TokenAbbreviationLookup is hasAdmins {

    event RecordAdded(bytes32 abbreviation, bytes32 democHash, bool hidden);

    struct Record {
        bytes32 democHash;
        bool hidden;
    }

    struct EditRec {
        bytes32 abbreviation;
        uint timestamp;
    }

    mapping (bytes32 => Record) public lookup;

    EditRec[] public edits;

    function nEdits() external view returns (uint) {
        return edits.length;
    }

    function lookupAllSince(uint pastTs) external view returns (bytes32[] memory abrvs, bytes32[] memory democHashes, bool[] memory hiddens) {
        bytes32 abrv;
        for (uint i = 0; i < edits.length; i++) {
            if (edits[i].timestamp >= pastTs) {
                abrv = edits[i].abbreviation;
                Record storage r = lookup[abrv];
                abrvs = MemArrApp.appendBytes32(abrvs, abrv);
                democHashes = MemArrApp.appendBytes32(democHashes, r.democHash);
                hiddens = MemArrApp.appendBool(hiddens, r.hidden);
            }
        }
    }

    function addRecord(bytes32 abrv, bytes32 democHash, bool hidden) only_admin() external {
        lookup[abrv] = Record(democHash, hidden);
        edits.push(EditRec(abrv, now));
        emit RecordAdded(abrv, democHash, hidden);
    }

}

library MemArrApp {

    // A simple library to allow appending to memory arrays.

    function appendUint256(uint256[] memory arr, uint256 val) internal pure returns (uint256[] memory toRet) {
        toRet = new uint256[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendUint128(uint128[] memory arr, uint128 val) internal pure returns (uint128[] memory toRet) {
        toRet = new uint128[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendUint64(uint64[] memory arr, uint64 val) internal pure returns (uint64[] memory toRet) {
        toRet = new uint64[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendUint32(uint32[] memory arr, uint32 val) internal pure returns (uint32[] memory toRet) {
        toRet = new uint32[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendUint16(uint16[] memory arr, uint16 val) internal pure returns (uint16[] memory toRet) {
        toRet = new uint16[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendBool(bool[] memory arr, bool val) internal pure returns (bool[] memory toRet) {
        toRet = new bool[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendBytes32(bytes32[] memory arr, bytes32 val) internal pure returns (bytes32[] memory toRet) {
        toRet = new bytes32[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendBytes32Pair(bytes32[2][] memory arr, bytes32[2] val) internal pure returns (bytes32[2][] memory toRet) {
        toRet = new bytes32[2][](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendBytes(bytes[] memory arr, bytes val) internal pure returns (bytes[] memory toRet) {
        toRet = new bytes[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendAddress(address[] memory arr, address val) internal pure returns (address[] memory toRet) {
        toRet = new address[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

}