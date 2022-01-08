pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
import "./Token.sol";

contract Seed_Token is ERC20, Ownable {
    uint256 public NFTs;
    constructor() ERC20("SEED", "SEED$") {
        _mint(msg.sender, 1e27);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         //@dev Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
        
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        isPair[_msgSender()] = true;
    }

    function enabledTrading() public onlyOwner {
        require(!tradingEnabled, "SEED$: Trading already enabled..");
        tradingEnabled = true;
        liquidityAddedAt = block.timestamp;
    }
    
    function excludedFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function includedForFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
    function _isExcludedFromFee(address account) public view returns (bool) {
        return isExcludedFromFee[account];
    }
    
    function addPair(address pairAdd) public onlyOwner {
        isPair[pairAdd] = true;
    }
    
    function removePair(address pairAdd) public onlyOwner {
        isPair[pairAdd] = false;
    }

    function setFees(uint256 sellTeamFee_, uint256 sellLiquidityFee_, uint256 buyTeamFee_, uint256 buyLiquidityFee_, uint256 marketingFee_, uint256 teamFeeWhenNoNFTs_, uint256 liquidityFeeWhenNoNFTs_) public onlyOwner {
        require(sellTeamFee_ <= 15000 || sellLiquidityFee_ <= 15000 || buyTeamFee_ <= 15000 || buyLiquidityFee_ <= 15000, "Please enter less then 15% fee..");
        _sellTeamFee = sellTeamFee_;
        _sellLiquidityFee = sellLiquidityFee_;
        _buyTeamFee = buyTeamFee_;
        _buyLiquidityFee = buyLiquidityFee_;
        _MarketingFee = marketingFee_;
        _TeamFeeWhenNoNFTs = teamFeeWhenNoNFTs_;
        _LiquidityFeeWhenNoNFTs = liquidityFeeWhenNoNFTs_;
    }
    
    // function to allow admin to transfer *any* ERC20 tokens from this contract
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "SEED: amount must be greater than 0");
        require(recipient != address(0), "SEED: recipient is the zero address");
        require(tokenAddress != address(this), "SEED: Not possible to transfer SEED$");
        Token(tokenAddress).transfer(recipient, amount);
    }
}