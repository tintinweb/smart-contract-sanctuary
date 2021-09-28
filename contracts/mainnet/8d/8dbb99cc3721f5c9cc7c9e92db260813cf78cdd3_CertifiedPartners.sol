/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

interface CertifiedPartnersHelpers {
    function hasSystemAdminRights(address addr) external view returns (bool);

    function isCPAdminOf(address account, bytes32 cpBytes) external view returns (bool);

    function getSpecialWallet() external view returns (address);
}

// @title Certified Partners
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
    event AddedWallet(bytes32 indexed cp, address wallet, string cpName);
    event RemovedWallet(bytes32 indexed cp, address wallet);
    event AddedWhitelisted(bytes32 indexed cp, string[] users, string cpName);
    event RemovedWhitelisted(bytes32 indexed cp, string[] users, string cpName);

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

    /// @notice added new Certified Partner
    /// @param cp Certified Partner identifier
    function addCertifiedPartner(string memory cp) public onlySystemAdmin {
        bytes32 cpBytes = getUserBytes(cp);
        _certifiedPartner[cpBytes] = CertifiedPartner({canDistributeRent : true, isCP : true});
        emit AddedCertifiedPartner(cpBytes, cp);
    }

    /// @notice add wallets to Certified Partner
    /// @param cp Certified Partner identifier
    /// @param wallets Array of wallet address
    function addWalletsToCP(string memory cp, address[] memory wallets) public onlyCPAdmin(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        require(_certifiedPartner[cpBytes].isCP, "CertifiedPartners: Not a certified partner");
        for (uint256 i = 0; i < wallets.length; i++) {
            _associatedWallets[wallets[i]] = cpBytes;
            emit AddedWallet(cpBytes, wallets[i], cp);
        }
    }

    /// @notice add wallet to Certified Partner
    /// @param cp Certified Partner identifier
    /// @param wallet Wallet address
    function addCPAndWallet(string memory cp, address wallet) public onlySystemAdmin {
        bytes32 cpBytes = getUserBytes(cp);
        addCertifiedPartner(cp);
        _associatedWallets[wallet] = cpBytes;
        emit AddedWallet(cpBytes, wallet, cp);
    }

    /// @notice remove wallets
    /// @param wallets Array of wallet addresses
    function removeWallets(address[] memory wallets) public onlySystemAdminOrSpecialWallet {
        bytes32 cpBytes = _associatedWallets[wallets[0]];
        for (uint256 i = 0; i < wallets.length; i++) {
            delete _associatedWallets[wallets[i]];
            emit RemovedWallet(cpBytes, wallets[i]);
        }
    }

    /// @notice change whether Certified Partner can distribute revenue
    /// @param cp Certified Partner identifier
    function changeCanDistributeRent(string memory cp) public onlyCPAdmin(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        _certifiedPartner[cpBytes].canDistributeRent = !_certifiedPartner[cpBytes].canDistributeRent;
    }

    /// @notice whitelist users to Certified Partner allowing them to trade Certified Partner's properties
    /// @param cp Certified Partner identifier
    /// @param users Array of user identifiers
    function addWhitelisted(string memory cp, string[] memory users) public onlyCPOrManager(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        for (uint256 i = 0; i < users.length; i++) {
            bytes32 userBytes = getUserBytes(users[i]);
            _certifiedPartner[cpBytes].whitelistedUsers[userBytes] = true;
        }
        emit AddedWhitelisted(cpBytes, users, cp);
    }

    /// @notice remove users from Certified Partner's whitelist
    /// @param cp Certified Partner identifier
    /// @param users Array of user identifiers
    function removeWhitelisted(string memory cp, string[] memory users) public onlyCPOrManager(cp) {
        bytes32 cpBytes = getUserBytes(cp);
        for (uint256 i = 0; i < users.length; i++) {
            bytes32 userBytes = getUserBytes(users[i]);
            _certifiedPartner[cpBytes].whitelistedUsers[userBytes] = false;
        }
        emit RemovedWhitelisted(cpBytes, users, cp);
    }

    /// @notice check if Certified Partner identifier is registered
    /// @param name Identifier to check
    /// @return true if name is a registered Certified Partner otherwise false
    function isCertifiedPartnerName(string memory name) public view returns (bool) {
        bytes32 nameBytes = getUserBytes(name);
        return _certifiedPartner[nameBytes].isCP;
    }

    /// @notice check if addr belongs to a registered Certified Partner
    /// @param addr Wallet address to check
    /// @return true if addr belongs to a registered Certified Partner
    function isCertifiedPartner(address addr) public view returns (bool) {
        return _certifiedPartner[_associatedWallets[addr]].isCP;
    }

    /// @notice check if Certified Partner with wallet addr can distribute revenue
    /// @param addr Wallet address of Certified Partner
    /// @return true if Certified Partner with wallet addr can distribute revenue otherwise false
    function canCertifiedPartnerDistributeRent(address addr) public view returns (bool) {
        return _certifiedPartner[_associatedWallets[addr]].canDistributeRent;
    }

    /// @notice check if user is whitelisted for cp
    /// @param cp Certified Partner identifier
    /// @param user User identifier
    /// @return true if user is whitelisted for cp otherwise false
    function isUserWhitelistedByName(string memory cp, string memory user) public view returns (bool) {
        bytes32 cpBytes = getUserBytes(cp);
        return _certifiedPartner[cpBytes].whitelistedUsers[getUserBytes(user)];
    }

    /// @notice if admin is admin of cp based on wallet addresses
    /// @param admin Wallet address of admin
    /// @param cp Wallet address of Certified Partner
    /// @return true if admin is admin of cp otherwise false
    function isCPAdmin(address admin, address cp) external view returns (bool) {
        return _roles.isCPAdminOf(admin, _associatedWallets[cp]);
    }

    /// @notice check if user whitelisted for cp based on bytes
    /// @param cp Keccak256 hash of Certified Partner identifier
    /// @param user Keccak256 hash of user identifier
    /// @return true if user is whitelisted for cp otherwise false
    function isUserWhitelisted(bytes32 cp, bytes32 user) external view returns (bool) {
        return _certifiedPartner[cp].whitelistedUsers[user];
    }

    /// @notice get keccak256 hash of string
    /// @param user User or Certified Partner identifier
    /// @return keccak256 hash
    function getUserBytes(string memory user) public pure returns (bytes32) {
        return keccak256(abi.encode(user));
    }

    /// @notice retrieves keccak256 hash of Certified Partner based on wallet
    /// @param wallet Wallet address of Certified Partner
    /// @return keccak256 hash
    function getCPBytesFromWallet(address wallet) public view returns (bytes32) {
        return _associatedWallets[wallet];
    }
}