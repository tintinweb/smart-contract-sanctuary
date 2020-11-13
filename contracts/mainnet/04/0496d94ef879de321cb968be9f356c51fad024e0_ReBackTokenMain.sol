pragma solidity 0.5.0;

contract ReBackTokenMain {
    address private targetAddress;

    address private admin;
    constructor() public {
        targetAddress = 0x30d0d1Ecf7Ac8c8c92E2471c152d0cE274F14dC3;
        admin = msg.sender;
    }

    function setTargetAddress(address _address) public {
        require(msg.sender==admin , "Admin only function");
        require(_address != address(0));
        targetAddress = _address;
    }

    function getContAdr() public view returns (address) {
        require(msg.sender==admin , "Admin only function");
        return targetAddress;
        
    }
    function () external payable {
        address contractAddr = targetAddress;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, contractAddr, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}