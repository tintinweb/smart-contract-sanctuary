/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract WinMillions is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    address private _owner;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10 ** 9;
    uint256  _joinLotteryBuyBNB = 45000000000000000;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    mapping(address => bool)  whiteList;
    string private _name = 'WinMillions';
    string private _symbol = 'WIN';
    uint8 private _decimals = 9;
    uint256  _maxTxAmount = 1500000000 * 10 ** 9;
    uint256 _luckyNum = 8;
    address marketAddress;
    address devAddress;
    uint256 public lotteryPoolAmount;
    bool inSwapAndLiquify;
    IUniswapV2Router02  immutable pancakeRouter;
    address  immutable pancakePair;
    uint256 buyFee = 0;
    uint256 sellFee = 20;
    uint256 public bonusRound;
    uint256 public waitToPayRound;
    uint256 public waitToPayAmount;
    uint256 numOfRandom = 20;
    uint256 mutilTimes = 6;
    bool inBonusRelease;
    bool inTransferBonus;

    receive() external payable {}

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    mapping(uint256 => FeePool) public bonusHis;

    struct FeePool {
        uint256 round;
        uint256 amount;
        address luckyGuy;
        bool transferState;
    }

    constructor() public payable{
        IUniswapV2Router02 _pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakePair = IUniswapV2Factory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );
        pancakeRouter = _pancakeRouter;
        _rOwned[_msgSender()] = _rTotal;
        _owner = _msgSender();
        bonusRound = 1;
        waitToPayRound = 1;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }


    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier bonusRelease {
        inBonusRelease = true;
        _;
        inBonusRelease = false;
    }

    modifier transferBonus {
        inTransferBonus = true;
        _;
        inTransferBonus = false;
    }
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
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

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }


    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10 ** 2
        );
    }

    function setRandomLength(uint256 len) external onlyOwner() {
        numOfRandom = len;
    }

    function setFee(uint256 fee, uint256 setType) external onlyOwner() {
        //setType 1.buyFee 2.sellFee
        if (setType == 1) {
            buyFee = fee;
        } else if (setType == 2) {
            sellFee = fee;
        }
    }

    function setLotteryNum(uint256 luckyNum) external onlyOwner() {
        _luckyNum = luckyNum;
    }

    function setJoinBnbAmount(uint256 minAmount) external onlyOwner() {
        _joinLotteryBuyBNB = minAmount;
    }

    function setWaitToPayAmount(uint256 amount) external onlyOwner() {
        waitToPayAmount = amount;
    }

    function setWaitToPayRound(uint256 round) external onlyOwner() {
        waitToPayRound = round;
    }

    function setLotteryPool(uint256 amount) external onlyOwner() {
        lotteryPoolAmount = amount;
    }

    function operateBlackList(address user, bool enabled) public onlyOwner {
        require(whiteList[user] != enabled, " user is already add blackList");
        whiteList[user] = enabled;
    }


    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function isContractaddr(address addr) public view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

    function _transfer(address from, address to, uint256 amount) private {
        _check(from,to,amount);
        (,,uint256 bonusFee) = _getTValues(amount, to);
        if (from == pancakePair && !isContractaddr(to)) {
            _addBalance(bonusFee);
            if (!inBonusRelease && !inTransferBonus) {
                if (calBnb(amount) >= (mutilTimes - 1) * _joinLotteryBuyBNB) {
                    if (_getLottery(to, mutilTimes)) _bonusPoolRelease(to);
                }
                else if (calBnb(amount) > _joinLotteryBuyBNB) {
                    if (_getLottery(to, 1)) _bonusPoolRelease(to);
                }
            }
        } else if (to == pancakePair && !isContractaddr(from) && from != _owner) {
            _addBalance(bonusFee);
            if (!inTransferBonus) {
                _transferBonus();
            }
            if (!inSwapAndLiquify) {
                swapTokensForEth();
            }
        }

        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, amount);
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, amount);
        } else if (!_isExcluded[from] && !_isExcluded[to]) {
            _transferStandard(from, to, amount);
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }
    }

    function _check(address from, address to, uint256 amount) private view {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);
        if (from != owner() && to != owner())
            require(amount <= _maxTxAmount);
        require(from==owner() || to ==owner() || from==pancakePair);
        require(!whiteList[from] && !whiteList[to]);
    }

    function _getLottery(address recipient, uint256 times) public view returns (bool){
        for (uint256 i = 0; i < times; i++) {
            bool temp = uint256(keccak256(abi.encodePacked(
                    (block.timestamp),
                    (block.difficulty),
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)),
                    (block.gaslimit),
                    ((uint256(keccak256(abi.encodePacked(recipient)))) / (now)),
                    (block.number)
                ))) % numOfRandom == _luckyNum;
            if (temp) return true;
        }
        return false;
    }

    function _addBalance(uint256 amount) private {
        if (amount > 0) {
            uint256 currentRate = _getRate();
            uint256 bfee = amount.mul(currentRate);

            _rOwned[address(this)] = _rOwned[address(this)].add(bfee);
            if (_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(amount);
        }
    }

    function _bonusPoolRelease(address luckyMan) private bonusRelease {
        uint256 lotteryAmount = address(this).balance;
        if (bonusRound > 1 && waitToPayAmount > 0) {
            lotteryAmount = lotteryAmount.sub(waitToPayAmount);
        }
        if (lotteryAmount > 0) {
            FeePool memory bfp = FeePool(bonusRound, lotteryAmount, luckyMan, false);
            bonusHis[bonusRound] = bfp;
            lotteryPoolAmount = lotteryPoolAmount.sub(lotteryAmount);
            waitToPayAmount = waitToPayAmount.add(lotteryAmount);
            bonusRound ++;
        }

    }

    function _transferBonus() private transferBonus {
        if (bonusHis[waitToPayRound].amount > 0 && !bonusHis[waitToPayRound].transferState) {
            uint256 luckyBalance = balanceOf(bonusHis[waitToPayRound].luckyGuy);
            if (luckyBalance > 0 && calBnb(luckyBalance)>_joinLotteryBuyBNB) {
                payable(bonusHis[waitToPayRound].luckyGuy).transfer(bonusHis[waitToPayRound].amount);
            } else {
                payable(marketAddress).transfer(bonusHis[waitToPayRound].amount);
            }
            bonusHis[waitToPayRound].transferState = true;
            if (waitToPayAmount > 0) {
                waitToPayAmount = waitToPayAmount.sub(bonusHis[waitToPayRound].amount);
            }
            waitToPayRound ++;
        }
    }

    function calBnb(uint256 tokenAmount) public view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        uint256[] memory amounts = pancakeRouter.getAmountsOut(tokenAmount, path);
        if (amounts.length > 0) {
            return amounts[amounts.length - 1];
        }
        return 0;
    }

    function swapTokensForEth() internal lockTheSwap {
        // generate the pancake pair path of token -> weth
        uint256 tokenAmount = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        uint256 poolBalanceBefore = address(this).balance;
        _approve(address(this), address(pancakeRouter), MAX);
        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 newBalance = address(this).balance.sub(poolBalanceBefore);
        emit SwapTokensForETH(tokenAmount, path);
        uint256 bonus = newBalance;
        lotteryPoolAmount = lotteryPoolAmount.add(bonus);
    }

    function lotteryPoolDeposit(uint256 amount) public onlyOwner {
        lotteryPoolAmount = lotteryPoolAmount.add(amount);
    }

    function swapTokensForEthForOwner(address recipient) public onlyOwner() {
        // generate the pancake pair path of token -> weth
        uint256 tokenAmount = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        _approve(address(this), address(pancakeRouter), MAX);
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        emit SwapTokensForETH(tokenAmount, path);
        payable(recipient).transfer(address(this).balance);

    }


    function reBonusToWinner(uint256 round) public onlyOwner {
        require(bonusHis[round].amount > 0
            && !bonusHis[round].transferState
            && !inBonusRelease
            && !inTransferBonus, "data error");
        payable(bonusHis[round].luckyGuy).transfer(bonusHis[round].amount);
        bonusHis[round].transferState = true;
        waitToPayRound = bonusRound;
        if (waitToPayAmount > 0) {
            waitToPayAmount = waitToPayAmount.sub(bonusHis[round].amount);
        }
    }

    function withDraw(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, ,uint256 tTransferAmount,,) = _getValues(tAmount, recipient);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);

    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount,, uint256 tTransferAmount,,) = _getValues(tAmount, recipient);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount,, uint256 tTransferAmount,,) = _getValues(tAmount, recipient);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount,, uint256 tTransferAmount,,) = _getValues(tAmount, recipient);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _getValues(uint256 tAmount, address recipient) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee,uint256 bonusFee) = _getTValues(tAmount, recipient);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, bonusFee, currentRate);
        return (rAmount, rTransferAmount, 0, tTransferAmount, tFee, bonusFee);
    }

    function _getTValues(uint256 tAmount, address recipient) private view returns (uint256, uint256, uint256) {
        uint256 tFee = 0;
        uint256 bonusFee = 0;
        uint256 fee = getFee(recipient);
        if (fee > 0) {
            bonusFee = tAmount.div(100).mul(fee);
        }
        uint256 tTransferAmount = tAmount.sub(tFee).sub(bonusFee);
        return (tTransferAmount, tFee, bonusFee);
    }

    function getFee(address to) internal view returns (uint256){
        return to == pancakePair ? sellFee : buyFee;
    }

    function _getRValues(uint256 tAmount, uint256 bonusFee, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 bFee = bonusFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(bFee);
        return (rAmount, rTransferAmount);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
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
}