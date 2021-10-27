pragma solidity >=0.7.0 <0.8.2;

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
    function InitOperationsConfig (address,address,address, uint256, uint256, uint256, uint256,string memory,address)external; 
    /*
    TODO
    function InitOperationsConfig (inputToken,outputToken, amontIn1, minAmountOut1, amontIn2, minAmountOut2)external;
    */
    function getState() external view returns(address,address,address,uint8,uint256, uint256,uint256, uint256,string memory,address);
    function execute() external;
    function withdrawToken(uint256 amount,address token)external;
    function withdrawBNB(uint256 amount)external;
    
}
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    constructor(address _WBNB){
        WBNB = _WBNB;
    }
    
    function InitOperationsConfig (address _token,address _receiver,address _base, uint256 _amountIn0, uint256 _amountOut0, uint256 _amountIn1, uint256 _amountOut1, string calldata _callMethod, address _pancackeRouterAddress)external onlyOwner override{
        counter = 0;
        token = _token;
        base = _base;
        receiver = _receiver;
        amountIn0 = _amountIn0;
        amountOut0 = _amountOut0;
        amountIn1 = _amountIn1;
        amountOut1 = _amountOut1;
        callMethod = _callMethod;
        if(base != WBNB){
            IERC20(base).approve(pancackeRouterAddress,2**256 - 1);
        }
        pancackeRouterAddress = _pancackeRouterAddress;
        Router = IUniswapV2Router01(_pancackeRouterAddress);
        
    } 
    
    function getState() external override view returns(address,address,address,uint8,uint256, uint256,uint256, uint256,string memory,address){
        return (token, base ,receiver,counter,amountIn0,amountOut0,amountIn1,amountOut1,callMethod,pancackeRouterAddress);
    }
    
    function _execute(uint256 amountIn,uint256 amountOut) internal{
        address[] memory path = new address[](2);
        path[0] = base;
        path[1] = token;


        if(base == WBNB){
            (bool success, bytes memory data) = address(pancackeRouterAddress).call{value:amountIn}(abi.encodeWithSignature(callMethod, amountOut,path,receiver,block.timestamp+9999));
            require(success,"");
            return;
        }
        (bool success, bytes memory data) = address(pancackeRouterAddress).call(abi.encodeWithSignature(callMethod,amountIn, amountOut,path,receiver,block.timestamp+9999));
        require(success,"");
    }
    function execute() external override onlyExecutor{
        require(counter<2,"counter overflow");
        counter==0?_execute(amountIn0,amountOut0):_execute(amountIn1,amountOut1);
        counter+=1;
    }
    
    function withdrawToken(uint256 amount,address _token)external override onlyOwner{
        IERC20(_token).transfer(msg.sender,amount);
    }
    function withdrawBNB(uint256 amount)external override onlyOwner{
        payable(msg.sender).transfer(amount);
    }
    receive()external payable{}
    
    
}