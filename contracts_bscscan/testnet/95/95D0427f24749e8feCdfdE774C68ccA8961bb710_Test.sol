/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool); 
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function CA() external view returns (address);
}

interface AdminRouter {
    function isManager(address account) external view returns(bool);
    function isContract(address account) external view returns(bool);
    function isSuperManager(address account) external view returns(bool);
}

interface NameRegistry_Interface {
    function Control() external view returns (address);
}

contract Test{
    event logger(address who,address nameregis,address controlleris);
    event logger2(address who,address nameregis,address controlleris,bool access);

    
    address internal Nameregis;

    constructor(address _regis) {
        Nameregis = _regis;
    }

    function tester() public {
        emit logger(msg.sender,Nameregis,NameRegistry_Interface(Nameregis).Control());
    }

    function tester2() public {
        emit logger2(msg.sender,Nameregis,NameRegistry_Interface(Nameregis).Control(),AdminRouter(NameRegistry_Interface(Nameregis).Control()).isContract(msg.sender));
    }
}