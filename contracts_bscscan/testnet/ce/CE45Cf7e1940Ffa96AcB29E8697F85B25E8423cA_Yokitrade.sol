/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

pragma solidity 0.8.7; /*

___________________________________________________________________



=== 'YOKI' Trade contract is a suppliment of 'YOKI' Token contract with following features ===
    => Buy/sell functions for yoki coin
    => Pulls buy and sell price from the liquidity pool on pancakeswap
    => Updated accurate prices from the pancakeswap 

============= Independant Audit of the code ============
    => Multiple Freelance Auditors
    => Community Audit by Bug Bounty program


-------------------------------------------------------------------
 Copyright (c) 2021 onwards Yoki Coin Inc. ( https://Yokicoin.com )
 Contract designed with ❤ by EtherAuthority ( https://EtherAuthority.io )
 SPDX-License-Identifier: MIT
-------------------------------------------------------------------
*/ 




//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }
    
    //this is to give up the ownership completely. All owner functions will stop
    function renounceOwnership() external onlyOwner{
        owner = payable(0);
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = payable(0);
    }
}



 //****************************************************************************//
//---------------------        BEP20 Token Interface      ---------------------//
//****************************************************************************//

interface IBEP20{
    function decimals() external view returns(uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

 //****************************************************************************//
//---------------------        Pancake Pair Interface      ---------------------//
//****************************************************************************//
interface IPancakePair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

 //****************************************************************************//
//---------------------        Pancake Router Interface      ---------------------//
//****************************************************************************//
interface IPancakeRouter {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

 //****************************************************************************//
//---------------------        Yoki Token Interface      ---------------------//
//****************************************************************************//
interface IYokiToken {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function totalSupply() external view returns (uint256);
    function tradeTransfer(address _from,  address _to, uint256 amount ) external returns(bool);
}

    
    


//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract Yokitrade is owned {

    /*************************************/
    /*  Section for Buy/Sell of tokens   */
    /*************************************/
    address public yokiAddress;
    address public routerAddress;
    address public lpAddress;
    address public busdWallet;
    uint256 private _totalSupply;
    event TokenBought(address buyer, uint256 yoki, uint256 busd, uint256 tokenPrice);
    event TokensSold(address seller, uint256 yoki, uint256 busd, uint256 tokenPrice);

    
    constructor(address _yokiAddress, address _routerAddress, address _lpAddress, address _busdWallet){
        yokiAddress = _yokiAddress;
        routerAddress = _routerAddress;
        lpAddress = _lpAddress;
        busdWallet = _busdWallet;
        _totalSupply = IYokiToken(yokiAddress).totalSupply();
    }
    
// This function calls lp pair and checks for the current price of YOKI token in BUSD
    function getSellPrice(uint256 tokenAmount) public view returns(uint256){
        uint256 price;
        address token0 = IPancakePair(lpAddress).token0();

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPancakePair(lpAddress).getReserves();
        if(token0 == address(this)){
            price = IPancakeRouter(routerAddress).getAmountOut(tokenAmount, reserve0, reserve1);
            return price;
        }
        price = IPancakeRouter(routerAddress).getAmountOut(tokenAmount, reserve1, reserve0);
        return price;
    }
    
    function getBuyPrice(uint256 tokenAmount) public view returns(uint256){
        uint256 price;
        address token0 = IPancakePair(lpAddress).token0();
        
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPancakePair(lpAddress).getReserves();
        if(token0 == address(this)){
            price = IPancakeRouter(routerAddress).getAmountIn(tokenAmount, reserve1, reserve0);
            return price;
        }
        price = IPancakeRouter(routerAddress).getAmountIn(tokenAmount, reserve0, reserve1);
        return price;
    }
    
   
    
    /**
     * Buy tokens using BUSD
     */
    
    function buyTokens(uint256 yokiAmount) external {
        require(yokiAmount <= _totalSupply, "amount can not be more than total supply");
        uint256 pricePerUnit = getBuyPrice(1e18);
        uint256 busdAmount = getBuyPrice(yokiAmount);
        
        IBEP20(busdWallet).transferFrom(msg.sender, yokiAddress, busdAmount);     //cut BUSD from user
        IYokiToken(yokiAddress).tradeTransfer(yokiAddress, msg.sender, yokiAmount);    // makes the transfers

        emit TokenBought(msg.sender, yokiAmount, busdAmount, pricePerUnit );
    }

    /**
     * Sell `amount` tokens to contract
     * user will get BUSD as per the token price. 
     * contract must have enough BUSD for this to work
     */
    function sellTokens(uint256 yokiAmount) external {
        require(yokiAmount <= _totalSupply, "amount can not be more than total supply");
        uint256 pricePerUnit = getSellPrice(1e18);
        uint256 busdAmount = getSellPrice(yokiAmount);
        
        IYokiToken(yokiAddress).tradeTransfer(msg.sender, yokiAddress, yokiAmount);    // makes the transfers
        IBEP20(busdWallet).transfer(msg.sender, busdAmount);        // send BUSD to user
        
        emit TokensSold(msg.sender, yokiAmount, busdAmount, pricePerUnit);
        
    }
    
    /**
     * set BUSD wallet
     */
    function setBUSDwallet(address _busdWallet) onlyOwner external{
        require(_busdWallet != address(0), "Invalid address");
        busdWallet = _busdWallet;
    }
    /**
     * set lp
     */
    function setLP(address _lp) onlyOwner external{
        require(_lp != address(0), "Invalid address");
        lpAddress = _lp;
    }
    /**
     * set router
     */
    function setRouter(address _router) onlyOwner external{
        require(_router != address(0), "Invalid address");
        routerAddress = _router;
    }
    

}