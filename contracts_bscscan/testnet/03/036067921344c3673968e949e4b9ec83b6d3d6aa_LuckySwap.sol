/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
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


contract LuckySwap {
    using SafeMath for uint256; 

    uint256 public saltAmount;
    uint256 public saltTimestamp = block.timestamp;

    IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    mapping (address => uint256) public lastSwapTimestampOfUser;
    mapping (address => address) public topUser;
    
    mapping (address => uint256) public bonusOfTopUser;


    


    // uint256 public profitAmount = 100 * (10 ** 18);

    // 100 = 1BNB, 10 = 0.1BNB, 1 = 0.01BNB
    uint256 public minAmount = 1 * (10 ** 16);
    // 1000000000000000000  1BNB
    // 100000000000000000  0.1BNB
    // 10000000000000000  0.01BNB

    uint256[] public allocation = [50,50,50,50,50,50,50,150,150,200];

    uint256 transferFee = 1;
    uint256 public devAmount;
    uint256 public devRandomAllocation;
    uint256 public devRandomAllocationIndex;

    // 最小存款金额 100 = 1BNB, 10 = 0.1BNB, 1 = 0.01BNB
    uint256 public minDepositValue = 1 * (10 ** 16);
    // 分红池总金额
    uint256 public tAmount = 100 * (10 ** 18);
    // 总股数
    uint256 public tStock = 100 * (10 ** 18);
    // 用户持股数量
    mapping (address => uint256) public stockOfAccount;
    // 存款手续费率
    uint256 public depositFee = 10;
    // 分红奖金比例
    uint256 public dividendRatio = 80;
    uint256 public bonusRatioOfhalve = 10;

    // 存款
    function depositStock() public payable {
        require(msg.value >= minDepositValue, "ERC20: approve from the zero address");
        require(tAmount > 0, "ERC20: approve from the zero address");

        // 收取存款手续费
        uint256 _fee = msg.value.mul(depositFee).div(10**2);
        uint256 _amount = msg.value - _fee;

        // 计算占股数量
        uint256 stock = tStock.mul(_amount).div(tAmount);

        // 增加分红池数量和持股数量 
        tAmount += _amount;
        tStock += stock;
        stockOfAccount[msg.sender] += stock; 
    }

    function withdrawStock(uint256 ratio) public {
        require(tAmount > 0, "ERC20: approve from the zero address");
        require(stockOfAccount[msg.sender] > 0, "ERC20: approve from the zero address");
        require(ratio > 0 && ratio <= 100, "ERC20: approve from the zero address");

        uint256 _stock = stockOfAccount[msg.sender].mul(ratio).div(10**2);
        uint256 _amount = tAmount.mul(_stock).div(tStock);
        require(_amount > 0 , "ERC20: approve from the zero address");

        tAmount -= _amount;
        tStock -= _stock;
        stockOfAccount[msg.sender] -= _stock;

        payable(msg.sender).transfer(_amount);
    }

    constructor () {}
    receive() external payable {}

    function bindingTopUser(address account) public {
        require(topUser[msg.sender] == address(0), "ERC20: approve from the zero address");
        require(msg.sender != account, "ERC20: approve from the zero address");
        require(account != address(0), "ERC20: approve from the zero address");

        topUser[msg.sender] = account;
    }

    function haveTopUser(address account) public view returns (bool) {
        return topUser[account] != address(0);
    }

    // [WBNB,BUSD] ["0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd", "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7"]
    function luckySwapETHForTokens(address[] memory path) public payable returns (uint256) {
        require (msg.value >= minAmount, 'less than minimum amount');
        require (block.timestamp - lastSwapTimestampOfUser[msg.sender] >= 30, "swap must 30 second interval");
        require(path[0] == uniswapV2Router.WETH(), "ERC20: approve from the zero address");
        
        uint256  receiveAmount = msg.value;

        uint256 allocationIndex = generateRandomNumber(receiveAmount);
        require (allocationIndex <= 9, 'error allocation index');

        uint256 randomAllocation = allocation[allocationIndex];

        if(!haveTopUser(msg.sender)){
            uint256 fee = receiveAmount.mul(transferFee).div(10**2);
            tAmount += fee;
            receiveAmount -= fee;
        }

        uint256 newAmount = receiveAmount.mul(randomAllocation).div(10**2);

        if(receiveAmount > newAmount){
            uint256 profit = receiveAmount.sub(newAmount);
            tAmount += profit.mul(dividendRatio).div(10**2);
            if(haveTopUser(msg.sender)){
                bonusOfTopUser[topUser[msg.sender]] += profit.mul(bonusRatioOfhalve).div(10**2);
            }
        }
        if(newAmount > receiveAmount){
            tAmount -= newAmount.sub(receiveAmount);
        }

        devAmount = newAmount;
        devRandomAllocation = randomAllocation;
        devRandomAllocationIndex = allocationIndex;

        swapETHForTokens(newAmount, msg.sender, path);

        saltAmount += receiveAmount;
        saltTimestamp = block.timestamp;
        lastSwapTimestampOfUser[msg.sender] = block.timestamp;
        return newAmount;
    }

    function swapETHForTokens(uint256 amount, address receiveAccount, address[] memory path) private {
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            receiveAccount, // Burn address
            block.timestamp.add(300)
        );
    }
 
    function generateRandomNumber(uint256 amount) public view returns(uint256) {
        uint256 _saltByUniswapV2Router = generateRandomNumberFromUniswapV2Router(amount);
        uint256 _gasleft = gasleft();
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, saltTimestamp, _gasleft, saltAmount, _saltByUniswapV2Router)));
        return randomNumber.mod(10);
    }
    function generateRandomNumberFromUniswapV2Router(uint256 amount) public view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = BUSD;
        uint[] memory amounts =  uniswapV2Router.getAmountsOut(amount , path);
        uint256 temp;
        for (uint i = 0; i < amounts.length; i++) {
            temp = temp.add(amounts[i]);
        }
        return temp;
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance of this address is zero");
        payable(msg.sender).transfer(balance);
    }

}