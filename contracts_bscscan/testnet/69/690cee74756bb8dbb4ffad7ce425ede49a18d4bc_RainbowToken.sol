/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

// SPDX-License-Identifier: MIT
//
// Copyright of The $RAINBOW Team
//
//  .______          ___       __  .__   __. .______     ______   ____    __    ____ 
//  |   _  \        /   \     |  | |  \ |  | |   _  \   /  __  \  \   \  /  \  /   / 
//  |  |_)  |      /  ^  \    |  | |   \|  | |  |_)  | |  |  |  |  \   \/    \/   /  
//  |      /      /  /_\  \   |  | |  . `  | |   _  <  |  |  |  |   \            /   
//  |  |\  \----./  _____  \  |  | |  |\   | |  |_)  | |  `--'  |    \    /\    /    
//  | _| `._____/__/     \__\ |__| |__| \__| |______/   \______/      \__/  \__/   
//
// There is a pot of gold at the end of every rainbow
// 
// $RAINBOW has 7% tax split across 7 protocols
// (Sells have doubled tax)
// 
// Red     1%: Burn
// Orange  1%: Buyback
// Yellow  1%: Reflected
// Green   1%: Charity
// Blue    1%: Liquidity
// Indigo  1%: Marketing
// Violet  1%: Lottery
                                                                                 
pragma solidity ^0.8.4;

// IERC20 interface taken from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Context abstract contract taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SafeMath library taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Address library taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// Ownable abstract contract taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// IUniswapV2Factory interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
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

// IUniswapV2Pair interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
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

// IUniswapV2Router01 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
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

// IUniswapV2Router02 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol 
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

/**
 * @dev The official RainbowToken smart contract
 */
contract RainbowToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    // General Info
    string private _name     = "RainbowToken";
    string private _symbol   = "RAINBOW";
    uint8  private _decimals = 9;
    
    // Liquidity Settings
    IUniswapV2Router02 public _pancakeswapV2Router; // The address of the PancakeSwap V2 Router
    address public _pancakeswapV2LiquidityPair;     // The address of the PancakeSwap V2 liquidity pairing for RAINBOW/WBNB
    
    bool currentlySwapping;

    modifier lockSwapping {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    
    // addresses
    address payable public _burnAddress      = payable(0x000000000000000000000000000000000000dEaD); // Burn address used to burn a portion of tokens
    address payable public _wallet_supply    = payable(0x683f5C7a783a6C621094689a9b234Cf22aDCBdd7); // Wallet Supply-team (là où nous enverrons les tokens à la création du smartcontract avant d'airdrop la v2)
    address payable public _wallet_part      = payable(0xbFc9B7F6352C4f684c93d09e049b006f203DBbF5); // Wallet Partenaires "générique" (quand nous n'avons pas add influenceur un acheteur pour le link à un partenaire, pour les 1,5% partenaires en BUSD et 1,5% partenaires en Nosta)
    address payable public _wallet_team      = payable(0x580229A61fA58291ee518d54B7e82Df259bB0020); // Wallet Team (pour les 1% de transaction fees "Team"
    address payable public _wallet_algo      = payable(0x301a2372486c9E70c61E750E7962f876Ec66156F); // Wallet Algo (pour les 7% transaction fees sur price impact > 2%)
    //address public immutable BUSD          = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD
    address public immutable BUSD            = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); //BUSD TESTNET
    
    // Balances
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Exclusions
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
   // Blacklist if TP
    mapping(address => bool) public _isBlacklisted;
    
    // Supply
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10**15 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalReflections; // Total reflections
    
    // Token Limits
    uint256 public _tokenSwapThreshold   = 100 * 10**9 * 10**9; // 100 billion
    
    // Token Tax Settings
    uint256 public    _TAX_TOTAL_FEE     = 8; // Total Transactions fees
    uint256 public    _CHARITY_FEE       = 3; // Transactions fees Partenaires (Nosta 1,5% et BUSD 1,5%)
    uint256 public    _TAX_FEE           = 1; //  Transactions fees Rewards holders (Nosta 0,5% et BUSD 0,5%)
    uint256 public    _BURN_FEE          = 1; // Transactions fees Burn (Nosta) => 1%
    uint256 public    _LP_FEE            = 2; // Transactions fees LP (Nosta 1% et BUSD 1%)
    uint256 public    _TEAM_FEE          = 1; // Transactions fees team (Nosta) => 1%
    uint256 public    _TAX_MORE_FEE      = 7; // Transactions fees Price impact (BUSD) => 7%
    
    // Track original fees to bypass fees for charity account
    uint256 private ORIG_TAX_TOTAL_FEE = _TAX_TOTAL_FEE;
    uint256 private ORIG_CHARITY_FEE  = _CHARITY_FEE;
    uint256 private ORIG_TAX_FEE      = _TAX_FEE;
    uint256 private ORIG_BURN_FEE     = _BURN_FEE;
    uint256 private ORIG_LP_FEE       = _LP_FEE;
    uint256 private ORIG_TEAM_FEE     = _TEAM_FEE;
    uint256 private ORIG_TAX_MORE_FEE = _TAX_MORE_FEE;
    
    // Timer Constants 
    uint256 private constant TWO_DAYS = 86400 * 2; // How many seconds in two days
    
    // Anti-Whale Settings 
    uint256 public _whaleSellThreshold = 500 * 10**9 * 10**9; // 500 billion
    mapping (address => uint) private _timeLastSell;    
    
    // LIQUIDITY
    bool public _enableLiquidity = false; // Controls whether the contract will swap tokens
    bool public _isTrading       = false; // Controls whether the contract will trade tokens

    uint256 private _algoPool    = 0;     // How many reflections are in the algo pool
    
    event Watch1(address _from, address _to);
    event Watch2(address _from, address _to);
    event Watch3(string _msg, address _from, address _to);
    event Watch4(string _msg);
    event Watch5(address[] _path);
    event Watch6(string _msg, uint256 tax);
    event Watch7(string _msg, bool _isTrue);
    
    constructor () {
        // Mint the total reflection balance to the deployer of this contract
        _rOwned[_msgSender()] = _rTotal;
        
        // Exclude the owner and the contract from paying fees
        _isExcludedFromFees[_msgSender()]   = true;
        _isExcludedFromFees[address(this)]  = true;
        _isExcludedFromFees[_wallet_supply] = true;
        _isExcludedFromFees[_wallet_part]   = true;
        _isExcludedFromFees[_wallet_team]   = true;
        _isExcludedFromFees[_wallet_algo]   = true;
        
        // Set up the pancakeswap V2 router
        IUniswapV2Router02 pancakeswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _pancakeswapV2LiquidityPair = IUniswapV2Factory(pancakeswapV2Router.factory())
            .createPair(address(this), pancakeswapV2Router.WETH());
        _pancakeswapV2Router = pancakeswapV2Router;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    /**
     * @notice Required to recieve BNB from PancakeSwap V2 Router when swaping
     */
    receive() external payable {}
    
    /**
     * @notice Withdraws BNB from the contract
     */
    function withdrawBNB(uint256 amount) public onlyOwner() {
        if(amount == 0) payable(owner()).transfer(address(this).balance);
        else payable(owner()).transfer(amount);
    }
    
    /**
     * @notice Withdraws non-RAINBOW tokens that are stuck as to not interfere with the liquidity
     */
    function withdrawForeignToken(address token) public onlyOwner() {
        require(address(this) != address(token), "Cannot withdraw native token");
        IERC20(address(token)).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    
    /**
     * @notice Transfers BNB to an address
     */
    function transferBNBToAddress(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    /**
     * @notice Allows the contract to change the router, in the instance when PancakeSwap upgrades making the contract future proof
     */
    function setRouterAddress(address router) public onlyOwner() {
        // Connect to the new router
        IUniswapV2Router02 newPancakeSwapRouter = IUniswapV2Router02(router);
        
        // Grab an existing pair, or create one if it doesnt exist
        address newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).getPair(address(this), newPancakeSwapRouter.WETH());
        if(newPair == address(0)){
            newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).createPair(address(this), newPancakeSwapRouter.WETH());
        }
        _pancakeswapV2LiquidityPair = newPair;

        _pancakeswapV2Router = newPancakeSwapRouter;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getTotalReflections() external view returns (uint256) {
        return _totalReflections;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function isExcludedFromReflection(address account) external view returns(bool) {
        return _isExcluded[account];
    }
    
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = false;
    }
   
    function setTokenSwapThreshold(uint256 tokenSwapThreshold) external onlyOwner() {
        _tokenSwapThreshold = tokenSwapThreshold;
    }
    
    function setLiquidity(bool b) external onlyOwner() {
        _enableLiquidity = b;
    }

    function setTrading(bool b) external onlyOwner() {
        _isTrading = b;
    }

    function updateFee(uint256 _tx_charityFee, uint256 _txFee, uint256 _burnFee, uint256 _teamFee, uint256 _moreTxFee, uint256 _LPFee) onlyOwner() public{
        _CHARITY_FEE       = _tx_charityFee;
        _TAX_FEE           = _txFee;
        _BURN_FEE          = _burnFee;
        _TEAM_FEE          = _teamFee;
        _LP_FEE            = _LPFee;
        _TAX_MORE_FEE      = _moreTxFee;
        _TAX_TOTAL_FEE     = _CHARITY_FEE.add(_TAX_FEE).add(_BURN_FEE).add(_TEAM_FEE).add(_LP_FEE);
    
        ORIG_CHARITY_FEE   = _CHARITY_FEE;
        ORIG_TAX_FEE       = _TAX_FEE;
        ORIG_BURN_FEE      = _BURN_FEE;
        ORIG_TEAM_FEE      = _TEAM_FEE;
        ORIG_LP_FEE        = _LP_FEE;
        ORIG_TAX_MORE_FEE  = _TAX_MORE_FEE;
        ORIG_TAX_TOTAL_FEE = _TAX_TOTAL_FEE;
    }
    
    function removeAllFees() private {
        if(_CHARITY_FEE == 0 && _TAX_FEE ==  0 && _BURN_FEE ==  0 && _TEAM_FEE == 0 && _TAX_MORE_FEE ==  0 && _LP_FEE ==  0 && _TAX_TOTAL_FEE == 0) return;
    
        ORIG_CHARITY_FEE   = _CHARITY_FEE;
        ORIG_TAX_FEE       = _TAX_FEE;
        ORIG_BURN_FEE      = _BURN_FEE;
        ORIG_LP_FEE        = _LP_FEE;
        ORIG_TEAM_FEE      = _TEAM_FEE;
        ORIG_TAX_MORE_FEE  = _TAX_MORE_FEE;
        ORIG_TAX_TOTAL_FEE = _TAX_TOTAL_FEE;
    
        _CHARITY_FEE       = 0;
        _TAX_FEE           = 0;
        _BURN_FEE          = 0;
        _TEAM_FEE          = 0;
        _TAX_MORE_FEE      = 0;
        _LP_FEE            = 0;
        _TAX_TOTAL_FEE     = 0;
    
    }
    
    function restoreAllFees() private {
        _CHARITY_FEE      = ORIG_CHARITY_FEE;
        _TAX_FEE          = ORIG_TAX_FEE;
        _BURN_FEE         = ORIG_BURN_FEE;
        _TEAM_FEE         = ORIG_TEAM_FEE;
        _TAX_MORE_FEE     = ORIG_TAX_MORE_FEE;
        _LP_FEE           = ORIG_LP_FEE;
        _TAX_TOTAL_FEE    = ORIG_TAX_TOTAL_FEE;
    }
    
    function _getTaxFee() private view returns(uint256) {
        return _TAX_TOTAL_FEE;
    }
    
    // Check for price impact before doing transfer
    function _priceImpactTax(uint256 amount) public returns(bool) { 
        (uint256 _reserveA, uint256 _reserveB, ) = IUniswapV2Pair(_pancakeswapV2LiquidityPair).getReserves();
        uint256 _constant = IUniswapV2Pair(_pancakeswapV2LiquidityPair).kLast();
        uint256 _market_price = _reserveA.div(_reserveB);
 
        uint256 _reserveA_new = _reserveA.sub(amount);
        uint256 _reserveB_new = _constant.div(_reserveA_new);
        uint256 receivedBUSD = _reserveB_new.sub(_reserveB);
        
        uint256 _new_price    = (amount.div(receivedBUSD)).mul(10**18);
        uint256 _delta_price  = _new_price.div(_market_price);
        uint256 _portion      = uint256(1).mul(10**18);
        uint256 _price_impact = _portion.sub(_delta_price); 
        uint256 _price_impact_percent =  _price_impact.mul(100);
        
        emit Watch4("_priceImpactTax");
        
        return (_price_impact_percent > uint256(200).mul(10**18));
    }

    /**
     * @notice Converts a token value to a reflection value
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    /**
     * @notice Converts a reflection value to a token value
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    

    /**
     * @notice Collects all the necessary transfer values
     */
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    /**
     * @notice Calculates transfer token values
     */
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(_TAX_TOTAL_FEE).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    /**
     * @notice Calculates transfer reflection values
     */
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    /**
     * @notice Calculates the rate of reflections to tokens
     */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**
     * @notice Gets the current supply values
     */
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
    
    /**
     * @notice Excludes an address from receiving reflections
     */
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
     * @notice Includes an address back into the reflection system
     */
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
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
    
    /**
     * @notice Handles the before and after of a token transfer, such as taking fees and firing off a swap and liquify event
     */
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // Only the owner of this contract can bypass the max transfer amount
        if(from != owner() && to != owner()) {
            require(_isTrading , "Is trading Disabled.");
        }
        
        uint delta = block.timestamp.sub(_timeLastSell[to]);
        
        // If the last time of sell < 48H then blacklist the _msgSender
        if (delta > 0 && delta <= TWO_DAYS) {
            // blacklist;
            _isBlacklisted[to] = true;
            revert();
        }else {
            _isBlacklisted[to] = false;
        }

        emit Watch7("Buy _isBlacklisted", _isBlacklisted[to]);
        emit Watch7("Delta - ", delta > 0 && delta <= TWO_DAYS);
        emit Watch3("_transfer", from, to);
        
        // Gets the contracts RAINBOW balance for buybacks, charity, liquidity and marketing
        uint256 tokenBalance = balanceOf(address(this));
        
        // AUTO-LIQUIDITY MECHANISM
        // Check that the contract balance has reached the threshold required to execute a swap and liquify event
        // Do not execute the swap and liquify if there is already a swap happening
        // Do not allow the adding of liquidity if the sender is the PancakeSwap V2 liquidity pool
        if (_enableLiquidity && tokenBalance >= _tokenSwapThreshold && !currentlySwapping && from != _pancakeswapV2LiquidityPair) {
            tokenBalance = _tokenSwapThreshold;
            swapAndLiquify(tokenBalance);
        }
        
        // If any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);

        // If we are taking fees and sending tokens to the liquidity pool (i.e. a sell), check for anti-whale tax
        if (takeFee && to == _pancakeswapV2LiquidityPair) {
            emit Watch7("takeFee Before sell 1 -", takeFee);

            // We will assume that the normal sell tax rate will apply
            uint256 fee = _TAX_TOTAL_FEE;
            emit Watch7("takeFee in sell", takeFee);
            emit Watch1(from, to);

        
            // if price impact is more than 2% then tax more fees (7%)
            if (_priceImpactTax(amount)) {
                fee = _TAX_TOTAL_FEE.add(_TAX_MORE_FEE);
            } 
                                    
            // Set the tax rate to the sell tax rate, if the price impact sell tax rate applies then we set that
            ORIG_TAX_FEE = _TAX_TOTAL_FEE;
            _TAX_TOTAL_FEE = fee;
            emit Watch6("_TAX_TOTAL_FEE = ", _TAX_TOTAL_FEE);
                        
            _isBlacklisted[from] = true;
            _timeLastSell[from] = block.timestamp;
                            
            emit Watch4("_transfer : _isBlacklisted");
        }
        
        // Remove fees completely from the transfer if either wallet are excluded
         if (!takeFee) {
            emit Watch4("_transfer !takeFee : 2197");
            removeAllFees();
        }
        
        _tokenTransfer(from, to, amount);
        
            
        // If we removed the fees for this transaction, then restore them for future transactions
        if (!takeFee) {
            emit Watch4("_transfer !takeFee : 2206");
            restoreAllFees();
        }
            
        // If this transaction was a sell, and we took a fee, restore the fee amount back to the original buy amount
        if (takeFee && to == _pancakeswapV2LiquidityPair) {
            emit Watch4("_transfer !takeFee : 2112");
            _TAX_TOTAL_FEE = ORIG_TAX_FEE;
        }
        
    }
    
    /**
     * @notice Handles the actual token transfer
     */
    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        // Calculate the values required to execute a transfer
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, _getRate());
        
        // Transfer from sender to recipient
		if (_isExcluded[sender]) {
		    _tOwned[sender] = _tOwned[sender].sub(tAmount);
		}
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		
		if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		}
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
		
		// This is always 8% of a transaction worth of tokens
        if (_TAX_TOTAL_FEE > 0) {
              uint256 tPortion        = tFee.div(_TAX_TOTAL_FEE);     // 1% (burn)
              uint256 tPortionNosta   = tPortion.mul(3); // 3% (1.5% Partenaires 0.5% Holders 1% LP)
              uint256 tPortionBUSD    = tPortion.mul(4); // 4% (1.5% Partenaires 0.5% Holders 1% LP 1% Team)
              
                // Burn some of the taxed tokens
                _burnTokens(tPortion);
        
                // Reflect some of the taxed tokens
              _reflectTokens(tPortionNosta);
        
                // Take the rest of the taxed tokens for the other functions
                uint256 _restTokens = tFee.sub(tPortion).sub(tPortionNosta);
                // (Team BUSD, LP (BUSD) , Rewards BUSD, Partenaires BUSD & TAX_MORE)
                if(_TAX_TOTAL_FEE == 8){
                    _takeTokens(_restTokens, tPortionBUSD);
                }else{
                    _takeTokens(_restTokens, tPortionBUSD.add(_restTokens));
                }
        } 
            // Emit an event 
            emit Transfer(sender, recipient, tTransferAmount);
    }
    
    /**
     * @notice Burns RAINBOW tokens straight to the burn address
     */
    function _burnTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rOwned[_burnAddress] = _rOwned[_burnAddress].add(rFee);
        if(_isExcluded[_burnAddress]) {
            _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tFee);
        }
    }

    /**
     * @notice Increases the rate of how many reflections each token is worth
     */
    function _reflectTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _totalReflections = _totalReflections.add(tFee);
    }
    
    /**
     * @notice The contract takes a portion of tokens from taxed transactions
     */
    function _takeTokens(uint256 tTakeAmount, uint256 tAlgo) private {
        uint256 currentRate = _getRate();
        uint256 rTakeAmount = tTakeAmount.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTakeAmount);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tTakeAmount);
        }
        
        // Add a portion to the algo wallet 
        uint256 rAlgo = tAlgo.mul(currentRate);
        _algoPool = _algoPool.add(rAlgo);
    }
    
    /**
    * @notice Generates BUSD by selling tokens and pairs some of the received BUSD with tokens to add and grow the liquidity pool
    */
    function swapAndLiquify(uint256 token) private lockSwapping {
        // Capture the contract's current BUSD balance so that we know exactly the amount of BUSD that the
        // swap creates. This way the liquidity event wont include any BUSD that has been collected by other means.
        uint256 initialBNBBalance = address(this).balance;
        emit Watch4("swapAndSendToFee - 2368");
    
        // Split the contract balance into the swap portion and the liquidity portion
        if(_TAX_TOTAL_FEE == 8){
            uint256 portion      = token.div(2);       // 1/4 of the tokens, used for liquidity
            uint256 swapAmount   = token.sub(portion); // 3/4 of the tokens, used to swap for BUSD
            emit Watch4("swapAndSendToFee - 2374");
    
            swapTokensForBNB(swapAmount);
    
            // How much BUSD did we just receive
            uint256 receivedBNB = address(this).balance.sub(initialBNBBalance);
            
            uint256 portionBUSD = receivedBNB.div(4);
            //uint256 BUSDDividends = receivedBNB.div(2);
    
            // Add liquidity via the PancakeSwap V2 Router 1% Nosta 1% BUSD
            addLiquidity(portion, portionBUSD);
    
            // add to dividends 1,5% partenaires
            /*
            sendDividendsForPart((BUSDDividends.mul(3)).div(4));
            // add to dividends 0,5% holders
            sendDividendsForHolders(BUSDDividends.div(4));
            // transfer 1% BUSD received to team wallet
            IBEP20(BUSD).transfer(_wallet_team, portionBUSD);
            */
            emit Watch4("swapAndLiquify : _TAX_TOTAL_FEE == 8");
            
        }else {
            uint256 portion      = token.div(15);      // 1/15 of the tokens, used for liquidity
            uint256 swapAmount   = portion.mul(11);           // 11/15 of the tokens, used to swap for BUSD
            emit Watch4("swapAndSendToFee - 2559");
            swapTokensForBNB(swapAmount);
    
            // How much BUSD did we just receive
            uint256 receivedBNB  = address(this).balance.sub(initialBNBBalance);
            uint256 portionBUSD  = receivedBNB.div(11);
            //uint256 BUSDDividends = (receivedBNB.mul(2)).div(11);
    
            // Add liquidity via the PancakeSwap V2 Router 1% Nosta 1% BUSD
            addLiquidity(portion, portionBUSD);
            
            /*
            // add to dividends 1,5% partenaires
            sendDividendsForPart(BUSDDividends.mul(3).div(4));
            // add to dividends 0,5% holders
            sendDividendsForHolders(BUSDDividends.div(4));
            // transfer 1% BUSD received to team wallet
            IBEP20(BUSD).transfer(_wallet_team, portionBUSD);
            // transfer 1% BUSD received to algo wallet
            IBEP20(BUSD).transfer(_wallet_algo, portionBUSD.mul(7));
            */
            emit Watch4("swapAndLiquify : _TAX_TOTAL_FEE > 8");
        }
    }
    /**
     * @notice Swap tokens for BNB storing the resulting BNB in the contract
     */
    function swapTokensForBNB(uint256 tokenAmount) private {
        // Generate the Pancakeswap pair for DHT/WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeswapV2Router.WETH(); // WETH = WBNB on BSC

        _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

        // Execute the swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp.add(300)
        );
    }
    
    /**
     * @notice Swaps BNB for tokens and immedietely burns them
     */
    function swapBNBForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(this);

        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of RAINBOW
            path,
            _burnAddress, // Burn address
            block.timestamp.add(300)
        );
    }

    /**
     * @notice Adds liquidity to the PancakeSwap V2 LP
     */
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

        // Adds the liquidity and gives the LP tokens to the owner of this contract
        // The LP tokens need to be manually locked
        _pancakeswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // Take any amount of tokens (ratio varies)
            0, // Take any amount of BNB (ratio varies)
            owner(),
            block.timestamp.add(300)
        );
    }
    
    /**
     * @notice Allows a user to voluntarily reflect their tokens to everyone else
     */
    function reflect(uint256 tAmount) public {
        require(!_isExcluded[_msgSender()], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _totalReflections = _totalReflections.add(tAmount);
    }
}