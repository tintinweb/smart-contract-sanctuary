// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol){
        _mint(msg.sender, 100000000 * 10**18);
    }
    
    mapping (address => bool) isBlacklist;
    address public rewardWallet;
    uint256 private limitTxForRewardWallet =1000;
  
    function updateRewardWallet(address newWallet) external onlyOwner {
        rewardWallet = newWallet;
    }
  
    function updateRewardWalletLimit(uint256 newLimitation) external onlyOwner {
        limitTxForRewardWallet = newLimitation;
    }
  
    function setBlacklist(address wallet) external onlyOwner {
        isBlacklist[wallet]=true;
    }
  
    function removeBlacklist(address wallet) external onlyOwner {
        isBlacklist[wallet]=false;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
      require(_allowances[sender][msg.sender]>=amount,"Insufficient Allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]-amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
    //Use to cover rewardWallet send more  than limitation per transaction
    if(sender==rewardWallet){
     require(amount<=limitTxForRewardWallet);
    }
    
    require(!isBlacklist[sender],"User blacklisted");
    require(_balances[sender]>=amount,"Insufficient Balance");
        _balances[sender] = _balances[sender]-amount;
        _balances[recipient] = _balances[recipient]+amount;

        emit Transfer(sender, recipient, amount);
    
        return true;
    }
}