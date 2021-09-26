// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FullERC20.sol";

contract FantasyCricketCoin is ERC20 {
    
    constructor() ERC20("FantasyCricketCoin", "FCC") {
        _owner = _msgSender();
    }
    
    uint256 private MAX_CURRENT_SUPPLY = 0;
    uint256 private MAX_ADDRESS_SUPPLY = 11;
    address private _owner = address(0);

    function mintCoin(uint256 amount) external {
        require(super.totalSupply() < MAX_CURRENT_SUPPLY, "cannot mint anymore coins");
        _mint(_msgSender(), amount);
        require(super.balanceOf(_msgSender()) < MAX_ADDRESS_SUPPLY, "this address cannot mint anymore coins");
    }
    
    function ownerMintCoin(uint256 amount) external onlyOwner {
        require(super.totalSupply() < MAX_CURRENT_SUPPLY, "cannot mint anymore coins");
        _mint(_msgSender(), amount);
    }
    
    function increaseMaxSupply(uint256 amount) external onlyOwner {
        require(amount > 0, "only positive values allowed");
        MAX_CURRENT_SUPPLY += amount;
    }
    
    function getMaxSupply() public view returns (uint256) {
        return MAX_CURRENT_SUPPLY;
    }

}