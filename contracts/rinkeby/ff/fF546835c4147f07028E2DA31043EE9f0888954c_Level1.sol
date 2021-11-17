pragma solidity =0.8.9;

import "./CTF.sol";

contract Level1 is CTF {
    constructor() CTF() {}

    function getFlag() external view returns (bytes32) {
        return flag;
    }
}

pragma solidity =0.8.9;

contract CTF {
    address internal owner;
    bytes32 internal flag;
    
    constructor() {
        owner = msg.sender;
        flag = keccak256(abi.encodePacked(block.timestamp));
    }
    
    function bye() external {
        require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }
}