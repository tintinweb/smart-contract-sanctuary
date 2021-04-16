/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// File: contracts\proxy\fnxProxy.sol

pragma solidity =0.5.16;
/**
 * @title  fnxProxy Contract

 */
contract fnxProxy {
    bytes32 private constant implementPositon = keccak256("org.Finnexus.implementation.storage");
    bytes32 private constant versionPositon = keccak256("org.Finnexus.version.storage");
    bytes32 private constant proxyOwnerPosition  = keccak256("org.Finnexus.Owner.storage");
    event Upgraded(address indexed implementation,uint256 indexed version);
    event DebugEvent(address indexed from,uint256 value1,uint256 value2);
    constructor(address implementation_,uint256 version_) public {
        // Creator of the contract is admin during initialization
        _setProxyOwner(msg.sender);
        _setImplementation(implementation_);
        _setVersion(version_);
        emit Upgraded(implementation_,version_);
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner 
    {
        require(_newOwner != address(0));
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
    function _setVersion(uint256 version_) internal 
    {
        bytes32 position = versionPositon;
        assembly {
            sstore(position, version_)
        }
    }
    function version() public view returns(uint256 version_){
        bytes32 position = versionPositon;
        assembly {
            version_ := sload(position)
        }
    }
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }
    function proxyType() public pure returns (uint256){
        return 2;
    }
    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementPositon;
        assembly {
            impl := sload(position)
        }
    }
    function _setImplementation(address _newImplementation) internal 
    {
        bytes32 position = implementPositon;
        assembly {
            sstore(position, _newImplementation)
        }
    }
    function upgradeTo(address _newImplementation,uint256 version_)public onlyProxyOwner upgradeVersion(version_){
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        _setVersion(version_);
        emit Upgraded(_newImplementation,version_);
        (bool success,) = _newImplementation.delegatecall(abi.encodeWithSignature("update()"));
        require(success);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner(),"proxyOwner: caller is not the proxy owner");
        _;
    }
    modifier upgradeVersion(uint256 version_) {
        require (version_>version(),"upgrade version number must greater than current version");
        _;
    }
    function () payable external {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
        let ptr := mload(0x40)
        calldatacopy(ptr, 0, calldatasize)
        let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
        let size := returndatasize
        returndatacopy(ptr, 0, size)

        switch result
        case 0 { revert(ptr, size) }
        default { return(ptr, size) }
        }
    }
}

// File: contracts\rebaseToken\IRebaseToken.sol

pragma solidity =0.5.16;
interface IRebaseToken {
    function changeTokenName(string calldata _name, string calldata _symbol,address token)external;
    function calRebaseRatio(uint256 newTotalSupply) external;
    function newErc20(uint256 leftAmount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

// File: contracts\uniswap\IUniswapV2Router02.sol

pragma solidity =0.5.16;


interface IUniswapV2Router02 {
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

// File: contracts\stakePool\IStakePool.sol

pragma solidity =0.5.16;
interface IStakePool {
    function poolToken()external view returns (address);
    function loan(address account) external view returns(uint256);
    function FPTCoin()external view returns (address);
    function interestRate()external view returns (uint64);
    function poolBalance() external view returns (uint256);
    function borrow(uint256 amount) external returns(uint256);
    function borrowAndInterest(uint256 amount) external returns(uint256);
    function repay(uint256 amount) external payable;
    function repayAndInterest(uint256 amount) external payable returns(uint256);
    function setPoolInfo(address fptToken,address stakeToken,uint64 interestrate) external;
}

// File: contracts\modules\Ownable.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\interface\IFNXOracle.sol

pragma solidity =0.5.16;

interface IFNXOracle {
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param asset Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
  */
    function getPrice(address asset) external view returns (uint256);
    function getUnderlyingPrice(uint256 cToken) external view returns (uint256);
    function getPrices(uint256[] calldata assets) external view returns (uint256[]memory);
    function getAssetAndUnderlyingPrice(address asset,uint256 underlying) external view returns (uint256,uint256);
//    function getSellOptionsPrice(address oToken) external view returns (uint256);
//    function getBuyOptionsPrice(address oToken) external view returns (uint256);
}
contract ImportOracle is Ownable{
    IFNXOracle internal _oracle;
    function oraclegetPrices(uint256[] memory assets) internal view returns (uint256[]memory){
        uint256[] memory prices = _oracle.getPrices(assets);
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
        require(prices[i] >= 100 && prices[i] <= 1e30,"oracle price error");
        }
        return prices;
    }
    function oraclePrice(address asset) internal view returns (uint256){
        uint256 price = _oracle.getPrice(asset);
        require(price >= 100 && price <= 1e30,"oracle price error");
        return price;
    }
    function oracleUnderlyingPrice(uint256 cToken) internal view returns (uint256){
        uint256 price = _oracle.getUnderlyingPrice(cToken);
        require(price >= 100 && price <= 1e30,"oracle price error");
        return price;
    }
    function oracleAssetAndUnderlyingPrice(address asset,uint256 cToken) internal view returns (uint256,uint256){
        (uint256 price1,uint256 price2) = _oracle.getAssetAndUnderlyingPrice(asset,cToken);
        require(price1 >= 100 && price1 <= 1e30,"oracle price error");
        require(price2 >= 100 && price2 <= 1e30,"oracle price error");
        return (price1,price2);
    }
    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }
    function setOracleAddress(address oracle)public onlyOwner{
        _oracle = IFNXOracle(oracle);
    }
}

// File: contracts\ERC20\IERC20.sol

pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string calldata _name, string calldata _symbol)external;

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

// File: contracts\modules\SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\modules\Address.sol

pragma solidity =0.5.16;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        (bool success, ) = recipient.call.value(amount)("");
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call.value(value )(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
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

// File: contracts\ERC20\safeErc20.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.5.16;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\LeveragedPool\leveragedPool.sol

pragma solidity =0.5.16;








contract leveragedPool is ImportOracle{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 constant internal calDecimal = 1e18; 
    uint256 constant internal feeDecimal = 1e8; 
    struct leverageInfo {
        uint8 id;
        bool bRebase;
        address token;
        IStakePool stakePool;
        uint256 leverageRate;
        uint256 rebalanceWorth;
        uint256 defaultRebalanceWorth;
        IRebaseToken leverageToken;

    }
    leverageInfo internal leverageCoin;
    leverageInfo internal hedgeCoin;
    IUniswapV2Router02 internal IUniswap;
    uint256 internal rebasePrice;
    uint256 internal currentPrice;
    uint256 internal buyFee;
    uint256 internal sellFee;
    uint256 internal rebalanceFee;
    uint256 internal defaultLeverageRatio;
    uint256 internal liquidateThreshold;
    address payable internal feeAddress;

    event DebugEvent(address indexed from,uint256 value1,uint256 value2);
    constructor() public {

    }
    function() external payable {
        
    }
    function initialize() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function setFeeAddress(address payable addrFee) onlyOwner public {
        feeAddress = addrFee;
    }
    function leverageTokens() public view returns (address,address){
        return (address(leverageCoin.leverageToken),address(hedgeCoin.leverageToken));
    }
    function setLeverageFee(uint256 _buyFee,uint256 _sellFee,uint256 _rebalanceFee) onlyOwner public{
        buyFee = _buyFee;
        sellFee = _sellFee;
        rebalanceFee = _rebalanceFee;
    }
    function getLeverageFee()public view returns(uint256,uint256,uint256){
        return (buyFee,sellFee,rebalanceFee);
    }
    function setLeveragePoolInfo(address payable _feeAddress,address rebaseImplement,uint256 rebaseVersion,address leveragePool,address hedgePool,address oracle,address swapRouter,
        uint256 fees,uint256 _liquidateThreshold,uint256 rebaseWorth,string memory baseCoinName) public onlyOwner {
        feeAddress = _feeAddress;
        uint256 lRate = uint64(fees>>192);
        defaultLeverageRatio = lRate;
        _oracle = IFNXOracle(oracle);
        leverageCoin.id = 0;
        leverageCoin.stakePool = IStakePool(leveragePool);
        leverageCoin.leverageRate = lRate;
        leverageCoin.rebalanceWorth = uint128(rebaseWorth);
        leverageCoin.defaultRebalanceWorth = uint128(rebaseWorth);
        fnxProxy newToken = new fnxProxy(rebaseImplement,rebaseVersion);
        leverageCoin.leverageToken = IRebaseToken(address(newToken));
        leverageCoin.token = leverageCoin.stakePool.poolToken();
        if(leverageCoin.token != address(0)){
            IERC20 oToken = IERC20(leverageCoin.token);
            oToken.safeApprove(swapRouter,uint256(-1));
            oToken.safeApprove(leveragePool,uint256(-1));
        }
        hedgeCoin.id = 1;
        hedgeCoin.stakePool = IStakePool(hedgePool);
        hedgeCoin.leverageRate = lRate;
        hedgeCoin.rebalanceWorth = uint128(rebaseWorth>>128);
        hedgeCoin.defaultRebalanceWorth = hedgeCoin.rebalanceWorth;
        newToken = new fnxProxy(rebaseImplement,rebaseVersion);
        hedgeCoin.leverageToken = IRebaseToken(address(newToken));
        hedgeCoin.token = hedgeCoin.stakePool.poolToken();
        if(hedgeCoin.token != address(0)){
            IERC20 oToken = IERC20(hedgeCoin.token);
            oToken.safeApprove(swapRouter,uint256(-1));
            oToken.safeApprove(hedgePool,uint256(-1));
        }
        buyFee = uint64(fees);
        sellFee = uint64(fees>>64);
        rebalanceFee = uint64(fees>>128);
        liquidateThreshold = _liquidateThreshold;
        string memory token0 = (leverageCoin.token == address(0)) ? baseCoinName : IERC20(leverageCoin.token).symbol();
        string memory token1 = (hedgeCoin.token == address(0)) ? baseCoinName : IERC20(hedgeCoin.token).symbol();
        string memory suffix = leverageSuffix(lRate);

        string memory leverageName = string(abi.encodePacked("LPT_",token0,uint8(95),token1,suffix));
        string memory hedgeName = string(abi.encodePacked("HPT_",token1,uint8(95),token0,suffix));

        leverageCoin.leverageToken.changeTokenName(leverageName,leverageName,leverageCoin.token);
        hedgeCoin.leverageToken.changeTokenName(hedgeName,hedgeName,hedgeCoin.token);
        IUniswap = IUniswapV2Router02(swapRouter);
        rebasePrice = _getUnderlyingPriceView(0);
    }
    function getDefaultLeverageRate()public view returns (uint256){
        return defaultLeverageRatio;
    }
    function leverageRates()public view returns (uint256,uint256){
        return (leverageCoin.leverageRate,hedgeCoin.leverageRate);
    }
    function UnderlyingPrice(uint8 id) internal view returns (uint256){
        if (id == 0){
            return currentPrice;
        }else{
            return calDecimal*calDecimal/currentPrice;
        }
    }
    function getRebasePrice(uint8 id) internal view returns (uint256){
        if (id == 0){
            return rebasePrice;
        }else{
            return calDecimal*calDecimal/rebasePrice;
        }
    }
    function underlyingBalance(uint8 id)internal view returns (uint256){
        address token = (id == 0) ? hedgeCoin.token : leverageCoin.token;
        if (token == address(0)){
            return address(this).balance;
        }else{
            return IERC20(token).balanceOf(address(this));
        }
    }
    function _coinTotalSupply(IRebaseToken leverageToken) internal view returns (uint256){
        return leverageToken.totalSupply();
    }

    function getTotalworths() public view returns(uint256,uint256){
        return (_totalWorthView(leverageCoin,_getUnderlyingPriceView(leverageCoin.id)),_totalWorthView(hedgeCoin,_getUnderlyingPriceView(hedgeCoin.id)));
    }
    function getTokenNetworths() public view returns(uint256,uint256){
        return (_tokenNetworthView(leverageCoin),_tokenNetworthView(hedgeCoin));
    }
    function _totalWorthView(leverageInfo memory coinInfo,uint256 underlyingPrice) internal view returns (uint256){
        uint256 totalSup = coinInfo.leverageToken.totalSupply();
        uint256 allLoan = totalSup.mul(coinInfo.rebalanceWorth)/feeDecimal;
        allLoan = allLoan.mul(coinInfo.leverageRate-feeDecimal);
        return underlyingPrice.mul(underlyingBalance(coinInfo.id)).sub(allLoan);
    }
    function _totalWorth(leverageInfo memory coinInfo) internal view returns (uint256){
        return _totalWorthView(coinInfo,UnderlyingPrice(coinInfo.id));
    }
    function _tokenNetworthBuy(leverageInfo memory coinInfo) internal view returns (uint256){
        uint256 curPrice = UnderlyingPrice(coinInfo.id);
        uint256 rePrice = getRebasePrice(coinInfo.id);
        return ((curPrice*3).mul(coinInfo.rebalanceWorth)/rePrice).sub(coinInfo.rebalanceWorth*2);
    }
    function _tokenNetworthView(leverageInfo memory coinInfo) internal view returns (uint256){
        uint256 tokenNum = _coinTotalSupply(coinInfo.leverageToken);
        if (tokenNum == 0){
            return coinInfo.rebalanceWorth;
        }else{
            return _totalWorthView(coinInfo,_getUnderlyingPriceView(coinInfo.id))/tokenNum;
        }
    }
    function _tokenNetworth(leverageInfo memory coinInfo) internal view returns (uint256){
        uint256 tokenNum = _coinTotalSupply(coinInfo.leverageToken);
        if (tokenNum == 0){
            return coinInfo.rebalanceWorth;
        }else{
            return _totalWorth(coinInfo)/tokenNum;
        }
    }
    function buyLeverage(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _buy(leverageCoin,amount,minAmount,data);
    }
    function buyHedge(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _buy(hedgeCoin, amount,minAmount,data);
    }
    function buyLeverage2(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _buy2(leverageCoin,amount,minAmount,data);
    }
    function buyHedge2(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _buy2(hedgeCoin, amount,minAmount,data);
    }
    function sellLeverage(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _sell(leverageCoin,amount,minAmount,data);
    }
    function sellHedge(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _sell(hedgeCoin, amount,minAmount,data);
    }
    function _buy2(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        address inputToken = (coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token;
        amount = _redeemBuyFeeSub(inputToken,amount);
        uint256 leverageAmount = amount.mul(UnderlyingPrice(coinInfo.id))/_tokenNetworthBuy(coinInfo);
        _buySub(coinInfo,leverageAmount,0,minAmount);
    }
    function _buy(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        amount = _redeemBuyFeeSub(coinInfo.token,amount);
        uint256 leverageAmount = amount.mul(calDecimal)/_tokenNetworthBuy(coinInfo);
        _buySub(coinInfo,leverageAmount,amount,minAmount);
    }
    function _redeemBuyFeeSub(address token,uint256 amount) internal returns(uint256){
        amount = getPayableAmount(token,amount);
        require(amount > 0, 'buy amount is zero');
        uint256 fee;
        (amount,fee) = getFees(buyFee,amount);
        if(fee>0){
            _redeem(feeAddress,token, fee);
        } 
        return amount;
    }
    function _buySub(leverageInfo memory coinInfo,uint256 leverageAmount,uint256 amount,uint256 minAmount) internal{
        require(leverageAmount>=minAmount,"token amount is less than minAmount");
        emit DebugEvent(address(0x111),leverageAmount, _tokenNetworth(coinInfo));
        uint256 userLoan = leverageAmount.mul(coinInfo.rebalanceWorth)/calDecimal;
        userLoan = userLoan.mul(coinInfo.leverageRate-feeDecimal)/feeDecimal;
        emit DebugEvent(address(0x222),amount, userLoan);
        userLoan = coinInfo.stakePool.borrow(userLoan);
        amount = swap(true,coinInfo.id,userLoan.add(amount),0,true);
        emit DebugEvent(address(0x333),amount, userLoan);
        coinInfo.leverageToken.mint(msg.sender,leverageAmount);
    }
    function _sell(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        require(amount > 0, 'sell amount is zero');
        uint256 userLoan = amount.mul(coinInfo.rebalanceWorth)/feeDecimal;
        userLoan = userLoan.mul(coinInfo.leverageRate-feeDecimal);
        uint256 getLoan = coinInfo.stakePool.loan(address(this)).mul(calDecimal);
        emit DebugEvent(address(0x123), getLoan, userLoan);
        if (userLoan > getLoan) {
            userLoan = getLoan;
        }
        uint256 userPayback =  amount.mul(_tokenNetworth(coinInfo));
        emit DebugEvent(address(0x333), underlyingBalance(0), underlyingBalance(1));
        uint256 allSell = swap(false,coinInfo.id,userLoan.add(userPayback)/UnderlyingPrice(coinInfo.id),0,true);
        userLoan = userLoan/calDecimal;
        emit DebugEvent(address(111), allSell, userLoan);
        (uint256 repay,uint256 fee) = getFees(sellFee,allSell.sub(userLoan));
        emit DebugEvent(address(0x222), repay, fee);
        emit DebugEvent(address(111), underlyingBalance(0), underlyingBalance(1));
        require(repay >= minAmount, "Repay amount is less than minAmount");
        _repay(coinInfo,userLoan);
        _redeem(msg.sender,coinInfo.token,repay);
        coinInfo.leverageToken.burn(msg.sender,amount);
        emit DebugEvent(address(0x555), fee, underlyingBalance(0));
        _redeem(feeAddress, coinInfo.token, fee);
    }
    
    function _settle(leverageInfo storage coinInfo) internal returns(uint256,uint256){
        uint256 tokenNum = _coinTotalSupply(coinInfo.leverageToken);
        if (tokenNum == 0){
            return (0,0);
        }
        uint256 insterest = coinInfo.stakePool.interestRate();
        uint256 curPrice = UnderlyingPrice(coinInfo.id);
        uint256 oldUnderlying = curPrice.mul(underlyingBalance(coinInfo.id))/calDecimal;
        uint256 totalWorth = _totalWorth(coinInfo);
        uint256 fee;
        (totalWorth,fee) = getFees(rebalanceFee,totalWorth);
        fee = fee/calDecimal;
        if(fee>0){
            _redeem(feeAddress,coinInfo.token, fee);
        } 
        if (coinInfo.bRebase){
            uint256 newSupply = totalWorth/coinInfo.rebalanceWorth;
            coinInfo.leverageToken.calRebaseRatio(newSupply);
        }else{
            coinInfo.rebalanceWorth = totalWorth/tokenNum;
        }
        totalWorth = totalWorth/calDecimal;
        uint256 allLoan = totalWorth.mul(coinInfo.leverageRate-feeDecimal)/feeDecimal;
        uint256 poolBalance = coinInfo.stakePool.poolBalance();
        emit DebugEvent(address(3), allLoan, poolBalance);
        if(allLoan <= poolBalance){
            coinInfo.leverageRate = defaultLeverageRatio;
        }else{
            allLoan = poolBalance;
            coinInfo.leverageRate = poolBalance.mul(feeDecimal)/totalWorth + feeDecimal;
        } 
        uint256 loadInterest = allLoan.mul(insterest)/1e8;
        emit DebugEvent(address(0x321), loadInterest, coinInfo.rebalanceWorth);
        uint256 newUnderlying = totalWorth+allLoan-loadInterest;
        if(oldUnderlying>newUnderlying){
            return (0,oldUnderlying-newUnderlying);
        }else{
            return (newUnderlying-oldUnderlying,0);
        }
    }
    function rebalance() getUnderlyingPrice public {
        (uint256 buyLev,uint256 sellLev) = _settle(leverageCoin);
        (uint256 buyHe,uint256 sellHe) = _settle(hedgeCoin);
        rebasePrice = UnderlyingPrice(0);
        uint256 _curPrice = rebasePrice;
        emit DebugEvent(address(0x1221), buyHe, sellHe);
        emit DebugEvent(address(0x1222), _curPrice, sellHe.mul(_curPrice)/calDecimal);
        if (buyLev>0){
            leverageCoin.stakePool.borrowAndInterest(buyLev);
        }
        if(buyHe>0){
            hedgeCoin.stakePool.borrowAndInterest(buyHe);
        }
        if (buyLev>0 && buyHe>0){
            buyHe = _curPrice.mul(buyHe);
            buyLev = buyLev.mul(calDecimal);
            if(buyLev>buyHe){
                swap(true,0,(buyLev - buyHe)/calDecimal,(buyLev - buyHe)/_curPrice/2,true);
            }else{
                swap(false,0,(buyHe - buyLev)/_curPrice,(buyHe - buyLev)/calDecimal/2,true);
            }
        }else if(sellLev>0 && sellHe>0){
            uint256 sellHe1 = _curPrice.mul(sellHe);
            uint256 sellLev1 = sellLev.mul(calDecimal);
            if(sellLev1>sellHe1){
                sellLev1 = (sellLev1-sellHe1);
                sellHe1 = sellLev1/calDecimal;
                sellLev1 = sellLev1.add(sellLev1/10)/_curPrice;
                swap(false,0,sellLev1,sellHe1,false);
            }else{
                sellLev1 = (sellHe1-sellLev1);
                sellHe1 = sellLev1.add(sellLev1)/calDecimal;
                sellLev1 =  sellLev1/_curPrice;
                swap(true,0,sellHe1,sellLev1,false);
            }
        }else{
            if (buyLev>0){
                swap(true,0,buyLev,buyLev.mul(_curPrice)/_curPrice/2,true);
            }else if (sellLev>0){
                swap(false,0,sellLev.add(sellLev/10).mul(calDecimal)/_curPrice,sellLev,false);
            }
            if(buyHe>0){
                swap(false,0,buyHe,buyHe.mul(_curPrice)/calDecimal/2,true);
            }else if(sellHe>0){
                emit DebugEvent(address(13), sellHe.add(sellHe/10).mul(_curPrice)/calDecimal, sellHe);
                swap(true,0,sellHe.add(sellHe/10).mul(_curPrice)/calDecimal,sellHe,false);
            }
        }
        emit DebugEvent(address(14), underlyingBalance(1), underlyingBalance(0));
        if(buyLev == 0){
            _repayAndInterest(leverageCoin,sellLev);
        }
        if(buyHe == 0){
            _repayAndInterest(hedgeCoin,sellHe);
        }
    }
    function liquidateLeverage() public {
        _liquidate(leverageCoin);
    }
    function liquidateHedge() public {
        _liquidate(hedgeCoin);
    }
    function _liquidate(leverageInfo storage coinInfo) canLiquidate(coinInfo)  internal{
        //all selled
        uint256 amount = swap(false,coinInfo.id,underlyingBalance(coinInfo.id),0,true);
        uint256 fee;
        (amount,fee) = getFees(rebalanceFee,amount);
        if(fee>0){
            _redeem(feeAddress,coinInfo.token, fee);
        } 
        uint256 allLoan = coinInfo.stakePool.loan(address(this));
        if (amount > allLoan){
            _repay(coinInfo,allLoan);
            _redeem(address(uint160(address(coinInfo.leverageToken))),coinInfo.token,amount-allLoan);
            coinInfo.leverageToken.newErc20(amount-allLoan);
        }else{
            _repay(coinInfo,amount);
        }
    }
    function _repay(leverageInfo memory coinInfo,uint256 amount)internal{
        if (coinInfo.token == address(0)){
            emit DebugEvent(coinInfo.token, amount, address(this).balance);
            coinInfo.stakePool.repay.value(amount)(amount);
        }else{
            coinInfo.stakePool.repay(amount);
        }
    }
    function _repayAndInterest(leverageInfo memory coinInfo,uint256 amount)internal{
        if (coinInfo.token == address(0)){
            coinInfo.stakePool.repayAndInterest.value(amount)(amount);
        }else{
            coinInfo.stakePool.repayAndInterest(amount);
        }
    }
    function getFees(uint256 feeRatio,uint256 amount) internal pure returns (uint256,uint256){
        uint256 fee = amount.mul(feeRatio)/feeDecimal;
        return(amount.sub(fee),fee);
    }

    function swap(bool buy,uint8 id,uint256 amount0,uint256 amount1,bool firstExact)internal returns (uint256) {
        return (id == 0) == buy ? _swap(leverageCoin.token,hedgeCoin.token,amount0,amount1,firstExact) : 
            _swap(hedgeCoin.token,leverageCoin.token,amount0,amount1,firstExact);
    }
    function _swap(address token0,address token1,uint256 amount0,uint256 amount1,bool firstExact) internal returns (uint256) {
        address[] memory path = new address[](2);
        uint[] memory amounts;
        if(token0 == address(0)){
            path[0] = IUniswap.WETH();
            path[1] = token1;
            if (!firstExact){
                amounts = IUniswap.swapETHForExactTokens.value(amount0)(amount1, path, address(this), now+30);
            }else{
                amounts = IUniswap.swapExactETHForTokens.value(amount0)(amount1, path, address(this), now+30);
            } 
        }else if(token1 == address(0)){
            path[0] = token0;
            path[1] = IUniswap.WETH();
            if (!firstExact){
                amounts = IUniswap.swapTokensForExactETH(amount1,amount0, path, address(this), now+30);
            }else{
                amounts = IUniswap.swapExactTokensForETH(amount0,amount1, path, address(this), now+30);
            }
        }else{
            path[0] = token0;
            path[1] = token1;
            if (!firstExact){
                amounts = IUniswap.swapTokensForExactTokens(amount1,amount0, path, address(this), now+30);
            }else{
                amounts = IUniswap.swapExactTokensForTokens(amount0,amount1, path, address(this), now+30);
            }
        }
        return amounts[amounts.length-1];
    }
    function getPayableAmount(address stakeCoin,uint256 amount) internal returns (uint256) {
        if (stakeCoin == address(0)){
            amount = msg.value;
        }else if (amount > 0){
            IERC20 oToken = IERC20(stakeCoin);
            oToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        return amount;
    }
        /**
     * @dev An auxiliary foundation which transter amount stake coins to recieptor.
     * @param recieptor recieptor recieptor's account.
     * @param stakeCoin stake address
     * @param amount redeem amount.
     */
    function _redeem(address payable recieptor,address stakeCoin,uint256 amount) internal{
        if (stakeCoin == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 token = IERC20(stakeCoin);
            token.safeTransfer(recieptor,amount);
        }
    }
    function _getUnderlyingPriceView(uint8 id) internal view returns(uint256){
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        return id == 0 ? prices[1]*calDecimal/prices[0] : prices[0]*calDecimal/prices[1];
    }
    modifier canLiquidate(leverageInfo memory coinInfo){
        require(_coinTotalSupply(coinInfo.leverageToken)>0,"Liquidate : current pool is empty!");
        currentPrice = _getUnderlyingPriceView(0);
        uint256 allLoan = coinInfo.rebalanceWorth.mul(coinInfo.leverageRate-feeDecimal);
        require(UnderlyingPrice(coinInfo.id).mul(feeDecimal+liquidateThreshold)<allLoan,"Liquidate: current price is not under the threshold!");
        _;
    }
    modifier getUnderlyingPrice(){
        currentPrice = _getUnderlyingPriceView(0);
        _;
    }
    function leverageSuffix(uint256 leverageRatio) internal pure returns (string memory){
        if (leverageRatio == 0) return "0";
        uint256 integer = leverageRatio*10/feeDecimal;
        uint8 fraction = uint8(integer%10+48);
        integer = integer/10;
        uint8 ten = uint8(integer/10+48);
        uint8 unit = uint8(integer%10+48);
        bytes memory suffix = new bytes(7);
        suffix[0] = bytes1(uint8(95));
        suffix[1] = bytes1(uint8(88));
        uint len = 2;
        if(ten>48){
                suffix[len++] = bytes1(ten);
            }
        suffix[len++] = bytes1(unit);
        if (fraction>48){
            suffix[len++] = bytes1(uint8(46));
            suffix[len++] = bytes1(fraction);
        }
        bytes memory newSuffix = new bytes(len);
        for(uint i=0;i<len;i++){
            newSuffix[i] = suffix[i];
        }
        return string(newSuffix);
    }

}