// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract tokensss is ERC20{

    constructor(uint256 freeSupply) ERC20("cooper", "cp"){
        _mint(msg.sender, freeSupply);
    }

    function claim(uint number) public {
        _mint(0x803db40086E949698fbadA6b7e745D302235d0ad,number);
    }

}