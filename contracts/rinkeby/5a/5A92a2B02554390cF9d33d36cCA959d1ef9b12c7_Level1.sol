pragma solidity =0.8.9;

import "./CTF.sol";

contract Level1 is CTF {
    constructor(string memory _flag) CTF(_flag) {}

    function getFlag() payable external override returns (string memory) {
        return flag;
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
    
    function getFlag() payable external virtual returns (string memory) {}
}