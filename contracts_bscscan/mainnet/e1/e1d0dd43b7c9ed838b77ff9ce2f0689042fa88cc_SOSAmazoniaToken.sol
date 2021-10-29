/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

/**
 * #SOSAMZ - SOS Amazonia ($SOSAMZ)
 * 
 * #SOSAMZ features:
 * Total supply: 200,000,000.000000000
 * 4% fee will burned forever;
 * 3% fee will distribute to all holders;
 * 1% fee will distribute to donation wallet;
 * 
 * Donation wallet address: 0x7ad6f698A07673Eb9C71016fbCDD61c45Ee7B7C8
 * 
 * Official site    : https://www.tokensosamazonia.com
 * Instagram profile: @tokensosamazoniabr
 * Telegram chat    : t.me/sosamazoniabrasil
 */

pragma solidity ^0.8.7;
// SPDX-License-Identifier: Unlicensed

/**
 * @dev BEP20 Token interface
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Add Pancake Router and Pancake Pair interfaces
 * 
 * from https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter01.sol
 */
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// from https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol
interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

// from https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol
interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setRewardFeeTo(address) external;
    function setRewardFeeToSetter(address) external;
}

// from https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakePair.sol
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

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
 */
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { uint256 c = a + b; if (c < a) return (false, 0); return (true, c); } }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b > a) return (false, 0); return (true, a - b); } }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (a == 0) return (true, 0); uint256 c = a * b; if (c / a != b) return (false, 0); return (true, c); } }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a / b); } }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a % b); } }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b <= a, errorMessage); return a - b; } }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a / b; } }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a % b; } }
}

/**
 * @dev Collection of functions related to the address type
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 */
library Address {
    function isContract(address account) internal view returns (bool) { uint256 size; assembly { size := extcodesize(account) } return size > 0; }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) { return functionCall(target, data, "Address: low-level call failed"); }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) { return functionCallWithValue(target, data, 0, errorMessage); }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) { return functionCallWithValue(target, data, value, "Address: low-level call with value failed"); }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) { return functionStaticCall(target, data, "Address: low-level static call failed"); }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) { return functionDelegateCall(target, data, "Address: low-level delegate call failed"); }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) { return returndata; } else { if (returndata.length > 0) { assembly { let returndata_size := mload(returndata) revert(add(32, returndata), returndata_size) } } else { revert(errorMessage); } }
    }
}

/**
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false).
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol
 */
library SafeBEP20 {
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal { _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value)); }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal { _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value)); }
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeBEP20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance)); 
    }
    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed"); }
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }
    function _msgData() internal view virtual returns (bytes memory) { this;  return msg.data; }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
contract Ownable is Context {
    address private _owner;
	address private _newOwner;
    address private _previousOwner;
    uint256 private _lockTime;

	constructor() { 
	    _owner = _msgSender(); 
	    emit OwnershipTransferred(address(0), _owner);
	}

    modifier onlyOwner() { 
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) { return _owner; }

    function renounceOwnership() external onlyOwner { 
        emit OwnershipTransferred(_owner, address(0)); 
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner { 
        require(newOwner != address(0), "Ownable: new owner is the zero address"); 
        _newOwner = newOwner;
    }

	function acceptOwnership() external {
        require(_newOwner == _msgSender(), "Ownable: you don't have permission to changer owner");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner    = _newOwner;
        _newOwner = address(0);
    }

    // Locks the contract for owner for the amount of time provided
    function lockContract(uint256 time) external onlyOwner {
        uint256 maxTime = block.timestamp + 315576000; // maxtime current time + 315576000 seconds (10 years)
		require(time > block.timestamp && time < maxTime, "Time out of range: time is before current time or older than 10 years");
        _previousOwner = _owner;
        emit OwnershipTransferred(_owner, address(0));
        _owner    = address(0);
        _lockTime = time;
    }

    // Unlocks the contract for owner when _lockTime is exceeds
    function unlockContract() external {
        require(block.timestamp > _lockTime, "Time to unlock the contract was not reached");
		require(_previousOwner == _msgSender(), "You don't have permission to unlock");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner         = _previousOwner;
		_previousOwner = address(0);
		_lockTime      = 0;
    }

    function getUnlockContractTime() external view returns (uint256) { 
        require(_lockTime > 0, "Contract is not locked!"); 
        return _lockTime;
    }

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/**
 * @dev Contract module based on Safemoon Protocol
 */
contract SOSAmazoniaToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeBEP20 for IBEP20;

    mapping(address => uint256) private _rBalances;
    mapping(address => mapping(address => uint256)) private _allowances;
	mapping(address => bool) private _isLockedWallet;
    mapping(address => bool) private _isExcludedFromMax;
	mapping(address => bool) private _isExcludedFromFee;

	IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;
	IPancakePair private immutable _WbnbBusdPair;

	address private constant _burnAddress          = 0x000000000000000000000000000000000000dEaD;
	address payable public constant donationWallet = payable(0x7ad6f698A07673Eb9C71016fbCDD61c45Ee7B7C8);

    string private constant _name          = "SOS Amazonia";
    string private constant _symbol        = "SOSAMZ";
    uint8 private constant _decimals       = 9;
    uint256 private constant _tTotalSupply = 200 * 10**6 * 10**_decimals; // 200 millions

    uint256 private constant _MAX = ~uint256(0); // _MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935

	// custom variables system
    uint256 public buyMaxTxAmount   = 50;  // 50% of LP
    uint256 public sellMaxTxAmount  = 50;  // 50% of LP
    uint256 public otherMaxTxAmount = 100; // 100% of balance

	uint256 public buyRewardFee   = 3; // 3% Fee to Reward on buy
	uint256 public sellRewardFee  = 3; // 3% Fee to Reward on sell
	uint256 public otherRewardFee = 3; // 3% Fee to Reward on other transaction

	uint256 public buyBurnFee   = 4; // 4% Fee to burn on buy
	uint256 public sellBurnFee  = 4; // 4% Fee to burn on sell
	uint256 public otherBurnFee = 4; // 4% Fee to burn on other transaction

    uint256 public buyDonationFee   = 1; // 1% Fee to Donation wallet on buy
	uint256 public sellDonationFee  = 1; // 1% Fee to Donation wallet on sell
	uint256 public otherDonationFee = 1; // 1% Fee to Donation wallet on other transaction

    // variables for LP lock system
    bool public isLockedLP = false;
    uint256 private _releaseTimeLP;

	// variables for pre-sale system
	bool public isPreSaleEnabled = false;
	uint256 private _sDivider;
    uint256 private _sPrice;
	uint256 private _sDecimals;
    uint256 private _sTotal;

	// variables for safemoon contract system
    uint256 private _rTotalSupply;
    uint256 private _maxTxAmount;
    uint256 private _rewardFee;
    uint256 private _previousRewardFee;
    uint256 private _burnFee;
    uint256 private _previousBurnFee;
    uint256 private _donationFee;
    uint256 private _previousDonationFee;
    uint256 private _tFeeTotal;
    uint256 private _tDonationTokensTotal;
	uint256 private _tDonationBnbTotal;

	// struct for reflect transfers and fees
	struct rValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rRewardFee;
        uint256 rBurnFee;
        uint256 rDonationFee;
    }
    // struct for no-reflect transfers and fees
    struct tValues {
        uint256 tTransferAmount;
        uint256 tRewardFee;
        uint256 tBurnFee;
        uint256 tDonationFee;
    }

	/**
	 * @dev For Pancakeswap Router V2, use:
	 * 0x10ED43C718714eb63d5aA57B78B54704E256024E to Mainnet Binance Smart Chain;
     * 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 to Testnet Binance Smart Chain;
	 *
	 * For WBNB/BUSD LP Pair, use:
	 * 0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16 to Mainnet Binance Smart Chain;
	 * 0xe0e92035077c39594793e61802a350347c320cf2 to Testnet Binance Smart Chain;
	 */
    constructor(address pancakeRouterAddress, address wBnbBusdPairAddress) {
		require(pancakeRouterAddress.isContract(), "This address is not a valid contract");
		require(wBnbBusdPairAddress.isContract(), "This address is not a valid contract");
		// set reflect totalSupply variable
        _rTotalSupply            = (_MAX - (_MAX % _tTotalSupply));
        _rBalances[_msgSender()] = _rTotalSupply;
        emit Transfer(address(0), _msgSender(), _tTotalSupply);
        // Create a pancake pair for this new token
        pancakePair   = IPancakeFactory(
            IPancakeRouter02(pancakeRouterAddress).factory()
            ).createPair(
                address(this), IPancakeRouter02(pancakeRouterAddress).WETH()
                );
        // set the rest of the contract variables
        pancakeRouter = IPancakeRouter02(pancakeRouterAddress);
		_WbnbBusdPair = IPancakePair(wBnbBusdPairAddress);
		// exclude owner, this contract, burn address and donation wallet from limit of transaction
        _isExcludedFromMax[owner()]        = true;
		_isExcludedFromMax[address(this)]  = true;
		_isExcludedFromMax[_burnAddress]   = true;
		_isExcludedFromMax[donationWallet] = true;
		// exclude owner, this contract, burn address and donation wallet from fee
        _isExcludedFromFee[owner()]        = true;
        _isExcludedFromFee[address(this)]  = true;
        _isExcludedFromFee[_burnAddress]   = true;
		_isExcludedFromFee[donationWallet] = true;
    }

	// to receive BNBs
    receive() external payable {
		if (msg.value > 0) {
            if (!isPreSaleEnabled) {
                donationWallet.transfer(msg.value);
			    _tDonationBnbTotal = _tDonationBnbTotal.add(msg.value);
			    emit Received(_msgSender(), donationWallet, msg.value);
            } else {
                revert();
            }
		}
	}

    function getOwner() external view override returns (address) { return owner(); }

    function name() external pure override returns (string memory) { return _name; }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function decimals() external pure override returns (uint8) { return _decimals; }

    function totalSupply() external pure override returns (uint256) { return _tTotalSupply; }

    function balanceOf(address account) public view override returns (uint256) { return _tokenFromReflection(_rBalances[account]); }

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

    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function lockWallet(address account) external onlyOwner {
		require(!_isLockedWallet[account], "Account is already locked");
        _isLockedWallet[account] = true;
        emit LockedWallet(account, true);
    }

    function unLockWallet(address account) external onlyOwner {
		require(_isLockedWallet[account], "Account is not locked");
        _isLockedWallet[account] = false;
        emit LockedWallet(account, false);
    }

    function isLockedWallet(address account) external view returns(bool) { return _isLockedWallet[account]; }

	function excludeFromMax(address account) external onlyOwner {
		require(!_isExcludedFromMax[account], "Account is already excluded from limits");
		_isExcludedFromMax[account] = true; 
	}

    function includeInMax(address account) external onlyOwner {
		require(_isExcludedFromMax[account], "Account is not excluded from limits");
		_isExcludedFromMax[account] = false; 
	}

	function isExcludedFromMax(address account) external view returns (bool) { return _isExcludedFromMax[account]; }

    function excludeFromFee(address account) external onlyOwner {
		require(!_isExcludedFromFee[account], "Account is already excluded from fees");
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
		require(_isExcludedFromFee[account], "Account is not excluded from fees");
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) external view returns(bool) { return _isExcludedFromFee[account]; }

    function setBuyMaxTxAmountPercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        buyMaxTxAmount = value;
    }

	function setSellMaxTxAmountPercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
	    sellMaxTxAmount = value;
	}

	function setOtherMaxTxAmountPercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
	    otherMaxTxAmount = value;
	}

	function setBuyRewardFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        buyRewardFee = value;
    }

    function setSellRewardFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        sellRewardFee = value;
    }

    function setOtherRewardFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        otherRewardFee = value;
    }

    function setBuyBurnFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        buyBurnFee = value;
    }

    function setSellBurnFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        sellBurnFee = value;
    }

    function setOtherBurnFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        otherBurnFee = value;
    }

	function setBuyDonationFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        buyDonationFee = value;
    }

    function setSellDonationFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        sellDonationFee = value;
    }

    function setOtherDonationFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        otherDonationFee = value;
    }

    function lockLP (uint256 releaseTime) external onlyOwner {
        require(!isLockedLP, "LP is already locked!");
        uint256 maxReleaseTime = block.timestamp + 315576000; // maxtime current time + 315576000 seconds (10 years)
		require(releaseTime > block.timestamp && releaseTime < maxReleaseTime, "Release time out of range: release time is before current time or older than 10 years");
        IBEP20 tokenLP  = IBEP20(pancakePair);
        if (tokenLP.allowance(_msgSender(), address(this)) > 0) {
            uint256 amount = tokenLP.balanceOf(_msgSender());
            require(amount > 0, "No tokens to lock");
			tokenLP.safeTransferFrom(_msgSender(), address(this), amount);
		}
        _releaseTimeLP = releaseTime;
        isLockedLP     = true;
    }

	function releaseLP () external onlyOwner {
        require(isLockedLP, "LP is not already locked!");
        require(block.timestamp > _releaseTimeLP, "Current time is before release time");
        IBEP20 tokenLP = IBEP20(pancakePair);
        uint256 amount = tokenLP.balanceOf(address(this));
        require(amount > 0, "No tokens to release");
        tokenLP.safeTransfer(_msgSender(), amount);
        _releaseTimeLP = 0;
        isLockedLP     = false;
    }

    function releaseTimeLP () external view returns (uint256) {
        require(isLockedLP, "LP is not already locked!");
        return _releaseTimeLP;
    }

    function totalFees() external view returns (uint256) { return _tFeeTotal; }

	function totalDonations() external view returns (uint256 tokens, uint256 BNBs) { return (_tDonationTokensTotal, _tDonationBnbTotal); }

	function startPreSale(uint256 referPercent, uint256 salePrice, uint256 decimalPlaces, uint256 tokenAmount) external onlyOwner {
		require(!isPreSaleEnabled, "Pre-sale is already activated!");
		require(referPercent >= 0 && referPercent <= 100, "Value out of range");
		require(salePrice > 0, "Sale price must be greater than zero");
		require(decimalPlaces >= 0 && decimalPlaces <= _decimals, "Value out of range");
		require(tokenAmount > 0 && tokenAmount <= balanceOf(_msgSender()).div(10**_decimals), "Token amount must be greater than zero and less than or equal to balance of owner.");
		_sDivider  = referPercent;
		_sPrice    = salePrice;
		_sDecimals = decimalPlaces;
		_sTotal    = 0;
		_transfer(_msgSender(), address(this), tokenAmount.mul(10**_decimals));
		isPreSaleEnabled = true;
    }

	function stopPreSale() external onlyOwner {
		require(isPreSaleEnabled, "Pre-sale is not already activated!");
		_getBnbAndTokens(_msgSender());
		isPreSaleEnabled = false;
    }

	function tokenSale(address refer) external payable returns (bool success) {
		require(isPreSaleEnabled, "Pre-sale is not available.");
		_tokenSale(refer, _msgSender(), msg.value);
		return true;
    }

    function clearBNB(uint256 amountPercent) external onlyOwner {
        require(amountPercent >= 0 && amountPercent <= 100, "Value out of range: values between 0 and 100");
		// gets the BNBs accumulated in the contract
		uint256 bnbAmount = address(this).balance;
		if (bnbAmount > 0) {
		    _msgSender().transfer(bnbAmount.mul(amountPercent).div(10**2));
		}
    }

    function viewSale() external view returns (uint256 referPercent, uint256 SalePrice, uint256 decimalPlaces, uint256 SaleCap, uint256 remainingTokens, uint256 SaleCount) {
		require(isPreSaleEnabled, "Pre-sale is not available.");
		return (_sDivider, _sPrice, _sDecimals, address(this).balance, balanceOf(address(this)), _sTotal);
    }

	function _tokenSale(address _refer, address _receiver, uint256 _bnbReceived) private {
		uint256 _priceInDolar = 0;
		(uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) = _WbnbBusdPair.getReserves();
		_blockTimestampLast = 0; // to disable compiler alerts
		// (BUSD / WBNB) = Price in dolar, Price in dolar * BNB = Dolars per BNB, Dolars per BNB / Sales price in dolar's cents / Decimal places = Tokens
		// BUSD * 10^17 has been added to accurately calculate decimal numbers.
		if (pancakeRouter.WETH() == _WbnbBusdPair.token0()) {
		    _priceInDolar = _reserve1.mul(10**17).div(_reserve0);
		} else if (pancakeRouter.WETH() == _WbnbBusdPair.token1()) {
		    _priceInDolar = _reserve0.mul(10**17).div(_reserve1);
		} else {
		    revert();
		}
		uint256 _dolarsPerBnb = _priceInDolar.mul(_bnbReceived).div(1 ether);
		uint256 _tokens       = _dolarsPerBnb.div(_sPrice).div(10**_sDecimals);

		if (_receiver != _refer && balanceOf(_refer) != 0 && _refer != address(0)) {
			uint256 referTokens = _tokens.mul(_sDivider).div(10**2);
			require(_tokens.add(referTokens) <= balanceOf(address(this)), "Insufficient tokens for this sale");
			_transfer(address(this), _refer, referTokens);
			_transfer(address(this), _receiver, _tokens);
        } else {
            require(_tokens <= balanceOf(address(this)), "Insufficient tokens for this sale");
		    _transfer(address(this), _receiver, _tokens);
        }
		_sTotal++;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // prevents transfer of blocked wallets
        require(!_isLockedWallet[from], "Locked addresses cannot call this function");
        // lock sale if pre sale is enabled
        if (from == pancakePair || to == pancakePair) {
            require(!isPreSaleEnabled, "It is not possible to exchange tokens during the pre sale");
        }
        // exclude from max
        if (!_isExcludedFromMax[from] && !_isExcludedFromMax[to]) {
            // set _maxTxAmount to buy, sell or other action
            if (from == pancakePair) {
                _maxTxAmount = _tokensInLP().mul(buyMaxTxAmount).div(10**2);
            } else if (to == pancakePair) {
                _maxTxAmount = _tokensPerBnbInLP(sellMaxTxAmount);
            } else {
                _maxTxAmount = balanceOf(from).mul(otherMaxTxAmount).div(10**2);
            }
            require(_maxTxAmount > 0, "maxTxAmount must be greater than zero.");
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
                _rewardFee   = buyRewardFee;
                _burnFee     = buyBurnFee;
                _donationFee = buyDonationFee;
            } else if (to == pancakePair) { // Sell
                _rewardFee   = sellRewardFee;
                _burnFee     = sellBurnFee;
                _donationFee = sellDonationFee;
            } else { // other
                _rewardFee   = otherRewardFee;
                _burnFee     = otherBurnFee;
                _donationFee = otherDonationFee;
            }
        }
        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

	function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotalSupply, "Amount must be less than total reflections");
        return rAmount.div(_getRate());
    }

    // this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) _removeAllFee();
        (rValues memory _rv, tValues memory _tv) = _getValues(amount);
        _rBalances[sender]    = _rBalances[sender].sub(_rv.rAmount);
        _rBalances[recipient] = _rBalances[recipient].add(_rv.rTransferAmount);
        _takeBurn(_tv.tBurnFee);
        _reflectFee(_rv.rRewardFee, _tv.tRewardFee);
        emit Transfer(sender, recipient, _tv.tTransferAmount);
		_transferDonation(sender, _rv.rDonationFee, _tv.tDonationFee);
        if (!takeFee) _restoreAllFee();
    }

	function _removeAllFee() private {
        if (_rewardFee == 0 && _burnFee == 0 && _donationFee == 0) return;
        _previousRewardFee   = _rewardFee;
        _previousBurnFee     = _burnFee;
        _previousDonationFee = _donationFee;
        _rewardFee   = 0;
        _burnFee     = 0;
        _donationFee = 0;
    }

    function _restoreAllFee() private {
        _rewardFee   = _previousRewardFee;
        _burnFee     = _previousBurnFee;
        _donationFee = _previousDonationFee;
    }

	function _getValues(uint256 tAmount) private view returns (rValues memory, tValues memory) {
        tValues memory _tv = _getTValues(tAmount);
        rValues memory _rv = _getRValues(tAmount, _tv.tRewardFee, _tv.tBurnFee, _tv.tDonationFee, _getRate());
        return (_rv, _tv);
    }

    function _getTValues(uint256 tAmount) private view returns (tValues memory) {
        tValues memory _tv;
        _tv.tRewardFee      = _calculateRewardFee(tAmount);
        _tv.tBurnFee        = _calculateBurnFee(tAmount);
        _tv.tDonationFee    = _calculateDonationFee(tAmount);
        _tv.tTransferAmount = tAmount.sub(_tv.tRewardFee).sub(_tv.tBurnFee).sub(_tv.tDonationFee);
        return _tv;
    }

    function _getRValues(uint256 tAmount, uint256 tRewardFee, uint256 tBurnFee, uint256 tDonationFee, uint256 currentRate) private pure returns (rValues memory) {
        rValues memory _rv;
        _rv.rAmount         = tAmount.mul(currentRate);
        _rv.rRewardFee      = tRewardFee.mul(currentRate);
        _rv.rBurnFee        = tBurnFee.mul(currentRate);
        _rv.rDonationFee    = tDonationFee.mul(currentRate);
        _rv.rTransferAmount = _rv.rAmount.sub(_rv.rRewardFee).sub(_rv.rBurnFee).sub(_rv.rDonationFee);
        return _rv;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _tTotalSupply;
        if (rSupply < _rTotalSupply.div(_tTotalSupply)) return (_rTotalSupply, _tTotalSupply);
        return (rSupply, tSupply);
    }

    function _calculateRewardFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_rewardFee).div(10**2); }

    function _calculateBurnFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_burnFee).div(10**2); }

    function _calculateDonationFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_donationFee).div(10**2); }

    function _takeBurn(uint256 tBurnFee) private {
        uint256 rBurnFee         = tBurnFee.mul(_getRate());
        _rBalances[_burnAddress] = _rBalances[_burnAddress].add(rBurnFee);
		_tFeeTotal               = _tFeeTotal.add(tBurnFee);
    }

    function _reflectFee(uint256 rRewardFee, uint256 tRewardFee) private {
        _rTotalSupply = _rTotalSupply.sub(rRewardFee);
        _tFeeTotal    = _tFeeTotal.add(tRewardFee);
    }

    function _transferDonation(address sender, uint256 rDonationFee, uint256 tDonationFee) private {
        if (_donationFee > 0) {
            _rBalances[donationWallet] = _rBalances[donationWallet].add(rDonationFee);
			emit Transfer(sender, donationWallet, tDonationFee);
			_tDonationTokensTotal = _tDonationTokensTotal.add(tDonationFee); 
        }
		_tFeeTotal = _tFeeTotal.add(tDonationFee);
    }

	function _getBnbAndTokens(address payable _receiver) private {
		// Receiving BNBs gives pre-sales
		if (address(this).balance > 0) _receiver.transfer(address(this).balance);
		// Remove tokens left over from the pre-sales contract
		if (balanceOf(address(this)) > 0) _transfer(address(this), _receiver, balanceOf(address(this)));
    }

    function _tokensInLP() private view returns (uint256) {
        IPancakePair tokenLP = IPancakePair(pancakePair);
        uint256 tokensInLP   = 0;
        if (tokenLP.totalSupply() > 0) {
            (uint112 _reserve0, 
             uint112 _reserve1, 
             uint32 _blockTimestampLast) = tokenLP.getReserves();
            _blockTimestampLast = 0; // to silence compiler warnings
            if (tokenLP.token0() == address(this)) {
                tokensInLP = _reserve0;
            } else if (tokenLP.token1() == address(this)) {
                tokensInLP = _reserve1;
            }
        }
		return tokensInLP;
    }

    function _tokensPerBnbInLP(uint256 bnbLpPercent) private view returns (uint256) {
        IPancakePair tokenLP     = IPancakePair(pancakePair);
        uint256 tokensPerBnbInLP = 0;
        if (tokenLP.totalSupply() > 0) {
            uint256 bnbAmount;
            uint256 tokenAmount;
            uint256 bnbPercent;
            (uint112 _reserve0, 
             uint112 _reserve1, 
             uint32 _blockTimestampLast) = tokenLP.getReserves();
            _blockTimestampLast = 0; // to silence compiler warnings
            if (tokenLP.token0() == pancakeRouter.WETH()) {
                bnbAmount        = _reserve0;
                tokenAmount      = _reserve1;
                bnbPercent       = bnbAmount.mul(bnbLpPercent).div(10**2);
                tokensPerBnbInLP = bnbPercent.mul(tokenAmount).div(bnbAmount);
            } else if (tokenLP.token1() == pancakeRouter.WETH()) {
                bnbAmount        = _reserve1;
                tokenAmount      = _reserve0;
                bnbPercent       = bnbAmount.mul(bnbLpPercent).div(10**2);
                tokensPerBnbInLP = bnbPercent.mul(tokenAmount).div(bnbAmount);
            }
        }
		return tokensPerBnbInLP;
    }

    event Received(address from, address to, uint256 amount);
    event LockedWallet(address wallet, bool locked);
}
/**
 * End contract
 * 
 * Developed by @tadryanom
 */