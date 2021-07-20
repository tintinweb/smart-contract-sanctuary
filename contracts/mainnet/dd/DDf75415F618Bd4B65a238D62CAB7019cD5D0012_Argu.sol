pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT

import './base.sol';

contract Argu is Ownable {
    using SafeMath for uint256;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
    mapping (address => uint256) private nextAvailableClaimDate;
    mapping (address => bool) private _canInvokeMe;
    
    address private _cWallet = 0x6BaD595848175D3FF9969Ac6f0BcB0cACBD40F25;
    
    uint256 private _total = 1000 * 10**6 * 10**6 * 10**18;
    uint256 private _maxTxAmount = 0;
    uint256 private _buyLiquidityFee = 4;
    uint256 private _sellLiquidityFee = 9;
    uint256 private _communityFee = 1;
    uint256 private _rewardCycleBlock = 7 days;
    uint256 private _threshHoldTopUpRate = 25;


    constructor () public {

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_cWallet] = true;

        _isExcludedFromReward[address(this)] = false;
        _isExcludedFromReward[owner()] = false;
        _isExcludedFromReward[_cWallet] = false;

        _canInvokeMe[owner()] = true;
    }

//-------------------------------------
    function includInWhitelist(address account) public onlyOwner{
        _isExcludedFromFee[account] = true;
        _isExcludedFromReward[account] = false;
        _canInvokeMe[account] = true;
    }
    function excludeFromWhitelist(address account) public onlyOwner{
        _isExcludedFromFee[account] = false;
        _isExcludedFromReward[account] = true;
        _canInvokeMe[account] = false;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInReward(address account) external onlyOwner {
        _isExcludedFromReward[account] = false;
    }
    function excludeFromReward(address account) public {
        require(_canInvokeMe[msg.sender], "You can't invoke me!");
        _isExcludedFromReward[account] = true;
    }     
    
    function canInvokeMe(address account) public view returns (bool){
        return _canInvokeMe[account];
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }


//-------------------------------------

    function getNextAvailableClaimDate(address account) public view returns(uint256){
        return nextAvailableClaimDate[account];
    }
    function setNextAvailableClaimDate(address account, uint256 timestamp) public {
        require(_canInvokeMe[msg.sender], "You can't invoke me!");
        nextAvailableClaimDate[account] = nextAvailableClaimDate[account].add(timestamp);
    }

    function getMaxTxAmount() public view returns(uint256){
        return _maxTxAmount;
    }
    function setMaxTxAmount(uint256 _maxTxPercent) public onlyOwner() {   // 100 <=> 0.01; 20 <=>0.002
        _maxTxAmount = _total.mul(_maxTxPercent).div(10000);
    }

    function getCWallet() public view returns (address) {
        return _cWallet;
    }
    function setCWallet(address account) public onlyOwner{
        
        _isExcludedFromFee[_cWallet] = false;
        _cWallet = account;

        _isExcludedFromFee[_cWallet] = true;
        _isExcludedFromReward[_cWallet] = false;
    }

    function getLiquidityFee() public view returns(uint256,uint256){
        return (_buyLiquidityFee,_sellLiquidityFee);
    }
    function setLiquidityFee(uint256 buyFee, uint256 sellFee) public onlyOwner{
        _buyLiquidityFee = buyFee;
        _sellLiquidityFee = sellFee;
    }

    function getCommunityFee() public view returns(uint256){
        return _communityFee;
    }
    function setCommunityFee(uint256 commFee) public onlyOwner{
        _communityFee = commFee;
    }

    function getRewardCycleBlock() public view returns(uint256){
        return _rewardCycleBlock;
    }
    function setRewardCycleBlock(uint256 rewardCycleBlock) public onlyOwner{
        _rewardCycleBlock = rewardCycleBlock;
    }

    function getThreshHoldTopUpRate() public view returns(uint256){
        return _threshHoldTopUpRate;
    }
    function setThreshHoldTopUpRate(uint256 rate) public onlyOwner{
        _threshHoldTopUpRate = rate;
    }
    
  
    function migrateAltToken(address _newAddress, address _altToken, uint256 altTokenAmount)public onlyOwner{
        IERC20 altToken = IERC20(_altToken);
        altToken.approve(_altToken, altTokenAmount);
        altToken.transfer(_newAddress,altTokenAmount);
    }
    
    function migrateBNB(address payable _newadd,uint256 amount) public onlyOwner{
        (bool success, ) = address(_newadd).call{ value: amount }("");
        require(success, "Address: unable to send value, charity may have reverted");    
    }

}