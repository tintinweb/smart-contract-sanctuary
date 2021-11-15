// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./interfaces/IBridge.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./RelayRecipientUpgradeable.sol";
import "./utils/IWrapper.sol";
import "./SymbHelper.sol";
import "../symbdex/interfaces/ISymbiosisV2Router02Restricted.sol";
import "../MetaRouteStructs.sol";

/**
 * @title A contract that synthesizes tokens
 * @notice In order to create a synthetic representation on another network, the user must call synthesize function here
 * @dev All function calls are currently implemented without side effects
 */
contract Portal is RelayRecipientUpgradeable {
  /// ** PUBLIC states **

  address public bridge;
  address public wrapper;
  uint256 public requestCount;
  uint256 public nativeTokenPrice;
  bool public paused;
  SymbHelper public symbHelper;
  mapping(bytes32 => TxState) public requests;
  mapping(bytes32 => UnsynthesizeState) public unsynthesizeStates;
  mapping(address => uint256) public balanceOf;

  /// ** STRUCTS **

  enum RequestState {
    Default,
    Sent,
    Reverted
  }
  enum UnsynthesizeState {
    Default,
    Unsynthesized,
    RevertRequest
  }

  struct TxState {
    address recipient;
    address chain2address;
    uint256 amount;
    address rtoken;
    RequestState state;
  }

  /// ** EVENTS **

  event SynthesizeRequest(
    bytes32 id,
    address from,
    address to,
    uint256 amount,
    address token
  );

  event OracleRequest(
    string requestType,
    address bridge,
    bytes32 requestId,
    bytes callData,
    address receiveSide,
    address oppositeBridge,
    uint256 chainId
  );

  event RevertBurnRequest(bytes32 indexed id, address indexed to);

  event BurnCompleted(
    bytes32 indexed id,
    address indexed to,
    uint256 amount,
    address token
  );

  event RevertSynthesizeCompleted(
    bytes32 indexed id,
    address indexed to,
    uint256 amount,
    address token
  );

  /// ** MODIFIERs **

  modifier onlyBridge() {
    require(bridge == msg.sender);
    _;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /// ** INITIALIZER **

  /**
   * init
   */
  function initialize(
    address _bridge,
    address _trustedForwarder,
    address _wrapper
  ) public virtual initializer {
    __RelayRecipient_init(_trustedForwarder);
    bridge = _bridge;
    nativeTokenPrice = 10000000000000000; // 0.01 of native token
    wrapper = _wrapper;
    symbHelper = new SymbHelper();
  }

  /// ** PUBLIC functions **

  /**
   * @notice Returns version
   */
  function versionRecipient() public view returns (string memory) {
    return "2.0.1";
  }

  // ** EXTERNAL functions **

  /**
   * @notice Sends synthesize request
   * @dev Token -> sToken on a second chain
   * @param _token The address of the token that the user wants to synthesize
   * @param _amount Number of tokens to synthesize
   * @param _chain2address The address to which the user wants to receive the synth asset on another network
   * @param _receiveSide Synthesis address on another network
   * @param _oppositeBridge Bridge address on another network
   * @param _chainID Chain id of the network where synthesization will take place
   */
  function synthesize(
    address _token,
    uint256 _amount,
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable whenNotPaused returns (bytes32) {
    require(msg.value == nativeTokenPrice, "Symb: Not enough money");
    TransferHelper.safeTransferFrom(
      _token,
      _msgSender(),
      address(this),
      _amount
    );

    return
      sendSynthesizeRequest(
        _token,
        _amount,
        _chain2address,
        _receiveSide,
        _oppositeBridge,
        _chainID
      );
  }

  // TODO: add natspec
  function metaSynthesize(
    MetaRouteStructs.MetaSynthesizeTransaction memory _metaSynthesizeTransaction
  ) external payable whenNotPaused returns (bytes32) {
    require(msg.value == nativeTokenPrice, "Symb: Not enough money");
    TransferHelper.safeTransferFrom(
      _metaSynthesizeTransaction.rtoken,
      _msgSender(),
      address(this),
      _metaSynthesizeTransaction.amount
    );

    bytes32 txID = sendMetaSynthesizeRequest(_metaSynthesizeTransaction);

    return txID;
  }

  /**
   * @notice Native -> sToken on a second chain
   */
  function synthesizeNative(
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable whenNotPaused returns (bytes32) {
    uint256 amount = msg.value - nativeTokenPrice;
    require(amount > 0, "Symb: Not enough money");
    symbHelper.depositToWrapper{ value: amount }(wrapper);

    return
      sendSynthesizeRequest(
        wrapper,
        amount,
        _chain2address,
        _receiveSide,
        _oppositeBridge,
        _chainID
      );
  }

  /**
   * @notice Token -> sToken on a second chain withPermit
   * @param _approvalData Allowance to spend tokens
   */
  function synthesizeWithPermit(
    bytes calldata _approvalData,
    address _token,
    uint256 _amount,
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable whenNotPaused returns (bytes32) {
    require(msg.value == nativeTokenPrice, "Symb: Not enough money");

    (
      address owner,
      uint256 value,
      uint256 deadline,
      uint8 v,
      bytes32 r,
      bytes32 s
    ) = abi.decode(
        _approvalData,
        (address, uint256, uint256, uint8, bytes32, bytes32)
      );
    IERC20Permit(_token).permit(owner, address(this), value, deadline, v, r, s);

    TransferHelper.safeTransferFrom(
      _token,
      _msgSender(),
      address(this),
      _amount
    );

    return
      sendSynthesizeRequest(
        _token,
        _amount,
        _chain2address,
        _receiveSide,
        _oppositeBridge,
        _chainID
      );
  }

  /**
   * @notice Emergency unsynthesize
   * @dev Can called only by bridge after initiation on a second chain
   * @dev If a transaction arrives at the synthesization chain with an already completed revert synthesize contract will fail this transaction,
   * since the state was changed during the call to the desynthesis request
   * @param _txID the synthesize transaction that was received from the event when it was originally called synthesize on the Portal contract
   */
  function revertSynthesize(bytes32 _txID) external onlyBridge whenNotPaused {
    TxState storage txState = requests[_txID];
    require(
      txState.state == RequestState.Sent,
      "Symb: state not open or tx does not exist"
    );
    txState.state = RequestState.Reverted; // close
    balanceOf[txState.rtoken] = balanceOf[txState.rtoken] - txState.amount;

    unlockAssets(txState.rtoken, txState.amount, txState.recipient);

    emit RevertSynthesizeCompleted(
      _txID,
      txState.recipient,
      txState.amount,
      txState.rtoken
    );
  }

  /**
   * @notice Revert synthesize
   * @dev After revertSynthesizeRequest in Synthesis this method is called
   */
  function unsynthesize(
    bytes32 _txID,
    address _token,
    uint256 _amount,
    address _to
  ) external onlyBridge whenNotPaused {
    require(
      unsynthesizeStates[_txID] == UnsynthesizeState.Default,
      "Symb: syntatic tokens emergencyUnburn"
    );
    balanceOf[_token] = balanceOf[_token] - _amount;
    unsynthesizeStates[_txID] = UnsynthesizeState.Unsynthesized;
    unlockAssets(_token, _amount, _to);
    emit BurnCompleted(_txID, _to, _amount, _token);
  }

  function metaUnsynthesize(
    bytes32 _txID,
    address _to,
    uint256 _amount,
    address _rToken,
    address _finalDexRouter,
    bytes memory _finalSwapCalldata
  ) external onlyBridge whenNotPaused {
    require(
      unsynthesizeStates[_txID] == UnsynthesizeState.Default,
      "Symb: synthetic tokens emergencyUnburn"
    );

    balanceOf[_rToken] = balanceOf[_rToken] - _amount;
    unsynthesizeStates[_txID] = UnsynthesizeState.Unsynthesized;

    if (_finalSwapCalldata.length == 0) {
      unlockAssets(_rToken, _amount, _to);
      emit BurnCompleted(_txID, address(this), _amount, _rToken);
      return;
    }

    IERC20(_rToken).approve(_finalDexRouter, _amount);
    (bool success, ) = _finalDexRouter.call(_finalSwapCalldata);
    require(success, "Portal: swap in metaUnsynthesize failed");

    emit BurnCompleted(_txID, address(this), _amount, _rToken);
  }

  /**
   * @notice Revert burnSyntheticToken() operation
   * @dev Can called only by bridge after initiation on a second chain
   * @dev Further, this transaction also enters the relay network and is called on the other side under the method "revertBurn"
   * @param _txID the synthesize transaction that was received from the event when it was originally called burn on the Synthesize contract
   * @param _receiveSide Synthesis address on another network
   * @param _oppositeBridge Bridge address on another network
   * @param _chainId Chain id of the network
   */
  function revertBurnRequest(
    bytes32 _txID,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainId
  ) external payable whenNotPaused {
    require(
      unsynthesizeStates[_txID] != UnsynthesizeState.Unsynthesized,
      "Symb: Real tokens already transfered"
    );
    require(msg.value == nativeTokenPrice, "Symb: Not enough money");
    unsynthesizeStates[_txID] = UnsynthesizeState.RevertRequest;

    bytes memory out = abi.encodeWithSelector(
      bytes4(keccak256(bytes("revertBurn(bytes32)"))),
      _txID
    );
    IBridge(bridge).transmitRequestV2(
      out,
      _receiveSide,
      _oppositeBridge,
      _chainId
    );

    emit RevertBurnRequest(_txID, _msgSender());
  }

  // ** ONLYOWNER functions **

  /**
   * @notice Set paused flag to true
   */
  function pause() external onlyOwner {
    paused = true;
  }

  /**
   * @notice Set paused flag to false
   */
  function unpause() external onlyOwner {
    paused = false;
  }

  /**
   * @notice Changes bridge price
   */
  function changeBridgePrice(uint256 _newPrice) external onlyOwner {
    nativeTokenPrice = _newPrice;
  }

  /**
   * @notice Withdraws bridge fee
   */
  function withdrawBridgeFee(address payable _to) external onlyOwner {
    require(_to != address(0x0));
    _to.transfer((address(this).balance));
  }

  /// ** INTERNAL functions **

  /**
   * @dev Sends synthesize request
   * @dev Internal function used in synthesize, synthesizeNative, synthesizeWithPermit
   */
  function sendSynthesizeRequest(
    address _token,
    uint256 _amount,
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) internal returns (bytes32 txID) {
    balanceOf[_token] = balanceOf[_token] + _amount;
    txID = keccak256(abi.encodePacked(this, requestCount, block.chainid));

    bytes memory out = abi.encodeWithSelector(
      bytes4(
        keccak256(
          bytes("mintSyntheticToken(bytes32,address,uint256,uint256,address)")
        )
      ),
      txID,
      _token,
      block.chainid,
      _amount,
      _chain2address
    );

    requests[txID] = TxState({
      recipient: _msgSender(),
      chain2address: _chain2address,
      rtoken: _token,
      amount: _amount,
      state: RequestState.Sent
    });

    requestCount += 1;
    IBridge(bridge).transmitRequestV2(
      out,
      _receiveSide,
      _oppositeBridge,
      _chainID
    );

    emit SynthesizeRequest(txID, _msgSender(), _chain2address, _amount, _token);
  }

  // TODO: add docs
  function sendMetaSynthesizeRequest(
    MetaRouteStructs.MetaSynthesizeTransaction memory _metaSynthesizeTransaction
  ) internal returns (bytes32 txID) {
    balanceOf[_metaSynthesizeTransaction.rtoken] =
      balanceOf[_metaSynthesizeTransaction.rtoken] +
      _metaSynthesizeTransaction.amount;
    txID = keccak256(abi.encodePacked(this, requestCount, block.chainid));

    MetaRouteStructs.MetaMintTransaction
      memory _metaMintTransaction = MetaRouteStructs.MetaMintTransaction(
        txID,
        _metaSynthesizeTransaction.rtoken,
        block.chainid,
        _metaSynthesizeTransaction.amount,
        _metaSynthesizeTransaction.chain2address,
        _metaSynthesizeTransaction.secondPath,
        _metaSynthesizeTransaction.secondDexRouter,
        _metaSynthesizeTransaction.secondAmountOutMin,
        _metaSynthesizeTransaction.finalPath,
        _metaSynthesizeTransaction.finalDexRouter,
        _metaSynthesizeTransaction.finalAmountOutMin,
        _metaSynthesizeTransaction.finalDeadline
      );

    bytes memory out = abi.encodeWithSignature(
      "metaMintSyntheticToken((bytes32,address,uint256,uint256,address,address[],"
      "address,uint256,address[],address,uint256,uint256))",
      _metaMintTransaction
    );

    requests[txID] = TxState({
      recipient: _metaSynthesizeTransaction.syntCaller,
      chain2address: _metaSynthesizeTransaction.chain2address,
      rtoken: _metaSynthesizeTransaction.rtoken,
      amount: _metaSynthesizeTransaction.amount,
      state: RequestState.Sent
    });

    requestCount += 1;
    IBridge(bridge).transmitRequestV2(
      out,
      _metaSynthesizeTransaction.receiveSide,
      _metaSynthesizeTransaction.oppositeBridge,
      _metaSynthesizeTransaction.chainID
    );

    emit SynthesizeRequest(
      txID,
      _msgSender(),
      _metaSynthesizeTransaction.chain2address,
      _metaSynthesizeTransaction.amount,
      _metaSynthesizeTransaction.rtoken
    );
  }

  /**
   * @dev Unlocks assets
   * @dev Internal function used in revertSynthesize and unsynthesize
   */
  function unlockAssets(
    address _token,
    uint256 _amount,
    address _to
  ) internal {
    if (_token == wrapper) {
      symbHelper.withdrawFromWrapper(wrapper, _amount, _to);
    } else {
      TransferHelper.safeTransfer(_token, _to, _amount);
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    address private _owner;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IBridge {
    function transmitRequestV2(
        bytes memory owner,
        address receiveSide,
        address oppositeBridge,
        uint256 chainID
    ) external;

    function receiveRequestV2(
        bytes32 _requestId,
        bytes memory _callData,
        address _receiveSide,
        address _bridgeFrom
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract RelayRecipientUpgradeable is OwnableUpgradeable {
    address private _trustedForwarder;

    function __RelayRecipient_init(address trustedForwarder)
        internal
        initializer
    {
        __Ownable_init();
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrapper is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/IWrapper.sol";

/**
 * @title Helper contract
 */
contract SymbHelper is Ownable {
    /**
     * @notice Deposits to wrapper
     */
    function depositToWrapper(address wrapper) external payable onlyOwner {
        IWrapper(wrapper).deposit{value: msg.value}();
    }

    /**
     * @notice Withdraws from wrapper
     */
    function withdrawFromWrapper(
        address wrapper,
        uint256 amount,
        address recipient
    ) external onlyOwner {
        IWrapper(wrapper).withdraw(amount);
        address payable payer = payable(recipient);
        payer.transfer(amount);
    }

    receive() external payable {}
}

pragma solidity 0.8.0;


interface ISymbiosisV2Router02Restricted {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

     function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        virtual
        returns (uint[] memory amounts);
}

pragma solidity ^0.8.0;

library MetaRouteStructs {
  struct MetaBurnTransaction {
    address syntCaller;
    address finalDexRouter;
    address sToken;
    bytes swapCallData;
    uint256 amount;
    address chain2address;
    address receiveSide;
    address oppositeBridge;
    uint256 chainID;
  }

  struct MetaMintTransaction {
    bytes32 txID;
    address tokenReal;
    uint256 chainID;
    uint256 amount;
    address to;
    address[] secondPath;
    address secondDexRouter;
    uint256 secondAmountOutMin;
    address[] finalPath;
    address finalDexRouter;
    uint256 finalAmountOutMin;
    uint256 finalDeadline;
  }

  struct MetaRouteReverseTransaction {
    address to;
    address[] firstPath; // firstToken -> secondToken
    address[] secondPath; // sSecondToken -> WETH
    address[] finalPath; // WETH -> finalToken
    address firstDexRouter;
    address secondDexRouter;
    uint256 amount;
    uint256 firstAmountOutMin;
    uint256 secondAmountOutMin;
    uint256 firstDeadline;
    uint256 finalAmountOutMin;
    uint256 finalDeadline;
    address finalDexRouter;
    uint256 chainID;
    address bridge;
    address synthesis;
  }

  struct MetaRouteTransaction {
    address to;
    address[] firstPath; // uni -> BUSD
    address[] secondPath; // BUSD -> sToken
    address[] finalPath; // rToken -> another token
    address firstDexRouter;
    address secondDexRouter;
    uint256 amount;
    uint256 firstAmountOutMin;
    uint256 secondAmountOutMin;
    uint256 firstDeadline;
    uint256 finalAmountOutMin;
    uint256 finalDeadline;
    address finalDexRouter;
    uint256 chainID;
    address bridge;
    address portal;
  }

  struct MetaSynthesizeTransaction {
    address rtoken;
    uint256 amount;
    address chain2address;
    address receiveSide;
    address oppositeBridge;
    address syntCaller;
    uint256 chainID;
    address[] secondPath;
    address secondDexRouter;
    uint256 secondAmountOutMin;
    address[] finalPath;
    address finalDexRouter;
    uint256 finalAmountOutMin;
    uint256 finalDeadline;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

