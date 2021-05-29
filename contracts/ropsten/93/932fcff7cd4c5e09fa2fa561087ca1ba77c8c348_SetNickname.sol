/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity ^0.8.0;

abstract contract CaptureTheEther {
    function setNickname(bytes32 nickname) public virtual;
}

contract SetNickname {
    address deployedAddr = 0xD9603e6c429680AC28a545eB2e0FFe868011FFfA;
    CaptureTheEther cteContract = CaptureTheEther(deployedAddr);
    
    function startSetNickname(string calldata _nickname) external returns (bytes32 bytesNickname) {
        bytes32 bytesNickname = stringToBytes32(_nickname);
        // cteContract.setNickname(bytesNickname);
    }
    
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
}