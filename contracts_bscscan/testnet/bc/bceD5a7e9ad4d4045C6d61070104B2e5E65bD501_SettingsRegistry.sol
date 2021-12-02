/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-06-04
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/SettingsRegistry.sol

pragma solidity >=0.4.24 <0.5.0;

////// contracts/interfaces/IAuthority.sol
/* pragma solidity ^0.4.24; */

contract IAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

////// contracts/DSAuth.sol
/* pragma solidity ^0.4.24; */

/* import './interfaces/IAuthority.sol'; */

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

/**
 * @title DSAuth
 * @dev The DSAuth contract is reference implement of https://github.com/dapphub/ds-auth
 * But in the isAuthorized method, the src from address(this) is remove for safty concern.
 */
contract DSAuth is DSAuthEvents {
    IAuthority   public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(IAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == owner) {
            return true;
        } else if (authority == IAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

////// contracts/interfaces/ISettingsRegistry.sol
/* pragma solidity ^0.4.24; */

contract ISettingsRegistry {
    enum SettingsValueTypes { NONE, UINT, STRING, ADDRESS, BYTES, BOOL, INT }

    function uintOf(bytes32 _propertyName) public view returns (uint256);

    function stringOf(bytes32 _propertyName) public view returns (string);

    function addressOf(bytes32 _propertyName) public view returns (address);

    function bytesOf(bytes32 _propertyName) public view returns (bytes);

    function boolOf(bytes32 _propertyName) public view returns (bool);

    function intOf(bytes32 _propertyName) public view returns (int);

    function setUintProperty(bytes32 _propertyName, uint _value) public;

    function setStringProperty(bytes32 _propertyName, string _value) public;

    function setAddressProperty(bytes32 _propertyName, address _value) public;

    function setBytesProperty(bytes32 _propertyName, bytes _value) public;

    function setBoolProperty(bytes32 _propertyName, bool _value) public;

    function setIntProperty(bytes32 _propertyName, int _value) public;

    function getValueTypeOf(bytes32 _propertyName) public view returns (uint /* SettingsValueTypes */ );

    event ChangeProperty(bytes32 indexed _propertyName, uint256 _type);
}

////// contracts/SettingsRegistry.sol
/* pragma solidity ^0.4.24; */

/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./DSAuth.sol"; */

/**
 * @title SettingsRegistry
 * @dev This contract holds all the settings for updating and querying.
 */
contract SettingsRegistry is ISettingsRegistry, DSAuth {

    mapping(bytes32 => uint256) public uintProperties;
    mapping(bytes32 => string) public stringProperties;
    mapping(bytes32 => address) public addressProperties;
    mapping(bytes32 => bytes) public bytesProperties;
    mapping(bytes32 => bool) public boolProperties;
    mapping(bytes32 => int256) public intProperties;

    mapping(bytes32 => SettingsValueTypes) public valueTypes;

    function uintOf(bytes32 _propertyName) public view returns (uint256) {
        require(valueTypes[_propertyName] == SettingsValueTypes.UINT, "Property type does not match.");
        return uintProperties[_propertyName];
    }

    function stringOf(bytes32 _propertyName) public view returns (string) {
        require(valueTypes[_propertyName] == SettingsValueTypes.STRING, "Property type does not match.");
        return stringProperties[_propertyName];
    }

    function addressOf(bytes32 _propertyName) public view returns (address) {
        require(valueTypes[_propertyName] == SettingsValueTypes.ADDRESS, "Property type does not match.");
        return addressProperties[_propertyName];
    }

    function bytesOf(bytes32 _propertyName) public view returns (bytes) {
        require(valueTypes[_propertyName] == SettingsValueTypes.BYTES, "Property type does not match.");
        return bytesProperties[_propertyName];
    }

    function boolOf(bytes32 _propertyName) public view returns (bool) {
        require(valueTypes[_propertyName] == SettingsValueTypes.BOOL, "Property type does not match.");
        return boolProperties[_propertyName];
    }

    function intOf(bytes32 _propertyName) public view returns (int) {
        require(valueTypes[_propertyName] == SettingsValueTypes.INT, "Property type does not match.");
        return intProperties[_propertyName];
    }

    function setUintProperty(bytes32 _propertyName, uint _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.UINT, "Property type does not match.");
        uintProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.UINT;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.UINT));
    }

    function setStringProperty(bytes32 _propertyName, string _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.STRING, "Property type does not match.");
        stringProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.STRING;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.STRING));
    }

    function setAddressProperty(bytes32 _propertyName, address _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.ADDRESS, "Property type does not match.");

        addressProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.ADDRESS;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.ADDRESS));
    }

    function setBytesProperty(bytes32 _propertyName, bytes _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.BYTES, "Property type does not match.");

        bytesProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.BYTES;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.BYTES));
    }

    function setBoolProperty(bytes32 _propertyName, bool _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.BOOL, "Property type does not match.");

        boolProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.BOOL;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.BOOL));
    }

    function setIntProperty(bytes32 _propertyName, int _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.INT, "Property type does not match.");

        intProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.INT;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.INT));
    }

    function getValueTypeOf(bytes32 _propertyName) public view returns (uint256 /* SettingsValueTypes */ ) {
        return uint256(valueTypes[_propertyName]);
    }

}