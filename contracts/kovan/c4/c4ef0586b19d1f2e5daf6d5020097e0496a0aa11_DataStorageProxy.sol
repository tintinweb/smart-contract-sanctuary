/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./Ownable.sol";

interface DataStorageProxyHelpers {
    function hasSystemAdminRights(address addr) external view returns (bool);

    function getUserBytesFromWallet(address wallet) external view returns (bytes32);

    function getCPBytesFromWallet(address wallet) external view returns (bytes32);

    function isUserWhitelisted(bytes32 cp, bytes32 user) external view returns (bool);

    function isCertifiedPartner(address addr) external view returns (bool);

    function canCertifiedPartnerDistributeRent(address addr) external view returns (bool);

    function isCPAdmin(address admin, address cp) external view returns (bool);
}

/// @title Data Storage Proxy
contract DataStorageProxy is Ownable {

    struct Fee {
        uint256 licencedIssuerFee;
        uint256 blocksquareFee;
        uint256 certifiedPartnerFee;
    }

    mapping(bytes32 => bool) _cpFrozen;
    mapping(address => bool) _propertyFrozen;
    mapping(address => address) _propertyToCP;
    mapping(address => bool) _whitelistedContract;

    address private _factory;
    address private _roles;
    address private _users;
    address private _certifiedPartners;
    address private _blocksquare;
    address private _oceanPoint;
    address private _government;

    address private _specialWallet;

    bool private _systemFrozen;

    Fee private _fee;

    modifier onlySystemAdmin {
        require(DataStorageProxyHelpers(_roles).hasSystemAdminRights(msg.sender), "DataStorageProxy: You need to have system admin rights!");
        _;
    }

    event TransferPropertyToCP(address property, address CP);
    event FreezeProperty(address property, bool frozen);

    constructor(address roles, address CP, address users, address specialWallet) public {
        // 5 means 0.5 percent of whole transaction value
        _fee = Fee(5, 5, 5);
        _blocksquare = msg.sender;
        _roles = roles;
        _users = users;
        _certifiedPartners = CP;
        _specialWallet = specialWallet;
    }

    function changeSpecialWallet(address specialWallet) public onlyOwner {
        _specialWallet = specialWallet;
    }

    function changeFactory(address factory) public onlyOwner {
        _factory = factory;
    }


    function changeRoles(address roles) public onlyOwner {
        _roles = roles;
    }

    function changeUsers(address users) public onlyOwner {
        _users = users;
    }

    function changeGovernmentContract(address government) public onlyOwner {
        _government = government;
    }

    function changeCertifiedPartners(address certifiedPartners) public onlyOwner {
        _certifiedPartners = certifiedPartners;
    }

    function changeOceanPointContract(address oceanPoint) public onlyOwner {
        _oceanPoint = oceanPoint;
    }

    /// @notice change whether contr can be used as minting of burning contract
    /// @param contr Contract address
    /// @param isWhitelisted Whether contract can be used or not
    function changeWhitelistedContract(address contr, bool isWhitelisted) public onlySystemAdmin {
        _whitelistedContract[contr] = isWhitelisted;
    }

    function changeFees(uint256 licencedIssuerFee, uint256 blocksquareFee, uint256 certifiedPartnerFee) public onlyOwner {
        require(_msgSender() == owner() || _msgSender() == _government, "DataStorageProxy: You can't change fee");
        require(licencedIssuerFee + blocksquareFee + certifiedPartnerFee <= 10000, "DataStorageProxy: Fee needs to be equal or bellow 100");
        _fee = Fee(licencedIssuerFee, blocksquareFee, certifiedPartnerFee);
    }

    function changeBlocksquareAddress(address blocksquare) public onlyOwner {
        _blocksquare = blocksquare;
    }

    /// @notice register prop to cp, can only be invoked by property factory contract
    /// @param prop Property contract address
    /// @param cp Certified Partner wallet (this wallet will receive fee from property)
    function addPropertyToCP(address prop, address cp) public {
        require(_factory == msg.sender, "DataHolder: Only factory can add properties");
        _propertyToCP[prop] = cp;
        _propertyFrozen[prop] = true;
    }

    /// @notice change Certified Partner of property
    /// @param prop Property contract address
    /// @param cp Certified Partner wallet (this wallet will receive fee from property)
    function changePropertyToCP(address prop, address cp) public onlySystemAdmin {
        require(isCertifiedPartner(cp), "DataStorageProxy: Can only assign property to Certified Partner");
        _propertyToCP[prop] = cp;
        emit TransferPropertyToCP(prop, cp);
    }

    function freezeSystem() public onlyOwner {
        _systemFrozen = true;
    }

    function unfreezeSystem() public onlyOwner {
        _systemFrozen = false;
    }

    /// @notice freeze Certified Partner (stops transactions for all Certified Partners properties)
    /// @param cp Certified Partner wallet
    function freezeCP(address cp) public onlySystemAdmin {
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(cp);
        _cpFrozen[cpBytes] = true;
    }

    /// @notice unfreeze Certified Partner (allowing transactions for all Certified Partners properties)
    /// @param cp Certified Partner wallet
    function unfreezeCP(address cp) public onlySystemAdmin {
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(cp);
        _cpFrozen[cpBytes] = false;
    }

    /// @notice freeze property (stopping transactions for property)
    /// @param prop Property contract address
    function freezeProperty(address prop) public {
        require(_propertyToCP[msg.sender] != address(0), "DataHolder: Sender must be property that belongs to a CP!");
        require(msg.sender == prop, "DataHolder: Only property can freeze itself!");
        _propertyFrozen[prop] = true;
        emit FreezeProperty(prop, true);
    }

    /// @notice unfreeze property (allowing transactions for property)
    /// @param prop Property contract address
    function unfreezeProperty(address prop) public {
        require(_propertyToCP[msg.sender] != address(0), "DataHolder: Sender must be property that belongs to a CP!");
        require(msg.sender == prop, "DataHolder: Only property can unfreeze itself!");
        _propertyFrozen[prop] = false;
        emit FreezeProperty(prop, false);
    }

    /// @notice checks if system is frozen
    function isSystemFrozen() public view returns (bool) {
        return _systemFrozen;
    }

    /// @notice checks if Certified Partner is frozen
    /// @param cp Certified Partner wallet address
    function isCPFrozen(address cp) public view returns (bool) {
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(cp);
        return _systemFrozen || _cpFrozen[cpBytes];
    }

    /// @notice checks if property is frozen
    /// @param property Property contract address
    function isPropTokenFrozen(address property) public view returns (bool) {
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(_propertyToCP[property]);
        return _systemFrozen || _cpFrozen[cpBytes] || _propertyFrozen[property];
    }

    /// @notice retrieves roles contract address
    function getRolesAddress() public view returns (address) {
        return _roles;
    }

    /// @notice retrieves property factory contract address
    function getPropertiesFactoryAddress() public view returns (address) {
        return _factory;
    }

    /// @notice retrieves users contract address
    function getUsersAddress() public view returns (address) {
        return _users;
    }

    /// @notice retrieves government contract address
    function getGovernmentAddress() public view returns (address) {
        return _government;
    }

    /// @notice checks if wallet has system admin rights
    /// @param sender Wallet address to check
    function hasSystemAdminRights(address sender) public view returns (bool) {
        return DataStorageProxyHelpers(_roles).hasSystemAdminRights(sender);
    }

    /// @notice retrieves certified partners contract address
    function getCertifiedPartnersAddress() public view returns (address) {
        return _certifiedPartners;
    }

    /// @notice retrieves blocksquare wallet address which receives fee
    function getBlocksquareAddress() public view returns (address) {
        return _blocksquare;
    }

    /// @notice retrieves Certified Partner's wallet address that receives fee for given property
    /// @param prop Property contract address
    /// @return wallet address
    function getCPOfProperty(address prop) public view returns (address) {
        return _propertyToCP[prop];
    }

    /// @notice checks if wallet belongs to Certified Partner
    /// @param addr Wallet address to check
    function isCertifiedPartner(address addr) public view returns (bool) {
        return DataStorageProxyHelpers(_certifiedPartners).isCertifiedPartner(addr);
    }

    /// @notice check if wallet can distribute revenue
    /// @param cpWallet Wallet address to check
    function canDistributeRent(address cpWallet) public view returns (bool) {
        return DataStorageProxyHelpers(_roles).hasSystemAdminRights(cpWallet) || DataStorageProxyHelpers(_certifiedPartners).canCertifiedPartnerDistributeRent(cpWallet);
    }

    /// @notice check if admin wallet address is admin of property
    /// @param admin Admin wallet address
    /// @param property Property contract address
    function isCPAdminOfProperty(address admin, address property) public view returns (bool) {
        address cp = _propertyToCP[property];
        return DataStorageProxyHelpers(_certifiedPartners).isCPAdmin(admin, cp);
    }

    /// @notice check if wallet address can edit property
    /// @param wallet Wallet address
    /// @param property Property contract address
    function canEditProperty(address wallet, address property) public view returns (bool) {
        address propOwner = getCPOfProperty(property);
        return propOwner == wallet ||
        isCPAdminOfProperty(wallet, property) ||
        DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(wallet) == DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(propOwner) ||
        DataStorageProxyHelpers(_roles).hasSystemAdminRights(wallet);
    }

    /// @notice retrieves ocean point contracts
    function getOceanPointContract() public view returns (address) {
        return _oceanPoint;
    }

    /// @notice retrieves Certified Partner fee
    function getCertifiedPartnerFee() public view returns (uint256) {
        return _fee.certifiedPartnerFee;
    }

    /// @notice retrieves Licenced Issuer fee
    function getLicencedIssuerFee() public view returns (uint256) {
        return _fee.licencedIssuerFee;
    }

    /// @notice retrieves Blocksquare fee
    function getBlocksquareFee() public view returns (uint256) {
        return _fee.blocksquareFee;
    }

    /// @notice retrieves special wallet address
    function getSpecialWallet() public view returns (address) {
        return _specialWallet;
    }

    /// @notice checks if contract address can be used for minting and burning
    /// @param cont Contract address
    function isContractWhitelisted(address cont) public view returns (bool) {
        return _whitelistedContract[cont];
    }

    /// @notice checks if property tokens can be transfered to wallet
    /// @param wallet Wallet address
    /// @param property Property contract address
    function canTransferPropTokensTo(address wallet, address property) public view returns (bool) {
        if (wallet == address(0)) {
            return false;
        }
        address cp = getCPOfProperty(property);
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(cp);
        bytes32 userBytes = DataStorageProxyHelpers(_users).getUserBytesFromWallet(wallet);
        if (DataStorageProxyHelpers(_certifiedPartners).isUserWhitelisted(cpBytes, userBytes)) {
            return true;
        }
        return false;
    }
}