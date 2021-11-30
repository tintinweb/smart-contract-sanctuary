// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract AlphaStarship is ERC20 {
    mapping(address => bool) private _isAdmin;

    constructor(address[] memory addrs, uint amount) ERC20("Alpha STARSHIP","aSTARSHIP") {
        for(uint256 i=0; i < addrs.length; i++){
            _isAdmin[addrs[i]] = true;
        }

        _mint(msg.sender, amount);
    }

    modifier onlyAdmin {
        require(_isAdmin[msg.sender] == true, "User must be be admin to call this function");
        _;
    }

    function mint(uint256 amount, address to) external onlyAdmin {
        _mint(to, amount);
    }

    // TODO: Burn function


}