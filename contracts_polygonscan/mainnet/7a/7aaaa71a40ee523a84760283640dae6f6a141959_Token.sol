// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol){
        _mint(msg.sender, 100000000 * 10**18);
    }
    mapping(address => bool) private liquidityPool;    
    mapping (address => bool) isBlacklist;
    mapping (address => bool) isFeeExempt;
    address public rewardWallet;
    address public marketing;
    uint256 private limitTxForRewardWallet =1000;
    uint256 private amountReceived;
    uint256 private fee = 0;
    
    event changeLiquidityPoolStatus(address lpAddress, bool status);

    function updateRewardWallet(address newWallet) external onlyOwner {
        rewardWallet = newWallet;
    }
  
    function updateRewardWalletLimit(uint256 newLimitation) external onlyOwner {
        limitTxForRewardWallet = newLimitation;
    }
  
    function setBlacklist(address wallet) external onlyOwner {
        isBlacklist[wallet]=true;
    }
    function setMarketingWallet(address _marketing) external onlyOwner {
        marketing = _marketing;
    }    
    function setSellFees(uint256 _fee) external onlyOwner {
        fee = _fee;
        require(_fee < 25);
    }    
    function setIsFeeExempt(address wallet, bool exempt) external onlyOwner {
        isFeeExempt[wallet] = exempt;
    }   
    function setLiquidityPoolStatus(address _lpAddress, bool _status) external onlyOwner {
    liquidityPool[_lpAddress] = _status;
    emit changeLiquidityPoolStatus(_lpAddress, _status);
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
        amountReceived = amount;
        if(liquidityPool[sender] == true) {
        //It's an LP Pair and it's a buy
        amountReceived = amount;
    }
        if(!isFeeExempt[sender]){
        amountReceived = amount-amount*fee/100;
    }

        _balances[recipient] = _balances[recipient] +amountReceived;
        _balances[marketing] = _balances[marketing] +amount*fee/100;
        emit Transfer(sender, recipient, amount);
    
        return true;
    }
}