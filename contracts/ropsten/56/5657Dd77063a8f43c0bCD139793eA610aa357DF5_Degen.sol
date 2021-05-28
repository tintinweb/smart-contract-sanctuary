/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

}

interface ISwapFactory {
     function swap(address tokenA, address tokenB, uint256 amount) external payable returns (bool);
    //  function getPairs(address tokenA, address tokenB) external view returns (address);
    //  function createPair(address tokenA, address tokenB, bool local) public returns (address payable pair);
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function mint(address to, uint256 amount) external returns(bool);

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

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// interface I1inch {

//     function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 minReturn, uint256[] calldata distribution, uint256 flags)
//     external payable
//     returns(uint256);
    
//     function getExpectedReturn(IERC20 fromToken, IERC20 toToken, uint256 amount, uint256 parts, uint256 featureFlags) external
//         view
//         returns(
//             uint256,
//             uint256[] calldata
//         );

//     function makeGasDiscount(uint256 gasSpent, uint256 returnAmount, bytes calldata msgSenderCalldata) external;

// }

interface IUni {

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable
    returns (uint[] memory amounts);
    
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
    external 
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}

interface IPoolSwapPair {
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


abstract contract Router {

    
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}

    event Received(address, uint);
    event Error(address);

    receive() external payable {
        // if (validUser[msg.sender] == true) {
        //     balance[msg.sender][ETH] += msg.value;
        emit Received(msg.sender, msg.value);
        // } else {
        //     balance[owner][ETH] += msg.value;
        // }
    }

    fallback() external payable {
        revert();
    }

    // I1inch OneSplit;
    IUni Uni;
    IUni Sushi;
    address ETH = address(0);
    constructor(address _Uni, address _sushi) public payable {
        // owner = payable(msg.sender);
        // OneSplit = I1inch(_oneSplit);
        Uni = IUni(_Uni);
        Sushi = IUni(_sushi);
    }
    
    function getBestQuote(address[] memory path, uint256 amountIn, OrderType orderType) public view returns (uint, uint256) {
        // uint256 returnAmount;
        uint256[] memory uniAmounts;
        uint256[] memory sushiAmounts;
        // uint256[] memory distribution;
        if(orderType == OrderType.EthForTokens){
            // path[0] = ETH;
            // (returnAmount, distribution) = OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[1]), amountIn, 100, 0);
            path[0] = Uni.WETH();
            (uniAmounts) = Uni.getAmountsOut(amountIn, path);
            (sushiAmounts) = Sushi.getAmountsOut(amountIn, path);
        } else if(orderType == OrderType.TokensForEth){
            // path[1] = ETH; 
            // (returnAmount, distribution) = OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[1]), amountIn, 100, 0);
            path[1] = Uni.WETH();
            (uniAmounts) = Uni.getAmountsOut(amountIn, path);
            (sushiAmounts) = Sushi.getAmountsOut(amountIn, path);
        } else{
            // (returnAmount, distribution) = OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[1]), amountIn, 100, 0);
            (uniAmounts) = Uni.getAmountsOut(amountIn, path);
            (sushiAmounts) = Sushi.getAmountsOut(amountIn, path);
        }
        
        if(sushiAmounts[1]>uniAmounts[1]) {
            return(2,sushiAmounts[1]);
        } else {
            return(1,uniAmounts[1]);
        }
        
        // return (0,sushiAmounts[1],uniAmounts[1]);
        
        
        // if(returnAmount>uniAmounts[0]){
        //     if(returnAmount>sushiAmounts[0])
        //     {
        //         return(0, returnAmount, distribution);
        //     }else{
        //         return(2, sushiAmounts[0], distribution);
        //     }
        // } else if(uniAmounts[0]>sushiAmounts[0]){
        //     return(1, uniAmounts[0], distribution);
        // } else {
        //     return(2, sushiAmounts[0], distribution);
        // }
    }
 
    // function swap(address _fromToken, address _toToken, uint256 amountIn, uint256 minReturn, uint256[] memory distribution, uint256 flags)
    // internal {
    //     if (_fromToken == ETH) {
    //         try OneSplit.swap{value: amountIn}(IERC20(ETH), IERC20(_toToken), amountIn, minReturn, distribution, flags)
    //          returns (uint256 amountOut){
    //              TransferHelper.safeTransferFrom(_toToken, address(this), msg.sender, amountOut);
    //         } catch {
    //             emit Error(msg.sender);
    //             revert("Error");
    //         }
    //     } else {
    //          try OneSplit.swap(IERC20(_fromToken), IERC20(_toToken), amountIn, minReturn, distribution, flags)
    //           returns (uint256 amountOut){
    //               if(_toToken == ETH){
    //                   msg.sender.transfer(amountOut);
    //               } else {
    //                   TransferHelper.safeTransferFrom(_toToken, address(this), msg.sender, amountOut);
    //               }
    //          } catch {
    //             emit Error(msg.sender);
    //             revert("Error");
    //         }
    //     }
    // }
    
}

contract Degen is Router {
    using SafeMath for uint256;
    // address _oneSplit = address(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E); //mainnet network address for oneInch
    address _Uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //ropsten network address for uniswap
    address _sushi = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // ropsten network address for sushiswap
    address USDT = address(0x47A530f3Fa882502344DC491549cA9c058dbC7Da); // USDT Token Address
    // address _swapFactory = address(0);
    // I1inch OneSplitt = I1inch(_oneSplit);
    IUni Unii = IUni(_Uni);
    IUni Sushii = IUni(_sushi);
    IERC20 degen;
    ISwapFactory swapFactory;
    IPoolSwapPair poolContract;
   
   
    
    constructor(address _tokenAddress, address _degEthPool, address _swapFactory) Router( _Uni, _sushi) public {
        // degen token contract deployed on ropsten: 0x4c685a9018e1830AB46F9C6F883a206E4ec7AbEA
         degen = IERC20(_tokenAddress);
         poolContract = IPoolSwapPair(_degEthPool);
         swapFactory = ISwapFactory(_swapFactory);
    }
    
    
    function degenPrice() public view returns (uint256){
        (uint112 reserve0, uint112 reserve1,) = poolContract.getReserves();
        if(poolContract.token0() == Uni.WETH()){
            return ((reserve1 * (10**18)) /(reserve0));
        } else {
            return ((reserve0 * (10**18)) /(reserve1));
        }
    }
    
    
    function executeSwap(OrderType orderType, address[] memory path, uint256 assetInOffered, uint256 fees) external payable{
        uint256 gasTokens = 0;
        uint256 gasA = gasleft();
        if(orderType == OrderType.EthForTokens){
            require(msg.value >= assetInOffered.add(fees), "Payment = assetInOffered + fees");
            gasTokens = gasTokens + msg.value - assetInOffered;
        } else {
            require(msg.value >= fees, "fees not received");
            gasTokens = gasTokens + msg.value;
            TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), assetInOffered);
        }
        
        
        (uint dexId, uint256 minAmountExpected) = getBestQuote(path, assetInOffered, orderType);
        if(dexId == 1){
            uint[] memory swapResult;
            if(orderType == OrderType.EthForTokens) {
                 path[0] = Uni.WETH();
                 swapResult = Uni.swapExactETHForTokens{value:assetInOffered}(minAmountExpected, path, msg.sender, block.timestamp);
            }
            else if (orderType == OrderType.TokensForEth) {
                path[1] = Uni.WETH();
                TransferHelper.safeApprove(path[0], address(_Uni), assetInOffered);
                swapResult = Uni.swapExactTokensForETH(assetInOffered, minAmountExpected, path, msg.sender, block.timestamp);
            }
            else if (orderType == OrderType.TokensForTokens) {
                TransferHelper.safeApprove(path[0], address(_Uni), assetInOffered);
                swapResult = Uni.swapExactTokensForTokens(assetInOffered, minAmountExpected, path, msg.sender, block.timestamp);
            }
        } else if(dexId == 2){
            uint[] memory swapResult;
            if(orderType == OrderType.EthForTokens) {
                 path[0] = Sushii.WETH();
                 swapResult = Sushii.swapExactETHForTokens{value:assetInOffered}(minAmountExpected, path, msg.sender, block.timestamp);
            }
            else if (orderType == OrderType.TokensForEth) {
                path[1] = Sushii.WETH();
                TransferHelper.safeApprove(path[0], address(_sushi), assetInOffered);
                swapResult = Sushii.swapExactTokensForETH(assetInOffered, minAmountExpected, path, msg.sender, block.timestamp);
            }
            else if (orderType == OrderType.TokensForTokens) {
                TransferHelper.safeApprove(path[0], address(_sushi), assetInOffered);
                swapResult = Sushii.swapExactTokensForTokens(assetInOffered, minAmountExpected, path, msg.sender, block.timestamp);
            }
        }
        uint256 gasB = gasleft();
        gasTokens = gasTokens + (gasA - gasB)*tx.gasprice;
        uint256 degenAmount = degenPrice() * gasTokens;
        // degen.mint(msg.sender, degenAmount);
        
        
    }
    
    function executeCrossExchange(address[] memory path,uint256 assetInOffered, uint256 fees) external payable {
        
        // address pair = swapFactory.createPair(USDT, tokenB, false);
        // address[] memory path = [tokenA,USDT] ;
        // path.push(tokenA);
        // path.push(USDT); // USDT address 
        
        address tokenB = path[1];
        path[1] = USDT;
        
        uint256 gasTokens = 0;
        uint256 gasA = gasleft();
        
        require(msg.value >= fees, "fees not received");
        gasTokens = gasTokens + msg.value;
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), assetInOffered);
        
        
        
        (uint dexId, uint256 minAmountExpected) = getBestQuote(path, assetInOffered,OrderType.TokensForTokens );
        if(dexId == 1){
            uint[] memory swapResult;
            
            TransferHelper.safeApprove(path[0], address(_Uni), assetInOffered);
            swapResult = Uni.swapExactTokensForTokens(assetInOffered, minAmountExpected, path, address(this), block.timestamp);
            
        } else if(dexId == 2){
            uint[] memory swapResult;
            
            TransferHelper.safeApprove(path[0], address(_sushi), assetInOffered);
            swapResult = Sushii.swapExactTokensForTokens(assetInOffered, minAmountExpected, path, address(this), block.timestamp);
            
        }
        uint256 gasB = gasleft();
        gasTokens = gasTokens + (gasA - gasB)*tx.gasprice;
        uint256 degenAmount = degenPrice() * gasTokens;
        // degen.mint(msg.sender, degenAmount);
        
        // swapFactory.swap(USDT,tokenB,minAmountExpected,msg.sender);
        
        
        
        
    }











}