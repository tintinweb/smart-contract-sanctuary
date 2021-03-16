pragma solidity >0.6.0 <0.8.0;

/*
  Copyright (c) 2015-2016 Oraclize SRL
  Copyright (c) 2016 Oraclize LTD
*/

contract OraclizeAddrResolver {
    address public addr;

    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address newowner) external {
        require(msg.sender == owner, "You are not owner of this contract");
        owner = newowner;
    }

    function getAddress() public view returns (address oaddr) {
        return addr;
    }

    function setAddr(address newaddr) external {
        require(
            msg.sender == owner,
            "You are not owner of this contract to change address"
        );
        addr = newaddr;
    }
}