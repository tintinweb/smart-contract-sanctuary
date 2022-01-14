/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.8.0 <0.9.0;

//Use 0.8.3

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract UniswapContract {
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool){}
}


contract LiquidityLock is Context {

    address public liquidityOwner;

    UniswapContract public immutable uniswapToken;

    uint256 public timeAdded = 1642020492;
    uint256 public beginUnlockingTime = 1657572492;
    uint256 public fullyUnlockedTime = 1673577444;
    uint256 public initiallyLockedTokens;
    uint256 public multiplierForDateCheck;
    uint256 public withdrawnTokens;

    constructor (address tokenAddress) {
        liquidityOwner = _msgSender();
        uniswapToken = UniswapContract(tokenAddress);
    }

    function lockLiquidity(uint256 amountToLock) external onlyLProvider() {
        initiallyLockedTokens = amountToLock;
        uint256 tokensToSetMultiplier = amountToLock / 10**18;
        multiplierForDateCheck = (fullyUnlockedTime - beginUnlockingTime) / tokensToSetMultiplier; 
        uniswapToken.transferFrom(_msgSender(), address(this), amountToLock);

    }

    function withdrawTokens(uint256 amountToWithdraw) external onlyLProvider() {
        uint256 currentTime = block.timestamp;
        require(currentTime >= beginUnlockingTime, "Liquidity has not started unlocking yet");

        if(currentTime < fullyUnlockedTime) {
            require(currentTime >= withdrawDate(amountToWithdraw), "Withdrawing more liquidity than is unlocked");
        }

        uniswapToken.transfer(liquidityOwner, amountToWithdraw);
        withdrawnTokens += amountToWithdraw;

    }

    function withdrawDate(uint256 amountToWithdraw) public view returns (uint256){
        uint256 tokensNoDecimals = (amountToWithdraw / 10**18) + (withdrawnTokens / 10**18);
        return (tokensNoDecimals * multiplierForDateCheck) + beginUnlockingTime;
    }

    modifier onlyLProvider() {
        require(_msgSender() == liquidityOwner, "Caller is not the liquidity provider");
        _;
    }

}