/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface ITypes {
  struct Call {
    address to;
    uint96 value;
    bytes data;
  }

  struct CallReturn {
    bool ok;
    bytes returnData;
  }
}

interface IActionRegistry {

  // events
  event AddedSelector(address account, bytes4 selector);
  event RemovedSelector(address account, bytes4 selector);
  event AddedSpender(address account, address spender);
  event RemovedSpender(address account, address spender);

  struct AccountSelectors {
    address account;
    bytes4[] selectors;
  }

  struct AccountSpenders {
    address account;
    address[] spenders;
  }

  function isValidAction(ITypes.Call[] calldata calls) external view returns (bool valid);
  function addSelector(address account, bytes4 selector) external;
  function removeSelector(address account, bytes4 selector) external;
  function addSpender(address account, address spender) external;
  function removeSpender(address account, address spender) external;
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * In order to transfer ownership, a recipient must be specified, at which point
 * the specified recipient can call `acceptOwnership` and take ownership.
 */

contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initialize contract by setting transaction submitter as initial owner.
   */
  constructor() public {
    _owner = tx.origin;
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
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
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
  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }

  /**
   * @dev Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}

interface DharmaTradeReserveV19Interface {
  event Trade(
    address account,
    address suppliedAsset,
    address receivedAsset,
    address retainedAsset,
    uint256 suppliedAmount,
    uint256 recievedAmount, // note: typo
    uint256 retainedAmount
  );
  event RoleModified(Role indexed role, address account);
  event RolePaused(Role indexed role);
  event RoleUnpaused(Role indexed role);
  event EtherReceived(address sender, uint256 amount);
  event GasReserveRefilled(uint256 etherAmount);

  enum Role {            //
    DEPOSIT_MANAGER,     // 0
    ADJUSTER,            // 1
    WITHDRAWAL_MANAGER,  // 2
    RESERVE_TRADER,      // 3
    PAUSER,              // 4
    GAS_RESERVE_REFILLER, // 5
    ACTIONER // 6
  }

  enum FeeType {    // #
    SUPPLIED_ASSET, // 0
    RECEIVED_ASSET, // 1
    ETHER           // 2
  }

  enum TradeType {
    ETH_TO_TOKEN,
    TOKEN_TO_ETH,
    TOKEN_TO_TOKEN,
    ETH_TO_TOKEN_WITH_TRANSFER_FEE,
    TOKEN_TO_ETH_WITH_TRANSFER_FEE,
    TOKEN_TO_TOKEN_WITH_TRANSFER_FEE
  }

  struct RoleStatus {
    address account;
    bool paused;
  }

  function simulate(
    ITypes.Call[] calldata calls
  ) external returns (bool[] memory ok, bytes[] memory returnData, bool validCalls);

  function execute(
    ITypes.Call[] calldata calls
  ) external returns (bool[] memory ok, bytes[] memory returnData);

  event CallSuccess(
    bool rolledBack,
    address to,
    uint256 value,
    bytes data,
    bytes returnData
  );

  event CallFailure(
    address to,
    uint256 value,
    bytes data,
    string revertReason
  );

  function tradeTokenForTokenSpecifyingFee(
    ERC20Interface tokenProvided,
    address tokenReceived,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 maximumFeeAmount, // WETH if routeThroughEther, else tokenReceived
    uint256 deadline,
    bool routeThroughEther,
    FeeType feeType
  ) external returns (uint256 totalTokensBought);

  function tradeTokenForTokenWithFeeOnTransfer(
    ERC20Interface tokenProvided,
    address tokenReceived,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 quotedTokenReceivedAmountAfterTransferFee,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalTokensBought);

  function tradeTokenForTokenWithFeeOnTransferSpecifyingFee(
    ERC20Interface tokenProvided,
    address tokenReceived,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 quotedTokenReceivedAmountAfterTransferFee,
    uint256 maximumFeeAmount, // WETH if routeThroughEther, else tokenReceived
    uint256 deadline,
    bool routeThroughEther,
    FeeType feeType
  ) external returns (uint256 totalTokensBought);

  function tradeTokenForTokenUsingReservesWithFeeOnTransferSpecifyingFee(
    ERC20Interface tokenProvidedFromReserves,
    address tokenReceived,
    uint256 tokenProvidedAmountFromReserves,
    uint256 quotedTokenReceivedAmount,
    uint256 maximumFeeAmount, // WETH if routeThroughEther, else tokenReceived
    uint256 deadline,
    bool routeThroughEther,
    FeeType feeType
  ) external returns (uint256 totalTokensBought);

  function tradeTokenForEtherWithFeeOnTransfer(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalEtherBought);

  function tradeTokenForEtherWithFeeOnTransferSpecifyingFee(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedEtherAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external returns (uint256 totalEtherBought);

  function tradeTokenForEtherUsingReservesWithFeeOnTransferSpecifyingFee(
    ERC20Interface token,
    uint256 tokenAmountFromReserves,
    uint256 quotedEtherAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external returns (uint256 totalEtherBought);

  function tradeTokenForEtherSpecifyingFee(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedEtherAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external returns (uint256 totalEtherBought);

  function tradeEtherForTokenWithFeeOnTransfer(
    address token,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 deadline
  ) external payable returns (uint256 totalTokensBought);

  function tradeEtherForTokenSpecifyingFee(
    address token,
    uint256 quotedTokenAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external payable returns (uint256 totalTokensBought);

  function tradeEtherForTokenWithFeeOnTransferSpecifyingFee(
    address token,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external payable returns (uint256 totalTokensBought);

  function tradeEtherForTokenWithFeeOnTransferUsingEtherizer(
    address token,
    uint256 etherAmount,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 deadline
  ) external returns (uint256 totalTokensBought);

  function tradeTokenForTokenUsingReservesSpecifyingFee(
    ERC20Interface tokenProvidedFromReserves,
    address tokenReceived,
    uint256 tokenProvidedAmountFromReserves,
    uint256 quotedTokenReceivedAmount,
    uint256 maximumFeeAmount, // WETH if routeThroughEther, else tokenReceived
    uint256 deadline,
    bool routeThroughEther,
    FeeType feeType
  ) external returns (uint256 totalTokensBought);

  function tradeEtherForTokenUsingReservesWithFeeOnTransferSpecifyingFee(
    address token,
    uint256 etherAmountFromReserves,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external returns (uint256 totalTokensBought);

  function tradeTokenForEtherUsingReservesSpecifyingFee(
    ERC20Interface token,
    uint256 tokenAmountFromReserves,
    uint256 quotedEtherAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external returns (uint256 totalEtherBought);

  function tradeEtherForTokenUsingReservesSpecifyingFee(
    address token,
    uint256 etherAmountFromReserves,
    uint256 quotedTokenAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external returns (uint256 totalTokensBought);

  function finalizeEtherDeposit(
    address payable smartWallet,
    address initialUserSigningKey,
    uint256 etherAmount
  ) external;

  function finalizeTokenDeposit(
    address smartWallet,
    address initialUserSigningKey,
    ERC20Interface token,
    uint256 amount
  ) external;

  function refillGasReserve(uint256 etherAmount) external;

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

  function getReserveTrader() external view returns (address reserveTrader);

  function getWithdrawalManager() external view returns (
    address withdrawalManager
  );

  function getActioner() external view returns (
    address actioner
  );

  function getPauser() external view returns (address pauser);

  function getGasReserveRefiller() external view returns (
    address gasReserveRefiller
  );

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
  function balanceOf(address) external view returns (uint256);
  function balanceOfUnderlying(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function exchangeRateCurrent() external view returns (uint256);
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

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;
}

library SafeMath {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


/**
 * @title DharmaTradeReserveV19Implementation
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
 *
 * Note that "proofs" can be validated via `isSmartWallet`.
 */
contract DharmaTradeReserveV19ImplementationStaging is DharmaTradeReserveV19Interface, TwoStepOwnable {
  using SafeMath for uint256;

  // Maintain a role status mapping with assigned accounts and paused states.
  mapping(uint256 => RoleStatus) private _roles;

  // Maintain a "primary recipient" the withdrawal manager can transfer Dai to.
  address private _primaryDaiRecipient;

  // Maintain a "primary recipient" the withdrawal manager can transfer USDC to.
  address private _primaryUSDCRecipient;

  // Maintain a maximum allowable transfer size (in Dai) for the deposit manager.
  uint256 private _daiLimit; // unused

  // Maintain a maximum allowable transfer size (in Ether) for the deposit manager.
  uint256 private _etherLimit; // unused

  bool private _originatesFromReserveTrader; // unused, don't change storage layout

  bytes4 internal _selfCallContext;

  uint256 private constant _VERSION = 1019;

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

  UniswapV2Interface internal constant _UNISWAP_ROUTER = UniswapV2Interface(
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  );

  address internal constant _WETH = address(
    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
  );

  address internal constant _GAS_RESERVE = address(
    0x09cd826D4ABA4088E1381A1957962C946520952d
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
  address internal constant _TRADE_FOR_USDC_AND_RETAIN_FLAG = address(type(uint160).max);

  // The "action registry" keeps track of function-selectors and approved spenders
  // allowed in the generic call execution flow.
  IActionRegistry public immutable _ACTION_REGISTRY;

  address private constant V17_STAGING = address(
    0x1C2c285A9B4a5985120D5493C8Aa24C347d0B2A9
  );

  // Include a payable fallback so that the contract can receive Ether payments.
  receive() external payable {
    emit EtherReceived(msg.sender, msg.value);
  }

  constructor(address actionRegistryAddress) public {
    _ACTION_REGISTRY = IActionRegistry(actionRegistryAddress);
  }

  /**
  * @notice Simulate a series of generic calls to other contracts.
  * Calls will be rolled back (and calls will only be
  * simulated up until a failing call is encountered).
  * @param calls Call[] A struct containing the target, value, and calldata to
  * provide when making each call.
  * return An array of structs signifying the status of each call, as well as
  * any data returned from that call. Calls that are not executed will return
  * empty data.
  */
  function simulate(
    ITypes.Call[] calldata calls
  ) external override returns (bool[] memory ok, bytes[] memory returnData, bool validCalls) {
    // Ensure all calls are valid
    validCalls = _ACTION_REGISTRY.isValidAction(calls);

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._simulate.selector, calls
      )
    );

    // Parse data returned from self-call into each call result and store / log.
    ITypes.CallReturn[] memory callResults = abi.decode(rawCallResults, (ITypes.CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      if (!callResults[i].ok) {
        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  /**
  * @notice Protected function that can only be called from
  * `simulateActionWithAtomicBatchCalls` on this contract. It will attempt to
  * perform each specified call, populating the array of results as it goes,
  * unless a failure occurs, at which point it will revert and "return" the
  * array of results as revert data. Regardless, it will roll back all calls at
  * the end of execution — in other words, this call always reverts.
  * @param calls Call[] A struct containing the target, value, and calldata to
  * provide when making each call.
  * return An array of structs signifying the status of each call, as well as
  * any data returned from that call. Calls that are not executed will return
  * empty data. If any of the calls fail, the array will be returned as revert
  * data.
  */
  function _simulate(
    ITypes.Call[] memory calls
  ) public returns (ITypes.CallReturn[] memory callResults) {

    callResults = new ITypes.CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call{value:
        uint256(calls[i].value)
      }(calls[i].data);
      callResults[i] = ITypes.CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        break;
      }
    }
    // Wrap in length encoding and revert (provide bytes instead of a string).
    bytes memory callResultsBytes = abi.encode(callResults);
    assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
  }

  function execute(
    ITypes.Call[] memory calls
  ) public onlyOwnerOr(Role.ACTIONER) override returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure all calls are valid
    bool validCalls = _ACTION_REGISTRY.isValidAction(calls);

    require(validCalls, "Invalid call detected!");

    // Note: from this point on, there are no reverts (apart from out-of-gas or
    // call-depth-exceeded) originating from this contract. However, one of the
    // calls may revert, in which case the function will return `false`, along
    // with the revert reason encoded as bytes, and fire a CallFailure event.

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _execute.
    _selfCallContext = this.execute.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool externalOk, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._execute.selector, calls
      )
    );

    // Ensure that self-call context has been cleared.
    if (!externalOk) {
      delete _selfCallContext;
    }

    // Parse data returned from self-call into each call result and store / log.
    ITypes.CallReturn[] memory callResults = abi.decode(rawCallResults, (ITypes.CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      ITypes.Call memory currentCall = calls[i];

      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      // Emit CallSuccess or CallFailure event based on the outcome of the call.
      if (callResults[i].ok) {
        // Note: while the call succeeded, the action may still have "failed".
        emit CallSuccess(
          !externalOk, // If another call failed this will have been rolled back
          currentCall.to,
          uint256(currentCall.value),
          currentCall.data,
          callResults[i].returnData
        );
      } else {
        // Note: while the call failed, the nonce will still be incremented,
        // which will invalidate all supplied signatures.
        emit CallFailure(
          currentCall.to,
          uint256(currentCall.value),
          currentCall.data,
          _decodeRevertReason(callResults[i].returnData)
        );

        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  function _execute(
    ITypes.Call[] memory calls
  ) public returns (ITypes.CallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.execute.selector);

    bool rollBack = false;
    callResults = new ITypes.CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call{value:
        uint256(calls[i].value)
      }(calls[i].data);
      callResults[i] = ITypes.CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        rollBack = true;
        break;
      }
    }

    if (rollBack) {
      // Wrap in length encoding and revert (provide bytes instead of a string).
      bytes memory callResultsBytes = abi.encode(callResults);
      assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
    }
  }

  /**
   * @notice Internal function to ensure that protected functions can only be
   * called from this contract and that they have the appropriate context set.
   * The self-call context is then cleared. It is used as an additional guard
   * against reentrancy, especially once generic actions are supported by the
   * smart wallet in future versions.
   * @param selfCallContext bytes4 The expected self-call context, equal to the
   * function selector of the approved calling function.
   */
  function _enforceSelfCallFrom(bytes4 selfCallContext) internal {
    // Ensure caller is this contract and self-call context is correctly set.
    require(
      msg.sender == address(this) && _selfCallContext == selfCallContext,
      "External accounts or unapproved internal functions cannot call this."
    );

    // Clear the self-call context.
    delete _selfCallContext;
  }


  function _decodeRevertReason(
    bytes memory revertData
  ) internal pure returns (string memory revertReason) {
    // Solidity prefixes revert reason with 0x08c379a0 -> Error(string) selector
    if (
      revertData.length > 68 && // prefix (4) + position (32) + length (32)
      revertData[0] == bytes1(0x08) &&
      revertData[1] == bytes1(0xc3) &&
      revertData[2] == bytes1(0x79) &&
      revertData[3] == bytes1(0xa0)
    ) {
      // Get the revert reason without the prefix from the revert data.
      bytes memory revertReasonBytes = new bytes(revertData.length - 4);
      for (uint256 i = 4; i < revertData.length; i++) {
        revertReasonBytes[i - 4] = revertData[i];
      }

      // Decode the resultant revert reason as a string.
      revertReason = abi.decode(revertReasonBytes, (string));
    } else {
      // Simply return the default, with no revert reason.
      revertReason = "(no revert reason)";
    }
  }

  function tradeTokenForTokenSpecifyingFee(
    ERC20Interface tokenProvided,
    address tokenReceived,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 maximumFeeAmount, // WETH if routeThroughEther, else tokenReceived
    uint256 deadline,
    bool routeThroughEther,
    FeeType feeType
  ) external override returns (uint256 totalTokensBought) {
    _ensureNoEtherFeeTypeWhenNotRouted(routeThroughEther, feeType);

    // Transfer the token from the caller and revert on failure.
    _transferInToken(tokenProvided, msg.sender, tokenProvidedAmount);

    totalTokensBought = _tradeTokenForToken(
      msg.sender,
      tokenProvided,
      tokenReceived,
      tokenProvidedAmount,
      quotedTokenReceivedAmount,
      maximumFeeAmount,
      deadline,
      routeThroughEther,
      feeType
    );
  }

  function tradeTokenForTokenWithFeeOnTransfer(
    ERC20Interface tokenProvided,
    address tokenReceived,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 quotedTokenReceivedAmountAfterTransferFee,
    uint256 deadline,
    bool routeThroughEther
  ) external override returns (uint256 totalTokensBought) {
    _delegate(V17_STAGING);
  }

  function tradeTokenForTokenWithFeeOnTransferSpecifyingFee(
    ERC20Interface tokenProvided,
    address tokenReceived,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 quotedTokenReceivedAmountAfterTransferFee,
    uint256 maximumFeeAmount, // WETH if routeThroughEther, else tokenReceived
    uint256 deadline,
    bool routeThroughEther,
    FeeType feeType
  ) external override returns (uint256 totalTokensBought) {
    _delegate(V17_STAGING);
  }

  function tradeTokenForEtherSpecifyingFee(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedEtherAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external override returns (uint256 totalEtherBought) {
    // Transfer the tokens from the caller and revert on failure.
    _transferInToken(token, msg.sender, tokenAmount);

    uint256 receivedEtherAmount;
    uint256 retainedAmount;
    (totalEtherBought, receivedEtherAmount, retainedAmount) = _tradeTokenForEther(
      token,
      tokenAmount,
      tokenAmount,
      quotedEtherAmount,
      deadline,
      feeType,
      maximumFeeAmount
    );

    _fireTradeEvent(
      false,
      false,
      feeType != FeeType.SUPPLIED_ASSET,
      address(token),
      tokenAmount,
      receivedEtherAmount,
      retainedAmount
    );

    // Transfer the Ether amount to receive to the caller.
    _transferEther(msg.sender, receivedEtherAmount);
  }

  function tradeTokenForEtherWithFeeOnTransfer(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external override returns (uint256 totalEtherBought) {
    _delegate(V17_STAGING);
  }

  function tradeTokenForEtherWithFeeOnTransferSpecifyingFee(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedEtherAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external override returns (uint256 totalEtherBought) {
    _delegate(V17_STAGING);
  }

  function tradeEtherForTokenSpecifyingFee(
    address token,
    uint256 quotedTokenAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external override payable returns (uint256 totalTokensBought) {
    // Trade Ether for the specified token.
    uint256 receivedTokenAmount;
    uint256 retainedAmount;
    (totalTokensBought, receivedTokenAmount, retainedAmount) = _tradeExactEtherForToken(
      token,
      msg.value,
      quotedTokenAmount,
      deadline,
      false,
      feeType,
      maximumFeeAmount
    );

    _fireTradeEvent(
      false,
      true,
      feeType != FeeType.RECEIVED_ASSET,
      token,
      msg.value,
      receivedTokenAmount,
      retainedAmount
    );
  }

  function tradeEtherForTokenWithFeeOnTransfer(
    address token,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 deadline
  ) external override payable returns (uint256 totalTokensBought) {
    _delegate(V17_STAGING);
  }

  function tradeEtherForTokenWithFeeOnTransferSpecifyingFee(
    address token,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external override payable returns (uint256 totalTokensBought) {
    _delegate(V17_STAGING);
  }

  function tradeEtherForTokenUsingReservesWithFeeOnTransferSpecifyingFee(
    address token,
    uint256 etherAmountFromReserves,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external override onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalTokensBought) {
    totalTokensBought = _tradeEtherForTokenWithFeeOnTransfer(
      token,
      etherAmountFromReserves,
      quotedTokenAmount,
      quotedTokenAmountAfterTransferFee,
      maximumFeeAmount,
      deadline,
      true,
      feeType
    );
  }

  function tradeEtherForTokenWithFeeOnTransferUsingEtherizer(
    address token,
    uint256 etherAmount,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 deadline
  ) external override returns (uint256 totalTokensBought) {
    _delegate(V17_STAGING);
  }

  function tradeTokenForTokenUsingReservesSpecifyingFee(
    ERC20Interface tokenProvidedFromReserves,
    address tokenReceived,
    uint256 tokenProvidedAmountFromReserves,
    uint256 quotedTokenReceivedAmount,
    uint256 maximumFeeAmount, // WETH if routeThroughEther, else tokenReceived
    uint256 deadline,
    bool routeThroughEther,
    FeeType feeType
  ) external onlyOwnerOr(Role.RESERVE_TRADER) override returns (uint256 totalTokensBought) {
    _ensureNoEtherFeeTypeWhenNotRouted(routeThroughEther, feeType);

    totalTokensBought = _tradeTokenForToken(
      address(this),
      tokenProvidedFromReserves,
      tokenReceived,
      tokenProvidedAmountFromReserves,
      quotedTokenReceivedAmount,
      maximumFeeAmount,
      deadline,
      routeThroughEther,
      feeType
    );
  }

  function tradeTokenForTokenUsingReservesWithFeeOnTransferSpecifyingFee(
    ERC20Interface tokenProvidedFromReserves,
    address tokenReceived,
    uint256 tokenProvidedAmountFromReserves,
    uint256 quotedTokenReceivedAmount,
    uint256 maximumFeeAmount, // WETH if routeThroughEther, else tokenReceived
    uint256 deadline,
    bool routeThroughEther,
    FeeType feeType
  ) external onlyOwnerOr(Role.RESERVE_TRADER) override returns (uint256 totalTokensBought) {
    _ensureNoEtherFee(feeType);

    totalTokensBought = _tradeTokenForTokenWithFeeOnTransfer(
      TradeTokenForTokenWithFeeOnTransferArgs({
      account: address(this),
      tokenProvided: tokenProvidedFromReserves,
      tokenReceivedOrUSDCFlag: tokenReceived,
      tokenProvidedAmount: tokenProvidedAmountFromReserves,
      tokenProvidedAmountAfterTransferFee: tokenProvidedAmountFromReserves,
      quotedTokenReceivedAmount: quotedTokenReceivedAmount,
      quotedTokenReceivedAmountAfterTransferFee: tokenProvidedAmountFromReserves,
      maximumFeeAmount: maximumFeeAmount,
      deadline: deadline,
      routeThroughEther: routeThroughEther,
      feeType: feeType
      })
    );
  }

  function tradeTokenForEtherUsingReservesSpecifyingFee(
    ERC20Interface token,
    uint256 tokenAmountFromReserves,
    uint256 quotedEtherAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external onlyOwnerOr(Role.RESERVE_TRADER) override returns (uint256 totalEtherBought) {
    uint256 receivedEtherAmount;
    uint256 retainedAmount;
    (totalEtherBought, receivedEtherAmount, retainedAmount) = _tradeTokenForEther(
      token,
      tokenAmountFromReserves,
      tokenAmountFromReserves,
      quotedEtherAmount,
      deadline,
      feeType,
      maximumFeeAmount
    );

    _fireTradeEvent(
      true,
      false,
      feeType != FeeType.SUPPLIED_ASSET,
      address(token),
      tokenAmountFromReserves,
      receivedEtherAmount,
      retainedAmount
    );
  }

  function tradeTokenForEtherUsingReservesWithFeeOnTransferSpecifyingFee(
    ERC20Interface token,
    uint256 tokenAmountFromReserves,
    uint256 quotedEtherAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external onlyOwnerOr(Role.RESERVE_TRADER) override returns (uint256 totalEtherBought) {
    uint256 receivedEtherAmount;
    uint256 retainedAmount;
    (totalEtherBought, receivedEtherAmount, retainedAmount) = _tradeTokenForEther(
      token,
      tokenAmountFromReserves + 1,
      tokenAmountFromReserves,
      quotedEtherAmount,
      deadline,
      feeType,
      maximumFeeAmount
    );

    _fireTradeEvent(
      true,
      false,
      feeType != FeeType.SUPPLIED_ASSET,
      address(token),
      tokenAmountFromReserves,
      receivedEtherAmount,
      retainedAmount
    );
  }

  function tradeEtherForTokenUsingReservesSpecifyingFee(
    address token,
    uint256 etherAmountFromReserves,
    uint256 quotedTokenAmount,
    uint256 maximumFeeAmount,
    uint256 deadline,
    FeeType feeType
  ) external onlyOwnerOr(Role.RESERVE_TRADER) override returns (
    uint256 totalTokensBought
  ) {
    // Trade Ether for the specified token.
    uint256 receivedTokenAmount;
    uint256 retainedAmount;
    (totalTokensBought, receivedTokenAmount, retainedAmount) = _tradeExactEtherForToken(
      token,
      etherAmountFromReserves,
      quotedTokenAmount,
      deadline,
      true,
      feeType,
      maximumFeeAmount
    );

    _fireTradeEvent(
      true,
      true,
      feeType != FeeType.RECEIVED_ASSET,
      token,
      etherAmountFromReserves,
      receivedTokenAmount,
      maximumFeeAmount
    );
  }

  /**
   * @notice Transfer `amount` of token `token` to `smartWallet`, providing the
   * initial user signing key `initialUserSigningKey` as proof that the
   * specified smart wallet is indeed a Dharma Smart Wallet - this assumes that
   * the address is derived and deployed using the Dharma Smart Wallet Factory
   * V1. Only the owner or the designated deposit manager role may call this
   * function.
   * @param smartWallet address The smart wallet to transfer tokens to.
   * @param initialUserSigningKey address The initial user signing key supplied
   * when deriving the smart wallet address - this could be an EOA or a Dharma
   * key ring address.
   * @param token ERC20Interface The token to transfer.
   * @param amount uint256 The amount of tokens to transfer.
   */
  function finalizeTokenDeposit(
    address smartWallet,
    address initialUserSigningKey,
    ERC20Interface token,
    uint256 amount
  ) external onlyOwnerOr(Role.DEPOSIT_MANAGER) override {
    // Ensure that the recipient is indeed a smart wallet.
    _ensureSmartWallet(smartWallet, initialUserSigningKey);

    // Transfer the token to the specified smart wallet.
    _transferToken(token, smartWallet, amount);
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
   * @param etherAmount uint256 The amount of Ether to transfer - this amount
   * must be less than the current limit.
   */
  function finalizeEtherDeposit(
    address payable smartWallet,
    address initialUserSigningKey,
    uint256 etherAmount
  ) external onlyOwnerOr(Role.DEPOSIT_MANAGER) override {
    // Ensure that the recipient is indeed a smart wallet.
    _ensureSmartWallet(smartWallet, initialUserSigningKey);

    // Transfer the Ether to the specified smart wallet.
    _transferEther(smartWallet, etherAmount);
  }

  function refillGasReserve(
    uint256 etherAmount
  ) external onlyOwnerOr(Role.GAS_RESERVE_REFILLER) override {
    // Transfer the Ether to the gas reserve.
    _transferEther(_GAS_RESERVE, etherAmount);

    emit GasReserveRefilled(etherAmount);
  }

  /**
   * @notice Transfer `usdcAmount` USDC for to the current primary recipient set
   * by the owner. Only the owner or the designated withdrawal manager role may
   * call this function.
   * @param usdcAmount uint256 The amount of USDC to transfer to the primary
   * recipient.
   */
  function withdrawUSDCToPrimaryRecipient(
    uint256 usdcAmount
  ) external onlyOwnerOr(Role.WITHDRAWAL_MANAGER) override {
    // Get the current primary recipient.
    address primaryRecipient = _primaryUSDCRecipient;
    require(
      primaryRecipient != address(0), "No USDC primary recipient currently set."
    );

    // Transfer the supplied USDC amount to the primary recipient.
    _transferToken(_USDC, primaryRecipient, usdcAmount);
  }

  /**
   * @notice Transfer `daiAmount` Dai for to the current primary recipient set
   * by the owner. Only the owner or the designated withdrawal manager role may
   * call this function.
   * @param daiAmount uint256 The amount of Dai to transfer to the primary
   * recipient.
   */
  function withdrawDaiToPrimaryRecipient(
    uint256 daiAmount
  ) external onlyOwnerOr(Role.WITHDRAWAL_MANAGER) override {
    // Get the current primary recipient.
    address primaryRecipient = _primaryDaiRecipient;
    require(
      primaryRecipient != address(0), "No Dai primary recipient currently set."
    );

    // Transfer the supplied Dai amount to the primary recipient.
    _transferToken(_DAI, primaryRecipient, daiAmount);
  }

  /**
   * @notice Transfer `etherAmount` Ether to `recipient`. Only the owner may
   * call this function.
   * @param recipient address The account to transfer Ether to.
   * @param etherAmount uint256 The amount of Ether to transfer.
   */
  function withdrawEther(
    address payable recipient, uint256 etherAmount
  ) external override onlyOwner {
    // Transfer the Ether to the specified recipient.
    _transferEther(recipient, etherAmount);
  }

  /**
   * @notice Transfer `amount` of ERC20 token `token` to `recipient`. Only the
   * owner may call this function.
   * @param token ERC20Interface The ERC20 token to transfer.
   * @param recipient address The account to transfer the tokens to.
   * @param amount uint256 The amount of tokens to transfer.
   * @return success - a boolean to indicate if the transfer was successful - note that
   * unsuccessful ERC20 transfers will usually revert.
   */
  function withdraw(
    ERC20Interface token, address recipient, uint256 amount
  ) external onlyOwner override returns (bool success) {
    // Transfer the token to the specified recipient.
    success = token.transfer(recipient, amount);
  }

  /**
   * @notice Call account `target`, supplying value `amount` and data `data`.
   * Only the owner may call this function.
   * @param target address The account to call.
   * @param amount uint256 The amount of ether to include as an endowment.
   * @param data bytes The data to include along with the call.
   * @return ok and returnData - a boolean to indicate if the call was successful, as well as the
   * returned data or revert reason.
   */
  function callAny(
    address payable target, uint256 amount, bytes calldata data
  ) external onlyOwner override returns (bool ok, bytes memory returnData) {
    // Call the specified target and supply the specified data.
    (ok, returnData) = target.call{value:amount}(data);
  }

  /**
   * @notice Set `recipient` as the new primary recipient for USDC withdrawals.
   * Only the owner may call this function.
   * @param recipient address The new primary recipient.
   */
  function setPrimaryUSDCRecipient(address recipient) external override onlyOwner {
    // Set the new primary recipient.
    _primaryUSDCRecipient = recipient;
  }

  /**
   * @notice Set `recipient` as the new primary recipient for Dai withdrawals.
   * Only the owner may call this function.
   * @param recipient address The new primary recipient.
   */
  function setPrimaryDaiRecipient(address recipient) external override onlyOwner {
    // Set the new primary recipient.
    _primaryDaiRecipient = recipient;
  }

  /**
   * @notice Pause a currently unpaused role and emit a `RolePaused` event. Only
   * the owner or the designated pauser may call this function. Also, bear in
   * mind that only the owner may unpause a role once paused.
   * @param role The role to pause.
   */
  function pause(Role role) external override onlyOwnerOr(Role.PAUSER) {
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
  function unpause(Role role) external override onlyOwner {
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
  function setRole(Role role, address account) external override onlyOwner {
    require(account != address(0), "Must supply an account.");
    _setRole(role, account);
  }

  /**
   * @notice Remove any current role bearer for a given role and emit a
   * `RoleModified` event if a role holder was previously set. Only the owner
   * may call this function.
   * @param role The role that the account will be removed from.
   */
  function removeRole(Role role) external override onlyOwner {
    _setRole(role, address(0));
  }

  /**
   * @notice External view function to check whether or not the functionality
   * associated with a given role is currently paused or not. The owner or the
   * pauser may pause any given role (including the pauser itself), but only the
   * owner may unpause functionality. Additionally, the owner may call paused
   * functions directly.
   * @param role The role to check the pause status on.
   * @return paused - a boolean to indicate if the functionality associated with the role
   * in question is currently paused.
   */
  function isPaused(Role role) external view override returns (bool paused) {
    paused = _isPaused(role);
  }

  /**
   * @notice External view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for.
   * @return hasRole - a boolean indicating if the caller has the specified role.
   */
  function isRole(Role role) external view override returns (bool hasRole) {
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
   * @return dharmaSmartWallet - a boolean indicating if the specified smart wallet account is
   * indeed a smart wallet based on the specified initial user signing key.
   */
  function isDharmaSmartWallet(
    address smartWallet, address initialUserSigningKey
  ) external pure override returns (bool dharmaSmartWallet) {
    dharmaSmartWallet = _isSmartWallet(smartWallet, initialUserSigningKey);
  }

  /**
   * @notice External view function to check the account currently holding the
   * deposit manager role. The deposit manager can process standard deposit
   * finalization via `finalizeDaiDeposit` and `finalizeDharmaDaiDeposit`, but
   * must prove that the recipient is a Dharma Smart Wallet and adhere to the
   * current deposit size limit.
   * @return depositManager - the address of the current deposit manager, or the null address if
   * none is set.
   */
  function getDepositManager() external view override returns (address depositManager) {
    depositManager = _roles[uint256(Role.DEPOSIT_MANAGER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * reserve trader role. The reserve trader can trigger trades that utilize
   * reserves in addition to supplied funds, if any.
   * @return reserveTrader - the address of the current reserve trader, or the null address if
   * none is set.
   */
  function getReserveTrader() external view override returns (address reserveTrader) {
    reserveTrader = _roles[uint256(Role.RESERVE_TRADER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * withdrawal manager role. The withdrawal manager can transfer USDC to the
   * "primary recipient" address set by the owner.
   * @return withdrawalManager - the address of the current withdrawal manager, or the null address
   * if none is set.
   */
  function getWithdrawalManager() external view override returns (
    address withdrawalManager
  ) {
    withdrawalManager = _roles[uint256(Role.WITHDRAWAL_MANAGER)].account;
  }


  /**
   * @notice External view function to check the account currently holding the
   * actioner role. The actioner can submit a generic calls transaction through `execute`
   * @return actioner - the address of the current actioner, or the null address
   * if none is set.
   */
  function getActioner() external view override returns (
    address actioner
    ) {
    actioner = _roles[uint256(Role.ACTIONER)].account;
  }


  /**
   * @notice External view function to check the account currently holding the
   * pauser role. The pauser can pause any role from taking its standard action,
   * though the owner will still be able to call the associated function in the
   * interim and is the only entity able to unpause the given role once paused.
   * @return pauser - the address of the current pauser, or the null address if none is
   * set.
   */
  function getPauser() external view override returns (address pauser) {
    pauser = _roles[uint256(Role.PAUSER)].account;
  }

  function getGasReserveRefiller() external view override returns (
    address gasReserveRefiller
  ) {
    gasReserveRefiller = _roles[uint256(Role.GAS_RESERVE_REFILLER)].account;
  }

  /**
   * @notice External view function to check the address of the current
   * primary recipient for USDC.
   * @return recipient - the primary recipient for USDC.
   */
  function getPrimaryUSDCRecipient() external view override returns (
    address recipient
  ) {
    recipient = _primaryUSDCRecipient;
  }

  /**
   * @notice External view function to check the address of the current
   * primary recipient for Dai.
   * @return recipient - the primary recipient for Dai.
   */
  function getPrimaryDaiRecipient() external view override returns (
    address recipient
  ) {
    recipient = _primaryDaiRecipient;
  }

  /**
   * @notice External view function to check the current implementation
   * of this contract (i.e. the "logic" for the contract).
   * @return implementation - the current implementation for this contract.
   */
  function getImplementation() external view override returns (
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
   * @return instance - the address of this contract instance.
   */
  function getInstance() external pure override returns (address instance) {
    instance = address(0x2040F2f2bB228927235Dc24C33e99E3A0a7922c1);
  }

  function getVersion() external pure override returns (uint256 version) {
    version = _VERSION;
  }

  function _grantUniswapRouterApprovalIfNecessary(
    ERC20Interface token, uint256 amount
  ) internal {
    if (token.allowance(address(this), address(_UNISWAP_ROUTER)) < amount) {
      // Try removing approval first as a workaround for unusual tokens.
      (bool success, bytes memory data) = address(token).call(
        abi.encodeWithSelector(
          token.approve.selector, address(_UNISWAP_ROUTER), uint256(0)
        )
      );

      // Grant transfer approval to Uniswap router on behalf of this contract.
      (success, data) = address(token).call(
        abi.encodeWithSelector(
          token.approve.selector, address(_UNISWAP_ROUTER), type(uint256).max
        )
      );

      if (!success) {
        // Some janky tokens only allow setting approval up to current balance.
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

  function _tradeEtherForTokenWithFeeOnTransfer(
    address tokenReceivedOrUSDCFlag,
    uint256 etherAmount,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 maximumFeeAmount,
    uint256 deadline,
    bool fromReserves,
    FeeType feeType
  ) internal returns (uint256 totalTokensBought) {
    _delegate(V17_STAGING);
  }

  function _tradeEtherForTokenWithFeeOnTransferLegacy(
    address tokenReceivedOrUSDCFlag,
    uint256 etherAmount,
    uint256 quotedTokenAmount,
    uint256 quotedTokenAmountAfterTransferFee,
    uint256 deadline,
    bool fromReserves
  ) internal returns (uint256 totalTokensBought) {
    _delegate(V17_STAGING);
  }

  /**
  * @notice Internal trade function. If token is _TRADE_FOR_USDC_AND_RETAIN_FLAG,
  * trade for USDC and retain the full output amount by replacing the recipient
  * ("to" input) on the swapETHForExactTokens call.
  */
  function _tradeExactEtherForToken(
    address tokenReceivedOrUSDCFlag,
    uint256 etherAmount,
    uint256 quotedTokenAmount,
    uint256 deadline,
    bool fromReserves,
    FeeType feeType,
    uint256 maximumFeeAmount
  ) internal returns (
    uint256 totalTokensBought,
    uint256 receivedTokenAmount,
    uint256 retainedAmount
  ) {
    // Set swap target destination and token.
    address destination;
    address[] memory path = new address[](2);
    path[0] = _WETH;
    if (tokenReceivedOrUSDCFlag == _TRADE_FOR_USDC_AND_RETAIN_FLAG) {
      path[1] = address(_USDC);
      destination = address(this);
    } else {
      path[1] = tokenReceivedOrUSDCFlag;
      destination = fromReserves ? address(this) : msg.sender;
    }

    // Trade Ether for quoted token amount and send to appropriate recipient.
    uint256[] memory amounts = new uint256[](2);
    amounts = _UNISWAP_ROUTER.swapExactETHForTokens{value:
      feeType != FeeType.RECEIVED_ASSET
      ? etherAmount - maximumFeeAmount
      : etherAmount
    }(
      quotedTokenAmount,
      path,
      destination,
      deadline
    );
    totalTokensBought = amounts[1];

    if (feeType == FeeType.RECEIVED_ASSET) {
      // Retain the lesser of either max fee or bought amount less quoted amount.
      retainedAmount = maximumFeeAmount.min(
        totalTokensBought - quotedTokenAmount
      );
      receivedTokenAmount = totalTokensBought - retainedAmount;
    } else {
      retainedAmount = maximumFeeAmount;
      receivedTokenAmount = totalTokensBought;
    }
  }

  function _tradeTokenForEther(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 tokenAmountAfterTransferFee,
    uint256 quotedEtherAmount,
    uint256 deadline,
    FeeType feeType,
    uint256 maximumFeeAmount
  ) internal returns (
    uint256 totalEtherBought,
    uint256 receivedEtherAmount,
    uint256 retainedAmount
  ) {
    // Trade tokens for Ether.
    uint256 tradeAmount;
    if (feeType == FeeType.SUPPLIED_ASSET) {
      tradeAmount = (tokenAmount.min(tokenAmountAfterTransferFee) - maximumFeeAmount);
      retainedAmount = maximumFeeAmount;
    } else {
      tradeAmount = tokenAmount.min(tokenAmountAfterTransferFee);
    }

    // Approve Uniswap router to transfer tokens on behalf of this contract.
    _grantUniswapRouterApprovalIfNecessary(token, tokenAmount);

    // Establish path from target token to Ether.
    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(token), _WETH, false
    );

    // Trade tokens for quoted Ether amount on Uniswap (send to this contract).
    if (tokenAmount == tokenAmountAfterTransferFee) {
      amounts = _UNISWAP_ROUTER.swapExactTokensForETH(
        tradeAmount, quotedEtherAmount, path, address(this), deadline
      );
      totalEtherBought = amounts[1];
    } else {
      uint256 ethBalanceBeforeTrade = address(this).balance;
      _UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tradeAmount,
        quotedEtherAmount,
        path,
        address(this),
        deadline
      );
      totalEtherBought = address(this).balance - ethBalanceBeforeTrade;
    }

    if (feeType != FeeType.SUPPLIED_ASSET) {
      // Retain the lesser of either max fee or bought amount less quoted amount.
      retainedAmount = maximumFeeAmount.min(
        totalEtherBought - quotedEtherAmount
      );

      // Receive back the total bought Ether less total retained Ether.
      receivedEtherAmount = totalEtherBought - retainedAmount;
    } else {
      receivedEtherAmount = totalEtherBought;
    }
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
    uint256 maximumFeeAmount, // WETH if routeThroughEther, else tokenReceived
    uint256 deadline,
    bool routeThroughEther,
    FeeType feeType
  ) internal returns (uint256 totalTokensBought) {
    uint256 retainedAmount;
    uint256 receivedAmount;
    address tokenReceived;

    // Approve Uniswap router to transfer tokens on behalf of this contract.
    _grantUniswapRouterApprovalIfNecessary(tokenProvided, tokenProvidedAmount);

    // Set recipient, swap target token
    if (tokenReceivedOrUSDCFlag == _TRADE_FOR_USDC_AND_RETAIN_FLAG) {
      tokenReceived = address(_USDC);
    } else {
      tokenReceived = tokenReceivedOrUSDCFlag;
    }

    if (routeThroughEther == false) {
      // Establish direct path between tokens.
      (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
        address(tokenProvided), tokenReceived, false
      );

      // Trade for the quoted token amount on Uniswap and send to this contract.
      amounts = _UNISWAP_ROUTER.swapExactTokensForTokens(
        feeType == FeeType.SUPPLIED_ASSET
        ? tokenProvidedAmount - maximumFeeAmount
        : tokenProvidedAmount,
        quotedTokenReceivedAmount,
        path,
        address(this),
        deadline
      );

      totalTokensBought = amounts[1];

      if (feeType == FeeType.RECEIVED_ASSET) {
        // Retain lesser of either max fee or bought amount less quoted amount.
        retainedAmount = maximumFeeAmount.min(
          totalTokensBought - quotedTokenReceivedAmount
        );
        receivedAmount = totalTokensBought - retainedAmount;
      } else {
        retainedAmount = maximumFeeAmount;
        receivedAmount = totalTokensBought;
      }
    } else {
      // Establish path between provided token and WETH.
      (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
        address(tokenProvided), _WETH, false
      );

      // Trade all provided tokens for WETH on Uniswap and send to this contract.
      amounts = _UNISWAP_ROUTER.swapExactTokensForTokens(
        feeType == FeeType.SUPPLIED_ASSET
        ? tokenProvidedAmount - maximumFeeAmount
        : tokenProvidedAmount,
        feeType == FeeType.ETHER ? maximumFeeAmount : 1,
        path,
        address(this),
        deadline
      );
      retainedAmount = amounts[1];

      // Establish path between WETH and received token.
      (path, amounts) = _createPathAndAmounts(
        _WETH, tokenReceived, false
      );

      // Trade bought WETH (less fee) for received token, send to this contract.
      amounts = _UNISWAP_ROUTER.swapExactTokensForTokens(
        feeType == FeeType.ETHER
        ? retainedAmount - maximumFeeAmount
        : retainedAmount,
        quotedTokenReceivedAmount,
        path,
        address(this),
        deadline
      );

      totalTokensBought = amounts[1];

      if (feeType == FeeType.RECEIVED_ASSET) {
        // Retain lesser of either max fee or bought amount less quoted amount.
        retainedAmount = maximumFeeAmount.min(
          totalTokensBought - quotedTokenReceivedAmount
        );
        receivedAmount = totalTokensBought - retainedAmount;
      } else {
        retainedAmount = maximumFeeAmount;
        receivedAmount = totalTokensBought;
      }
    }

    _emitTrade(
      account,
      address(tokenProvided),
      tokenReceivedOrUSDCFlag,
      feeType == FeeType.ETHER
      ? _WETH
      : (feeType == FeeType.RECEIVED_ASSET
    ? tokenReceived
    : address(tokenProvided)
    ),
      tokenProvidedAmount,
      receivedAmount,
      retainedAmount
    );

    if (
      account != address(this) &&
      tokenReceivedOrUSDCFlag != _TRADE_FOR_USDC_AND_RETAIN_FLAG
    ) {
      _transferToken(ERC20Interface(tokenReceived), account, receivedAmount);
    }
  }

  /**
  * @notice Internal trade function. If tokenReceived is _TRADE_FOR_USDC_AND_RETAIN_FLAG,
  * trade for USDC and retain the full output amount by replacing the recipient
  * ("to" input) on the swapTokensForExactTokens call.
  */
  function _tradeTokenForTokenLegacy(
    address account,
    ERC20Interface tokenProvided,
    address tokenReceivedOrUSDCFlag,
    uint256 tokenProvidedAmount,
    uint256 quotedTokenReceivedAmount,
    uint256 deadline,
    bool routeThroughEther
  ) internal returns (uint256 totalTokensSold) {
    uint256 retainedAmount;
    address tokenReceived;
    address recipient;

    // Approve Uniswap router to transfer tokens on behalf of this contract.
    _grantUniswapRouterApprovalIfNecessary(tokenProvided, tokenProvidedAmount);

    // Set recipient, swap target token
    if (tokenReceivedOrUSDCFlag == _TRADE_FOR_USDC_AND_RETAIN_FLAG) {
      recipient = address(this);
      tokenReceived = address(_USDC);
    } else {
      recipient = account;
      tokenReceived = tokenReceivedOrUSDCFlag;
    }

    if (routeThroughEther == false) {
      // Establish direct path between tokens.
      (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
        address(tokenProvided), tokenReceived, false
      );

      // Trade for the quoted token amount on Uniswap and send to recipient.
      amounts = _UNISWAP_ROUTER.swapTokensForExactTokens(
        quotedTokenReceivedAmount,
        tokenProvidedAmount,
        path,
        recipient,
        deadline
      );

      totalTokensSold = amounts[0];
      retainedAmount = tokenProvidedAmount - totalTokensSold;
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
        _WETH, tokenReceived, false
      );

      // Trade bought WETH for received token on Uniswap and send to recipient.
      amounts = _UNISWAP_ROUTER.swapTokensForExactTokens(
        quotedTokenReceivedAmount, retainedAmount, path, recipient, deadline
      );

      totalTokensSold = amounts[0];
      retainedAmount = retainedAmount - totalTokensSold;
    }

    _emitTrade(
      account,
      address(tokenProvided),
      tokenReceivedOrUSDCFlag,
      routeThroughEther ? _WETH : address(tokenProvided),
      tokenProvidedAmount,
      quotedTokenReceivedAmount,
      retainedAmount
    );
  }

  struct TradeTokenForTokenWithFeeOnTransferArgs {
    address account;
    ERC20Interface tokenProvided;
    address tokenReceivedOrUSDCFlag;
    uint256 tokenProvidedAmount;
    uint256 tokenProvidedAmountAfterTransferFee;
    uint256 quotedTokenReceivedAmount;
    uint256 quotedTokenReceivedAmountAfterTransferFee;
    uint256 maximumFeeAmount;
    uint256 deadline;
    bool routeThroughEther;
    FeeType feeType;
  }

  /**
  * @notice Internal trade function for cases where one of the tokens in
  * question levies a transfer fee. If tokenReceived is
  * _TRADE_FOR_USDC_AND_RETAIN_FLAG, trade for USDC and retain the full output
  * amount by replacing the recipient ("to" input) on the
  * swapTokensForExactTokens call.
  */
  function _tradeTokenForTokenWithFeeOnTransfer(
    TradeTokenForTokenWithFeeOnTransferArgs memory args
  ) internal returns (uint256 totalTokensBought) {
    ERC20Interface tokenReceived = (
    args.tokenReceivedOrUSDCFlag == _TRADE_FOR_USDC_AND_RETAIN_FLAG
    ? ERC20Interface(_USDC)
    : ERC20Interface(args.tokenReceivedOrUSDCFlag)
    );

    // Approve Uniswap router to transfer tokens on behalf of this contract.
    _grantUniswapRouterApprovalIfNecessary(
      args.tokenProvided, args.tokenProvidedAmountAfterTransferFee
    );

    { // Scope to avoid stack too deep error.
      // Establish path between tokens.
      (address[] memory path, ) = _createPathAndAmounts(
        address(args.tokenProvided), address(tokenReceived), args.routeThroughEther
      );

      // Get this contract's balance in the output token prior to the trade.
      uint256 priorReserveBalanceOfReceivedToken = tokenReceived.balanceOf(
        address(this)
      );

      // Trade for the quoted token amount on Uniswap and send to this contract.
      _UNISWAP_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        args.feeType == FeeType.SUPPLIED_ASSET
        ? args.tokenProvidedAmountAfterTransferFee - args.maximumFeeAmount
        : args.tokenProvidedAmountAfterTransferFee,
        args.quotedTokenReceivedAmount,
        path,
        address(this),
        args.deadline
      );

      totalTokensBought = tokenReceived.balanceOf(address(this)) - priorReserveBalanceOfReceivedToken;
    }
    uint256 receivedAmountAfterTransferFee;
    if (
      args.account != address(this) &&
      args.tokenReceivedOrUSDCFlag != _TRADE_FOR_USDC_AND_RETAIN_FLAG
    ) {
      {
        // Get the receiver's balance prior to the transfer.
        uint256 priorRecipientBalanceOfReceivedToken = tokenReceived.balanceOf(
          args.account
        );

        // Transfer the received tokens (less the fee) to the recipient.
        _transferToken(
          tokenReceived,
          args.account,
          args.feeType == FeeType.RECEIVED_ASSET
          ? totalTokensBought - args.maximumFeeAmount
          : totalTokensBought
        );

        receivedAmountAfterTransferFee = tokenReceived.balanceOf(args.account) - priorRecipientBalanceOfReceivedToken;
      }

      // Ensure that sufficient tokens were returned to the user.
      require(
        receivedAmountAfterTransferFee >= args.quotedTokenReceivedAmountAfterTransferFee,
        "Received token amount after transfer fee is less than quoted amount."
      );
    } else {
      receivedAmountAfterTransferFee = args.feeType == FeeType.RECEIVED_ASSET
      ? totalTokensBought - args.maximumFeeAmount
      : totalTokensBought;
    }

    _emitTrade(
      args.account,
      address(args.tokenProvided),
      args.tokenReceivedOrUSDCFlag,
      args.feeType == FeeType.RECEIVED_ASSET
      ? address(tokenReceived)
      : address(args.tokenProvided),
      args.tokenProvidedAmount,
      receivedAmountAfterTransferFee,
      args.maximumFeeAmount
    );
  }

  /**
  * @notice Internal trade function for cases where one of the tokens in
  * question levies a transfer fee. If tokenReceived is
  * _TRADE_FOR_USDC_AND_RETAIN_FLAG, trade for USDC and retain the full output
  * amount by replacing the recipient ("to" input) on the
  * swapTokensForExactTokens call.
  */
  function _tradeTokenForTokenWithFeeOnTransferLegacy(
    address account,
    ERC20Interface tokenProvided,
    address tokenReceivedOrUSDCFlag,
    uint256 tokenProvidedAmount,
    uint256 tokenProvidedAmountAfterTransferFee,
    uint256 quotedTokenReceivedAmount,
    uint256 quotedTokenReceivedAmountAfterTransferFee,
    uint256 deadline,
    bool routeThroughEther
  ) internal returns (uint256 totalTokensBought) {
    uint256 retainedAmount;
    uint256 receivedAmountAfterTransferFee;
    ERC20Interface tokenReceived;

    // Approve Uniswap router to transfer tokens on behalf of this contract.
    _grantUniswapRouterApprovalIfNecessary(
      tokenProvided, tokenProvidedAmountAfterTransferFee
    );

    { // Scope to avoid stack too deep error.
      address recipient;
      // Set recipient, swap target token
      if (tokenReceivedOrUSDCFlag == _TRADE_FOR_USDC_AND_RETAIN_FLAG) {
        recipient = address(this);
        tokenReceived = ERC20Interface(_USDC);
      } else {
        recipient = account;
        tokenReceived = ERC20Interface(tokenReceivedOrUSDCFlag);
      }

      // Establish path between tokens.
      (address[] memory path, ) = _createPathAndAmounts(
        address(tokenProvided), address(tokenReceived), routeThroughEther
      );

      // Get this contract's balance in the output token prior to the trade.
      uint256 priorReserveBalanceOfReceivedToken = tokenReceived.balanceOf(
        address(this)
      );

      // Trade for the quoted token amount on Uniswap and send to this contract.
      _UNISWAP_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        tokenProvidedAmountAfterTransferFee,
        quotedTokenReceivedAmount,
        path,
        address(this),
        deadline
      );

      totalTokensBought = tokenReceived.balanceOf(address(this)) - priorReserveBalanceOfReceivedToken;
      retainedAmount = totalTokensBought - quotedTokenReceivedAmount;

      // Get the receiver's balance prior to the transfer.
      uint256 priorRecipientBalanceOfReceivedToken = tokenReceived.balanceOf(
        recipient
      );

      // Transfer the received tokens to the recipient.
      _transferToken(tokenReceived, recipient, quotedTokenReceivedAmount);

      receivedAmountAfterTransferFee = tokenReceived.balanceOf(recipient) - priorRecipientBalanceOfReceivedToken;

      // Ensure that sufficient tokens were returned to the user.
      require(
        receivedAmountAfterTransferFee >= quotedTokenReceivedAmountAfterTransferFee,
        "Received token amount after transfer fee is less than quoted amount."
      );
    }

    _emitTrade(
      account,
      address(tokenProvided),
      tokenReceivedOrUSDCFlag,
      address(tokenReceived),
      tokenProvidedAmount,
      receivedAmountAfterTransferFee,
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

  function _emitTrade(
    address account,
    address suppliedAsset,
    address receivedAsset,
    address retainedAsset,
    uint256 suppliedAmount,
    uint256 receivedAmount,
    uint256 retainedAmount
  ) internal {
    emit Trade(
      account,
      suppliedAsset,
      receivedAsset,
      retainedAsset,
      suppliedAmount,
      receivedAmount,
      retainedAmount
    );
  }

  function _fireTradeEvent(
    bool fromReserves,
    bool supplyingEther,
    bool feeInEther,
    address token,
    uint256 suppliedAmount,
    uint256 receivedAmount,
    uint256 retainedAmount
  ) internal {
    emit Trade(
      fromReserves ? address(this) : msg.sender,
      supplyingEther ? address(0) : token,
      supplyingEther ? token : address(0),
      feeInEther
      ? address(0)
      : (token == _TRADE_FOR_USDC_AND_RETAIN_FLAG ? address(_USDC) : token),
      suppliedAmount,
      receivedAmount,
      retainedAmount
    );
  }

  /**
   * @notice Internal view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for.
   * @return hasRole - a boolean indicating if the caller has the specified role.
   */
  function _isRole(Role role) internal view returns (bool hasRole) {
    hasRole = msg.sender == _roles[uint256(role)].account;
  }

  /**
   * @notice Internal view function to check whether the given role is paused or
   * not.
   * @param role The role to check for.
   * @return paused - a boolean indicating if the specified role is paused or not.
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

  function _transferToken(ERC20Interface token, address to, uint256 amount) internal {
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.transfer.selector, to, amount)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "Transfer out failed."
    );
  }

  function _transferEther(address recipient, uint256 etherAmount) internal {
    // Send quoted Ether amount to recipient and revert with reason on failure.
    (bool ok, ) = recipient.call{value:etherAmount}("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  function _transferInToken(ERC20Interface token, address from, uint256 amount) internal {
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.transferFrom.selector, from, address(this), amount)
    );

    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "Transfer in failed."
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

  function _ensureNoEtherFeeTypeWhenNotRouted(
    bool routeThroughEther, FeeType feeType
  ) internal pure {
    require(
      routeThroughEther || feeType != FeeType.ETHER,
      "Cannot take token-for-token fee in Ether unless routed through Ether."
    );
  }

  function _ensureNoEtherFee(FeeType feeType) internal pure {
    require(
      feeType != FeeType.ETHER,
      "Cannot take token-for-token fee in Ether with fee on transfer."
    );
  }

  function _delegate(address implementation) private {
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
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