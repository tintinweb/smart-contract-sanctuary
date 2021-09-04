/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;




/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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



// pragma solidity >=0.6.2;

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


interface RezerveExchange {
     function exchangeReserve ( uint256 _amount ) external;
     function flush() external;
    
}





interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable( msg.sender );
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require( block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}



contract Rezerve is Context, IERC20, Ownable {
	using Address for address;

	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => uint256) private balances;
	mapping (address => bool) private _isExcludedFromFee;

	uint256 private _totalSupply = 21000000 * 10**9;
	uint256 private _tFeeTotal;

	string private constant _name = "Rezerve";
	string private constant _symbol = "RZRV";
	uint8 private constant _decimals = 9;

	uint256 public _taxFeeOnSale = 0;
	uint256 private _previousSellFee = _taxFeeOnSale;

	uint256 public _taxFeeOnBuy = 10;
	uint256 private _previousBuyFee = _taxFeeOnBuy;

    uint256 public _burnFee = 2;
	uint256 private _previousBurnFee = _burnFee;
	
	uint256 public stakingSlice = 20;


	bool public saleTax = true;

	mapping (address => uint256) public lastTrade;
	mapping (address => uint256) public lastBlock;
	mapping (address => bool)    public blacklist;
	mapping (address => bool)    public whitelist;
	mapping (address => bool)    public rezerveEcosystem;
	address public reserveStaking;
	address payable public reserveVault;
	address public reserveExchange;
	address public ReserveStakingReceiver;
	address public DAI;

	IUniswapV2Router02 public immutable uniswapV2Router;
	address public uniswapV2RouterAddress;
	address public immutable uniswapV2Pair;

	uint8 public action;
	bool public daiShield;
	bool public AutoSwap = false;

	uint8 public lpPullPercentage = 70;
	bool public pauseContract = true;
	bool public stakingTax = true;

	address public burnAddress = 0x000000000000000000000000000000000000dEaD;  

	bool inSwapAndLiquify;
	bool public swapAndLiquifyEnabled = true;

	uint256 public _maxTxAmount = 21000000  * 10**9;
	uint256 public numTokensSellToAddToLiquidity = 21000 * 10**9;

	event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
	event SwapAndLiquifyEnabledUpdated(bool enabled);
	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiqudity
	);

	// ========== Modifiers ========== //
	modifier lockTheSwap {
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}

	constructor () {
		//DAI = 0x9A702Da2aCeA529dE15f75b69d69e0E94bEFB73B;
		// DAI = 0x6980FF5a3BF5E429F520746EFA697525e8EaFB5C; // @audit - make sure this address is correct
		//uniswapV2RouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
                balances[msg.sender] = _totalSupply;
		DAI = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // testnet DAI
		uniswapV2RouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // @audit - make sure this address is correct
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
		 // Create a uniswap pair for this new token
		address pairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
			.createPair(address(this), DAI );
		uniswapV2Pair = pairAddress;
		// UNCOMMENT THESE FOR ETHEREUM MAINNET
		//DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

		// set the rest of the contract variables
		uniswapV2Router = _uniswapV2Router;

		addRezerveEcosystemAddress(owner());
		addRezerveEcosystemAddress(address(this));

		addToWhitelist(pairAddress);

		//exclude owner and this contract from fee
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[0x397c2dBe7af135eA95561acdd9E558E630410a84] = true; // @audit - make sure this address is correct
		daiShield = true;
		emit Transfer(address(0), _msgSender(), _totalSupply);
	}

	// ========== View Functions ========== //

	function thresholdMet () public view returns (bool) {
		return reserveBalance() > numTokensSellToAddToLiquidity ;
	}
	
	function reserveBalance () public view returns (uint256) {
		return balanceOf( address(this) );
	}

	function name() public pure returns (string memory) {
		return _name;
	}

	function symbol() public pure returns (string memory) {
		return _symbol;
	}

	function decimals() public pure returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view override returns (uint256) {
		return balances[account];
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function totalFees() public view returns (uint256) {
		return _tFeeTotal;
	}

	function getLPBalance() public view returns(uint256){
		IERC20 _lp = IERC20 ( uniswapV2Pair);
		return _lp.balanceOf(address(this));
	}

	function isExcludedFromFee(address account) public view returns(bool) {
		return _isExcludedFromFee[account];
	}

	function checkDaiOwnership( address _address ) public view returns(bool){
		IERC20 _dai = IERC20(DAI);
		uint256 _daibalance = _dai.balanceOf(_address );
		return ( _daibalance > 0 );
	}

	// ========== Mutative / Owner Functions ========== //

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount );
		_transfer(sender, recipient, amount);
		return true;
	}

	//to receive ETH from uniswapV2Router when swaping
	receive() external payable {}

	function setReserveExchange( address _address ) public onlyOwner {
		require(_address != address(0), "reserveExchange is zero address");
		reserveExchange = _address;
		excludeFromFee( _address );
		addRezerveEcosystemAddress(_address);
	}

	function contractPauser() public onlyOwner {
		pauseContract = !pauseContract;
		AutoSwap = !AutoSwap;
		_approve(address(this), reserveExchange, ~uint256(0));
		_approve(address(this), uniswapV2Pair ,  ~uint256(0));
		_approve(address(this), uniswapV2RouterAddress, ~uint256(0));
		 
		IERC20 _dai = IERC20 ( DAI );
		_dai.approve( uniswapV2Pair, ~uint256(0) );
		_dai.approve( uniswapV2RouterAddress ,  ~uint256(0) );
		_dai.approve( reserveExchange ,  ~uint256(0) );
	}

	function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}

	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}

	function setSellFeePercent(uint256 sellFee) external onlyOwner() {
		require ( sellFee < 30 , "Tax too high" );
		_taxFeeOnSale = sellFee;
	}

	function setBuyFeePercent(uint256 buyFee) external onlyOwner() {
		require ( buyFee < 11 , "Tax too high" );
		_taxFeeOnBuy = buyFee;
	}
	
	function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
		require ( burnFee < 11 , "Burn too high" );
		_burnFee = burnFee;
	}

	function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
		_maxTxAmount = (_totalSupply * maxTxPercent) / 10**6;
	}

	function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
		swapAndLiquifyEnabled = _enabled;
		emit SwapAndLiquifyEnabledUpdated(_enabled);
	}

	function setReserveStakingReceiver(address _address) public onlyOwner {
		require(_address != address(0), "ReserveStakingReceiver is zero address");
		ReserveStakingReceiver = _address;
		excludeFromFee( _address );
		addRezerveEcosystemAddress(_address);
	}
	
	function setReserveStaking ( address _address ) public onlyOwner {
		require(_address != address(0), "ReserveStaking is zero address");
		reserveStaking = _address;
		excludeFromFee( _address );
		addRezerveEcosystemAddress(_address);
	}

	function setMinimumNumber (uint256 _min) public onlyOwner {
		numTokensSellToAddToLiquidity = _min * 10** 9;
	}

	function daiShieldToggle () public onlyOwner {
		daiShield = !daiShield;
	}
	
	function AutoSwapToggle () public onlyOwner {
		AutoSwap = !AutoSwap;
	}

	function addToBlacklist(address account) public onlyOwner {
		whitelist[account] = false;
		blacklist[account] = true;
	}

	function removeFromBlacklist(address account) public onlyOwner {
		blacklist[account] = false;
	}
	
	// To be used for contracts that should never be blacklisted, but aren't part of the Rezerve ecosystem, such as the Uniswap pair
	function addToWhitelist(address account) public onlyOwner {
		blacklist[account] = false;
		whitelist[account] = true;
	}

	function removeFromWhitelist(address account) public onlyOwner {
		whitelist[account] = false;
	}

	// To be used if new contracts are added to the Rezerve ecosystem
	function addRezerveEcosystemAddress(address account) public onlyOwner {
		rezerveEcosystem[account] = true;
		addToWhitelist(account);
	}

	function removeRezerveEcosystemAddress(address account) public onlyOwner {
		rezerveEcosystem[account] = false;
	}

	function toggleStakingTax() public onlyOwner {
		stakingTax = !stakingTax;
	}

	function withdrawLPTokens () public onlyOwner {
		IERC20 _uniswapV2Pair = IERC20 ( uniswapV2Pair );
		uint256 _lpbalance = _uniswapV2Pair.balanceOf(address(this));
		_uniswapV2Pair.transfer( msg.sender, _lpbalance );
	}
	
	function setLPPullPercentage ( uint8 _perc ) public onlyOwner {
		require ( _perc >9 && _perc <71);
		lpPullPercentage = _perc;
	}

	function addToLP(uint256 tokenAmount, uint256 daiAmount) public onlyOwner {
		// approve token transfer to cover all possible scenarios
		_transfer ( msg.sender, address(this) , tokenAmount );
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		
		IERC20 _dai = IERC20 ( DAI );
		_dai.approve(  address(uniswapV2Router), daiAmount);
		_dai.transferFrom ( msg.sender, address(this) , daiAmount );
		
		// add the liquidity
		uniswapV2Router.addLiquidity(
			address(this),
			DAI,
			tokenAmount,
			daiAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			address(this),
			block.timestamp
		);
		contractPauser();
	}

	function removeLP () public onlyOwner {
		saleTax = false;  
		IERC20 _uniswapV2Pair = IERC20 ( uniswapV2Pair );
		uint256 _lpbalance = _uniswapV2Pair.balanceOf(address(this));
		uint256 _perc = (_lpbalance * lpPullPercentage ) / 100;
		
		_uniswapV2Pair.approve( address(uniswapV2Router), _perc );
		uniswapV2Router.removeLiquidity(
			address(this),
			DAI,
			_perc,
			0,
			0,
			reserveExchange,
			block.timestamp + 3 minutes
		); 
		RezerveExchange _reserveexchange = RezerveExchange ( reserveExchange );
		_reserveexchange.flush();
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	// ========== Private / Internal Functions ========== //

	function _transfer(
		address from,
		address to,
		uint256 amount
	) private {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		require(!blacklist[from]);
		if (pauseContract) require (from == address(this) || from == owner());

		if (!rezerveEcosystem[from]) {
			if(to == uniswapV2Pair && daiShield) require ( !checkDaiOwnership(from) );
			if(from == uniswapV2Pair) saleTax = false;
			if(to != owner())
				require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

			if (!whitelist[from]) {
				if (lastBlock[from] == block.number) blacklist[from] = true;
				if (lastTrade[from] + 20 seconds > block.timestamp && !blacklist[from]) revert("Slowdown");
				lastBlock[from] = block.number;
				lastTrade[from] = block.timestamp;
			}
		}

		action = 0;

		if(from == uniswapV2Pair) action = 1;
		if(to == uniswapV2Pair) action = 2;
		// is the token balance of this contract address over the min number of
		// tokens that we need to initiate a swap + liquidity lock?
		// also, don't get caught in a circular liquidity event.
		// also, don't swap & liquify if sender is uniswap pair.
		
		uint256 contractTokenBalance = balanceOf(address(this));
		contractTokenBalance = Math.min(contractTokenBalance, numTokensSellToAddToLiquidity);
		bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
		if (
			overMinTokenBalance &&
			!inSwapAndLiquify &&
			from != uniswapV2Pair &&
			swapAndLiquifyEnabled &&
			AutoSwap
		) {
			swapIt(contractTokenBalance);
		}
		
		//indicates if fee should be deducted from transfer
		bool takeFee = true;
		
		//if any account belongs to _isExcludedFromFee account then remove the fee
		if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}
		
		//transfer amount, it will take tax, burn, liquidity fee
		if (!blacklist[from])
			_tokenTransfer(from, to, amount, takeFee);
		else
			_tokenTransfer(from, to, 1, false);
	}

	function swapIt(uint256 contractTokenBalance) internal lockTheSwap {
		uint256 _exchangeshare = contractTokenBalance;
		if (stakingTax) {
			_exchangeshare = ( _exchangeshare * 4 ) / 5;
			uint256 _stakingshare = contractTokenBalance - _exchangeshare;
			_tokenTransfer(address(this), ReserveStakingReceiver, _stakingshare, false);
		}
		swapTokensForDai(_exchangeshare);
	}

	function swapTokensForDai(uint256 tokenAmount) internal {
		// generate the uniswap pair path of token -> DAI
		address[] memory path = new address[](2);

		path[0] = address(this);
		path[1] = DAI;
		uniswapV2Router.swapExactTokensForTokens(
			tokenAmount,
			0, // accept any amount of DAI
			path,
			reserveExchange,
			block.timestamp + 3 minutes
		);
	}
	
	function setStakingSlice ( uint256 _slice ) public onlyOwner {
	    stakingSlice = _slice;
	}
	
	//this method is responsible for taking all fee, if takeFee is true
	function _tokenTransfer(
		address sender,
		address recipient,
		uint256 amount,
		bool takeFee
	) private {
		if(!takeFee)
			removeAllFee();

		( uint256 transferAmount, uint256 sellFee, uint256 buyFee, uint256 burnFee ) = _getTxValues(amount);
		_tFeeTotal = _tFeeTotal + sellFee + buyFee + burnFee;
		uint256 stakingFee;
		if (stakingTax) {
		        uint256 stakingFeeB = (buyFee * stakingSlice )/100; 
		        uint256 stakingFeeS = (sellFee * stakingSlice )/100;
		        buyFee = buyFee - stakingFeeB; 
		        sellFee = sellFee - stakingFeeS;
		        stakingFee = stakingFeeB + stakingFeeS;
		
		}
		balances[sender] = balances[sender] - amount;
		balances[recipient] = balances[recipient] + transferAmount;
		balances[address(this)] = balances[address(this)] + sellFee + buyFee;
		balances[burnAddress] = balances[burnAddress] + burnFee;
		balances[ReserveStakingReceiver] = balances[ReserveStakingReceiver] + stakingFee;

		emit Transfer(sender, recipient, transferAmount);
		
		if(!takeFee)
			restoreAllFee();
	}

	function _getTxValues(uint256 tAmount) private returns (uint256, uint256, uint256, uint256) {
		uint256 sellFee = calculateSellFee(tAmount);
		uint256 buyFee = calculateBuyFee(tAmount);
		uint256 burnFee = calculateBurnFee(tAmount);
		uint256 tTransferAmount = tAmount - sellFee - buyFee - burnFee;
		return (tTransferAmount, sellFee, buyFee, burnFee);
	}

	function calculateSellFee(uint256 _amount) private returns (uint256) {
		if (!saleTax) {
			saleTax = true;
			return 0;
		}
		return( _amount * _taxFeeOnSale) / 10**2;
	}

	function calculateBuyFee(uint256 _amount) private view returns (uint256) {
		if(action == 1)
			return (_amount * _taxFeeOnBuy) / 10**2;

		return 0;
	}
	
	function calculateBurnFee(uint256 _amount) private view returns (uint256) {
		if ( _burnFee > 0 )
		return (_amount * _burnFee) / 10**2;
        return 0;
		
	}

	function removeAllFee() private {
		if(_taxFeeOnSale == 0 && _taxFeeOnBuy == 0  && _burnFee == 0 ) return;
		
		_previousSellFee = _taxFeeOnSale;
		_previousBuyFee = _taxFeeOnBuy;
		_previousBurnFee = _burnFee;
		
		_taxFeeOnSale = 0;
		_taxFeeOnBuy = 0;
		_burnFee = 0;
	}

	function restoreAllFee() private {
		_taxFeeOnSale = _previousSellFee;
		_taxFeeOnBuy = _previousBuyFee;
		_burnFee = _previousBurnFee;
	}
}