//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

/**
 * Contract: KEYS Token
 * Contract Developed By: DeFi Mark ( MoonMark )
 *
 * Keys is a project aimed to create revolutionary blockchain products built
 * Around the exchange of luxury assets in both the metaverse and physical world
 * Exlusive only to $KEYS Token Holders
 * 
 *  Join us on Discord:
 *  https://discord.gg/keystoken
 * 
 */
contract KEYS is IERC20 {
    
    using SafeMath for uint256;
    using Address for address;

    // token data
    string constant _name = "Keys";
    string constant _symbol = "KEYS";
    uint8 constant _decimals = 9;

    // 1 Billion Starting Supply
    uint256 _totalSupply = 10**9 * 10**_decimals;
    
    // Bot Prevention
    uint256 maxTransfer;
    bool maxTransferCheckEnabled;
    
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Fees
    uint256 public fee = 3; // 3% transfer fee
    
    // fee exemption for staking / utility
    mapping ( address => bool ) public isFeeExempt;

    // Uniswap Router
    IUniswapV2Router02 _router; 
    
    // ETH -> Token
    address[] path;
    
    // Tokens -> ETH
    address[] sellPath;
    
    // owner
    address _owner;
    
    // multisignature wallet
    address _developmentFund;
    
    // Auto Swapper Enabled
    bool swapEnabled;

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Only Owner Function');
        _;
    }

    // initialize some stuff
    constructor () {
        
        // router
        _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        // ETH -> Token
        path = new address[](2);
        path[0] = _router.WETH();
        path[1] = address(this);
        
        // Token -> ETH
        sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = _router.WETH();
        
        // Dev Fund
        _developmentFund = 0xfCacEAa7b4cf845f2cfcE6a3dA680dF1BB05015c;
        
        // Enable Auto Swapper
        swapEnabled = true;
        
        // Anti-Bot Prevention
        maxTransfer = _totalSupply.div(100);
        maxTransferCheckEnabled = true;

        // fee exempt fund + owner + router for LP injection
        isFeeExempt[msg.sender] = true;
        isFeeExempt[_developmentFund] = true;
        isFeeExempt[address(this)] = true;
        
        // allocate tokens to owner
        _balances[msg.sender] = _totalSupply;

        // ownership
        _owner = msg.sender;
        
        // emit allocations
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
  
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, 'Insufficient Allowance');
        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0) && sender != address(0), "Transfer To Zero Address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // check anti-bot
        if (maxTransferCheckEnabled && msg.sender != _owner) {
            require(amount <= maxTransfer, 'Maximum Transfer Threshold Reached');
        }
        
        // subtract full amount from sender
        _balances[sender] = _balances[sender].sub(amount, 'Insufficient Balance');
        
        // fee exempt
        bool takeFee = !( isFeeExempt[sender] || isFeeExempt[recipient] );
        
        // calculate taxed amount
        uint256 taxAmount = takeFee ? amount.mul(fee).div(10**2) : 0;
        
        // amount to give to recipient (amount - tax)
        uint256 receiveAmount = amount.sub(taxAmount);
        
        // give potentially reduced amount to recipient
        _balances[recipient] = _balances[recipient].add(receiveAmount);
        emit Transfer(sender, recipient, receiveAmount);
        
        // allocate to marketing
        if (taxAmount > 0) {
            _balances[_developmentFund] = _balances[_developmentFund].add(taxAmount);
            emit Transfer(sender, _developmentFund, taxAmount);
        }
        return true;
    }
    
    function burnTokens(uint256 numTokens) external {
        _burnTokens(numTokens * 10**_decimals);
    }
    
    function burnAllTokens() external {
        _burnTokens(_balances[msg.sender]);
    }
    
    function burnTokensIncludingDecimals(uint256 numTokens) external {
        _burnTokens(numTokens);
    }
    
    function purchaseTokenForAddress(address receiver) external payable {
        require(msg.value >= 10**4, 'Amount Too Few');
        _purchaseToken(receiver);
    }
    
    function sellTokensForETH(address receiver, uint256 numTokens) external {
        _sellTokensForETH(receiver, numTokens);
    }
    
    function sellTokensForETH(uint256 numTokens) external {
        _sellTokensForETH(msg.sender, numTokens);
    }
    
    function sellTokensForETHWholeTokenAmounts(uint256 numTokens) external {
        _sellTokensForETH(msg.sender, numTokens*10**_decimals);
    }
    

    ///////////////////////////////////
    //////   OWNER FUNCTIONS    ///////
    ///////////////////////////////////
    
    function setUniswapRouterAddress(address router) external onlyOwner {
        _router = IUniswapV2Router02(router);
        emit SetUniswapRouterAddress(router);
    }
    
    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
        emit SetSwapEnabled(enabled);
    }
    
    /** Withdraws Tokens Mistakingly Sent To Contract */
    function withdrawTokens(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, 'Zero Balance');
        IERC20(token).transfer(msg.sender, bal);
    }
    
    /** Sets Maximum Transaction Data */
    function setMaxTransactionData(bool checkEnabled, uint256 transferThreshold) external onlyOwner {
        if (checkEnabled) {
            require(transferThreshold >= _totalSupply.div(1000), 'Threshold Too Few');   
        }
        maxTransferCheckEnabled = checkEnabled;
        maxTransfer = transferThreshold;
        emit MaxTransactionDataSet(checkEnabled, transferThreshold);
    }
    
    /** Updates The Address Of The Development Fund Receiver */
    function updateDevelopmentFundingAddress(address newFund) external onlyOwner {
        _developmentFund = newFund;
        emit UpdatedDevelopmentFundingAddress(newFund);
    }
    
    /** Excludes Contract From Fees */
    function setFeeExemption(address wallet, bool exempt) external onlyOwner {
        require(wallet != address(0));
        isFeeExempt[wallet] = exempt;
        emit SetFeeExemption(wallet, exempt);
    }
    
    /** Sets Transfer Fees */
    function setFee(uint256 newFee) external onlyOwner {
        require(newFee <= 10, 'Fee Too High');
        fee = newFee;
        emit SetFee(newFee);
    }
    
    /** Transfers Ownership To Another User */
    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
        emit TransferOwnership(newOwner);
    }
    
    /** Transfers Ownership To Zero Address */
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit TransferOwnership(address(0));
    }
    
    
    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    
    function _sellTokensForETH(address receiver, uint256 numberTokens) internal {

        // checks
        require(_balances[msg.sender] >= numberTokens, 'Insufficient Balance');
        require(receiver != address(this) && receiver != address(0), 'Insufficient Destination');
        require(swapEnabled, 'Swapping Disabled');
        
        // transfer in tokens
        _balances[msg.sender] = _balances[msg.sender].sub(numberTokens, 'Insufficient Balance');
        
        // divvy up amount
        uint256 tax = isFeeExempt[msg.sender] ? 0 : numberTokens.mul(fee).div(10**2);
        
        // amount to send to recipient
        uint256 sendAmount = numberTokens.sub(tax);
        require(sendAmount > 0, 'Zero Tokens To Send');
        
        // Allocate To Contract
        _balances[address(this)] = _balances[address(this)].add(sendAmount);
        emit Transfer(msg.sender, address(this), sendAmount);
        
        // Allocate Tax
        if (tax > 0) {
            _balances[_developmentFund] = _balances[_developmentFund].add(tax);
            emit Transfer(msg.sender, _developmentFund, tax);
        }
        
        // Approve Of Router To Move Tokens
        _allowances[address(this)][address(_router)] = sendAmount;
        
        // make the swap
        _router.swapExactTokensForETH(
            sendAmount,
            0,
            sellPath,
            receiver,
            block.timestamp + 30
        );
    
    }
    
    function _purchaseToken(address receiver) internal {
        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            receiver,
            block.timestamp + 30
        );
    }
    
    function _burnTokens(uint256 numTokens) internal {
        require(_balances[msg.sender] >= numTokens && numTokens > 0, 'Insufficient Balance');
        // remove from balance and supply
        _balances[msg.sender] = _balances[msg.sender].sub(numTokens, 'Insufficient Balance');
        _totalSupply = _totalSupply.sub(numTokens, 'Insufficient Supply');
        // emit transfer to zero
        emit Transfer(msg.sender, address(0), numTokens);
    }
    
    /** Purchase Tokens For Holder */
    receive() external payable {
        _purchaseToken(msg.sender);
    }
    
    
    ///////////////////////////////////
    //////        EVENTS        ///////
    ///////////////////////////////////
    
    event UpdatedDevelopmentFundingAddress(address newFund);
    event TransferOwnership(address newOwner);
    event SetSwapEnabled(bool enabled);
    event SetFee(uint256 newFee);
    event SetUniswapRouterAddress(address router);
    event SetFeeExemption(address Contract, bool exempt);
    event MaxTransactionDataSet(bool checkEnabled, uint256 transferThreshold);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


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