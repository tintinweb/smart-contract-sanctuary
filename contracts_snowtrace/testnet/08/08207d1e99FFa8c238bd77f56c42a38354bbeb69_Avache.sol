//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Context.sol";
import "./IERC20.sol";

contract Avache is ERC20 {
    constructor(uint256 _totalSupply) ERC20("Avalanche", "Avache") {
        _totalSupply = _totalSupply * (10**18);
        _mint(msg.sender, _totalSupply);
    }
}