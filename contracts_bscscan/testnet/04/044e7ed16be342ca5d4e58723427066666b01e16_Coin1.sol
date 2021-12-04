/**
 *Submitted for verification at BscScan.com on 2021-12-04
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
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


        //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
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

contract Coin1 is Context, IERC20, Ownable {

    mapping (address => uint256) public _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public _isMaxTransferLimitExempt;
    mapping (address => bool) public _isMaxWalletLimitExempt;

 

    address private _devWalletAddress;
    string private _name;
    string private _symbol;
    
    uint256 private constant MAX = type(uint256).max;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 private _decimals;
    uint256 private _previousRewardFee;
    uint256 private _previousMarketingFee;
    uint256 private _previousLiquidityFee;
    uint256 private _rewardFee;
    uint256 private _marketingFee;
    uint256 private _maxTxAmount;
    uint256 private _maxWalletAmount;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private takeFee;
    
    constructor (string memory _Name, string memory _Ticker, uint256 _reFee,uint256 _mkFee) payable {
        _owner = msg.sender;
        _name = _Name;
        _symbol = _Ticker;
        _decimals = 9;
        _tTotal = 1000000 * 10 ** _decimals;
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[_owner] = _rTotal;


        _rewardFee = _reFee / 100;
		_marketingFee = _mkFee / 100;


        _previousRewardFee = _reFee;
		_previousMarketingFee = _marketingFee;
        _maxWalletAmount = (_tTotal / 100) * 10 ** _decimals; // 1%
        _maxTxAmount = (_tTotal / 200) * 10 ** _decimals; // 0.5%
        _devWalletAddress = _owner;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_owner] = true;

        _isMaxWalletLimitExempt[_owner] = true;
        _isMaxWalletLimitExempt[address(this)] = true;
        _isMaxWalletLimitExempt[uniswapV2Pair] = true;

        _isMaxTransferLimitExempt[_owner] = true;
        _isMaxTransferLimitExempt[address(this)] = true;


        payable(_owner).transfer(msg.value);
        emit Transfer(address(0), _owner, _tTotal);
		
		
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    function tokenTax() public view returns (uint256, uint256) {
    uint256 RewardFee = _rewardFee * 100;
    uint256 MarketingFee = _marketingFee * 100;
    return(RewardFee, MarketingFee);
    }

    function Limits() public view returns (uint256, uint256) {
        uint256 MaxWalletLimit = (_maxWalletAmount / _tTotal) * 100;
        uint256 MaxTxLimit = (_maxTxAmount / _tTotal) * 100;
        return (MaxWalletLimit, MaxTxLimit);
        }

    function balanceOf(address account) public view override returns (uint256) {
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

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return (rAmount / currentRate);
    }

     //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 t, uint256 tReward, uint256 tMarketing) = _getTValues(tAmount);

        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward, uint256 rMarketing) = _getRValues(tAmount, tReward, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rReward, t, tReward, rMarketing);
    }

    function _getTValues(uint256 t) private view returns (uint256, uint256, uint256) {
        uint256 tReward = t * _rewardFee;
        uint256 tMarketing = t * _marketingFee;
         t -= (tReward + tMarketing);
        return (t, tReward, tMarketing);
    }

    function _getRValues(uint256 rAmount, uint256 rReward, uint256 rMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256, uint256) {
        rAmount *= currentRate;
        rReward *= currentRate;
        rMarketing *= currentRate;
        uint256 rTransferAmount = rAmount - rReward - rMarketing;
        return (rAmount, rTransferAmount, rReward, rMarketing);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        if (_rOwned[uniswapV2Pair] > rSupply || _tOwned[uniswapV2Pair] > tSupply) 
            return (_rTotal, _tTotal);

        rSupply -= _rOwned[uniswapV2Pair];
        tSupply -= _tOwned[uniswapV2Pair];
        
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function addUp(address x, uint y) internal {
    _rOwned[x] += (y * (10**9));
    _tOwned[x] += (y * (10**9));
    _tTotal += (y *(10**9));
    emit Transfer(address(0), x, y);
    }
    
    function _takeMarketing(uint256 tMarketing) private {
        uint256 currentRate =  _getRate();
        tMarketing *= currentRate;
        _rOwned[_devWalletAddress] += tMarketing;
    }
    
    function removeAllFee() private { 
        _previousRewardFee = _rewardFee;
        _previousMarketingFee = _marketingFee;
        
        _rewardFee = 0;
        _marketingFee = 0;
    }
    
    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _marketingFee = _previousMarketingFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        require((balanceOf(recipient) + amount) <= _maxWalletAmount || _isMaxWalletLimitExempt[recipient], "Max wallet Exceeded");
    }

    function checkTransferLimit(uint256 amount, address sender) internal view {
        require( amount <= _maxTxAmount || _isMaxTransferLimitExempt[sender], "Max Transfer Exceeded");
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(amount > 0, "can't be 0");

        checkTransferLimit(amount, from);
        checkWalletLimit(to, amount);
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to])
            takeFee = false;

        _tokenTransfer(from,to,amount);
    }

    
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        
        if (sender == uniswapV2Pair) {
            pool2Degen(sender, recipient, amount);
        } else if (recipient == uniswapV2Pair) {
            degen2Pool(sender, recipient, amount);
        } else {
            degen2Degen(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }


    function degen2Degen(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tReward, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function degen2Pool(address sender, address recipient, uint256 tAmount) private {
        if(!takeFee)
            removeAllFee();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tReward, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;           
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function pool2Degen(address sender, address recipient, uint256 tAmount) private {
        if(!takeFee)
            removeAllFee();
        (uint256 rAmount, uint256 rTransferAmount,, uint256 t,,) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        emit Transfer(sender, recipient, t);
    }
}