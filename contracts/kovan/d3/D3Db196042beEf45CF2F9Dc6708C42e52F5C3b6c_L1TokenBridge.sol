// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { ILyra } from "../interfaces/ILyra.sol";
import { IL1TokenBridge } from "../interfaces/IL1TokenBridge.sol";
import { IL2TokenBridge } from "../interfaces/IL2TokenBridge.sol";
import { iOVM_L2DepositedToken } from "@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L2DepositedToken.sol";
import { BaseTokenBridge } from "./BaseTokenBridge.sol";
import { OVMCrossDomainEnabled } from "./OVMCrossDomainEnabled.sol";

/**
 * @title L1TokenBridge
 * @dev Stores deposited L1 funds that are in use on L2.
 * It synchronizes a corresponding L2 representation of the "deposited token", informing it
 * of new deposits and releasing L1 funds when there are newly finalized withdrawals.
 */
contract L1TokenBridge is IL1TokenBridge, BaseTokenBridge {
  // Default gas value which can be overridden if more complex logic runs on L2.
  uint32 internal constant DEFAULT_FINALIZE_DEPOSIT_L2_GAS = 1200000;

  ILyra public immutable token;
  address public immutable l2TokenBridge;

  /**
   * @dev Store references to external contracts
   * @param _token L1 ERC20 address this contract stores deposits for
   * @param _l2TokenBridge IL2TokenBridge-compatible address on the chain being deposited into.
   * @param _l1Messenger L1 Messenger address being used for cross-chain communications.
   */
  constructor(
    ILyra _token,
    address _l2TokenBridge,
    address _l1Messenger
  ) OVMCrossDomainEnabled(_l1Messenger) {
    token = _token;
    l2TokenBridge = _l2TokenBridge;
  }

  /**
   * @dev deposit an amount of the ERC20 to the caller's balance on L2
   * @param _amount Amount of the ERC20 to deposit
   */
  function deposit(uint256 _amount) external virtual override {
    _initiateDeposit(msg.sender, msg.sender, _amount);
  }

  /**
   * @dev deposit an amount of ERC20 to a recipient on L2
   * @param _to L2 address to credit the withdrawal to
   * @param _amount Amount of the ERC20 to deposit
   */
  function depositTo(address _to, uint256 _amount) external virtual override {
    _initiateDeposit(msg.sender, _to, _amount);
  }

  /**
   * @dev  deposit an amount of the ERC20 to the caller's balance on L2 using a permit signature for approval
   * @param _amount Amount of the ERC20 to deposit
   * @param _deadline The time at which this expires (unix time)
   * @param _v v of the signature
   * @param _r r of the signature
   * @param _s s of the signature
   */
  function depositWithPermit(
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external virtual override {
    _permit(token, msg.sender, address(this), _amount, _deadline, _v, _r, _s);
    _initiateDeposit(msg.sender, msg.sender, _amount);
  }

  /**
   * @dev deposit an amount of ERC20 to a recipient on L2 using a permit signature for approval
   * @param _to L2 address to credit the withdrawal to
   * @param _amount Amount of the ERC20 to deposit
   * @param _deadline The time at which this expires (unix time)
   * @param _v v of the signature
   * @param _r r of the signature
   * @param _s s of the signature
   */
  function depositToWithPermit(
    address _to,
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external virtual override {
    _permit(token, msg.sender, address(this), _amount, _deadline, _v, _r, _s);
    _initiateDeposit(msg.sender, _to, _amount);
  }

  /**
   * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the
   * L1 ERC20 token.
   * This call will fail if the initialized withdrawal from L2 has not been finalized.
   *
   * @param _to L1 address to credit the withdrawal to
   * @param _amount Amount of the ERC20 to withdraw
   */
  function finalizeWithdrawal(address _to, uint256 _amount)
    external
    virtual
    override
    onlyFromCrossDomainAccount(l2TokenBridge)
  {
    // Transfer withdrawn funds out
    token.transfer(_to, _amount);

    emit WithdrawalFinalized(_to, _amount);
  }

  /**
   * @dev Overridable getter for the L2 gas limit, in the case it may be
   * dynamic, and the above public constant does not suffice.
   *
   */
  function getFinalizeDepositL2Gas() public view virtual returns (uint32) {
    return DEFAULT_FINALIZE_DEPOSIT_L2_GAS;
  }

  /**
   * @dev Performs the logic for deposits by informing the L2 Deposited Token
   * contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
   *
   * @param _from Account to pull the deposit from on L1
   * @param _to Account to give the deposit to on L2
   * @param _amount Amount of the ERC20 to deposit.
   */
  function _initiateDeposit(
    address _from,
    address _to,
    uint256 _amount
  ) internal {
    // Lock funds in the contract
    token.transferFrom(_from, address(this), _amount);

    // Construct calldata for l2DepositedToken.finalizeDeposit(_to, _amount)
    bytes memory data = abi.encodeWithSelector(iOVM_L2DepositedToken.finalizeDeposit.selector, _to, _amount);

    // Send calldata into L2
    sendCrossDomainMessage(l2TokenBridge, data, getFinalizeDepositL2Gas());

    emit DepositInitiated(_from, _to, _amount);
  }
}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/drafts/IERC20Permit.sol";

// solhint-disable-next-line no-empty-blocks
interface ILyra is IERC20, IERC20Permit {

}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { iOVM_L1TokenGateway } from "@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L1TokenGateway.sol";

interface IL1TokenBridge is iOVM_L1TokenGateway {
  function depositWithPermit(
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  function depositToWithPermit(
    address _to,
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;
}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { iOVM_L2DepositedToken } from "@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L2DepositedToken.sol";

interface IL2TokenBridge is iOVM_L2DepositedToken {
  function withdrawWithPermit(
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  function withdrawToWithPermit(
    address _to,
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_L2DepositedToken
 */
interface iOVM_L2DepositedToken {

    /**********
     * Events *
     **********/

    event WithdrawalInitiated(
        address indexed _from,
        address _to,
        uint256 _amount
    );

    event DepositFinalized(
        address indexed _to,
        uint256 _amount
    );


    /********************
     * Public Functions *
     ********************/

    function withdraw(
        uint _amount
    )
        external;

    function withdrawTo(
        address _to,
        uint _amount
    )
        external;


    /*************************
     * Cross-chain Functions *
     *************************/

    function finalizeDeposit(
        address _to,
        uint _amount
    )
        external;
}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { OVMCrossDomainEnabled } from "./OVMCrossDomainEnabled.sol";
import { IERC20Permit } from "@openzeppelin/contracts/drafts/IERC20Permit.sol";

/**
 * @title BaseTokenBridge
 * @dev Handle common logic for L1 and L2 token bridge contracts
 */
abstract contract BaseTokenBridge is OVMCrossDomainEnabled {
  /**
   * @dev Calls permit on the token
   * @param _token Address of the token
   * @param _owner Owner of the tokens
   * @param _spender Spender of the tokens
   * @param _amount Amount of the ERC20 to deposit
   * @param _deadline The time at which this expires (unix time)
   * @param _v v of the signature
   * @param _r r of the signature
   * @param _s s of the signature
   */
  function _permit(
    IERC20Permit _token,
    address _owner,
    address _spender,
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) internal {
    _token.permit(_owner, _spender, _amount, _deadline, _v, _r, _s);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {
  iAbs_BaseCrossDomainMessenger
} from "@eth-optimism/contracts/iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

/**
 * @title OVMCrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications.
 */
contract OVMCrossDomainEnabled {
  /*************
   * Variables *
   *************/

  // Messenger contract used to send and receive messages from the other domain.
  address public immutable messenger;

  /**********************
   * Function Modifiers *
   **********************/

  /**
   * Enforces that the modified function is only callable by a specific cross-domain account.
   * @param _sourceDomainAccount The only account on the originating domain which is
   *  authenticated to call this function.
   */
  modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
    require(msg.sender == address(getCrossDomainMessenger()), "OVM_XCHAIN: messenger contract unauthenticated");

    require(
      getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
      "OVM_XCHAIN: wrong sender of cross-domain message"
    );

    _;
  }

  /***************
   * Constructor *
   ***************/

  /**
   * @param _messenger Address of the CrossDomainMessenger on the current layer.
   */
  constructor(address _messenger) {
    messenger = _messenger;
  }

  /**********************
   * Internal Functions *
   **********************/

  /**
   * Gets the messenger, usually from storage. This function is exposed in case a child contract
   * needs to override.
   * @return The address of the cross-domain messenger contract which should be used.
   */
  function getCrossDomainMessenger() internal virtual returns (iAbs_BaseCrossDomainMessenger) {
    return iAbs_BaseCrossDomainMessenger(messenger);
  }

  /**
   * Sends a message to an account on another domain
   * @param _crossDomainTarget The intended recipient on the destination domain
   * @param _data The data to send to the target (usually calldata to a function with
   *  `onlyFromCrossDomainAccount()`)
   * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
   */
  function sendCrossDomainMessage(
    address _crossDomainTarget,
    bytes memory _data,
    uint32 _gasLimit
  ) internal {
    getCrossDomainMessenger().sendMessage(_crossDomainTarget, _data, _gasLimit);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_L1TokenGateway
 */
interface iOVM_L1TokenGateway {

    /**********
     * Events *
     **********/

    event DepositInitiated(
        address indexed _from,
        address _to,
        uint256 _amount
    );

    event WithdrawalFinalized(
        address indexed _to,
        uint256 _amount
    );


    /********************
     * Public Functions *
     ********************/

    function deposit(
        uint _amount
    )
        external;

    function depositTo(
        address _to,
        uint _amount
    )
        external;


    /*************************
     * Cross-chain Functions *
     *************************/

    function finalizeWithdrawal(
        address _to,
        uint _amount
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iAbs_BaseCrossDomainMessenger
 */
interface iAbs_BaseCrossDomainMessenger {

    /**********
     * Events *
     **********/

    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);
    event FailedRelayedMessage(bytes32 msgHash);


    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);


    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}