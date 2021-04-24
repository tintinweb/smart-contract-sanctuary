/**
 *Submitted for verification at Etherscan.io on 2021-04-24
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Owned is Context {
    address private _owner;
    address private _operator;
    address private _pendingOwner;

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
        uint256 donationFee;
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
        uint256 burn;
        uint256 tx;
        uint256 donate;
    }

    struct Account {
        bool feeless;
        bool transferPair;
        bool excluded;
        uint256 tTotal;
        uint256 nTotal;
    }
}

contract MUSKITO is IERC20, Owned {

    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    IStates.Balances balances;
    IStates.Divisors divisors;
    ITValues.TState lastTState;

    EnumerableSet.AddressSet excludedAccounts;
    EnumerableSet.AddressSet blackListedBots;


    address private _op;
    address private _donations;
    address private _router;
    address public  _pool;
    address private _pair;

    uint256 private _lastFee;
    uint256 public buys;
    uint256 public burns;


    bool private _paused;
    bool private _lpAdded;

    mapping(address => IStates.Account) accounts;
    mapping(address => mapping(address => uint256)) allowances;

    constructor() {

        _name = "MUSKITO Token";
        _symbol = "MUSKITO";
        _decimals = 18;

        balances.tokenSupply = 1_000_000_000 ether;
        balances.networkSupply = (~uint256(0) - (~uint256(0) % balances.tokenSupply));

        divisors.tx = 50;    // 2%
        divisors.sell = 100;  // 1%
        divisors.buy = 100;   // 1%
        divisors.burn = 100; // 1%
        divisors.donate = 100;   // 1%

        _router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _op = address(0x9C5142ca89EAC453C1Eb9EF8d5E854ca01743F6e);
        _donations = address(0x9C5142ca89EAC453C1Eb9EF8d5E854ca01743F6e);
        _pair = IUniswapV2Router02(_router).WETH();
        _pool = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(address(this), _pair);
        _paused = true;

        EnumerableSet.add(blackListedBots, address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce));
        EnumerableSet.add(blackListedBots, address(0x000000000000084e91743124a982076C59f10084));
        EnumerableSet.add(blackListedBots, address(0x000000917de6037d52b1F0a306eeCD208405f7cd));
        EnumerableSet.add(blackListedBots, address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d));
        EnumerableSet.add(blackListedBots, address(0x7100e690554B1c2FD01E8648db88bE235C1E6514));
        EnumerableSet.add(blackListedBots, address(0x72b30cDc1583224381132D379A052A6B10725415));
        EnumerableSet.add(blackListedBots, address(0x9282dc5c422FA91Ff2F6fF3a0b45B7BF97CF78E7));
        EnumerableSet.add(blackListedBots, address(0x9eDD647D7d6Eceae6bB61D7785Ef66c5055A9bEE));
        EnumerableSet.add(blackListedBots, address(0xfad95B6089c53A0D1d861eabFaadd8901b0F8533));

        accounts[_msgSender()].feeless = true;
        accounts[_donations].feeless = true;
        accounts[_pool].transferPair = true;
        accounts[_msgSender()].nTotal = balances.networkSupply / 2;
        accounts[address(0)].nTotal = balances.networkSupply / 2;

        _approve(_msgSender(), _router, balances.tokenSupply);

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
        _rTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _rTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()] - amount);
        return true;
    }


    function whaleCheck(uint256 amount, address account) internal view {
        if(_paused) {
            require(amount <= (balances.tokenSupply / 2) / 100, "whale limit on");
            require(balanceOf(account) <= (balances.tokenSupply / 2) / 100, "already bought 500, wait till check off");
        }
    }

    // one way function, once called it will always be false.
    function enableTrading() external ownerOnly {
        _paused = false;
    }

    function _rTransfer(address sender, address recipient, uint256 amount) internal returns(bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!EnumerableSet.contains(blackListedBots, recipient), "fuck you bot");
        require(!EnumerableSet.contains(blackListedBots, msg.sender), "fuck you bot");
        if(sender == _pool) {
            whaleCheck(amount, recipient);
        }
        if(_paused){
            require(sender == owner() || recipient != _pool, "still paused");
        }
        uint256 rate = ratio();
        uint256 lpAmount = getCurrentLPBal();
        bool isFeeless = isFeelessTx(sender, recipient);
        (ITValues.TxValue memory t, ITValues.TState ts, ITValues.TxType txType) = calcT(sender, recipient, amount, isFeeless, lpAmount);
        balances.lpSupply = lpAmount;
        if(!isFeeless) {
            accounts[_donations].nTotal += (t.donationFee * rate);
            accounts[address(0)].nTotal += (t.burnFee) * rate;
            accounts[address(0)].tTotal += (t.burnFee);
            if(ts == ITValues.TState.Sell) {
                accounts[_donations].nTotal += (_lastFee) * rate;
                accounts[_donations].tTotal += (_lastFee);
                _lastFee = 0;
            } else if(ts == ITValues.TState.Buy) {
                accounts[recipient].nTotal += _lastFee * rate;
                buys++;
                _lastFee = 0;
            } else { // liq transfers
                accounts[address(0)].nTotal += (_lastFee * rate);
                _lastFee = 0;
            }
            _lastFee = t.sellFee + t.buyFee;
            balances.fees += t.fee;
            balances.networkSupply -= t.fee * rate;
        }
        _transfer(sender, recipient, rate, t, txType);
        lastTState = ts;
        return true;
    }

    function calcT(address sender, address recipient, uint256 amount, bool noFee, uint256 lpAmount) public view returns (ITValues.TxValue memory t, ITValues.TState ts, ITValues.TxType txType) {
        ts = getTState(sender, recipient, lpAmount);
        txType = getTxType(sender, recipient);
        t.amount = amount;
        if(!noFee) {
            if(!_paused) {
                t.fee = amount / divisors.tx;
                t.donationFee = amount / divisors.donate;
                t.burnFee = amount / divisors.burn;
                if(ts == ITValues.TState.Sell) {
                    t.sellFee = amount / divisors.sell;
                }
                if(ts == ITValues.TState.Buy) {
                    t.buyFee = amount / divisors.buy;
                }
            }
        }
        t.transferAmount = t.amount - t.fee - t.sellFee - t.buyFee - t.donationFee - t.burnFee;
        return (t, ts, txType);
    }

    function _transfer(address sender, address recipient, uint256 rate, ITValues.TxValue memory t, ITValues.TxType txType) internal {
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
        emit Transfer(sender, recipient, t.transferAmount);
    }

    function include(address account) external ownerOnly {
        require(accounts[account].excluded, "Account is already excluded");
        require(accounts[account].nTotal > 3 ether * ratio(), "not enough to include yourself");
        accounts[account].tTotal = 0;
        EnumerableSet.remove(excludedAccounts, account);
    }

    function exclude(address account) external ownerOnly {
        require(!accounts[account].excluded, "Account is already excluded");
        accounts[account].excluded = true;
        if(accounts[account].nTotal > 0) {
            accounts[account].tTotal = accounts[account].nTotal / ratio();
        }
        accounts[account].excluded = true;
        EnumerableSet.add(excludedAccounts, account);
    }

    function donate(uint256 amount) external {
        address sender = _msgSender();
        uint256 rate = ratio();
        require(!getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < accounts[sender].nTotal, "too much");
        accounts[sender].nTotal -= (amount * rate);
        accounts[_donations].nTotal -= (amount * rate);
        emit Transfer(msg.sender, _donations, amount);
    }

    function burn() external {
        require(buys >= 5000 * burns, "can't call yet");
        uint256 r = accounts[_pool].nTotal;
        uint256 rTarget = (r / 5); // 20%
        uint256 t = rTarget / ratio();
        accounts[_pool].nTotal -= rTarget;
        accounts[address(0)].nTotal += rTarget;
        emit Transfer(_pool, address(0), t);
        burns++;
        syncPool();
    }

    function burned() public view returns(uint256) {
        return balanceOf(address(0));
    }

    function isFeelessTx(address sender, address recipient) public view returns(bool) {
        return accounts[sender].feeless || accounts[recipient].feeless;
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

    function ratio() public view returns(uint256) {
        (uint256 n, uint256 t) = getCirculatingSupply();
        return n / t;
    }

    function syncPool() public  {
        IUniswapV2Pair(_pool).sync();
    }

}