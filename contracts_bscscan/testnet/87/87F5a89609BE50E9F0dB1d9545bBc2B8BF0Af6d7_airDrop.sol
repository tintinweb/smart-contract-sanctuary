pragma solidity ^0.8.9;
//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract airDrop {
    
    address payable public owner;
    IBEP20 public token;

    mapping(address => bool) public isClaimed;
    
    constructor() {
        owner = payable(0x607541193dd9f7D3409f97b587EE3ab3d515C271);
        token = IBEP20(0xd00F344Bff61b29474Dad12BC0257321b3dc640F);
    }
    
    function claimAirDropDGAT(uint256 _amount) public {
        require(!isClaimed[msg.sender],"Already Claimed");
        token.transferFrom(owner, msg.sender, _amount);
        isClaimed[msg.sender] = true;
        
    }
    
    // transfer ownership
    function changeOwner(address payable _newOwner) external {
        owner = _newOwner;
    }

    function changeToken(address _token) external {
        token = IBEP20(_token);
    }
    
}