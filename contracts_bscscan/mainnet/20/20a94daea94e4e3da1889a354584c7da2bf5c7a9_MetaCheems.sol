// SPDX-License-Identifier: MIT

/**

███╗░░░███╗███████╗████████╗░█████╗░  ░█████╗░██╗░░██╗███████╗███████╗███╗░░░███╗░██████╗
████╗░████║██╔════╝╚══██╔══╝██╔══██╗  ██╔══██╗██║░░██║██╔════╝██╔════╝████╗░████║██╔════╝
██╔████╔██║█████╗░░░░░██║░░░███████║  ██║░░╚═╝███████║█████╗░░█████╗░░██╔████╔██║╚█████╗░
██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║  ██║░░██╗██╔══██║██╔══╝░░██╔══╝░░██║╚██╔╝██║░╚═══██╗
██║░╚═╝░██║███████╗░░░██║░░░██║░░██║  ╚█████╔╝██║░░██║███████╗███████╗██║░╚═╝░██║██████╔╝
╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝  ░╚════╝░╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░░░░╚═╝╚═════╝░
Telegram : @meta_cheems
Website : www.metacheems.live

1% Max Buy & Sell 
2% Max Wallet 

Buy Fee
2% Buyback 
5% Marketing 
3% Liquidity 

Sell Fee
5% Buyback      
5% Marketing
5% Liquidity
**/

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./SafeMath.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract MetaCheems is ERC20, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromLimit;
    
    uint256 private _supplyWithoutDecimals = 100000000000;
    uint256 public maxSupply = _supplyWithoutDecimals * 10**18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public liquidityReceiver;
    address public marketingWallet;
    address public buybackWallet;
    
    uint256 public buyLiquidityFee = 3;
    uint256 public buyMarketingFee = 5;
    uint256 public buyBuybackFee = 2;
    uint256 public totalBuyFees = buyLiquidityFee.add(buyMarketingFee).add(buyBuybackFee);

    uint256 public sellLiquidityFee = 5;
    uint256 public sellMarketingFee = 5;
    uint256 public sellBuybackFee = 5;
    uint256 public totalSellFees = sellLiquidityFee.add(sellMarketingFee).add(sellBuybackFee);

    uint256 public buyFeeTokensToSwap;
    uint256 public sellFeeTokensToSwap;

    uint256 public maxBuyTransaction = maxSupply.div(100);
    uint256 public maxSellTransaction = maxSupply.div(200);
    uint256 public maxWallet = maxSupply.div(50);
    
    uint256 public launchedAt;

    bool public swapAndLiquifyEnabledOnBuy = true;
    bool public swapAndLiquifyEnabledOnSell = true;

    bool public swapUpperLimitOnBuyEnabled = true;
    bool public swapUpperLimitOnSellEnabled = true;

    uint256 public minimumTokensBeforeSwap = maxSupply * 5 / 4000;
    uint256 public swapOnBuyUpperLimit = maxSupply * 5 / 4000;
    uint256 public swapOnSellUpperLimit = maxSupply * 5 / 4000;

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
    {
        _mint(_msgSender(), maxSupply);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[address(msg.sender)] = true;

        isExcludedFromLimit[address(this)] = true;
        isExcludedFromLimit[address(msg.sender)] = true;

    }
    
    function launch() public onlyOwner {
    launchedAt = block.timestamp;
    }

    function excludeAddressFromFees(address account, bool excludedFromFees) public onlyOwner {
        isExcludedFromFees[address(account)] = excludedFromFees;

        emit excludeAddressFromFee(account, excludedFromFees);
    }
    
    event excludeAddressFromFee(address,bool);

    function excludeAddressFromLimit(address account, bool excludedFromLimit) public onlyOwner {
        isExcludedFromLimit[address(account)] = excludedFromLimit;

        emit excludeAddressFromLimits(account, excludedFromLimit);

    }
    
    event excludeAddressFromLimits(address,bool);

    function setBuyFees(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee) public onlyOwner {
        require(liquidityFee.add(marketingFee).add(buybackFee) <= 20, "You can't set Buy Fees higher than 20%");

        buyLiquidityFee = liquidityFee;
        buyMarketingFee = marketingFee;
        buyBuybackFee = buybackFee;

        totalBuyFees = buyLiquidityFee.add(buyMarketingFee).add(buyBuybackFee);

        emit changeBuyFees(buyLiquidityFee, buyMarketingFee, buyBuybackFee, totalBuyFees);

    }

    event changeBuyFees(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 totalBuyFees);

    function setSellFees(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee) public onlyOwner {
        require(liquidityFee.add(marketingFee).add(buybackFee) <= 20, "You can't set Sell Fees higher than 20%");

        sellLiquidityFee = liquidityFee;
        sellMarketingFee = marketingFee;
        sellBuybackFee = buybackFee;

        totalSellFees = sellLiquidityFee.add(sellMarketingFee).add(sellBuybackFee);

        emit changeSellFees(sellLiquidityFee, sellMarketingFee, sellBuybackFee, totalSellFees);

    }
    
    event changeSellFees(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 totalSellFees);

    function setWallet(address setLiquidityReceiver, address setMarketingWallet, address setBuybackWallet) public onlyOwner {
        liquidityReceiver = setLiquidityReceiver;
        marketingWallet = setMarketingWallet;
        buybackWallet = setBuybackWallet;

        emit setWalletAddress(liquidityReceiver, marketingWallet, buybackWallet);

    }
    
    event setWalletAddress(address newLiquidityAddress, address newMarketingAddress, address newBuybackAddress);
    
    function changeMaxTxLimits(uint256 setMaxBuyTransaction, uint256 setMaxSellTransaction) public onlyOwner {
        require(setMaxBuyTransaction >= _supplyWithoutDecimals.div(1000), "You can't set max buy lower than 0.1% of supply");
        

        maxBuyTransaction = setMaxBuyTransaction * (10**18);
        maxSellTransaction = setMaxSellTransaction * (10**18);

        emit changeMaxTransaction(maxBuyTransaction, maxSellTransaction);

    }

    event changeMaxTransaction(uint256 newMaxBuyTransactionValue, uint256 newMaxSellTransactionValue);

    function changeMaxWalletLimit(uint256 setNewMaxWalletValue) public onlyOwner {
        require(setNewMaxWalletValue >= _supplyWithoutDecimals.div(1000), "You can't set max wallet lower than 0.1% of supply");
        maxWallet = setNewMaxWalletValue * (10**18);

        emit changeMaxWallet(maxWallet);

    }

    event changeMaxWallet(uint256 newMaxWalletValue);

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);

        emit Burn(amount);
    }

    event Burn(uint256 amount);
    
    function swapAndLiquifyEnabled(bool setSwapAndLiquifyEnabledOnBuy, bool setSwapAndLiquifyEnabledOnSell) public onlyOwner {
        swapAndLiquifyEnabledOnBuy = setSwapAndLiquifyEnabledOnBuy;
        swapAndLiquifyEnabledOnSell = setSwapAndLiquifyEnabledOnSell;
        
        emit SwapAndLiquifyEnabled(swapAndLiquifyEnabledOnBuy, swapAndLiquifyEnabledOnSell);

    }

    event SwapAndLiquifyEnabled(bool SwapAndLiquifyEnabledOnBuy, bool SwapAndLiquifyEnabledOnSell);
    
    function changeUpperLimitEnabled(bool setSwapUpperLimitOnBuyEnabled, bool setSwapUpperLimitOnSellEnabled) public onlyOwner {
        swapUpperLimitOnBuyEnabled = setSwapUpperLimitOnBuyEnabled;
        swapUpperLimitOnSellEnabled = setSwapUpperLimitOnSellEnabled;

        emit SetSwapUpperLimitsEnabled(swapUpperLimitOnBuyEnabled, swapUpperLimitOnSellEnabled);
        
    }
    
    event SetSwapUpperLimitsEnabled(bool SwapUpperLimitOnBuyEnabled, bool SwapUpperLimitOnSellEnabled);

    function swapSetting(uint256 setMinimumTokensBeforeSwap, uint256 setSwapOnBuyUpperLimit, uint256 setSwapOnSellUpperLimit) public onlyOwner {
        minimumTokensBeforeSwap = setMinimumTokensBeforeSwap;
        swapOnBuyUpperLimit = setSwapOnBuyUpperLimit;
        swapOnSellUpperLimit = setSwapOnSellUpperLimit;

        emit ChangeSwapSetting(minimumTokensBeforeSwap, swapOnBuyUpperLimit, swapOnSellUpperLimit);

    }
    
    event ChangeSwapSetting(uint256 NewMinimumTokensBeforeSwap, uint256 NewSwapOnBuyUpperLimit, uint256 NewSwapOnSellUpperLimit);

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        
        //Buy
        if(sender == uniswapV2Pair && !isExcludedFromFees[recipient]) {
            require(launchedAt > 0);

            uint256 buyFee = amount.mul(totalBuyFees).div(100);
            super._transfer(sender, address(this), buyFee);
            amount = amount.sub(buyFee);
            buyFeeTokensToSwap = buyFeeTokensToSwap.add(buyFee);

            if(!isExcludedFromLimit[recipient]){
                require(amount <= maxBuyTransaction, "Buy exceeded max transaction value");
                require(balanceOf(recipient).add(amount) <= maxWallet, "Buy exceeded max wallet value");
            }
         
            if(buyFeeTokensToSwap > minimumTokensBeforeSwap && swapAndLiquifyEnabledOnBuy) {
                if(swapUpperLimitOnBuyEnabled){
                    bool success = swapBack(swapOnBuyUpperLimit, buyLiquidityFee, buyBuybackFee, totalBuyFees);

                    if(success)
                        buyFeeTokensToSwap = buyFeeTokensToSwap.sub(swapOnBuyUpperLimit);
                }

                else{
                    bool success = swapBack(buyFeeTokensToSwap, buyLiquidityFee, buyBuybackFee, totalBuyFees);
                
                    if(success)
                        buyFeeTokensToSwap = 0;
                }
            }

        super._transfer(sender, recipient, amount);

        }
        
        //Sell
        else if(recipient == uniswapV2Pair && !isExcludedFromFees[sender]) {
            uint256 sellFee = amount.mul(totalSellFees).div(100);
            super._transfer(sender, address(this), sellFee);
            amount = amount.sub(sellFee);
            sellFeeTokensToSwap = sellFeeTokensToSwap.add(sellFee);

            if(!isExcludedFromLimit[sender]){
                require(amount <= maxSellTransaction, "Sell exceeded max transaction value");
            }

            if(sellFeeTokensToSwap > minimumTokensBeforeSwap && swapAndLiquifyEnabledOnSell) {
                if(swapUpperLimitOnSellEnabled){
                    bool success = swapBack(swapOnSellUpperLimit, sellLiquidityFee, sellBuybackFee, totalSellFees);

                    if(success)
                        sellFeeTokensToSwap = sellFeeTokensToSwap.sub(swapOnSellUpperLimit);
                }

                else{
                    bool success = swapBack(sellFeeTokensToSwap, sellLiquidityFee, sellBuybackFee, totalSellFees);
                
                    if(success)
                        sellFeeTokensToSwap = 0;
                }
            }
        super._transfer(sender, recipient, amount);

        }

        else{
        super._transfer(sender, recipient, amount);
        }
    }


    function withdrawForeignToken(address _tokenContract, uint256 _amount)
        external
    {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);

        emit WithdrawForeignToken(_tokenContract, _amount);

    }
    
    event WithdrawForeignToken(address TokenContract, uint256 amount);

    function forceSwap() public onlyOwner {

        uint256 amount = balanceOf(address(this));
        uint256 liqFee = buyLiquidityFee.add(sellLiquidityFee);
        uint256 bbFee = buyBuybackFee.add(sellBuybackFee);
        uint256 totalFee = totalBuyFees.add(totalSellFees);

        buyFeeTokensToSwap = 0;
        sellFeeTokensToSwap = 0;

        swapBack(amount, liqFee, bbFee, totalFee);
    
        emit ForceSwapBack(amount);

    }
    
    event ForceSwapBack(uint256 amount);

    function swapBack(uint256 amount, uint256 liquidityFee, uint256 buybackFee, uint256 totalFee) internal returns (bool) {

        uint256 tokensToLiquify = amount;
        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;

        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBBuyback = amountBNB.mul(buybackFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.sub(amountBNBLiquidity).sub(amountBNBBuyback);

        (bool tmpSuccess,) = payable(marketingWallet).call{value: amountBNBMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(buybackWallet).call{value: amountBNBBuyback, gas: 30000}("");

        // only to supress warning msg
        tmpSuccess = false;
       

        if(amountToLiquify > 0){
            uniswapV2Router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                address(this),
                block.timestamp
            );
        }

        return true;
    }

}