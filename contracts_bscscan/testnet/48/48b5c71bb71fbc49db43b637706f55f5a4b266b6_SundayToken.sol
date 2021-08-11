/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: GPL-3.0 or later

/**
 * Submitted for verification at BscScan.com on 2021-05-28
 * /

/**

    @@@@@@@@@            @@@@@@@@@@
    @@@@@@@@@@   @      @@@@@@@@@@@ @
    @@@@@@@@@@@@  @    @@@@@@@@@@@@ @
    @@@@@@@@@@@@@@   @@@@@@@@@@@@@@ @
    @@@@@@@  @@@@@@@@@@@@@  @@@@@@@ @
    @@@@@@@    @@@@@@@@@    @@@@@@@ @         @@@@@@@          @@@@@  @@@@@@@        @@@@@@@@@@@@               &&&&&           @@@@@@    @@@@@
    @@@@@@@ @    @@@@@      @@@@@@@ @       @@@@@@@@@@@   @    @@@@@@@@@@@@@@@  @    @@@@@@@@@@@@@@  @         &&&&&&&  @       @@@@@    @@@@@  @
    @@@@@@@ @     @@@       @@@@@@@ @     @@@@@     @@@@@  @   @@@@@@@@   @@@@@  @   @@@@@@   @@@@@@  @       &&&&&&&&&  @      @@@@@   @@@@@  @
    @@@@@@@ @               @@@@@@@ @    @@@@        @@@@@  @  @@@@@@    @@@@@@  @   @@@@@@    @@@@@@  @     &&&&&&&&&&&  @      @@@@@@@@@@@@  @
    @@@@@@@ @               @@@@@@@ @    @@@@@       @@@@@  @  @@@@@  @  @@@@@  @    @@@@@@    @@@@@@  @    @@@@@  @@@@@@  @      @@@@@@@@@@@  @
    @@@@@@@ @               @@@@@@@ @     @@@@      @@@@@  @   @@@@@  @  @@@@@  @    @@@@@@    @@@@@@  @   @@@@@    @@@@@@  @           @@@@@@  @
    @@@@@@@ @               @@@@@@@ @      @@@@@@@@@@@@@  @    @@@@@  @  @@@@@  @    @@@@@@   @@@@@@   @  @@@@@@@@@@@@@@@@@  @          @@@@@@  @
    @@@@@@@ @               @@@@@@@ @        @@@@@@@@    @     @@@@@  @  @@@@@@  @   @@@@@@@@@@@@@@   @  @@@@@@      @@@@@@  @         @@@@@@  @
            @                       @                   @             @         @                    @          @           @         @@@@@@  @
     @@@@@@@@                @@@@@@@@         @@@@@@@@@         @@@@@@   @@@@@@@       @@@@@@@@@@@@@@      @@@@@       @@@@@         @@@@@@  @
                                                                                                                                    @@@@@@  @
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @
                                                                                                                                         @
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    # MONDAY

    Great features:

    2% fee auto add to the liquidity pool to lock forever when selling
    3% fee auto distribute to all holders
    5% fee auto swaped with BNB and move to Monday Investment fund

    When sell token:
    5% fee auto burn

    When buy token:
    5% fee auto swaped with BNB and move to donation wallet.

    Official site: https://monday.land

 */

pragma solidity ^0.8.4;

abstract contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    /**
     * @dev Returns message sender
     */
    function _msgSender() internal view virtual returns (address) {
        return payable(msg.sender);
    }

    /**
     * @dev Returns message content
     */
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {

    /**
     * @dev Emitted when `value` tokens are moved
     * from one account (`from`) to another account (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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

abstract contract Ownable is Context {
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

    function getUnlockTime() public view returns (uint256) {
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
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
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

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
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

contract SundayToken is Ownable, IBEP20 {
    using Address for address;

    mapping (address => uint256) private _reflectOwned;
    mapping (address => uint256) private _tokenOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;

    address[] private _excluded;

    // Address of Token Owner
    address private _ownerAddress = payable(0xD5fA8Fe5f8068b8657c3B9Ee7D10b493bC878129);

    // Address of Monday Investment Fund
    address private _mondayInvestmentFund = payable(0x97a902364255429B430cb25E71d17df3CfBc90bf);

    // Address of marketing and dev
    address private _marketingDev = payable(0xD5fA8Fe5f8068b8657c3B9Ee7D10b493bC878129);

    // Address of Monday AR Game
    address private _mondayArGame = payable(0x85D117cD3C10a44f26896ebbB84C4181D051fD08);

    // Address of Service for sale
    address private _service = payable(0x5cCCb537f3CAf12ca138614a3f5756124cA2094f);

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tokenTotal = 100000000000000000;
    uint256 private _reflectTotal = (MAX - (MAX % _tokenTotal));
    uint256 private _tokenFeeTotal;

    string public _name = "SundayToken";
    string public _symbol = "SDY2";
    uint8 private _decimals = 9;

    uint256 private _distributeFee = 3;
    uint256 private _fundOrBurnFee = 5;
    uint256 private _devFee = 5;
    uint256 private _liquidityFee = 2;

    uint256 private _previousDistributeFee = _distributeFee;
    uint256 private _previousFundOrBurnFee = _fundOrBurnFee;
    uint256 private _previousDevFee = _devFee;
    uint256 private _previousLiquidityFee = _liquidityFee;

    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 private _maxTokenHold = 1 * 10**15 * 10**10;
    uint256 private _maxTxAmount = 5 * 10**11 * 10**10;
    uint256 private numTokensSellToAddToLiquidity = 5 * 10**10 * 10**10;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapAndDonate(uint256 swapTokenBalance, address recipient);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        _reflectOwned[_ownerAddress] = _reflectTotal;

        // PancakeSwap Router address:
        // (BSC testnet) 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        // (BSC mainnet) V2 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

        // Create a pancakeswap pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        address _pancakeFactory = payable(0x3328C0fE37E8ACa9763286630A9C33c23F0fAd1A);

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_pancakeFactory] = true;
        _isExcludedFromFee[_ownerAddress] = true;
        _isExcludedFromFee[_mondayInvestmentFund] = true;
        _isExcludedFromFee[_marketingDev] = true;
        _isExcludedFromFee[_mondayArGame] = true;
        _isExcludedFromFee[_service] = true;

        emit Transfer(address(0), _ownerAddress, _tokenTotal);
    }

    /**
     * @dev Returns the token name.
     */
    function name() external override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return _ownerAddress;
    }

    function totalSupply() external view override returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) {
            return _tokenOwned[account];
        }

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
        require(_allowances[sender][_msgSender()] - amount < 0, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(_allowances[_msgSender()][spender] - subtractedValue < 0, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tokenFeeTotal;
    }

    function deliver(uint256 transferAmount) external {
        address sender = _msgSender();

        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        (uint256 rAmount,,,,,,,) = _getValues(transferAmount);

        _reflectOwned[sender] = _reflectOwned[sender] - rAmount;
        _reflectTotal = _reflectTotal - rAmount;

        _tokenFeeTotal = _tokenFeeTotal + transferAmount;
    }

    function reflectionFromToken(uint256 transferAmount, bool deductTransferFee) external view returns(uint256) {
        require(transferAmount <= _tokenTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 reflectAmount,,,,,,,) = _getValues(transferAmount);
            return reflectAmount;
        } else {
            (,uint256 reflectTransferAmount,,,,,,) = _getValues(transferAmount);
            return reflectTransferAmount;
        }
    }

    function tokenFromReflection(uint256 reflectAmount) public view returns(uint256) {
        require(reflectAmount <= _reflectTotal, "Amount must be less than total reflections");

        uint256 currentRate =  _getRate();

        return reflectAmount / currentRate;
    }

    function resetMaxTokenPerWallet() public onlyOwner() {
        _maxTokenHold = 5 * 10**11 * 10**10;
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F, 'We can not exclude Pancakeswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_reflectOwned[account] > 0) {
            _tokenOwned[account] = tokenFromReflection(_reflectOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function removeAllFee() private {
        if(_distributeFee == 0 && _fundOrBurnFee == 0 && _devFee == 0 && _liquidityFee == 0) return;

        _previousDistributeFee = _distributeFee;
        _previousFundOrBurnFee = _fundOrBurnFee;
        _previousDevFee = _devFee;
        _previousLiquidityFee = _liquidityFee;

        _distributeFee = 0;
        _fundOrBurnFee = 0;
        _devFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _distributeFee = _previousDistributeFee;
        _fundOrBurnFee = _previousFundOrBurnFee;
        _devFee = _previousDevFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setDistributeFeePercent(uint256 distributeFee) external onlyOwner() {
        _distributeFee = distributeFee;
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner() {
        _devFee = devFee;
    }

    function setFundOrBurnFeePercent(uint256 fundOrBurnFee) external onlyOwner() {
        _fundOrBurnFee = fundOrBurnFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

     //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    /// This will allow to rescue BNB sent by mistake directly to the contract
    function rescueBNBFromContract() external onlyOwner {
        address _owner = payable(_msgSender());
        payable(_owner).transfer(address(this).balance);
    }

    function _getValues(
        uint256 transferAmount
    )
        private
        view
        returns
    (
        uint256 reflectAmount,
        uint256 reflectTransferAmount,
        uint256 reflectFee,
        uint256 tokenTransferAmount,
        uint256 feeDistribute,
        uint256 feeFundOrBurn,
        uint256 feeDev,
        uint256 feeLiquidity
    ) {

        (
            tokenTransferAmount,
            feeDistribute,
            feeFundOrBurn,
            feeDev,
            feeLiquidity
        ) = _getTokenRelatedValues(transferAmount);

        (
            reflectAmount,
            reflectTransferAmount,
            reflectFee
        ) = _getReflectRelatedValues(
            transferAmount,
            feeDistribute,
            feeFundOrBurn + feeDev + feeLiquidity,
            _getRate()
        );
    }

    function _getTokenRelatedValues(
        uint256 transferAmount
    )
        private
        view
        returns
    (uint256, uint256, uint256, uint256, uint256) {

        uint256 feeDistribute = calculateDistributeFee(transferAmount);
        uint256 feeFundOrBurn = calculateFundOrBurnFee(transferAmount);
        uint256 feeDev = calculateDevFee(transferAmount);
        uint256 feeLiquidity = calculateLiquidityFee(transferAmount);

        uint256 tokenTransferAmount = transferAmount - feeDistribute - feeFundOrBurn - feeDev - feeLiquidity;

        return (
            tokenTransferAmount,
            feeDistribute,
            feeFundOrBurn,
            feeDev,
            feeLiquidity
        );
    }

    function _getReflectRelatedValues(
        uint256 transferAmount,
        uint256 feeDistribute,
        uint256 feeTotal,
        uint256 currentRate
    )
        private
        pure
        returns
    (uint256, uint256, uint256) {

        uint256 reflectAmount = transferAmount * currentRate;

        uint256 reflectFee = feeDistribute * currentRate;
        uint256 reflectFeeTotal = feeTotal * currentRate;

        uint256 reflectTransferAmount = reflectAmount - reflectFee - reflectFeeTotal;

        return (
            reflectAmount,
            reflectTransferAmount,
            reflectFee
        );
    }

    function _getRate() private view returns(uint256) {
        (uint256 reflectSupply, uint256 tokenSupply) = _getCurrentSupply();
        return reflectSupply / tokenSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 reflectSupply = _reflectTotal;
        uint256 tokenSupply = _tokenTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectOwned[_excluded[i]] > reflectSupply || _tokenOwned[_excluded[i]] > tokenSupply) return (_reflectTotal, _tokenTotal);
            reflectSupply = reflectSupply - _reflectOwned[_excluded[i]];
            tokenSupply = tokenSupply - _tokenOwned[_excluded[i]];
        }

        if (reflectSupply < _reflectTotal / _tokenTotal) {
            return (_reflectTotal, _tokenTotal);
        }

        return (reflectSupply, tokenSupply);
    }

    function _takeLiquidity(uint256 feeLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 reflectLiquidity = feeLiquidity * currentRate;
        _reflectOwned[address(this)] = _reflectOwned[address(this)] + reflectLiquidity;
        if(_isExcluded[address(this)])
            _tokenOwned[address(this)] = _tokenOwned[address(this)] + feeLiquidity;
    }

    function calculateDistributeFee(uint256 _amount) private view returns (uint256) {
        return _amount * _distributeFee / 10**2;
    }

    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount * _devFee / 10**2;
    }

    function calculateFundOrBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount * _fundOrBurnFee / 10**2;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * _liquidityFee / 10**2;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(_tokenOwned[to] + amount <= _maxTokenHold, "Recipient's wallet will exceed max token hold 500,000,000 MONDAY with your amount");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity

            (,,,,, uint256 feeFundOrBurn, uint256 feeDev,) = _getValues(amount);

            bool isBurn = false;
            if (from.isContract()) {
                isBurn = true;
            }

            swapAndLiquify(contractTokenBalance, feeFundOrBurn, feeDev, isBurn);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance, uint256 donateFund, uint256 donateDev, bool burn) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        uint256 initialBalance = address(this).balance;

        uint256 rating = 0;
        if (burn) {
            rating = (half + donateDev) / half;

            swapTokensForBNB(half + donateDev); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        } else {
            rating = (half + donateDev + donateFund) / half;

            swapTokensForBNB(half + donateDev + donateFund); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        }

        // how much BNB did we earn from swap?
        uint256 newBalance = address(this).balance - initialBalance;
        // how much BNB did we swap into?
        uint256 balanceHalf = newBalance / rating;
        uint256 donateBalance = newBalance - balanceHalf;

        if (burn) {
            TransferBnbToExternalAddress(_marketingDev, donateBalance);
        } else {
            uint256 fundBalance = donateBalance / 2;
            uint256 devBalance = donateBalance - fundBalance;

            TransferBnbToExternalAddress(_mondayInvestmentFund, fundBalance);
            TransferBnbToExternalAddress(_marketingDev, devBalance);
        }

        // add liquidity to uniswap
        addLiquidity(otherHalf, balanceHalf);

        emit SwapAndLiquify(half, newBalance, otherHalf);
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

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 transferAmount) private {
        (
            uint256 reflectAmount,
            uint256 reflectTransferAmount,
            uint256 reflectFee,
            uint256 tokenTransferAmount,
            uint256 feeDistribute,
            uint256 feeFundOrBurn,
            uint256 feeDev,
            uint256 feeLiquidity
        ) = _getValues(transferAmount);

        _reflectOwned[sender] = _reflectOwned[sender] - reflectAmount;
        _reflectOwned[recipient] = _reflectOwned[recipient] + reflectTransferAmount;

        _takeLiquidity(feeLiquidity);

        if (sender.isContract()) {
            _reflectFee(reflectFee, feeDistribute, feeDev, feeFundOrBurn, false);
        } else {
            _reflectFee(reflectFee, feeDistribute, feeDev, feeFundOrBurn, true);
        }

        emit Transfer(sender, recipient, tokenTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 transferAmount) private {
        (
            uint256 reflectAmount,
            uint256 reflectTransferAmount,
            uint256 reflectFee,
            uint256 tokenTransferAmount,
            uint256 feeDistribute,
            uint256 feeFundOrBurn,
            uint256 feeDev,
            uint256 feeLiquidity
        ) = _getValues(transferAmount);

        _reflectOwned[sender] = _reflectOwned[sender] - reflectAmount;
        _tokenOwned[recipient] = _tokenOwned[recipient] + tokenTransferAmount;
        _reflectOwned[recipient] = _reflectOwned[recipient] + reflectTransferAmount;

        _takeLiquidity(feeLiquidity);

        if (sender.isContract()) {
            _reflectFee(reflectFee, feeDistribute, feeDev, feeFundOrBurn, false);
        } else {
            _reflectFee(reflectFee, feeDistribute, feeDev, feeFundOrBurn, true);
        }

        emit Transfer(sender, recipient, tokenTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 transferAmount) private {
        (
            uint256 reflectAmount,
            uint256 reflectTransferAmount,
            uint256 reflectFee,
            uint256 tokenTransferAmount,
            uint256 feeDistribute,
            uint256 feeFundOrBurn,
            uint256 feeDev,
            uint256 feeLiquidity
        ) = _getValues(transferAmount);

        _tokenOwned[sender] = _tokenOwned[sender] - transferAmount;
        _reflectOwned[sender] = _reflectOwned[sender] - reflectAmount;
        _reflectOwned[recipient] = _reflectOwned[recipient] + reflectTransferAmount;

        _takeLiquidity(feeLiquidity);

        if (sender.isContract()) {
            _reflectFee(reflectFee, feeDistribute, feeDev, feeFundOrBurn, false);
        } else {
            _reflectFee(reflectFee, feeDistribute, feeDev, feeFundOrBurn, true);
        }

        emit Transfer(sender, recipient, tokenTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 transferAmount) private {
        (
            uint256 reflectAmount,
            uint256 reflectTransferAmount,
            uint256 reflectFee,
            uint256 tokenTransferAmount,
            uint256 feeDistribute,
            uint256 feeFundOrBurn,
            uint256 feeDev,
            uint256 feeLiquidity
        ) = _getValues(transferAmount);

        _tokenOwned[sender] = _tokenOwned[sender] - transferAmount;
        _reflectOwned[sender] = _reflectOwned[sender] - reflectAmount;
        _tokenOwned[recipient] = _tokenOwned[recipient] + tokenTransferAmount;
        _reflectOwned[recipient] = _reflectOwned[recipient] + reflectTransferAmount;

        _takeLiquidity(feeLiquidity);

        if (sender.isContract()) {
            _reflectFee(reflectFee, feeDistribute, feeDev, feeFundOrBurn, false);
        } else {
            _reflectFee(reflectFee, feeDistribute, feeDev, feeFundOrBurn, true);
        }

        emit Transfer(sender, recipient, tokenTransferAmount);
    }

    function TransferBnbToExternalAddress(address recipient, uint256 amount) private {
        payable(recipient).transfer(amount);
    }

    function _reflectFee(uint256 reflectFee, uint256 feeDistribute, uint256 feeDev, uint256 feeFundOrBurn, bool burn) private {
        _reflectTotal = _reflectTotal - reflectFee;
        _tokenFeeTotal = _tokenFeeTotal + feeDistribute + feeDev + feeFundOrBurn;

        if (burn) {
            _tokenTotal = _tokenTotal - feeFundOrBurn;
        }
    }

}