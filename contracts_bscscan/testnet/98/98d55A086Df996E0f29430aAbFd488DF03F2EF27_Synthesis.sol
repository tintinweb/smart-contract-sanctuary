// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/ISyntFabric.sol";
import "./interfaces/ISynthesis.sol";
import "./RelayRecipientUpgradeable.sol";
import "../stabledex/interfaces/ISwap.sol";
import "../symbdex/interfaces/IERC20.sol";
import "../symbdex/interfaces/ISymbiosisV2Router02Restricted.sol";
import "../MetaRouteStructs.sol";

/**
 * @title A contract that burns (unsynthesizes) tokens
 * @dev All function calls are currently implemented without side effects
 */
contract Synthesis is RelayRecipientUpgradeable {
  /// ** PUBLIC states **

  uint256 public requestCount;
  bool public paused;
  uint256 public nativeTokenPrice;
  address public fabric;
  mapping(bytes32 => TxState) public requests;
  mapping(bytes32 => SynthesizeState) public synthesizeStates;
  address public bridge;

  /// ** STRUCTS **

  enum RequestState {
    Default,
    Sent,
    Reverted
  }
  enum SynthesizeState {
    Default,
    Synthesized,
    RevertRequest
  }
  struct TxState {
    address recipient;
    address chain2address;
    uint256 amount;
    address token;
    address stoken;
    RequestState state;
  }

  /// ** EVENTS **

  event BurnRequest(
    bytes32 id,
    address from,
    address to,
    uint256 amount,
    address token
  );
  event RevertSynthesizeRequest(bytes32 indexed id, address indexed to);
  event SynthesizeCompleted(
    bytes32 indexed id,
    address indexed to,
    uint256 amount,
    address token
  );
  event RevertBurnCompleted(
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

  /// ** INITIALIZER **

  /**
   * init
   */

  function initialize(address _bridge, address _trustedForwarder)
    public
    virtual
    initializer
  {
    __RelayRecipient_init(_trustedForwarder);
    bridge = _bridge;
    nativeTokenPrice = 10000000000000000;
    // 0.01 of native token
  }

  /// ** PUBLIC functions **

  /**
   * @notice Returns version
   */
  function versionRecipient() public view returns (string memory) {
    return "2.0.1";
  }

  /// ** EXTERNAL functions **

  /**
   * @notice Synthesis contract subcall with synthesis Parameters
   * @dev Can called only by bridge after initiation on a second chain
   * @param _txID the synthesize transaction that was received from the event when it was originally called burn on the Synthesize contract
   * @param _tokenReal The address of the token that the user wants to synthesize
   * @param _chainID Chain id of the network where synthesization will take place
   * @param _amount Number of tokens to synthesize
   * @param _to The address to which the user wants to receive the synth asset on another network
   */
  function mintSyntheticToken(
    bytes32 _txID,
    address _tokenReal,
    uint256 _chainID,
    uint256 _amount,
    address _to
  ) external onlyBridge whenNotPaused {
    require(
      synthesizeStates[_txID] == SynthesizeState.Default,
      "Symb: emergencyUnsynthesizedRequest called or tokens has been already synthesized"
    );
    synthesizeStates[_txID] = SynthesizeState.Synthesized;
    ISyntFabric(fabric).synthesize(
      _to,
      _amount,
      ISyntFabric(fabric).getSyntRepresentation(_tokenReal, _chainID)
    );
    emit SynthesizeCompleted(_txID, _to, _amount, _tokenReal);
  }

  // TODO: add natspec
  function metaMintSyntheticToken(
    MetaRouteStructs.MetaMintTransaction memory _metaMintTransaction
  ) external onlyBridge whenNotPaused {
    require(
      synthesizeStates[_metaMintTransaction.txID] == SynthesizeState.Default,
      "Symb: emergencyUnsynthesizedRequest called or tokens has been already synthesized"
    );
    synthesizeStates[_metaMintTransaction.txID] = SynthesizeState.Synthesized;
    address syntReprAddr = ISyntFabric(fabric).getSyntRepresentation(
      _metaMintTransaction.tokenReal,
      _metaMintTransaction.chainID
    );

    ISyntFabric(fabric).synthesize(
      address(this),
      _metaMintTransaction.amount,
      syntReprAddr
    );
    emit SynthesizeCompleted(
      _metaMintTransaction.txID,
      _metaMintTransaction.to,
      _metaMintTransaction.amount,
      _metaMintTransaction.tokenReal
    );

    if (_metaMintTransaction.secondPath.length == 0) {
      TransferHelper.safeTransfer(
        syntReprAddr,
        _metaMintTransaction.to,
        _metaMintTransaction.amount
      );
      return;
    }

    IERC20(_metaMintTransaction.secondPath[0]).approve(
      _metaMintTransaction.secondDexRouter,
      _metaMintTransaction.amount
    );

    ISwap(_metaMintTransaction.secondDexRouter).swap(
      ISwap(_metaMintTransaction.secondDexRouter).getTokenIndex(
        _metaMintTransaction.secondPath[0]
      ),
      ISwap(_metaMintTransaction.secondDexRouter).getTokenIndex(
        _metaMintTransaction.secondPath[1]
      ),
      _metaMintTransaction.amount,
      _metaMintTransaction.secondAmountOutMin,
      _metaMintTransaction.finalDeadline
    );

    uint256 secondSwapReturnAmount = IERC20(_metaMintTransaction.secondPath[1])
      .balanceOf(address(this));

    if (_metaMintTransaction.finalPath.length == 0) {
      TransferHelper.safeTransfer(
        _metaMintTransaction.secondPath[1],
        _metaMintTransaction.to,
        secondSwapReturnAmount
      );
      return;
    }

    IERC20(_metaMintTransaction.finalPath[0]).approve(
      _metaMintTransaction.finalDexRouter,
      secondSwapReturnAmount
    );

    ISymbiosisV2Router02Restricted(_metaMintTransaction.finalDexRouter)
      .swapExactTokensForTokens(
        secondSwapReturnAmount,
        _metaMintTransaction.finalAmountOutMin,
        _metaMintTransaction.finalPath,
        _metaMintTransaction.to,
        _metaMintTransaction.finalDeadline
      );
  }

  /**
   * @notice Revert synthesize() operation
   * @dev Can called only by bridge after initiation on a second chain
   * @dev Further, this transaction also enters the relay network and is called on the other side under the method "revertSynthesize"
   * @param _txID the synthesize transaction that was received from the event when it was originally called synthesize on the Portal contract
   * @param _receiveSide Synthesis address on another network
   * @param _oppositeBridge Bridge address on another network
   * @param _chainID Chain id of the network
   */
  function revertSynthesizeRequest(
    bytes32 _txID,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable whenNotPaused {
    require(msg.value == nativeTokenPrice, "Symb: Not enough money");
    require(
      synthesizeStates[_txID] != SynthesizeState.Synthesized,
      "Symb: syntatic tokens already minted"
    );
    synthesizeStates[_txID] = SynthesizeState.RevertRequest;
    // close
    bytes memory out = abi.encodeWithSelector(
      bytes4(keccak256(bytes("revertSynthesize(bytes32)"))),
      _txID
    );
    IBridge(bridge).transmitRequestV2(
      out,
      _receiveSide,
      _oppositeBridge,
      _chainID
    );

    emit RevertSynthesizeRequest(_txID, _msgSender());
  }

  /**
   * @notice Sends synthesize request
   * @dev sToken -> Token on a second chain
   * @param _stoken The address of the token that the user wants to burn
   * @param _amount Number of tokens to burn
   * @param _chain2address The address to which the user wants to receive tokens
   * @param _receiveSide Synthesis address on another network
   * @param _oppositeBridge Bridge address on another network
   * @param _chainID Chain id of the network where burning will take place
   */
  function burnSyntheticToken(
    address _stoken,
    uint256 _amount,
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable whenNotPaused returns (bytes32 _txID) {
    require(msg.value == nativeTokenPrice, "Symb: Not enough money");
    ISyntFabric(fabric).unsynthesize(_msgSender(), _amount, _stoken);
    address rtoken = ISyntFabric(fabric).getRealRepresentation(_stoken);
    _txID = keccak256(abi.encodePacked(this, requestCount, block.chainid));
    bytes memory out = abi.encodeWithSelector(
      bytes4(keccak256(bytes("unsynthesize(bytes32,address,uint256,address)"))),
      _txID,
      rtoken,
      _amount,
      _chain2address
    );

    requests[_txID] = TxState({
      recipient: _msgSender(),
      chain2address: _chain2address,
      token: rtoken,
      stoken: _stoken,
      amount: _amount,
      state: RequestState.Sent
    });

    requestCount++;

    IBridge(bridge).transmitRequestV2(
      out,
      _receiveSide,
      _oppositeBridge,
      _chainID
    );

    emit BurnRequest(_txID, _msgSender(), _chain2address, _amount, _stoken);
  }

  function metaBurnSyntheticToken(
    MetaRouteStructs.MetaBurnTransaction memory _metaBurnTransaction
  ) external payable whenNotPaused returns (bytes32 _txID) {
    require(msg.value == nativeTokenPrice, "Symb: Not enough money");

    ISyntFabric(fabric).unsynthesize(
      _msgSender(),
      _metaBurnTransaction.amount,
      _metaBurnTransaction.sToken
    );

    address rtoken = ISyntFabric(fabric).getRealRepresentation(
      _metaBurnTransaction.sToken
    );

    _txID = keccak256(abi.encodePacked(this, requestCount, block.chainid));

    bytes memory out = abi.encodeWithSelector(
      bytes4(
        keccak256(
          bytes(
            "metaUnsynthesize(bytes32,address,uint256,address,address,bytes)"
          )
        )
      ),
      _txID,
      _metaBurnTransaction.chain2address,
      _metaBurnTransaction.amount,
      rtoken,
      _metaBurnTransaction.finalDexRouter,
      _metaBurnTransaction.swapCallData
    );

    requests[_txID] = TxState({
      recipient: _metaBurnTransaction.syntCaller,
      chain2address: _metaBurnTransaction.chain2address,
      token: rtoken,
      stoken: _metaBurnTransaction.sToken,
      amount: _metaBurnTransaction.amount,
      state: RequestState.Sent
    });

    requestCount++;

    IBridge(bridge).transmitRequestV2(
      out,
      _metaBurnTransaction.receiveSide,
      _metaBurnTransaction.oppositeBridge,
      _metaBurnTransaction.chainID
    );

    emit BurnRequest(
      _txID,
      _msgSender(),
      _metaBurnTransaction.chain2address,
      _metaBurnTransaction.amount,
      _metaBurnTransaction.sToken
    );
  }

  /**
   * @notice Emergency unburn
   * @dev Can called only by bridge after initiation on a second chain
   * @param _txID the synthesize transaction that was received from the event when it was originally called burn on the Synthesize contract
   */
  function revertBurn(bytes32 _txID) external onlyBridge whenNotPaused {
    TxState storage txState = requests[_txID];
    require(
      txState.state == RequestState.Sent,
      "Symb: state not open or tx does not exist"
    );
    txState.state = RequestState.Reverted;
    // close
    ISyntFabric(fabric).synthesize(
      txState.recipient,
      txState.amount,
      txState.stoken
    );
    emit RevertBurnCompleted(
      _txID,
      txState.recipient,
      txState.amount,
      txState.stoken
    );
  }

  /// ** ONLYOWNER functions **

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
   * Changes bridge price
   */
  function changeBridgePrice(uint256 _newPrice) external onlyOwner {
    nativeTokenPrice = _newPrice;
  }

  /**
   * @notice Withdraws bridge fee
   */
  function withdrawBridgeFee(address payable _to) external onlyOwner {
    _to.transfer((address(this).balance));
  }

  /// @notice checks if there is not paused
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @notice Sets Fabric address
   */
  function setFabric(address _fabric) external onlyOwner {
    require(fabric == address(0x0), "Symb: Fabric already set");
    fabric = _fabric;
  }

  /**
   * @notice Gets bridging fee
   */
  function getBridgingFee() external view returns (uint256) {
    return nativeTokenPrice;
  }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ISyntFabric {
    function getRealRepresentation(address _syntTokenAdr)
        external
        view
        returns (address);

    function getSyntRepresentation(address _realTokenAdr, uint256 _chainID)
        external
        view
        returns (address);

    function synthesize(
        address _to,
        uint256 _amount,
        address _stoken
    ) external;

    function unsynthesize(
        address _to,
        uint256 _amount,
        address _stoken
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

import "../../MetaRouteStructs.sol";

interface ISynthesis {
  function mintSyntheticToken(
    bytes32 _txID,
    address _tokenReal,
    uint256 _chainID,
    uint256 _amount,
    address _to
  ) external;

  function revertSynthesizeRequest(
    bytes32 _txID,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable;

  function burnSyntheticToken(
    address _stoken,
    uint256 _amount,
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable returns (bytes32 txID);

  function metaBurnSyntheticToken(
    MetaRouteStructs.MetaBurnTransaction memory _metaBurnTransaction
  ) external payable returns (bytes32 txID);

  function revertBurn(bytes32 _txID) external;

  function getBridgingFee() external view returns (uint256);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISwap {
    function updateUserWithdrawFee(address recipient, uint256 transferAmount)
    external;

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external;

    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function getTokenIndex(address tokenAddress) external view returns (uint8);
}

pragma solidity >=0.5.0;

interface IERC20 {
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

