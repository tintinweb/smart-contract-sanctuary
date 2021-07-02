/**
 * 
 * 

 /$$$$$$$$ /$$$$$$  /$$    /$$  /$$$$$$  /$$$$$$$        /$$   /$$  /$$$$$$  /$$$$$$$  /$$$$$$$$
| $$_____//$$__  $$| $$   | $$ /$$__  $$| $$__  $$      | $$  | $$ /$$__  $$| $$__  $$| $$_____/
| $$     | $$  \ $$| $$   | $$| $$  \ $$| $$  \ $$      | $$  | $$| $$  \__/| $$  \ $$| $$      
| $$$$$  | $$$$$$$$|  $$ / $$/| $$  | $$| $$$$$$$/      | $$  | $$|  $$$$$$ | $$  | $$| $$$$$   
| $$__/  | $$__  $$ \  $$ $$/ | $$  | $$| $$__  $$      | $$  | $$ \____  $$| $$  | $$| $$__/   
| $$     | $$  | $$  \  $$$/  | $$  | $$| $$  \ $$      | $$  | $$ /$$  \ $$| $$  | $$| $$      
| $$     | $$  | $$   \  $/   |  $$$$$$/| $$  | $$      |  $$$$$$/|  $$$$$$/| $$$$$$$/| $$      
|__/     |__/  |__/    \_/     \______/ |__/  |__/       \______/  \______/ |_______/ |__/      
                                        εɖɖίε રεĢĢίε ĵΘε
 *
 */


// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {ERC20} from "./ERC20.sol";
import {FavorCurrency} from "./FavorCurrency.sol";
import {ClaimableOwnable} from "./ClaimableOwnable.sol";

/**
 * @title FavorUSD
 * @dev This is the top-level ERC20 contract, but most of the interesting functionality is
 * inherited - see the documentation on the corresponding contracts.
 */
contract FavorUSD is FavorCurrency {
    
    uint8 constant DECIMALS = 18;
    uint8 constant ROUNDING = 2;

    function initialize() external {
        require(!initialized);
        owner = msg.sender;
        initialized = true;
    }

    function decimals() public override pure returns (uint8) {
        return DECIMALS;
    }

    function rounding() public pure returns (uint8) {
        return ROUNDING;
    }

    function name() public override pure returns (string memory) {
        return "FavorUSD";
    }

    function symbol() public override pure returns (string memory) {
        return "USDF";
    }
    
    function donate() public payable {}


 
    function burnFrom(address _to, uint256 _amount) external onlyOwner() returns (bool) {
        transferFrom(_to, msg.sender, _amount);
        _burn(msg.sender, _amount);
        return true;
    }
    
}