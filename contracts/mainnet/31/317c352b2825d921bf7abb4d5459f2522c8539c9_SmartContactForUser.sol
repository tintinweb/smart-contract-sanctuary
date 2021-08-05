/**
 *Submitted for verification at Etherscan.io on 2020-02-02
*/

pragma solidity ^0.5.16;
contract SmartContactForUser {
    event PersonRemoval(address indexed removed, address indexed attachedTo, Role indexed role);
    event HolderAdd(address indexed added);
    mapping(address => mapping(address => uint256)) _allowed; //mapping of accounts allowed to withdraw from a given account and their balances
    address[] _holders; //all token holders
    address _owner;
    enum Role {Holder, Appointee, Owner}
    constructor() public payable {
        _holders.push(msg.sender);
        _owner = msg.sender;
    }
    function holderExist(address accountToCheck) public view returns (bool){
        for(uint i = 0; i<_holders.length; i++){
            if(_holders[i] == accountToCheck)
                return true;
        }
        return false;
    }
    function signContact(address accountToAdd) public returns (bool){
        require(!holderExist(accountToAdd), "Contact already exists.");
        require(checkHolderPermission(msg.sender), "Not authorized");
        _holders.push(accountToAdd);
        assert(holderExist(accountToAdd));
        emit HolderAdd(accountToAdd);
        return true;
    }
    /*Only contract's owner can remove a holder.
    */
    function removeContact(address toRemove) public returns (bool){
        require(checkOwnerPermission(msg.sender), "Not authorized.");
        require(holderExist(toRemove), "Contact not exist.");
        uint index;
        for(uint i = 0; i<_holders.length; i++){
            if(_holders[i] == toRemove){
                index = i;
            }
        }
        uint256 arrlen = _holders.length;
        delete _holders[index];
        _holders[index] = _holders[arrlen - 1];
        _holders.length--;
        
        emit PersonRemoval(toRemove, address(0), Role.Holder);
        return true;
    }
    function checkHolderPermission(address toCheck) public view returns (bool){
        return (holderExist(toCheck));
        return true;
    }
    function checkOwnerPermission(address toCheck) public view returns (bool){
        return (toCheck == _owner);
    }
    function checkAppointeePermission(address toCheck, address mapToOwner) public view returns (bool){
        return (_allowed[mapToOwner][toCheck] != 0);
    }
    function getOwner() public view returns(address owner){
        return _owner;
    }
}