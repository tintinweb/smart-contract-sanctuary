/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;
contract BUSDContract {
    function balanceOf(address account) external view returns (uint256) {}
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event MaxTxUpdate(address indexed from, uint256 value);
    
    event MinimumSleepUpdate(address indexed from, uint256 value);
}

contract Context {
    constructor () internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "low-lvl call fail");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "lowlvl call with val fail");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "low bal 4 call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "call 2 nocontract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract HKUN is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    BUSDContract BUSD = BUSDContract(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _interest;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private exclude;
    mapping(address => bool)private excludeFromRewards;
    
    mapping(address => uint256) private lastClaim;
    mapping(address => uint256) private totalHKUNClaimed;
    mapping(address => uint256) private totalBUSDClaimed;
    
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10_000_000_000 * 10 ** uint256(_decimals);
    uint256 public maxTxAllowed =  50_000_000 * 10 ** uint256(_decimals);

    uint256 private totalTaxCollected;
    uint256 private totalLiquidityCollected;

    uint256 public redistributionFee = 5;
    uint256 public burnFee = 4;
    uint256 public liquidityFee = 3;
    uint256 public marketingFee = 2;
    uint256 public charityFee = 1;
    
    string private constant _name = "Hakuna Matata";
    string private constant _symbol = "HKUN";
    
    uint256 private minClaimSleep = 6 hours;
    uint256 private tokensForRedistribution; 
    uint256 private tokensForLiquidity;

    uint256 private totalHKUNRedistributed;
    uint256 private totalBUSDRedistributed;
    uint256 private totalTokensBurnt;
    
    uint256 public marketingToken;
    uint256 public charityToken;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    constructor(address multiSigOwnerWallet) ReentrancyGuard() public {
        transferOwnership(multiSigOwnerWallet);
        
        exclude[address(this)] = true;
        exclude[owner()] = true;
        exclude[DEAD] = true;
        
        excludeFromRewards[address(this)] = true;
        excludeFromRewards[owner()] = true;
        excludeFromRewards[DEAD] = true;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeSwap Router
        address PairCreated = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = PairCreated;
        excludeFromRewards[PairCreated] = true;
        
        _balances[owner()] = _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function viewDividend(address account) public view returns (uint256){
        if (excludeFromRewards[account]) {
            return 0;

        } else {
            uint256 dividend = totalTaxCollected.sub(_interest[account]);
            uint256 proportion = _balances[account];
            return dividend.mul(proportion).div(_totalSupply.sub(totalTokensBurnt));
        }
    }
    
    function lastClaimTime(address account) public view returns (uint256) {
        return lastClaim[account];
    }
    
    function nextClaimTime(address account) public view returns (uint256) {
        return lastClaimTime(account).add(minClaimSleep);
    }
    
    function showTotalHKUNClaimed(address account) external view returns (uint256) {
        return totalHKUNClaimed[account];
    }
    
    function showTotalBUSDClaimed(address account) external view returns (uint256) {
        return totalBUSDClaimed[account];
    }

    function isExcludedfromFee(address account) external view returns (bool) {
        return exclude[account];
    }

    function isExcludedFromRewards(address account) external view returns (bool) {
        return excludeFromRewards[account];
    }

    function removeFromReward(address account) external onlyOwner {
        excludeFromRewards[account] = true;
    }

    function removeFromFee(address account) external onlyOwner {
        exclude[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        exclude[account] = false;
    }

    function includeInReward(address account) external onlyOwner {
        excludeFromRewards[account] = false;
    }

    function setMaxTx(uint256 amount) external onlyOwner {
        maxTxAllowed = amount * 10 ** uint256(_decimals);
        emit MaxTxUpdate(owner(), maxTxAllowed);
    }
    
    function setMinClaimSleep(uint256 newMinClaimSleep) external onlyOwner {
        minClaimSleep = newMinClaimSleep;
        emit MinimumSleepUpdate(owner(), minClaimSleep);
    }
    
    function buyBack() external onlyOwner returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        _approve(address(this), address(uniswapV2Router), address(this).balance);
        
        // Make the Swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(this).balance,
            0, // Accept any Amount of TOKEN
            path,
            address(this),
            block.timestamp
        );
        
        uint256 tokensBurnt = _balances[address(this)];
        _balances[DEAD] = _balances[DEAD].add(tokensBurnt);
        totalTokensBurnt = totalTokensBurnt.add(tokensBurnt);
        _balances[address(this)] = 0;
        
        return tokensBurnt;
    }
    
    function withdrawCharityFunds(address recipient, uint256 amount) external onlyOwner {
        require(charityToken >= amount, "insufficient Marketing Balance");
        charityToken = charityToken.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(address(this), recipient, amount);
    }
    
    function withdrawMarketingFunds(address recipient, uint256 amount) external onlyOwner {
        require(marketingToken >= amount, "insufficient Marketing Balance");
        marketingToken = marketingToken.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(address(this), recipient, amount);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "trnsfr amt > alonce"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "alonce < 0"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from 0 Address");
        require(recipient != address(0), "Transfer to 0 Address");
        bool sell;
        
        if (exclude[sender] || exclude[recipient]) {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

        } else {
            require(amount <= maxTxAllowed, "Amount larger than MaxTX Allowance");

            if (address(recipient) == address(uniswapV2Pair) || address(recipient) == address(uniswapV2Router)) {
                takeDividendBeforeSell(sender);
                sell = true;
            }
            
            takeDividendBeforeBuy(recipient);
            _balances[sender] = _balances[sender].sub(amount);
            amount = handleFees(amount, sell);
            _balances[recipient] = _balances[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }
    
    function handleFees(uint256 amount, bool sell) internal returns (uint256) {
        uint256 remainingAmount = amount;
        uint8 sellWeight;
        
        if (sell) {
            sellWeight = 3;
        }

        uint256 redistributionPart = amount.mul(redistributionFee + sellWeight).div(100);
        tokensForRedistribution = tokensForRedistribution.add(redistributionPart);
        totalTaxCollected = totalTaxCollected.add(redistributionPart);
        remainingAmount = remainingAmount.sub(redistributionPart);
        
        uint256 burnPart = amount.mul(burnFee).div(100);
        _balances[DEAD] = _balances[DEAD].add(burnPart);
        totalTokensBurnt = totalTokensBurnt.add(burnPart);
        remainingAmount = remainingAmount.sub(burnPart);
        
        uint256 liquidityPart = amount.mul(liquidityFee).div(100);
        tokensForLiquidity = tokensForLiquidity.add(liquidityPart);
        remainingAmount = remainingAmount.sub(liquidityPart);
        
        uint256 marketingPart = amount.mul(marketingFee).div(100);
        marketingToken = marketingToken.add(marketingPart);
        remainingAmount = remainingAmount.sub(marketingPart);
        
        uint256 charityPart = amount.mul(charityFee).div(100);
        charityToken = charityToken.add(charityPart);
        remainingAmount = remainingAmount.sub(charityPart);
        
        return remainingAmount;
    }
    
    function getTotalFee() public view returns (uint256) {
        return redistributionFee.add(burnFee).add(liquidityFee).add(marketingFee).add(charityFee);
    }
    
    function setFees(uint256 newRedistributionFee, uint256 newBurnFee, uint256 newLiquidityFee, uint256 newMarketingFee, uint256 newCharityFee) external onlyOwner {
        redistributionFee = newRedistributionFee;
        burnFee = newBurnFee;
        liquidityFee = newLiquidityFee;
        marketingFee = newMarketingFee;
        charityFee = newCharityFee;
        
        require(getTotalFee() <= 20, "Fee can't exceed 20%");
    }
    
    function addLiquidity() external onlyOwner nonReentrant {
        require(tokensForLiquidity > 0, "Amount for Liquidity isinsufficient");

        uint256 half = tokensForLiquidity.div(2);
        uint256 otherHalf = tokensForLiquidity.sub(half);
        _balances[address(this)] = _balances[address(this)].add(tokensForLiquidity);
        tokensForLiquidity = 0;
        
        uint256 initialBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), half);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            1000,
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance.sub(initialBalance);
        _approve(address(this), address(uniswapV2Router), otherHalf);

        uniswapV2Router.addLiquidityETH{value : newBalance}(
            address(this),
            otherHalf,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function takeDividendBeforeSell(address account) internal {
        if (excludeFromRewards[account]) return;
        if (nextClaimTime(account) > block.timestamp) return;
        
        uint256 dividend = viewDividend(account);
        _interest[account] = totalTaxCollected;
        
        if (dividend > 0) {
            uint256 initialBUSD = BUSD.balanceOf(msg.sender);
            swapTokensForETH(dividend, account);
            uint256 claimedBUSD = BUSD.balanceOf(msg.sender).sub(initialBUSD);
            appendTotalDividend(msg.sender, claimedBUSD, false);
        }
    }

    function takeDividendBeforeBuy(address account) internal {
        if (excludeFromRewards[account]) return;
        if (nextClaimTime(account) > block.timestamp) return;
        
        uint256 dividend = viewDividend(account);
        _interest[account] = totalTaxCollected;
        
        if (dividend > 0) {
            tokensForRedistribution = tokensForRedistribution.sub(dividend);
            _balances[account] = _balances[account].add(dividend);
            appendTotalDividend(account, dividend, true);
        }
    }

    function takeDividend(bool ownCurrency) external {
        require(!excludeFromRewards[msg.sender], "Account should not be excluded from Rewards");
        require(nextClaimTime(msg.sender) <= block.timestamp, "Minimum Claim Sleep not over");
        require(totalTaxCollected.sub(_interest[msg.sender]) > 0, "Account has no interest to Claim");

        uint256 dividend = viewDividend(msg.sender);
        _interest[msg.sender] = totalTaxCollected;
        
        if (ownCurrency) {
            tokensForRedistribution = tokensForRedistribution.sub(dividend);
            _balances[msg.sender] = _balances[msg.sender].add(dividend);
            appendTotalDividend(msg.sender, dividend, true);
        }
        
        else {
            uint256 initialBUSD = BUSD.balanceOf(msg.sender);
            swapTokensForETH(dividend, msg.sender);
            uint256 claimedBUSD = BUSD.balanceOf(msg.sender).sub(initialBUSD);
            appendTotalDividend(msg.sender, claimedBUSD, false);
        }
    }
    
    function appendTotalDividend(address account, uint256 claimedAmount, bool ownCurrency) internal {
        if (ownCurrency) {
            totalHKUNRedistributed = totalHKUNRedistributed.add(claimedAmount);
            totalHKUNClaimed[account] = totalHKUNClaimed[account].add(claimedAmount);
            
        } else {
            totalBUSDRedistributed = totalBUSDRedistributed.add(claimedAmount);
            totalBUSDClaimed[account] = totalBUSDClaimed[account].add(claimedAmount);
        }
        
        lastClaim[account] = block.timestamp;
    }
    
    function swapTokensForETH(uint256 tokenAmount, address account) private nonReentrant {
        tokensForRedistribution = tokensForRedistribution.sub(tokenAmount);
        _balances[address(this)] = _balances[address(this)].add(tokenAmount);

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // Make the Swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            1000,
            path,
            account,
            block.timestamp
        );
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from 0 Address");
        require(spender != address(0), "Approve to 0 Address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}