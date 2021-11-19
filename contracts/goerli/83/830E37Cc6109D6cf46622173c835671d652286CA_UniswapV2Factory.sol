// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.12;

import './uniswapv2/UniswapV2Pair.sol';
import './uniswapv2/UniswapV2ERC20.sol';
import './uniswapv2/interfaces/IERC20.sol';
import './uniswapv2/interfaces/IUniswapV2Factory.sol';
import './starkex/interfaces/IStarkEx.sol';
import './uniswapv2/libraries/SafeMath.sol';
import './uniswapv2/libraries/TransferHelper.sol';
import './StarkWareAssetData.sol';
import './uniswapv2/interfaces/IWETH.sol';

contract PairWithL2Overlay is UniswapV2Pair, StarkWareAssetData {
  using SafeMathUniswap for uint;
  uint internal constant lpQuantum = 1000;
  uint public totalLoans;
  uint public tokenAOutstanding;
  uint public tokenBOutstanding;
  uint private nonce;

  // Starkware values to be set
  uint public lpAssetId;
  uint public tokenAAssetId;
  uint public tokenAQuantum;
  uint public tokenBAssetId;
  uint public tokenBQuantum;

  address public weth;
  bool public isLayer2Live;
  uint16 private starkWareState; // 0 - off, 1 - mint, 2 - burn, 3 - swap
  uint32 private unsignedInt22 = 4194303;

  event FlashMint(uint amount, uint quantizedAmount);

  modifier l2OperatorOnly() {
    if(isLayer2Live) {
      requireOperator();
    }
    _;
  }

  modifier l2Only() {
    require(isLayer2Live, 'DVF: ONLY_IN_LAYER2');
    _;
  }

  modifier operatorOnly() {
    requireOperator();
    _;
  }

  function validateTokenAssetId(uint assetId) private view {
    require(assetId == tokenAAssetId || assetId == tokenBAssetId, 'DVF: INVALID_ASSET_ID');
  }

  receive() external payable {
      // accept ETH from WETH and StarkEx
  }

  function getQuantums() public override view returns (uint, uint, uint) {
    require(tokenAQuantum != 0, 'DVF: STARKWARE_NOT_SETUP');
    return (lpQuantum, tokenAQuantum, tokenBQuantum);
  }

  function setupStarkware(uint _assetId, uint _tokenAAssetId, uint _tokenBAssetId) external operatorOnly {
    IStarkEx starkEx = getStarkEx();
    require(extractContractAddress(starkEx, _assetId) == address(this), 'INVALID_ASSET_ID');
    require(isValidAssetId(starkEx, _tokenAAssetId, token0), 'INVALID_TOKENA_ASSET_ID');
    require(isValidAssetId(starkEx, _tokenBAssetId, token1), 'INVALID_TOKENB_ASSET_ID');
    lpAssetId = _assetId;
    tokenAAssetId = _tokenAAssetId;
    tokenBAssetId = _tokenBAssetId;
    tokenAQuantum = starkEx.getQuantum(_tokenAAssetId);
    tokenBQuantum = starkEx.getQuantum(_tokenBAssetId);
  }

  /*
   * Ensure ETH assetId is provided instead of WETH to successfully trade the underlying token
  */
  function isValidAssetId(IStarkEx starkEx, uint assetId, address token) internal view returns(bool) {
    if (token == weth) {
      require(isEther(starkEx, assetId), 'DVF: EXPECTED_ETH_SELECTOR');
      return true;
    }

    address contractAddress = extractContractAddress(starkEx, assetId);

    return token == contractAddress;
  }

  function initialize(address _token0, address _token1, address _weth) external {
    super.initialize(_token0, _token1);
    weth = _weth;
  }

  function getStarkEx() internal view returns (IStarkEx) {
    return IStarkEx(IUniswapV2Factory(factory).starkExContract());
  }

  function getStarkExRegistry(IStarkEx starkEx) internal returns (IStarkEx) {
    return IStarkEx(starkEx.orderRegistryAddress());
  }

  function requireOperator() internal view {
    require(isOperator(), 'L2_TRADING_ONLY');
  }

  function isOperator() internal view returns(bool) {
    return IUniswapV2Factory(factory).operators(tx.origin);
  }

  function depositStarkWare(IStarkEx starkEx, address token, uint _quantum, uint _assetId, uint vaultId, uint quantisedAmount) internal {
    if (token == weth) {
      // Must unwrap and deposit ETH
      uint amount = fromQuantized(_quantum, quantisedAmount);

      IWETH(weth).withdraw(amount);
      starkEx.depositEthToVault{value: amount}(_assetId, vaultId);
    } else {
      starkEx.depositERC20ToVault(_assetId, vaultId, quantisedAmount);
    }
  }

  function withdrawStarkWare(IStarkEx starkEx, address token, uint _quantum, uint _assetId, uint vaultId, uint quantisedAmount) internal {
    starkEx.withdrawFromVault(_assetId, vaultId, quantisedAmount);

    // Wrap in WETH if it was ETH
    if (token == weth) {
      // Must unwrap and deposit ETH
      uint amount = fromQuantized(_quantum, quantisedAmount);
      IWETH(weth).deposit{value: amount}();
    } 
  }
  function _swapStarkWare( 
    uint pathTo,
    uint pathFrom,
    uint amountTo,
    uint amountFrom,
    address exchangeAddress) private returns(uint, uint) {
    require(pathFrom != pathTo, 'DVF: SWAP_PATHS_IDENTICAL');
    require(amountFrom > 0 && amountTo > 0, 'DVF_SWAP_AMOUNTS_INVALID');

    // Local reassignment to avoid stack too deep
    uint localPathFrom = pathFrom;
    uint localPathTo = pathTo;
    uint localAmountFrom = amountFrom;
    uint localAmountTo = amountTo;

    validateTokenAssetId(localPathFrom);
    validateTokenAssetId(localPathTo);

    // Validate the swap amounts
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    uint balance0;
    uint balance1;
    if (localPathFrom == tokenAAssetId) {
      balance0 = _reserve0 - fromQuantized(tokenAQuantum, localAmountFrom);
      balance1 =_reserve1 + fromQuantized(tokenBQuantum, localAmountTo);
    } else {
      balance0 = _reserve0 + fromQuantized(tokenAQuantum, localAmountTo);
      balance1 =_reserve1 - fromQuantized(tokenBQuantum, localAmountFrom);
    }
    IStarkEx starkEx = getStarkEx();

    validateK(balance0, balance1, _reserve0, _reserve1);
    (address fromToken, uint fromQuantum) = starkWareInfo(localPathFrom);

    TransferHelper.safeApprove(fromToken, IUniswapV2Factory(factory).starkExContract(), fromQuantized(fromQuantum, localAmountFrom));
    depositStarkWare(starkEx, fromToken, fromQuantum, localPathFrom, 0, localAmountFrom);
    getStarkExRegistry(starkEx).registerLimitOrder(exchangeAddress, localPathFrom, localPathTo,
      localPathFrom, localAmountFrom, localAmountTo, 0, 0, 0, 0, nonce++, unsignedInt22);

    return (balance0, balance1);
  }

  function swapStarkWare(
    uint swapPathFrom,
    uint swapPathTo,
    uint swapAmountFrom,
    uint swapAmountTo,
    uint nonceToUse,
    address exchangeAddress) external operatorOnly l2Only returns(bool) {
    require(!isLocked(), "DVF: LOCK_IN_PROGRESS");
    // Lock the contract so no operations can proceed
    setLock(true);

    { // Avoid stack too deep
    nonce = nonceToUse;
    (uint balance0, uint balance1) = _swapStarkWare(swapPathFrom, swapPathTo, swapAmountFrom, swapAmountTo, exchangeAddress);
    tokenAOutstanding = balance0;
    tokenBOutstanding = balance1;
    }

    starkWareState = 3;
    return true;
  }

  function swapAndMintStarkWare(
    uint swapPathFrom,
    uint swapPathTo,
    uint swapAmountFrom,
    uint swapAmountTo,
    uint lpQuantisedAmount,
    uint tokenAAmount,
    uint tokenBAmount,
    uint nonceToUse,
    address exchangeAddress) external operatorOnly l2Only returns(bool) {
    require(!isLocked(), "DVF: LOCK_IN_PROGRESS");
    // Lock the contract so no operations can proceed
    setLock(true);

    { // Avoid stack too deep
    nonce = nonceToUse;
    (uint balance0, uint balance1) = _swapStarkWare(swapPathFrom, swapPathTo, swapAmountFrom, swapAmountTo, exchangeAddress);

    // We mint on the pair itself
    // Then deposit into starkEx valut
    uint amount = fromQuantized(lpQuantum, lpQuantisedAmount);
    uint _totalSupply = toQuantizedUnsafe(lpQuantum, totalSupply); 
    { // avoid stack errors
    uint balance0Quantised = toQuantizedUnsafe(tokenAQuantum, balance0);
    uint balance1Quantised = toQuantizedUnsafe(tokenBQuantum, balance1);
    uint liquidity = Math.min(tokenAAmount.mul(_totalSupply) / balance0Quantised, tokenBAmount.mul(_totalSupply) / balance1Quantised);
    require(liquidity <= amount, 'DVF_LIQUIDITY_REQUESTED_TOO_HIGH');
    }
    {
    uint amount0 = fromQuantized(tokenAQuantum, tokenAAmount);
    uint amount1 = fromQuantized(tokenBQuantum, tokenBAmount);

    tokenAOutstanding = balance0.add(amount0);
    tokenBOutstanding = balance1.add(amount1);
    }

    _mint(address(this), amount);
    totalLoans = amount;

    // now create L1 limit order
    // Must allow starkEx contract to transfer the tokens from this pair
    _approve(address(this), IUniswapV2Factory(factory).starkExContract(), amount);
    emit FlashMint(amount, lpQuantisedAmount);
    }

    IStarkEx starkEx = getStarkEx();
    starkEx.depositERC20ToVault(lpAssetId, 0, lpQuantisedAmount);

    // No native bit shifting available in EVM hence divison is fine

    // Reassigning to registry, no new variables to limit stack
    uint amountA = lpQuantisedAmount / 2;
    uint amountB = lpQuantisedAmount - amountA;
    starkEx = getStarkExRegistry(starkEx);

    // Verify the ratio
    uint nonceLocal = nonce;
    starkEx.registerLimitOrder(exchangeAddress, lpAssetId, tokenAAssetId,
    tokenAAssetId, amountA, tokenAAmount, 0, 0, 0, 0, nonceLocal++, unsignedInt22);

    starkEx.registerLimitOrder(exchangeAddress, lpAssetId, tokenBAssetId,
    tokenBAssetId, amountB, tokenBAmount, 0, 0, 0, 0, nonceLocal, unsignedInt22);

    starkWareState = 1;
    return true;
  }

  function swapAndBurnStarkWare(
    uint swapPathFrom,
    uint swapPathTo,
    uint swapAmountFrom,
    uint swapAmountTo,
    uint lpQuantisedAmount,
    uint tokenAAmount,
    uint tokenBAmount,
    uint nonceToUse,
    address exchangeAddress) external operatorOnly l2Only returns(bool) {
    require(!isLocked(), "DVF: LOCK_IN_PROGRESS");
    // Lock the contract so no operations can proceed
    setLock(true);
    // Then deposit into starkEx valut
    IStarkEx starkEx = getStarkEx();
    address starkExAddress = IUniswapV2Factory(factory).starkExContract();
    nonce = nonceToUse; // Using storage unit as stack is too deep
    (uint balance0, uint balance1) = _swapStarkWare(swapPathFrom, swapPathTo, swapAmountFrom, swapAmountTo, exchangeAddress);

    uint liquidity = fromQuantized(lpQuantum, lpQuantisedAmount);

    uint amount0;
    uint amount1;
    {
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
    amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
    balance0 = balance0 - amount0;
    balance1 = balance1 - amount1;

    // Expected final balance
    tokenAOutstanding = balance0;
    tokenBOutstanding = balance1;

    // amount0 and amount1 are the ones we are willing to give in return for LP tokens
    // hence transfer and create L1 limit orders
    TransferHelper.safeApprove(token0, starkExAddress, amount0);
    TransferHelper.safeApprove(token1, starkExAddress, amount1);

    amount0 = toQuantized(tokenAQuantum, amount0 - (amount0 % tokenAQuantum));
    amount1 = toQuantized(tokenBQuantum, amount1 - (amount1 % tokenBQuantum));
    require(amount0 >= tokenAAmount, 'DVF: MIN_TOKEN_A');
    require(amount1 >= tokenBAmount, 'DVF: MIN_TOKEN_B');
    amount0 = tokenAAmount;
    amount1 = tokenBAmount;
    depositStarkWare(starkEx, token0, tokenAQuantum, tokenAAssetId, 0, amount0);
    depositStarkWare(starkEx, token1, tokenBQuantum, tokenBAssetId, 0, amount1);
    }

    // Reassigning to registry, no new variables to limit stack
    uint amountA = lpQuantisedAmount / 2;
    uint amountB = lpQuantisedAmount - amountA;
    uint nonceLocal = nonce; // gas savings
    starkEx = getStarkExRegistry(starkEx);
    // Verify the ratio
    starkEx.registerLimitOrder(exchangeAddress, tokenAAssetId, lpAssetId,
    lpAssetId, amount0, amountA, 0, 0, 0, 0, nonceLocal++, unsignedInt22);

    starkEx.registerLimitOrder(exchangeAddress, tokenBAssetId, lpAssetId,
    lpAssetId, amount1, amountB, 0, 0, 0, 0, nonceLocal++, unsignedInt22);

    totalLoans = liquidity;
    nonce = nonceLocal;

    starkWareState = 2;
    return true;
  }

  function settleStarkWare() external operatorOnly returns(bool) {
    uint16 _starkWareState = starkWareState; // gas savings
    require(_starkWareState == 1 || _starkWareState == 2 || _starkWareState == 3, 'DVF: NOTHING_TO_SETTLE');

    IStarkEx starkEx = getStarkEx();
    // must somehow clear all pending limit orders as well
    withdrawAllFromVaultIn(starkEx, token0, tokenAQuantum, tokenAAssetId, 0);
    withdrawAllFromVaultIn(starkEx, token1, tokenBQuantum, tokenBAssetId, 0);
    {
      // withdraw from vault into this address and then burn it
      withdrawAllFromVaultIn(starkEx, lpAssetId);
      uint contractBalance = balanceOf[address(this)];
      if (_starkWareState == 2) {
        // Ensure we were paid enough LP for burn
        require(contractBalance >= totalLoans, 'DVF: NOT_ENOUGH_LP');
      }

      if (contractBalance > 0) {
        _burn(address(this), contractBalance);
      }
    }

    // Ensure we received the expected ratio matching totalLoans
    { // block to avoid stack limit exceptions
      uint balance0 = IERC20Uniswap(token0).balanceOf(address(this));
      uint balance1 = IERC20Uniswap(token1).balanceOf(address(this));

      // We can't validate state transition, can only verify that the expected balanece was achieved
      require(balance0 >= tokenAOutstanding && balance1 >= tokenBOutstanding, 'DVF: INVALID_TOKEN_AMOUNTS');
    }

    totalLoans = 0;
    starkWareState = 0;
    setLock(false);
    sync();
    return true;
  }

  /**
   * Allow clearing vaults by pulling all funds out, can only be used by the operator in L2
   * Should not be required if all operations are performing correctly
  */
  function withdrawAllFromVault() public l2OperatorOnly {
    IStarkEx starkEx = getStarkEx();
    withdrawAllFromVaultIn(starkEx, lpAssetId);
    withdrawAllFromVaultIn(starkEx, tokenAAssetId);
    withdrawAllFromVaultIn(starkEx, tokenBAssetId);
  }

  function withdrawAllFromVaultIn(IStarkEx starkEx, uint _assetId) internal l2OperatorOnly {
    uint balance = starkEx.getQuantizedVaultBalance(address(this), _assetId, 0);
    starkEx.withdrawFromVault(_assetId, 0, balance);
  }

  function withdrawAllFromVaultIn(IStarkEx starkEx, address token, uint _quantum, uint _assetId, uint vaultId) internal l2OperatorOnly {
    uint balance = starkEx.getQuantizedVaultBalance(address(this), _assetId, vaultId);
    withdrawStarkWare(starkEx, token, _quantum, _assetId, 0, balance);
  }

  function withdrawAndClearStarkWare() external l2OperatorOnly {
    require(totalLoans > 0, "DVF: NO_OUTSTANDING_LOANS");
    withdrawAllFromVault();
    clearLoans();
  }

  // Clear all loans by expecting the loaned tokens to be depossited back in
  function clearLoans() public l2OperatorOnly {
    require(totalLoans > 0, "DVF: NO_OUTSTANDING_LOANS");
    uint balance = balanceOf[address(this)];
    if (starkWareState == 1) {
      require(balance >= totalLoans, "DVF: NOT_ENOUGH_LP_DEPOSITED");
    } 
    _burn(address(this), balance);
    setLock(false);
    totalLoans = 0;
    starkWareState = 0;
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

  function skim(address to) public override l2OperatorOnly {
    super.skim(to);
  }

  function sync() public override l2OperatorOnly {
    super.sync();
  }

  function activateLayer2(bool _isLayer2Live) external operatorOnly {
    if (_isLayer2Live) {
      require(lpAssetId != 0, 'DVF_AMM: NOT_SETUP_FOR_L2');
      require(!IUniswapV2Factory(factory).isStarkExContractFrozen(), 'DVF_AMM: STARKEX_FROZEN');
    }
    isLayer2Live = _isLayer2Live;
  }

  function emergencyDisableLayer2() external {
    require(isLayer2Live, 'DVF_AMM: LAYER2_ALREADY_DISABLED');
    require(IUniswapV2Factory(factory).isStarkExContractFrozen(), 'DVF_AMM: STARKEX_NOT_FROZEN');
    isLayer2Live = false;
    setLock(false);
  }

  function starkWareInfo(uint _assetId) public view returns (address _token, uint _quantum) {
    if (_assetId == lpAssetId) {
      return (address(this), lpQuantum);
    } else if (_assetId == tokenAAssetId) {
      return (token0, tokenAQuantum);
    } else if (_assetId == tokenBAssetId) {
      return (token1, tokenBQuantum);
    } 

    require(false, 'DVF_NO_STARKWARE_INFO');
  }

  function setLock(bool state) internal {
    unlocked = state ? 0 : 1;
  }

  function isLocked() internal view returns (bool) {
    return unlocked == 0;
  }
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.12;

import './starkex/interfaces/IStarkEx.sol';

// Required functions from StarkWare TokenAssetData
abstract contract StarkWareAssetData {
    bytes4 internal constant ETH_SELECTOR = bytes4(keccak256("ETH()"));

    // The selector follows the 0x20 bytes assetInfo.length field.
    uint256 internal constant SELECTOR_OFFSET = 0x20;
    uint256 internal constant SELECTOR_SIZE = 4;
    uint256 internal constant TOKEN_CONTRACT_ADDRESS_OFFSET = SELECTOR_OFFSET + SELECTOR_SIZE;

    function extractContractAddressFromAssetInfo(bytes memory assetInfo)
        private pure returns (address res) {
        uint256 offset = TOKEN_CONTRACT_ADDRESS_OFFSET;
        assembly {
            res := mload(add(assetInfo, offset))
        }
    }

    function extractTokenSelector(bytes memory assetInfo) internal pure
        returns (bytes4 selector) {
        assembly {
            selector := and(
                0xffffffff00000000000000000000000000000000000000000000000000000000,
                mload(add(assetInfo, SELECTOR_OFFSET))
            )
        }
    }

    function isEther(IStarkEx starkEx, uint256 assetType) internal view returns (bool) {
        return extractTokenSelector(starkEx.getAssetInfo(assetType)) == ETH_SELECTOR;
    }

    function extractContractAddress(IStarkEx starkEx, uint256 assetType) internal view returns (address) {
        return extractContractAddressFromAssetInfo(starkEx.getAssetInfo(assetType));
    }
}

pragma solidity >=0.8.0;

interface IStarkEx {
  function VERSION() external view returns(string memory);
  event LogL1LimitOrderRegistered( address userAddress, address exchangeAddress, uint256 tokenIdSell, uint256 tokenIdBuy,
      uint256 tokenIdFee, uint256 amountSell, uint256 amountBuy, uint256 amountFee, uint256 vaultIdSell, uint256 vaultIdBuy,
      uint256 vaultIdFee, uint256 nonce, uint256 expirationTimestamp);

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

  function orderRegistryAddress() external returns (address);
  function getAssetInfo(uint256 assetType) external view returns (bytes memory);
  function getQuantum(uint assetId) external view returns(uint);
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

pragma solidity >=0.8.0;

abstract contract StarkPair {
  function getQuantums() public view virtual returns (uint, uint, uint);

  function fromQuantized(uint _quantum, uint256 quantizedAmount)
      public pure returns (uint256 amount) {
      amount = quantizedAmount * _quantum;
      require(amount / _quantum == quantizedAmount, "DEQUANTIZATION_OVERFLOW");
  }

  function toQuantizedUnsafe(uint _quantum, uint256 amount)
      public pure returns (uint256 quantizedAmount) {
      quantizedAmount = amount / _quantum;
  }

  function toQuantized(uint _quantum, uint256 amount)
      public pure returns (uint256 quantizedAmount) {
      if (amount == 0) {
        return 0;
      }
      require(amount % _quantum == 0, "INVALID_AMOUNT_TO_QUANTIZED");
      quantizedAmount = toQuantizedUnsafe(_quantum, amount);
  }

  function truncate(uint quantum, uint amount) internal pure returns (uint) {
    if (amount == 0) {
      return 0;
    }
    require(amount > quantum, 'DVF: TRUNCATE_AMOUNT_LOWER_THAN_QUANTUM');
    return amount - (amount % quantum);
  }
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

    function _approve(address owner, address spender, uint value) internal {
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
    address public override wethAddress;
    address public nextStarkExContract;
    uint public nextStarkExContractSwitchDeadline;

    mapping(address => bool) public override operators;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    modifier _isFeeToSetter() {
        require(msg.sender == feeToSetter, 'DVF_AMM: FORBIDDEN');
        _;
    }

    function requireOperator() internal view {
      require(isOperator(), 'L2_TRADING_ONLY');
    }

    function isOperator() internal view returns(bool) {
      return operators[tx.origin];
    }

    constructor(address _feeToSetter, address _starkExContract, address _wethAddress) {
        feeToSetter = _feeToSetter;
        starkExContract = _starkExContract;
        wethAddress = _wethAddress;
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
        address payable payablePair;
        assembly {
            payablePair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        pair = address(payablePair);
        PairWithL2Overlay(payablePair).initialize(token0, token1, wethAddress);
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
import './StarkPair.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

abstract contract UniswapV2Pair is UniswapV2ERC20, StarkPair {
    using SafeMathUniswap  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
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

    uint internal unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'DVF_AMM: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
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
        (uint lpQuantum, uint token0Quantum, uint token1Quantum) = getQuantums();
        uint balance0 = IERC20Uniswap(token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(token1).balanceOf(address(this));
        // Quantize to ensure we do not respect the percision higher than our quant
        uint amount0 = toQuantizedUnsafe(token0Quantum, balance0.sub(_reserve0));
        uint amount1 = toQuantizedUnsafe(token1Quantum, balance1.sub(_reserve1));
        uint reserve0Quantised = toQuantizedUnsafe(token0Quantum, _reserve0);
        uint reserve1Quantised = toQuantizedUnsafe(token1Quantum, _reserve1);

        // gas savings, must be defined here since totalSupply can update in _mintFee
        uint _totalSupply = toQuantizedUnsafe(lpQuantum, totalSupply); 
        if (_totalSupply == 0) {
            address migrator = IUniswapV2Factory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(liquidity > 0 && liquidity != type(uint256).max, "Bad desired liquidity");
            } else {
                require(migrator == address(0), "Must not have migrator");
                liquidity = calculateInitialLiquidity(amount0, amount1, lpQuantum);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / reserve0Quantised, amount1.mul(_totalSupply) / reserve1Quantised);
            liquidity = fromQuantized(lpQuantum, liquidity);
        }

        require(liquidity > 0, 'DVF_AMM: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function calculateInitialLiquidity(uint amount0, uint amount1, uint lpQuantum) internal pure returns(uint liquidity) {
      liquidity = Math.sqrt(amount0.mul(amount1).mul(lpQuantum).mul(lpQuantum)).sub(MINIMUM_LIQUIDITY);
      // Truncate
      liquidity = liquidity.sub(liquidity % lpQuantum);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];
        // TODO Ensure cannot burn with higher percision than quantum

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
        (,uint token0Quantum, uint token1Quantum) = getQuantums();
        if (amount0Out > 0) {
          amount0Out = truncate(token0Quantum, amount0Out);
          _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        }
        if (amount1Out > 0) {
          amount1Out = truncate(token1Quantum, amount1Out);
          _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        }
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'DVF_AMM: INSUFFICIENT_INPUT_AMOUNT');

        // validate K ratio
        validateK(balance0, balance1, _reserve0, _reserve1);

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function validateK(uint balance0, uint balance1, uint _reserve0, uint _reserve1) internal view {
      (,uint token0Quantum, uint token1Quantum) = getQuantums();
      uint balance0Adjusted = toQuantizedUnsafe(token0Quantum, balance0);
      uint balance1Adjusted = toQuantizedUnsafe(token1Quantum, balance1);
      uint reserve0Adjusted = toQuantizedUnsafe(token0Quantum, _reserve0);
      uint reserve1Adjusted = toQuantizedUnsafe(token1Quantum, _reserve1);
      require(balance0Adjusted.mul(balance1Adjusted) >= reserve0Adjusted.mul(reserve1Adjusted), 'DVF_AMM: K');
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
    function wethAddress() external view returns (address);

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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