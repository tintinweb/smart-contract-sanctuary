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

    /**
    * @dev Changes current `factory`
    * @param factory Address of the factory
    */
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


    function addPropertyToCP(address prop, address cp) public {
        require(_factory == msg.sender, "DataHolder: Only factory can add properties");
        _propertyToCP[prop] = cp;
        _propertyFrozen[prop] = true;
    }

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

    function freezeCP(address cp) public onlySystemAdmin {
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(cp);
        _cpFrozen[cpBytes] = true;
    }

    function unfreezeCP(address cp) public onlySystemAdmin {
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(cp);
        _cpFrozen[cpBytes] = false;
    }

    function freezeProperty(address prop) public {
        require(_propertyToCP[msg.sender] != address(0), "DataHolder: Sender must be property that belongs to a CP!");
        require(msg.sender == prop, "DataHolder: Only property can freeze itself!");
        _propertyFrozen[prop] = true;
        emit FreezeProperty(prop, true);
    }

    function unfreezeProperty(address prop) public {
        require(_propertyToCP[msg.sender] != address(0), "DataHolder: Sender must be property that belongs to a CP!");
        require(msg.sender == prop, "DataHolder: Only property can unfreeze itself!");
        _propertyFrozen[prop] = false;
        emit FreezeProperty(prop, false);
    }

    function isSystemFrozen() public view returns (bool) {
        return _systemFrozen;
    }

    function isCPFrozen(address cp) public view returns (bool) {
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(cp);
        return _systemFrozen || _cpFrozen[cpBytes];
    }

    function isPropTokenFrozen(address property) public view returns (bool) {
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(_propertyToCP[property]);
        return _systemFrozen || _cpFrozen[cpBytes] || _propertyFrozen[property];
    }

    function getRolesAddress() public view returns (address) {
        return _roles;
    }

    function getPropertiesFactoryAddress() public view returns (address) {
        return _factory;
    }

    function getUsersAddress() public view returns (address) {
        return _users;
    }

    function getGovernmentAddress() public view returns (address) {
        return _government;
    }

    function hasSystemAdminRights(address sender) public view returns (bool) {
        return DataStorageProxyHelpers(_roles).hasSystemAdminRights(sender);
    }

    function getCertifiedPartnersAddress() public view returns (address) {
        return _certifiedPartners;
    }

    function getBlocksquareAddress() public view returns (address) {
        return _blocksquare;
    }

    function getCPOfProperty(address prop) public view returns (address) {
        return _propertyToCP[prop];
    }

    function isCertifiedPartner(address addr) public view returns (bool) {
        return DataStorageProxyHelpers(_certifiedPartners).isCertifiedPartner(addr);
    }

    function canDistributeRent(address cpWallet) public view returns (bool) {
        return DataStorageProxyHelpers(_roles).hasSystemAdminRights(cpWallet) || DataStorageProxyHelpers(_certifiedPartners).canCertifiedPartnerDistributeRent(cpWallet);
    }

    function isCPAdminOfProperty(address admin, address property) public view returns (bool) {
        address cp = _propertyToCP[property];
        return DataStorageProxyHelpers(_certifiedPartners).isCPAdmin(admin, cp);
    }

    function canEditProperty(address wallet, address property) public view returns (bool) {
        address propOwner = getCPOfProperty(property);
        return propOwner == wallet ||
        isCPAdminOfProperty(wallet, property) ||
        DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(wallet) == DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(propOwner) ||
        DataStorageProxyHelpers(_roles).hasSystemAdminRights(wallet);
    }

    function getOceanPointContract() public view returns (address) {
        return _oceanPoint;
    }

    function getCertifiedPartnerFee() public view returns (uint256) {
        return _fee.certifiedPartnerFee;
    }

    function getLicencedIssuerFee() public view returns (uint256) {
        return _fee.licencedIssuerFee;
    }

    function getBlocksquareFee() public view returns (uint256) {
        return _fee.blocksquareFee;
    }

    function getSpecialWallet() public view returns (address) {
        return _specialWallet;
    }

    function isContractWhitelisted(address cont) public view returns (bool) {
        return _whitelistedContract[cont];
    }

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