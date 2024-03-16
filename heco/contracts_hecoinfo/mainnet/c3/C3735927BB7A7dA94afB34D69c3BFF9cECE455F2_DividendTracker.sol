/**
 *Submitted for verification at hecoinfo.com on 2022-06-07
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed

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

// erc20
interface IERC20 {
    function totalSupply() external view returns (uint256);    
    function balanceOf(address _address) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// 提供的接口
interface IDividendTracker {
    function initialization() external payable;
    function hsbSwapHT() external;
    function putWHTtoPoll(address BPancakePair) external;
}


// safe math
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Math error");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Math error");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a / b;
        return c;
    }
}


// safe transfer
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        // (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// owner
contract Ownable {
    address public _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, 'DividendTracker: owner error');
        _;
    }

    function changeOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;       
    }
}


// 主合约
contract DividendTracker is IDividendTracker, Ownable {
    using SafeMath for uint256;

    address public _routerAddress;
    address public _hsbAddress;
    address public _whtAddress;
    address public _shjAddress;    
    address private _destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);    

    uint256 public _htPct;
    uint256 public _usdtPct;
    uint256 public _dvPct;

    uint256 public _lpAmout;           

    address public _pledgeAddress;//质押LP合约地址            

    // 构造函数
    constructor(
        address routerAddress,
        address whtAddress,
        address shjAddress
    ){
        _owner = msg.sender;
        _routerAddress = routerAddress;
        _whtAddress = whtAddress;
        _shjAddress = shjAddress;
        _htPct = 80;
        _usdtPct = 20;
        _dvPct = 67;        
    }
    event HSBswapHT(uint256 hsbBalances, uint256 htBalances);
   
    modifier onlyHsbAddress() {
        require(msg.sender == _hsbAddress, 'DividendTracker: HSB error');
        _;
    }       

    function initialization() public override payable {
        require(msg.value == 1000000000000000, 'DividendTracker: initialization value error');
        require(_hsbAddress == address(0), 'DividendTracker: initialization address error');

        _hsbAddress = msg.sender;
    }

    // 提取
    function withdraw(address token, address to, uint256 value) public onlyOwner {
        TransferHelper.safeTransfer(token, to, value);
    } 

    // 兑换
    function hsbSwapHT() public override {
        require(_routerAddress != address(0), "routerAddress error");      
        uint256 _hsbBalances = IERC20(_hsbAddress).balanceOf(address(this));
        // WHT
        uint256 initialBalance = IERC20(_whtAddress).balanceOf(address(this));
        if(_hsbBalances == 0 || _hsbBalances<=_lpAmout) return;
        uint256 dvAmount = _hsbBalances.sub(_lpAmout);
        uint256 dvBalances = dvAmount.mul(_dvPct).div(100);

        address[] memory _path = new address[](2);
        _path[0] = _hsbAddress;
        _path[1] = _whtAddress;
        // 授权给路由合约。
        TransferHelper.safeApprove(_hsbAddress, _routerAddress, dvBalances);
        IUniswapV2Router02(_routerAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            dvBalances,
            0, // 接受任意金额的兑换
            _path,
            address(this),
            block.timestamp + 300);

        _lpAmout += dvAmount.sub(dvBalances);

        uint256 whtReceived = IERC20(_whtAddress).balanceOf(address(this)) - initialBalance;
        emit HSBswapHT(dvBalances, whtReceived);
    }

   function putWHTtoPoll(address BPancakePair) public override onlyHsbAddress {
        require(BPancakePair != address(0), "BPancakePair error");
        // uint256 initialBalance = IERC20(_whtAddress).balanceOf(address(this));
        uint256 hsbBalances = IERC20(_hsbAddress).balanceOf(address(this));
        // if(initialBalance == 0)return;
        if(BPancakePair == _shjAddress){
            // address[] memory _path = new address[](2);
            // _path[0] = _whtAddress;
            // _path[1] = BPancakePair;
            // // 授权给路由合约。
            // TransferHelper.safeApprove(_whtAddress, _routerAddress, initialBalance);
            // IUniswapV2Router02(_routerAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            //     initialBalance,
            //     0, // 接受任意金额的兑换
            //     _path,
            //     address(this),
            //     block.timestamp + 300);

                uint256 shjBalances = IERC20(_shjAddress).balanceOf(address(this));
                if(shjBalances > 0)TransferHelper.safeTransfer(_shjAddress, _destroyAddress, shjBalances);
        }
        // else{
        //     TransferHelper.safeTransfer(_whtAddress, BPancakePair, initialBalance);
        // }

        if(hsbBalances >= _lpAmout && _lpAmout > 0){
            TransferHelper.safeTransfer(_hsbAddress, _pledgeAddress, _lpAmout);
            _lpAmout = 0;
        }       
    }

    function changePair(address hsbAddress, address pledgeAddress) public onlyOwner {      
        _hsbAddress = hsbAddress;
        _pledgeAddress = pledgeAddress;        
    }

    function changePct(uint256 htPct, uint256 usdtPct, uint256 dvPct) public onlyOwner {
        _htPct = htPct;
        _usdtPct = usdtPct;
        _dvPct = dvPct;        
    } 

}