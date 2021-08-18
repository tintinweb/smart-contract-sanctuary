pragma solidity 0.8.5;

// SPDX-License-Identifier: MIT

import "./PancakeRouter.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./IBEP20.sol";

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract MakaSwapper is Ownable, ReentrancyGuard {
    address WETH;   // BNB
    address MAKA;  //MAKA Test 0x9000959a575b05920ed9dd722dcf25b959e8ce5e || Main 0x75b429A3D699e6E711BDBC8C0d00cca6a6da4CfE
    IBEP20 WETH_IBEP20;
    mapping (address => bool) private _whitelistedAddresses; // The list of whitelisted addresses
    
    
    // PANCAKESWAP INTERFACES (For swaps)
    address private _pancakeSwapRouterAddress;
    address private _marketingWalletAddress;
    
    IPancakeRouter02 private _pancakeswapV2Router;
    
    uint8 private _contractFee; //% of each transaction that will sent to Maka contract
    uint8 private _rewardFee; //% of each transaction that will be used for BNB reward pool
    uint8 private _marketingFee; //% of each transaction that will be used for increasing market wallet
    uint8 private _totalFees; //total fees
      
    uint256 private _totalMarketingFeesPooled;
    uint256 private _totalContractFeesPooled;
    uint256 private _totalRewardFeesPooled;
    uint256 private _totalBnbBought;
    uint256 private _totalFeesPooled;
        
    event BoughtWithBnb(address, bool, bool, bool);
    event BoughtWithToken(address, address, bool, bool, bool); //sender, token

    //Router TESTNET: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 || other 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    constructor(address router, address token)  {
        //Router MAINNET: 0x10ed43c718714eb63d5aa57b78b54704e256024e
        MAKA = token;
        _whitelistedAddresses[address(this)] = true;
        setPancakeSwapRouter(router);
        
        _totalMarketingFeesPooled = 0;
        _totalContractFeesPooled = 0;
        _totalRewardFeesPooled = 0;
        _totalBnbBought = 0;
        _totalFeesPooled = 0;
    }
    
    receive() external payable {
        calculateFeesAndBuyTokens(msg.sender, msg.value);
    }
    
    function setPancakeSwapRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(0), "Cannot use the zero address as router address");

        _pancakeSwapRouterAddress = routerAddress; 
        _pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);
        WETH = _pancakeswapV2Router.WETH();
        WETH_IBEP20 = IBEP20(WETH);
    }
    
     function setMarketingWallet(address marketingWallet) public onlyOwner {
        require(marketingWallet != address(0), "Cannot use 0 address for marketing");

        _marketingWalletAddress = marketingWallet; 
    }
    
    function getMarketingWallet() public view returns (address) {
        return _marketingWalletAddress;
    }
    
    function totalBnbBought() public view returns (uint256) {
        return _totalBnbBought;
    }
    
    function totalMarketingFeesPooled() public view returns (uint256) {
        return _totalMarketingFeesPooled;
    }
    
    function totalContractFeesPooled() public view returns (uint256) {
        return _totalContractFeesPooled;
    }
    
    function totalRewardFeesPooled() public view returns (uint256) {
        return _totalRewardFeesPooled;
    }
    
    function totalFeesPooledt() public view returns (uint256) {
        return _totalFeesPooled;
    }

    function getPath(address token0, address token1) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }
    
     function getMakaAddress() public view returns (address) {
        return MAKA;
    }
    
    function getBnbAddress() public view returns (address) {
        return WETH;
    }
    
    // This function applied to the bying contract
    function setFees(uint8 marketingFee, uint8 contractFee, uint8 rewardFee) public onlyOwner {
        require(marketingFee + contractFee + rewardFee <= 18, "Total fees cannot exceed 18%");
        
        _marketingFee = marketingFee;
        _contractFee = contractFee;
        _rewardFee = rewardFee;
        
        // Enforce invariant
        _totalFees = marketingFee + contractFee + rewardFee; 
    }
    
    function getFees() public view returns(uint8, uint8, uint8) {
        return (_marketingFee, _contractFee, _rewardFee);
    }
    
    function calculateFeesAndBuyTokens(address sender, uint256 amount) private {
        // Calculate fee rate
        uint256 feeRate = calculateFeeRate(sender);
        (uint256 feeAmount, uint256 transferAmount) = getFees(feeRate, amount);
        buyTokens(sender, transferAmount, feeAmount);
    }
    
    function calculateFeesAndBuyTokens(IBEP20 token, uint256 amount) external nonReentrant {
        // Calculate fee rate
        uint256 feeRate = calculateFeeRate(msg.sender);
        (uint256 feeAmount, uint256 transferAmount) = getFees(feeRate, amount);
        buyTokensWithToken(token, msg.sender, transferAmount, feeAmount);
    }
    
    function calculateFeeRate(address sender) private view returns(uint256) {
        bool applyFees = !_whitelistedAddresses[sender];
        if (applyFees) {
            return _totalFees;
        }

        return 0;
    }
    
    function getFees(uint256 feeRate, uint256 amount) private pure returns (uint256, uint256) {
        uint256 feeAmount = amount * feeRate / 100;
        uint256 transferAmount = amount - feeAmount;
        
        return (feeAmount, transferAmount);
    }
    
    function buyTokens(address sender, uint transferAmount, uint feeAmount) private {
        require(transferAmount >= 0);
        
        // The amount parameter includes both the liquidity and the reward tokens, we need to find the correct portion for each one so that they are allocated accordingly
        uint256 tokensReservedForReward = feeAmount * _rewardFee / _totalFees;
        uint256 tokensReservedForContract = feeAmount * _contractFee / _totalFees;
        uint256 tokensReservedForMarketing = feeAmount - tokensReservedForReward - tokensReservedForContract;

        bool successfulSentToUser = buyMakaWithBnb(transferAmount, sender);
        
        if (!successfulSentToUser) {
            revert("Something has gone wrong while sending user tokens, operation was reverted");
        }
        
        bool successfulSentToRewards = buyMakaWithBnb(transferAmount, sender);
//      bool bnbSentToContract = WETH_IBEP20.transfer(MAKA, tokensReservedForContract);
//      bool bnbSentToMarketing = WETH_IBEP20.transfer(_marketingWalletAddress, tokensReservedForMarketing);
        
        // Keep track of how many BNB were added to all
        _totalBnbBought += transferAmount;
        _totalContractFeesPooled += tokensReservedForContract;
        _totalRewardFeesPooled += tokensReservedForReward;
        _totalMarketingFeesPooled += tokensReservedForMarketing;
        _totalFeesPooled += feeAmount;
        
        // emit BoughtWithBnb(sender, successfulSentToRewards, bnbSentToContract, bnbSentToMarketing);
        emit BoughtWithBnb(sender, successfulSentToRewards, false, false);
    }
    
    function buyTokensWithToken(IBEP20 token, address sender, uint transferAmount, uint feeAmount)  private {
        require(transferAmount >= 0);
        require(token.allowance(sender, address(_pancakeswapV2Router)) >= transferAmount);
        
        // The amount parameter includes both the liquidity and the reward tokens, we need to find the correct portion for each one so that they are allocated accordingly
        uint256 tokensReservedForReward = feeAmount * _rewardFee / _totalFees;
        uint256 tokensReservedForContract = feeAmount * _contractFee / _totalFees;
        uint256 tokensReservedForMarketing = feeAmount - tokensReservedForReward - tokensReservedForContract;

        bool successfulSentToUser = buyMakaWithToken(tokensReservedForReward, token, sender);
        if (!successfulSentToUser) {
           revert("Something has gone wrong while sending user tokens, operation was reverted");
        }
        bool successfulSentToRewards = buyMakaWithToken(transferAmount, token, sender);
        bool bnbSentToContract = WETH_IBEP20.transfer(MAKA, tokensReservedForContract);
        bool bnbSentToMarketing = WETH_IBEP20.transfer(_marketingWalletAddress, tokensReservedForMarketing);
        
        // Keep track of how many BNB were added to all
        _totalBnbBought += transferAmount;
        _totalContractFeesPooled += tokensReservedForContract;
        _totalRewardFeesPooled += tokensReservedForReward;
        _totalMarketingFeesPooled += tokensReservedForMarketing;
        _totalFeesPooled += feeAmount;
        
        emit BoughtWithToken(sender, address(token), successfulSentToRewards, bnbSentToContract, bnbSentToMarketing);
    }
    
    function extractLeftovers() external onlyOwner {
        require(address(this).balance > 0, "Contract balance is zero");
        WETH_IBEP20.transfer(msg.sender, address(this).balance);
    }
    
    function buyMakaWithBnb(uint amount, address sender) private returns (bool) {
        try _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            getPath(WETH, MAKA),
            sender,
            block.timestamp
        ) {
            return true;
        } catch {
            return false;
        }
    }
    
    function buyMakaWithToken(uint amount, IBEP20 token, address sender) private returns (bool) {
        try _pancakeswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                getPath(address(token), MAKA),
                sender,
                block.timestamp
            ) {
           return true;
        }
        catch {
            return false;
        }
    }
}