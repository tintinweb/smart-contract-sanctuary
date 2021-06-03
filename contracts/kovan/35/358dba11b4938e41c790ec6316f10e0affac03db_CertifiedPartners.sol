pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

interface CertifiedPartnersHelpers {
    function hasSystemAdminRights(address addr) external view returns (bool);

    function isCPAdminOf(address account, bytes32 cpBytes) external view returns (bool);

    function getSpecialWallet() external view returns (address);
}

contract CertifiedPartners is Ownable {
    struct CertifiedPartner {
        bool canDistributeRent;
        bool isCP;
        mapping(bytes32 => bool) whitelistedUsers;
    }

    CertifiedPartnersHelpers private _roles;

    mapping(bytes32 => CertifiedPartner) private _certifiedPartner;
    mapping(address => bytes32) _associatedWallets;

    address private _dataProxy;


    event AddedCertifiedPartner(bytes32 indexed cpBytes, string cp);
    event AddedWallet(bytes32 indexed cp, address wallet);
    event RemovedWallet(bytes32 indexed cp, address wallet);
    event AddedWhitelisted(bytes32 indexed cp, string[] users);
    event RemovedWhitelisted(bytes32 indexed cp, string[] users);
    event CPRestricted(bytes32 indexed cp, bool isRestricted);

    modifier onlySystemAdmin {
        require(_roles.hasSystemAdminRights(_msgSender()), "CertifiedPartners: You need to have system admin rights!");
        _;
    }

    modifier onlySystemAdminOrSpecialWallet {
        require(_roles.hasSystemAdminRights(_msgSender()) || CertifiedPartnersHelpers(_dataProxy).getSpecialWallet() == _msgSender(), "CertifiedPartners: You don't have rights!");
        _;
    }

    modifier onlyCPAdmin(string memory cp) {
        bytes32 cpBytes = getUserBytes(cp);
        require(_roles.isCPAdminOf(_msgSender(), cpBytes) || CertifiedPartnersHelpers(_dataProxy).getSpecialWallet() == _msgSender(), "CertifiedPartners: You need to be admin of this CP!");
        _;
    }

    modifier onlyCPOrManager(string memory cp) {
        bytes32 cpBytes = getUserBytes(cp);
        require(_roles.isCPAdminOf(_msgSender(), cpBytes) || _associatedWallets[_msgSender()] == cpBytes || CertifiedPartnersHelpers(_dataProxy).getSpecialWallet() == _msgSender(), "CertifiedPartners: You need to have CP admin rights or you have to be CP!");
        _;
    }

    constructor(address roles) public {
        _roles = CertifiedPartnersHelpers(roles);
    }

    function changeRolesAddress(address newRoles) public onlyOwner {
        _roles = CertifiedPartnersHelpers(newRoles);
    }

    function changeDataProxy(address dataProxy) public onlyOwner {
        _dataProxy = dataProxy;
    }

    function addCertifiedPartner(string memory cp) public onlySystemAdmin {
        bytes32 cpBytes = getUserBytes(cp);
        _certifiedPartner[cpBytes] = CertifiedPartner({canDistributeRent : true, isCP : true});
        emit AddedCertifiedPartner(cpBytes, cp);
    }

    function addWalletsToCP(string memory cp, address[] memory wallets) public onlyCPAdmin(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        require(_certifiedPartner[cpBytes].isCP, "CertifiedPartners: Not a certified partner");
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

    function removeWallets(address[] memory wallets) public onlySystemAdminOrSpecialWallet {
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

    function addWhitelisted(string memory cp, string[] memory users) public onlyCPOrManager(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        for (uint256 i = 0; i < users.length; i++) {
            bytes32 userBytes = getUserBytes(users[i]);
            _certifiedPartner[cpBytes].whitelistedUsers[userBytes] = true;
        }
        emit AddedWhitelisted(cpBytes, users);
    }

    function removeWhitelisted(string memory cp, string[] memory users) public onlyCPOrManager(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        for (uint256 i = 0; i < users.length; i++) {
            bytes32 userBytes = getUserBytes(users[i]);
            _certifiedPartner[cpBytes].whitelistedUsers[userBytes] = false;
        }
        emit RemovedWhitelisted(cpBytes, users);
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

    function isUserWhitelistedByName(string memory cp, string memory user) public view returns (bool) {
        bytes32 cpBytes = getUserBytes(cp);
        return _certifiedPartner[cpBytes].whitelistedUsers[getUserBytes(user)];
    }

    function isCPAdmin(address admin, address cp) external view returns (bool) {
        return _roles.isCPAdminOf(admin, _associatedWallets[cp]);
    }

    function isUserWhitelisted(bytes32 cp, bytes32 user) external view returns (bool) {
        return _certifiedPartner[cp].whitelistedUsers[user];
    }

    function getUserBytes(string memory user) public pure returns (bytes32) {
        return keccak256(abi.encode(user));
    }

    function getCPBytesFromWallet(address wallet) public view returns (bytes32) {
        return _associatedWallets[wallet];
    }
}