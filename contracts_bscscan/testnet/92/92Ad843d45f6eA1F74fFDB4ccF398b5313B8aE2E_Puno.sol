// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./BEP20.sol";
import "./Ownable.sol";


contract Puno is BEP20, Ownable{
    
    uint256  private _totalSupply        = 5100000 * 10 ** 18;   
    uint256  private _rewardPercent      = 250000 * 10 ** 18;
    uint256  private _holdPercent        = 2799000 * 10 ** 18;
    uint256  private _maintenacePercent  = 51000 * 10 ** 18;
    uint256  private _circulatingPercent = 2000000 * 10 ** 18;
    
    address private rewardWallet       = 0x4A250668b0610cA1aff58732346982F7d75120C1;
    address private maintenanceWallet  = 0x4A250668b0610cA1aff58732346982F7d75120C1;
    address private holdWallet         = 0x4A250668b0610cA1aff58732346982F7d75120C1;
    
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
    
    function getRewardWallet() public view returns (address){
        return rewardWallet;
    }
    
    function getMainetanceWallet() public view returns (address){
        return maintenanceWallet;
    }
    
    function getHoldWallet() public view returns (address){
        return holdWallet;
    }
    
}