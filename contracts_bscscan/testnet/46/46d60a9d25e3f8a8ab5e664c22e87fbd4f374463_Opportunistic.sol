/*SPDX-License-Identifier: MIT*/

pragma solidity ^0.5.0;




import "./FlashLoanReceiverBase.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";





interface IRouter{
    function WETH() external pure returns (address);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function factory() external view returns (address);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IFactory{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


interface IBEP20 {
    
    function approve(address spender, uint256 amount) external returns (bool);
}


contract Opportunistic is FlashLoanReceiverBase{
    
    /**
     * Some variables and events
     */
    
    address payable public owner;
    address public exchangeToken = address(0x158B209faA05CDDde634BD1344C04DB412c3E395); //DAI, BUSD, BAT...ETC
    address[] public routers = [0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0,0xD99D1c33F9fC3444f8101754aBC46c52416550D1,0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3]; 
    address public bnb = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    event SwappedFromBnBToToken(uint amount, uint256 buyPrice, address buyOnSwap);
    event SwappedFromTokenToBnB(uint amount, uint sellPrice, address soldOnSwap);
    
    
    constructor(ILendingPoolAddressesProvider _addressesProvider) FlashLoanReceiverBase(_addressesProvider) public {
        owner = msg.sender;
    }

  
  
    
    
    function setExchangeToken(address _exchangeToken) external returns(bool){
        require(msg.sender == owner, "You are not the owner");
        exchangeToken = _exchangeToken;
        return true;
    }
   
    function addRouter(address _router) external returns(bool added, address){
        require(msg.sender == owner, "You are not the owner");
        routers.push(_router);
        return(true, _router);
    }
    
    function getUtilAddresses(address routerAddress) public view returns(address[] memory){
        address[] memory paths = new address[](4);
        paths[0] = IRouter(routerAddress).WETH();
        paths[1] = IRouter(routerAddress).factory();
        paths[2] = IFactory(paths[1]).getPair(paths[0], exchangeToken);
        paths[3] = IPair(paths[2]).token0();
        return paths;
    }
    
    
    
    /**
     * Get selling price of 1 bnb
     */
    function getSellPrice(address routerAddress, uint256 tokenAmount) public view returns(uint256){
        uint256 price;
        address[] memory paths = new address[](4);
        paths = getUtilAddresses(routerAddress);

        (uint112 reserve0, uint112 reserve1,) = IPair(paths[2]).getReserves();
        if(paths[3] == paths[0]){
            price = IRouter(routerAddress).getAmountOut(tokenAmount, reserve1, reserve0);
            return price;
        }
        price = IRouter(routerAddress).getAmountOut(tokenAmount, reserve0, reserve1);
        return price;
    }
    
    /**
     * Get buying price of 1 bnb
     */
    function getBuyPrice(address routerAddress, uint256 tokenAmount) public view returns(uint256){
        uint256 price;
        address[] memory paths = new address[](4);
        paths = getUtilAddresses(routerAddress);

        (uint112 reserve0, uint112 reserve1,) = IPair(paths[2]).getReserves();
        if(paths[3] == paths[0]){
            price = IRouter(routerAddress).getAmountIn(tokenAmount, reserve0, reserve1);
            return price;
        }
        price = IRouter(routerAddress).getAmountIn(tokenAmount, reserve1, reserve0);
        return price;
    }
    
    /**
     * Checking for minBuyPrice and maxSellPrice for a given pair on the given swaps
     */
    function checkAllSwapsAndGetProfitSpread(uint256 tokenAmount) public view returns(uint256, address, address, uint256, uint256){

        uint256 price0 = getBuyPrice(routers[0], tokenAmount);
        uint256 price1 = getSellPrice(routers[0], tokenAmount);
        
        uint256 maxSellPrice = price1;
        uint256 minBuyPrice = price0;
        uint32 sellIndex;
        uint32 buyIndex;
        for(uint32 i = 0; i < routers.length; i++){
            if(getSellPrice(routers[i], tokenAmount) > maxSellPrice){
                maxSellPrice = getSellPrice(routers[i], tokenAmount);
                sellIndex = i;
            }
            if(getBuyPrice(routers[i], tokenAmount) < minBuyPrice){
                minBuyPrice = getBuyPrice(routers[i], tokenAmount);
                buyIndex = i;
            }
        }
        if(minBuyPrice < maxSellPrice){
            uint256 _margin = maxSellPrice - minBuyPrice;
            return (_margin, routers[buyIndex], routers[sellIndex], minBuyPrice, maxSellPrice);
        }
        return (0, routers[buyIndex], routers[sellIndex], minBuyPrice, maxSellPrice);
    }
    
    function executeSwapOnProfit(uint256 _forAmount) internal{
        
        (uint256 margin, address buyOn, address sellOn, uint256 minBuyPrice, uint256 maxSellPrice) = checkAllSwapsAndGetProfitSpread(_forAmount);
        require(margin > 0, "You missed the window!");
        
        require(IBEP20(IRouter(buyOn).WETH()).approve(address(buyOn), minBuyPrice), 'approve failed.');
        address[] memory path = new address[](2);
        path[0] = IRouter(buyOn).WETH();
        path[1] = address(exchangeToken);
        
        IRouter(buyOn).swapETHForExactTokens.value(minBuyPrice)(_forAmount, path, address(this), block.timestamp+100);
        emit SwappedFromBnBToToken(_forAmount, minBuyPrice, buyOn);

        
        require(IBEP20(exchangeToken).approve(address(sellOn), _forAmount), 'approve failed.');
        
        path = new address[](2);
        path[0] = address(exchangeToken);
        path[1] = IRouter(sellOn).WETH();
        
        IRouter(sellOn).swapExactTokensForETH(_forAmount, maxSellPrice, path, address(this), block.timestamp+100);
        emit SwappedFromTokenToBnB(_forAmount, maxSellPrice, sellOn);
    }
    
    function getFlashLoanAndDoArbitrage(uint _forAmount) external{
        require(msg.sender == owner, "You are not the owner");
        
        (uint margin,,,,) = checkAllSwapsAndGetProfitSpread(_forAmount);
        
        require(margin > 0 , "Not much to earn, try again");
        flashloan(_forAmount);
        
    }
    
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");

        (uint amount) = abi.decode(_params, (uint));
        executeSwapOnProfit(amount);
        // Time to transfer the funds back
        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }
    
    function flashloan(uint _forAmount) public {
        require(msg.sender == owner, "You are not the owner");
        bytes memory data = abi.encode(_forAmount);
        uint amount = _forAmount;
        address asset = address(bnb); // mainnet BNB
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), asset, amount, data);
    }
    
    
    
    
    // receive and rescue BNB
    function receive() external payable{}

    function rescueBNB(uint256 amount) external {
        msg.sender.transfer(amount);
    }
    
    
    
    
    
    
   
}