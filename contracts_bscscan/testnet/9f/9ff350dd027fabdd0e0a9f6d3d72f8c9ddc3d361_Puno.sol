// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BEP20.sol";
import "./Ownable.sol";

contract Puno is BEP20, Ownable{
    
    uint256  _totalSupply        = 5100000 * 10 ** 18;   
    uint256  _rewardPercent      = 250000 * 10 ** 18;
    uint256  _holdPercent        = 2799000 * 10 ** 18;
    uint256  _maintenacePercent  = 51000 * 10 ** 18;
    uint256  _circulatingPercent = 2000000 * 10 ** 18;
    
    address rewardWallet       = 0x4A250668b0610cA1aff58732346982F7d75120C1;
    address maintenanceWallet  = 0x4A250668b0610cA1aff58732346982F7d75120C1;
    address holdWallet         = 0x4A250668b0610cA1aff58732346982F7d75120C1;
    
    constructor (string memory name, string memory symbol) BEP20(name, symbol) {
        _mint(msg.sender, _circulatingPercent);
        _mint(rewardWallet, _rewardPercent);
        _mint(maintenanceWallet, _maintenacePercent);
        _mint(holdWallet, _holdPercent);
    }
    
    function burn(uint256 amount) external  {
        _burn(msg.sender, amount);
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function setRewardWallet(address account) public onlyOwner {
        rewardWallet = account;
    }
    
    function setMainetanceWallet(address account) public onlyOwner {
        maintenanceWallet = account;
    }
    
    function setHoldWallet(address account) public onlyOwner {
        holdWallet = account;
    }
    
}