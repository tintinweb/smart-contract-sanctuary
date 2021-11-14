/*
  _____ _ _      ____  _             
 |  ___| (_)_ __/ ___|| |_ __ _ _ __ 
 | |_  | | | '_ \___ \| __/ _` | '__|
 |  _| | | | |_) |__) | || (_| | |   
 |_|   |_|_| .__/____/ \__\__,_|_|   
           |_|                       
*/
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";
import "./BaseErc20.sol";
import "./Taxable.sol";
import "./Dividends.sol";
import "./AntiSniper.sol";

contract FlipStar is BaseErc20, Taxable, Dividends, AntiSniper {
    using SafeMath for uint256;

    mapping (address => bool) public excludedFromSelling;

    constructor () {
        owner = msg.sender;
        symbol = "FLIP";
        name = "FlipStar";
        decimals = 18;

        address pancakeSwap = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // TESTNET
        //address pancakeSwap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET
        IDEXRouter router = IDEXRouter(pancakeSwap);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;

        minimumTimeBetweenSwaps = 5 minutes;
        minimumTokensBeforeSwap = 1000 * 10 ** decimals;
        distributorGas = 500000;
        
        enableSniperBlocking = true;
        enableBlockLogProtection = true;
        enableHighTaxCountdown = true;

        taxDistributor = new TaxDistributor(pancakeSwap, pair, WBNB);
        dividendDistributor = new DividendDistributor(address(taxDistributor));

        taxDistributor.createWalletTax("Development", 100, 100, address(1));
        taxDistributor.createWalletTax("Marketing", 100, 100, address(2));
        taxDistributor.createWalletTax("Lotto", 100, 100, address(3));
        taxDistributor.createDividendTax("Liquidity", 200, 300, address(dividendDistributor));
        taxDistributor.createLiquidityTax("Rewards", 500, 600);

        excludedFromTax[owner] = true;
        excludedFromTax[address(taxDistributor)] = true;
        excludedFromTax[address(dividendDistributor)] = true;

        excludedFromDividends[pair] = true;
        excludedFromDividends[address(this)] = true;
        excludedFromDividends[address(taxDistributor)] = true;
        excludedFromDividends[address(dividendDistributor)] = true;

        _allowed[address(taxDistributor)][pancakeSwap] = 2**256 - 1;
        _totalSupply = _totalSupply.add(100_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner].add(_totalSupply);
        
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides

    function launch() public override(BaseErc20, AntiSniper) onlyOwner {
        return super.launch();
    }

    function isAlwaysExempt(address who) override(BaseErc20, Taxable, Dividends) internal returns (bool) {
        return super.isAlwaysExempt(who);
    }

    function preTransfer(address from, address to, uint256 value) override(BaseErc20, AntiSniper) internal {
        require(excludedFromSelling[from] == false, "address is not allowed to sell");
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(BaseErc20, AntiSniper, Taxable) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
    
    function postTransfer(address from, address to) override(BaseErc20, Taxable, Dividends) internal {
        super.postTransfer(from, to);
    }


    // Admin methods

    function setExchange(address who, bool isExchange) public onlyOwner {
        exchanges[who] = isExchange;
        excludedFromDividends[who] = isExchange;
    }

    function setExcludedFromSelling(address who, bool isExcluded) public onlyOwner {
        require(who != address(this) && who != address(taxDistributor) && who != address(dividendDistributor) && exchanges[who] == false, "this address cannot be excluded");
        excludedFromSelling[who] = isExcluded;
    }
}