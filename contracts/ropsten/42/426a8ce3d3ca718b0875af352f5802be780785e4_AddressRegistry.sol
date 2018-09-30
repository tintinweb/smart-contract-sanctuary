pragma solidity ^0.4.24;

contract AddressRegistry {

    event eSetAddr(string AddrName, address TargetAddr);
    mapping(bytes32 => address) internal addressBook;

    modifier onlyAdmin() {
        require(msg.sender == getAddr("admin"), "Permission Denied");
        _;
    }

    constructor() public {
        addressBook[keccak256("admin")] = msg.sender;
    }

    function setAddr(string AddrName, address Addr) public onlyAdmin {
        addressBook[keccak256(AddrName)] = Addr;
        emit eSetAddr(AddrName, Addr);
    }

    function getAddr(string AddrName) public view returns(address AssignedAddress) {
        address realAddress = addressBook[keccak256(AddrName)];
        require(realAddress != address(0), "Not a valid address.");
        return realAddress;
    }

}