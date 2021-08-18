/**
 *Submitted for verification at polygonscan.com on 2021-08-18
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
  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
}

/* IUniswapV2Pair interface */
interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

/* Factory Interface */
interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}

/* =============================== */
contract ROBOFactory{
    FundOfMaster[] public createFunds;
    
    function createFund() public {
        
        FundOfMaster fundAdd = new FundOfMaster(address(this), msg.sender, 0, 0);
        createFunds.push(fundAdd);

        //address(fundAdd);
    }
    function fundLength() public view returns(uint256){
        return createFunds.length;
    }

}
contract FundOfMaster{
    address public owner;
    address public master;
    uint256 public masterBalance;
    uint256 public fundBalance;
    
    constructor(address _owner, address _master, uint256 _masterBalance, uint256 _fundBalance) {
        owner = _owner;
        master = _master;
        masterBalance = _masterBalance;
        fundBalance = _fundBalance;
    }
}
/* =============================== */

contract ROBOBank{
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner = msg.sender;
    address public dev;
    uint256 public feeMasterTransaction; // 10 = 0.1%, 100 = 1%
    uint256 public feeWithdraw; // 10 = 0.1%, 100 = 1%
    uint256 public feeRegisterMaster; // WETH
    uint256 public feeRegisterCopyTrade; // WETH
    address public UNISWAP_V2_ROUTER; // 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Quickswap router address
    address public WETH; // WMATIC with 18 decimal, USDT with 6 decimal.
    

    address zeroAddress = 0x0000000000000000000000000000000000000000;
    
    function BankSetting(
        address _dev, 
        uint256 _feeMasterTransaction, 
        uint256 _feeWithdraw, 
        uint256 _feeRegisterMaster, 
        uint256 _feeRegisterCopyTrade, 
        address _UNISWAP_V2_ROUTER, 
        address _WETH
    ) public {
        dev = _dev;
        feeMasterTransaction = _feeMasterTransaction;
        feeWithdraw = _feeWithdraw;
        feeRegisterMaster = _feeRegisterMaster;
        feeRegisterCopyTrade = _feeRegisterCopyTrade;
        UNISWAP_V2_ROUTER = _UNISWAP_V2_ROUTER;
        WETH = _WETH;
    }


    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    /* ****************************************************************************************************************************************** */
    
    /*
    *********************************************************************
    *-------------------------   Store Data   ---------------------------
    *********************************************************************
    */
    
    /* ----------------   AssetsToTrade Storage   ------------------ */
    struct AssetToTrade { 
      address assetsAddress;
    }
    AssetToTrade[] private _AssetToTrade;
    mapping(address => AssetToTrade) public AssetToTradeInfo;
    uint256 public assetsLength = 0;
    

     /* ----------------   Manager Pools Storage   ------------------ */
    struct Pools { 
      uint256 poolsId;
      uint256 balanceMaster;
      uint256 balanceOfPools;
      address manager;
    }
    Pools[] private _Pools;
    mapping(uint256 => Pools) public PoolsInfo;
    uint256 public poolsLength = 0;
    
    
    /* ----------------   Follower Storage   ------------------ */
    struct FollowerFund { 
        uint256 followId;
        uint256 poolsId;
        uint256 balanceFollower;
        address follower;
    }
    FollowerFund[] private _FollowerFund;
    mapping(uint256 => FollowerFund) public FollowerFundInfo;
    uint256 public followerLength = 0;
    
    /* ****************************************************************** */
    
    /* ****************************************************************** */
    /*------------------------   All Function   -------------------------/
    /* ****************************************************************** */
    
    /* ----------------   AssetsToTrade Function   ------------------ */
    /* 
    * Assets to Trade - List of assets.
    * @dev after deploy code you should add Assets in list for trade
    */
    function addAssetsToTrade(address _tokenAddress) public onlyOwner {
        assetsLength++;
    	
    	// push data to array struct
    	_AssetToTrade.push(AssetToTrade(_tokenAddress));
    	
    	// push for view data
    	AssetToTradeInfo[_tokenAddress] = AssetToTrade(_tokenAddress);
        //AssetToTrade.push(_tokenAddress);
    }
    
    function totalAssetsToTrade() public view returns(uint256){
        return assetsLength;
    }
    function removeAssets(address _assetsAddress) public onlyOwner {
        assetsLength--;
        delete AssetToTradeInfo[_assetsAddress];
    }


    /* ----------------   beComeToMaster Function   ------------------ */
    function beComeToMaster(uint256 _balance) public {
        
        uint256 realBalance = _balance - ((_balance * feeMasterTransaction) / 1000);
        
        poolsLength++;
    	
    	// push data to array struct
    	_Pools.push(Pools(poolsLength, realBalance, realBalance, msg.sender));
    	
    	// push for view data
    	PoolsInfo[poolsLength] = Pools(poolsLength, realBalance, realBalance, msg.sender);
    	
    	fee_registerMaster();
        IERC20(WETH).transferFrom(msg.sender, address(this), _balance);
    }
    
    /* ----------------   Admin remove pools Function   ------------------ */
    function removePools(uint256 _poolsId) public onlyOwner {
        poolsLength--;
        delete PoolsInfo[_poolsId];
    }
    
    /* ----------------   Follwer copytrade Function   ------------------ */
    function copyTrade(uint256 _poolsId, uint256 _balance) public {
        
        followerLength++;
    	
    	// push data to array struct
    	_FollowerFund.push(FollowerFund(followerLength, _poolsId, _balance, msg.sender));
    	
    	// push for view data
    	FollowerFundInfo[followerLength] = FollowerFund(followerLength, _poolsId, _balance, msg.sender);
    	
    	// update master pools
    	 PoolsInfo[_poolsId].balanceOfPools += _balance;
    	 
    	fee_registerCopyTrade();
        IERC20(WETH).transferFrom(msg.sender, address(this), _balance);
    }

    
   /* function testInvest(address _investToAssets) public view returns(bool) {
        require(AssetToTradeInfo[_investToAssets].assetsAddress == _investToAssets, "Asset not allow to invest.");
        return true;
    }*/
    
    /* ---------------------------------- */
    /* ----------------   Fee Function   ------------------ */
    

    /* ----------------   for registerMaster ( fee is Dollar) Function   ------------------ */
    function fee_registerMaster() internal {
        IERC20(WETH).transfer(dev, feeRegisterMaster);
    }
    
    /* ----------------   for Follower CopyTrade ( fee is Dollar) Function   ------------------ */
    function fee_registerCopyTrade() internal {
        IERC20(WETH).transfer(dev, feeRegisterCopyTrade);
    }
    
    /* ----------------   for Master Transaction invest on assets ( fee is Percentage) Function   ------------------ */
    function fee_masterTransaction(address _tokenIn, uint256 _amountIn) internal {
        uint256 feeTransaction = (_amountIn * feeMasterTransaction)/1000;
        IERC20(_tokenIn).transfer(dev, feeTransaction);
    }
    
    /* ****************************************************************** */
    /* --------------------   withdraw  Function   ---------------------- */
    /* ****************************************************************** */
    
    /* ----------------   Master withdraw  Function   ------------------ */
    function master_withdraw(uint256 _pools, uint256 _amount) public {

        require(PoolsInfo[_pools].manager == msg.sender, "Not found of pools id.");
        uint256 amount = PoolsInfo[_pools].balanceMaster;
        
        require(_amount >= amount, "Balance is enough.");
        
        IERC20(WETH).transferFrom(address(this), msg.sender, _amount);
    }
    

    // Investing stable coin
    function investAssets(
        uint256 _poolsManage,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) public {
        require(PoolsInfo[_poolsManage].manager == msg.sender, "You not a Master in this pools.");
        require(AssetToTradeInfo[_tokenIn].assetsAddress == _tokenIn, "Asset not allow to invest.");
        address _to = address(this);
        
        //IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
        
        // send transaction fee to dev
        fee_masterTransaction(_tokenIn, _amountIn);
        
        uint _amountInCurrent = _amountIn - ((_amountIn * feeMasterTransaction)/1000);
        
        
    
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
    
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
          _amountInCurrent,
          _amountOutMin,
          path,
          _to,
          block.timestamp
        );
    }

  function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn
      ) public view returns (uint) {
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
    
        // same length as path
        uint[] memory amountOutMins =
          IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
    
        return amountOutMins[path.length - 1];
      }
    
}