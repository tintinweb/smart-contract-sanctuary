// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./ERC20.sol";
contract wooInu is ERC20("Woo Inu", "WOOINU"){
    constructor(){
        _mint(_msgSender(), 210000e18);
    }
}