/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

contract BRANDON is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1*10**(12+18);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string public _name = "Token Brandon";
    string public _symbol = "BRANDON";
    uint256 public _decimals = 18;

    // Fees

    struct FeeSet {
        uint256 rewardFee;
        uint256 marketingFee;
        uint256 distributionFee;
        uint256 devFee;
        uint256 burnFee;
        uint256 liquidityFee;
    }

    struct FeeAddresses {
        address rewardFund;
        address marketingFund;
        address devFund;
        address burnAddress;
    }

    address public BURN = 0x000000000000000000000000000000000000dEaD;
    uint256 public ZERO = 0;
    address private _rewardWalletAddress;
    address private _marketingWalletAddress;

    FeeSet public buyFees;
    FeeSet public buyWhaleFee;

    FeeSet public sellFees;
    FeeSet public sellWhaleFee;

    FeeAddresses private feeAddresses;

    uint256 private _taxFee;
    uint256 private _previousTaxFee;

    uint256 private _devFee;
    uint256 private _previousDevFee;

    uint256 private _marketingFee;
    uint256 public _previousMarketingFee;

    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;

    uint256 private _rewardFee;
    uint256 private _previousRewardFee;

    uint256 private _burnFee;
    uint256 private _previousBurnFee;

    // Uniswap Router
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 public denominator = 1000;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public numTokensSellToAddToLiquidity =(_tTotal * 1 / denominator); // 0.1%
    uint256 public whaleAmount = (_tTotal * 10/denominator); // 1%

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
    
    constructor (address _rewardFund, address _marketingFund, address _devFund) {

        setSellFees(0, 0, 10, 30, 0, 80);
        setBuyFees(30, 0, 10, 0, 0, 60);
        setWhaleSellFee(0, 0, 10, 30, 0, 80);
        setWhaleBuyFee(30, 10, 0, 0, 60, 60);

        feeAddresses.burnAddress = BURN;
        changeFeeStatus(feeAddresses.burnAddress, true);
        changeRewardStatus(feeAddresses.burnAddress, true);
        setFeeAddresses(_rewardFund, _marketingFund, _devFund);
        
        _rOwned[_msgSender()] = _rTotal;
        
        // pancakeswap 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // ropsten 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        
        //exclude owner and this contract from fee

        changeFeeStatus(_msgSender(), true);
        changeRewardStatus(_msgSender(), true);

        changeFeeStatus(address(this), true);
        changeRewardStatus(address(this), true);
    
        _owner = _msgSender();
        emit Transfer(address(0), owner(), _tTotal);
		
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
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function changeRewardStatus(address account, bool value) public onlyOwner {
        if(value) {
            if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        } else {
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == account) {
                    _excluded[i] = _excluded[_excluded.length - 1];
                    _tOwned[account] = 0;
                    _isExcluded[account] = false;
                    _excluded.pop();
                    break;
                }
            }
        }
    }

    
    /// @dev FEES

    function changeFeeStatus(address account, bool value) public onlyOwner {
        _isExcludedFromFee[account] = value;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tDev);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tDev = calculateDevFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tDev);
        return (tTransferAmount, tFee, tLiquidity, tDev);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rDev = tDev.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rDev);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        if(tLiquidity > 0) {
            uint256 currentRate =  _getRate();
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);    
            emit Transfer(sender, address(this), tLiquidity);   
        }
        
    }
    
    function _takeDev(address sender, uint256 tDev) private {
        if(tDev > 0) {
            uint256 currentRate =  _getRate();
            uint256 rDev = tDev.mul(currentRate);
            _rOwned[feeAddresses.devFund] = _rOwned[feeAddresses.devFund].add(rDev);
            if(_isExcluded[feeAddresses.devFund])
                _tOwned[feeAddresses.devFund] = _tOwned[feeAddresses.devFund].add(tDev);

            emit Transfer(sender, feeAddresses.devFund, tDev);
        }
    }

    function _takeReward(address sender, uint256 tReward) private {
        if(tReward > 0) {
            uint256 currentRate =  _getRate();
            uint256 rReward = tReward.mul(currentRate);
            _rOwned[feeAddresses.rewardFund] = _rOwned[feeAddresses.rewardFund].add(rReward);
            if(_isExcluded[feeAddresses.rewardFund])
                _tOwned[feeAddresses.rewardFund] = _tOwned[feeAddresses.rewardFund].add(tReward);

            emit Transfer(sender, feeAddresses.rewardFund, tReward);
        }
    }

    function _takeMarketing(address sender, uint256 tMarketing) private {
        if(tMarketing > 0) {
            uint256 currentRate =  _getRate();
            uint256 rMarketing = tMarketing.mul(currentRate);
            _rOwned[feeAddresses.marketingFund] = _rOwned[feeAddresses.marketingFund].add(rMarketing);
            if(_isExcluded[feeAddresses.marketingFund])
                _tOwned[feeAddresses.marketingFund] = _tOwned[feeAddresses.marketingFund].add(tMarketing); 

            emit Transfer(sender, feeAddresses.marketingFund, tMarketing);
        }
    }

    function _takeBurn(address sender, uint256 tBurn) private {
        if(tBurn > 0) {
            uint256 currentRate =  _getRate();
            uint256 rBurn = tBurn.mul(currentRate);
            _rOwned[feeAddresses.burnAddress] = _rOwned[feeAddresses.burnAddress].add(rBurn);
            if(_isExcluded[feeAddresses.burnAddress])
                _tOwned[feeAddresses.burnAddress] = _tOwned[feeAddresses.burnAddress].add(tBurn);

            emit Transfer(sender, feeAddresses.burnAddress, tBurn);
        }
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(denominator);
    }

    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_devFee).div(denominator);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(denominator);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(denominator);
    }

    function calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_rewardFee).div(denominator);
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(denominator);
    }

    function setWhalePercent(uint256 _whalePercent) public onlyOwner {
        whaleAmount = (_tTotal * _whalePercent/denominator);
    }
    
    function removeAllFee() private { 
        _previousTaxFee = _taxFee;
        _previousDevFee = _devFee;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousRewardFee = _rewardFee;
        _previousBurnFee = _burnFee;
        
        _taxFee = 0;
        _devFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
        _rewardFee = 0;
        _burnFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _devFee = _previousDevFee;
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
        _rewardFee = _previousRewardFee;
        _burnFee = _previousBurnFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
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

        // if selling
        if(automatedMarketMakerPairs[to]) {
            _liquidityFee = sellFees.liquidityFee;
            _rewardFee = sellFees.rewardFee;
            _marketingFee = sellFees.marketingFee;
            _taxFee = sellFees.distributionFee;
            _devFee = sellFees.devFee;
            _burnFee = sellFees.burnFee;


            //if selling more than 1% apply whale fee
            if(amount >= whaleAmount) {
                _liquidityFee = sellWhaleFee.liquidityFee;
                _rewardFee = sellWhaleFee.rewardFee;
                _marketingFee = sellWhaleFee.marketingFee;
                _taxFee = sellWhaleFee.distributionFee;
                _devFee = sellWhaleFee.devFee;
                _burnFee = sellWhaleFee.burnFee;
            }
        } else if (automatedMarketMakerPairs[from]) { // if buying
            _liquidityFee = buyFees.liquidityFee;
            _rewardFee = buyFees.rewardFee;
            _marketingFee = buyFees.marketingFee;
            _taxFee = buyFees.distributionFee;
            _devFee = buyFees.devFee;
            _burnFee = buyFees.burnFee;

            // if buying more than 1% apply whale fee
            if(amount >= whaleAmount) {
                _liquidityFee = buyWhaleFee.liquidityFee;
                _rewardFee = buyWhaleFee.rewardFee;
                _marketingFee = buyWhaleFee.marketingFee;
                _taxFee = buyWhaleFee.distributionFee;
                _devFee = buyWhaleFee.devFee;
                _burnFee = buyWhaleFee.burnFee;
            }
        } else { // if making simple transfer
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half); 

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
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
            0, // slippage is unavoidable
            0, // slippage is unavoidable
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
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        
        uint256 _tFee = calculateBurnFee(tAmount);
        uint256 _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeBurn(sender, _tFee);

       _tFee = calculateMarketingFee(tAmount);
        _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeMarketing(sender, _tFee);
        
        _tFee = calculateRewardFee(tAmount);
        _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeReward(sender, _tFee);
        
        _takeLiquidity(sender, tLiquidity);
        _takeDev(sender, tDev);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        
        uint256 _tFee = calculateBurnFee(tAmount);
        uint256 _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeBurn(sender, _tFee);

        _tFee = calculateMarketingFee(tAmount);
        _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeMarketing(sender, _tFee);
        
        _tFee = calculateRewardFee(tAmount);
        _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeReward(sender, _tFee);

        _takeLiquidity(sender, tLiquidity);
        _takeDev(sender, tDev);
        
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);

        uint256 _tFee = calculateBurnFee(tAmount);
        uint256 _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeBurn(sender, _tFee);

        _tFee = calculateMarketingFee(tAmount);
        _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeMarketing(sender, _tFee);
        
        _tFee = calculateRewardFee(tAmount);
        _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeReward(sender, _tFee);

        _takeLiquidity(sender, tLiquidity);
        _takeDev(sender, tDev);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }
        
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        
        uint256 _tFee = calculateBurnFee(tAmount);
        uint256 _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeBurn(sender, _tFee);

        _tFee = calculateMarketingFee(tAmount);
        _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeMarketing(sender, _tFee);
        
        _tFee = calculateRewardFee(tAmount);
        _rFee = _tFee.mul(_getRate());
        tTransferAmount = tTransferAmount.sub(_tFee);
        rTransferAmount = rTransferAmount.sub(_rFee);
        _takeReward(sender, _tFee);

        _takeLiquidity(sender, tLiquidity);
        _takeDev(sender, tDev);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function setRouterAddress(address newRouter) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
    }

    function setNumTokensSellToAddToLiquidity(uint256 amountToUpdate) external onlyOwner {
        numTokensSellToAddToLiquidity = amountToUpdate;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
		require(pair != uniswapV2Pair, "MemeKing: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
		_setAutomatedMarketMakerPair(pair, value);
	}

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "MemeKing: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
        changeRewardStatus(pair, value);
	}

    function setFeeAddresses(address _rewardFund, address _marketingFund, address _devFund) public onlyOwner {
        if(isExcludedFromFee(feeAddresses.rewardFund))
            changeFeeStatus(feeAddresses.rewardFund, false);
        if(isExcludedFromFee(feeAddresses.marketingFund))
            changeFeeStatus(feeAddresses.marketingFund, false);
        if(isExcludedFromFee(feeAddresses.devFund))
            changeFeeStatus(feeAddresses.devFund, false);

        if(isExcludedFromReward(feeAddresses.rewardFund))
            changeRewardStatus(feeAddresses.rewardFund, false);
        if(isExcludedFromReward(feeAddresses.marketingFund))
            changeRewardStatus(feeAddresses.marketingFund, false);
        if(isExcludedFromReward(feeAddresses.devFund))
            changeRewardStatus(feeAddresses.devFund, false);

        feeAddresses.rewardFund = _rewardFund;
        feeAddresses.marketingFund = _marketingFund;
        feeAddresses.devFund = _devFund;

        changeFeeStatus(feeAddresses.rewardFund, true);
        changeFeeStatus(feeAddresses.marketingFund, true);
        changeFeeStatus(feeAddresses.devFund, true);

        changeRewardStatus(feeAddresses.rewardFund, true);
        changeRewardStatus(feeAddresses.marketingFund, true);
        changeRewardStatus(feeAddresses.devFund, true);
    }

    function setSellFees(uint256 _liqFee, uint256 _reFee, uint256 _markFee, uint256 _disFee, uint256 _dFee, uint256 _buFee) public onlyOwner {
        sellFees.liquidityFee = _liqFee;
        sellFees.rewardFee = _reFee;
        sellFees.marketingFee = _markFee;
        sellFees.distributionFee = _disFee;
        sellFees.devFee = _dFee;
        sellFees.burnFee= _buFee;
    }

    function setBuyFees(uint256 _liqFee, uint256 _reFee, uint256 _markFee, uint256 _disFee, uint256 _dFee, uint256 _buFee) public onlyOwner {
        buyFees.liquidityFee = _liqFee;
        buyFees.rewardFee = _reFee;
        buyFees.marketingFee = _markFee;
        buyFees.distributionFee = _disFee;
        buyFees.devFee = _dFee;
        buyFees.burnFee= _buFee;
    }

    function setWhaleBuyFee(uint256 _liqFee, uint256 _reFee, uint256 _markFee, uint256 _disFee, uint256 _dFee, uint256 _buFee) public onlyOwner {
        buyWhaleFee.liquidityFee = _liqFee;
        buyWhaleFee.rewardFee = _reFee;
        buyWhaleFee.marketingFee = _markFee;
        buyWhaleFee.distributionFee = _disFee;
        buyWhaleFee.devFee = _dFee;
        buyWhaleFee.burnFee= _buFee;
    }

    function setWhaleSellFee(uint256 _liqFee, uint256 _reFee, uint256 _markFee, uint256 _disFee, uint256 _dFee, uint256 _buFee) public onlyOwner {
        sellWhaleFee.liquidityFee = _liqFee;
        sellWhaleFee.rewardFee = _reFee;
        sellWhaleFee.marketingFee = _markFee;
        sellWhaleFee.distributionFee = _disFee;
        sellWhaleFee.devFee = _dFee;
        sellWhaleFee.burnFee= _buFee;
    }



}