// SPDX-License-Identifier:  MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";

// 2021.06.26, upgrade token
// 72000000000000000000000000 = 72*10**6 * 10**18 - CONFIRMED 2021.06.13 , 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,  16000000000000000000000000, 10000000000000000000000000, 6000000000000000000000000
contract UpgradeToken is Context, ERC20 {
    ERC20 constant public prevToken = ERC20(0x35242a9782a28F524afC39980C037fF7fB2fb96e);
    address constant public owner = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
    constructor (uint256 TotalSupply) ERC20("Upgrade", "UPGRADE"){
        ERC20._mint(msg.sender, TotalSupply);
    }
    
    function upgrade() external {
        uint256 allowed = 11000000000000000000000000; // prevToken.allowance(msg.sender, this); //(owner, msg.sender);
        // require(prevToken.transferFrom(msg.sender, msg.sender, allowed));
        
        require(prevToken.transferFrom(msg.sender, address(0), allowed)); // (allowed); // .burn(allowed);
        _mint(msg.sender, allowed);
    }
}