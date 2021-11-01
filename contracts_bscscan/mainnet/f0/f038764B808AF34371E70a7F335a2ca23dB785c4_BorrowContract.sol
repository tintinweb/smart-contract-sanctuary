/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.17;


// Part: Bigfoot

interface Bigfoot {
  /// @dev Work on a (potentially new) position. Optionally send BNB back to Bank.
  function work(
    uint id,
    address user,
    uint debt,
    bytes calldata data
  ) external;


  /// @dev Return the amount of BNB wei to get back if we are to liquidate the position.
  function health(uint id) external view returns (uint);

  /// @dev Liquidate the given position to BNB. Send all BNB back to Bank.
  function liquidate(uint id) external;
}


// Part: OpenZeppelin/[email protected]/IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
     * > Note: Renouncing ownership will leave the contract without an owner,
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

// Part: OpenZeppelin/[email protected]/ReentrancyGuard

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// Part: OpenZeppelin/[email protected]/SafeMath

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// Part: Strategy

interface Strategy {
  /// @dev Execute worker strategy. Take LP tokens + BNB. Return LP tokens + BNB.
  /// @param user The original user that is interacting with the operator.
  /// @param debt The user's total debt, for better decision making context.
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address user,
    uint debt,
    bytes calldata data
  ) external payable;
}



// Part: Uniswap/[email protected]/IUniswapV2Pair

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


// Part: SafeToken

library SafeToken {
  function myBalance(address token) internal view returns (uint) {
    return IERC20(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint) {
    return IERC20(token).balanceOf(user);
  }

  function safeApprove(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeApprove');
  }

  function safeTransfer(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransfer');
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransferFrom');
  }

  function safeTransferBNB(address to, uint value) internal {
    (bool success, ) = to.call.value(value)(new bytes(0));
    require(success, '!safeTransferBNB');
  }
}

interface VaultInterface{
    function getPricePerFullShare() external view returns (uint);
    function depositAll() external;
    function deposit(uint _amount) external;
    function token() view external returns(IERC20);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


// Borrow Contract
contract BorrowContract is Ownable, ReentrancyGuard, Bigfoot {
  /// @notice Libraries
  using SafeToken for address;
  using SafeMath for uint;


  /// @notice Events
  event ModifyShare(uint indexed id, uint share);
  event Liquidate(uint indexed id, uint wad);

  /// @notice Immutable variables
  IUniswapV2Pair public lpToken;
  address public operator;
  address public vaultAddress;
  address public bankcurrency;
  address public fToken;


  /// @notice Mutable state variables
  mapping(uint => uint) public shares;
  mapping(address => bool) public okStrats;
  Strategy public addStrat;
  Strategy public liqStrat;

  constructor(address _vaultAddress, address _bankAddress, address _bankcurrency, address _liqstrat, address _addstrat) public {
    vaultAddress = _vaultAddress;
    operator = _bankAddress;
    bankcurrency = _bankcurrency;//0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
    liqStrat = Strategy(_liqstrat);
    addStrat = Strategy(_addstrat);
    okStrats[address(addStrat)] = true;
    okStrats[address(liqStrat)] = true;
    lpToken = IUniswapV2Pair(address(VaultInterface(vaultAddress).token()));

    fToken = lpToken.token0() == bankcurrency ? lpToken.token1(): lpToken.token0();
  }


  /// @dev Require that the caller must be the operator (the bank).
  modifier onlyOperator() {
    require(msg.sender == operator, 'not operator');
    _;
  }

  function lpToBalance(uint balance) public view returns (uint){
    uint pps = VaultInterface(vaultAddress).getPricePerFullShare();
    return balance.mul(1e18).div(pps);//TODO doublecheck perfect maths
  }

  function balanceToLp(uint balance) public view returns (uint){
    uint pps = VaultInterface(vaultAddress).getPricePerFullShare();
    return balance.mul(pps).div(1e18).mul(9997).div(10000);//TODO doublecheck perfect maths
  }

  /// @dev Work on the given position. Must be called by the operator.
  /// @param id The position ID to work on.
  /// @param user The original user that is interacting with the operator.
  /// @param debt The amount of user debt to help the strategy make decisions.
  /// @param data The encoded data, consisting of strategy address and calldata.
  function work(
    uint id,
    address user,
    uint debt,
    bytes calldata data
  ) external onlyOperator nonReentrant {
    // 1. Check Vault tokens before starting.
    uint256 bfrtokens = vaultAddress.myBalance();
    // 2. Perform the worker strategy; sending vault tokens + bankcurrency; expecting Vault tokens + bankcurrency.
    (address strat, uint vaultTokens, bytes memory ext) = abi.decode(data, (address, uint, bytes));
    if(vaultTokens>0) vaultAddress.safeTransferFrom(user, address(this), vaultTokens);
    require(okStrats[strat], 'unapproved work strategy');
    vaultAddress.safeTransfer(strat, shares[id]);
    bankcurrency.safeTransfer(strat, bankcurrency.myBalance());
    Strategy(strat).execute(user, debt, ext);
    // 3. Add shares to the record.
    uint aftrtokens = vaultAddress.myBalance();
    if(aftrtokens>bfrtokens)
      shares[id] = shares[id].add(aftrtokens.sub(bfrtokens));
    else shares[id] = shares[id].sub(bfrtokens.sub(aftrtokens));
    // 4. Return any remaining bankcurrency back to the operator.
    bankcurrency.safeTransfer(msg.sender, bankcurrency.myBalance());
    emit ModifyShare(id, shares[id]);
  }

  // @ dev these are stables, funtion is not needed at all
  function getMktSellAmount(
    uint aIn,
    uint rIn,
    uint rOut
  ) public pure returns (uint) {
    if (aIn == 0) return 0;
    require(rIn > 0 && rOut > 0, 'bad reserve values');
    uint aInWithFee = aIn.mul(997);
    uint numerator = aInWithFee.mul(rOut);
    uint denominator = rIn.mul(1000).add(aInWithFee);
    return numerator / denominator;
  }

  /// @dev Return the amount of BNB to receive if we are to liquidate the given position.
  /// @param id The position ID to perform health check.
  function health(uint id) external view returns (uint) {
    // 1. Get the position's LP balance and LP total supply.
    uint lpBalance = balanceToLp(shares[id]);
    uint lpSupply = lpToken.totalSupply(); // Ignore pending mintFee as it is insignificant
    // 2. Get the pool's total supply of WBNB and farming token.
    (uint r0, uint r1, ) = lpToken.getReserves();
    (uint totalBankCurrency, uint totalBtc) = lpToken.token0() == bankcurrency ? (r0, r1) : (r1, r0);
    // 3. Convert the position's LP tokens to the underlying assets.
    uint userBankCurrency = lpBalance.mul(totalBankCurrency).div(lpSupply);
    uint userBtc = lpBalance.mul(totalBtc).div(lpSupply);
    // 4. Convert all farming tokens to BNB and return total BNB.
    return
      getMktSellAmount(userBtc, totalBtc.sub(userBtc), totalBankCurrency.sub(userBankCurrency)).add(
        userBankCurrency
      );
  }


  /// @dev Liquidate the given position by converting it to BNB and return back to caller.
  /// @param id The position ID to perform liquidation
  function liquidate(uint id) external onlyOperator nonReentrant {
    // 1. Convert the position back to LP tokens and use liquidate strategy.
    vaultAddress.safeTransfer(address(liqStrat), shares[id]);
    liqStrat.execute(address(0), 0, abi.encode(fToken,0));
    // 2. Return all available BNB back to the operator.
    uint wad = bankcurrency.myBalance();
    bankcurrency.safeTransfer(msg.sender, wad);
    shares[id] = 0;
    emit ModifyShare(id, 0);
    emit Liquidate(id, wad);
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyOwner nonReentrant {
    require(token != vaultAddress, "rugs not allowed");
    token.safeTransfer(to, value);
  }


  /// @dev Set the given strategies' approval status.
  /// @param strats The strategy addresses.
  /// @param isOk Whether to approve or unapprove the given strategies.
  function setStrategyOk(address[] calldata strats, bool isOk) external onlyOwner {
    uint len = strats.length;
    for (uint idx = 0; idx < len; idx++) {
      okStrats[strats[idx]] = isOk;
    }
  }
  
  /// @dev Set liquidation strategy. Be extremely careful.
  function setCriticalStrat(address _liqstrat) external onlyOwner{
      liqStrat = Strategy(_liqstrat);
  }
}