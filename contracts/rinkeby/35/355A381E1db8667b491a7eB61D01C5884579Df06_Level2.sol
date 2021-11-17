pragma solidity =0.8.9;

import "./CTF.sol";

contract Level2 is CTF {
    mapping(address => uint256) debt;
    
    constructor(string memory _flag) CTF(_flag) {}

    function getFlag() external view override returns (string memory) {
        require(debt[msg.sender] > 0.1 ether);
        return flag;
    }

    function pay() payable external {
        require(msg.value > 0.1 ether);
        debt[msg.sender] += msg.value;
    }
    
    function withdraw() external {
        uint256 value = debt[msg.sender];
        debt[msg.sender] = 0;
        payable(msg.sender).transfer(value);
    }
}

pragma solidity =0.8.9;

abstract contract CTF {
    address internal owner;
    string internal flag;
    
    constructor(string memory _flag) {
        owner = msg.sender;
        flag = _flag;
    }
    
    function bye() external {
        require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }
    
    function getFlag() external view virtual returns (string memory) {}
}