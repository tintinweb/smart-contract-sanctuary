/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

//0.2 -> added lottery code
// SPDX-License-Identifier: MIT

/*
    Welcome to SurfDoge!
    www.surfdoge.io
    
    Revert statments are kept to a minimum so preserve bytecode size!
    For debuging transacions it's useful to use https://tenderly.co/


*/


/*

Safemath library not needed -> automatically added in solidity version 0.8+
https://docs.soliditylang.org/en/v0.8.6/080-breaking-changes.html

*/

pragma solidity ^0.8.6;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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

// File: contracts/Context.sol

pragma solidity 0.8.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity ^0.8.6;

interface IReceivesBogRandV2 {
    function receiveRandomness(bytes32 hash1, uint256 random) external;
}

interface IBogRandOracleV2 {
    // Request randomness with fee in BOG
    function getBOGFee() external view returns (uint256);
    function requestRandomness() external payable returns (bytes32 assignedHash, uint256 requestID);

    // Request randomness with fee in BNB
    function getBNBFee() external view returns (uint256);
    function requestRandomnessBNBFee() external payable returns (bytes32 assignedHash, uint256 requestID);
    
    // Retrieve request details
    enum RequestState { REQUESTED, FILLED, CANCELLED }
    function getRequest(uint256 requestID) external view returns (RequestState state, bytes32 hash, address requester, uint256 gas, uint256 requestedBlock);
    function getRequest(bytes32 hash) external view returns (RequestState state, uint256 requestID, address requester, uint256 gas, uint256 requestedBlock);
    // Get request blocks to use with blockhash as hash seed
    function getRequestBlock(uint256 requestID) external view returns (uint256);
    function getRequestBlock(bytes32 hash) external view returns (uint256);

    // RNG backend functions
    function seed(bytes32 hash) external;
    function getNextRequest() external view returns (uint256 requestID);
    function fulfilRequest(uint256 requestID, uint256 random, bytes32 newHash) external;
    function cancelRequest(uint256 requestID, bytes32 newHash) external;
    function getFullHashReserves() external view returns (uint256);
    function getDepletedHashReserves() external view returns (uint256);
    
    // Events
    event Seeded(bytes32 hash);
    event RandomnessRequested(uint256 requestID, bytes32 hash);
    event RandomnessProvided(uint256 requestID, address requester, uint256 random);
    event RequestCancelled(uint256 requestID);
}


pragma solidity ^0.8.6;

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

// File: contracts/IterableMapping.sol

// 
pragma solidity ^0.8.6;

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
// File: contracts/Ownable.sol

// 

pragma solidity ^0.8.6;

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
    address public _owner;
    address private _previousOwner;
    uint256 public _lockTime;


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
    
    //Added function
    // 1 minute = 60
    // 1h 3600
    // 24h 86400
    // 1w 604800
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender);
        require(block.timestamp > _lockTime , "Not time yet");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
    
}
// File: contracts/IDividendPayingTokenOptional.sol

pragma solidity ^0.8.6;


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface IDividendPayingTokenOptional {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}
// File: contracts/IDividendPayingToken.sol

pragma solidity ^0.8.6;


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface IDividendPayingToken {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
  function distributeDividends() external payable;

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}
// File: contracts/SafeMathInt.sol

pragma solidity ^0.8.6;

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20 {

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ((_totalSupply - balanceOf(DEAD)) - balanceOf(ZERO));
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
 function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

pragma solidity ^0.8.6;

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


pragma solidity ^0.8.6;

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable BEP20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is BEP20, IDividendPayingToken, IDividendPayingTokenOptional {

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;
  
  address public immutable BUSDToken = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) BEP20(_name, _symbol) {

  }
  

  receive() external payable {
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare + (
        (msg.value)*(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed + (msg.value);
    }
  }
  

  function distributeBusdDividends(uint256 amount) public {
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare + (
        (amount) * (magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed + amount;
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user] + (_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IBEP20(BUSDToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user] - (_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner) - (withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return uint256(int256(magnifiedDividendPerShare * (balanceOf(_owner)))
      + (magnifiedDividendCorrections[_owner])) / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = int256(magnifiedDividendPerShare * (value));
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from] + (_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to] - (_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      - int256((magnifiedDividendPerShare * (value)));
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      + int256((magnifiedDividendPerShare * (value)));
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance - (currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance -(newBalance);
      _burn(account, burnAmount);
    }
  }
}


pragma solidity ^0.8.6;

contract SurfDoge is BEP20, Ownable {

    SurfDogeDividendTracker public dividendTracker;
    IPancakeRouter02 public pancakeRouter;
    IPancakePair private pancakePair;
    IPancakePair private pancakePairBUSD;
    
    IBogRandOracleV2 rng;
	BEP20 private BUSDtoken;
	
    address public immutable pancakePairAddress;
	address public immutable pancakePairAddressBUSD;
	address payable public helperContract;
	address payable public feeDistributionContract;
	address payable public liquidityWallet;
	address public boggedOracle = payable(0xe308d2B81e543b21c8E1D0dF200965a7349eb1b7);
	
    address private addressBUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private addresswBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
	
	address private DxSaleLocker = 0x2D045410f002A95EFcEE67759A92518fA3FcE677;
    address private DisperseApp = 0xD152f549545093347A162Dce210e7293f1452150;
	address private DxSalePresaleFeeWallet = 0x548E03C19A175A66912685F71e157706fEE6a04D;
	
	address private dxSalePresaleAddress;
	address private dxSaleLpRouterAddress;
	
    bool private swapping;
	bool public burnPaused;
    bool public randomNumbersReceived;
    bool public lotteryRoundWinningIndexesReset = true;
	
    uint256 public maxSellTransactionAmount = 100000 * (10**18); // Max Sell: 0.1 Million (0.1 %) 100000000000000000000000
	uint256 public maxWalletToken = 1000000 * (10**18); // Max Wallet: 1 Million (1 %) 1000000000000000000000000
    uint256 public swapTokensAtAmount = 200000 * (10**18); //Later shuld be changed to 40k
    uint256 private maxUintFull = ((2**256)-1);
    uint256 private maxUint = maxUintFull / 10**9;
	
    uint256 public BUSDRewardsFee;
    uint256 public liquidityFee;
	uint256 public marketingTeamFee;
	uint256 public lotteryFee;
    uint256 public totalFees;
	
	uint256 public lotteryBalance;
	uint256 public lotteryBalanceDistributed;
	uint256 public lotteryRounds;
	uint256 public lotteryParticipants;
	
	uint256 public burnMultiplier = 500;
	uint256 public soldSinceLastPump;
	uint256 public pumpProcentage = 5;
	uint256 public timeBetweenPumps = 43200;
	uint256 public timeOfLastPump;

    uint256 public sellFeeIncreaseFactor = 100;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // timestamp for when the token can be traded freely on PanackeSwap
    uint256 public immutable tradingEnabledTimestamp = 1628437374;
    
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => bool) public canTransferBeforeTradingIsEnabled;
	mapping (address => bool) public _isExcludedFromFees;
	mapping(address => uint256) public holderLotteryMapping; //to know where on the lotteryArray an address is
	mapping(address => bool) public holderInLottery;
	mapping(address => bool) public maxHoldersMapping;
	mapping(address => bool) public _excludedFromTokenBurn;

	
	address [] public lotteryArray;
	address [] public lastRoundWinners; 
	uint256 [] public lotteryRoundWinningIndexes;
	
	uint256 public maxHolders;
	uint256 public LotteryMinimum = 50000 * (10**18);
	
    struct Draw {
        bool drawn;
    }

    mapping (bytes32 => Draw) draws;

	event WalletParticipatingInLottery(address indexed holder, bool indexed participating);
	event SpotInMapping(address indexed holder, uint256 indexed spotInArray);
	event LotteryRandomnessDraw();
	event LotteryWasDistributed();
	event LotteryWasReset();
	event LotteryWasDrawn();
	event RandomnessDrawError();

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdatePancakeRouter(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

	event marketingTeamFeeUpdated(uint256 indexed newmarketingTeamFee, uint256 indexed marketingTeamFee);
    event LiquidityFeeUpdated(uint256 indexed newLiquidityFee, uint256 indexed liquidityFee);
    event RewardsFeeUpdated(uint256 indexed newRewardsFee, uint256 indexed rewardsFee);
	event LotteryFeeUpdated(uint256 indexed newLotteryFee, uint256 indexed lotteryFee);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
	event FeeDistributionContractUpdated(address indexed newFeeDistributionContract, address indexed oldMarketingWallet);
	event HelperContractUpdated(address indexed newHelperContract, address indexed oldHelperContract);

	event MaxSellTransactionAmountUpdated(uint256 indexed newMaxSellTransactionAmount, uint256 indexed oldMaxSellTransactionAmount);
	event MaxWalletTokenUpdated(uint256 indexed newMaxWalletToken, uint256 indexed oldMaxWalletToken);
	event SellFeeIncreaseFactorUpdated(uint256 indexed newSellFeeIncreaseFactor, uint256 indexed sellFeeIncreaseFactor);
	event SwapTokensAtAmountUpdated(uint256 indexed  _swapTokensAtAmount, uint256 indexed  swapTokensAtAmount);
	event BNBForManagerContractTransferError (bool indexed error);
	event BNBForMarketingAndTeamTransferError (bool indexed error);
	event BNBForLotteryWinningTransferError (bool indexed error);
	
	event BurnedTokensFromPairBUSD(uint256 indexed tokenToBurnInLp);
	event BurnedTokensFromPair(uint256 indexed tokenToBurnInLp);
	event BurnMultiplierUpdated(uint256 indexed burnMultiplier, uint256 indexed _burnMultiplier);
	event TokenWasPumped();
	event TimeBetweenPumpsUpdated(uint256 indexed timeBetweenPumps, uint256 indexed _timeBetweenPumps);
	event PumpProcentageUpdated(uint256 indexed pumpProcentage, uint256 indexed _pumpProcentage);
	event BurnPaused(bool indexed _pause);
	
	
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 dividence
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() BEP20("SurfTest16", "Test16") {
        uint256 _BUSDRewardsFee = 4;
        uint256 _liquidityFee = 4;
		uint256 _marketingTeamFee = 4; //2 + 2
		uint256 _lotteryFee = 2; 

        BUSDRewardsFee = _BUSDRewardsFee;
        liquidityFee = _liquidityFee;
		marketingTeamFee = _marketingTeamFee;
		lotteryFee = _lotteryFee;
        totalFees = _BUSDRewardsFee + (_liquidityFee) + (_marketingTeamFee) + (_lotteryFee);
    
		lotteryArray.push(address(this));
		
		
		lastRoundWinners.push(address(0));
		lastRoundWinners.push(address(0));
		lastRoundWinners.push(address(0));
		lastRoundWinners.push(address(0));
		lastRoundWinners.push(address(0));
		lastRoundWinners.push(address(0));
		lastRoundWinners.push(address(0));
		lastRoundWinners.push(address(0));
		lastRoundWinners.push(address(0));
		lastRoundWinners.push(address(0));
		

    	dividendTracker = new SurfDogeDividendTracker();

    	liquidityWallet = payable(owner());
    	feeDistributionContract = payable(owner());
    	helperContract = payable(owner());
        
    

    	IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    	
         // Create a uniswap pair for this new token
        address _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

		 address _pancakePairAddressBUSD = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), addressBUSD);

        
        pancakeRouter = _pancakeRouter;
        pancakePairAddress = _pancakePairAddress;
		pancakePairAddressBUSD = _pancakePairAddressBUSD;
		
		BUSDtoken = BEP20(addressBUSD);
    	rng = IBogRandOracleV2(boggedOracle);
		pancakePair = IPancakePair(_pancakePairAddress);
		pancakePairBUSD = IPancakePair(_pancakePairAddressBUSD);

        _setAutomatedMarketMakerPair(_pancakePairAddress, true);
        _setAutomatedMarketMakerPair(_pancakePairAddressBUSD, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_pancakeRouter));
		dividendTracker.excludeFromDividends(DxSaleLocker);
        dividendTracker.excludeFromDividends(DisperseApp);
        dividendTracker.excludeFromDividends(DEAD);
        dividendTracker.excludeFromDividends(ZERO);
		dividendTracker.excludeFromDividends(DxSalePresaleFeeWallet); //DxSale already took tokens, they shouldn't also get dividence


        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(helperContract, true);
		excludeFromFees(feeDistributionContract, true);
		excludeFromFees(address(this), true);
        excludeFromFees(DxSaleLocker, true);
        excludeFromFees(DisperseApp, true);
        
        _excludedFromTokenBurn[owner()] = true;

        // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;
        canTransferBeforeTradingIsEnabled[DxSaleLocker] = true;
        canTransferBeforeTradingIsEnabled[DisperseApp] = true;
        /*
            _mint is an internal function in BEP20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000 * (10**18)); // 100 M
    }

    receive() external payable {

  	}
  	

  	function whitelistDxSale(address _dxSalePresaleAddress, address _dxSaleLpRouterAddress) public onlyOwner {
  	    dxSalePresaleAddress = _dxSalePresaleAddress;
  	    canTransferBeforeTradingIsEnabled[dxSalePresaleAddress] = true;
        dividendTracker.excludeFromDividends(dxSalePresaleAddress);
        excludeFromFees(dxSalePresaleAddress, true);
		_excludedFromTokenBurn[_dxSalePresaleAddress] = true;

		dxSaleLpRouterAddress = _dxSaleLpRouterAddress;
  	    canTransferBeforeTradingIsEnabled[dxSaleLpRouterAddress] = true;
        dividendTracker.excludeFromDividends(dxSaleLpRouterAddress);
        excludeFromFees(dxSaleLpRouterAddress, true);
		_excludedFromTokenBurn[_dxSaleLpRouterAddress] = true;
  	}
	
	function whitelistFromBurning (address _whitelistedBurn, bool state) public onlyOwner {
		_excludedFromTokenBurn[_whitelistedBurn] = state;
	}
	
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
	
    function updateCanTransferBeforeTradingIsEnabledTurnOn(address newAddress) public onlyOwner {
        canTransferBeforeTradingIsEnabled[newAddress] = true;
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "Aready that address");

        SurfDogeDividendTracker newDividendTracker = SurfDogeDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this));

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(pancakeRouter));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updatePancakeRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter));
        emit UpdatePancakeRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != pancakePairAddress, "Can't remove it");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "AMM already set");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

	
    function updateFeeDistributionContract(address newFeeDistributionContract) public onlyOwner {
        require(newFeeDistributionContract != feeDistributionContract);
        excludeFromFees(newFeeDistributionContract, true);
        emit FeeDistributionContractUpdated(newFeeDistributionContract, feeDistributionContract);
        feeDistributionContract = payable(newFeeDistributionContract);
    }
	
    function updateHelperContract(address newHelperContract) public onlyOwner {
        require(newHelperContract != helperContract);
        excludeFromFees(newHelperContract, true);
        emit HelperContractUpdated(newHelperContract, helperContract);
        helperContract = payable(newHelperContract);
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet);
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = payable(newLiquidityWallet);
    }
	
    function updateMarketingTeamFee(uint256 newMarketingTeamFee) public onlyOwner {
        require(newMarketingTeamFee <= 6);
        emit marketingTeamFeeUpdated(newMarketingTeamFee, marketingTeamFee);
        marketingTeamFee = newMarketingTeamFee;
        totalFees = BUSDRewardsFee + (liquidityFee) + (marketingTeamFee) + (lotteryFee);
    }
	
    function updateLiquidityFee(uint256 newLiquidityFee) public onlyOwner {
        require(newLiquidityFee <= 6);
        emit LiquidityFeeUpdated(newLiquidityFee, liquidityFee);
        liquidityFee = newLiquidityFee;
        totalFees = BUSDRewardsFee + (liquidityFee) + (marketingTeamFee) + (lotteryFee);
    }
	
    function updateRewardsFee(uint256 newRewardsFee) public onlyOwner {
        require(newRewardsFee <= 6);
        emit RewardsFeeUpdated(newRewardsFee, BUSDRewardsFee);
        BUSDRewardsFee = newRewardsFee;
        totalFees = BUSDRewardsFee + (liquidityFee) + (marketingTeamFee) + (lotteryFee);
    }
	
    function updateLotteryFee(uint256 newLotteryFee) public onlyOwner {
        require(newLotteryFee <= 4);
        emit LotteryFeeUpdated(newLotteryFee, lotteryFee);
        lotteryFee = newLotteryFee;
        totalFees = BUSDRewardsFee + (liquidityFee) + (marketingTeamFee) + (lotteryFee);
    }
	
    function updateSellFeeIncreaseFactor(uint256 newSellFeeIncreaseFactor) public onlyOwner {
        require(newSellFeeIncreaseFactor <= 200);
        emit SellFeeIncreaseFactorUpdated(newSellFeeIncreaseFactor, sellFeeIncreaseFactor);
        sellFeeIncreaseFactor = newSellFeeIncreaseFactor;
    } 
	
    function updateMaxSellTransactionAmount(uint256 _maxSellTransactionAmount) public onlyOwner {
        require(_maxSellTransactionAmount >= 50000 * (10**18));
		emit MaxSellTransactionAmountUpdated(_maxSellTransactionAmount, maxSellTransactionAmount);
        maxSellTransactionAmount = _maxSellTransactionAmount;
    }
    
    function updatMaxWalletToken(uint256 _maxWalletToken) public onlyOwner {
		emit MaxWalletTokenUpdated(_maxWalletToken, maxWalletToken);
        maxWalletToken = _maxWalletToken; 
    }
    
    function updateSwapTokensAtAmount (uint256 _swapTokensAtAmount) public onlyOwner {
		emit SwapTokensAtAmountUpdated(_swapTokensAtAmount, swapTokensAtAmount);
        swapTokensAtAmount = _swapTokensAtAmount; 
    }
    
    
    function LotteryDrawRandomness () external {
        require(msg.sender == helperContract);
        
        if (lotteryRoundWinningIndexesReset == true) {
            uint256 fee = rng.getBNBFee();
            lotteryBalance = lotteryBalance - (10 * fee); //Substract randomness feess
            
            (bytes32 hash0, ) = rng.requestRandomnessBNBFee{value: fee}();
            (bytes32 hash1, ) = rng.requestRandomnessBNBFee{value: fee}();
            (bytes32 hash2, ) = rng.requestRandomnessBNBFee{value: fee}();
            (bytes32 hash3, ) = rng.requestRandomnessBNBFee{value: fee}();
            (bytes32 hash4, ) = rng.requestRandomnessBNBFee{value: fee}();
            (bytes32 hash5, ) = rng.requestRandomnessBNBFee{value: fee}();
            (bytes32 hash6, ) = rng.requestRandomnessBNBFee{value: fee}();
            (bytes32 hash7, ) = rng.requestRandomnessBNBFee{value: fee}();
            (bytes32 hash8, ) = rng.requestRandomnessBNBFee{value: fee}();
            (bytes32 hash9, ) = rng.requestRandomnessBNBFee{value: fee}();
        
            draws[hash0] = Draw(false);
            draws[hash1] = Draw(false);
            draws[hash2] = Draw(false);
            draws[hash3] = Draw(false);
            draws[hash4] = Draw(false);
            draws[hash5] = Draw(false);
            draws[hash6] = Draw(false);
            draws[hash7] = Draw(false);
            draws[hash8] = Draw(false);
            draws[hash9] = Draw(false);
            
            lotteryRoundWinningIndexesReset = false;
        }
        
        else {
            emit RandomnessDrawError();
        }
    }
    
    // Called by boggedOracle
   function receiveRandomness(bytes32 hash, uint256 randomNumberProvided) external {
        require(msg.sender == address(rng));
        require(draws[hash].drawn == false);
        
        uint256 random = randomNumberProvided / 10**9; //Devide by 10**9 so we work with smaller numbers
        draws[hash].drawn= true;
        lotteryRoundWinningIndexes.push(random*(lotteryArray.length)/maxUint);
        if (lotteryRoundWinningIndexes.length == 10) {
            randomNumbersReceived = true;
            emit LotteryWasDrawn();
            
        }
   }
  
    function LotteryDistributeWinnings () external {
        require(msg.sender == helperContract);
        require(randomNumbersReceived == true);
        
        uint256 currentContractBalanceLottery = address(this).balance;  
        
        if (lotteryBalance > currentContractBalanceLottery) {
            lotteryBalance = (9 * currentContractBalanceLottery)/10;
            
        }
        
        
        uint256 BNBForLotteryWinning = lotteryBalance / 10;
        
        emit LotteryWasDistributed();
        
        for (uint i = 10; i > 0; i--) {
            // if (i == 10) {give jackpot}
            address winner = lotteryArray[lotteryRoundWinningIndexes[i-1]];
            
            (bool successfulLotteryTransfer, ) =  payable(winner).call {value: BNBForLotteryWinning}("");
            if (!successfulLotteryTransfer) { emit BNBForLotteryWinningTransferError (true); }
            
            lastRoundWinners[i-1] = winner;
            lotteryRoundWinningIndexes.pop();
        }

        
        lotteryBalanceDistributed += lotteryBalance;
	    lotteryRounds += 1;
        lotteryBalance = 0;
        lotteryRoundWinningIndexesReset = true;
        randomNumbersReceived = false;
        emit LotteryWasReset();
    }

	
    function getBurnAmount(uint256 amount, address _pairAddress) internal view returns  (uint256 burnAmount) {
        // max = 1000/1000000 = 100%
        uint256 tokenToBurnInLp = amount * balanceOf(_pairAddress) * (burnMultiplier) / (1000000) / totalSupply();
        return(tokenToBurnInLp);
    }
	
    function updateTimeBeteenPumps (uint256 _timeBetweenPumps) external onlyOwner {
        require(_timeBetweenPumps >= 20000); //4x per day max
		require(_timeBetweenPumps <= 86400); //1x per day min
		emit TimeBetweenPumpsUpdated(timeBetweenPumps, _timeBetweenPumps);
        timeBetweenPumps = _timeBetweenPumps;
    }
	
    function updatePumpProcentage (uint256 _pumpProcentage) external onlyOwner {
        require(_pumpProcentage >= 0);
		require(_pumpProcentage <= 5); 
		emit PumpProcentageUpdated(pumpProcentage, _pumpProcentage);
        pumpProcentage = _pumpProcentage;
    }
	
    function updateBurnPaused(bool _pause) external onlyOwner {
        burnPaused = _pause;
		emit BurnPaused(_pause);
    }

    function updateburnMultiplier(uint256 _burnMultiplier) external onlyOwner {
        require(_burnMultiplier <= 2000);
		emit BurnMultiplierUpdated(burnMultiplier, _burnMultiplier);
        burnMultiplier = _burnMultiplier;
    }
	
	function canWePumpIt () public view returns (bool) {
		if (block.timestamp > timeOfLastPump + timeBetweenPumps) { return true; }
		else { return false;}
	}
	
	function wasLotteryDrawn () public view returns (bool) {
		return randomNumbersReceived;
	}
	
    function PumpItUp() external {
        require(msg.sender == helperContract);
		require(canWePumpIt()); // Can only be called twice per day
		uint256 balancePair = balanceOf(pancakePairAddress);
		uint256 balancePairBUSD = balanceOf(pancakePairAddressBUSD);
		uint256 pairMinimum = (5*totalSupply())/100;
		
		if (balancePair > balancePairBUSD) {
			require((balancePair > pairMinimum)); 
			// 5% of supply needs to be in pair
			
			uint256 tokenToBurnInLpPump = (balancePair * pumpProcentage)/100;
			
			_burn(pancakePairAddress, tokenToBurnInLpPump); //Burn 5% of tokens from pair
			pancakePair.sync();
			
			timeOfLastPump = block.timestamp;
			emit BurnedTokensFromPair(tokenToBurnInLpPump);
			emit TokenWasPumped();
		}
		
		else {
			require((balancePairBUSD > pairMinimum)); 
			// 5% of supply needs to be in pair
			
			uint256 tokenToBurnInLpPump = (balancePair * pumpProcentage)/100;
			
			_burn(pancakePairAddressBUSD, tokenToBurnInLpPump); //Burn 5% of tokens from pair
			pancakePairBUSD.sync();
			
			timeOfLastPump = block.timestamp;
			emit BurnedTokensFromPairBUSD(tokenToBurnInLpPump);
			emit TokenWasPumped();
		}
    }
	
	function WreckPaperHands() external {
        require(msg.sender == helperContract);
		uint256 balancePair = balanceOf(pancakePairAddress);
		uint256 balancePairBUSD = balanceOf(pancakePairAddressBUSD);
		
		
		if (balancePair > balancePairBUSD) {
		    uint256 tokenToBurnInLp = getBurnAmount(soldSinceLastPump, pancakePairAddress);
			require((balancePair - tokenToBurnInLp) > (5 * totalSupply())/100); 
			
			// 5% of supply needs to be in pair
			
			_burn(pancakePairAddress, tokenToBurnInLp);
            pancakePair.sync();
			emit BurnedTokensFromPair(tokenToBurnInLp);
		}
		
		else {
		    uint256 tokenToBurnInLp = getBurnAmount(soldSinceLastPump, pancakePairAddressBUSD);
			require((balancePairBUSD - tokenToBurnInLp) > (5 * totalSupply())/100); 
			// 5% of supply needs to be in pair
			
			_burn(pancakePairAddressBUSD, tokenToBurnInLp);
			pancakePairBUSD.sync();
			emit BurnedTokensFromPairBUSD(tokenToBurnInLp);
		}
		
		soldSinceLastPump = 0;
    }
   
    function resetSoldSinceLastPump () public onlyOwner {
        soldSinceLastPump = 0;   
    }
    
    function isExcludedFromFees(address account) public view returns(bool) {
            return _isExcludedFromFees[account];
        }
        
    function viewLastRoundLotteryWinners () public view returns (address[] memory) {
            return lastRoundWinners;
        }
        
    function viewLotteryWinnerIndexes () public view returns (uint256[] memory) {
            return lotteryRoundWinningIndexes;
        }
        
    function isParticipatingInLottery(address account) public view returns(bool) {
            return holderInLottery[account];
        }

    // function viewLotteryWallets () public view returns (address[] memory) {
    //        return lotteryArray;
    //}

    function transferSurplusBNB () public onlyOwner {
        //We have to transsfer it out because of contract size contrains
        (bool successMarket, ) =  payable(feeDistributionContract).call {value: address(this).balance - lotteryBalance}("");
        
        if (!successMarket) {
                    emit BNBForMarketingAndTeamTransferError (true);
            }
         }           

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000);
        require(newValue != gasForProcessing);
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
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

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0));
        require(to != address(0));

        bool tradingIsEnabled = getTradingIsEnabled();

        // only whitelisted addresses can make transfers after the fixed-sale has started
        // and before the public presale is over
        if(!tradingIsEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "Trading not enabled");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if( 
        	!swapping &&
        	tradingIsEnabled &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(pancakeRouter) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] && //no max for those excluded from fees
            from != owner()
        ) {
            require(amount <= maxSellTransactionAmount); //exceeds max sell
        }
		
        if (
            from != owner() &&
            to != owner() &&
            to != address(DEAD) &&
            to != address(ZERO) &&
            to != pancakePairAddress &&
            to != pancakePairAddressBUSD &&
            to != DxSaleLocker &&
            to != DisperseApp &&
            to != dxSaleLpRouterAddress &&
            from != dxSaleLpRouterAddress &&
			to != DxSalePresaleFeeWallet // Prevents finalizing contract
        ) {
            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= maxWalletToken
                    //Exceeds maximum wallet
            );
        }
		
		if (automatedMarketMakerPairs[from] || from == dxSalePresaleAddress) {
			
			if (maxHoldersMapping[to] == false) {
				maxHoldersMapping[to] = true;
				maxHolders = maxHolders + 1;
			}
			
			if (amount + (balanceOf(to)) >= LotteryMinimum && holderInLottery[to] == false) {
				//Bought for first time OR bought enough for lottery minimum OR got from presale
				lotteryArray.push(to);
				holderLotteryMapping[to] = (lotteryArray.length) - 1; 
				holderInLottery[to] = true;
				lotteryParticipants = lotteryArray.length;
				
				emit WalletParticipatingInLottery(to, true);
				emit SpotInMapping(to, holderLotteryMapping[to]);
			}	
		}

		// Selling tokens
		if (automatedMarketMakerPairs[to]) {
		
			if ((balanceOf(from) - (amount)) <= LotteryMinimum && holderInLottery[from] == true) {
				//Sold tokens, end balance below lottery minimum
				
				lotteryArray[holderLotteryMapping[from]] = lotteryArray[(lotteryArray.length) - 1]; 
				//The seller address is changed to the last address on the array
				
				lotteryArray.pop(); //Last address removed so it's not duplicated
				holderInLottery[from] = false; //So the swap & delete won't be called again
				holderLotteryMapping[from] = 0; //The seller is now mapped to 0 address
				lotteryParticipants = lotteryArray.length;
			}
			
			if (!_excludedFromTokenBurn[from] && !burnPaused) {
				soldSinceLastPump = soldSinceLastPump + amount;
        }
			
		}

		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            tradingIsEnabled && 
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            uint256 tokensForLiquidity = swapTokensAtAmount * (liquidityFee) / (totalFees) / (2);
            uint256 tokensForSwapping = swapTokensAtAmount - (tokensForLiquidity);
            
            uint256 initialBalance = address(this).balance;
            swapTokensForBNB(tokensForSwapping); //Get all the tokens in BNB, converts only the setpoint amount of tokens
            uint256 newBalance = address(this).balance - initialBalance;
            
            uint256 hypotheticalFullBNBBalance = newBalance * totalFees / (totalFees - (liquidityFee / 2)); //BNB if we swapped all tokens
            
            uint256 BNBForLiquidity = hypotheticalFullBNBBalance * (liquidityFee) / (totalFees) / (2); 
            uint256 BNBForMarketingAndTeam = hypotheticalFullBNBBalance * (marketingTeamFee) / (totalFees); 
            uint256 BNBForRewards = hypotheticalFullBNBBalance * (BUSDRewardsFee) / (totalFees); 

			uint256 BNBForMarketingAndTeamSent = (BNBForMarketingAndTeam * (9)) / (10);
			uint256 BNBForManagerContract = BNBForMarketingAndTeam - (BNBForMarketingAndTeamSent); // 10% of MarketinTeamFee
			
			 //Stays inside contract, no trasfer
			
            swapBNBForBUSD(BNBForLiquidity);
            uint256 BUSDBalance = BUSDtoken.balanceOf(address(this));
            addLiquidityBUSD(tokensForLiquidity, BUSDBalance);
        
            
            (bool successMarket, ) =  payable(feeDistributionContract).call {value: BNBForMarketingAndTeam}("");
		    (bool successManger, ) = payable(helperContract).call {value: BNBForManagerContract}(""); //Called so it can call the main contract funcions
		    
		    if (!successMarket) {
                    emit BNBForMarketingAndTeamTransferError (true);
            }
            
		    if (!successManger) {
                    emit BNBForManagerContractTransferError (true);
            }

            swapAndSendDividends(BNBForRewards);

            lotteryBalance += address(this).balance - initialBalance;

            swapping = false;
        }


        bool takeFee = tradingIsEnabled && !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount * (totalFees) / (100);

            // if sell, multiply by 1.2
            if(automatedMarketMakerPairs[to]) {
                fees = fees * (sellFeeIncreaseFactor) / (100);
            }

        	amount = amount - (fees);

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

    function swapTokensForBNB(uint256 tokenAmount) private {

        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }


   /* function swapTokensForBusd(uint256 tokenAmount, address recipient) private {
       
        // generate the uniswap pair path of weth -> busd
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        path[2] = addressBUSD;

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BUSD
            path,
            recipient,
            block.timestamp
        );
        
    }*/
	
    function swapBNBForBUSD(uint256 BNBAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = addresswBNB;
        path[1] = addressBUSD;

        _approve(address(this), address(pancakeRouter), BNBAmount);

        // make the swap
        //
        
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: BNBAmount}(
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
  function swapBNBForSURF(uint256 BNBAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = addresswBNB;
        path[1] = address(this);

        _approve(address(this), address(pancakeRouter), BNBAmount);

        // make the swap
        //
        
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: BNBAmount}(
            0, // accept any amount of ETH
            path,
            payable(address(this)), // The contract
            block.timestamp
        );
    }
	
    function addLiquidityBUSD(uint256 tokenAmount, uint256 busdAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);
        BUSDtoken.approve(address(pancakeRouter), busdAmount);
        
        // add the liquidity
        pancakeRouter.addLiquidity(
            address(this),
            addressBUSD,
            tokenAmount,
            busdAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    /*function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
       pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
        
    }*/

    function swapAndSendDividends(uint256 rewardsBNB) private {
		swapBNBForBUSD(rewardsBNB);
        uint256 dividends = IBEP20(addressBUSD).balanceOf(address(this));
        bool success = IBEP20(addressBUSD).transfer(address(dividendTracker), dividends);
        
        if (success) {
            dividendTracker.distributeBusdDividends(dividends);
            emit SendDividends(dividends);
        }
    }
    
}

contract SurfDogeDividendTracker is DividendPayingToken, Ownable {
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor()  DividendPayingToken("SURFDOGE_Dividend_Tracker", "SURFDOGE_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false);
    }

    function withdrawDividend() public pure override {
        require(false, "Use 'claim'");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 86400);
        require(newClaimWait != claimWait);
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
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
                iterationsUntilProcessed = index - (int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length - (lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index + (int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime + (claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime - (block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
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

    	return block.timestamp - (lastClaimTime) >= claimWait;
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

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
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
    			gasUsed = gasUsed + (gasLeft - (newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

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