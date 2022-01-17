pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

import "./BEP20.sol";
import "./Ownable.sol";
import "./Token.sol";

contract Seed_Token is BEP20, Ownable {
    constructor(address teamAddress_, address NFTAddress_, address marketingAddress_) BEP20("SEEDS", "SEED$") {
        _mint(msg.sender, 1e29);

        teamAddress = teamAddress_;
        NFTtokenAddress = NFTAddress_;
        marketingAddress = marketingAddress_;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         //@dev Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
        
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        isPair[uniswapV2Pair] = true;
    }
    
    function setBPAddrss(address _bp) public onlyOwner {
        require(address(BP)== address(0), "Can only be initialized once");
        BP = BPContract(_bp);
    }
    
    function setBpEnabled() public onlyOwner {
        bpEnabled = true;
    }
    
    function setBotProtectionDisableForever() public onlyOwner {
        require(BPDisabledForever == false);
        BPDisabledForever = true;
    }
    
    // function to allow admin to enable trading..
    function enabledTrading() public onlyOwner {
        require(!tradingEnabled, "SEED$: Trading already enabled..");
        tradingEnabled = true;
        liquidityAddedAt = block.timestamp;
    }
    
    // function to allow admin to remove an address from fee..
    function excludedFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    // function to allow admin to add an address for fees..
    function includedForFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
    // function to allow users to check ad address is it an excluded from fee or not..
    function _isExcludedFromFee(address account) public view returns (bool) {
        return isExcludedFromFee[account];
    }
    
    // function to allow users to check an address is pair or not..
    function _isPairAddress(address account) public view returns (bool) {
        return isPair[account];
    }
    
    // function to allow admin to add an address on pair list..
    function addPair(address pairAdd) public onlyOwner {
        isPair[pairAdd] = true;
    }
    
    // function to allow admin to remove an address from pair address..
    function removePair(address pairAdd) public onlyOwner {
        isPair[pairAdd] = false;
    }
    
    // function to allow admin to set team address..
    function setTeamAddress(address teamAdd) public onlyOwner {
        teamAddress = teamAdd;
    }
    
    // function to allow admin to set NFT token contract adress..
    function setNFTAddress(address NFTAdd) public onlyOwner {
        NFTtokenAddress = NFTAdd;
    }
    
    // function to allow admin to set Marketing Address..
    function setMarketingAddress(address marketingAdd) public onlyOwner {
        marketingAddress = marketingAdd;
    }
    
    // function to allow admin to add an address on blacklist..
    function addOnBlacklist(address account) public onlyOwner {
        require(!isBlacklisted[account], "Already added..");
        require(canBlacklistOwner, "No more blacklist");
        isBlacklisted[account] = true;
    }
    
    // function to allow admin to remove an address from blacklist..
    function removeFromBlacklist(address account) public onlyOwner {
        require(isBlacklisted[account], "Already removed..");
        isBlacklisted[account] = false;
    }
    
    // function to allow admin to stop adding address to blacklist..
    function stopBlacklisting() public onlyOwner {
        require(canBlacklistOwner, "Already stoped..");
        canBlacklistOwner = false;
    }
    
    // function to allow admin to set maximum Tax amout..
    function setMaxTaxAmount(uint256 amount) public onlyOwner {
        maxTaxAmount = amount;
    }
    
    // function to allow admin to set all fees..
    function setFees(uint256 sellTeamFee_, uint256 sellLiquidityFee_, uint256 buyTeamFee_, uint256 buyLiquidityFee_, uint256 marketingFeeWhenNoNFTs_, uint256 teamFeeWhenNoNFTs_, uint256 liquidityFeeWhenNoNFTs_) public onlyOwner {
        require(sellTeamFee_ <= 15000 || sellLiquidityFee_ <= 15000 || buyTeamFee_ <= 15000 || buyLiquidityFee_ <= 15000, "Please enter less then 15% fee..");
        _sellTeamFee = sellTeamFee_;
        _sellLiquidityFee = sellLiquidityFee_;
        _buyTeamFee = buyTeamFee_;
        _buyLiquidityFee = buyLiquidityFee_;
        _MarketingFeeWhenNoNFTs = marketingFeeWhenNoNFTs_;
        _TeamFeeWhenNoNFTs = teamFeeWhenNoNFTs_;
        _LiquidityFeeWhenNoNFTs = liquidityFeeWhenNoNFTs_;
    }
    
    // function to allow admin to enable Swap and auto liquidity function..
    function enableSwapAndLiquify() public onlyOwner {
        require(!swapAndLiquifyEnabled, "Already enabled..");
        swapAndLiquifyEnabled = true;
    }
    
    // function to allow admin to disable Swap and auto liquidity function..
    function disableSwapAndLiquify() public onlyOwner {
        require(swapAndLiquifyEnabled, "Already disabled..");
        swapAndLiquifyEnabled = false;
    }
    
    // function to allow admin to disable the NFT fee that take if sender don't have NFT's..
    function disableNFTFee() public onlyOwner {
        isNoNFTFeeWillTake = false;
    }
    
    // function to allow admin to set first 5 block buy & sell fee..
    function setFirst_5_Block_Buy_Sell_Fee(uint256 _fee) public onlyOwner {
        first_5_Block_Buy_Sell_Fee = _fee;
    }

    function burn(uint256 amount) public {
        require(amount > 0, "SEED: amount must be greater than 0");
        _burn(msg.sender, amount);
    }
    
    // function to allow admin to transfer *any* BEP20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "SEED: amount must be greater than 0");
        require(recipient != address(0), "SEED: recipient is the zero address");
        require(tokenAddress != address(this), "SEED: Not possible to transfer SEED$");
        Token(tokenAddress).transfer(recipient, amount);
    }
    
    // function to allow admin to transfer BNB from this contract..
    function transferBNB(uint256 amount, address payable recipient) public onlyOwner {
        recipient.transfer(amount);
    }

    receive() external payable {
        
    }
}