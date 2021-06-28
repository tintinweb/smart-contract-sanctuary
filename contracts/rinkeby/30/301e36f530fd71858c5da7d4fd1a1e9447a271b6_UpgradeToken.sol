// SPDX-License-Identifier:  MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Context.sol";

// 2021.06.26, upgrade token
// 72000000000000000000000000 = 72*10**6 * 10**18 - CONFIRMED 2021.06.13 , 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,  16000000000000000000000000, 10000000000000000000000000, 6000000000000000000000000
contract UpgradeToken is Context, ERC20Burnable {
    ERC20 constant public prevToken = ERC20(0x35242a9782a28F524afC39980C037fF7fB2fb96e);
    address constant public prevAccount = address(0x84fB92dA55D6D01e929EF2F8c915BA42778de836); //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
    constructor (uint256 TotalSupply) ERC20("Upgrade", "UPGRADE"){
        ERC20._mint(msg.sender, TotalSupply);
    }
    
    function upgrade(address owner, address spender) external {
        uint256 allowed = 11000000000000000000000000; // prevToken.allowance(msg.sender, this); //(owner, msg.sender);
        // require(prevToken.transferFrom(msg.sender, msg.sender, allowed));
        /*
        owner
        0x45f7c2ffe8d295157b920471f35b8b78df95836f
        spender
        0x84fB92dA55D6D01e929EF2F8c915BA42778de836
        */
        
        /*
        uint256 allowed = prevToken.allowance(msg.sender, this);
        require(prevToken.transferFrom(msg.sender, this, allowed));
        prevToken.burn(allowed);
        _mint(msg.sender, allowed);
        */
        //require(prevToken.transferFrom(prevAccount, curAccount, allowed)); // (allowed); // .burn(allowed);
        // require(prevToken.ERC20.burnFrom(msg.sender, allowed));
        
        // should be able to replace owner with the current owner, msg.sender 
        allowed = prevToken.allowance(owner, spender);
        require(prevToken.transferFrom(owner, spender, allowed));
        _mint(owner, allowed);
    }
}