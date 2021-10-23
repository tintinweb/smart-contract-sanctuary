pragma solidity >=0.7.0 <0.9.0;
interface IUniswapV2Router01 {
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
interface IBSCSnipingSmartContract{
    function InitOperationsConfig (address,address,address, uint256, uint256, uint256, uint256,string memory)external; 
    /*
    TODO
    function InitOperationsConfig (inputToken,outputToken, amontIn1, minAmountOut1, amontIn2, minAmountOut2)external;
    */
    function getState() external view returns(address,address,address,uint8,uint256, uint256,uint256, uint256,string memory);
    function execute() external;
    function withdrawToken(uint256 amount,address token)external;
    function withdrawBNB(uint256 amount)external;
    
}
interface TokenInterface {
    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256) external;
}

abstract contract  Ownable{
    address internal owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
}
abstract contract  Executable is Ownable{
    mapping (address => bool) internal executors;
    constructor(){
        executors[msg.sender] = true;
    }
    modifier onlyExecutor{
        require(executors[msg.sender] == true, 'Only Executor may call this method');
        _;
    }
    function addExecutors(address[] calldata newExecutors) external onlyOwner returns (bool) {
        for(uint8 i; i < newExecutors.length; i++){
            executors[newExecutors[i]] = true;
        }
        return true;
    }
    function removeExecutors(address[] calldata removedExecutors) external onlyOwner returns (bool) {
        for(uint8 i; i < removedExecutors.length; i++){
            executors[removedExecutors[i]] = false;
        }
        return true;
    }
    function isExecutor(address toCheck)external view returns (bool){
        return executors[toCheck];
    }
}

contract BSCSnipingSmartContract is Executable,IBSCSnipingSmartContract{
    
    uint8 internal counter;
    address internal WBNB;// = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address internal pancackeRouterAddress;// = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
    IUniswapV2Router01 internal Router;// = IUniswapV2Router01(pancackeRouterAddress);
    
    address internal token;
    address internal base;
    address internal receiver;
    
    uint256 internal amountIn0; 
    uint256 internal amountOut0;
    
    uint256 internal amountIn1; 
    uint256 internal amountOut1;
    
    string internal callMethod;

    constructor(address _pancackeRouterAddress,address _WBNB){
        WBNB = _WBNB;
        pancackeRouterAddress = _pancackeRouterAddress;
        Router = IUniswapV2Router01(_pancackeRouterAddress);
    }
    
    function InitOperationsConfig (address _token,address _receiver,address _base, uint256 _amountIn0, uint256 _amountOut0, uint256 _amountIn1, uint256 _amountOut1, string calldata _callMethod)external onlyOwner override{
        counter = 0;
        token = _token;
        base = _base;
        receiver = _receiver;
        amountIn0 = _amountIn0;
        amountOut0 = _amountOut0;
        amountIn1 = _amountIn1;
        amountOut1 = _amountOut1;
        callMethod = _callMethod;
        
    } 
    
    function getState() external override view returns(address,address,address,uint8,uint256, uint256,uint256, uint256,string memory){
        return (token, base ,receiver,counter,amountIn0,amountOut0,amountIn1,amountOut1,callMethod);
    }
    
    function _execute(uint256 amountIn,uint256 amountOut) internal{
        address[] memory path = new address[](2);
        path[0] = base;
        path[1] = token;


        if(base == WBNB){
            address(pancackeRouterAddress).call{value:amountIn}(abi.encodeWithSignature(callMethod, amountOut,path,address(this),block.timestamp+9999));
            return;
        }
        address(pancackeRouterAddress).call(abi.encodeWithSignature(callMethod,amountIn, amountOut,path,address(this),block.timestamp+9999));
    }
    function execute() external override onlyExecutor{
        require(counter<2,"counter overflow");
        counter==0?_execute(amountIn0,amountOut0):_execute(amountIn1,amountOut1);
        counter+=1;
    }
    
    function withdrawToken(uint256 amount,address _token)external override onlyOwner{
        TokenInterface(_token).transfer(msg.sender,amount);
    }
    function withdrawBNB(uint256 amount)external override onlyOwner{
        payable(msg.sender).transfer(amount);
    }
    receive()external payable{}
    
    
}