pragma solidity 0.5.17; // optimization runs: 200, evm version: istanbul


interface DharmaTradeReserveV15Interface {
  event Trade(
    address account,
    address suppliedAsset,
    address receivedAsset,
    address retainedAsset,
    uint256 suppliedAmount,
    uint256 recievedAmount,
    uint256 retainedAmount
  );
  event RoleModified(Role indexed role, address account);
  event RolePaused(Role indexed role);
  event RoleUnpaused(Role indexed role);
  event EtherReceived(address sender, uint256 amount);
  event GasReserveRefilled(uint256 etherAmount);

  enum Role {            // #
    DEPOSIT_MANAGER,     // 0
    ADJUSTER,            // 1
    WITHDRAWAL_MANAGER,  // 2
    RESERVE_TRADER,      // 3
    PAUSER,              // 4
    GAS_RESERVE_REFILLER // 5
  }

  enum TradeType {
    DAI_TO_TOKEN,
    DAI_TO_ETH,
    ETH_TO_DAI,
    TOKEN_TO_DAI,
    ETH_TO_TOKEN,
    TOKEN_TO_ETH,
    TOKEN_TO_TOKEN
  }

  struct RoleStatus {
    address account;
    bool paused;
  }

  function tradeDaiForEtherV2(
    uint256 daiAmount, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function tradeEtherForDaiV2(
    uint256 quotedDaiAmount, uint256 deadline
  ) external payable returns (uint256 totalDaiBought);

  function tradeDaiForToken(
    address token,
    uint256 daiAmount,
    uint256 quotedTokenAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalDaiSold);

  function tradeTokenForDai(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedDaiAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalDaiBought);

  function tradeTokenForEther(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalEtherBought);

  function tradeEtherForToken(
    address token, uint256 quotedTokenAmount, uint256 deadline
  ) external payable returns (uint256 totalEtherSold);

  function tradeEtherForTokenUsingEtherizer(
    address token,
    uint256 etherAmount,
    uint256 quotedTokenAmount,
    uint256 deadline
  ) external returns (uint256 totalEtherSold);

  function tradeTokenForToken(
    ERC20Interface tokenProvided,
    address tokenReceived,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalTokensSold);

  function tradeTokenForTokenUsingReserves(
    ERC20Interface tokenProvidedFromReserves,
    address tokenReceived,
    uint256 tokenProvidedAmountFromReserves,
    uint256 quotedTokenReceivedAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalTokensSold);

  function tradeDaiForEtherUsingReservesV2(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function tradeEtherForDaiUsingReservesAndMintDDaiV2(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external returns (uint256 totalDaiBought, uint256 totalDDaiMinted);

  function tradeDaiForTokenUsingReserves(
    address token,
    uint256 daiAmountFromReserves,
    uint256 quotedTokenAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalDaiSold);

  function tradeTokenForDaiUsingReservesAndMintDDai(
    ERC20Interface token,
    uint256 tokenAmountFromReserves,
    uint256 quotedDaiAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalDaiBought, uint256 totalDDaiMinted);

  function tradeTokenForEtherUsingReserves(
    ERC20Interface token,
    uint256 tokenAmountFromReserves,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalEtherBought);

  function tradeEtherForTokenUsingReserves(
    address token,
    uint256 etherAmountFromReserves,
    uint256 quotedTokenAmount,
    uint256 deadline
  ) external returns (uint256 totalEtherSold);

  function finalizeEtherDeposit(
    address payable smartWallet,
    address initialUserSigningKey,
    uint256 etherAmount
  ) external;

  function finalizeDaiDeposit(
    address smartWallet, address initialUserSigningKey, uint256 daiAmount
  ) external;

  function finalizeDharmaDaiDeposit(
    address smartWallet, address initialUserSigningKey, uint256 dDaiAmount
  ) external;

  function mint(uint256 daiAmount) external returns (uint256 dDaiMinted);

  function redeem(uint256 dDaiAmount) external returns (uint256 daiReceived);

  function tradeDDaiForUSDC(
    uint256 daiEquivalentAmount, uint256 quotedUSDCAmount
  ) external returns (uint256 usdcReceived);

  function tradeUSDCForDDai(
    uint256 usdcAmount, uint256 quotedDaiEquivalentAmount
  ) external returns (uint256 dDaiMinted);

  function refillGasReserve(uint256 etherAmount) external;

  function withdrawUSDC(address recipient, uint256 usdcAmount) external;

  function withdrawDai(address recipient, uint256 daiAmount) external;

  function withdrawDharmaDai(address recipient, uint256 dDaiAmount) external;

  function withdrawUSDCToPrimaryRecipient(uint256 usdcAmount) external;

  function withdrawDaiToPrimaryRecipient(uint256 usdcAmount) external;

  function withdrawEther(
    address payable recipient, uint256 etherAmount
  ) external;

  function withdraw(
    ERC20Interface token, address recipient, uint256 amount
  ) external returns (bool success);

  function callAny(
    address payable target, uint256 amount, bytes calldata data
  ) external returns (bool ok, bytes memory returnData);

  function setDaiLimit(uint256 daiAmount) external;

  function setEtherLimit(uint256 daiAmount) external;

  function setPrimaryUSDCRecipient(address recipient) external;

  function setPrimaryDaiRecipient(address recipient) external;

  function setRole(Role role, address account) external;

  function removeRole(Role role) external;

  function pause(Role role) external;

  function unpause(Role role) external;

  function isPaused(Role role) external view returns (bool paused);

  function isRole(Role role) external view returns (bool hasRole);

  function isDharmaSmartWallet(
    address smartWallet, address initialUserSigningKey
  ) external view returns (bool dharmaSmartWallet);

  function getDepositManager() external view returns (address depositManager);

  function getAdjuster() external view returns (address adjuster);

  function getReserveTrader() external view returns (address reserveTrader);

  function getWithdrawalManager() external view returns (address withdrawalManager);

  function getPauser() external view returns (address pauser);

  function getGasReserveRefiller() external view returns (address gasReserveRefiller);

  function getReserves() external view returns (
    uint256 dai, uint256 dDai, uint256 dDaiUnderlying
  );

  function getDaiLimit() external view returns (
    uint256 daiAmount, uint256 dDaiAmount
  );

  function getEtherLimit() external view returns (uint256 etherAmount);

  function getPrimaryUSDCRecipient() external view returns (
    address recipient
  );

  function getPrimaryDaiRecipient() external view returns (
    address recipient
  );

  function getImplementation() external view returns (address implementation);

  function getInstance() external pure returns (address instance);

  function getVersion() external view returns (uint256 version);
}


interface ERC20Interface {
  function balanceOf(address) external view returns (uint256);
  function approve(address, uint256) external returns (bool);
  function allowance(address, address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
}


interface DTokenInterface {
  function mint(uint256 underlyingToSupply) external returns (uint256 dTokensMinted);
  function redeem(uint256 dTokensToBurn) external returns (uint256 underlyingReceived);
  function redeemUnderlying(uint256 underlyingToReceive) external returns (uint256 dTokensBurned);
  function balanceOf(address) external view returns (uint256);
  function balanceOfUnderlying(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function exchangeRateCurrent() external view returns (uint256);
}


interface TradeHelperInterface {
  function tradeUSDCForDDai(
    uint256 amountUSDC,
    uint256 quotedDaiEquivalentAmount
  ) external returns (uint256 dDaiMinted);
  function tradeDDaiForUSDC(
    uint256 amountDai,
    uint256 quotedUSDCAmount
  ) external returns (uint256 usdcReceived);
  function getExpectedDai(uint256 usdc) external view returns (uint256 dai);
  function getExpectedUSDC(uint256 dai) external view returns (uint256 usdc);
}


interface UniswapV2Interface {
  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);
}


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 *
 * In order to transfer ownership, a recipient must be specified, at which point
 * the specified recipient can call `acceptOwnership` and take ownership.
 */
contract TwoStepOwnable {
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  address private _owner;

  address private _newPotentialOwner;

  /**
   * @dev Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

  /**
   * @dev Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() external onlyOwner {
    delete _newPotentialOwner;
  }

  /**
   * @dev Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() external {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address) {
    return _owner;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }
}


/**
 * @title DharmaTradeReserveV15ImplementationStaging
 * @author 0age
 * @notice This contract manages Dharma's reserves. It designates a collection of
 * "roles" - these are dedicated accounts that can be modified by the owner, and
 * that can trigger specific functionality on the reserve. These roles are:
 *  - depositManager (0): initiates Eth / token transfers to smart wallets
 *  - adjuster (1): mints / redeems Dai, and swaps USDC, for dDai
 *  - withdrawalManager (2): initiates token transfers to recipients set by owner
 *  - reserveTrader (3): initiates trades using funds held in reserve
 *  - pauser (4): pauses any role (only the owner is then able to unpause it)
 *  - gasReserveRefiller (5): transfers Ether to the Dharma Gas Reserve
 *
 * When finalizing deposits, the deposit manager must adhere to two constraints:
 *  - it must provide "proof" that the recipient is a smart wallet by including
 *    the initial user signing key used to derive the smart wallet address
 *  - it must not attempt to transfer more Eth, Dai, or the Dai-equivalent
 *    value of Dharma Dai, than the current "limit" set by the owner.
 *
 * Note that "proofs" can be validated via `isSmartWallet`.
 */
contract DharmaTradeReserveV15ImplementationStaging is DharmaTradeReserveV15Interface, TwoStepOwnable {
  using SafeMath for uint256;

  // Maintain a role status mapping with assigned accounts and paused states.
  mapping(uint256 => RoleStatus) private _roles;

  // Maintain a "primary recipient" the withdrawal manager can transfer Dai to.
  address private _primaryDaiRecipient;

  // Maintain a "primary recipient" the withdrawal manager can transfer USDC to.
  address private _primaryUSDCRecipient;

  // Maintain a maximum allowable transfer size (in Dai) for the deposit manager.
  uint256 private _daiLimit;

  // Maintain a maximum allowable transfer size (in Ether) for the deposit manager.
  uint256 private _etherLimit;

  bool private _originatesFromReserveTrader; // unused, don't change storage layout

  uint256 private constant _VERSION = 1015;

  // This contract interacts with USDC, Dai, and Dharma Dai.
  ERC20Interface internal constant _USDC = ERC20Interface(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 // mainnet
  );

  ERC20Interface internal constant _DAI = ERC20Interface(
    0x6B175474E89094C44Da98b954EedeAC495271d0F // mainnet
  );

  ERC20Interface internal constant _ETHERIZER = ERC20Interface(
    0x723B51b72Ae89A3d0c2a2760f0458307a1Baa191
  );

  DTokenInterface internal constant _DDAI = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430
  );

  TradeHelperInterface internal constant _TRADE_HELPER = TradeHelperInterface(
    0x9328F2Fb3e85A4d24Adc2f68F82737183e85691d
  );

  UniswapV2Interface internal constant _UNISWAP_ROUTER = UniswapV2Interface(
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  );

  address internal constant _WETH = address(
    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
  );

  address internal constant _GAS_RESERVE = address(
    0x09cd826D4ABA4088E1381A1957962C946520952d // staging version
  );

  // The "Create2 Header" is used to compute smart wallet deployment addresses.
  bytes21 internal constant _CREATE2_HEADER = bytes21(
    0xff8D1e00b000e56d5BcB006F3a008Ca6003b9F0033 // control character + factory
  );

  // The "Wallet creation code" header & footer are also used to derive wallets.
  bytes internal constant _WALLET_CREATION_CODE_HEADER = hex"60806040526040516104423803806104428339818101604052602081101561002657600080fd5b810190808051604051939291908464010000000082111561004657600080fd5b90830190602082018581111561005b57600080fd5b825164010000000081118282018810171561007557600080fd5b82525081516020918201929091019080838360005b838110156100a257818101518382015260200161008a565b50505050905090810190601f1680156100cf5780820380516001836020036101000a031916815260200191505b5060405250505060006100e661019e60201b60201c565b6001600160a01b0316826040518082805190602001908083835b6020831061011f5780518252601f199092019160209182019101610100565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d806000811461017f576040519150601f19603f3d011682016040523d82523d6000602084013e610184565b606091505b5050905080610197573d6000803e3d6000fd5b50506102be565b60405160009081906060906eb45d6593312ac9fde193f3d06336449083818181855afa9150503d80600081146101f0576040519150601f19603f3d011682016040523d82523d6000602084013e6101f5565b606091505b509150915081819061029f576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825283818151815260200191508051906020019080838360005b8381101561026457818101518382015260200161024c565b50505050905090810190601f1680156102915780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b508080602001905160208110156102b557600080fd5b50519392505050565b610175806102cd6000396000f3fe608060405261001461000f610016565b61011c565b005b60405160009081906060906eb45d6593312ac9fde193f3d06336449083818181855afa9150503d8060008114610068576040519150601f19603f3d011682016040523d82523d6000602084013e61006d565b606091505b50915091508181906100fd5760405162461bcd60e51b81526004018080602001828103825283818151815260200191508051906020019080838360005b838110156100c25781810151838201526020016100aa565b50505050905090810190601f1680156100ef5780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b5080806020019051602081101561011357600080fd5b50519392505050565b3660008037600080366000845af43d6000803e80801561013b573d6000f35b3d6000fdfea265627a7a723158203c578cc1552f1d1b48134a72934fe12fb89a29ff396bd514b9a4cebcacc5cacc64736f6c634300050b003200000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000024c4d66de8000000000000000000000000";
  bytes28 internal constant _WALLET_CREATION_CODE_FOOTER = bytes28(
    0x00000000000000000000000000000000000000000000000000000000
  );

  // Flag to trigger trade for USDC and retain full trade amount
  address internal constant _TRADE_FOR_USDC_AND_RETAIN_FLAG = address(uint160(-1));

  // Include a payable fallback so that the contract can receive Ether payments.
  function () external payable {
    emit EtherReceived(msg.sender, msg.value);
  }

  function initialize() external onlyOwner {
    // Approve Uniswap router to transfer WETH on behalf of this contract.
    _grantUniswapRouterApprovalIfNecessary(ERC20Interface(_WETH), uint256(-1));
  }

  /**
   * @notice Pull in `daiAmount` Dai from the caller, trade it for Ether using
   * UniswapV2, and return `quotedEtherAmount` Ether to the caller.
   * @param daiAmount uint256 The amount of Dai to supply when trading for Ether.
   * @param quotedEtherAmount uint256 The amount of Ether to return to the caller.
   * @param deadline uint256 The timestamp the order is valid until.
   * @return The amount of Dai sold as part of the trade.
   */
  function tradeDaiForEtherV2(
    uint256 daiAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalDaiSold) {
    // Transfer the Dai from the caller and revert on failure.
    _transferInToken(_DAI, msg.sender, daiAmount);

    // Trade Dai for Ether.
    totalDaiSold = _tradeDaiForEther(
      daiAmount, quotedEtherAmount, deadline, false
    );
  }

  function tradeTokenForEther(
    ERC20Interface token, uint256 tokenAmount, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalEtherBought) {
    // Transfer the tokens from the caller and revert on failure.
    _transferInToken(token, msg.sender, tokenAmount);

    // Trade tokens for Ether.
    totalEtherBought = _tradeTokenForEther(
      token, tokenAmount, quotedEtherAmount, deadline, false
    );

    // Transfer the quoted Ether amount to the caller.
    _transferEther(msg.sender, quotedEtherAmount);
  }

  function tradeDaiForToken(
    address token, uint256 daiAmount, uint256 quotedTokenAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiSold) {
    // Transfer the Dai from the caller and revert on failure.
    _transferInToken(_DAI, msg.sender, daiAmount);

    // Trade Dai for specified token.
    totalDaiSold = _tradeDaiForToken(
      token, daiAmount, quotedTokenAmount, deadline, routeThroughEther, false
    );
  }

  /**
   * @notice Using `daiAmountFromReserves` Dai (note that dDai will be redeemed
   * if necessary), trade for Ether using UniswapV2. Only the owner or the trade
   * reserve role can call this function. Note that Dharma Dai will be redeemed
   * to cover the Dai if there is not enough currently in the contract.
   * @param daiAmountFromReserves the amount of Dai to take from reserves.
   * @param quotedEtherAmount uint256 The amount of Ether requested in the trade.
   * @param deadline uint256 The timestamp the order is valid until.
   * @return The amount of Ether bought as part of the trade.
   */
  function tradeDaiForEtherUsingReservesV2(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalDaiSold) {
    // Redeem dDai if the current Dai balance is less than is required.
    _redeemDDaiIfNecessary(daiAmountFromReserves);

    // Trade Dai for Ether using reserves.
    totalDaiSold = _tradeDaiForEther(
      daiAmountFromReserves, quotedEtherAmount, deadline, true
    );
  }

  function tradeTokenForEtherUsingReserves(
    ERC20Interface token, uint256 tokenAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalEtherBought) {
    // Trade tokens for Ether using reserves.
    totalEtherBought = _tradeTokenForEther(
      token, tokenAmountFromReserves, quotedEtherAmount, deadline, true
    );
  }

  /**
   * @notice Accept `msg.value` Ether from the caller, trade it for Dai using
   * UniswapV2, and return `quotedDaiAmount` Dai to the caller.
   * @param quotedDaiAmount uint256 The amount of Dai to return to the caller.
   * @param deadline uint256 The timestamp the order is valid until.
   * @return The amount of Dai bought as part of the trade.
   */
  function tradeEtherForDaiV2(
    uint256 quotedDaiAmount,
    uint256 deadline
  ) external payable returns (uint256 totalDaiBought) {
    // Trade Ether for Dai.
    totalDaiBought = _tradeEtherForDai(
      msg.value, quotedDaiAmount, deadline, false
    );

    // Transfer the Dai to the caller and revert on failure.
    _transferToken(_DAI, msg.sender, quotedDaiAmount);
  }

  function tradeEtherForToken(
    address token, uint256 quotedTokenAmount, uint256 deadline
  ) external payable returns (uint256 totalEtherSold) {
    // Trade Ether for the specified token.
    totalEtherSold = _tradeEtherForToken(
      token, msg.value, quotedTokenAmount, deadline, false
    );
  }

  function tradeEtherForTokenUsingEtherizer(
    address token, uint256 etherAmount, uint256 quotedTokenAmount, uint256 deadline
  ) external returns (uint256 totalEtherSold) {
    // Transfer the Ether from the caller and revert on failure.
    _transferInToken(_ETHERIZER, msg.sender, etherAmount);

    // Trade Ether for the specified token.
    totalEtherSold = _tradeEtherForToken(
      token, etherAmount, quotedTokenAmount, deadline, false
    );
  }

  function tradeTokenForDai(
    ERC20Interface token, uint256 tokenAmount, uint256 quotedDaiAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiBought) {
    // Transfer the token from the caller and revert on failure.
    _transferInToken(token, msg.sender, tokenAmount);

    // Trade the token for Dai.
    totalDaiBought = _tradeTokenForDai(
      token, tokenAmount, quotedDaiAmount, deadline, routeThroughEther, false
    );

    // Transfer the quoted Dai amount to the caller and revert on failure.
    _transferToken(_DAI, msg.sender, quotedDaiAmount);
  }

  function tradeTokenForToken(
    ERC20Interface tokenProvided,
    address tokenReceived,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalTokensSold) {
    // Transfer the token from the caller and revert on failure.
    _transferInToken(tokenProvided, msg.sender, tokenProvidedAmount);

    totalTokensSold = _tradeTokenForToken(
      msg.sender,
      tokenProvided,
      tokenReceived,
      tokenProvidedAmount,
      quotedTokenReceivedAmount,
      deadline,
      routeThroughEther
    );
  }

  function tradeTokenForTokenUsingReserves(
    ERC20Interface tokenProvidedFromReserves,
    address tokenReceived,
    uint256 tokenProvidedAmountFromReserves,
    uint256 quotedTokenReceivedAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external onlyOwnerOr(Role.RESERVE_TRADER)  returns (uint256 totalTokensSold) {
    totalTokensSold = _tradeTokenForToken(
      address(this),
      tokenProvidedFromReserves,
      tokenReceived,
      tokenProvidedAmountFromReserves,
      quotedTokenReceivedAmount,
      deadline,
      routeThroughEther
    );
  }

  /**
   * @notice Using `etherAmountFromReserves`, trade for Dai using UniswapV2,
   * and use that Dai to mint Dharma Dai.
   * Only the owner or the trade reserve role can call this function.
   * @param etherAmountFromReserves the amount of Ether to take from reserves
   * and add to the provided amount.
   * @param quotedDaiAmount uint256 The amount of Dai requested in the trade.
   * @param deadline uint256 The timestamp the order is valid until.
   * @return The amount of Dai bought as part of the trade.
   */
  function tradeEtherForDaiUsingReservesAndMintDDaiV2(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (
    uint256 totalDaiBought, uint256 totalDDaiMinted
  ) {
    // Trade Ether for Dai using reserves.
    totalDaiBought = _tradeEtherForDai(
      etherAmountFromReserves, quotedDaiAmount, deadline, true
    );

    // Mint dDai using the received Dai.
    totalDDaiMinted = _DDAI.mint(totalDaiBought);
  }

  function tradeEtherForTokenUsingReserves(
    address token, uint256 etherAmountFromReserves, uint256 quotedTokenAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalEtherSold) {
    // Trade Ether for token using reserves.
    totalEtherSold = _tradeEtherForToken(
      token, etherAmountFromReserves, quotedTokenAmount, deadline, true
    );
  }

  function tradeDaiForTokenUsingReserves(
    address token, uint256 daiAmountFromReserves, uint256 quotedTokenAmount, uint256 deadline, bool routeThroughEther
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalDaiSold) {
    // Redeem dDai if the current Dai balance is less than is required.
    _redeemDDaiIfNecessary(daiAmountFromReserves);

    // Trade Dai for token using reserves.
    totalDaiSold = _tradeDaiForToken(
      token, daiAmountFromReserves, quotedTokenAmount, deadline, routeThroughEther, true
    );
  }

  function tradeTokenForDaiUsingReservesAndMintDDai(
    ERC20Interface token, uint256 tokenAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline, bool routeThroughEther
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (
    uint256 totalDaiBought, uint256 totalDDaiMinted
  ) {
    // Trade the token for Dai using reserves.
    totalDaiBought = _tradeTokenForDai(
      token, tokenAmountFromReserves, quotedDaiAmount, deadline, routeThroughEther, true
    );

    // Mint dDai using the received Dai.
    totalDDaiMinted = _DDAI.mint(totalDaiBought);
  }

  /**
   * @notice Transfer `daiAmount` Dai to `smartWallet`, providing the initial
   * user signing key `initialUserSigningKey` as proof that the specified smart
   * wallet is indeed a Dharma Smart Wallet - this assumes that the address is
   * derived and deployed using the Dharma Smart Wallet Factory V1. In addition,
   * the specified amount must be less than the configured limit amount. Only
   * the owner or the designated deposit manager role may call this function.
   * @param smartWallet address The smart wallet to transfer Dai to.
   * @param initialUserSigningKey address The initial user signing key supplied
   * when deriving the smart wallet address - this could be an EOA or a Dharma
   * key ring address.
   * @param daiAmount uint256 The amount of Dai to transfer - this must be less
   * than the current limit.
   */
  function finalizeDaiDeposit(
    address smartWallet, address initialUserSigningKey, uint256 daiAmount
  ) external onlyOwnerOr(Role.DEPOSIT_MANAGER) {
    // Ensure that the recipient is indeed a smart wallet.
    _ensureSmartWallet(smartWallet, initialUserSigningKey);

    // Ensure that the amount to transfer is lower than the limit.
    require(daiAmount < _daiLimit, "Transfer size exceeds the limit.");

    // Transfer the Dai to the specified smart wallet.
    _transferToken(_DAI, smartWallet, daiAmount);
  }

  /**
   * @notice Transfer `dDaiAmount` Dharma Dai to `smartWallet`, providing the
   * initial user signing key `initialUserSigningKey` as proof that the
   * specified smart wallet is indeed a Dharma Smart Wallet - this assumes that
   * the address is derived and deployed using the Dharma Smart Wallet Factory
   * V1. In addition, the Dai equivalent value of the specified dDai amount must
   * be less than the configured limit amount. Only the owner or the designated
   * deposit manager role may call this function.
   * @param smartWallet address The smart wallet to transfer Dai to.
   * @param initialUserSigningKey address The initial user signing key supplied
   * when deriving the smart wallet address - this could be an EOA or a Dharma
   * key ring address.
   * @param dDaiAmount uint256 The amount of Dharma Dai to transfer - the Dai
   * equivalent amount must be less than the current limit.
   */
  function finalizeDharmaDaiDeposit(
    address smartWallet, address initialUserSigningKey, uint256 dDaiAmount
  ) external onlyOwnerOr(Role.DEPOSIT_MANAGER) {
    // Ensure that the recipient is indeed a smart wallet.
    _ensureSmartWallet(smartWallet, initialUserSigningKey);

    // Get the current dDai exchange rate.
    uint256 exchangeRate = _DDAI.exchangeRateCurrent();

    // Ensure that an exchange rate was actually returned.
    require(exchangeRate != 0, "Could not retrieve dDai exchange rate.");

    // Get the equivalent Dai amount of the transfer.
    uint256 daiEquivalent = (dDaiAmount.mul(exchangeRate)) / 1e18;

    // Ensure that the amount to transfer is lower than the limit.
    require(daiEquivalent < _daiLimit, "Transfer size exceeds the limit.");

    // Transfer the dDai to the specified smart wallet.
    _transferToken(ERC20Interface(address(_DDAI)), smartWallet, dDaiAmount);
  }

  /**
   * @notice Transfer `etherAmount` Ether to `smartWallet`, providing the
   * initial user signing key `initialUserSigningKey` as proof that the
   * specified smart wallet is indeed a Dharma Smart Wallet - this assumes that
   * the address is derived and deployed using the Dharma Smart Wallet Factory
   * V1. In addition, the Ether amount must be less than the configured limit
   * amount. Only the owner or the designated deposit manager role may call this
   * function.
   * @param smartWallet address The smart wallet to transfer Ether to.
   * @param initialUserSigningKey address The initial user signing key supplied
   * when deriving the smart wallet address - this could be an EOA or a Dharma
   * key ring address.
   * @param etherAmount uint256 The amount of Ether to transfer - this amount must be
   * less than the current limit.
   */
  function finalizeEtherDeposit(
    address payable smartWallet,
    address initialUserSigningKey,
    uint256 etherAmount
  ) external onlyOwnerOr(Role.DEPOSIT_MANAGER) {
    // Ensure that the recipient is indeed a smart wallet.
    _ensureSmartWallet(smartWallet, initialUserSigningKey);

    // Ensure that the amount to transfer is lower than the limit.
    require(etherAmount < _etherLimit, "Transfer size exceeds the limit.");

    // Transfer the Ether to the specified smart wallet.
    _transferEther(smartWallet, etherAmount);
  }

  /**
   * @notice Use `daiAmount` Dai mint Dharma Dai. Only the owner or the
   * designated adjuster role may call this function.
   * @param daiAmount uint256 The amount of Dai to supply when minting Dharma
   * Dai.
   * @return The amount of Dharma Dai minted.
   */
  function mint(
    uint256 daiAmount
  ) external onlyOwnerOr(Role.ADJUSTER) returns (uint256 dDaiMinted) {
    // Use the specified amount of Dai to mint dDai.
    dDaiMinted = _DDAI.mint(daiAmount);
  }

  /**
   * @notice Redeem `dDaiAmount` Dharma Dai for Dai. Only the owner or the
   * designated adjuster role may call this function.
   * @param dDaiAmount uint256 The amount of Dharma Dai to supply when redeeming
   * for Dai.
   * @return The amount of Dai received.
   */
  function redeem(
    uint256 dDaiAmount
  ) external onlyOwnerOr(Role.ADJUSTER) returns (uint256 daiReceived) {
    // Redeem the specified amount of dDai for Dai.
    daiReceived = _DDAI.redeem(dDaiAmount);
  }

  /**
   * @notice trade `usdcAmount` USDC for Dharma Dai. Only the owner or the designated
   * adjuster role may call this function.
   * @param usdcAmount uint256 The amount of USDC to supply when trading for Dharma Dai.
   * @param quotedDaiEquivalentAmount uint256 The expected DAI equivalent value of the
   * received dDai - this value is returned from the `getAndExpectedDai` view function
   * on the trade helper.
   * @return The amount of dDai received.
   */
  function tradeUSDCForDDai(
    uint256 usdcAmount,
    uint256 quotedDaiEquivalentAmount
  ) external onlyOwnerOr(Role.ADJUSTER) returns (uint256 dDaiMinted) {
    dDaiMinted = _TRADE_HELPER.tradeUSDCForDDai(
      usdcAmount, quotedDaiEquivalentAmount
    );
  }

  /**
   * @notice tradeDDaiForUSDC `daiEquivalentAmount` Dai amount to trade in Dharma Dai
   * for USDC. Only the owner or the designated adjuster role may call this function.
   * @param daiEquivalentAmount uint256 The Dai equivalent amount to supply in Dharma
   * Dai when trading for USDC.
   * @param quotedUSDCAmount uint256 The expected USDC received in exchange for
   * dDai - this value is returned from the `getExpectedUSDC` view function on the
   * trade helper.
   * @return The amount of USDC received.
   */
  function tradeDDaiForUSDC(
    uint256 daiEquivalentAmount,
    uint256 quotedUSDCAmount
  ) external onlyOwnerOr(Role.ADJUSTER) returns (uint256 usdcReceived) {
    usdcReceived = _TRADE_HELPER.tradeDDaiForUSDC(
      daiEquivalentAmount, quotedUSDCAmount
    );
  }

  function refillGasReserve(uint256 etherAmount) external onlyOwnerOr(Role.GAS_RESERVE_REFILLER) {
    // Transfer the Ether to the gas reserve.
    _transferEther(_GAS_RESERVE, etherAmount);

    emit GasReserveRefilled(etherAmount);
  }

  /**
   * @notice Transfer `usdcAmount` USDC for to the current primary recipient set by the
   * owner. Only the owner or the designated withdrawal manager role may call this function.
   * @param usdcAmount uint256 The amount of USDC to transfer to the primary recipient.
   */
  function withdrawUSDCToPrimaryRecipient(
    uint256 usdcAmount
  ) external onlyOwnerOr(Role.WITHDRAWAL_MANAGER) {
    // Get the current primary recipient.
    address primaryRecipient = _primaryUSDCRecipient;
    require(
      primaryRecipient != address(0), "No USDC primary recipient currently set."
    );

    // Transfer the supplied USDC amount to the primary recipient.
    _transferToken(_USDC, primaryRecipient, usdcAmount);
  }

  /**
   * @notice Transfer `daiAmount` Dai for to the current primary recipient set by the
   * owner. Only the owner or the designated withdrawal manager role may call this function.
   * @param daiAmount uint256 The amount of Dai to transfer to the primary recipient.
   */
  function withdrawDaiToPrimaryRecipient(
    uint256 daiAmount
  ) external onlyOwnerOr(Role.WITHDRAWAL_MANAGER) {
    // Get the current primary recipient.
    address primaryRecipient = _primaryDaiRecipient;
    require(
      primaryRecipient != address(0), "No Dai primary recipient currently set."
    );

    // Transfer the supplied Dai amount to the primary recipient.
    _transferToken(_DAI, primaryRecipient, daiAmount);
  }

  /**
   * @notice Transfer `usdcAmount` USDC to `recipient`. Only the owner may call
   * this function.
   * @param recipient address The account to transfer USDC to.
   * @param usdcAmount uint256 The amount of USDC to transfer.
   */
  function withdrawUSDC(
    address recipient, uint256 usdcAmount
  ) external onlyOwner {
    // Transfer the USDC to the specified recipient.
    _transferToken(_USDC, recipient, usdcAmount);
  }

  /**
   * @notice Transfer `daiAmount` Dai to `recipient`. Only the owner may call
   * this function.
   * @param recipient address The account to transfer Dai to.
   * @param daiAmount uint256 The amount of Dai to transfer.
   */
  function withdrawDai(
    address recipient, uint256 daiAmount
  ) external onlyOwner {
    // Transfer the Dai to the specified recipient.
    _transferToken(_DAI, recipient, daiAmount);
  }

  /**
   * @notice Transfer `dDaiAmount` Dharma Dai to `recipient`. Only the owner may
   * call this function.
   * @param recipient address The account to transfer Dharma Dai to.
   * @param dDaiAmount uint256 The amount of Dharma Dai to transfer.
   */
  function withdrawDharmaDai(
    address recipient, uint256 dDaiAmount
  ) external onlyOwner {
    // Transfer the dDai to the specified recipient.
    _transferToken(ERC20Interface(address(_DDAI)), recipient, dDaiAmount);
  }

  /**
   * @notice Transfer `etherAmount` Ether to `recipient`. Only the owner may
   * call this function.
   * @param recipient address The account to transfer Ether to.
   * @param etherAmount uint256 The amount of Ether to transfer.
   */
  function withdrawEther(
    address payable recipient, uint256 etherAmount
  ) external onlyOwner {
    // Transfer the Ether to the specified recipient.
    _transferEther(recipient, etherAmount);
  }

  /**
   * @notice Transfer `amount` of ERC20 token `token` to `recipient`. Only the
   * owner may call this function.
   * @param token ERC20Interface The ERC20 token to transfer.
   * @param recipient address The account to transfer the tokens to.
   * @param amount uint256 The amount of tokens to transfer.
   * @return A boolean to indicate if the transfer was successful - note that
   * unsuccessful ERC20 transfers will usually revert.
   */
  function withdraw(
    ERC20Interface token, address recipient, uint256 amount
  ) external onlyOwner returns (bool success) {
    // Transfer the token to the specified recipient.
    success = token.transfer(recipient, amount);
  }

  /**
   * @notice Call account `target`, supplying value `amount` and data `data`.
   * Only the owner may call this function.
   * @param target address The account to call.
   * @param amount uint256 The amount of ether to include as an endowment.
   * @param data bytes The data to include along with the call.
   * @return A boolean to indicate if the call was successful, as well as the
   * returned data or revert reason.
   */
  function callAny(
    address payable target, uint256 amount, bytes calldata data
  ) external onlyOwner returns (bool ok, bytes memory returnData) {
    // Call the specified target and supply the specified data.
    (ok, returnData) = target.call.value(amount)(data);
  }

  /**
   * @notice Set `daiAmount` as the new limit on the size of finalized deposits.
   * Only the owner may call this function.
   * @param daiAmount uint256 The new limit on the size of finalized deposits.
   */
  function setDaiLimit(uint256 daiAmount) external onlyOwner {
    // Set the new limit.
    _daiLimit = daiAmount;
  }

  /**
   * @notice Set `etherAmount` as the new limit on the size of finalized deposits.
   * Only the owner may call this function.
   * @param etherAmount uint256 The new limit on the size of finalized deposits.
   */
  function setEtherLimit(uint256 etherAmount) external onlyOwner {
    // Set the new limit.
    _etherLimit = etherAmount;
  }

  /**
   * @notice Set `recipient` as the new primary recipient for USDC withdrawals.
   * Only the owner may call this function.
   * @param recipient address The new primary recipient.
   */
  function setPrimaryUSDCRecipient(address recipient) external onlyOwner {
    // Set the new primary recipient.
    _primaryUSDCRecipient = recipient;
  }

  /**
   * @notice Set `recipient` as the new primary recipient for Dai withdrawals.
   * Only the owner may call this function.
   * @param recipient address The new primary recipient.
   */
  function setPrimaryDaiRecipient(address recipient) external onlyOwner {
    // Set the new primary recipient.
    _primaryDaiRecipient = recipient;
  }

  /**
   * @notice Pause a currently unpaused role and emit a `RolePaused` event. Only
   * the owner or the designated pauser may call this function. Also, bear in
   * mind that only the owner may unpause a role once paused.
   * @param role The role to pause.
   */
  function pause(Role role) external onlyOwnerOr(Role.PAUSER) {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(!storedRoleStatus.paused, "Role in question is already paused.");
    storedRoleStatus.paused = true;
    emit RolePaused(role);
  }

  /**
   * @notice Unpause a currently paused role and emit a `RoleUnpaused` event.
   * Only the owner may call this function.
   * @param role The role to pause.
   */
  function unpause(Role role) external onlyOwner {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(storedRoleStatus.paused, "Role in question is already unpaused.");
    storedRoleStatus.paused = false;
    emit RoleUnpaused(role);
  }

  /**
   * @notice Set a new account on a given role and emit a `RoleModified` event
   * if the role holder has changed. Only the owner may call this function.
   * @param role The role that the account will be set for.
   * @param account The account to set as the designated role bearer.
   */
  function setRole(Role role, address account) external onlyOwner {
    require(account != address(0), "Must supply an account.");
    _setRole(role, account);
  }

  /**
   * @notice Remove any current role bearer for a given role and emit a
   * `RoleModified` event if a role holder was previously set. Only the owner
   * may call this function.
   * @param role The role that the account will be removed from.
   */
  function removeRole(Role role) external onlyOwner {
    _setRole(role, address(0));
  }

  /**
   * @notice External view function to check whether or not the functionality
   * associated with a given role is currently paused or not. The owner or the
   * pauser may pause any given role (including the pauser itself), but only the
   * owner may unpause functionality. Additionally, the owner may call paused
   * functions directly.
   * @param role The role to check the pause status on.
   * @return A boolean to indicate if the functionality associated with the role
   * in question is currently paused.
   */
  function isPaused(Role role) external view returns (bool paused) {
    paused = _isPaused(role);
  }

  /**
   * @notice External view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for.
   * @return A boolean indicating if the caller has the specified role.
   */
  function isRole(Role role) external view returns (bool hasRole) {
    hasRole = _isRole(role);
  }

  /**
   * @notice External view function to check whether a "proof" that a given
   * smart wallet is actually a Dharma Smart Wallet, based on the initial user
   * signing key, is valid or not. This proof only works when the Dharma Smart
   * Wallet in question is derived using V1 of the Dharma Smart Wallet Factory.
   * @param smartWallet address The smart wallet to check.
   * @param initialUserSigningKey address The initial user signing key supplied
   * when deriving the smart wallet address - this could be an EOA or a Dharma
   * key ring address.
   * @return A boolean indicating if the specified smart wallet account is
   * indeed a smart wallet based on the specified initial user signing key.
   */
  function isDharmaSmartWallet(
    address smartWallet, address initialUserSigningKey
  ) external view returns (bool dharmaSmartWallet) {
    dharmaSmartWallet = _isSmartWallet(smartWallet, initialUserSigningKey);
  }

  /**
   * @notice External view function to check the account currently holding the
   * deposit manager role. The deposit manager can process standard deposit
   * finalization via `finalizeDaiDeposit` and `finalizeDharmaDaiDeposit`, but
   * must prove that the recipient is a Dharma Smart Wallet and adhere to the
   * current deposit size limit.
   * @return The address of the current deposit manager, or the null address if
   * none is set.
   */
  function getDepositManager() external view returns (address depositManager) {
    depositManager = _roles[uint256(Role.DEPOSIT_MANAGER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * adjuster role. The adjuster can exchange Dai in reserves for Dharma Dai and
   * vice-versa via minting or redeeming.
   * @return The address of the current adjuster, or the null address if none is
   * set.
   */
  function getAdjuster() external view returns (address adjuster) {
    adjuster = _roles[uint256(Role.ADJUSTER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * reserve trader role. The reserve trader can trigger trades that utilize
   * reserves in addition to supplied funds, if any.
   * @return The address of the current reserve trader, or the null address if
   * none is set.
   */
  function getReserveTrader() external view returns (address reserveTrader) {
    reserveTrader = _roles[uint256(Role.RESERVE_TRADER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * withdrawal manager role. The withdrawal manager can transfer USDC to the
   * "primary recipient" address set by the owner.
   * @return The address of the current withdrawal manager, or the null address
   * if none is set.
   */
  function getWithdrawalManager() external view returns (address withdrawalManager) {
    withdrawalManager = _roles[uint256(Role.WITHDRAWAL_MANAGER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * pauser role. The pauser can pause any role from taking its standard action,
   * though the owner will still be able to call the associated function in the
   * interim and is the only entity able to unpause the given role once paused.
   * @return The address of the current pauser, or the null address if none is
   * set.
   */
  function getPauser() external view returns (address pauser) {
    pauser = _roles[uint256(Role.PAUSER)].account;
  }

  function getGasReserveRefiller() external view returns (address gasReserveRefiller) {
    gasReserveRefiller = _roles[uint256(Role.GAS_RESERVE_REFILLER)].account;
  }

  /**
   * @notice External view function to check the current reserves held by this
   * contract.
   * @return The Dai and Dharma Dai reserves held by this contract, as well as
   * the Dai-equivalent value of the Dharma Dai reserves.
   */
  function getReserves() external view returns (
    uint256 dai, uint256 dDai, uint256 dDaiUnderlying
  ) {
    dai = _DAI.balanceOf(address(this));
    dDai = _DDAI.balanceOf(address(this));
    dDaiUnderlying = _DDAI.balanceOfUnderlying(address(this));
  }

  /**
   * @notice External view function to check the current limit on deposit amount
   * enforced for the deposit manager when finalizing deposits, expressed in Dai
   * and in Dharma Dai.
   * @return The Dai and Dharma Dai limit on deposit finalization amount.
   */
  function getDaiLimit() external view returns (
    uint256 daiAmount, uint256 dDaiAmount
  ) {
    daiAmount = _daiLimit;
    dDaiAmount = (daiAmount.mul(1e18)).div(_DDAI.exchangeRateCurrent());
  }

  /**
   * @notice External view function to check the current limit on deposit amount
   * enforced for the deposit manager when finalizing Ether deposits.
   * @return The Ether limit on deposit finalization amount.
   */
  function getEtherLimit() external view returns (uint256 etherAmount) {
    etherAmount = _etherLimit;
  }

  /**
   * @notice External view function to check the address of the current
   * primary recipient for USDC.
   * @return The primary recipient for USDC.
   */
  function getPrimaryUSDCRecipient() external view returns (
    address recipient
  ) {
    recipient = _primaryUSDCRecipient;
  }

  /**
   * @notice External view function to check the address of the current
   * primary recipient for Dai.
   * @return The primary recipient for Dai.
   */
  function getPrimaryDaiRecipient() external view returns (
    address recipient
  ) {
    recipient = _primaryDaiRecipient;
  }

  /**
   * @notice External view function to check the current implementation
   * of this contract (i.e. the "logic" for the contract).
   * @return The current implementation for this contract.
   */
  function getImplementation() external view returns (
    address implementation
  ) {
    (bool ok, bytes memory returnData) = address(
      0x481B1a16E6675D33f8BBb3a6A58F5a9678649718
    ).staticcall("");
    require(ok && returnData.length == 32, "Invalid implementation.");
    implementation = abi.decode(returnData, (address));
  }

  /**
   * @notice External pure function to get the address of the actual
   * contract instance (i.e. the "storage" foor this contract).
   * @return The address of this contract instance.
   */
  function getInstance() external pure returns (address instance) {
    instance = address(0x09cd826D4ABA4088E1381A1957962C946520952d);

  }

  function getVersion() external view returns (uint256 version) {
    version = _VERSION;
  }

  function _grantUniswapRouterApprovalIfNecessary(ERC20Interface token, uint256 amount) internal {
    if (token.allowance(address(this), address(_UNISWAP_ROUTER)) < amount) {
      // Try removing approval for Uniswap router first as a workaround for unusual tokens.
      (bool success, bytes memory data) = address(token).call(
        abi.encodeWithSelector(
          token.approve.selector, address(_UNISWAP_ROUTER), uint256(0)
        )
      );

      // Grant approval for Uniswap router to transfer tokens on behalf of this contract.
      (success, data) = address(token).call(
        abi.encodeWithSelector(
          token.approve.selector, address(_UNISWAP_ROUTER), uint256(-1)
        )
      );

      if (!success) {
        // Some really janky tokens only allow setting approval up to current balance.
        (success, data) = address(token).call(
          abi.encodeWithSelector(
            token.approve.selector, address(_UNISWAP_ROUTER), amount
          )
        );
      }

      require(
        success && (data.length == 0 || abi.decode(data, (bool))),
        "Token approval for Uniswap router failed."
      );
    }
  }

  function _tradeEtherForDai(
    uint256 etherAmount, uint256 quotedDaiAmount, uint256 deadline, bool fromReserves
  ) internal returns (uint256 totalDaiBought) {
    // Establish path from Ether to Dai.
    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      _WETH, address(_DAI), false
    );

    // Trade Ether for Dai on Uniswap (send to this contract).
    amounts = _UNISWAP_ROUTER.swapExactETHForTokens.value(etherAmount)(
      quotedDaiAmount, path, address(this), deadline
    );
    totalDaiBought = amounts[1];

    _fireTradeEvent(
      fromReserves,
      TradeType.ETH_TO_DAI,
      address(0),
      etherAmount,
      quotedDaiAmount,
      totalDaiBought.sub(quotedDaiAmount)
    );
  }

  function _tradeDaiForEther(
    uint256 daiAmount, uint256 quotedEtherAmount, uint256 deadline, bool fromReserves
  ) internal returns (uint256 totalDaiSold) {
    // Establish path from Dai to Ether.
    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(_DAI), _WETH, false
    );

    // Trade Dai for quoted Ether amount on Uniswap (send to appropriate recipient).
    amounts = _UNISWAP_ROUTER.swapTokensForExactETH(
      quotedEtherAmount, daiAmount, path, fromReserves ? address(this) : msg.sender, deadline
    );
    totalDaiSold = amounts[0];

    _fireTradeEvent(
      fromReserves,
      TradeType.DAI_TO_ETH,
      address(0),
      daiAmount,
      quotedEtherAmount,
      daiAmount.sub(totalDaiSold)
    );
  }

  /**
  * @notice Internal trade function. If token is _TRADE_FOR_USDC_AND_RETAIN_FLAG,
  * trade for USDC and retain the full output amount by replacing the recipient
  * ("to" input) on the swapETHForExactTokens call.
  */
  function _tradeEtherForToken(
    address tokenReceivedOrUSDCFlag, uint256 etherAmount, uint256 quotedTokenAmount, uint256 deadline, bool fromReserves
  ) internal returns (uint256 totalEtherSold) {

    // Set swap target token
    address tokenReceived = tokenReceivedOrUSDCFlag == _TRADE_FOR_USDC_AND_RETAIN_FLAG 
      ? address(_USDC) 
      : tokenReceivedOrUSDCFlag;

    // Establish path from Ether to token.
    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      _WETH, tokenReceived, false
    );

    // Trade Ether for quoted token amount on Uniswap and send to appropriate recipient.
    amounts = _UNISWAP_ROUTER.swapETHForExactTokens.value(etherAmount)(
      quotedTokenAmount,
      path,
      fromReserves || tokenReceivedOrUSDCFlag == _TRADE_FOR_USDC_AND_RETAIN_FLAG 
        ? address(this)
        : msg.sender,
      deadline
    );
    totalEtherSold = amounts[0];

    _fireTradeEvent(
      fromReserves,
      TradeType.ETH_TO_TOKEN,
      tokenReceivedOrUSDCFlag,
      etherAmount,
      quotedTokenAmount,
      etherAmount.sub(totalEtherSold)
    );
  }

  function _tradeTokenForEther(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedEtherAmount,
    uint256 deadline,
    bool fromReserves
  ) internal returns (uint256 totalEtherBought) {
    // Approve Uniswap router to transfer tokens on behalf of this contract.
    _grantUniswapRouterApprovalIfNecessary(token, tokenAmount);

    // Establish path from target token to Ether.
    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(token), _WETH, false
    );

    // Trade tokens for quoted Ether amount on Uniswap (send to this contract).
    amounts = _UNISWAP_ROUTER.swapExactTokensForETH(
      tokenAmount, quotedEtherAmount, path, address(this), deadline
    );
    totalEtherBought = amounts[1];

    _fireTradeEvent(
      fromReserves,
      TradeType.TOKEN_TO_ETH,
      address(token),
      tokenAmount,
      quotedEtherAmount,
      totalEtherBought.sub(quotedEtherAmount)
    );
  }

  function _tradeDaiForToken(
    address token,
    uint256 daiAmount,
    uint256 quotedTokenAmount,
    uint256 deadline,
    bool routeThroughEther,
    bool fromReserves
  ) internal returns (uint256 totalDaiSold) {
    // Establish path (direct or routed through Ether) from Dai to target token.
    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(_DAI), address(token), routeThroughEther
    );

    // Trade the Dai for the quoted token amount on Uniswap and send to appropriate recipient.
    amounts = _UNISWAP_ROUTER.swapTokensForExactTokens(
      quotedTokenAmount, daiAmount, path, fromReserves ? address(this) : msg.sender, deadline
    );

    totalDaiSold = amounts[0];

    _fireTradeEvent(
      fromReserves,
      TradeType.DAI_TO_TOKEN,
      address(token),
      daiAmount,
      quotedTokenAmount,
      daiAmount.sub(totalDaiSold)
    );
  }

  function _tradeTokenForDai(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedDaiAmount,
    uint256 deadline,
    bool routeThroughEther,
    bool fromReserves
  ) internal returns (uint256 totalDaiBought) {
    // Approve Uniswap router to transfer tokens on behalf of this contract.
    _grantUniswapRouterApprovalIfNecessary(token, tokenAmount);

    // Establish path (direct or routed through Ether) from target token to Dai.
    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(token), address(_DAI), routeThroughEther
    );

    // Trade the Dai for the quoted token amount on Uniswap (send to this contract).
    amounts = _UNISWAP_ROUTER.swapExactTokensForTokens(
      tokenAmount, quotedDaiAmount, path, address(this), deadline
    );

    totalDaiBought = amounts[path.length - 1];

    _fireTradeEvent(
      fromReserves,
      TradeType.TOKEN_TO_DAI,
      address(token),
      tokenAmount,
      quotedDaiAmount,
      totalDaiBought.sub(quotedDaiAmount)
    );
  }

  /**
  * @notice Internal trade function. If tokenReceived is _TRADE_FOR_USDC_AND_RETAIN_FLAG,
  * trade for USDC and retain the full output amount by replacing the recipient
  * ("to" input) on the swapTokensForExactTokens call.
  */
  function _tradeTokenForToken(
    address account,
    ERC20Interface tokenProvided,
    address tokenReceivedOrUSDCFlag,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 deadline,
    bool routeThroughEther
  ) internal returns (uint256 totalTokensSold) {
    uint256 retainedAmount;
    address tokenRecieved;
    address recipient;

    // Approve Uniswap router to transfer tokens on behalf of this contract.
    _grantUniswapRouterApprovalIfNecessary(tokenProvided, tokenProvidedAmount);

    // Set recipient, swap target token
    if (tokenReceivedOrUSDCFlag == _TRADE_FOR_USDC_AND_RETAIN_FLAG) {
      recipient = address(this);
      tokenRecieved = address(_USDC);
    } else {
      recipient = account;
      tokenRecieved = tokenReceivedOrUSDCFlag;
    }

    if (routeThroughEther == false) {
      // Establish direct path between tokens.
      (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
        address(tokenProvided), tokenRecieved, false
      );

      // Trade for the quoted token amount on Uniswap and send to recipient.
      amounts = _UNISWAP_ROUTER.swapTokensForExactTokens(
        quotedTokenReceivedAmount, tokenProvidedAmount, path, recipient, deadline
      );

      totalTokensSold = amounts[0];
      retainedAmount = tokenProvidedAmount.sub(totalTokensSold);
    } else {
      // Establish path between provided token and WETH.
      (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
        address(tokenProvided), _WETH, false
      );

      // Trade all provided tokens for WETH on Uniswap and send to this contract.
      amounts = _UNISWAP_ROUTER.swapExactTokensForTokens(
        tokenProvidedAmount, 0, path, address(this), deadline
      );
      retainedAmount = amounts[1];

      // Establish path between WETH and received token.
      (path, amounts) = _createPathAndAmounts(
        _WETH, tokenRecieved, false
      );

      // Trade bought WETH for received token on Uniswap and send to recipient.
      amounts = _UNISWAP_ROUTER.swapTokensForExactTokens(
        quotedTokenReceivedAmount, retainedAmount, path, recipient, deadline
      );

      totalTokensSold = amounts[0];
      retainedAmount = retainedAmount.sub(totalTokensSold);
    }

    emit Trade(
      account,
      address(tokenProvided),
      tokenReceivedOrUSDCFlag,
      routeThroughEther ? _WETH : address(tokenProvided),
      tokenProvidedAmount,
      quotedTokenReceivedAmount,
      retainedAmount
    );
  }

  /**
   * @notice Internal function to set a new account on a given role and emit a
   * `RoleModified` event if the role holder has changed.
   * @param role The role that the account will be set for. Permitted roles are
   * deposit manager (0), adjuster (1), and pauser (2).
   * @param account The account to set as the designated role bearer.
   */
  function _setRole(Role role, address account) internal {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];

    if (account != storedRoleStatus.account) {
      storedRoleStatus.account = account;
      emit RoleModified(role, account);
    }
  }

  function _fireTradeEvent(
    bool fromReserves,
    TradeType tradeType,
    address token,
    uint256 suppliedAmount,
    uint256 receivedAmount,
    uint256 retainedAmount
  ) internal {
    uint256 t = uint256(tradeType);

    emit Trade(
      fromReserves ? address(this) : msg.sender,
      t < 2 ? address(_DAI) : (t % 2 == 0 ? address(0) : token),
      (t > 1 && t < 4) ? address(_DAI) : (t % 2 == 0 ? token : address(0)),
      t < 4 ? address(_DAI) : address(0),
      suppliedAmount,
      receivedAmount,
      retainedAmount
    );
  }

  /**
   * @notice Internal view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for.
   * @return A boolean indicating if the caller has the specified role.
   */
  function _isRole(Role role) internal view returns (bool hasRole) {
    hasRole = msg.sender == _roles[uint256(role)].account;
  }

  /**
   * @notice Internal view function to check whether the given role is paused or
   * not.
   * @param role The role to check for.
   * @return A boolean indicating if the specified role is paused or not.
   */
  function _isPaused(Role role) internal view returns (bool paused) {
    paused = _roles[uint256(role)].paused;
  }

  /**
   * @notice Internal view function to enforce that the given initial user signing
   * key resolves to the given smart wallet when deployed through the Dharma Smart
   * Wallet Factory V1. (staging version)
   * @param smartWallet address The smart wallet.
   * @param initialUserSigningKey address The initial user signing key.
   */
  function _isSmartWallet(
    address smartWallet, address initialUserSigningKey
  ) internal pure returns (bool) {
    // Derive the keccak256 hash of the smart wallet initialization code.
    bytes32 initCodeHash = keccak256(
      abi.encodePacked(
        _WALLET_CREATION_CODE_HEADER,
        initialUserSigningKey,
        _WALLET_CREATION_CODE_FOOTER
      )
    );

    // Attempt to derive a smart wallet address that matches the one provided.
    address target;
    for (uint256 nonce = 0; nonce < 10; nonce++) {
      target = address(          // derive the target deployment address.
        uint160(                 // downcast to match the address type.
          uint256(               // cast to uint to truncate upper digits.
            keccak256(           // compute CREATE2 hash using all inputs.
              abi.encodePacked(  // pack all inputs to the hash together.
                _CREATE2_HEADER, // pass in control character + factory address.
                nonce,           // pass in current nonce as the salt.
                initCodeHash     // pass in hash of contract creation code.
              )
            )
          )
        )
      );

      // Exit early if the provided smart wallet matches derived target address.
      if (target == smartWallet) {
        return true;
      }

      // Otherwise, increment the nonce and derive a new salt.
      nonce++;
    }

    // Explicity recognize no target was found matching provided smart wallet.
    return false;
  }

  function _redeemDDaiIfNecessary(uint256 daiAmountFromReserves) internal {
    uint256 daiBalance = _DAI.balanceOf(address(this));
    if (daiBalance < daiAmountFromReserves) {
      uint256 additionalDaiRequired = daiAmountFromReserves - daiBalance;
      _DDAI.redeemUnderlying(additionalDaiRequired);
    }
  }

  function _transferToken(ERC20Interface token, address to, uint256 amount) internal {
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.transfer.selector, to, amount)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'Transfer out failed.'
    );
  }

  function _transferEther(address recipient, uint256 etherAmount) internal {
    // Send quoted Ether amount to recipient and revert with reason on failure.
    (bool ok, ) = recipient.call.value(etherAmount)("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }

  function _transferInToken(ERC20Interface token, address from, uint256 amount) internal {
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.transferFrom.selector, from, address(this), amount)
    );

    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'Transfer in failed.'
    );
  }

  function _ensureSmartWallet(
    address smartWallet, address initialUserSigningKey
  ) internal pure {
    require(
      _isSmartWallet(smartWallet, initialUserSigningKey),
      "Could not resolve smart wallet using provided signing key."
    );
  }

  function _createPathAndAmounts(
    address start, address end, bool routeThroughEther
  ) internal pure returns (address[] memory, uint256[] memory) {
    uint256 pathLength = routeThroughEther ? 3 : 2;
    address[] memory path = new address[](pathLength);
    path[0] = start;

    if (routeThroughEther) {
      path[1] = _WETH;
    }

    path[pathLength - 1] = end;

    return (path, new uint256[](pathLength));
  }

  /**
   * @notice Modifier that throws if called by any account other than the owner
   * or the supplied role, or if the caller is not the owner and the role in
   * question is paused.
   * @param role The role to require unless the caller is the owner.
   */
  modifier onlyOwnerOr(Role role) {
    if (!isOwner()) {
      require(_isRole(role), "Caller does not have a required role.");
      require(!_isPaused(role), "Role in question is currently paused.");
    }
    _;
  }
}