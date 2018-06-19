pragma solidity ^0.4.15;


contract Contributor {

    //=================Variables================
    bool isInitiated = false;

    //Addresses
    address creatorAddress;

    address contributorAddress;

    address marketplaceAddress;

    //State
    string name;

    uint creationTime;

    bool isRepudiated = false;

    //Publications
    enum ExtensionType {MODULE, THEME}
    struct Extension {
    string name;
    string version;
    ExtensionType extType;
    string moduleKey;
    }

    mapping (string => Extension) private publications;

    //Modifiers
    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

    //Events
    event newExtensionPublished (string _name, string _hash, string _version, ExtensionType _type, string _moduleKey);

    //=================Transactions================
    //Constructor
    function Contributor(string _name, address _contributorAddress, address _marketplaceAddress) {
        creatorAddress = msg.sender;
        contributorAddress = _contributorAddress;
        marketplaceAddress = _marketplaceAddress;
        creationTime = now;
        name = _name;
        isInitiated = true;
    }

    //Publish a new extension in structure
    function publishExtension(string _hash, string _name, string _version, ExtensionType _type, string _moduleKey)
    onlyBy(creatorAddress) {
        publications[_hash] = Extension(_name, _version, _type, _moduleKey);
        newExtensionPublished(_name, _hash, _version, _type, _moduleKey);
    }

    //=================Calls================
    //Check if the contract is initialised
    function getInitiated() constant returns (bool) {
        return isInitiated;
    }

    //Return basic information about the contract
    function getInfos() constant returns (address, string, uint) {
        return (creatorAddress, name, creationTime);
    }

    //Return information about a module
    function getExtensionPublication(string _hash) constant returns (string, string, ExtensionType) {
        return (publications[_hash].name, publications[_hash].version, publications[_hash].extType);
    }

    function haveExtension(string _hash) constant returns (bool) {
        bool result = true;

        if (bytes(publications[_hash].name).length == 0) {
            result = false;
        }
        return result;
    }
}