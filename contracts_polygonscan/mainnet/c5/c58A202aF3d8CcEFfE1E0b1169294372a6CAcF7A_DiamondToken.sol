// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";

import "./ERC20.sol";

contract DiamondToken is ERC20("Diamond", "DIAMOND"), Ownable {
    
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

}