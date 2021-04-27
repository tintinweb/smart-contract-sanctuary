pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

interface RolesCP {
    function hasSystemAdminRights(address addr) external view returns (bool);

    function isCPAdminOf(address account, bytes32 cpBytes) external view returns (bool);
}

contract CertifiedPartners is Ownable {
    struct CertifiedPartner {
        bool canDistributeRent;
        bool isCP;
        bool hasRestriction;
        mapping(bytes32 => bool) whitelabeledUsers;
    }

    RolesCP private _roles;

    mapping(bytes32 => CertifiedPartner) private _certifiedPartner;
    mapping(address => bytes32) _associatedWallets;


    event AddedCertifiedPartner(bytes32 indexed cpBytes, string cp);
    event AddedWallet(bytes32 indexed cp, address wallet);
    event RemovedWallet(bytes32 indexed cp, address wallet);
    event AddedWhitelabeled(bytes32 indexed cp, string[] users);
    event RemovedWhitelabeled(bytes32 indexed cp, string[] users);
    event CPRestricted(bytes32 indexed cp, bool isRestricted);

    modifier onlySystemAdmin {
        require(_roles.hasSystemAdminRights(msg.sender), "CertifiedPartners: You need to have system admin rights!");
        _;
    }

    modifier onlyCPAdmin(string memory cp) {
        bytes32 cpBytes = getUserBytes(cp);
        require(_roles.isCPAdminOf(msg.sender, cpBytes), "CertifiedPartners: You need to be admin of this CP!");
        _;
    }

    modifier onlyCPOrManager(string memory cp) {
        bytes32 cpBytes = getUserBytes(cp);
        require(_roles.isCPAdminOf(msg.sender, cpBytes) || _associatedWallets[msg.sender] == cpBytes, "CertifiedPartners: You need to have CP admin rights or you have to be CP!");
        _;
    }

    constructor(address roles) public {
        _roles = RolesCP(roles);
    }

    function changeRolesAddress(address newRoles) public onlyOwner {
        _roles = RolesCP(newRoles);
    }

    function addCertifiedPartner(string memory cp) public onlySystemAdmin {
        bytes32 cpBytes = getUserBytes(cp);
        _certifiedPartner[cpBytes] = CertifiedPartner({canDistributeRent : true, hasRestriction : true, isCP : true});
        emit AddedCertifiedPartner(cpBytes, cp);
    }

    function addWalletsToCP(string memory cp, address[] memory wallets) public onlyCPAdmin(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        for (uint256 i = 0; i < wallets.length; i++) {
            _associatedWallets[wallets[i]] = cpBytes;
            emit AddedWallet(cpBytes, wallets[i]);
        }
    }

    function addCPAndWallet(string memory cp, address wallet) public onlySystemAdmin {
        bytes32 cpBytes = getUserBytes(cp);
        addCertifiedPartner(cp);
        _associatedWallets[wallet] = cpBytes;
        emit AddedWallet(cpBytes, wallet);
    }

    function removeWallets(address[] memory wallets) public onlySystemAdmin {
        bytes32 cpBytes = _associatedWallets[wallets[0]];
        for (uint256 i = 0; i < wallets.length; i++) {
            delete _associatedWallets[wallets[i]];
            emit RemovedWallet(cpBytes, wallets[i]);
        }
    }

    function changeCanDistributeRent(string memory cp) public onlyCPAdmin(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        _certifiedPartner[cpBytes].canDistributeRent = !_certifiedPartner[cpBytes].canDistributeRent;
    }

    function changeRestrictionStatus(string memory cp) public onlyCPOrManager(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        _certifiedPartner[cpBytes].hasRestriction = !_certifiedPartner[cpBytes].hasRestriction;
        emit CPRestricted(cpBytes, _certifiedPartner[cpBytes].hasRestriction);
    }

    function addWhitelabeled(string memory cp, string[] memory users) public onlyCPOrManager(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        for (uint256 i = 0; i < users.length; i++) {
            bytes32 userBytes = getUserBytes(users[i]);
            _certifiedPartner[cpBytes].whitelabeledUsers[userBytes] = true;
        }
        emit AddedWhitelabeled(cpBytes, users);
    }

    function removeWhitelabeled(string memory cp, string[] memory users) public onlyCPOrManager(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        for (uint256 i = 0; i < users.length; i++) {
            bytes32 userBytes = getUserBytes(users[i]);
            _certifiedPartner[cpBytes].whitelabeledUsers[userBytes] = false;
        }
        emit RemovedWhitelabeled(cpBytes, users);
    }

    function isCertifiedPartnerName(string memory name) public view returns (bool) {
        bytes32 nameBytes = getUserBytes(name);
        return _certifiedPartner[nameBytes].isCP;
    }

    function isCertifiedPartner(address addr) public view returns (bool) {
        return _certifiedPartner[_associatedWallets[addr]].isCP;
    }

    function canCertifiedPartnerDistributeRent(address addr) public view returns (bool) {
        return _certifiedPartner[_associatedWallets[addr]].canDistributeRent;
    }

    function hasCertifiedPartnerRestriction(address addr) public view returns (bool) {
        return _certifiedPartner[_associatedWallets[addr]].hasRestriction;
    }

    function isUserWhitelabeledByName(string memory cp, string memory user) public view returns (bool) {
        bytes32 cpBytes = getUserBytes(cp);
        return _certifiedPartner[cpBytes].whitelabeledUsers[getUserBytes(user)];
    }

    function isCPAdmin(address admin, address cp) external view returns (bool) {
        return _roles.isCPAdminOf(admin, _associatedWallets[cp]);
    }

    function isUserWhitelabeled(bytes32 cp, bytes32 user) external view returns (bool) {
        return _certifiedPartner[cp].whitelabeledUsers[user];
    }

    function getUserBytes(string memory user) public pure returns (bytes32) {
        return keccak256(abi.encode(user));
    }

    function getCPBytesFromWallet(address wallet) public view returns (bytes32) {
        return _associatedWallets[wallet];
    }
}