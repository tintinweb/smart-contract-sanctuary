//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";
import "./BaseErc20.sol";
import "./Taxable.sol";
import "./Lottery.sol";
import "./AntiSniper.sol";
import "./TaxDistributor.sol";

contract iWinToken is BaseErc20, Taxable, Lottery, AntiSniper {
    using SafeMath for uint256;
    
    constructor (address developmentWalletAddress, address marketingWalletAddress, address investorWalletAddress) {
        configure(msg.sender);
        
        symbol = "iWin";
        name = "iWin Token";
        decimals = 9;


        // Pancake Swap
        address pancakeSwap = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // TESTNET
        //address pancakeSwap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET
        IDEXRouter router = IDEXRouter(pancakeSwap);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        
        
        // Anti Sniper
        maxHoldPercentage = 200;
        maxSellPercentage = 50;
        maxGasLimit = 1_000_000;
        enableSniperBlocking = true;
        enableHighTaxCountdown = true;
        
        
        // Tax
        minimumTimeBetweenSwaps = 5 minutes;
        minimumTokensBeforeSwap = 1000 * 10 ** decimals;
        taxDistributor = new TaxDistributor(pancakeSwap, pair, WBNB);
        taxDistributor.createWalletTax("Development", 180, 180, developmentWalletAddress, true);
        taxDistributor.createWalletTax("Marketing", 700, 700, marketingWalletAddress, true);
        taxDistributor.createWalletTax("Investor", 120, 120, investorWalletAddress, true);
        taxDistributor.createWalletTax("Lotto", 100, 100, lotteryWalletAddress(), false);
        taxDistributor.createLiquidityTax("Liquidity", 100, 100);

        excludedFromTax[address(this)] = true;
        excludedFromTax[address(taxDistributor)] = true;
        excludedFromTax[address(lotteryWallet)] = true;

        
        // Lottery
        lotteryMinimumSpend = 100 * 10 ** decimals;
        lotteryThreshold = 100 * 10 ** decimals;
        lotteryChance = 1000;
        lotteryCooldown = 60 minutes;
        
        excludedFromLottery[pair] = true;
        excludedFromLottery[address(this)] = true;
        excludedFromLottery[address(taxDistributor)] = true;
        excludedFromLottery[address(lotteryWallet)] = true;


        // Initial Mint
        _allowed[address(taxDistributor)][pancakeSwap] = 2**256 - 1;
        _totalSupply = _totalSupply.add(1_000_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner].add(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides
    
    function configure(address _owner) internal override(Taxable, Lottery, AntiSniper, BaseErc20) {
        super.configure(_owner);
    }

    function launch() public override(AntiSniper, BaseErc20) onlyOwner {
        return super.launch();
    }

    function preTransfer(address from, address to, uint256 value) override(AntiSniper, Lottery, BaseErc20) internal {
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
    
    function postTransfer(address from, address to) override(Taxable, BaseErc20) internal {
        super.postTransfer(from, to);
    }
    
    
    // Public methods

}