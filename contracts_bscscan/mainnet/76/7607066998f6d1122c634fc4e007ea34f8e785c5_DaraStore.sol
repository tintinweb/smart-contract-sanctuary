/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract DaraStore {

    address private _owner;
    mapping(uint => string) Database;
    uint public totalEntries = 0;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: Caller is not the owner");
        _;
    }

    function set(string memory valueHash) public onlyOwner returns (uint) {
        Database[totalEntries] = valueHash;
        totalEntries++;
        return totalEntries;
    }

    function get(uint key) public view returns (string memory){
        return Database[key];
    }
}