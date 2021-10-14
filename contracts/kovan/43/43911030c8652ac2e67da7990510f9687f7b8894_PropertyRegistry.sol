/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";

interface PropertyRegistryHelpers {
    function hasSystemAdminRights(address sender) external view returns (bool);

    function getCPOfProperty(address prop) external view returns (address);

    function getSpecialWallet() external view returns (address);

    function changeTokenNameAndSymbol(string memory name, string memory symbol) external;

    function isCPAdminOfProperty(address user, address property) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function canEditProperty(address wallet, address property) external view returns (bool);
}

/// @title Property Registry
contract PropertyRegistry is Ownable {
    using SafeMath for uint256;
    struct Property {
        string kadastralMunicipality;
        string parcelNumber;
        string ID;
        uint64 buildingPart;
        string propertyType;
    }

    struct BasicInfo {
        string propertyValuationCurrency;
        string streetLocation;
        string geoLocation;
        uint256 propertyValuation;
        uint256 tokenValuation;
    }

    uint256 private constant BSPT_CAP = 100000 * (10 ** 10);

    address private _dataProxy;
    address private _exchange;

    mapping(address => string) private _IPFSs;
    mapping(address => mapping(uint64 => Property)) private _properties;
    mapping(address => uint64) private _numberOfProperties;
    mapping(address => BasicInfo) private _basicInfos;

    event PropertyBasicInfoChanged(address indexed property, string streetLocation, string geoLocation, string propertyValuationCurrency, uint256 propertyValuation);
    event PropertyInfoAdded(address indexed property, string propertyType, string kadastralMunicipality, string parcelNumber, string ID, uint64 buildingPart);
    event PropertyInfoChanged(address indexed property, uint64 idProp, string propertyType, string kadastralMunicipality, string parcelNumber, string ID, uint64 buildingPart);
    event IPFSHashChanged(address indexed property, string newIPFSHash);
    event NameAndSymbolChange(address indexed property, string newName, string newSymbol);
    event PropertyValuationChange(address indexed property, uint256 newValuationProperty);
    event TokenValuationChange(address indexed property, uint256 newTokenValuation);

    modifier onlyBlocksquareOrSpecialWallet {
        require(PropertyRegistryHelpers(_dataProxy).hasSystemAdminRights(msg.sender) || PropertyRegistryHelpers(_dataProxy).getSpecialWallet() == _msgSender(), "PropertiesFactory: You need to have system admin rights or special wallet!");
        _;
    }

    modifier onlyPropertyManager(address property) {
        require(PropertyRegistryHelpers(_dataProxy).canEditProperty(_msgSender(), property) || PropertyRegistryHelpers(_dataProxy).getSpecialWallet() == _msgSender(), "PropertiesFactory: You need to have permission to edit this property!");
        _;
    }

    constructor(address dataProxy) public {
        _dataProxy = dataProxy;
    }

    function setDataProxy(address dataProxy) public onlyOwner {
        _dataProxy = dataProxy;
    }

    function setExchange(address exchange) public onlyOwner {
        _exchange = exchange;
    }

    function _editProperty(address property, uint64 id, string memory propertyType, string memory kadastralMunicipality, string memory parcelNumber, string memory ID, uint64 buildingPart) private {
        Property memory prop = Property(kadastralMunicipality, parcelNumber, ID, buildingPart, propertyType);
        _properties[property][id] = prop;
    }

    // @notice changes the token name and symbol of property token
    // @param property Contract address of property
    // @param name New name for token
    // @param symbol New symbol for token
    function changeTokenNameAndSymbol(address property, string memory name, string memory symbol) public onlyBlocksquareOrSpecialWallet {
        PropertyRegistryHelpers(property).changeTokenNameAndSymbol(name, symbol);
        emit NameAndSymbolChange(property, name, symbol);
    }

    /// @notice set IPFS hash to corporate resolution for property
    /// @param property Contract address of property
    /// @param newIPFSHash IPFS hash of corporate resolution
    function setIPFS(address property, string memory newIPFSHash) public onlyBlocksquareOrSpecialWallet {
        _IPFSs[property] = newIPFSHash;
        emit IPFSHashChanged(property, newIPFSHash);
    }

    /// @notice sets basic information about property
    /// @param property Contract address of property
    /// @param streetLocation Location where property is located
    /// @param geoLocation Longitude and Latitude of property location (inputed like ##.########,##.#######)
    /// @param propertyValuationCurrency Currency for evaluating property (DAI for example)
    /// @param propertyValuation Valuation of property in propertyValuationCurrency
    /// @param tokenValuation Valuation of property token in propertyValuationCurrency (price by which the tokens were sold)
    function editBasicInfo(address property, string memory streetLocation, string memory geoLocation, string memory propertyValuationCurrency, uint256 propertyValuation, uint256 tokenValuation) public onlyBlocksquareOrSpecialWallet {
        BasicInfo memory basicInfo = BasicInfo(propertyValuationCurrency, streetLocation, geoLocation, propertyValuation, tokenValuation);
        _basicInfos[property] = basicInfo;
        emit PropertyBasicInfoChanged(property, streetLocation, geoLocation, propertyValuationCurrency, propertyValuation);
    }

    /// @notice changes the valuation of property
    /// @param property Contract address of property
    /// @param propertyValuation New valuation of property
    function changePropertyValuation(address property, uint256 propertyValuation) public {
        require(PropertyRegistryHelpers(_dataProxy).canEditProperty(_msgSender(), property) || _msgSender() == PropertyRegistryHelpers(_dataProxy).getSpecialWallet(), "PropertyRegistry: You don't have permission");
        _basicInfos[property].propertyValuation = propertyValuation;
        emit PropertyValuationChange(property, propertyValuation);
    }

    /// @notice changes the valuation of property token
    /// @param property Contract address of property
    /// @param tokenValuation New valuation of property token
    function changeTokenValuation(address property, uint256 tokenValuation) public {
        require(PropertyRegistryHelpers(_dataProxy).hasSystemAdminRights(msg.sender) || _msgSender() == PropertyRegistryHelpers(_dataProxy).getSpecialWallet() || msg.sender == _exchange, "PropertyRegistry: You don't have permission");
        _basicInfos[property].tokenValuation = tokenValuation;
        emit TokenValuationChange(property, tokenValuation);
    }

    /// @notice adds additional information about property
    /// @param property Contract address of property
    /// @param propertyType Type of the property (Office, Leisure, ...)
    /// @param kadastralMunicipality Cadastral municipality (Cadastral community)
    /// @param parcelNumber Parcel number
    /// @param ID Additional ID
    /// @param buildingPart Part of building
    function addPropertyInfo(address property, string memory propertyType, string memory kadastralMunicipality, string memory parcelNumber, string memory ID, uint64 buildingPart) public onlyPropertyManager(property) {
        _editProperty(property, _numberOfProperties[property], propertyType, kadastralMunicipality, parcelNumber, ID, buildingPart);
        _numberOfProperties[property] = _numberOfProperties[property] + 1;
        emit PropertyInfoAdded(property, propertyType, kadastralMunicipality, parcelNumber, ID, buildingPart);
    }

    /// @notice edits additional information about property
    /// @param property Contract address of property
    /// @param idProp Consecutive number of additional information
    /// @param propertyType Type of the property (Office, Leisure, ...)
    /// @param kadastralMunicipality Cadastral municipality (Cadastral community)
    /// @param parcelNumber Parcel number
    /// @param ID Additional ID
    /// @param buildingPart Part of building
    function editPropertyInfo(address property, uint64 idProp, string memory propertyType, string memory kadastralMunicipality, string memory parcelNumber, string memory ID, uint64 buildingPart) public onlyPropertyManager(property) {
        _editProperty(property, idProp, propertyType, kadastralMunicipality, parcelNumber, ID, buildingPart);
        emit PropertyInfoChanged(property, idProp, propertyType, kadastralMunicipality, parcelNumber, ID, buildingPart);
    }

    /// @notice retrieves all the basic information about property
    /// @param property Contract address of property
    function getBasicInfo(address property) public view returns (string memory streetLocation, string memory geoLocation, uint256 propertyValuation, uint256 tokenValuation, string memory propertyValuationCurrency) {
        BasicInfo memory basicInfo = _basicInfos[property];
        return (
        basicInfo.streetLocation,
        basicInfo.geoLocation,
        basicInfo.propertyValuation,
        basicInfo.tokenValuation,
        basicInfo.propertyValuationCurrency
        );
    }

    /// @notice retrieves additional information about property
    /// @param property Contract address of property
    /// @param index Consecutive number of additional information
    function getPropertyInfo(address property, uint64 index) public view returns (string memory propertyType, string memory kadastralMunicipality, string memory parcelNumber, string memory ID, uint64 buildingPart) {
        Property memory properties = _properties[property][index];
        return (
        properties.propertyType,
        properties.kadastralMunicipality,
        properties.parcelNumber,
        properties.ID,
        properties.buildingPart);
    }

    /// @notice retrieves combined valuation of property
    /// @param property Contract address of property
    /// @return combined property and property token valuation of property
    function getValuation(address property) public view returns (uint256) {
        (string memory streetLocation, string memory geoLocation, uint256 propertyValuation, uint256 tokenValuation, string memory propertyValuationCurrency) = getBasicInfo(property);
        uint256 totalSupply = PropertyRegistryHelpers(property).totalSupply().div(10 ** 8);
        uint256 tValuation = tokenValuation.mul(totalSupply);
        uint256 pValuation = propertyValuation.mul(BSPT_CAP.sub(totalSupply));

        return tValuation.add(pValuation).div(BSPT_CAP);
    }

    /// @notice retrieves IPFS hash of corporate resolution
    /// @param property Contract address of property
    /// @return IPFS hash of corporate resolution
    function getIPFS(address property) public view returns (string memory) {
        return _IPFSs[property];
    }

    /// @notice retrieves number of additional information on property
    /// @param property Contract address of property
    /// @return number of additional information on property
    function getNumberOfPropertiesOnPropToken(address property) public view returns (uint64) {
        return _numberOfProperties[property];
    }

    /// @notice retrieves contract address of data proxy contract
    /// @return contract address of data proxy contract
    function getDataProxy() public view returns (address) {
        return _dataProxy;
    }
}