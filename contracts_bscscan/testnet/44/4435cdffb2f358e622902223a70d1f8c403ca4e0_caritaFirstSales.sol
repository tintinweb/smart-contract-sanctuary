/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
        
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
}

contract caritaFirstSales {

    address public owner = 0xF53c251ACbfc7Df58A2f47F063af69A3ED897042;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    address public tokenAddress = 0x867B6c58B5fBFbF0a74220c36Ef2310Ab3d4a268;
    address public lpContractAddress = 0x9167F481BE90DfCC29Ef5351F60C2B0466590019;
    address public pairAddress = 0x9167F481BE90DfCC29Ef5351F60C2B0466590019;
    address private WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    uint256 public tokensSold;
    uint256 public bnbAvailableForLiquidity = address(this).balance;
    bool public liquidityTrigger;
    uint256 public liquidityThreshold = 10000000000000000;
    bool public needToBuyLiquidity;
    address private routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;  
    IPancakeRouter02 pancakeRouter = IPancakeRouter02 (routerAddress);
    uint256 public realTimeLiquidityPotential;
    uint256 public realTimeBalanceToken;
    bool public isTooLargeInput;


    IBEP20 public tokenContract = IBEP20(tokenAddress);  // the token being sold
    IBEP20 public lpContract = IBEP20(lpContractAddress);
    IBEP20 public wbnbContract = IBEP20(WBNB);

    event Sold(address buyer, uint256 amount);
    event LiquidityBuyTriggered();
    event AwaitForMoreBnb();
    event tooLargeInput();

    receive() payable external {}

    function approveAllTokens () public {

        uint maxApprovationAmount = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        tokenContract.approve(routerAddress, maxApprovationAmount);
        wbnbContract.approve(routerAddress, maxApprovationAmount);
        lpContract.approve(routerAddress, maxApprovationAmount);
        tokenContract.approve(pairAddress, maxApprovationAmount);
        wbnbContract.approve(pairAddress, maxApprovationAmount);
        lpContract.approve(pairAddress, maxApprovationAmount);

    }
    
    // Guards against integer overflows
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    function getEstimatedTokenForBNB(uint WeiAmount) public view returns (uint[] memory bnbQuote) {

        bnbQuote = pancakeRouter.getAmountsIn(WeiAmount, getPathForTokenToBNB());
  }

  function updateLiquidityTrigger() public {
      
      if( address(this).balance > liquidityThreshold){liquidityTrigger = true;}
      else{liquidityTrigger = false;}

  }

  function  checkContractBalances() public {

      realTimeBalanceToken = tokenContract.balanceOf(address(this));
      realTimeLiquidityPotential = getEstimatedTokenForBNB(address(this).balance)[0];
      if(realTimeBalanceToken > realTimeLiquidityPotential){needToBuyLiquidity = false;}
      else{needToBuyLiquidity = true;}
  }

  function getPathForTokenToBNB() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = tokenAddress;
    path[1] = WBNB;
    
    return path;
  }


    function adjustLiquidityThreshold( uint256 _newThreshold) public onlyOwner {
        liquidityThreshold = _newThreshold;
    }

    function checkAmountValidity (uint256 amoutToCheck) internal view returns (bool testOk) {

        try pancakeRouter.getAmountsIn(amoutToCheck, getPathForTokenToBNB()) {return testOk = true;} 
        catch {return testOk = false;}

    }

    function buyPublicLiquidity (uint amountOfBnbToSell) public onlyOwner {

            if(checkAmountValidity(amountOfBnbToSell) == true){
                
                pancakeRouter.addLiquidityETH{value: amountOfBnbToSell}(
                tokenAddress,
                realTimeBalanceToken,
                0,
                0,
                0xE13F7785ad6f6E0F286745736084Aab332Fa49Dc,
                block.timestamp + 360
                );
            }

            else{
                
            pancakeRouter.addLiquidityETH{value: liquidityThreshold}(
            tokenAddress,
            realTimeBalanceToken,
            0,
            0,
            0xE13F7785ad6f6E0F286745736084Aab332Fa49Dc,
            block.timestamp + 360
            );
            emit tooLargeInput();
            }
            


    }
    

    function charityBuyForLiquidity(uint _confirmationInWei) public payable {

        uint numberOfTokens;
        require(msg.sender != tokenAddress, "Can t come from token");
        require(_confirmationInWei <= msg.value, "Not enought BNB sent");

        checkContractBalances();  
        if(needToBuyLiquidity == true) {
            emit LiquidityBuyTriggered();
            buyPublicLiquidity(liquidityThreshold);
        }
        if(checkAmountValidity(_confirmationInWei) == true){

            numberOfTokens = (getEstimatedTokenForBNB(_confirmationInWei))[0];
            require(numberOfTokens > 0, "Output is zero");

            emit Sold(msg.sender, numberOfTokens);
            tokensSold += numberOfTokens;
        }

        else{

            numberOfTokens = (getEstimatedTokenForBNB(liquidityThreshold))[0];
            require(numberOfTokens > 0, "Output is zero");

            emit tooLargeInput();
            emit Sold(msg.sender, numberOfTokens);
            tokensSold += numberOfTokens;
        }

        require(tokenContract.transfer(msg.sender, numberOfTokens));

        updateLiquidityTrigger();

        if (liquidityTrigger == true){

            emit LiquidityBuyTriggered();
            buyPublicLiquidity(bnbAvailableForLiquidity);

        }else{ 

            emit AwaitForMoreBnb();
        }
    }

    function endSale() public onlyOwner {

        // Send unsold tokens to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));

        payable(msg.sender).transfer(address(this).balance);
    }

    function setRouterAddress(address newRouter) public {
        require(msg.sender == owner, "Sender not authorized");
        routerAddress = newRouter;
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }


}