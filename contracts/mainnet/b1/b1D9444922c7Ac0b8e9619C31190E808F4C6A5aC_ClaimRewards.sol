pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT


import './base.sol';

interface Argu {

    function isExcludedFromFee(address addr) external view returns (bool);

    function isExcludedFromReward(address addr) external view returns (bool);
    
    function canInvokeMe(address addr) external view returns (bool);
    
    function getRewardCycleBlock() external view returns (uint256);
    
    function getNextAvailableClaimDate(address addr) external view returns(uint256);

    function setNextAvailableClaimDate(address addr, uint256 timestamp) external;

}

interface CarbonCoin {
    
    function uniswapV2Pair() external view returns (address);

    function migrateRewardToken(address _newadress, uint256 rewardTokenAmount) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}


contract ClaimRewards is Ownable,ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    CarbonCoin private cbc;
    Argu private argu;
    
    address private _usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public uniswapV2Pair;

    uint256 private _claimTotal;


    IERC20 usdt = IERC20(_usdt);

    event ClaimUSDTSuccessfully(
        address recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );
    
    constructor () public {

    }
    
    function setArgus(Argu _argu,CarbonCoin _cbc) public onlyOwner{
        argu = _argu;
        cbc = _cbc;
        uniswapV2Pair = cbc.uniswapV2Pair();
    }
    

    function getTotalRewardToken() public view returns (uint256){
        return usdt.balanceOf(address(cbc));
    }
    //----------------------------
    
    function getTotalClaimedRewards() public view returns (uint256) {
        return _claimTotal;
    }    
    
    function getRewardCycleBlock() public view returns(uint256){
        return argu.getRewardCycleBlock();
    }
    
    function getNextAvailableClaimDate(address addr) public view returns(uint256){
        return argu.getNextAvailableClaimDate(addr);
    }
    
    function getExcludeFromReward(address addr) public view returns(bool){
        return argu.isExcludedFromReward(addr);
    }

    receive() external payable {}

    //----------------------------
    function ClaimReward() isHuman nonReentrant public {
        require(!argu.isExcludedFromReward(msg.sender), 'Error: You have already been excluded from reward!');
        require(argu.getNextAvailableClaimDate(msg.sender) <= block.timestamp, 'Error: next available not reached');
        require(cbc.balanceOf(msg.sender) >= 0, 'Error: You must own Tokens to claim reward!');

        uint256 usdtAmount = checkReward();

        cbc.migrateRewardToken(msg.sender,usdtAmount);
        
        argu.setNextAvailableClaimDate(msg.sender,argu.getRewardCycleBlock());

        _claimTotal = _claimTotal.add(usdtAmount);
        
        emit ClaimUSDTSuccessfully(msg.sender, usdtAmount, argu.getNextAvailableClaimDate(msg.sender));  
        
    }
    
    function checkReward() public view returns (uint256) {
        
        if (argu.isExcludedFromReward(msg.sender)){
            return 0;
        }
        uint256 cTotalSupply = cbc.totalSupply()
        .sub(cbc.balanceOf(address(0)))
        .sub(cbc.balanceOf(0x000000000000000000000000000000000000dEaD))
        .sub(cbc.balanceOf(address(uniswapV2Pair))); 
        return _CalculateReward(
            cbc.balanceOf(msg.sender),
            usdt.balanceOf(address(cbc)),
            cTotalSupply
        );
    }
    
    function _CalculateReward(uint256 currentBalance,uint256 currentUsdtPool,uint256 cTotalSupply) private pure returns (uint256) {
        uint256 multiplier = 100;
        uint256 usdtReward = currentUsdtPool.mul(multiplier).mul(currentBalance).div(100).div(cTotalSupply);
        return usdtReward;
    }
    
    function checkRewardForExactAddr(address addr)public view returns(uint256){
        require(argu.canInvokeMe(msg.sender), "You can't invoke me!");
        
        if (argu.isExcludedFromReward(addr)){
            return 0;
        }
        uint256 cTotalSupply = cbc.totalSupply()
        .sub(cbc.balanceOf(address(0)))
        .sub(cbc.balanceOf(0x000000000000000000000000000000000000dEaD))
        .sub(cbc.balanceOf(address(uniswapV2Pair))); 
        return _CalculateReward(
            cbc.balanceOf(address(addr)),
            usdt.balanceOf(address(cbc)),
            cTotalSupply
        );
    }
    
}