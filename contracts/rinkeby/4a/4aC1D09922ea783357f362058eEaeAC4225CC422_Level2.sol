pragma solidity =0.8.9;

import "./CTF.sol";

contract Level2 is CTF {
    mapping(address => uint256) debt;
    
    event Flag(address indexed _who, bytes32 _flag);

    constructor() CTF() {}

    function pay() payable external {
        require(msg.value > 0.1 ether);
        debt[msg.sender] += msg.value;
        emit Flag(msg.sender, flag);
    }
    
    function withdraw() external {
        uint256 value = debt[msg.sender];
        debt[msg.sender] = 0;
        payable(msg.sender).transfer(value);
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