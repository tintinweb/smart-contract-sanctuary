pragma solidity ^0.6.12;

import "./Ownable.sol";

interface DataStorageProxyHelpers {
    function hasSystemAdminRights(address addr) external view returns (bool);

    function isWhitelisted(address addr) external view returns (bool);

    function getUserBytesFromWallet(address wallet) external view returns (bytes32);

    function getCPBytesFromWallet(address wallet) external view returns (bytes32);

    function isUserWhitelabeled(bytes32 cp, bytes32 user) external view returns (bool);

    function hasCertifiedPartnerRestriction(address addr) external view returns (bool);

    function isCertifiedPartner(address addr) external view returns (bool);

    function canCertifiedPartnerDistributeRent(address addr) external view returns (bool);

    function isCPAdmin(address admin, address cp) external view returns (bool);
}

contract DataStorageProxy is Ownable {

    // Add option for property to change CP
    // Add option to change owner of property
    // Special code naj bo vezan na CP, v transfer poglej kdo je CP in kakšen special code ima(če ga ima)
    // Podobna stvar za restricted countries
    struct Fee {
        uint256 licencedIssuerFee;
        uint256 blocksquareFee;
        uint256 certifiedPartnerFee;
    }

    mapping(bytes32 => bool) _cpFrozen;
    mapping(address => bool) _propertyFrozen;
    mapping(address => address) _propertyToCP;
    mapping(address => uint64) _cpToSpecialCode;
    mapping(address => uint64[]) _cpToForbiddenCountries;

    address private _factory;
    address private _roles;
    address private _users;
    address private _certifiedPartners;
    address private _blocksquare;
    address private _oceanPoint;


    bool private _systemFrozen;

    Fee private _fee;

    modifier onlySystemAdmin {
        require(DataStorageProxyHelpers(_roles).hasSystemAdminRights(msg.sender), "DataStorageProxy: You need to have system admin rights!");
        _;
    }

    constructor(address roles, address CP, address users) public {
        // 5 means 0.5 percent of whole transaction value
        _fee = Fee(5, 5, 5);
        _blocksquare = msg.sender;
        _roles = roles;
        _users = users;
        _certifiedPartners = CP;
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

    function changeCertifiedPartners(address certifiedPartners) public onlyOwner {
        _certifiedPartners = certifiedPartners;
    }

    function changeOceanPointContract(address oceanPoint) public onlyOwner {
        _oceanPoint = oceanPoint;
    }

    function changeFees(uint256 licencedIssuerFee, uint256 blocksquareFee, uint256 certifiedPartnerFee) public onlyOwner {
        // TODO new role that could change this
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
    }

    function unfreezeProperty(address prop) public {
        require(_propertyToCP[msg.sender] != address(0), "DataHolder: Sender must be property that belongs to a CP!");
        require(msg.sender == prop, "DataHolder: Only property can unfreeze itself!");
        _propertyFrozen[prop] = false;
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

    function isWalletWhitelisted(address wallet) public view returns (bool) {
        return DataStorageProxyHelpers(_users).isWhitelisted(wallet);
    }

    function canTransferPropTokensTo(address wallet, address property) public view returns (bool) {
        if (wallet == address(0)) {
            return false;
        }
        if (!isWalletWhitelisted(wallet)) {
            return false;
        }
        // get CP
        address cp = _propertyToCP[property];
        bytes32 cpBytes = DataStorageProxyHelpers(_certifiedPartners).getCPBytesFromWallet(cp);
        bytes32 userBytes = DataStorageProxyHelpers(_users).getUserBytesFromWallet(wallet);
        // Check if cp has restriction
        if (DataStorageProxyHelpers(_certifiedPartners).hasCertifiedPartnerRestriction(cp)) {
            // Check if user is whitelabeled
            if (DataStorageProxyHelpers(_certifiedPartners).isUserWhitelabeled(cpBytes, userBytes)) {
                return true;
            }
            return false;
        }
        return true;
    }
}