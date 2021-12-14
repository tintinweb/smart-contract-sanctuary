/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.10;

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 public _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
   
    function owner() public view virtual returns (address) {
        return _owner;
    }
   
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
   
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }



        //Locks the contract for owner for the amount of time provided
    function RenounceOwnership(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = time;
        emit OwnershipTransferred(_owner, address(0));
    }
   
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock.");
        require(block.timestamp > _lockTime , "Contract is locked.");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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

contract CryptoClit is Context, IERC20, Ownable {

    IUniswapV2Router02 public uniswapV2Router;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isMaxTransferLimitExempt;
    mapping (address => bool) private _isMaxWalletLimitExempt;
    address[] private _excluded;
    address private _devWalletAddress;
    address public _burnWallet;
    address public uniswapV2Pair;
    string private _name;
    string private _symbol;
    uint256 private constant MAX = type(uint256).max;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 private _decimals;
    uint256 private _rewardFee;
    uint256 private _marketingFee;
    uint256 private _liquidityFee;
    uint256 private _maxTxAmount;
    uint256 private _maxWalletAmount;
    uint256 private numTokensSellToAddToLiquidity;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
   
    constructor (string memory _NAME, string memory _SYMBOL, uint256 _reFee, uint256 _mkFee, uint256 _lpFee) payable {
        _name = _NAME;
        _symbol = _SYMBOL;
        _decimals = 9;

        _tTotal = 1000000 * (10 ** _decimals);
        _rTotal = (MAX - (MAX % _tTotal));
        _maxWalletAmount = _tTotal; // 2%
        _maxTxAmount = _tTotal; // 0.5%

        _rewardFee = _reFee;
        _marketingFee = _mkFee;
        _liquidityFee = _lpFee;
       
        numTokensSellToAddToLiquidity = (_tTotal * 5 / 10000) * (10 ** _decimals);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
       

        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_burnWallet] = true;
       

        _isMaxWalletLimitExempt[address(this)] = true;
        _isMaxWalletLimitExempt[uniswapV2Pair] = true;
        _isMaxWalletLimitExempt[_owner] = true;
        _isMaxWalletLimitExempt[_burnWallet] = true;

        _isMaxTransferLimitExempt[_burnWallet] = true;
        _isMaxTransferLimitExempt[_owner] = true;
        _isMaxTransferLimitExempt[address(this)] = true;
        _isMaxTransferLimitExempt[uniswapV2Pair] = true;

        _isExcluded[uniswapV2Pair] = true;
        _isExcluded[_burnWallet] = true;
       
        _burnWallet = 0x000000000000000000000000000000000000dEaD;
        _devWalletAddress = _owner;
        _rOwned[_owner] = _rTotal;
   
        _owner = msg.sender;
        payable(_owner).transfer(msg.value);
        emit Transfer(address(0), _owner, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function percentageHolderLimits() public view returns (uint256, uint256) {
        uint256 walletPercentage = 100 * (_maxWalletAmount / _tTotal);
        uint256 txPercentage = 100 * (_maxTxAmount / _tTotal); 
        return (walletPercentage, txPercentage);
        }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return _transfer(sender, recipient, amount);

    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return (rAmount / currentRate);
    }

    receive() external payable {}


    function withdrawFromContract() external returns(bool) {

        uint256 contractBalance = address(this).balance;

        payable(_devWalletAddress).transfer(contractBalance);
        return true;
    }

    function _takeTax(uint256 tMarketing, uint256 rReward, uint256 tReward, uint256 tLiquidity) private {

        uint256 currentRate =  _getRate();

        uint256 rMarketing = tMarketing * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;

        _rOwned[_devWalletAddress] += rMarketing;
        _rOwned[address(this)] += rLiquidity;

        _rTotal -= rReward;
        _tFeeTotal += tReward;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tReward, uint256 tMarketing, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward) = _getRValues(tAmount, tReward, tMarketing, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rReward, tTransferAmount, tReward, tMarketing, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tReward = calculateRewardFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tReward - tMarketing - tLiquidity;
        return (tTransferAmount, tReward, tMarketing, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tReward, uint256 tMarketing, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rReward = tReward * currentRate;   
        uint256 rMarketing = tMarketing * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rReward - rMarketing - rLiquidity;
        return (rAmount, rTransferAmount, rReward);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {

        if (_rOwned[uniswapV2Pair] > _rTotal || _tOwned[uniswapV2Pair] > _tTotal) return (_rTotal, _tTotal);

        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;


        rSupply -= _rOwned[uniswapV2Pair];
        tSupply -= _tOwned[uniswapV2Pair];

        rSupply -= _rOwned[_burnWallet];
        tSupply -= _tOwned[_burnWallet];
    
        if (rSupply < (_rTotal / _tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
   
    function calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _rewardFee) / 100;
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _marketingFee) / 100;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _liquidityFee) / 100;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view returns(bool) {
        require(balanceOf(recipient) + amount <= _maxWalletAmount || _isMaxWalletLimitExempt[recipient], "Max wallet Exceeded");
        return true;
    }

    function checkTransferLimit(uint256 amount, address sender, address recipient) internal view returns(bool) {
        require( amount <= _maxTxAmount || (_isMaxTransferLimitExempt[sender] && _isMaxTransferLimitExempt[recipient]), "Max Transfer Exceeded");
        return true;
    }

    function removeAllFee() private {

        _rewardFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
    }
   
    function restoreAllFee() private {

        _rewardFee = 5;
        _marketingFee = 3;
        _liquidityFee = 2;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns(bool) {

        checkTransferLimit(amount, from, to);
        checkWalletLimit(to, amount);
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        _tokenTransfer(from,to,amount,takeFee);
        return true;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half); 
        uint256 newBalance = address(this).balance - initialBalance;
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        if(!takeFee)
            removeAllFee();

       
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
       
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward, uint256 tTransferAmount, uint256 tReward, uint256 tMarketing, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] +=rTransferAmount;
        _takeTax(tMarketing, rReward, tReward, tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward, uint256 tTransferAmount, uint256 tReward, uint256 tMarketing, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;          
        _takeTax(tMarketing, rReward, tReward, tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward, uint256 tTransferAmount, uint256 tReward, uint256 tMarketing, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeTax(tMarketing, rReward, tReward, tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}