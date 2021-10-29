// SPDX-License-Identifier: No License
    /*
        LOTUS NETWORK TOKEN CONTRACT
            HYPER DEFLATION PHASE
            NOTE THAT TAXES WILL
            BE REMOVED IN LATER PHASES
            Website - http://lotusnetwork.net
            We're open to any inquiry at
            Email - [email protected]
            Founder - @mks3lim
            Twitter - @LTSNET
                                    */

pragma solidity ^0.8.4;

// File @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File @openzeppelin/contracts/security/ReentrancyGuard.sol

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// File @openzeppelin/contracts/math/SafeMath.sol

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

    function ceil(
        uint256 a,
        uint256 m
        ) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
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

  // File @openzeppelin/contracts/utils/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

 // File @openzeppelin/contracts/utils/Address.sol

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

 // File @openzeppelin/contracts/access/Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

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

// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

contract LTS is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public _buyBackWalletAddress;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 public _totalSupply =  1000000000 * 10 ** 18; // 1 Billion LTS TOKEN
    string public _name = "Lotus Network";
    string public _symbol = "LTS";
    uint8 public _decimals = 18;
    uint256 public _burnFee = 8;
    uint256 public _buyBackFee = 2;
    uint256 public _penaltyBurnFee = 3;
    uint256 public _penaltyBuybackFee = 2;
    uint256 private _previousBurnFee = _burnFee;
    uint256 private _previousBuyBackFee = _buyBackFee;
    uint256 private _previousPenaltyBurnFee = _penaltyBurnFee;
    uint256 private _previousPenaltyBuyBackFee = _penaltyBuybackFee;
    uint256 public totalBurns;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public _feesStatus = false;
    uint256 public _maxTxAmount = 90000000 * 10**18;
    mapping(address => uint256) private _holderToTimestamp;
    mapping(address => bool) private _isHolder;
    event ManualBurn(address indexed deadwallet, uint256 totalBurn);
    event UpdateBurnFee(uint256 newFee);
    event UpdateBuybackFee(uint256 newFee);
    event UpdatePenaltyBuybackFee(uint256 newFee);
    event UpdatePenaltyBurnFee(uint256 newFee);
    event UpdateMaxTxPercent(uint256 newPercent);
    event UpdateFeesStatus(bool newStatus);

    constructor() {
        _balances[_msgSender()] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _isExcluded[address(this)] = true;
        _isExcluded[owner()] = true;
        _isExcluded[burnAddress] = true;
        _buyBackWalletAddress = owner();
        totalBurns = 0; // MAX BURNS 7
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

        //  EIP-20: Token Standard 
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    function totalTokensBurned() public view returns (uint256) {
        return balanceOf(burnAddress);
    }

    function excludeAccountFromTxAndFees(address account) public onlyOwner() returns (bool) {
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);
        return true;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
        emit UpdateBurnFee(burnFee);
    }

    function setBuybackFee(uint256 buyBackfee) external onlyOwner() {
        _buyBackFee = buyBackfee;
        emit UpdateBuybackFee(buyBackfee);
    }

    function setPenaltyBuybackFee(uint256 penaltyBuybackfee) external onlyOwner() {
        _penaltyBuybackFee = penaltyBuybackfee;
        emit UpdatePenaltyBuybackFee(penaltyBuybackfee);
    }

    function setPenaltyBurnFee(uint256 penaltyBurnFee) external onlyOwner() { 
        _penaltyBurnFee = penaltyBurnFee;
        emit UpdatePenaltyBurnFee(penaltyBurnFee);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _totalSupply.mul(maxTxPercent).div(10**2);
        emit UpdateMaxTxPercent(maxTxPercent);
    }

    function setFeesStatus(bool feesStatus) external onlyOwner() nonReentrant returns (bool) {
        _feesStatus = feesStatus;
        if(feesStatus = true) {restoreAllFee();} else {removeAllFee();}
        emit UpdateFeesStatus(feesStatus);
        return true;
    }
    
    receive() external payable {}
    
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tBuyback = calculateBuybackFee(tAmount, false);
        uint256 tBurn = calculateBurnFee(tAmount, false);
        uint256 tTransferAmount = tAmount.sub(tBuyback).sub(tBurn);
        return (tTransferAmount, tBurn, tBuyback);
    }

    function _getPenaltyValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 penaltyBuyback = calculateBuybackFee(tAmount,  true);
        uint256 penaltyBurn = calculateBurnFee(tAmount, true);
        uint256 penaltyTransferAmount = tAmount.sub(penaltyBuyback).sub(penaltyBurn);
        return (penaltyTransferAmount, penaltyBurn, penaltyBuyback);
    }

    function calculateBurnFee(uint256 _amount, bool _heldLessThan7Hours) private view returns (uint256) {
        if(_heldLessThan7Hours) {
            return _amount.mul(_burnFee + _penaltyBurnFee).div(10 ** 2); 
            } else {
            return _amount.mul(_burnFee).div(10 ** 2);
            }
    }
        
    function calculateBuybackFee(uint256 _amount, bool _heldLessThan7Hours) private view returns (uint256) {
        if(_heldLessThan7Hours) {
            return _amount.mul(_buyBackFee + _penaltyBuybackFee).div(10 ** 2); 
            } else {
            return _amount.mul(_buyBackFee).div(10 ** 2); 
            }
    }

    function toDeadWallet(uint256 tBurn) private {
        _totalSupply = _totalSupply.sub(tBurn);
        _balances[burnAddress] = _balances[burnAddress].add(tBurn);
        emit Transfer(_msgSender(), burnAddress, tBurn);
    }

    function _takeBuybackFee(uint256 tBuyback) private {
        _balances[owner()] = _balances[owner()].add(tBuyback);
        emit Transfer(_msgSender(), owner(), tBuyback);
    }
    
    function removeAllFee() private {
        if (_burnFee == 0 && _buyBackFee == 0 && _penaltyBuybackFee == 0 && _penaltyBurnFee == 0) return;
        _previousBurnFee = _burnFee;
        _previousBuyBackFee = _buyBackFee;
        _previousPenaltyBurnFee = _penaltyBurnFee;
        _previousPenaltyBuyBackFee = _penaltyBuybackFee;
        _burnFee = 0;
        _buyBackFee = 0;
        _penaltyBurnFee = 0;
        _penaltyBuybackFee = 0;
    }

    function restoreAllFee() private {
        _burnFee = _previousBurnFee;
        _buyBackFee = _previousBuyBackFee;
        _penaltyBuybackFee = _previousPenaltyBuyBackFee;
        _penaltyBurnFee = _previousPenaltyBurnFee;
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!_isExcluded[from])
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        bool takeFee = _feesStatus;

        if (_isExcluded[from]) {
            takeFee = false;
        }
            _tokenTransfer(from, to, amount, takeFee);

        if (!_isHolder[to]) {
            _holderToTimestamp[to] = block.timestamp;
            _isHolder[to] = true;
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
            bool heldLessThan7Hours = block.timestamp <
                _holderToTimestamp[_msgSender()] + 7 hours;
        if (!_isExcluded[sender] && !heldLessThan7Hours && takeFee) {
            _transferStandard(sender, recipient, amount);
        } else if (!_isExcluded[sender] && heldLessThan7Hours && takeFee) {
            _penaltyTransfer(sender, recipient, amount);
        } else if (_isExcluded[sender]) {
            _transferFromExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tBurn, uint256 tBuyback) = _getTValues(tAmount);
        _balances[sender] = _balances[sender].sub(tTransferAmount).sub(tBurn).sub(tBuyback);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _takeBuybackFee(tBuyback);
        toDeadWallet(tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount,,) = _getTValues(tAmount);
        _balances[sender] = _balances[sender].sub(tTransferAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _penaltyTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 penaltyTransferAmount, uint256 penaltyBurn, uint256 penaltyBuyback) = _getPenaltyValues(tAmount);
        _balances[sender] = _balances[sender].sub(penaltyTransferAmount).sub(penaltyBurn).sub(penaltyBuyback);
        _balances[recipient] = _balances[recipient].add(penaltyTransferAmount);
        _takeBuybackFee(penaltyBuyback);
        toDeadWallet(penaltyBurn);
        emit Transfer(sender, recipient, penaltyTransferAmount);
    }

        //  NOTE CONTRACT IS NOT DESIGNED TO STORE ANY ASSETS
        //  WE'RE KEEPING THESE FUNCTIONS HERE JUST IN CASE OF WRONG TRANSFERS
    function totalBalance() external view returns(uint) {
        return payable(address(this)).balance;
    }
        
    function withdrawContractFunds() external onlyOwner() nonReentrant {
        payable(owner()).transfer(this.totalBalance());
    }

    function manualBurn(uint256 tokenBurnAmount) external onlyOwner() nonReentrant returns (bool) {
        require (tokenBurnAmount != 0 , "Amount cannot be zero");
        require (tokenBurnAmount <= _balances[owner()], "Amount exceeds owner balance");
        require (tokenBurnAmount < _totalSupply , "Burning amount exceeds total supply");
        require (totalBurns <= 7 , "Total burns exceeds the burn limit of lts");
        _totalSupply = _totalSupply.sub(tokenBurnAmount);
        _balances[owner()] = _balances[owner()].sub(tokenBurnAmount);
        _balances[burnAddress] = _balances[burnAddress].add(tokenBurnAmount);
        totalBurns = totalBurns.add(1);
        emit ManualBurn(burnAddress, tokenBurnAmount);
        emit Transfer(owner(), burnAddress, tokenBurnAmount);
        return true;
    }
}