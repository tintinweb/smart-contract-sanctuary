pragma solidity ^0.4.21;

/* ********************************************************** */

library Util {

    struct Object {
        bool isObject;
        bool isActive;
        bool isRejected;
        uint index;
        bytes32 badge;
    }

    struct List {
        mapping(address => Object) registry;
        uint length;
    }

    function add(List storage list, address _addr, bytes32 _badge) internal {
        list.registry[_addr].isObject = true;
        list.registry[_addr].index = list.length;
        list.registry[_addr].badge = _badge;
        list.length++;
    }

    function remove(List storage list, address _addr) internal {
        list.registry[_addr].isObject = false;
    }
    /* ********************************************************** */

    function activate(List storage list, address _addr) internal {
        list.registry[_addr].isActive = true;
    }

    function deactivate(List storage list, address _addr) internal {
        list.registry[_addr].isActive = false;
    }

    /* ********************************************************** */

    function accept(List storage list, address _addr) internal {
        list.registry[_addr].isRejected = false;
    }

    function reject(List storage list, address _addr) internal {
        list.registry[_addr].isRejected = true;
    }

    /* ********************************************************** */

    function isObject(List storage list, address _addr) view internal returns (bool) {
        return list.registry[_addr].isObject;
    }

    function isActive(List storage list, address _addr) view internal returns (bool) {
        return list.registry[_addr].isActive;
    }

    function isRejected(List storage list, address _addr) view internal returns (bool) {
        return list.registry[_addr].isRejected;
    }

    function indexOf(List storage list, address _addr) view internal returns (uint) {
        return list.registry[_addr].index;
    }

    function getBadge(List storage list, address _addr) view internal returns (bytes32) {
        return list.registry[_addr].badge;
    }

    function length(List storage list) view internal returns (uint) {
        return list.length;
    }
}

/* ********************************************************** */

contract CanYaDao {

    bytes32 private constant BADGE_ADMIN = "Admin";
    bytes32 private constant BADGE_MOD = "Mod";
    bytes32 public currentBadge = "Pioneer";

    Util.List private _admins;
    Util.List private _mods;
    Util.List private _providers;

    /* ********************************************************** */

    modifier onlyAdmins() {
        require(Util.isObject(_admins, msg.sender) == true);
        _;
    }

    modifier onlyMods() {
        require(Util.isObject(_mods, msg.sender) == true);
        _;
    }

    /* ********************************************************** */

    event onAdminAdded(address _addr);
    event onAdminRemoved(address _addr);

    event onModAdded(address _addr);
    event onModRemoved(address _addr);

    event onProviderAdded(address _addr);
    event onProviderRemoved(address _addr);

    event onProviderActivated(address _addr);
    event onProviderDeactivated(address _addr);

    event onProviderAccepted(address _addr);
    event onProviderRejected(address _addr);

    /* ********************************************************** */

    function CanYaDao() public {
        Util.add(_admins, msg.sender, BADGE_ADMIN);
        Util.add(_mods, msg.sender, BADGE_ADMIN);
    }

    /* ********************************************************** */

    function addAdmin(address _addr) onlyAdmins public {
        if ( Util.isObject(_admins, _addr) == false ) {
            Util.add(_admins, _addr, BADGE_ADMIN);
            emit onAdminAdded(_addr);
            addMod(_addr);
        }
    }

    function removeAdmin(address _addr) onlyAdmins public {
        if ( Util.isObject(_admins, _addr) == true ) {
            Util.remove(_admins, _addr);
            emit onAdminRemoved(_addr);
            removeMod(_addr);
        }
    }

    function isAdmin(address _addr) public view returns (bool) {
        return Util.isObject(_admins, _addr);
    }

    /* ********************************************************** */

    function addMod(address _addr) onlyAdmins public {
        if ( Util.isObject(_mods, _addr) == false ) {
            Util.add(_mods, _addr, BADGE_ADMIN);
            emit onModAdded(_addr);
        }
    }

    function removeMod(address _addr) onlyAdmins public {
        if ( Util.isObject(_mods, _addr) == true ) {
            Util.remove(_mods, _addr);
            emit onModRemoved(_addr);
        }
    }

    function isMod(address _addr) public view returns (bool) {
        return Util.isObject(_mods, _addr);
    }

    /* ********************************************************** */

    function addProvider(address _addr) onlyMods public {
        if ( Util.isObject(_providers, _addr) == true ) revert();
        Util.add(_providers, _addr, currentBadge);
        emit onProviderAdded(_addr);
    }

    function removeProvider(address _addr) onlyMods public {
        if ( Util.isObject(_providers, _addr) == false ) revert();
        Util.remove(_providers, _addr);
        emit onProviderRemoved(_addr);
    }

    function activateProvider(address _addr) onlyMods public {
        if ( Util.isActive(_providers, _addr) == true ) revert(); 
        Util.activate(_providers, _addr);
        emit onProviderActivated(_addr);
    }

    function deactivateProvider(address _addr) onlyMods public {
        if ( Util.isActive(_providers, _addr) == false ) revert(); 
        Util.deactivate(_providers, _addr);
        emit onProviderDeactivated(_addr);
    }

    function acceptProvider(address _addr) onlyMods public {
        if ( Util.isRejected(_providers, _addr) == false ) revert(); 
        Util.accept(_providers, _addr);
        emit onProviderAccepted(_addr);
    }

    function rejectProvider(address _addr) onlyMods public {
        if ( Util.isRejected(_providers, _addr) == true ) revert(); 
        Util.reject(_providers, _addr);
        emit onProviderRejected(_addr);
    }

    function isProvider(address _addr) public view returns (bool) {
        return Util.isObject(_providers, _addr);
    }

    function isActive(address _addr) public view returns (bool) {
        return Util.isActive(_providers, _addr);
    }

    function isRejected(address _addr) public view returns (bool) {
        return Util.isRejected(_providers, _addr);
    }

    function indexOfProvider(address _addr) public view returns (uint) {
        return Util.indexOf(_providers, _addr);
    }

    function getProviderBadge(address _addr) public view returns (bytes32) {
        return Util.getBadge(_providers, _addr);
    }

    function sizeOfProviders() public view returns (uint) {
        return Util.length(_providers);
    }

    /* ********************************************************** */

    function setCurrentBadge(bytes32 _badge) onlyAdmins public {
        currentBadge = _badge;
    }

    function () public payable {
        revert();
    }
}