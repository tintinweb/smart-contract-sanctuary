/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ Pancake Swap Connection \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


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
    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FinalTestCoin6 is Context, IBEP20, Ownable {
    using Address for address;
    using SafeMath for uint256;
    mapping (address => uint256) private _reflectOwned;
    mapping (address => uint256) private _takeOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isDEXBuyFee;
    mapping (address => bool) private _isDEXSellFee;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _takeTotal = 280 * 10**6 * 10**9;
    uint256 private _reflectTotal = (MAX - (MAX % _takeTotal));
    uint256 private _takeFeeTotal;
    string private constant _name = "FinalTestCoin6 v26";
    string private constant _symbol = "FTC6";
    uint8 private constant _decimals = 9;
    bool public _taxFeeFlag = false;
    uint256 public _taxFee = 0;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _liquiditySellFee = 25;
    uint256 private _previousLiquiditySellFee = _liquiditySellFee;
    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;
    bool public isIntoLiquifySwap;
    bool public swapAndLiquifyEnabled = true;

    uint256 private _maxLoopCount = 100;
    uint256 private _maximumValueOfTransaction = 280 * 10**6 * 10**9 ;
    uint256 private numTokensSellToAddToLiquidity = 10 * 10**9 ;

    event SwapAndLiquifyEvent(
        uint256 coinsForSwapping,
        uint256 bnbIsReceived,
        uint256 coinsThatWasAddedIntoLiquidity
    );

    event LiquifySwapUpdatedEnabled(bool enabled);
    event SetTaxFeePercent(uint value);
    event SetTaxFeeFlag(bool flag);
    event SetMaxLoopCount(uint value);
    event SetPancakeSwapPairAddress(address pair);
    event SetMaxTxPercent(uint value);
    event SetLiquidityFeePercent(uint value);
    event ExcludedFromFee(address _address);
    event ExcludedFromReward(address _address);
    event IncludeInReward(address _address);
    event IncludeInFee(address _address);
    event BNBReceived(address _address);
    event Delivery(address _address,  uint256 amount);
    event AddLiquidity(uint256 coin_amount, uint256 bnb_amount);
    event SwapAndLiquifyEnabled(bool flag);

    modifier lockSwaping {
        isIntoLiquifySwap = true;
        _;
        isIntoLiquifySwap = false;
    }

    constructor () {
        _reflectOwned[_msgSender()] = _reflectTotal;
        // PancakeSwap Router address: (BSC testnet) 0xD99D1c33F9fC3444f8101754aBC46c52416550D1  (BSC mainnet) V2 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a pancakeswap pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        address payable _pancakeFactory = payable(0x3328C0fE37E8ACa9763286630A9C33c23F0fAd1A);

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_pancakeFactory] = true;

        emit Transfer(address(0), _msgSender(), _takeTotal);
    }

    // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ BEP20 functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _takeTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _takeOwned[account];
        return tokenFromReflection(_reflectOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));

        return true;
    }


    function _getCurrentSupply() private view returns(uint256, uint256) {
        require(_excluded.length <= _maxLoopCount, "The number of loop iterations in _getCurrentSupply is greater than the allowed value.");
        
        uint256 rSupply = _reflectTotal;
        uint256 tSupply = _takeTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectOwned[_excluded[i]] > rSupply || _takeOwned[_excluded[i]] > tSupply) return (_reflectTotal, _takeTotal);
            rSupply = rSupply.sub(_reflectOwned[_excluded[i]]);
            tSupply = tSupply.sub(_takeOwned[_excluded[i]]);
        }
        if (rSupply < _reflectTotal.div(_takeTotal)) return (_reflectTotal, _takeTotal);

        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ Fees calculate functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    function totalFees() external view returns (uint256) {
        return _takeFeeTotal;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        emit SetTaxFeePercent(taxFee);
        _taxFee = taxFee;
    }

    function setTaxFeeFlag(bool flag) external onlyOwner() {
        emit SetTaxFeeFlag(flag);
        _taxFeeFlag = flag;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        emit SetLiquidityFeePercent(liquidityFee);
        _liquidityFee = liquidityFee;
    }

    function setLiquiditySellFeePercent(uint256 liquiditySellFee) external onlyOwner() {
        _liquiditySellFee = liquiditySellFee;
    }
    
    function setMaxLoopCount(uint256 maxLoopCount) external onlyOwner() {
        emit SetMaxLoopCount(maxLoopCount);
        _maxLoopCount = maxLoopCount;
    }


    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        emit SetMaxTxPercent(maxTxPercent);
        _maximumValueOfTransaction = _takeTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function setNumTokensSellToAddToLiquidity(uint256 amount) external onlyOwner() {
        numTokensSellToAddToLiquidity = amount;
    }    


    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _reflectTotal = _reflectTotal.sub(rFee);
        _takeFeeTotal = _takeFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 takeAmountToTransfer, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 reflectAmount, uint256 reflectAmountToTransfer, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());

        return (reflectAmount, reflectAmountToTransfer, rFee, takeAmountToTransfer, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 takeAmountToTransfer = tAmount.sub(tFee).sub(tLiquidity);

        return (takeAmountToTransfer, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 reflectAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 reflectAmountToTransfer = reflectAmount.sub(rFee).sub(rLiquidity);

        return (reflectAmount, reflectAmountToTransfer, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

    // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ Withdraw function \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    function rescueTokensFromContract(uint256 amount) external onlyOwner {
        if(amount == 0 ){ // BNB
            payable(msg.sender).transfer(address(this).balance);
        }else{ // TCG2
            _tokenTransfer(address(this), _msgSender(), amount, false);
        }
    }

    // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ Fees managing meber functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ Fees group mebership functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


    function excludeFromReward(address account) external onlyOwner() {
        emit ExcludedFromReward(account);
        require(!_isExcluded[account], "Account is already excluded");
        if(_reflectOwned[account] > 0) {
            _takeOwned[account] = tokenFromReflection(_reflectOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        emit IncludeInReward(account);
        require(_excluded.length <= _maxLoopCount, "The number of loop iterations in includeInReward is greater than the allowed value.");
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _takeOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        emit ExcludedFromFee(account);
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        emit IncludeInFee(account);
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function includeFromDexWithSellFee(address account) external onlyOwner {
        _isDEXSellFee[account] = true;
    }

    function excludeInDexWithSellFee(address account) external onlyOwner {
        _isDEXSellFee[account] = false;
    }

    function isDexWithSellFee(address account) public view returns(bool) {
        return _isDEXSellFee[account];
    }

    function includeFromDexWithBuyFee(address account) external onlyOwner {
        _isDEXBuyFee[account] = true;
    }

    function excludeInDexWithBuyFee(address account) external onlyOwner {
        _isDEXBuyFee[account] = false;
    }

    function isDexWithBuyFee(address account) public view returns(bool) {
        return _isDEXBuyFee[account];
    }


    // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ LP functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        emit SwapAndLiquifyEnabled(_enabled);
        swapAndLiquifyEnabled = _enabled;

        emit LiquifySwapUpdatedEnabled(_enabled);
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _reflectOwned[address(this)] = _reflectOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _takeOwned[address(this)] = _takeOwned[address(this)].add(tLiquidity);
    }

    function swapAndLiquify(uint256 contractTokenBalance) public {
        require(_msgSender() == owner() || _msgSender() == address(this));
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBNB(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);


        // add liquidity to pancakswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquifyEvent(half, newBalance, otherHalf);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        emit AddLiquidity(tokenAmount, bnbAmount);
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ Reflection functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        emit Delivery(sender, tAmount);
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 reflectAmount,,,,,) = _getValues(tAmount);
        _reflectOwned[sender] = _reflectOwned[sender].sub(reflectAmount);
        _reflectTotal = _reflectTotal.sub(reflectAmount);
        _takeFeeTotal = _takeFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _takeTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 reflectAmount,,,,,) = _getValues(tAmount);
            return reflectAmount;
        } else {
            (,uint256 reflectAmountToTransfer,,,,) = _getValues(tAmount);
            return reflectAmountToTransfer;
        }
    }

    function tokenFromReflection(uint256 reflectAmount) public view returns(uint256) {
        require(reflectAmount <= _reflectTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();

        return reflectAmount.div(currentRate);
    }

    // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ Custom transfer functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maximumValueOfTransaction, "Transfer amount exceeds the maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= _maximumValueOfTransaction){contractTokenBalance = _maximumValueOfTransaction;}

        bool overMinimumCoinBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinimumCoinBalance &&
            !isIntoLiquifySwap &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = _taxFeeFlag;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isDEXSellFee[to] && !_isExcludedFromFee[from]){     
            takeFee = true;
        } else if(_isDEXBuyFee[from] && !_isExcludedFromFee[to]){
            takeFee = true;
            _previousLiquidityFee = _liquidityFee;
            _liquidityFee = _liquiditySellFee;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
        _liquidityFee = _previousLiquidityFee;
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        if(!takeFee){removeAllFee();}

        (uint256 reflectAmount, uint256 reflectAmountToTransfer, uint256 rFee, uint256 takeAmountToTransfer, uint256 tFee, uint256 tLiquidity) = _getValues(amount);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {

            // Transfer FROM an account excluded from the list of reward recipients.
            _takeOwned[sender] = _takeOwned[sender].sub(amount);
            _reflectOwned[sender] = _reflectOwned[sender].sub(reflectAmount);
            _reflectOwned[recipient] = _reflectOwned[recipient].add(reflectAmountToTransfer);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {

            // Transfer TO an account excluded from the list of reward recipients.
            _reflectOwned[sender] = _reflectOwned[sender].sub(reflectAmount);
            _takeOwned[recipient] = _takeOwned[recipient].add(takeAmountToTransfer);
            _reflectOwned[recipient] = _reflectOwned[recipient].add(reflectAmountToTransfer);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {

            // Transfer BETWEEN accounts excluded from the list of reward recipients.
            _takeOwned[sender] = _takeOwned[sender].sub(amount);
            _reflectOwned[sender] = _reflectOwned[sender].sub(reflectAmount);
            _takeOwned[recipient] = _takeOwned[recipient].add(takeAmountToTransfer);
            _reflectOwned[recipient] = _reflectOwned[recipient].add(reflectAmountToTransfer);

        } else {

             // Standart transfer BETWEEN accounts included in the list of reward recipients.
            _reflectOwned[sender] = _reflectOwned[sender].sub(reflectAmount);
            _reflectOwned[recipient] = _reflectOwned[recipient].add(reflectAmountToTransfer);

        }

        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, takeAmountToTransfer);

        if(!takeFee){restoreAllFee();}
    }
}