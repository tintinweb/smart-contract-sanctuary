pragma solidity ^0.4.24;


contract DeviceLink {

    // Key Value list for device public key and addresses
    mapping (address => string)  addrToDevice;
    mapping (string => address)  deviceToAddr;

    function getPublicKey(address _addr) public view returns (string) {
        return addrToDevice[_addr];
    }

    function getAddress(string _publickey) public view returns (address){
        return deviceToAddr[_publickey];
    }

    function link(string _publickey) public  {
        addrToDevice[msg.sender] = _publickey;
        deviceToAddr[_publickey] = msg.sender;
    }

}