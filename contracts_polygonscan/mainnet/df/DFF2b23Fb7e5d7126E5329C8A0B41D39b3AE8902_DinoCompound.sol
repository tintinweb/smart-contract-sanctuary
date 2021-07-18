/**
 *Submitted for verification at polygonscan.com on 2021-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;



interface IUniswapV2Pair {
    
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);


}

interface ERC20 {
    
    function balanceOf(address account) external view returns (uint256) ;
    
    function transfer(address recipient, uint256 amount) external returns (bool) ;
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);

    
}

interface IUniswapV2ERC20 {
    
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    
}

interface IUniswapRouterV2 {
    
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    
}




contract DinoCompound{
    
    address public admin;
    address public auctionAddress = 0x1D86852b823775267eE60D98cbCdA9e8d5C2fAA7; //start out with the diamond address, but can change later
    address public gotchiAddress = 0x86935F11C86623deC8a25696E1C19a8659CbF95d; //this is the diamond address
    address public ghstAddress = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
    
    address public farmAddress = 0x1948abC5400Aa1d72223882958Da3bec643fb4E5;
    address public dinoAddress = 0xAa9654BECca45B5BDFA5ac646c939C62b527D394;
    
    address public usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public ethAddress = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    address public stkGHSTWETHAddress = 0x388E2a3d389F27504212030c2D42Abf0a8188cd1;
    address public ghstStakeAddress = 0xA02d547512Bb90002807499F05495Fe9C4C3943f;
    address public GHSTWETHAddress = 0xcCB9d2100037f1253e6C1682AdF7dC9944498AFF;
    
    address public USDCDINOAddress = 0x3324af8417844e70b81555A6D1568d78f4D4Bf1f;

    address public aavegotchiStakeAddress = 0xA02d547512Bb90002807499F05495Fe9C4C3943f;

    address public quickswapAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    address public sushiAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    //address public

    uint256 internal MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    ERC20 ghst = ERC20(ghstAddress);
    ERC20 dino = ERC20(dinoAddress);
    ERC20 usdc = ERC20(usdcAddress);
    ERC20 eth = ERC20(ethAddress);
    
    ERC20 stkGHSTWETH = ERC20(stkGHSTWETHAddress);
    IUniswapV2ERC20 GHSTWETH = IUniswapV2ERC20(GHSTWETHAddress);
    IUniswapV2ERC20 USDCDINO = IUniswapV2ERC20(USDCDINOAddress);

    IUniswapRouterV2 quickSwap = IUniswapRouterV2(quickswapAddress);
    IUniswapRouterV2 sushiSwap = IUniswapRouterV2(sushiAddress);




    
    function swapDinoToGHSTWETH(uint256 _amount) public {
        dino.transferFrom(msg.sender,address(this),_amount);
        address[] memory path = new address[](2);
            path[0] = dinoAddress;
            path[1] = usdcAddress;
        sushiSwap.swapExactTokensForTokens(dino.balanceOf(address(this)),0,path,address(this),2626531562);
        //sell half of USDC for ghst at Quickswap
        path[0] = usdcAddress;
        path[1] = ghstAddress;
        quickSwap.swapExactTokensForTokens(usdc.balanceOf(address(this))/2,0,path,address(this),2626531562);
        //sell other half of USDC for WETH at Quickswap
        path[0] = usdcAddress;
        path[1] = ethAddress;
        quickSwap.swapExactTokensForTokens(usdc.balanceOf(address(this)),0,path,address(this),2626531562);
        //LP our GHST and WETH
        quickSwap.addLiquidity(ghstAddress,ethAddress,ghst.balanceOf(address(this)),eth.balanceOf(address(this)),0,0,address(this),2626531812);
        
        GHSTWETH.transfer(msg.sender,GHSTWETH.balanceOf(address(this)));
        ReturnFunds(msg.sender);

        
    }


    
    function swapAllDinoToGHSTWETH() public {
        dino.transferFrom(msg.sender,address(this),dino.balanceOf(msg.sender));
        address[] memory path = new address[](2);
            path[0] = dinoAddress;
            path[1] = usdcAddress;
        sushiSwap.swapExactTokensForTokens(dino.balanceOf(address(this)),0,path,address(this),2626531562);
        //sell half of USDC for ghst at Quickswap
        path[0] = usdcAddress;
        path[1] = ghstAddress;
        quickSwap.swapExactTokensForTokens(usdc.balanceOf(address(this))/2,0,path,address(this),2626531562);
        //sell other half of USDC for WETH at Quickswap
        path[0] = usdcAddress;
        path[1] = ethAddress;
        quickSwap.swapExactTokensForTokens(usdc.balanceOf(address(this)),0,path,address(this),2626531562);
        //LP our GHST and WETH
        quickSwap.addLiquidity(ghstAddress,ethAddress,ghst.balanceOf(address(this)),eth.balanceOf(address(this)),0,0,address(this),2626531812);
        
        GHSTWETH.transfer(msg.sender,GHSTWETH.balanceOf(address(this)));
        ReturnFunds(msg.sender);
        
    }
    
    function senderDinoBalance() public view returns(uint256){
        return dino.balanceOf(msg.sender);
    }

    constructor(){
        admin = msg.sender;
        setApprovals();
    }
    
    function setApprovals() public onlyAdmin{
        dino.approve(sushiAddress,MAX_INT);
        usdc.approve(quickswapAddress,MAX_INT);
        eth.approve(quickswapAddress,MAX_INT);
        ghst.approve(quickswapAddress,MAX_INT);
        GHSTWETH.approve(ghstStakeAddress,MAX_INT);
        stkGHSTWETH.approve(farmAddress,MAX_INT);
        USDCDINO.approve(farmAddress,MAX_INT);
    }
    
 
    
    modifier onlyAdmin() {
        require(admin == msg.sender, "onlyAdmin: not admin");
        _;
    }

    
    function changeAdmin(address _admin) public onlyAdmin{ //allows us to change the admin user
        admin = _admin;
    }
    
    function ReturnFunds(address _recipient) internal{
        if(dino.balanceOf(address(this)) > 0){
            dino.transfer(_recipient,dino.balanceOf(address(this)));
        }
        
        if(usdc.balanceOf(address(this)) > 0){
            usdc.transfer(_recipient,usdc.balanceOf(address(this)));
        }
        
        if(eth.balanceOf(address(this)) > 0){
            eth.transfer(_recipient,eth.balanceOf(address(this)));
        }
        
        if(ghst.balanceOf(address(this)) > 0){
            ghst.transfer(_recipient,ghst.balanceOf(address(this)));
        }
        
        if(GHSTWETH.balanceOf(address(this)) > 0){
            GHSTWETH.transfer(_recipient,GHSTWETH.balanceOf(address(this)));
        }
        
        if(USDCDINO.balanceOf(address(this)) > 0){
            USDCDINO.transfer(_recipient,USDCDINO.balanceOf(address(this)));
        }
        
        if(stkGHSTWETH.balanceOf(address(this)) > 0){
            stkGHSTWETH.transfer(_recipient,stkGHSTWETH.balanceOf(address(this)));
        }
    }
    
    function ReturnFunds() public onlyAdmin{
        if(dino.balanceOf(address(this)) > 0){
            dino.transfer(msg.sender,dino.balanceOf(address(this)));
        }
        
        if(usdc.balanceOf(address(this)) > 0){
            usdc.transfer(msg.sender,usdc.balanceOf(address(this)));
        }
        
        if(eth.balanceOf(address(this)) > 0){
            eth.transfer(msg.sender,eth.balanceOf(address(this)));
        }
        
        if(ghst.balanceOf(address(this)) > 0){
            ghst.transfer(msg.sender,ghst.balanceOf(address(this)));
        }
        
        if(GHSTWETH.balanceOf(address(this)) > 0){
            GHSTWETH.transfer(msg.sender,GHSTWETH.balanceOf(address(this)));
        }
        
        if(USDCDINO.balanceOf(address(this)) > 0){
            USDCDINO.transfer(msg.sender,USDCDINO.balanceOf(address(this)));
        }
        
        if(stkGHSTWETH.balanceOf(address(this)) > 0){
            stkGHSTWETH.transfer(msg.sender,stkGHSTWETH.balanceOf(address(this)));
        }
    }
    

    
    
    receive() external payable{
        
    }
    
}