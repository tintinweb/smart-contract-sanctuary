//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";
import "./BaseErc20.sol";
import "./Taxable.sol";
import "./Lottery.sol";
import "./AntiSniper.sol";
import "./TaxDistributor.sol";

library LightweightsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }
}


contract iWinToken is BaseErc20, Taxable, Lottery, AntiSniper {
    using SafeMath for uint256;
    using LightweightsDateTimeLibrary for uint256;
    
    constructor (address developmentWalletAddress, address marketingWalletAddress, address investorWalletAddress) {
        configure(msg.sender);
        
        symbol = "iWin";
        name = "iWin Token";
        decimals = 9;


        // IF USING PINKSALE, REMEMBER TO MARK THE PINKSALE ADDRESS AS:
        // setExcludedFromTax
        // setIsNeverSniper
        // 


        // Pancake Swap
        address pancakeSwap = 0xc99f3718dB7c90b020cBBbb47eD26b0BA0C6512B; // TESTNET
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
        taxDistributor.createDistributorTax("Investor", 120, 120, investorWalletAddress, false);
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

    function lotteryReady() public override view returns (bool) {
        if (launched && lotteryEnabled) {
            (uint year, uint month, uint day, uint hour,,) = block.timestamp.timestampToDateTime();
            (uint lwyear, uint lwmonth, uint lwday, uint lwhour,,) = lotteryLastWinTime.timestampToDateTime();

            if (day > lwday || hour > lwhour || month > lwmonth || year > lwyear) {
                return true;
            }
        }

        return false;
    }
    
    
    // Public methods

}