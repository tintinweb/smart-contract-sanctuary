/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: MIT Licensed

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(IPancakeRouter02 routerAddress, uint256 tokenAmount,IBEP20 _token) internal {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = routerAddress.WETH();

        _token.approve(address(routerAddress), tokenAmount);
         
        // make the swap
        routerAddress.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 360
        );
    }

    function swapTokensForTokens(IPancakeRouter02 routerAddress, uint256 tokenAmount,IBEP20 _token,IBEP20 _busd) internal {
        // generate the pancake pair path of token -> busd
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = address(_busd);

        _token.approve(address(routerAddress), tokenAmount);
         
        // make the swap
        routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp + 360
        );
    }

    function swapETHForTokens(
        IPancakeRouter02 routerAddress,
        address recipient,
        uint256 ethAmount
    ) internal {

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = routerAddress.WETH();
        path[1] = address(this);

        // make the swap
        routerAddress.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }

    function addLiquidity(
        IPancakeRouter02 routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {

        // add the liquidity
        routerAddress.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


contract SwapScrapYard {
    using SafeMath for uint256;

    IBEP20 public scrap;  
    IBEP20 public busd;  //  0x8840DD8080b4ddDc1D0a5C2A825C96D127c43FcD
    IPancakePair scrapPairAddress;   // 0xa24fa2d74bcd016dcbf4d06d2eb7bfd59bf88c26

    address payable public marketingWallet = payable(0x2Ae232893C60DF913E9501c609A9797bC5cAda58); // 0xdE0C38c263cb40607896AdF02082c6B9A0312A40
    address payable public owner;

    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    IPancakeFactory public factoryContract = IPancakeFactory(0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc);
    AggregatorV3Interface priceFeedUsd = AggregatorV3Interface(0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c);
    AggregatorV3Interface priceFeedBnb = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);

    
    uint256 public worthLessTokenReward = 5e18;
    uint256 public maxSwapPerDay = 20e18;
    uint256 public swapTimeLimit = 1 days;
    uint256 public scrapSupply;

    mapping(address => uint256) public lastSwapBalance;
    mapping(address => uint256) public lastSwapTime; 

    address[] public scrapedTokens;

    modifier onlyOwner() {
        require(owner == payable(msg.sender), "Ownable: caller is not the owner");
        _;
    }
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    constructor (address _scrapPair) {
        owner = payable(msg.sender);
        scrap = IBEP20(0x4eD1a8c8A5cf23cbd7aDe2b8910731720C5aBcA9);
        busd = IBEP20(0x8840DD8080b4ddDc1D0a5C2A825C96D127c43FcD);
        scrapPairAddress = IPancakePair(_scrapPair);
        scrapSupply = 10000e9;
    }
    
    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}


    function swapNoneWorthyToken(IBEP20 _token)public returns(bool){
        uint256 tokenAmount = getUserTokenBalance(msg.sender, _token);
        require(scrap.balanceOf(msg.sender) >= scrapSupply,"dont have enough scrap");  
        require(tokenAmount > 0,"you must have token balance");
        address pairAddress = factoryContract.getPair(address(_token),pancakeRouter.WETH());
        require(pairAddress == address(0),"Pair exists"); 
        _token.transferFrom(msg.sender, marketingWallet, tokenAmount);
        scrapedTokens.push(address(_token));

        uint256 reward=busd.balanceOf(marketingWallet).div(1e3);
        if(reward>worthLessTokenReward){
            reward=worthLessTokenReward;
        }
        
        busd.transferFrom(marketingWallet,msg.sender,reward);
        return true;
    }



    function swapWorthyToken(IBEP20 _token, uint256 pairNumber) public {
        require(scrap.balanceOf(msg.sender) >= scrapSupply,"dont have enough scrap");
        require(_token.balanceOf(msg.sender)>0,"you must have token balance");
        address pairAddress;
        uint256 tokenAmount = getUserTokenBalance(msg.sender, _token);
        _token.transferFrom(msg.sender, address(this), tokenAmount);
        scrapedTokens.push(address(_token));
        uint256 reward=busd.balanceOf(marketingWallet).div(1e3);
        if(reward>worthLessTokenReward){
            reward=worthLessTokenReward;
        }
        
        busd.transferFrom(marketingWallet,msg.sender,reward);
        if(pairNumber==1){
            
            pairAddress = factoryContract.getPair(address(_token),pancakeRouter.WETH());
            require(pairAddress != address(0),"Pair don't exist");
            swapAndLiquifyBNB(tokenAmount,_token);
          }
          
        else{

            pairAddress = factoryContract.getPair(address(_token),address(busd));
            require(pairAddress != address(0),"Pair don't exist");
            swapAndLiquifyBUSD(tokenAmount,_token);  
        }
            
        
        
    }
    

    function swapAndLiquifyBNB(uint256 tokenBalance,IBEP20 _token) private {
        
        require(lastSwapBalance[msg.sender] <= (maxSwapPerDay) || lastSwapTime[msg.sender] > block.timestamp,"limit exeeded");
        if(lastSwapTime[msg.sender] > block.timestamp){
            lastSwapBalance[msg.sender] = 0;
        }
        uint256 initialBalance = getContractBnbBalance();
    
        // swap tokens for ETH
        Utils.swapTokensForEth(pancakeRouter,tokenBalance,_token); 
        
        // how much ETH did we just swap into?
        uint256 newBalance = getContractBnbBalance().sub(initialBalance);

        uint256 scrapRate = getScrapCurrentRateBnb();
        uint256 amountToSend = newBalance.mul(1e9).div(2).div(scrapRate);
        payable(msg.sender).transfer(newBalance.div(2));
        scrap.transferFrom(marketingWallet,msg.sender,amountToSend);
        lastSwapBalance[msg.sender] = lastSwapBalance[msg.sender].add(newBalance.mul(getLatestPriceBnb()));
        lastSwapTime[msg.sender] = block.timestamp + swapTimeLimit;
        
    }


    function swapAndLiquifyBUSD(uint256 tokenBalance,IBEP20 _token) private  {
        
        require(lastSwapBalance[msg.sender] <= (maxSwapPerDay) || lastSwapTime[msg.sender] > block.timestamp,"limit exeeded");
        if(lastSwapTime[msg.sender] > block.timestamp){
            lastSwapBalance[msg.sender] = 0;
        }
        
        uint256 initialBalance = getContractBusdBalance();

        // swap tokens for ETH
        Utils.swapTokensForTokens(pancakeRouter,tokenBalance,_token,busd);

        // how much ETH did we just swap into?
        uint256 newBalance = getContractBusdBalance().sub(initialBalance);
        uint256 scrapRate = getScrapCurrentRateBusd();
        uint256 amountToSend = newBalance.mul(1e9).div(2).div(scrapRate);
        
        scrap.transferFrom(marketingWallet,msg.sender,amountToSend);
        busd.transfer(msg.sender,newBalance.div(2));
        lastSwapBalance[msg.sender] = lastSwapBalance[msg.sender].add(newBalance);
        lastSwapTime[msg.sender] = block.timestamp + swapTimeLimit;

    }

    function getCurrentPrice(address pairAddress,uint256 decimals) public view returns(uint256){
        
        (uint256 _token, uint256 Wbnb,) = IPancakePair(pairAddress).getReserves();
        
        uint256 currentRate = Wbnb.div(_token.div(10 ** decimals));
        return currentRate;
    }

    // to get real time price of BNB

    function getLatestPriceBnb() public view returns (uint256) {
        (,int price,,,) = priceFeedBnb.latestRoundData();
        return uint256(price).div(1e8);
    }

    function getScrapCurrentRateBnb() public view returns(uint256){
        (uint256 _scrap, uint256 Wbnb,) = IPancakePair(scrapPairAddress).getReserves();
        return Wbnb.div(_scrap.div(1e9));
    }

    function getScrapCurrentRateBusd() public view returns(uint256){
        uint256 rateBnb = getScrapCurrentRateBnb();
        return rateBnb.mul(getLatestPriceBnb());
    }
    
    function getUserTokenBalance(address _user, IBEP20 _token) public view returns(uint256){
        return _token.balanceOf(_user);
    }

    function getContractBnbBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getContractBusdBalance() public view returns(uint256){
        return busd.balanceOf(address(this));
    }

    function migrateFundsBnb(uint256 _value) external onlyOwner{
        owner.transfer(_value);
    }

    function migrateFundsBusd(uint256 _value) external onlyOwner{
        busd.transfer(owner, _value);
    }

    function setMarketingAddress(address payable _marketing) external onlyOwner{
        marketingWallet = _marketing;
    }

    function setWorthLessTokenReward(uint256 _amount) external onlyOwner{
        worthLessTokenReward = _amount;
    }

    function setMaxSwapPerDay(uint256 _amount) external onlyOwner{
        maxSwapPerDay = _amount;
    }

    function setScrapSupply(uint256 _amount) external onlyOwner{
        scrapSupply = _amount;
    }

    function setSwapTimeLimit(uint256 _time) external onlyOwner{
        swapTimeLimit = _time;
    }

}