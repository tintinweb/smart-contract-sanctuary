// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 *
 * Adapted from openzepplin Ownable
 */
abstract contract Ownable {
    address private _owner;
    bool private _isInitialized;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _Ownable_Initialize(address newOwner) internal {
        require(!_isInitialized, "DVF_ERROR: ALREADY_INITIALIZED");
        _owner = newOwner;
        _isInitialized = true;
        emit OwnershipTransferred(address(0), newOwner);
    }

    /**
    * @dev Returns the address of the user who originated the transaction
    */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.12;

import './uniswapv2/UniswapV2Pair.sol';
import './uniswapv2/UniswapV2ERC20.sol';
import './uniswapv2/interfaces/IERC20.sol';
import './uniswapv2/interfaces/IUniswapV2Factory.sol';
import './starkex/interfaces/IStarkEx.sol';
import './uniswapv2/libraries/SafeMath.sol';
import './Ownable.sol';

contract PairWithL2Overlay is UniswapV2Pair {
  using SafeMathUniswap for uint;
  uint internal constant delay = 1 days;
  bool public isLayer2Live;
  uint totalLoans;
  uint nonce;

  struct Withdrawal {
    uint amount;
    uint time;
  }

  mapping(address => Withdrawal) public delayedTransfers;

  event QueuedWithdrawal(address indexed from, uint value, uint indexed time, uint indexed deadline);
  event FalshMint(uint amount, uint quantizedAmount);

  // User to convey errors when enough balance requirement is not met
  error InsufficientBalance(uint256 available, uint256 required);

  modifier l2OperatorOnly() {
    if(isLayer2Live) {
      requireOperator();
    }
    _;
  }

  modifier operatorOnly() {
    requireOperator();
    _;
  }

  function getStarkEx() internal view returns (IStarkEx) {
    return IStarkEx(IUniswapV2Factory(factory).starkExContract());
  }
  function requireOperator() internal view {
    require(isOperator(), 'L2_TRADING_ONLY');
  }

  function isOperator() internal view returns(bool) {
    return IUniswapV2Factory(factory).operators(tx.origin);
  }

  function flashMint(
    uint amount,
    uint quantisedAmount,
    uint assetId, 
    uint tokenAssetId,
    uint tokenAmount,
    uint tokenBAssetId,
    uint tokenBAmount,
    address exchangeAddress) external operatorOnly returns(bool) {
    require(!isLocked(), "DVF: LOCK_IN_PROGRESS");
    // We mint on the pair itself
    // Then deposit into starkEx valut
    _mint(address(this), amount);
    totalLoans = amount;
    // Lock the contract so no operations can proceed
    setLock(true);
    // Once it has been deployed
    // now create L1 limit order
    IStarkEx starkEx = getStarkEx();
    starkEx.depositERC20ToVault(assetId, 0, quantisedAmount);

    // No native bit shifting available in EVM hence divison is fine
    uint amountA = amount / 2;
    uint amountB = amount - amountA;
    uint nonceLocal = nonce; // gas savings

    // Verify the ratio

    starkEx.registerLimitOrder(exchangeAddress, assetId, tokenAssetId,
     tokenAssetId, amountA, tokenAmount, 0, 0, 0, 0, nonceLocal++, type(uint).max);

    starkEx.registerLimitOrder(exchangeAddress, assetId, tokenAssetId,
     tokenBAssetId, amountB, tokenBAmount, 0, 0, 0, 0, nonceLocal++, type(uint).max);

    nonce = nonceLocal;
    emit FalshMint(amount, quantisedAmount);
    return true;
  }

  function settleLoans( uint tokenAssetId, uint tokenBAssetId) external operatorOnly returns(bool) {
    IStarkEx starkEx = getStarkEx();
    // must somehow clear all pending limit orders as well
    uint balance0 = starkEx.getQuantizedVaultBalance(address(this), tokenAssetId, 0);
    uint balance1 = starkEx.getQuantizedVaultBalance(address(this), tokenBAssetId, 0);
    starkEx.withdrawFromVault(tokenAssetId, 0, balance0);
    starkEx.withdrawFromVault(tokenBAssetId, 0, balance1);

    // Ensure we received the expected ratio matching totalLoans
    { // block to avoid stack limit exceptions
      (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
      balance0 = IERC20Uniswap(token0).balanceOf(address(this));
      balance1 = IERC20Uniswap(token1).balanceOf(address(this));
      uint amount0 = balance0.sub(_reserve0);
      uint amount1 = balance1.sub(_reserve1);
      uint _totalSupply = totalSupply;
      uint liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
      // require(liquidity >= totalLoans, "DVF: INSUFFICIENT_BALANCE_TO_SETTLE");
      if(liquidity < totalLoans) {
        revert InsufficientBalance({
          available: totalLoans,
          required: liquidity
        });
      }
    }

    // Must have a way to clear all loans and existing orders
    // withdraw from vault into this address and then burn it
    uint contractBalance = balanceOf[address(this)];
    if (contractBalance > 0) {
      _burn(address(this), contractBalance);
    }

    totalLoans = 0;
    setLock(false);
    sync();
    return true;
  }

  function withdrwalAndCleanLoans(uint assetId) external operatorOnly {
    require(totalLoans > 0, "DVF: NO_OUTSTANDING_LOANS");
    getStarkEx().withdrawFromVault(assetId, 0, totalLoans);
    clearLoans();
  }

  // Clear all loans by expecting the loaned tokens to be depossited back in
  function clearLoans() public operatorOnly {
    require(totalLoans > 0, "DVF: NO_OUTSTANDING_LOANS");
    uint balance = balanceOf[address(this)];
    require(balance >= totalLoans, "DVF: NOT_ENOUGH_LP_DEPOSITTED");
    _burn(address(this), balance);
    setLock(false);
    totalLoans = 0;
  }

  /**
   * Restrict for L2
  */
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) public override l2OperatorOnly {
    super.swap(amount0Out, amount1Out, to, data);
  }

  function mint(address to) public override l2OperatorOnly returns (uint liquidity) {
    return super.mint(to);
  }

  /**
  * @dev Transfer your tokens
  * For burning tokens transfers are done to this contact address first and they must be queued in L2 `queueBurnDirect`
  * User to User transfers follow standard ERC-20 pattern
  */
  function transfer(address to, uint value) public override returns (bool) { 
    require(!(isLayer2Live && !isOperator() && to == address(this)), "DVF_AMM: CANNOT_MINT_L2");

    require(super.transfer(to, value), "DVF_AMM: TRANSFER_FAILED");
    return true;
  }

  /**
  * @dev Transfer approved tokens
  * For burning tokens transfers are done to this contact address first and they must be queued in L2 `queueBurn`
  * User to User transfers follow standard ERC-20 pattern
  */
  function transferFrom(address from, address to, uint value) public override returns (bool) {
    require(!(isLayer2Live && !isOperator() && to == address(this)), "DVF_AMM: CANNOT_MINT_L2");

    require(super.transferFrom(from, to, value), "DVF_AMM: TRANSFER_FAILED");
    return true;
  }

  function _validateDelayedTransfers(uint time, uint amount, uint value) private view {
    require(time <= block.timestamp, "DVF_AMM: TOO_EARLY");
    require(time > block.timestamp - delay, "DVF_AMM: TOO_LATE");
    require(amount >= value, "DVF_AMM: REQUEST_LARGER_THAN_EXPECTATION");
  }

  function _queueBurn(uint value, address from) private returns (uint) {
    require(isLayer2Live, "DVF_AMM: L1_NOT_REQUIRED");
    require(balanceOf[from] >= value, "DVF_AMM: INSUFFICIENT_BALANCE");
    Withdrawal storage w = delayedTransfers[from];
    uint time = block.timestamp + delay; // gas saving
    uint deadline = time + delay; 
    w.time = time;
    w.amount = value;
    emit QueuedWithdrawal(from, value, time, deadline);

    return time;
  }

  function skim(address to) public override l2OperatorOnly {
    super.skim(to);
  }

  function sync() public override l2OperatorOnly {
    super.sync();
  }

  function activateLayer2(bool _isLayer2Live) external operatorOnly {
    if (_isLayer2Live) {
      require(!IUniswapV2Factory(factory).isStarkExContractFrozen(), 'DVF_AMM: STARKEX_FROZEN');
    }
    isLayer2Live = _isLayer2Live;
  }

  function emergencyDisableLayer2() public {
    require(isLayer2Live, 'DVF_AMM: LAYER2_ALREADY_DISABLED');
    require(IUniswapV2Factory(factory).isStarkExContractFrozen(), 'DVF_AMM: STARKEX_NOT_FROZEN');
    isLayer2Live = false;
  }
}

pragma solidity >=0.8.0;

interface IStarkEx {
  /**
   * Register an L1 limit order
   */
  function registerLimitOrder(
      address exchangeAddress,
      uint256 tokenIdSell,
      uint256 tokenIdBuy,
      uint256 tokenIdFee,
      uint256 amountSell,
      uint256 amountBuy,
      uint256 amountFee,
      uint256 vaultIdSell,
      uint256 vaultIdBuy,
      uint256 vaultIdFee,
      uint256 nonce,
      uint256 expirationTimestamp
  ) external;

  /**
   * Deposits and withdrawals
  */
  function depositERC20ToVault(uint256 assetId, uint256 vaultId, uint256 quantizedAmount) external;
  function depositEthToVault(uint256 assetId, uint256 vaultId) external payable;
  function withdrawFromVault(uint256 assetId, uint256 vaultId, uint256 quantizedAmount) external;
  function getVaultBalance(address ethKey, uint256 assetId, uint256 vaultId) external view returns (uint256);
  function getQuantizedVaultBalance(address ethKey, uint256 assetId, uint256 vaultId) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity >=0.6.11;

abstract contract MFreezable {
    /*
      Returns true if the exchange is frozen.
    */
    function isFrozen() public view virtual returns (bool); // NOLINT: external-function.

    /*
      Forbids calling the function if the exchange is frozen.
    */
    modifier notFrozen()
    {
        require(!isFrozen(), "STATE_IS_FROZEN");
        _;
    }

    function validateFreezeRequest(uint256 requestTime) internal virtual;

    /*
      Allows calling the function only if the exchange is frozen.
    */
    modifier onlyFrozen()
    {
        require(isFrozen(), "STATE_NOT_FROZEN");
        _;
    }

    /*
      Freezes the exchange.
    */
    function freeze() internal virtual;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './libraries/SafeMath.sol';

contract UniswapV2ERC20 {
    using SafeMathUniswap for uint;

    string public constant name = 'DeversiFi LP Token';
    string public constant symbol = 'DLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) public virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'DVF_AMM: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'DVF_AMM: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './interfaces/IUniswapV2Factory.sol';
import '../PairWithL2Overlay.sol';
import '../starkex/interfaces/MFreezable.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    uint internal constant starkExContractSwitchDelay = 8 days;
    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;
    address public override starkExContract;
    address public nextStarkExContract;
    uint public nextStarkExContractSwitchDeadline;

    mapping(address => bool) public override operators;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    modifier _isFeeToSetter() {
        require(msg.sender == feeToSetter, 'DVF_AMM: FORBIDDEN');
        _;
    }

    function setL2StateOnAllPairs(bool state) external {
      for (uint i = 0; i < allPairs.length; i++) {
        address pair = allPairs[i];
        PairWithL2Overlay(pair).activateLayer2(state);
      }
    }

    function requireOperator() internal view {
      require(isOperator(), 'L2_TRADING_ONLY');
    }

    function isOperator() internal view returns(bool) {
      return operators[tx.origin];
    }

    constructor(address _feeToSetter, address _starkExContract) {
        feeToSetter = _feeToSetter;
        starkExContract = _starkExContract;
        operators[feeToSetter] = true;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external override pure returns (bytes32) {
        return keccak256(type(PairWithL2Overlay).creationCode);
    }

    function getPairForTokens(address tokenA, address tokenB) external view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = getPair[token0][token1];
        require(getPair[token0][token1] != address(0), 'DVF_AMM: PAIR_NOT_FOUND');
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(isOperator(), 'DVF: FORBIDDEN');
        require(tokenA != tokenB, 'DVF_AMM: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DVF_AMM: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'DVF_AMM: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(PairWithL2Overlay).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        PairWithL2Overlay(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override _isFeeToSetter {
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override _isFeeToSetter {
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override _isFeeToSetter {
        feeToSetter = _feeToSetter;
    }

    function isStarkExContractFrozen() external override view returns (bool) {
        return MFreezable(starkExContract).isFrozen();
    }

    function initiateStarkExContractChange(address _starkExContract) external _isFeeToSetter {
        require(nextStarkExContract == address(0), 'DVF_AMM: STARKEX_CONTRACT_CHANGE_ALREADY_IN_PROGRESS');
        require(_starkExContract != starkExContract, 'DVF_AMM: INPUT_STARKEX_CONTRACT_SAME_AS_CURRENT');
        require(_starkExContract != address(0) , 'DVF_AMM: INPUT_STARKEX_CONTRACT_UNDEFINED');
        nextStarkExContract = _starkExContract;
        nextStarkExContractSwitchDeadline = block.timestamp + starkExContractSwitchDelay;
    }

    function finalizeStarkExContractChange() external {
        require(nextStarkExContract != address(0), 'DVF_AMM: NEXT_STARKEX_CONTRACT_UNDEFINED');
        require(block.timestamp >= nextStarkExContractSwitchDeadline, 'DVF_AMM: DELAY_NO_REACHED_FOR_STARKEX_CONTRACT_CHANGE');
        require(!this.isStarkExContractFrozen(), 'DVF_AMM: CURRENT_STARKEX_CONTRACT_FROZEN');
        starkExContract = nextStarkExContract;
        nextStarkExContract = address(0);
        nextStarkExContractSwitchDeadline = 0;
    }

    function addOperator(address _operator) external _isFeeToSetter {
      operators[_operator] = true;
    }

    function removeOperator(address _operator) external _isFeeToSetter {
      delete operators[_operator];
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

contract UniswapV2Pair is UniswapV2ERC20 {
    using SafeMathUniswap  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 0;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'DVF_AMM: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function setLock(bool state) internal {
      unlocked = state ? 0 : 1;
    }

    function isLocked() internal view returns (bool) {
      return unlocked == 0;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'DVF_AMM: TRANSFER_FAILED');
    }

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

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) public {
        require(msg.sender == factory, 'DVF_AMM: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'DVF_AMM: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = address(0);
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) public virtual lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20Uniswap(token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            address migrator = IUniswapV2Factory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(liquidity > 0 && liquidity != type(uint256).max, "Bad desired liquidity");
            } else {
                require(migrator == address(0), "Must not have migrator");
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'DVF_AMM: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'DVF_AMM: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) public virtual lock {
        require(amount0Out > 0 || amount1Out > 0, 'DVF_AMM: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'DVF_AMM: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'DVF_AMM: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'DVF_AMM: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        // Fee removed
        uint balance0Adjusted = balance0;
        uint balance1Adjusted = balance1;
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1), 'DVF_AMM: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) public virtual lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20Uniswap(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20Uniswap(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() public virtual lock {
        _update(IERC20Uniswap(token0).balanceOf(address(this)), IERC20Uniswap(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function operators(address operator) external view returns (bool);

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

    function pairCodeHash() external pure returns (bytes32);

    function isStarkExContractFrozen() external view returns (bool);

    function starkExContract() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

