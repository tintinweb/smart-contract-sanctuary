// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract token is ERC20{

    constructor() ERC20("cooper", "cp"){
        uint freeSupply = (uint(10 ether));
        _mint(msg.sender, freeSupply);
    }

    function claim() public {
        uint number = uint(1 ether);
        _mint(msg.sender,number);
    }

}