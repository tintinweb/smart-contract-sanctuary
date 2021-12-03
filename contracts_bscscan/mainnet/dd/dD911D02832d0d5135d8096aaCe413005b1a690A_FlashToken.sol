/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/* IERC20.sol */
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


/* Context.sol */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/* IUniswapV2Router.sol */
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


/* IUniswapV2Factory */
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


/* IUniswapv2Pair.sol */
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
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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


/* IERC20 Metadata.sol */
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


/* Ownable.sol */
contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
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


/* SafeMath.sol */
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
}


/* SafeMathInt.sol */
library SafeMathInt {

    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}


/* SafeMathUint.sol */
library SafeMathUint {

    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}


/* IterableMapping.sol */
library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}


/* ERC20.sol */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount ) internal virtual {}
}


/* DividendPayingTokenInterface.sol */
interface DividendPayingTokenInterface {

    function dividendOf(address _owner) external view returns(uint256);
    function withdrawDividend() external;
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}


/* DividendPayingTokenOptionalInterface.sol */
interface DividendPayingTokenOptionalInterface {

    function withdrawableDividendOf(address _owner) external view returns(uint256);
    function withdrawnDividendOf(address _owner) external view returns(uint256);
    function accumulativeDividendOf(address _owner) external view returns(uint256);
}


/* DividendPayingToken.sol */
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {

    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    address public constant BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD
    // for testnet: 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47
    // for mainnet: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56

    uint256 constant internal magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {

    }

    function distributeBUSDDividends(uint256 amount) public onlyOwner{
        require(totalSupply() > 0);

        if (amount > 0) {
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (amount).mul(magnitude) / totalSupply()
        );
        emit DividendsDistributed(msg.sender, amount);

        totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(msg.sender);
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
        withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
        emit DividendWithdrawn(user, _withdrawableDividend);
        bool success = IERC20(BUSD).transfer(user, _withdrawableDividend);

        if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
        }
        return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner) public view override returns(uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view override returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view override returns(uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view override returns(uint256) {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if(newBalance > currentBalance) {
        uint256 mintAmount = newBalance.sub(currentBalance);
        _mint(account, mintAmount);
        } else if(newBalance < currentBalance) {
        uint256 burnAmount = currentBalance.sub(newBalance);
        _burn(account, burnAmount);
        }
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


/* FLASH.sol */
contract FlashToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    FLASHDividendTracker public dividendTracker;
    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    
    bool private swapping; 

    address public constant BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD
    //testnet: 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47
    //mainnet: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56

    uint256 public  swapTokensAtAmount = 100 ether;

    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 public liquidityFee = 4;
    uint256 public BUSDRewardsFee = 6;
    uint256 public marketingFee = 5;
    uint256 public burnFee = 1;
    uint256 public buybackFee = 0;
    uint256 public algorithmFee = 0;
    uint256 public sellFee = 7;
    uint256 public priceImpact = 3;

    uint256 public totalFees = liquidityFee.add(BUSDRewardsFee).add(marketingFee).add(burnFee).add(buybackFee).add(algorithmFee);
    
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public _marketingWalletAddress = 0x01f6ed64AA795E3Fc650A129b59D2408f5B68833;
    address public _algorithmWalletAddress = 0x00C174A0A7A55D139039E26951Bf2327fe87D7cD;
    address public _buybackWalletAddress = 0xEBAe3Bc51FB4b35B5AC13c7C63eE504D77163f49;

    uint256 public gasForProcessing = 300000;

    bool public swapAndLiquifyDividendEnabled = false;
    bool public impactEnabled = false;
    bool public trading = false;

    uint256 public transactionLockTime = 120;
    mapping (address => bool) public isExcludedFromAntiWhale;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => uint256) private _transactionCheckpoint;
    mapping (address => bool) public isExcludedFromTransactionlock;

    uint256 public maxTxAmount = totalSupply().div(1000); // 0.1%. 
    uint256 public maxTokensPerAddress = totalSupply().mul(3).div(1000); //0.3%
    
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetBlacklist(address indexed account, bool isExcluded);
    event ExcludedFromTxLimit(address indexed account, bool isExcluded);
    event ExcludedFromTransactionCooldown(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event MarketingWalletUpdated(address indexed operator, address indexed oldMarketingWallet, address indexed newMarketingWallet);
    event AlgorithmWalletUpdated(address indexed operator, address indexed oldAlgorithmWallet, address indexed newAlgorithmWallet);
    event BuybackWalletUpdated(address indexed operator, address indexed oldBuybackWallet, address indexed newBuybackWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SwapAndLiquifyDividendEnabledUpdated(address indexed operator, bool enabled);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event LiquidityFeeUpdated(address indexed operator, uint256 oldLiquidityfee, uint256 newLiquidityfee);
    event BUSDRewardsFeeUpdated(address indexed operator, uint256 oldBUSDRewardsfee, uint256 newBUSDRewardsfee);
    event MarketingFeeUpdated(address indexed operator, uint256 oldMarketingfee, uint256 newMarketingfee);
    event BurnFeeUpdated(address indexed operator, uint256 oldBurnfee, uint256 newBurnfee);
    event BuybackFeeUpdated(address indexed operator, uint256 oldBuybackfee, uint256 newBuybackfee);
    event AlgorithmFeeUpdated(address indexed operator, uint256 oldAlgorithmfee, uint256 newAlgorithmfee);
    event SellFeeUpdated(address indexed operator, uint256 oldSellfee, uint256 newSellfee);
    event MaxTxAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event MaxTokensPerAddressUpdated(uint256 oldAmount, uint256 newAmount);
    event TransactionCooldownTimeUpdated(uint256 oldAmount, uint256 newAmount);
    event FlashTokensWithdrawn(address indexed operator, address indexed recipient, uint256 amount);
    event BNBWithdrawn(address indexed operator, address indexed recipient, uint256 amount);
    event SwapTokensAtAmountUpdated(address indexed operator, uint256 newSwapAtAmount);
    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() public ERC20("Flash Token", "FLASH") {

    	dividendTracker = new FLASHDividendTracker();
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        // for testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // for mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        
        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(_algorithmWalletAddress, true);
        excludeFromFees(_buybackWalletAddress, true);

        isExcludedFromTransactionlock[_uniswapV2Pair]            = true;
        isExcludedFromTransactionlock[owner()]                   = true;
        isExcludedFromTransactionlock[address(this)]             = true;
        isExcludedFromTransactionlock[_marketingWalletAddress]   = true;
        isExcludedFromTransactionlock[_algorithmWalletAddress]   = true;
        isExcludedFromTransactionlock[_buybackWalletAddress]     = true;
        isExcludedFromTransactionlock[address(_uniswapV2Router)] = true;

        isExcludedFromAntiWhale[_uniswapV2Pair]            = true;
        isExcludedFromAntiWhale[owner()]                   = true;
        isExcludedFromAntiWhale[deadWallet]                = true;
        isExcludedFromAntiWhale[address(this)]             = true;
        isExcludedFromAntiWhale[_marketingWalletAddress]   = true;
        isExcludedFromAntiWhale[_algorithmWalletAddress]   = true;
        isExcludedFromAntiWhale[_buybackWalletAddress]     = true;
        isExcludedFromAntiWhale[address(_uniswapV2Router)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        _mint(owner(), 1000000000  * (10**18));
    }

    receive() external payable {

  	}

    function setMaxTransaction(uint256 percentage) external onlyOwner {
        uint256 newmaxTxAmount = totalSupply().mul(percentage).div(1000);
        emit MaxTxAmountUpdated(maxTxAmount, newmaxTxAmount);
        maxTxAmount = newmaxTxAmount;
    }

    function setMaxTokensPerAddress(uint256 percentage) external onlyOwner {
        uint256 newmaxTokensPerAddress = totalSupply().mul(percentage).div(1000);
        emit MaxTokensPerAddressUpdated(maxTokensPerAddress, newmaxTokensPerAddress);
        maxTokensPerAddress = newmaxTokensPerAddress;
    }

    function setTxLimitExempt(address account, bool excluded) external onlyOwner {
        require(isTxLimitExempt[account] != excluded, "FLASH::setTxLimitExempt: Account is already the value of 'excluded'");
        isTxLimitExempt[account] = excluded;
        emit ExcludedFromTxLimit(account, excluded);
    }

    function setExcludedFromTransactionCooldown(address account, bool excluded) public onlyOwner {
        require(isExcludedFromTransactionlock[account] != excluded, "FLASH::setExcludedFromTransactionCooldown: Account is already the value of 'excluded'");
        isExcludedFromTransactionlock[account] = excluded;
        emit ExcludedFromTransactionCooldown(account, excluded);
    }

    function setTransactionCooldownTime(uint256 transactiontime) public onlyOwner {
        require(transactiontime <= 86400, "FLASH::setTransactionCooldownTime: Can not to exceed max amount");
        emit TransactionCooldownTimeUpdated(transactionLockTime, transactiontime);
        transactionLockTime = transactiontime;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "FLASH::excludeFromFees: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setBlacklist(address account, bool excluded) public onlyOwner {
        require(_isBlacklisted[account] != excluded, "FLASH::setBlacklist: Account is already the value of 'excluded'");
        _isBlacklisted[account] = excluded;

        emit SetBlacklist(account, excluded);
    }

    function updateSwapAndLiquifyDividendEnabled(bool value) external onlyOwner {
        emit SwapAndLiquifyDividendEnabledUpdated(msg.sender, value);
        swapAndLiquifyDividendEnabled = value;
    }

    function enableTrading(bool value) external onlyOwner {
        require(!trading, "FLASH::setTrading: Trading is already set.");
        trading = value;
    }

    function enableImpactEffect(bool value) external onlyOwner {
        require(value != impactEnabled, "FLASH::enableTrading: ImpactEnabled is already set.");
        impactEnabled = value;
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        require(wallet != address(0), "FLASH::setMarketingWallet: Please use vaild payable address.");
        emit MarketingWalletUpdated(msg.sender, _marketingWalletAddress, wallet);
        _marketingWalletAddress = wallet;
    }

    function setAlgorithmWallet(address payable wallet) external onlyOwner{
        require(wallet != address(0), "FLASH::setAlgorithmWallet: Please use vaild payable address.");
        emit AlgorithmWalletUpdated(msg.sender, _algorithmWalletAddress, wallet);
        _algorithmWalletAddress = wallet;
    }

    function setBuybackWallet(address payable wallet) external onlyOwner{
        require(wallet != address(0), "FLASH::setBuybackWallet: Please use vaild payable address.");
        emit BuybackWalletUpdated(msg.sender, _buybackWalletAddress, wallet);
        _buybackWalletAddress = wallet;
    }

    function setLiquidityFee(uint256 value) external onlyOwner{
        totalFees = value.add(BUSDRewardsFee).add(marketingFee).add(burnFee).add(buybackFee).add(algorithmFee);
        require(totalFees <= 30, "FLASH::setLiquidityFee: Too high Fees");
        emit LiquidityFeeUpdated(msg.sender, liquidityFee, value);
        liquidityFee = value;
    }

    function setBUSDRewardsFee(uint256 value) external onlyOwner{
        totalFees = value.add(liquidityFee).add(marketingFee).add(burnFee).add(buybackFee).add(algorithmFee);
        require(totalFees <= 30, "FLASH::setBUSDRewardsFee: Too high Fees");
        emit BUSDRewardsFeeUpdated(msg.sender, BUSDRewardsFee, value);
        BUSDRewardsFee = value;
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        totalFees = value.add(BUSDRewardsFee).add(liquidityFee).add(burnFee).add(buybackFee).add(algorithmFee);
        require(totalFees <= 30, "FLASH::setMarketingFee: Too high Fees");
        emit MarketingFeeUpdated(msg.sender, marketingFee, value);
        marketingFee = value;
    }

    function setBurnFee(uint256 value) external onlyOwner{
        totalFees = value.add(BUSDRewardsFee).add(marketingFee).add(liquidityFee).add(buybackFee).add(algorithmFee);
        require(totalFees <= 30, "FLASH::setBurnFee: Too high Fees");
        emit BurnFeeUpdated(msg.sender, burnFee, value);
        burnFee = value;
    }

    function setBuybackFee(uint256 value) external onlyOwner{
        totalFees = value.add(BUSDRewardsFee).add(marketingFee).add(burnFee).add(liquidityFee).add(algorithmFee);
        require(totalFees <= 30, "FLASH::setBuybackFee: Too high Fees");
        emit BuybackFeeUpdated(msg.sender, buybackFee, value);
        buybackFee = value;
    }

    function setAlogrithmFee(uint256 value) external onlyOwner{
        totalFees = value.add(BUSDRewardsFee).add(marketingFee).add(burnFee).add(buybackFee).add(liquidityFee);
        require(totalFees <= 30, "FLASH::setAlogrithmFee: Too high Fees");
        emit AlgorithmFeeUpdated(msg.sender, algorithmFee, value);
        algorithmFee = value;
    }

    function setSellFee(uint256 value) external onlyOwner{
        require(sellFee <= 10, "FLASH::setSellFee: Too high Fees");
        emit SellFeeUpdated(msg.sender, algorithmFee, value);
        sellFee = value;
    }

    function updateSwapTokensAtAmount(uint256 newSwapAtAmount) external onlyOwner {
        swapTokensAtAmount = newSwapAtAmount * (10 ** 18);
        emit SwapTokensAtAmountUpdated(msg.sender, swapTokensAtAmount);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "FLASH::setAutomatedMarketMakerPair: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "FLASH::_setAutomatedMarketMakerPair: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "FLASH::updateGasForProcessing: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "FLASH::updateGasForProcessing: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function updateMinimumTokenBalanceForDividends(uint256 minimumTokenBalanceForDividends) external onlyOwner {
        dividendTracker.updateMinimumTokenBalanceForDividends(minimumTokenBalanceForDividends);
    }

    function setPriceImpact(uint256 _percent) external onlyOwner {
        priceImpact = _percent;
    }

    function calculPriceImpactLimit() internal view returns (uint256) {
        return ((uint256(100).sub(priceImpact)).mul(10**18)).div(100);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) external view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) external view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external returns(bool) {
		return dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "FLASH: transfer from the zero address");
        require(to != address(0), "FLASH: transfer to the zero address");
        require(amount <= maxTxAmount || isTxLimitExempt[from], "FLASH: transfer amount limit exceeded");
        require(!_isBlacklisted[to] && !_isBlacklisted[from], 'FLASH: Blacklisted address');
        require(isExcludedFromAntiWhale[to] || balanceOf(to) + amount <= maxTokensPerAddress, "FLASH: Max tokens limit for this account exceeded. Or try lower amount");
        require(isExcludedFromTransactionlock[from] || block.timestamp >= _transactionCheckpoint[from] + transactionLockTime, "Wait for transaction cooldown time to end before making a tansaction");
        require(isExcludedFromTransactionlock[to] || block.timestamp >= _transactionCheckpoint[to] + transactionLockTime, "Wait for transaction cooldown time to end before making a tansaction");

        _transactionCheckpoint[from] = block.timestamp;
        _transactionCheckpoint[to] = block.timestamp;

        if( !trading && 
            from != owner() && 
            from != address(this) && 
            to != owner() && 
            to != address(this) ) {

            require( !automatedMarketMakerPairs[to], "FLASH: Trading disabled");
            require( !automatedMarketMakerPairs[from], "FLASH: Trading disabled");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this)) ;

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( swapAndLiquifyDividendEnabled &&
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFee(marketingTokens, _marketingWalletAddress);

            if(buybackFee != 0){
                uint256 buybackTokens = contractTokenBalance.mul(buybackFee).div(totalFees);
                swapAndSendToFee(buybackTokens, _buybackWalletAddress);
            }
            
            if(algorithmFee != 0){
                uint256 algorithmTokens = contractTokenBalance.mul(algorithmFee).div(totalFees);
                super._transfer(address(this), _algorithmWalletAddress, algorithmTokens);
            }

            if(burnFee != 0){
                uint256 burnTokens = contractTokenBalance.mul(burnFee).div(totalFees);
                super._transfer(address(this), deadWallet, burnTokens);
            }

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount.mul(totalFees).div(100);
        	if(automatedMarketMakerPairs[to]){
                if ( impactEnabled && _priceImpactTax(amount)) {
                    fees += amount.mul(sellFee).div(100);
                }
        	}

        	amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }

    function swapAndSendToFee(uint256 tokens, address to) private  {
        uint256 initialBUSDBalance = IERC20(BUSD).balanceOf(address(this));

        swapTokensForBusd(tokens);
        uint256 newBalance = IERC20(BUSD).balanceOf(address(this)).sub(initialBUSDBalance);
        IERC20(BUSD).transfer(to, newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function swapTokensForBusd(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = BUSD;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        (,,uint256 liquidity) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
        require(liquidity > 0);
    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForBusd(tokens);
        uint256 dividends = IERC20(BUSD).balanceOf(address(this));
        try IERC20(BUSD).transfer(address(dividendTracker), dividends){
            dividendTracker.distributeBUSDDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
        catch {
            revert("FLASH::BUSD transfer reverted because of insufficient BUSD balance");
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(uniswapV2Pair)
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // Check for price impact before doing transfer
    function _priceImpactTax(uint256 amount) internal view returns (bool) {
        (uint256 _reserveA, uint256 _reserveB) = getReserves(
            address(this),
            BUSD
        );
        uint256 _constant = IUniswapV2Pair(uniswapV2Pair).kLast();
        uint256 _market_price = _reserveA.div(_reserveB);

        if (_reserveA == 0 && _reserveB == 0) {
            return false;
        } else {
            if (amount >= _reserveA) return false;

            uint256 _reserveA_new = _reserveA.sub(amount);
            uint256 _reserveB_new = _constant.div(_reserveA_new);

            if (_reserveB >= _reserveB_new) return false;
            uint256 receivedBUSD = _reserveB_new.sub(_reserveB);

            uint256 _new_price = (amount.div(receivedBUSD)).mul(10**18);
            uint256 _delta_price = _new_price.div(_market_price);
            uint256 _priceImpact = calculPriceImpactLimit();

            return (_delta_price < _priceImpact);
        }
    }

    function withdrawFlash(address toAddress, uint256 amount) external onlyOwner {
        uint256 maxblance = balanceOf(address(this));
        if(maxblance <= amount) {
            amount = maxblance;
        }
        super._transfer(address(this), toAddress, amount);
        emit FlashTokensWithdrawn(msg.sender, toAddress, amount);
    }
    
    function withdrawBNB(address toAddress, uint256 amount) external onlyOwner {
        uint256 bnbblance = address(this).balance;
        if(bnbblance <= amount) {
            amount = bnbblance;
        }
        payable(toAddress).sendValue(amount);
        emit BNBWithdrawn(msg.sender, toAddress, amount);
    }
}

contract FLASHDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event MinimumTokenBalanceForDividendsUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    event Processed(uint256 from, uint256 to);

    constructor() public DividendPayingToken("FLASH_Dividen_Tracker", "FLASH_DTker") {
    	claimWait = 21600;
        minimumTokenBalanceForDividends = 100000 * (10**18); //must hold 100000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        revert("FLASH_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        revert("FLASH_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main FLASH contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "FLASH_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "FLASH_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function updateMinimumTokenBalanceForDividends(uint256 newMinimumTokenBalanceForDividends) external onlyOwner {
        require(newMinimumTokenBalanceForDividends >= 100 * (10**18) && newMinimumTokenBalanceForDividends <= 10000000 * (10**18), "FLASH_Dividend_Tracker: MinimumTokenBalanceForDividends must be updated to between 100 and 10000000");
        require(newMinimumTokenBalanceForDividends != minimumTokenBalanceForDividends, "FLASH_Dividend_Tracker: Cannot update MinimumTokenBalanceForDividends to same value");
        emit MinimumTokenBalanceForDividendsUpdated(newMinimumTokenBalanceForDividends, minimumTokenBalanceForDividends);
        minimumTokenBalanceForDividends = newMinimumTokenBalanceForDividends;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilbeginOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilbeginOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) external returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}
        emit Processed(lastProcessedIndex, _lastProcessedIndex);
    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}