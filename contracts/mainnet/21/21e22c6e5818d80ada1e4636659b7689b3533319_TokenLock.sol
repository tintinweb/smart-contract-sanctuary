// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenLock {
    address public lockedToken;
    address public withdrawAddress = 0x66C0ca89b1246612Ee1E4454B779E2dBEd55B876;
    uint public releaseTime = 1605125871 + 14 days;
    
    constructor() public {
        lockedToken = 0xE1c94F1dF9f1A06252da006C623E07982787ceE4;
        
    }

    function lockedTokens() public view returns (uint256) {
        IERC20 token = IERC20(lockedToken);
        return token.balanceOf(address(this));
    }

    function withdrawTokens()  public  {
        require(block.timestamp>releaseTime);
        require(msg.sender == withdrawAddress);
        IERC20 token = IERC20(lockedToken);
        uint256 balancetransfer =  lockedTokens();
        
        token.transfer(address(msg.sender), balancetransfer);
    }
    
}