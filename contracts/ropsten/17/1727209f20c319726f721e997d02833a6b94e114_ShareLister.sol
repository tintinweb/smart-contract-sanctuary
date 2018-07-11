pragma solidity ^0.4.24;
contract ShareLister {
    address public owner;
    address[] addressLists;
    mapping(address => uint256) valueLists;
    uint public totalAddress;
    event ShareAdded(address indexed _newAddress, uint256 _newValue);
    event ShareRemoved(address indexed _address);
    event ShareValueChanged(address indexed _address, uint256 _lastValue, uint256 _newValue);
    event ShareAddressChanged(address indexed _lastAddress, address indexed _newAddress);
    event OwnerChanged(address indexed _lastOwner, address indexed _newOwner);
    constructor () public {
        owner = msg.sender;
        addressLists.push(msg.sender);
        valueLists[msg.sender] = 1 szabo;
        totalAddress = 1;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public admin returns(bool success) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        emit OwnerChanged(msg.sender, newOwner);
        return true;
    }
    function getIndex(address checkAddress) public view returns(uint) {
        uint z = 0;
        uint zX = totalAddress;
        while (z < totalAddress) {
            zX = z;
            if (addressLists[z] == checkAddress) {
                break;
            }
            z++;
        }
        return zX + 1;
    }
    function getAddress(uint x) public view returns(address) {
        if (x < 1) return address(0);
        if (x >= totalAddress) return address(0);
        uint posIndex = x - 1;
        return addressLists[posIndex];
    }
    function getShare(address checkAddress) public view returns(uint256) {
        return valueLists[checkAddress];
    }
    function newShare(address newAddress, uint256 newValue) public admin returns(bool success) {
        require(getIndex(newAddress) > totalAddress);
        addressLists.push(newAddress);
        valueLists[newAddress] = newValue;
        totalAddress += 1;
        emit ShareAdded(newAddress, newValue);
        return true;
    }
    function updateShareValue(address existsAddress, uint256 newValue) public admin returns(bool success) {
        uint shareId = getIndex(existsAddress);
        require(shareId >= 1 && shareId <= totalAddress);
        uint256 shareValue = valueLists[existsAddress];
        valueLists[existsAddress] = newValue;
        emit ShareValueChanged(existsAddress, shareValue, newValue);
        return true;
    }
    function updateShareAddress(address lastAddress, address newAddress) public admin returns(bool success) {
        uint shareId = getIndex(lastAddress);
        require(shareId >= 1 && shareId <= totalAddress);
        addressLists[shareId - 1] = newAddress;
        valueLists[newAddress] = valueLists[lastAddress];
        valueLists[lastAddress] -= valueLists[newAddress];
        emit ShareAddressChanged(lastAddress, newAddress);
        return true;
    }
    function removeShare(address existsAddress) public admin returns(bool success) {
        require(existsAddress != owner);
        uint y = 0;
        address[] memory tempAddress = addressLists;
        delete(addressLists);
        while (y < tempAddress.length) {
            if (tempAddress[y] != existsAddress) addressLists.push(tempAddress[y]);
            y++;
        }
        require(addressLists.length == totalAddress - 1);
        valueLists[existsAddress] = 0;
        totalAddress = addressLists.length;
        delete(tempAddress);
        emit ShareRemoved(existsAddress);
        return true;
    }
    function callSender(address gateAddress, bytes4 ecode) public admin returns(bool success) {
        uint256[] memory amountLists;
        uint v = 0;
        while (v < addressLists.length) {
            amountLists[v] = valueLists[addressLists[v]];
            v++;
        }
        return gateAddress.delegatecall.gas(1000000)(ecode,addressLists,amountLists);
    }
}