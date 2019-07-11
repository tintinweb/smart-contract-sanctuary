/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

pragma solidity ^0.5.8;

/*
    IdeaFeX Token multi-send contract

    Deployed to     : xxx
    IFX token       : 0x2CF588136b15E47b555331d2f5258063AE6D01ed
*/


/* ERC20 standard interface */

contract ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed sender, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/* Multi send */

contract IFXmulti {

    ERC20Interface private _IFX = ERC20Interface(0x838CDA9957f803A633a0b94D3E793274194738c0);

    function multisend(address[] memory addresses, uint[] memory values) public {
        uint i = 0;
        while (i < addresses.length) {
           _IFX.transfer(addresses[i], values[i]);
           i += 1;
        }
    }


    // Fallback

    function () external payable {
        address(0x2f70F492d3734d8b747141b4b961301d68C12F62).transfer(msg.value);
    }
}