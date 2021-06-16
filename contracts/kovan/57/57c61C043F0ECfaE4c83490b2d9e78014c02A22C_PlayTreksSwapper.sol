/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// File: ..\..\node_modules\@uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

// File: @uniswap\v2-periphery\contracts\interfaces\IERC20.sol

pragma solidity >=0.5.0;

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

// File: contracts\Swapper.sol

pragma solidity >=0.8.4;


interface IUniswapV2Factory1 {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router1 {
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
    ) external payable returns (uint amountA, uint amountB, uint liquidity);
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
    ) external payable returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH);
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
    ) external payable returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
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

interface IUniswapV2Router is IUniswapV2Router1 {
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

interface Token {
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
}

contract Treks{
    Token treks;

    constructor(){
        treks =  Token(0x15492208Ef531EE413BD24f609846489a082F74C);
    }
}

contract DAI{
    Token Dai;
    
    constructor(){
        Dai = Token(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
    }
}

// 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
contract Uniswap{
    IUniswapV2Router uniswap;

    constructor(){
        uniswap =  IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);     // Kovan, Rinkeby and Mainnet
        // uniswap =  IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);     // Matic mainnet
    }
}

contract UniswapFactory{
    IUniswapV2Factory1 uniswapFactory;

    constructor(){
        uniswapFactory =  IUniswapV2Factory1(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);     // Kovan, Rinkeby and Mainnet
        // uniswap =  IUniswapV2Router(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);     // Matic mainnet
    }
}

contract PlayTreksSwapper is Uniswap, UniswapFactory, Treks, DAI{
    address owner;
    mapping (address=>uint) EthTreks;
    mapping (address=>uint) DaiTreks;
    constructor(){
        owner = msg.sender;
    }
    
     // the fallback function (even if Ether is sent along with the call).
    fallback() external payable {
        if(owner != msg.sender){
            flashSwapExactETHForTreks(msg.value); 
        }
    }
    
   receive() external payable {
        if(owner != msg.sender){
            flashSwapExactETHForTreks(msg.value); //record the address that paid to you
        }
    }
    
    function getAvgEthTreksPrice(uint amount) public view returns(uint){
        address pairAddress = 0x4D04fb3398F213Bb6c8621248817F4A0f5bE11b8;
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IERC20 token1 = IERC20(pair.token1());
        (uint Res0, uint Res1,) = pair.getReserves();
    
        // decimals
        uint res0 = Res0*(10**token1.decimals());
        return((amount*res0)/Res1); // return amount of token0 needed to buy token1
   }
   
   function getAvgTreksEthPrice(uint amount) public view returns(uint){
        address pairAddress = 0x4D04fb3398F213Bb6c8621248817F4A0f5bE11b8;
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IERC20 token1 = IERC20(pair.token0());
        (uint Res0, uint Res1,) = pair.getReserves();
    
        // decimals
        uint res0 = Res1*(10**token1.decimals());
        return((amount*res0)/Res0); // return amount of token0 needed to buy token1
   }
   
   function getAvgDaiTreksPrice(uint amount) public view returns(uint){
        address pairAddress = 0xcA7612D7B8D460A537848d98226F0dEEE05cfc03;
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IERC20 token1 = IERC20(pair.token1());
        (uint Res0, uint Res1,) = pair.getReserves();
    
        // decimals
        uint res0 = Res0*(10**token1.decimals());
        return((amount*res0)/Res1); // return amount of token0 needed to buy token1
   }
   
   function getAvgTreksDaiPrice(uint amount) public view returns(uint){
        address pairAddress = 0xcA7612D7B8D460A537848d98226F0dEEE05cfc03;
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IERC20 token1 = IERC20(pair.token0());
        (uint Res0, uint Res1,) = pair.getReserves();
    
        // decimals
        uint res0 = Res1*(10**token1.decimals());
        return((amount*res0)/Res0); // return amount of token0 needed to buy token1
   }
    
    function createPairToken(
        address tokenA,
        address tokenB
    )external {
        uniswapFactory.createPair(tokenA, tokenB);
    }
    
    function createPairEthTreks(
    )external {
        uniswapFactory.createPair(uniswap.WETH(), 0x15492208Ef531EE413BD24f609846489a082F74C);
    }
    
    function createPairTreksEth(
    )external {
        uniswapFactory.createPair(0x15492208Ef531EE413BD24f609846489a082F74C, uniswap.WETH());
    }
    
    function getPairs(uint num) view public returns (address pair){
        return uniswapFactory.allPairs(num);
    }
    
    function getPairDaiTreks() view public returns (address pair){
        address token1 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address token2 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        return uniswapFactory.getPair(token1, token2);
    }
    
    function getPairEthTreks() view public returns (address pair){
        address token1 = uniswap.WETH();
        address token2 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        return uniswapFactory.getPair(token1, token2);
    }
    
    function removeLiquidityDaiTreks(
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )public{
        deadline = block.timestamp  + deadline;   
        address token1 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address token2 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        
        require(DaiTreks[msg.sender] >=amountAMin, "You have no stake in this liquidity up to the amount you're requesting for.");
        uniswap.removeLiquidity(
            token1,
            token2,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }
    
    function removeLiquidityEthTreks(
        uint liquidity,
        uint amountTokenMin,
        uint amountEthMin,
        address to,
        uint deadline
    )public {
        deadline = block.timestamp  + deadline;   
        address token1 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        
        require(EthTreks[msg.sender] >= amountTokenMin, "You have no stake in this liquidity up to the amount you're requesting for.");
        uniswap.removeLiquidityETHSupportingFeeOnTransferTokens(
            token1,
            liquidity,
            amountTokenMin,
            amountEthMin,
            to,
            deadline
        );
    }
    
    function addLiquidityEthTreks(
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
        ) external payable{
        deadline = block.timestamp  + deadline; 
        address token = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        
        require(treks.transferFrom(msg.sender, address(this), amountTokenDesired), 'transferFrom failed from contract.');
        require(treks.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountTokenDesired), 'approve failed from contract.');
        
        
        uniswap.addLiquidityETH{ value: msg.value }(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            msg.sender,
            deadline
        );
        
        if(EthTreks[msg.sender] >0){
            uint old = EthTreks[msg.sender];
            EthTreks[msg.sender] = amountTokenDesired + old;
        }else{
            EthTreks[msg.sender] = amountTokenDesired;
        }
    }
    
    function addLiquidityDaiTreks(
        uint amountToken1Desired,
        uint amountToken2Desired,
        uint amountToken1Min,
        uint amountToken2Min,
        uint deadline
        ) external payable{
        deadline = block.timestamp  + deadline;   
        address token1 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address token2 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        require(treks.transferFrom(msg.sender, address(this), amountToken2Desired), 'transferFrom failed from contract.');
        require(treks.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountToken2Desired), 'approve failed from contract.');
        require(Dai.transferFrom(msg.sender, address(this), amountToken1Desired), 'transferFrom failed from contract.');
        require(Dai.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountToken1Desired), 'approve failed from contract.');
        
        uniswap.addLiquidity(
            token1,
            token2,
            amountToken1Desired,
            amountToken2Desired,
            amountToken1Min,
            amountToken2Min,
            msg.sender,
            deadline
        );
        uint old = DaiTreks[msg.sender];
        DaiTreks[msg.sender] = amountToken1Desired + old;
    }
    
    function addLiquidityTreksDai(
        uint amountToken1Desired,
        uint amountToken2Desired,
        uint amountToken1Min,
        uint amountToken2Min,
        uint deadline
        ) external payable{
        deadline = block.timestamp  + deadline; 
        address token2 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address token1 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan Dai
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        
        require(treks.transferFrom(msg.sender, address(this), amountToken1Desired), 'transferFrom failed from contract.');
        require(treks.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountToken1Desired), 'approve failed from contract.');
        require(Dai.transferFrom(msg.sender, address(this), amountToken2Desired), 'transferFrom failed from contract.');
        require(Dai.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountToken2Desired), 'approve failed from contract.');
        
        uniswap.addLiquidity(
            token1,
            token2,
            amountToken1Desired,
            amountToken2Desired,
            amountToken1Min,
            amountToken2Min,
            msg.sender,
            deadline
        );
        
        uint old = DaiTreks[msg.sender];
        DaiTreks[msg.sender] = amountToken2Desired + old;
    }
    
    function fastSwapExactETHForTokens(
        uint amountOut,
        address token,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function flashSwapExactETHForTreks(
        uint amountOut
    ) internal{
        address token = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        uint deadline = block.timestamp  + 1200;
        
        require(treks.transferFrom(msg.sender, address(this), amountOut), 'transferFrom failed from contract.');
        require(treks.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 1000 * 10**18), 'approve failed from contract.');
        
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            msg.sender,
            deadline
        );
        
        //msg.sender.call{value:msg.sender.balance}("");
    }
    
    function fastSwapExactETHForTreks(
        uint amountOut
    ) external payable{
        address token = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        uint deadline = block.timestamp  + 1200;
        address[] memory path = new address[](2);
        
        require(treks.transferFrom(msg.sender, address(this), amountOut), 'transferFrom failed from contract.');
        require(treks.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 1000* 10**18), 'approve failed from contract.');
        
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapExactETHForDai(
        uint amountOut
    ) external payable {
        address token = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        uint deadline = block.timestamp  + 1200;
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapTokensForExactETH(
        uint amountOut,
        uint amountIn,
        address token,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address[] memory path = new address[](2);
        path[1] = uniswap.WETH();
        path[0] = token;
        uniswap.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountOut,
            amountIn,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapTreksForExactETH(
        uint amountOut,
        uint amountIn,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address token = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address[] memory path = new address[](2);
        path[1] = uniswap.WETH();
        path[0] = token;
        
        require(treks.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed from contract.');
        require(treks.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountIn), 'approve failed from contract.');
        
        
        uniswap.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountOut,
            amountIn,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapDaiForExactETH(
        uint amountOut,
        uint amountIn,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address token = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        
        require(Dai.transferFrom(msg.sender, address(this), amountOut), 'transferFrom failed from contract.');
        require(Dai.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountOut), 'approve failed from contract.');
        
        address[] memory path = new address[](2);
        path[1] = uniswap.WETH();
        path[0] = token;
        uniswap.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountOut,
            amountIn,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapExactTokenForTokens(
        uint amountOut,
        uint amountIn,
        address token1,
        address token2,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        uniswap.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapExactDaiForTreks(
        uint amountOut,
        uint amountIn,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address token1 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token1 = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        address token2 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        
        require(treks.transferFrom(msg.sender, address(this), amountOut), 'transferFrom failed from contract.');
        require(treks.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountOut), 'approve failed from contract.');
        require(Dai.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed from contract.');
        require(Dai.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountIn), 'approve failed from contract.');
        
        uniswap.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapExactTreksForDai(
        uint amountOut,
        uint amountIn,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address token1 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address token2 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token2 = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        
        require(treks.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed from contract.');
        require(treks.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountIn), 'approve failed from contract.');
        require(Dai.transferFrom(msg.sender, address(this), amountOut), 'transferFrom failed from contract.');
        require(Dai.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountOut), 'approve failed from contract.');
        
        uniswap.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapTokensForExactToken(
        uint amountOut,
        uint amountIn,
        address token1,
        address token2,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address[] memory path = new address[](2);
        path[1] = token1;
        path[0] = token2;
        uniswap.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountOut,
            amountIn,
            path,
            msg.sender,
            deadline
        );
    }
  
}