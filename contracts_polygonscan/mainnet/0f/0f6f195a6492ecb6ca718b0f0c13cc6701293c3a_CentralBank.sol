/**
 *Submitted for verification at polygonscan.com on 2021-08-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

contract CentralBank{
    address public owner = msg.sender;
    address public dev;
    uint256 public fee; // 10 = 0.1%, 100 = 1%
    address public Matic;

    address zeroAddress = 0x0000000000000000000000000000000000000000;
    
    constructor(address _dev, uint256 _fee, address _Matic) {
        dev = _dev;
        fee = _fee;
        Matic = _Matic;
    }

    address private constant UNISWAP_V2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Quickswap router address
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH token
    
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    
    
    //--- Pools Data
    struct Pools { 
      uint256 poolsId;
      uint256 balanceMaster;
      uint256 balanceOfPools;
      address manager;
    }
    Pools[] private _Pools;
    mapping(uint256 => Pools) public PoolsInfo;
    uint256 public poolsLength = 0;
    
    
    //--- AssetsToTrade Data
    struct AssetToTrade { 
      address assetsAddress;
    }
    AssetToTrade[] private _AssetToTrade;
    mapping(address => AssetToTrade) public AssetToTradeInfo;
    uint256 public assetsLength = 0;


    //--- Function
    function addPools(uint256 _balance) external {
        
        IERC20(Matic).transferFrom(msg.sender, address(this), _balance);
        
        poolsLength++;
    	
    	// push data to array struct
    	_Pools.push(Pools(poolsLength, _balance, _balance, msg.sender));
    	
    	// push for view data
    	PoolsInfo[poolsLength] = Pools(poolsLength, _balance, _balance, msg.sender);

    	
    }

    
    function removePools(uint256 _poolsId) external onlyOwner {
        poolsLength--;
        delete PoolsInfo[_poolsId];
    }
    
    function addAssetsToTrade(address _tokenAddress) external onlyOwner {
        assetsLength++;
    	
    	// push data to array struct
    	_AssetToTrade.push(AssetToTrade(_tokenAddress));
    	
    	// push for view data
    	AssetToTradeInfo[_tokenAddress] = AssetToTrade(_tokenAddress);
        //AssetToTrade.push(_tokenAddress);
    }
    
    function totalAssetsToTrade() external view returns(uint256){
        return assetsLength;
    }
    function removeAssets(address _assetsAddress) external onlyOwner {
        assetsLength--;
        delete AssetToTradeInfo[_assetsAddress];
    }
    
    
    function testInvest(address _investToAssets) external view returns(bool) {
        require(AssetToTradeInfo[_investToAssets].assetsAddress == _investToAssets, "Asset not allow to invest.");
        return true;
    }
    
    function sendFeeToDev(address _token0, uint256 _value) internal {
        uint256 feeToDev = (_value * fee) / 1000;
        IERC20(_token0).transfer(dev, feeToDev);
    }


    // Investing stable coin
    function investToCoin(
        address _tokenIn, 
        address _tokenOut, 
        uint256 _amountIn, 
        uint256 _amountOutMin
    ) external {
        require(AssetToTradeInfo[_tokenIn].assetsAddress == _tokenIn, "Asset not allow to invest.");
        
        address _to = address(this);

        //IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
          path = new address[](2);
          path[0] = _tokenIn;
          path[1] = _tokenOut;
        } else {
          path = new address[](3);
          path[0] = _tokenIn;
          path[1] = WETH;
          path[2] = _tokenOut;
        }
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
        // send fee to dev
        sendFeeToDev(_tokenIn, _amountIn);
        
    }
    
}