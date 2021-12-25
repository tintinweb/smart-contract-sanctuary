// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./InstaDappActions.sol";
import "./KeeperCompatibleInterface.sol";
import "./KeeperBase.sol";

contract AutoRepayLeverage is InstaDappActions, KeeperCompatibleInterface, KeeperBase {

    address public owner = 0xe1Cee19cc8Ef9553B1d5285FbEE749ed643148c5;

    uint256 public validUntilBlock = 0;

    uint256 public lastBuyPrice = 260 * 1e4; // 245 cents

    uint256 public buyPercentageInHundreds = 50; // 10e1 = 0.1%; 10e2 = 1%; 10e3 = 10%; 10e4 = 100%;

    uint256 public lastSellPrice = 265 * 1e4; // 250 cents

    uint256 public sellPercentageInHundreds = 100; // 10e1 = 0.1%; 10e2 = 1%; 10e3 = 10%; 10e4 = 100%;

    uint256 public differenceToLastPrice = 1e4;

    address private quickswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    address private USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    
    address private WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address private amWMATIC = 0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4;  

    function updateValidity() external {
        require(msg.sender == owner);
        validUntilBlock = block.number + 12 * 10 * 30; // 30 Blocks per Minute
    }

    function kill() external {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }

    function calculateBuyAmount(uint256 balance) private view returns (uint256){
        uint256 inversePercentage = 10000 / buyPercentageInHundreds;
        return balance / inversePercentage;
    }

    function calculateSellAmount(uint256 balance) private view returns (uint256){
        uint256 inversePercentage = 10000 / sellPercentageInHundreds;
        return balance / inversePercentage;
    }

    function checkUpkeep(bytes calldata checkData) external override cannotExecute returns (bool upkeepNeeded, bytes memory performData) {
        bool buy = abi.decode(checkData, (bool));

        if(buy){
            try this.leverageVault() {
                return (true, abi.encode(true));
            }catch{
                return (false, bytes(""));
            }
        }else{
            try this.repayVault() {
                return (true, abi.encode(false));
            }catch{
                return (false, bytes(""));
            }
        }
    }

    function performUpkeep(bytes calldata performData) external {
        bool buy = abi.decode(performData, (bool));
        if(buy){
            this.leverageVault();
        }else{
            this.repayVault();
        }
    }

    function leverageVault() external {
        require(msg.sender == address(this), "Invalid Caller");
        require(block.number <= validUntilBlock, "Not valid");

        uint256 existingBalance = IERC20(amWMATIC).balanceOf(dsa);

        uint256 amtToBuy = calculateBuyAmount(existingBalance);
        uint256 nextBuyPrice = lastBuyPrice - differenceToLastPrice;
        uint256 usdcToBorrow = (amtToBuy * nextBuyPrice) / 1e18; // BuyAmount * Price; Cut away 1e18 decimal Places from BuyAmount

        lastSellPrice = lastBuyPrice; // Set old Buy Price to new Sell Price
        lastBuyPrice = nextBuyPrice; // Set new Price before calling out to other Contracts

        aaveBorrow(USDC, usdcToBorrow);
        uint boughtMatic = swap(USDC, WMATIC, amtToBuy);       

        require(boughtMatic >= amtToBuy, "TOO FEW MATIC BOUGHT");
        
        aaveDeposit(WMATIC, boughtMatic);
    }

    function repayVault() external {
        require(msg.sender == address(this), "Invalid Caller");
        require(block.number <= validUntilBlock, "Not Valid");

        uint256 existingBalance = IERC20(amWMATIC).balanceOf(dsa);

        uint256 amtToSell = calculateSellAmount(existingBalance);
        uint256 nextSellPrice = lastSellPrice + differenceToLastPrice;
        uint256 usdcToRepay = (amtToSell * nextSellPrice) / 1e18; // BuyAmount * Price; Cut away 1e18 decimal Places from BuyAmount

        lastBuyPrice = lastSellPrice; // Set old Sell Price to new Buy Price
        lastSellPrice = nextSellPrice; // Set new Price before calling out to other Contracts

        aaveWithdraw(WMATIC, amtToSell);
        uint boughtUSDC = swap(WMATIC, USDC, usdcToRepay);       

        require(boughtUSDC >= usdcToRepay, "TOO FEW USDC BOUGHT");
        
        aaveRepay(USDC, boughtUSDC);
    }    

    function swap(address fromToken, address toToken, uint minimumAmount) private returns (uint256){
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;

        uint fromBalance = IERC20(fromToken).balanceOf(address(this));
        IERC20(fromToken).approve(quickswapRouter, fromBalance);

        return IUniswapV2Router02(quickswapRouter).swapExactTokensForTokens(fromBalance, minimumAmount, path, dsa, block.timestamp)[1];
    }



}