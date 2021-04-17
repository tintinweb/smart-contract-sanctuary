/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
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

library EnumerableSet {

    struct Set {

        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

interface IBaseFireNFT {
    function baseFireOwnersNow() external view returns (uint256);
    function isNFTOwner(address account) external view returns(bool);
    function getNFTOwners(uint256 index) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function baseURI() external view returns (string memory);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract Owned is Context {
    address private _owner;
    address private _operator;
    address private _pendingOwner;

    EnumerableSet.AddressSet permitted;

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
    modifier ownerOnly {
        require(_owner == _msgSender() || _msgSender() == _operator, "not allowed");
        _;
    }

    modifier allowedOnly(address account) {
        require(EnumerableSet.contains(permitted, account) || account == _owner, "Owned: not permitted");
        _;
    }

    modifier pendingOnly {
        require (_pendingOwner == msg.sender, "cannot claim");
        _;
    }

    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    function renounceOwnership() public virtual ownerOnly {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public ownerOnly {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _pendingOwner = newOwner;
    }

    function cancelTransfer() public ownerOnly {
        require(_pendingOwner != address(0), "no pending owner");
        _pendingOwner = address(0);
    }

    function claimOwnership() public pendingOnly {
        _pendingOwner = address(0);
        emit OwnershipTransferred(_owner, _msgSender());
        _owner = _msgSender();
    }

    function setOperator(address op) public {
        require(_operator == _msgSender() || _owner == _msgSender(), "not allowed");
        _operator = op;
    }

    function setAllowedContracts(bool add, address _permitted) external {
        require(_operator == _msgSender() || _owner == _msgSender(), "not allowed");
        if(add) {
            EnumerableSet.add(permitted, _permitted);
        } else {
            EnumerableSet.remove(permitted, _permitted);
        }
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
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

interface ITValues {
    struct TxValue {
        uint256 amount;
        uint256 transferAmount;
        uint256 fee;
        uint256 buyFee;
        uint256 sellFee;
        uint256 buyBonus;
        uint256 operationalFee;
        uint256 burnFee;
        uint256 farmFee;
        uint256 lpFee;
        uint256 nftFee;
    }
    enum TxType { FromExcluded, ToExcluded, BothExcluded, Standard }
    enum TState { Buy, Sell, Normal }
}

interface IStates {

    struct Balances {
        uint256 tokenSupply;
        uint256 networkSupply;
        uint256 targetSupply;
        uint256 pairSupply;
        uint256 lpSupply;
        uint256 fees;
    }


    struct Divisors {
        uint256 buy;
        uint256 sell;
        uint256 bonus;
        uint256 burn;
        uint256 tx;
        uint256 farm;
        uint256 lp;
        uint256 op;
        uint256 nft;
    }

    struct Account {
        bool feeless;
        bool transferPair;
        bool excluded;
        uint256 lastBonus;
        uint256 lastSell;
        uint256 lastBuy;
        uint256 tTotal;
        uint256 nTotal;
    }
}

contract Pool is Owned {
    string public name;
    constructor(string memory _name) {
        name = _name;
    }
    function saveTokens(IERC20 token) external ownerOnly {
        token.transferFrom(address(this), owner(), token.balanceOf(address(this)));
    }
}

contract BaseFire is IERC20, Owned, ReentrancyGuard {

    using Address for address;

    event BonusAwarded(address account, uint256 amount);
    event TransactionEvents(ITValues.TxValue t, ITValues.TState tstate);
    event Winner(address account, uint256 amount);
    event Burned(uint256 amount);
    event Based(uint256 amount);
    event SentToBurn(uint256 amount);

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    IStates.Balances balances;
    IStates.Divisors divisors;
    ITValues.TState lastTState;

    IBaseFireNFT baseFireNFT;

    EnumerableSet.AddressSet excludedAccounts;

    Pool private _prizePool;
    Pool private _buyBonusPool;
    Pool private _farmPool;
    Pool private _nftPool;

    address[] private _entries;

    bool public inflationGuard;
    bool private _inflationCheck;

    uint256 public devFeeDivisor;
    uint256 public inflationRateDivisor;
    uint256 public tokenBurnRateDivisor;
    uint256 public buyCounterLimit;
    uint256 public buys;
    uint256 public minBuyForBonus;
    uint256 public rebased;
    uint256 public farmed;
    uint256 public burned;
    uint256 public inflation;

    address constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    address private _op;
    address private _router;
    address private _pool;
    address private _pair;
    address private _lpAddr;

    uint256 public lastBOB;
    uint256 public emissionPerBlock;
    uint256 public manuallyBurnedAt;
    uint256 private _BOBCooldown;
    uint256 private _lastRewardBlock;
    uint256 private _timeCheck;
    uint256 private _bonusInterval; // once every hour
    uint256 private _buyDefault;
    uint256 private _sellDefault;
    uint256 private _counterLimitDefault;
    uint256 private _manualBurns;

    bool public isFarmActive;
    bool private _isNFTPoolActive;
    bool private _paused;
    bool private _dynamicFees;
    bool private _botChecking;

    mapping(address => IStates.Account) accounts;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(uint8 => Pool) pools;

    constructor() {

        _name = "StopDontBuy Token";
        _symbol = "STOP";
        _decimals = 18;

        balances.tokenSupply = 100_000_000_000 ether;
        balances.networkSupply = (~uint256(0) - (~uint256(0) % balances.tokenSupply));
        inflationGuard = true;

        // ----- abstract to fee manager
        divisors.buy = 50;  // 2%
        divisors.sell = 50; // 2%
        divisors.bonus = 2; //
        divisors.burn = 100;// 1%
        divisors.tx = 100;  // 1%
        divisors.farm = 200;// .5%
        divisors.op = 200;  // .5%
        divisors.lp = 200;  // .5%
        divisors.nft = 200; // .5%
        // -----

        inflationRateDivisor = 20;
        tokenBurnRateDivisor = 20;
        buyCounterLimit = 30;
        emissionPerBlock = 1000 ether; // BAFI per block
        minBuyForBonus = balances.tokenSupply / 10000; // starts w/ .01%

        _prizePool = new Pool("BaseFire's Prize Pool");
        _buyBonusPool = new Pool("BaseFire's DBB Pool");
        _farmPool = new Pool("BaseFire's Farm Pool");
        _nftPool = new Pool("BaseFire's NFT Rewards Pool");
        pools[0] = _prizePool;
        pools[1] = _buyBonusPool;
        pools[2] = _farmPool;
        pools[3] = _nftPool;

        _bonusInterval = 1 hours; // once every hour
        _buyDefault = 50;
        _sellDefault = 50;
        _counterLimitDefault = 30;


        //--- pancake specific ---

//        _op = address(0xfEDD9544b47a6D4A1967D385575866BD6f7A2b37);
//        _router = address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
//        _pair = IPancakeRouter02(_router).WETH();
//        _pool = IPancakeFactory(IPancakeRouter02(_router).factory()).createPair(address(this), _pair);

        _router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _op = address(0xfEDD9544b47a6D4A1967D385575866BD6f7A2b37);
        _pair = IUniswapV2Router02(_router).WETH();
        _pool = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(address(this), _pair);
        _paused = true;
        _BOBCooldown = 60 minutes;
        _dynamicFees = true;
        _timeCheck = 1 days;

        EnumerableSet.add(permitted, _msgSender());
        accounts[BURN_ADDRESS].feeless = true;
//        accounts[_msgSender()].feeless = true;
        accounts[_pool].transferPair = true;
        uint256 _amount = balances.networkSupply / 2;
        accounts[_msgSender()].nTotal = _amount / 5; // 10%
        accounts[address(_farmPool)].nTotal = (_amount / 5) * 2; // 20%
        accounts[address(_buyBonusPool)].nTotal = (_amount / 5) * 2; // 20%
        accounts[BURN_ADDRESS].nTotal = _amount; // 50%
        emit Transfer(address(0), _msgSender(), balances.tokenSupply / 10);
        emit Transfer(address(0), address(_farmPool), balances.tokenSupply / 5);
        emit Transfer(address(0), address(_buyBonusPool), balances.tokenSupply / 5);
        emit Transfer(address(0), BURN_ADDRESS, balances.tokenSupply / 2);

    }

    modifier isNotContract(address sender) {
        require(!Address.isContract(msg.sender), "contract");
        _;
    }

    //------ ERC20 Functions -----

    function name() public view returns(string memory) {
        return _name;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    // This is important to show the rebalanced values.
    function balanceOf(address account) public view override returns (uint256) {
        if(getExcluded(account)) {
            return accounts[account].tTotal;
        }
        return accounts[account].nTotal / ratio();
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] - (subtractedValue));
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return balances.tokenSupply;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _bfTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _bfTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()] - amount);
        return true;
    }

    //----------- core functions -------------

    /*

        - checks if interval is passed then sets defaults
        - only pool can send
        -

    */
    function _bfTransfer(address sender, address recipient, uint256 amount) internal returns(bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(sender == _pool) {
            require(_paused == false, "Transfers are _paused");
        }
        if(_dynamicFees == true && block.timestamp % _timeCheck == 0) {
            buyCounterLimit = _counterLimitDefault;
            divisors.buy = _buyDefault;
            divisors.sell = _sellDefault;
        }
        uint256 rate = ratio();
        uint256 lpAmount = getCurrentLPBal();
        (ITValues.TxValue memory t, ITValues.TState ts, ITValues.TxType txType) = calculateTXValues(sender, recipient, amount, isFeelessTx(sender, recipient), lpAmount);
        balances.lpSupply = lpAmount;
        if(t.buyBonus > 0 && accounts[recipient].lastBonus <= _bonusInterval) {
            accounts[recipient].lastBonus = block.timestamp;
        }
        _handleAdjustments(recipient, rate, ts, t);
        _applyTransfer(sender, recipient, rate, t, txType);
        balances.fees += t.fee;
        balances.networkSupply -= t.fee * rate;
        lastTState = ts;
        emit Transfer(sender, recipient, t.transferAmount);
        emit Transfer(sender, _op, t.operationalFee);
        emit Transfer(sender, _lpAddr, t.lpFee);
        emit Transfer(sender, BURN_ADDRESS, t.burnFee);
        emit Transfer(sender, address(_farmPool), t.farmFee);
        emit Transfer(sender, address(_nftPool), t.nftFee);
        emit Transfer(sender, address(_buyBonusPool), t.sellFee);
        emit TransactionEvents(t, ts);
        return true;
    }

    function calculateTXValues(address sender, address recipient, uint256 amount, bool noFee, uint256 lpAmount) public view returns (ITValues.TxValue memory t, ITValues.TState ts, ITValues.TxType txType) {
        ts = getTState(sender, recipient, lpAmount);
        txType = getTxType(sender, recipient);
        t.amount = amount;
        if(!noFee) {
            t.fee = amount / divisors.tx;
            t.operationalFee = amount / divisors.op;
            t.burnFee = amount / divisors.burn;
            t.farmFee = amount / divisors.farm;
            t.lpFee = amount / divisors.lp;
            t.nftFee = amount / divisors.nft;
            if(ts == ITValues.TState.Sell) {
                t.sellFee = amount / divisors.sell;
            }
            if(ts == ITValues.TState.Buy) {
                t.buyFee = amount / getBuyTax(amount);
                t.buyBonus = getBuyBonus(recipient, amount);
            }
        }
        t.transferAmount = t.amount - t.fee - t.sellFee - t.buyFee - t.operationalFee - t.burnFee - t.farmFee - t.lpFee - t.nftFee;
        return (t, ts, txType);
    }

    function _handleAdjustments(address recipient, uint256 rate, ITValues.TState ts, ITValues.TxValue memory t) internal {
        accounts[_op].nTotal += (t.operationalFee * rate);
        accounts[_lpAddr].nTotal += t.lpFee * rate;
        accounts[BURN_ADDRESS].nTotal += (t.burnFee * rate);
        accounts[BURN_ADDRESS].tTotal += (t.burnFee);
        accounts[address(_farmPool)].nTotal += t.farmFee * rate;
        accounts[address(_farmPool)].tTotal += t.farmFee;
        accounts[address(_nftPool)].nTotal += t.nftFee * rate;
        accounts[address(_nftPool)].tTotal += t.nftFee;
        if(ts == ITValues.TState.Sell) {
            accounts[address(_buyBonusPool)].nTotal += t.sellFee * rate;
            accounts[address(_buyBonusPool)].tTotal += t.sellFee;
        }
        if(ts == ITValues.TState.Buy) {
            if(t.amount > minBuyForBonus) {
                buys++;
                if(buys % buyCounterLimit == 0) {
                    uint256 a = accounts[address(_prizePool)].nTotal;
                    accounts[address(_prizePool)].nTotal = 0;
                    accounts[address(_prizePool)].tTotal = 0;
                    accounts[recipient].nTotal += a;
                    emit Transfer(address(_prizePool), recipient, a);
                    emit Winner(recipient, a);
                }
            }
            accounts[address(_prizePool)].nTotal += t.buyFee * rate;
            accounts[address(_prizePool)].tTotal += t.buyFee;
            accounts[address(_buyBonusPool)].nTotal -= t.buyBonus * rate;
            accounts[address(_buyBonusPool)].tTotal -= t.buyBonus;
            accounts[recipient].nTotal += t.buyBonus * rate;
            emit Transfer(address(_buyBonusPool), recipient, t.buyBonus);
        }
    }

    function _applyTransfer(address sender, address recipient, uint256 rate, ITValues.TxValue memory t, ITValues.TxType txType) internal {
        if (txType == ITValues.TxType.ToExcluded) {
            accounts[sender].nTotal         -= t.amount * rate;
            accounts[recipient].tTotal      += (t.transferAmount);
            accounts[recipient].nTotal      += t.transferAmount * rate;
        } else if (txType == ITValues.TxType.FromExcluded) {
            accounts[sender].tTotal         -= t.amount;
            accounts[sender].nTotal         -= t.amount * rate;
            accounts[recipient].nTotal      += t.transferAmount * rate;
        } else if (txType == ITValues.TxType.BothExcluded) {
            accounts[sender].tTotal         -= t.amount;
            accounts[sender].nTotal         -= (t.amount * rate);
            accounts[recipient].tTotal      += t.transferAmount;
            accounts[recipient].nTotal      += (t.transferAmount * rate);
        } else {
            accounts[sender].nTotal         -= (t.amount * rate);
            accounts[recipient].nTotal      += (t.transferAmount * rate);
        }
    }

    function burn() external isNotContract(msg.sender) {
        require(lastBOB + _BOBCooldown < block.timestamp, "BoB coolingdown");
        require(!_paused, "still paused");
        // this burns only tokens in the pool, causing an increase in the ratio of BNB : BAFI
        _burn(_pool, tokenBurnRateDivisor);
        // increase the sell fee to put a break on sell-offs
        if(_dynamicFees == true) {
            divisors.sell += 2;
        }
    }

    function _burn(address target, uint256 rate) internal {
        uint256 r = accounts[target].nTotal;
        uint256 amountToDeflate = (r / rate);
        if(inflationGuard == false && _inflationCheck == true) {
            // to compensate for if we're actually minting supply
            if(inflation > amountToDeflate){
                inflation -= amountToDeflate;
                balances.tokenSupply -= amountToDeflate;
            }
        }
        accounts[target].nTotal -= amountToDeflate;
        accounts[BURN_ADDRESS].nTotal += r;
        accounts[BURN_ADDRESS].tTotal += amountToDeflate;
        lastBOB = block.timestamp;
        syncPool();
        emit Transfer(target, BURN_ADDRESS, amountToDeflate);
    }

    function base() external isNotContract(msg.sender) {
        require(lastBOB + _BOBCooldown < block.timestamp, "BoB cooling down");
        require(!_paused, "still paused");
        uint256 rate = ratio();
        uint256 amountToInflate;
        if(inflationGuard == true && accounts[BURN_ADDRESS].tTotal > 0) {
            // we use the total of the burn address as a base here.
            amountToInflate = accounts[BURN_ADDRESS].tTotal / inflationRateDivisor;
            if(amountToInflate > accounts[BURN_ADDRESS].tTotal) {
                // just set it to the entire burn address if its greater
                amountToInflate = accounts[BURN_ADDRESS].tTotal;
            }
            require(amountToInflate <= accounts[BURN_ADDRESS].tTotal, "wait for burn to fill up");
            accounts[BURN_ADDRESS].nTotal -= amountToInflate * rate;
            accounts[BURN_ADDRESS].tTotal -= amountToInflate;
            // positive rebase
            balances.networkSupply -= amountToInflate * rate;
        } else {
            // phase 2 for frictionless farms / pools
            amountToInflate = balances.tokenSupply / inflationRateDivisor;
            // this alone wouldn't inflate the actual token supply,
            // but balances would get moved around depending on how much people are holding etc.
            balances.networkSupply -= amountToInflate * rate;
            if(_inflationCheck){
                // if we want bases to actually mint
                balances.tokenSupply += amountToInflate;
                // keep track of inflation with this
                inflation += amountToInflate;
            }
        }

        lastBOB = block.timestamp;

        // increase the buyCounterLimit
        if(_dynamicFees == true && divisors.buy > 0) {
            divisors.buy += 2;
            buyCounterLimit++;
        }
        rebased += amountToInflate;
        syncPool();
        emit Based(amountToInflate);
    }

    // We do this when we reach 1000 holders, 2500, 5000, 10000, and so on.
    function burnForSuccess(uint256 rate, uint256 pid) external allowedOnly(msg.sender) {
        require(rate > 4, "can't burn more than 25%");
        require(manuallyBurnedAt + (10 days * _manualBurns) < block.timestamp, "must wait to do another burn");
        address target;
        if(pid == 0) {
            target = _pool;
        } else if(pid == 1) {
            target = address(_buyBonusPool);
        } else if(pid == 2) {
            target = address(_farmPool);
        } else if(pid == 3){
            target = address(_nftPool);
        } else if(pid == 4) {
            target = _lpAddr;
        } else {
            target = _pool;
        }
        _burn(target, rate);
        _manualBurns++;
        manuallyBurnedAt = block.timestamp;
    }

    function include(address account) external allowedOnly(msg.sender) {
        require(accounts[account].excluded, "Account is already excluded");
        accounts[account].tTotal = 0;
        EnumerableSet.remove(excludedAccounts, account);
    }

    function exclude(address account) external allowedOnly(msg.sender) {
        require(!accounts[account].excluded, "Account is already excluded");
        accounts[account].excluded = true;
        if(accounts[account].nTotal > 0) {
            accounts[account].tTotal = accounts[account].nTotal / ratio();
        }
        accounts[account].excluded = true;
        EnumerableSet.add(excludedAccounts, account);
    }

    function harvest() public nonReentrant {
        require(isFarmActive, "farm not yet active");
        require(_lastRewardBlock != block.number, "crops not ready yet");
        uint256 rate = ratio();
        uint256 nInflation = (block.number - _lastRewardBlock) * emissionPerBlock * rate; // blocks * 100 * rate
        accounts[address(_farmPool)].nTotal -= nInflation;
        farmed += nInflation / rate;
        _lastRewardBlock = block.number;
        balances.networkSupply -= nInflation;
    }

    function disperseNFTFees() public { // anyone can disperse nft fees to nft holders at any time, will disperse all fees.
        if(_isNFTPoolActive) {
            uint256 owners = baseFireNFT.baseFireOwnersNow();
            uint256 share = balanceOf(address(_nftPool)) / owners;
            for (uint256 i = 0; i < owners; i++) {
                accounts[baseFireNFT.getNFTOwners(i)].nTotal += share;
            }
        }
    }

    // disperse amount to all holders, for *possible* cex integration
    // !!BEWARE!!: you will send from your wallet when you call this.
    function reflectFromYouToEveryone(uint256 amount) external {
        address sender = _msgSender();
        uint256 rate = ratio();
        require(!getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < accounts[sender].nTotal, "too much");
        accounts[sender].nTotal -= (amount * rate);
        balances.networkSupply -= amount * rate;
        balances.fees += amount;
    }

    function rebalancePools(uint8 _from, uint8 _to, uint256 amount) external allowedOnly(msg.sender) {
        // depending on amount of buy/sell fees gathered, during times of high growth of holders increasing farm pool is >,
        // during low volume having higher buy bonus fees is better to prevent big sell offs.
        // nTotal is used since pools are "included" and gather fees through txns as well.
        require(address(pools[_from]) != _pool, "can't be transferring from lpool");
        uint256 n = amount * ratio();
        require(n <= accounts[address(pools[_from])].nTotal, "can't move more");
        accounts[address(pools[_from])].nTotal -= n;
        accounts[address(pools[_to])].nTotal += n;
        emit Transfer(address(pools[_from]), address(pools[_to]), n);
    }

    // manual burn amount, for *possible* cex integration
    // !!BEWARE!!: you will burn from your wallet when you call this.
    function sendToBurn(uint256 amount) external {
        address sender = _msgSender();
        uint256 rate = ratio();
        require(!getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < accounts[sender].nTotal, "too much");
        accounts[sender].nTotal -= (amount * rate);
        accounts[BURN_ADDRESS].nTotal += (amount * rate);
        accounts[BURN_ADDRESS].tTotal += (amount);
        syncPool();
        emit Transfer(address(this), BURN_ADDRESS, amount);
    }

    // --------------------------------------------

    // ----------- view functions -----------------

    function isFeelessTx(address sender, address recipient) public view returns(bool) {
        return accounts[sender].feeless || accounts[recipient].feeless;
    }

    function getPoolAddrs(uint8 pid) public view returns(address) {
        return address(pools[pid]);
    }

    function getPoolValue(uint8 pid) public view returns(uint256) {
        return balanceOf(getPoolAddrs(pid));
    }

    function getAccount(address account) external view returns(IStates.Account memory) {
        return accounts[account];
    }

    function getDivisors() external view returns(IStates.Divisors memory) {
        return divisors;
    }

    function getBalances() external view returns(IStates.Balances memory) {
        return balances;
    }

    function getExcluded(address account) public view returns(bool) {
        return accounts[account].excluded;
    }

    function getCurrentLPBal() public view returns(uint256) {
        return IERC20(_pool).totalSupply();
    }

    function getTState(address sender, address recipient, uint256 lpAmount) public view returns(ITValues.TState) {
        ITValues.TState t;
        if(sender == _router) {
            t = ITValues.TState.Normal;
        } else if(accounts[sender].transferPair) {
            if(balances.lpSupply != lpAmount) { // withdraw vs buy
                t = ITValues.TState.Normal;
            }
            t = ITValues.TState.Buy;
        } else if(accounts[recipient].transferPair) {
            t = ITValues.TState.Sell;
        } else {
            t = ITValues.TState.Normal;
        }
        return t;
    }

    function getCirculatingSupply() public view returns(uint256, uint256) {
        uint256 rSupply = balances.networkSupply;
        uint256 tSupply = balances.tokenSupply;
        for (uint256 i = 0; i < EnumerableSet.length(excludedAccounts); i++) {
            address account = EnumerableSet.at(excludedAccounts, i);
            uint256 rBalance = accounts[account].nTotal;
            uint256 tBalance = accounts[account].tTotal;
            if (rBalance > rSupply || tBalance > tSupply) return (balances.networkSupply, balances.tokenSupply);
            rSupply -= rBalance;
            tSupply -= tBalance;
        }
        if (rSupply < balances.networkSupply / balances.tokenSupply) return (balances.networkSupply, balances.tokenSupply);
        return (rSupply, tSupply);
    }

    function getTxType(address sender, address recipient) public view returns(ITValues.TxType t) {
        bool isSenderExcluded = accounts[sender].excluded;
        bool isRecipientExcluded = accounts[recipient].excluded;
        if (isSenderExcluded && !isRecipientExcluded) {
            t = ITValues.TxType.FromExcluded;
        } else if (!isSenderExcluded && isRecipientExcluded) {
            t = ITValues.TxType.ToExcluded;
        } else if (!isSenderExcluded && !isRecipientExcluded) {
            t = ITValues.TxType.Standard;
        } else if (isSenderExcluded && isRecipientExcluded) {
            t = ITValues.TxType.BothExcluded;
        } else {
            t = ITValues.TxType.Standard;
        }
        return t;
    }

    function getBuyBonus(address account, uint256 amount) public view returns(uint256) {
        uint256 bonus;
        uint256 total = balanceOf(address(_buyBonusPool));
        if(lastTState == ITValues.TState.Sell && accounts[account].lastBonus <= _bonusInterval) { // to prevent whales or bots from abusing the system
            if(amount >= total / 2) {
                bonus = amount / divisors.bonus;
            } else if(amount >= total / 5) {
                bonus = amount / (divisors.bonus * 2);
            } else if(amount >= total / 10) {
                bonus = amount / (divisors.bonus * 3);
            } else if(amount >= total / 25) {
                bonus = amount / (divisors.bonus * 4);
            } else {
                bonus = amount / (divisors.bonus * 5);
            }
        }
        // make sure we can't give more than the pool itself
        return bonus > total ? 0 : bonus;
    }

    function getBuyTax(uint256 amount) public view returns(uint256) {
        if(amount < minBuyForBonus) {
            return divisors.buy; // charges whatever max buy fee is at, to discourage gaming the prizepool.
        } else if (amount / 10 > minBuyForBonus) { // you are at 10x the min buy for bonus
            return divisors.buy * 5; // charges 1/5th of buy fee, from default is 1%
        } else if (amount / 2 > minBuyForBonus){
            return divisors.buy * 4; // and so on.
        } else {
            return divisors.buy * 2;
        }
    }

    function getCooldown() public view returns(uint256) {
        // negative means it's not yet ready, positive means its ready
       return lastBOB;
    }

    function isCooledDown() public view returns (bool) {
        return int256(block.timestamp - (lastBOB + _BOBCooldown)) < 0;
    }

    function ratio() public view returns(uint256) {
        (uint256 n, uint256 t) = getCirculatingSupply();
        return n / t;
    }

    function syncPool() public  {
        IUniswapV2Pair(_pool).sync();
//        IPancakeSwapPair(_pool).sync();
    }

    // --------------------

    // ------ setters / mutative ------

    // one way function, once called it will always be false.
    function enableTrading() external allowedOnly(msg.sender) {
        _paused = false;
    }

    // please don't send money DIRECTLY to the contract.
    // but there's always been one who does. this is for you.

    function saveTokensInContract(address _to, address _token) external allowedOnly(msg.sender) {
        IERC20(_token).transferFrom(address(this), _to, IERC20(address(this)).balanceOf(address(this)));
    }

    function saveTokensInPool(uint8 pid, address token) external allowedOnly(msg.sender) {
        require(token != _pair, "can't pull tokens from pool");
        pools[pid].saveTokens(IERC20(token));
    }

    function setEmissionRate(uint256 _emissionPerBlock) external allowedOnly(msg.sender) {
        emissionPerBlock = _emissionPerBlock;
    }

    function setInflationGuard(bool value) external allowedOnly(msg.sender) {
        inflationGuard = value;
    }

    function setBotChecking(bool value) external allowedOnly(msg.sender) {
        _botChecking = value;
    }

    function setLPFee(uint256 _lp) external allowedOnly(msg.sender) {
        require(_lp >= 25 || _lp == 0, "can't be more than 4%");
        divisors.lp = _lp;
    }

    function setNFTFee(uint256 _nft) external allowedOnly(msg.sender) {
        require(_nft >= 25 || _nft == 0, "can't be more than 4%");
        divisors.nft = _nft;
    }

    function setFarmFee(uint256 _farm) external allowedOnly(msg.sender) {
        require(_farm >= 25 || _farm == 0, "can't be more than 2%");
        divisors.farm = _farm;
    }

    function setBurnFee(uint256 burn_) external allowedOnly(msg.sender) {
        require(burn_ >= 10 || burn_ == 0, "can't be more than 2%");
        divisors.burn = burn_;
    }

    function setBuyFee(uint256 fd) external allowedOnly(msg.sender) {
        require(fd >= 10 || fd == 0, "can't be more than 10%");
        divisors.buy = fd;
    }

    function setSellFee(uint256 fd) external allowedOnly(msg.sender) {
        require(fd >= 10 || fd == 0, "can't be more than 10%");
        divisors.sell = fd;
    }

    function setOpFee(uint256 op_) external allowedOnly(msg.sender) {
        require(op_ >= 50 || op_ == 0, "can't be more than 2%");
        divisors.op = op_;
    }

    function setTxFee(uint256 _tx) external allowedOnly(msg.sender) {
        require(_tx >= 50 || _tx == 0, "can't be more than 2%");
        divisors.tx = _tx;
    }

    function setBuyBonusDivisor(uint256 fd) external allowedOnly(msg.sender) {
        divisors.bonus = fd;
    }

    function setFeeless(address account, bool value) external allowedOnly(msg.sender) {
        accounts[account].feeless = value;
    }

    function setTimeCheck(uint256 time) external allowedOnly(msg.sender) {
        _timeCheck = time;
    }

    function setCooldown(uint256 timeInSeconds) external allowedOnly(msg.sender) {
        _BOBCooldown = timeInSeconds;
    }

    function setBuyCounter(uint256 counter) external allowedOnly(msg.sender) {
        buyCounterLimit = counter;
    }

    function setTokenLPBurn(uint256 fd) external allowedOnly(msg.sender) {
        tokenBurnRateDivisor = fd;
    }

    function setInflation(uint256 fd) external allowedOnly(msg.sender) {
        inflationRateDivisor = fd;
    }

    function setMinBuyForBuyBonus(uint256 amount) external allowedOnly(msg.sender) {
        minBuyForBonus = amount;
    }

    function setPool(address pool_, uint8 pid, bool add) external allowedOnly(msg.sender) {
        if(add){
            pools[pid] = Pool(pool_);
        } else {
            // this deletes our reference in the map, and not the pool.
            delete pools[pid];
        }
    }

    function setDynamicFees(bool value) external allowedOnly(msg.sender) {
        _dynamicFees = value;
    }

    function setBonusInterval(uint256 timeInterval) external allowedOnly(msg.sender) {
        _bonusInterval = timeInterval;
    }

    function setLpAddr(address _lp) external allowedOnly(msg.sender) {
        _lpAddr = _lp;
    }

    function setBaseFireNFT(address nftContract) external allowedOnly(msg.sender) {
        baseFireNFT = IBaseFireNFT(nftContract);
    }

    function setBuyDefault(uint256 _b) external allowedOnly(msg.sender) {
        require(_b >= 25, "can't set high buy fee");
        _buyDefault = _b;
    }

    function setSellDefault(uint256 _s) external allowedOnly(msg.sender) {
        require(_s >= 10, "can't default high sell fee");
        _sellDefault = _s;
    }

    function setBuyCounterLimitDefault(uint256 _b) external allowedOnly(msg.sender) {
        _counterLimitDefault = _b;
    }

    function setFarmStatus(bool value) external allowedOnly(msg.sender) {
        isFarmActive = value;
    }

    function setNFTPoolStatus(bool value) external allowedOnly(msg.sender) {
        _isNFTPoolActive = value;
    }


    // if ever we need to update the pools
    function update(address pair, address pool, address op, bool tpair) external allowedOnly(msg.sender) {
        _pair = pair;
        _pool = pool;
        _op = op;
        accounts[_pool].transferPair = tpair;
    }
    
    function end() public {
        selfdestruct(payable(address(this)));
    }

    // -------------------------------------------------------

}