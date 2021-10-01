/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: Unlicensed

/**
 * @dev BEP20 Token interface
 */
interface IBEP20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

library Address {
 
    function isContract(address account) internal view returns (bool) {

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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // Locks the contract for owner for the amount of time provided
    function lock(uint256 time) external onlyOwner {
        _previousOwner = _owner;
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Unlocks the contract for owner when _lockTime is exceeds
    function unlock() external {
        require(_previousOwner == _msgSender(), "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }

    function geUnlockTime() external view returns (uint256) {
        return _lockTime;
    }
}

contract HireXToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _tBalances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isLockedWallet;
	mapping(address => bool) private _isExcludedFromMax;

	address private constant burnAddress = 0x000000000000000000000000000000000000dEaD;
	address public marketingWallet;
    address public researchWallet;

    string private constant _name          = "HIRE-X";
    string private constant _symbol        = "HIRE-X";
    uint8 private constant _decimals       = 9;
    uint256 private constant _tTotalSupply = 10 * 10**9 * 10**_decimals; // 10,000,000,000.000000000 - 10B

    uint256 public _buyMaxTxAmount     = 2000000 * 10**_decimals;
    uint256 public _sellMaxTxAmount    = 1000000 * 10**_decimals; // 0.3% of total supply
    uint256 public _otherMaxTxAmount   = _tTotalSupply;
    uint256 public _buyLiquidityFee    = 2; // 2% Fee to LP on buy
    uint256 public _buyMarketingFee    = 4; // 4% Fee to Marketing wallet on buy
    uint256 public _buyResearchFee     = 4; // 4% Fee to Research wallet on buy
    uint256 public _sellLiquidityFee   = 4; // 4% Fee to LP on sell
    uint256 public _sellMarketingFee   = 10; // 10% Fee to Marketing wallet on sell
    uint256 public _sellResearchFee    = 10; // 10% Fee to Research wallet on sell
	uint256 public _otherLiquidityFee  = 2; // 2% Fee to LP on other transaction
    uint256 public _otherMarketingFee  = 4; // 4% Fee to Marketing wallet on other transaction
    uint256 public _otherResearchFee   = 4; // 4% Fee to Research wallet on other transaction

    uint256 private _maxTxAmount;
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;
    uint256 private _marketingFee;
    uint256 private _previousMarketingFee;
    uint256 private _researchFee;
    uint256 private _previousResearchFee;
    uint256 private _tFeeTotal;


    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;

	event LockedWallet(address indexed wallet, bool locked);
	event TransferBurn(address indexed from, address indexed to, uint256 value);
    event updatePancakeV2Router(address indexed newAddress, address indexed oldAddress);

    constructor (address payable MarketingWallet, address payable ResearchWallet, address PancakeSwapRouter) {

        marketingWallet = MarketingWallet;
        researchWallet = ResearchWallet;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(PancakeSwapRouter);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        // exclude owner, this contract, burn address, marketing wallet and other wallets from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[burnAddress] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[researchWallet] =  true;

        // exclude burn address, marketing wallet and other wallets from limit of transaction
        _isExcludedFromMax[owner()] = true;
        _isExcludedFromMax[address(this)] = true;
		_isExcludedFromMax[burnAddress] = true;
		_isExcludedFromMax[marketingWallet] = true;
		_isExcludedFromMax[researchWallet] = true;

		// set totalSupply variable
		_tBalances[_msgSender()] = _tTotalSupply;
		emit Transfer(address(0), _msgSender(), _tTotalSupply);
    }

    // to receive BNBs
    receive() external payable {}

	function getOwner() external view returns (address) {
        return owner();
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _tBalances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function lockWallet(address account) external onlyOwner {
        _isLockedWallet[account] = true;
        emit LockedWallet(account, true);
    }

    function unLockWallet(address account) external onlyOwner {
        _isLockedWallet[account] = false;
        emit LockedWallet(account, false);
    }

    function isLockedWallet(address account) external view returns(bool) {
        return _isLockedWallet[account];
    }

    function excludeFromMax(address account) external onlyOwner() {
		_isExcludedFromMax[account] = true; 
	}

    function includeInMax(address account) external onlyOwner() {
		_isExcludedFromMax[account] = false; 
	}

	function isExcludedFromMax(address account) external view returns (bool) {
		return _isExcludedFromMax[account]; 
	}

    function setBuyMaxTxAmount(uint256 buyTxValue, uint256 sellTxValue, uint256 otherTxValue) external onlyOwner() {
        _buyMaxTxAmount = buyTxValue.mul(10**_decimals);
        _sellMaxTxAmount = sellTxValue.mul(10**_decimals);
        _otherMaxTxAmount = otherTxValue.mul(10**_decimals);
    }

	function setBuyFee(uint256 buyLiqFee, uint256 buyMarketingFee, uint256 buyResearchFee) external onlyOwner() {
        _buyLiquidityFee = buyLiqFee;
        _buyMarketingFee = buyMarketingFee;
        _buyResearchFee = buyResearchFee;
    }

    function setSellFee(uint256 sellLiqFee, uint256 sellMarketingFee, uint256 sellResearchFee) external onlyOwner() {
        _sellLiquidityFee = sellLiqFee;
        _sellMarketingFee  = sellMarketingFee;
        _sellResearchFee = sellResearchFee;
    }

	function setOtherOtherFee(uint256 otherLiqFee, uint256 otherMarketingFee, uint256 otherResearchFee) external onlyOwner() {
        _otherLiquidityFee = otherLiqFee;
        _otherMarketingFee  = otherMarketingFee;
        _otherResearchFee = otherResearchFee;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function _transfer(address from, address to, uint256 amount) private {
        // prevents transfer of blocked wallets
        require(!_isLockedWallet[from], "Locked addresses cannot call this function");

        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner() && !_isExcludedFromMax[from] && !_isExcludedFromMax[to]) {
            // set _maxTxAmount to buy or sell action
            if (from == pancakePair) { // Buy
                _maxTxAmount = _buyMaxTxAmount;
            } else if (to == pancakePair) { // Sell
                _maxTxAmount = _sellMaxTxAmount;
            } else { // other
                _maxTxAmount = _otherMaxTxAmount;
            }

            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        // indicates if fee should be deducted from transfer
        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else {
            // set _taxFee and _liquidityFee to buy or sell action
            if (from == pancakePair) { // Buy
                _liquidityFee = _buyLiquidityFee;
                _marketingFee = _buyMarketingFee;
                _researchFee = _buyResearchFee;
            } else if (to == pancakePair) { // Sell
                _liquidityFee = _sellLiquidityFee;
                _marketingFee = _sellMarketingFee;
                _researchFee = _sellResearchFee;
            } else { // other
                _liquidityFee = _otherLiquidityFee;
                _marketingFee = _otherMarketingFee;
                _researchFee = _otherResearchFee;
            }
        }

        // transfer amount, it will take tax, burn, liquidity fee
        if (!takeFee) {
            removeAllFee();
        }
        
        (uint256 tLiquidity, uint256 tMarketing, uint256 tResearch, uint256 tTransferAmount) = _getTValues(amount);
        _takeLiquidity(tLiquidity);
		emit TransferBurn(from, burnAddress, tLiquidity);
		_transferOtherFees(to, tMarketing, tResearch);
        _tBalances[from] = _tBalances[from].sub(amount);
        _tBalances[to] = _tBalances[to].add(tTransferAmount);
        emit Transfer(from, to, tTransferAmount);
        
        if (!takeFee) {
            restoreAllFee();
        }
    }

    function removeAllFee() private {
        if (_liquidityFee == 0 && _marketingFee == 0 && _researchFee == 0) return;

        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _previousResearchFee = _researchFee;

        _liquidityFee = 0;
        _marketingFee = 0;
        _researchFee = 0;
    }

	function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tResearch = calculateResearchFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLiquidity).sub(tMarketing).sub(tResearch);
        return (tLiquidity, tMarketing, tResearch, tTransferAmount);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(10**2);
    }

    function calculateResearchFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_researchFee).div(10**2);
    }

	function _takeLiquidity(uint256 tLiquidity) private {
	    if (tLiquidity > 0) {
            _tBalances[burnAddress] = _tBalances[burnAddress].add(tLiquidity);
            _tFeeTotal = _tFeeTotal.add(tLiquidity);
	    }
    }

    function _transferOtherFees(address sender, uint256 tMarketing, uint256 tResearch) private {
        if (tMarketing > 0) {
            _tBalances[marketingWallet] = _tBalances[marketingWallet].add(tMarketing);
            emit Transfer(sender, marketingWallet, tMarketing);
            _tFeeTotal = _tFeeTotal.add(tMarketing); 
        }
        if (tResearch > 0) {
            _tBalances[researchWallet] = _tBalances[researchWallet].add(tResearch);
            emit Transfer(sender, researchWallet, tResearch);
            _tFeeTotal = _tFeeTotal.add(tResearch);
        }
    }

	function restoreAllFee() private {
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
        _researchFee = _previousResearchFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function updatePancakeRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter), "The router already has that address");
        emit updatePancakeV2Router(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
        
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .getPair(address(this), pancakeRouter.WETH());
    }
}