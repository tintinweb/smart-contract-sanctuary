// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_CrossDomainMessenger
 */
interface iOVM_CrossDomainMessenger {

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

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_CrossDomainMessenger } from
    "../../iOVM/bridge/messaging/iOVM_CrossDomainMessenger.sol";

/**
 * @title OVM_CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
contract OVM_CrossDomainEnabled {

    /*************
     * Variables *
     *************/

    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _messenger Address of the CrossDomainMessenger on the current layer.
     */
    constructor(
        address _messenger
    ) {
        messenger = _messenger;
    }


    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is
     *  authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(
        address _sourceDomainAccount
    ) {
        require(
            msg.sender == address(getCrossDomainMessenger()),
            "OVM_XCHAIN: messenger contract unauthenticated"
        );

        require(
            getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "OVM_XCHAIN: wrong sender of cross-domain message"
        );

        _;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the messenger, usually from storage. This function is exposed in case a child contract
     * needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainMessenger()
        internal
        virtual
        returns (
            iOVM_CrossDomainMessenger
        )
    {
        return iOVM_CrossDomainMessenger(messenger);
    }

    /**
     * Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _message The data to send to the target (usually calldata to a function with
     *  `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        uint32 _gasLimit,
        bytes memory _message
    )
        internal
    {
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _message, _gasLimit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_L1StandardBridge } from "../../../iOVM/bridge/tokens/iOVM_L1StandardBridge.sol";
import { iOVM_L1ERC20Bridge } from "../../../iOVM/bridge/tokens/iOVM_L1ERC20Bridge.sol";
import { iOVM_L2ERC20Bridge } from "../../../iOVM/bridge/tokens/iOVM_L2ERC20Bridge.sol";

/* Library Imports */
import { ERC165Checker } from "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import { OVM_CrossDomainEnabled } from "../../../libraries/bridge/OVM_CrossDomainEnabled.sol";
import { Lib_PredeployAddresses } from "../../../libraries/constants/Lib_PredeployAddresses.sol";

/* Contract Imports */
import { IL2StandardERC20 } from "../../../libraries/standards/IL2StandardERC20.sol";

/**
 * @title OVM_L2StandardBridge
 * @dev The L2 Standard bridge is a contract which works together with the L1 Standard bridge to
 * enable ETH and ERC20 transitions between L1 and L2.
 * This contract acts as a minter for new tokens when it hears about deposits into the L1 Standard
 * bridge.
 * This contract also acts as a burner of the tokens intended for withdrawal, informing the L1
 * bridge to release L1 funds.
 *
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_L2StandardBridge is iOVM_L2ERC20Bridge, OVM_CrossDomainEnabled {

    /********************************
     * External Contract References *
     ********************************/

    address public l1TokenBridge;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _l2CrossDomainMessenger Cross-domain messenger used by this contract.
     * @param _l1TokenBridge Address of the L1 bridge deployed to the main chain.
     */
    constructor(
        address _l2CrossDomainMessenger,
        address _l1TokenBridge
    )
        OVM_CrossDomainEnabled(_l2CrossDomainMessenger)
    {
        l1TokenBridge = _l1TokenBridge;
    }

    /***************
     * Withdrawing *
     ***************/

    /**
     * @inheritdoc iOVM_L2ERC20Bridge
     */
    function withdraw(
        address _l2Token,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    )
        external
        override
        virtual
    {
        _initiateWithdrawal(
            _l2Token,
            msg.sender,
            msg.sender,
            _amount,
            _l1Gas,
            _data
        );
    }

    /**
     * @inheritdoc iOVM_L2ERC20Bridge
     */
    function withdrawTo(
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    )
        external
        override
        virtual
    {
        _initiateWithdrawal(
            _l2Token,
            msg.sender,
            _to,
            _amount,
            _l1Gas,
            _data
        );
    }

    /**
     * @dev Performs the logic for deposits by storing the token and informing the L2 token Gateway
     * of the deposit.
     * @param _l2Token Address of L2 token where withdrawal was initiated.
     * @param _from Account to pull the deposit from on L2.
     * @param _to Account to give the withdrawal to on L1.
     * @param _amount Amount of the token to withdraw.
     * param _l1Gas Unused, but included for potential forward compatibility considerations.
     * @param _data Optional data to forward to L1. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function _initiateWithdrawal(
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    )
        internal
    {
        // When a withdrawal is initiated, we burn the withdrawer's funds to prevent subsequent L2
        // usage
        IL2StandardERC20(_l2Token).burn(msg.sender, _amount);

        // Construct calldata for l1TokenBridge.finalizeERC20Withdrawal(_to, _amount)
        address l1Token = IL2StandardERC20(_l2Token).l1Token();
        bytes memory message;

        if (_l2Token == Lib_PredeployAddresses.OVM_ETH) {
            message = abi.encodeWithSelector(
                        iOVM_L1StandardBridge.finalizeETHWithdrawal.selector,
                        _from,
                        _to,
                        _amount,
                        _data
                    );
        } else {
            message = abi.encodeWithSelector(
                        iOVM_L1ERC20Bridge.finalizeERC20Withdrawal.selector,
                        l1Token,
                        _l2Token,
                        _from,
                        _to,
                        _amount,
                        _data
                    );
        }

        // Send message up to L1 bridge
        sendCrossDomainMessage(
            l1TokenBridge,
            _l1Gas,
            message
        );

        emit WithdrawalInitiated(l1Token, _l2Token, msg.sender, _to, _amount, _data);
    }

    /************************************
     * Cross-chain Function: Depositing *
     ************************************/

    /**
     * @inheritdoc iOVM_L2ERC20Bridge
     */
    function finalizeDeposit(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    )
        external
        override
        virtual
        onlyFromCrossDomainAccount(l1TokenBridge)
    {
        // Check the target token is compliant and
        // verify the deposited token on L1 matches the L2 deposited token representation here
        if (
            ERC165Checker.supportsInterface(_l2Token, 0x1d1d8b63) &&
            _l1Token == IL2StandardERC20(_l2Token).l1Token()
        ) {
            // When a deposit is finalized, we credit the account on L2 with the same amount of
            // tokens.
            IL2StandardERC20(_l2Token).mint(_to, _amount);
            emit DepositFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
        } else {
            // Either the L2 token which is being deposited-into disagrees about the correct address
            // of its L1 token, or does not support the correct interface.
            // This should only happen if there is a  malicious L2 token, or if a user somehow
            // specified the wrong L2 token address to deposit into.
            // In either case, we stop the process here and construct a withdrawal
            // message so that users can get their funds out in some cases.
            // There is no way to prevent malicious token contracts altogether, but this does limit
            // user error and mitigate some forms of malicious contract behavior.
            bytes memory message = abi.encodeWithSelector(
                iOVM_L1ERC20Bridge.finalizeERC20Withdrawal.selector,
                _l1Token,
                _l2Token,
                _to,   // switched the _to and _from here to bounce back the deposit to the sender
                _from,
                _amount,
                _data
            );

            // Send message up to L1 bridge
            sendCrossDomainMessage(
                l1TokenBridge,
                0,
                message
            );
            emit DepositFailed(_l1Token, _l2Token, _from, _to, _amount, _data);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;
pragma experimental ABIEncoderV2;

import "./iOVM_L1ERC20Bridge.sol";

/**
 * @title iOVM_L1StandardBridge
 */
interface iOVM_L1StandardBridge is iOVM_L1ERC20Bridge {

    /**********
     * Events *
     **********/
    event ETHDepositInitiated (
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        bytes _data
    );

    event ETHWithdrawalFinalized (
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        bytes _data
    );

    /********************
     * Public Functions *
     ********************/

    /**
     * @dev Deposit an amount of the ETH to the caller's balance on L2.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositETH (
        uint32 _l2Gas,
        bytes calldata _data
    )
        external
        payable;

    /**
     * @dev Deposit an amount of ETH to a recipient's balance on L2.
     * @param _to L2 address to credit the withdrawal to.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositETHTo (
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external
        payable;

    /*************************
     * Cross-chain Functions *
     *************************/

    /**
     * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the
     * L1 ETH token. Since only the xDomainMessenger can call this function, it will never be called
     * before the withdrawal is finalized.
     * @param _from L2 address initiating the transfer.
     * @param _to L1 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function finalizeETHWithdrawal (
        address _from,
        address _to,
        uint _amount,
        bytes calldata _data
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_L1ERC20Bridge
 */
interface iOVM_L1ERC20Bridge {

    /**********
     * Events *
     **********/

    event ERC20DepositInitiated (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event ERC20WithdrawalFinalized (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    /********************
     * Public Functions *
     ********************/

    /**
     * @dev deposit an amount of the ERC20 to the caller's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _amount Amount of the ERC20 to deposit
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20 (
        address _l1Token,
        address _l2Token,
        uint _amount,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external;

    /**
     * @dev deposit an amount of ERC20 to a recipient's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _to L2 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20To (
        address _l1Token,
        address _l2Token,
        address _to,
        uint _amount,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external;


    /*************************
     * Cross-chain Functions *
     *************************/

    /**
     * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the
     * L1 ERC20 token.
     * This call will fail if the initialized withdrawal from L2 has not been finalized.
     *
     * @param _l1Token Address of L1 token to finalizeWithdrawal for.
     * @param _l2Token Address of L2 token where withdrawal was initiated.
     * @param _from L2 address initiating the transfer.
     * @param _to L1 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _data Data provided by the sender on L2. This data is provided
     *   solely as a convenience for external contracts. Aside from enforcing a maximum
     *   length, these contracts provide no guarantees about its content.
     */
    function finalizeERC20Withdrawal (
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint _amount,
        bytes calldata _data
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_L2ERC20Bridge
 */
interface iOVM_L2ERC20Bridge {

    /**********
     * Events *
     **********/

    event WithdrawalInitiated (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event DepositFinalized (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event DepositFailed (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );


    /********************
     * Public Functions *
     ********************/

    /**
     * @dev initiate a withdraw of some tokens to the caller's account on L1
     * @param _l2Token Address of L2 token where withdrawal was initiated.
     * @param _amount Amount of the token to withdraw.
     * param _l1Gas Unused, but included for potential forward compatibility considerations.
     * @param _data Optional data to forward to L1. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function withdraw (
        address _l2Token,
        uint _amount,
        uint32 _l1Gas,
        bytes calldata _data
    )
        external;

    /**
     * @dev initiate a withdraw of some token to a recipient's account on L1.
     * @param _l2Token Address of L2 token where withdrawal is initiated.
     * @param _to L1 adress to credit the withdrawal to.
     * @param _amount Amount of the token to withdraw.
     * param _l1Gas Unused, but included for potential forward compatibility considerations.
     * @param _data Optional data to forward to L1. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function withdrawTo (
        address _l2Token,
        address _to,
        uint _amount,
        uint32 _l1Gas,
        bytes calldata _data
    )
        external;

    /*************************
     * Cross-chain Functions *
     *************************/

    /**
     * @dev Complete a deposit from L1 to L2, and credits funds to the recipient's balance of this
     * L2 token. This call will fail if it did not originate from a corresponding deposit in
     * OVM_l1TokenGateway.
     * @param _l1Token Address for the l1 token this is called with
     * @param _l2Token Address for the l2 token this is called with
     * @param _from Account to pull the deposit from on L2.
     * @param _to Address to receive the withdrawal at
     * @param _amount Amount of the token to withdraw
     * @param _data Data provider by the sender on L1. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function finalizeDeposit (
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint _amount,
        bytes calldata _data
    )
        external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_PredeployAddresses
 */
library Lib_PredeployAddresses {
    address internal constant L2_TO_L1_MESSAGE_PASSER = 0x4200000000000000000000000000000000000000;
    address internal constant L1_MESSAGE_SENDER = 0x4200000000000000000000000000000000000001;
    address internal constant DEPLOYER_WHITELIST = 0x4200000000000000000000000000000000000002;
    address internal constant ECDSA_CONTRACT_ACCOUNT = 0x4200000000000000000000000000000000000003;
    address internal constant SEQUENCER_ENTRYPOINT = 0x4200000000000000000000000000000000000005;
    address payable internal constant OVM_ETH = 0x4200000000000000000000000000000000000006;
    // solhint-disable-next-line max-line-length
    address internal constant L2_CROSS_DOMAIN_MESSENGER = 0x4200000000000000000000000000000000000007;
    address internal constant LIB_ADDRESS_MANAGER = 0x4200000000000000000000000000000000000008;
    address internal constant PROXY_EOA = 0x4200000000000000000000000000000000000009;
    // solhint-disable-next-line max-line-length
    address internal constant EXECUTION_MANAGER_WRAPPER = 0x420000000000000000000000000000000000000B;
    address internal constant SEQUENCER_FEE_WALLET = 0x4200000000000000000000000000000000000011;
    address internal constant ERC1820_REGISTRY = 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
    address internal constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/introspection/IERC165.sol";

interface IL2StandardERC20 is IERC20, IERC165 {
    function l1Token() external returns (address);

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    event Mint(address indexed _account, uint256 _amount);
    event Burn(address indexed _account, uint256 _amount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_PredeployAddresses } from "../../libraries/constants/Lib_PredeployAddresses.sol";

/* Contract Imports */
import { OVM_ETH } from "../predeploys/OVM_ETH.sol";
import { OVM_L2StandardBridge } from "../bridge/tokens/OVM_L2StandardBridge.sol";

/**
 * @title OVM_SequencerFeeVault
 * @dev Simple holding contract for fees paid to the Sequencer. Likely to be replaced in the future
 * but "good enough for now".
 *
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_SequencerFeeVault {

    /*************
     * Constants *
     *************/

    // Minimum ETH balance that can be withdrawn in a single withdrawal.
    uint256 public constant MIN_WITHDRAWAL_AMOUNT = 15 ether;


    /*************
     * Variables *
     *************/

    // Address on L1 that will hold the fees once withdrawn. Dynamically initialized within l2geth.
    address public l1FeeWallet;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _l1FeeWallet Initial address for the L1 wallet that will hold fees once withdrawn.
     * Currently HAS NO EFFECT in production because l2geth will mutate this storage slot during
     * the genesis block. This is ONLY for testing purposes.
     */
    constructor(
        address _l1FeeWallet
    ) {
        l1FeeWallet = _l1FeeWallet;
    }


    /********************
     * Public Functions *
     ********************/

    function withdraw()
        public
    {
        uint256 balance = OVM_ETH(Lib_PredeployAddresses.OVM_ETH).balanceOf(address(this));

        require(
            balance >= MIN_WITHDRAWAL_AMOUNT,
            // solhint-disable-next-line max-line-length
            "OVM_SequencerFeeVault: withdrawal amount must be greater than minimum withdrawal amount"
        );

        OVM_L2StandardBridge(Lib_PredeployAddresses.L2_STANDARD_BRIDGE).withdrawTo(
            Lib_PredeployAddresses.OVM_ETH,
            l1FeeWallet,
            balance,
            0,
            bytes("")
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_PredeployAddresses } from "../../libraries/constants/Lib_PredeployAddresses.sol";

/* Contract Imports */
import { L2StandardERC20 } from "../../libraries/standards/L2StandardERC20.sol";
import { IWETH9 } from "../../libraries/standards/IWETH9.sol";

/**
 * @title OVM_ETH
 * @dev The ETH predeploy provides an ERC20 interface for ETH deposited to Layer 2. Note that
 * unlike on Layer 1, Layer 2 accounts do not have a balance field.
 *
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_ETH is L2StandardERC20, IWETH9 {

    /***************
     * Constructor *
     ***************/

    constructor()
        L2StandardERC20(
            Lib_PredeployAddresses.L2_STANDARD_BRIDGE,
            address(0),
            "Ether",
            "ETH"
        )
    {}


    /******************************
     * Custom WETH9 Functionality *
     ******************************/
    fallback() external payable {
        deposit();
    }

    /**
     * Implements the WETH9 deposit() function as a no-op.
     * WARNING: this function does NOT have to do with cross-chain asset bridging. The relevant
     * deposit and withdraw functions for that use case can be found at L2StandardBridge.sol.
     * This function allows developers to treat OVM_ETH as WETH without any modifications to their
     * code.
     */
    function deposit()
        public
        payable
        override
    {
        // Calling deposit() with nonzero value will send the ETH to this contract address.
        // Once received here, we transfer it back by sending to the msg.sender.
        _transfer(address(this), msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * Implements the WETH9 withdraw() function as a no-op.
     * WARNING: this function does NOT have to do with cross-chain asset bridging. The relevant
     * deposit and withdraw functions for that use case can be found at L2StandardBridge.sol.
     * This function allows developers to treat OVM_ETH as WETH without any modifications to their
     * code.
     * @param _wad Amount being withdrawn
     */
    function withdraw(
        uint256 _wad
    )
        external
        override
    {
        // Calling withdraw() with value exceeding the withdrawer's ovmBALANCE should revert,
        // as in WETH9.
        require(balanceOf(msg.sender) >= _wad);

        // Other than emitting an event, OVM_ETH already is native ETH, so we don't need to do
        // anything else.
        emit Withdrawal(msg.sender, _wad);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./IL2StandardERC20.sol";

contract L2StandardERC20 is IL2StandardERC20, ERC20 {
    address public override l1Token;
    address public l2Bridge;

    /**
     * @param _l2Bridge Address of the L2 standard bridge.
     * @param _l1Token Address of the corresponding L1 token.
     * @param _name ERC20 name.
     * @param _symbol ERC20 symbol.
     */
    constructor(
        address _l2Bridge,
        address _l1Token,
        string memory _name,
        string memory _symbol
    )
        ERC20(_name, _symbol) {
        l1Token = _l1Token;
        l2Bridge = _l2Bridge;
    }

    modifier onlyL2Bridge {
        require(msg.sender == l2Bridge, "Only L2 Bridge can mint and burn");
        _;
    }

    function supportsInterface(bytes4 _interfaceId) public override pure returns (bool) {
        bytes4 firstSupportedInterface = bytes4(keccak256("supportsInterface(bytes4)")); // ERC165
        bytes4 secondSupportedInterface = IL2StandardERC20.l1Token.selector
            ^ IL2StandardERC20.mint.selector
            ^ IL2StandardERC20.burn.selector;
        return _interfaceId == firstSupportedInterface || _interfaceId == secondSupportedInterface;
    }

    function mint(address _to, uint256 _amount) public virtual override onlyL2Bridge {
        _mint(_to, _amount);

        emit Mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public virtual override onlyL2Bridge {
        _burn(_from, _amount);

        emit Burn(_from, _amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9. Also contains the non-ERC20 events
/// normally present in the WETH9 implementation.
interface IWETH9 is IERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
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
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
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
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
        //require(address(this).balance >= amount, "Address: insufficient balance");

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
        //require(address(this).balance >= value, "Address: insufficient balance for call");
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

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_L1StandardBridge } from "../../../iOVM/bridge/tokens/iOVM_L1StandardBridge.sol";
import { iOVM_L1ERC20Bridge } from "../../../iOVM/bridge/tokens/iOVM_L1ERC20Bridge.sol";
import { iOVM_L2ERC20Bridge } from "../../../iOVM/bridge/tokens/iOVM_L2ERC20Bridge.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Library Imports */
import { OVM_CrossDomainEnabled } from "../../../libraries/bridge/OVM_CrossDomainEnabled.sol";
import { Lib_PredeployAddresses } from "../../../libraries/constants/Lib_PredeployAddresses.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title OVM_L1StandardBridge
 * @dev The L1 ETH and ERC20 Bridge is a contract which stores deposited L1 funds and standard
 * tokens that are in use on L2. It synchronizes a corresponding L2 Bridge, informing it of deposits
 * and listening to it for newly finalized withdrawals.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_L1StandardBridge is iOVM_L1StandardBridge, OVM_CrossDomainEnabled {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /********************************
     * External Contract References *
     ********************************/

    address public l2TokenBridge;

    // Maps L1 token to L2 token to balance of the L1 token deposited
    mapping(address => mapping (address => uint256)) public deposits;

    /***************
     * Constructor *
     ***************/

    // This contract lives behind a proxy, so the constructor parameters will go unused.
    constructor()
        OVM_CrossDomainEnabled(address(0))
    {}

    /******************
     * Initialization *
     ******************/

    /**
     * @param _l1messenger L1 Messenger address being used for cross-chain communications.
     * @param _l2TokenBridge L2 standard bridge address.
     */
    function initialize(
        address _l1messenger,
        address _l2TokenBridge
    )
        public
    {
        require(messenger == address(0), "Contract has already been initialized.");
        messenger = _l1messenger;
        l2TokenBridge = _l2TokenBridge;
    }

    /**************
     * Depositing *
     **************/

    /** @dev Modifier requiring sender to be EOA.  This check could be bypassed by a malicious
     *  contract via initcode, but it takes care of the user error we want to avoid.
     */
    modifier onlyEOA() {
        // Used to stop deposits from contracts (avoid accidentally lost tokens)
        require(!Address.isContract(msg.sender), "Account not EOA");
        _;
    }

    /**
     * @dev This function can be called with no data
     * to deposit an amount of ETH to the caller's balance on L2.
     * Since the receive function doesn't take data, a conservative
     * default amount is forwarded to L2.
     */
    receive()
        external
        payable
        onlyEOA()
    {
        _initiateETHDeposit(
            msg.sender,
            msg.sender,
            1_300_000,
            bytes("")
        );
    }

    /**
     * @inheritdoc iOVM_L1StandardBridge
     */
    function depositETH(
        uint32 _l2Gas,
        bytes calldata _data
    )
        external
        override
        payable
        onlyEOA()
    {
        _initiateETHDeposit(
            msg.sender,
            msg.sender,
            _l2Gas,
            _data
        );
    }

    /**
     * @inheritdoc iOVM_L1StandardBridge
     */
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external
        override
        payable
    {
        _initiateETHDeposit(
            msg.sender,
            _to,
            _l2Gas,
            _data
        );
    }

    /**
     * @dev Performs the logic for deposits by storing the ETH and informing the L2 ETH Gateway of
     * the deposit.
     * @param _from Account to pull the deposit from on L1.
     * @param _to Account to give the deposit to on L2.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function _initiateETHDeposit(
        address _from,
        address _to,
        uint32 _l2Gas,
        bytes memory _data
    )
        internal
    {
        // Construct calldata for finalizeDeposit call
        bytes memory message =
            abi.encodeWithSelector(
                iOVM_L2ERC20Bridge.finalizeDeposit.selector,
                address(0),
                Lib_PredeployAddresses.OVM_ETH,
                _from,
                _to,
                msg.value,
                _data
            );

        // Send calldata into L2
        sendCrossDomainMessage(
            l2TokenBridge,
            _l2Gas,
            message
        );

        emit ETHDepositInitiated(_from, _to, msg.value, _data);
    }

    /**
     * @inheritdoc iOVM_L1ERC20Bridge
     */
    function depositERC20(
        address _l1Token,
        address _l2Token,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external
        override
        virtual
        onlyEOA()
    {
        _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, msg.sender, _amount, _l2Gas, _data);
    }

     /**
     * @inheritdoc iOVM_L1ERC20Bridge
     */
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external
        override
        virtual
    {
        _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, _to, _amount, _l2Gas, _data);
    }

    /**
     * @dev Performs the logic for deposits by informing the L2 Deposited Token
     * contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
     *
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _from Account to pull the deposit from on L1
     * @param _to Account to give the deposit to on L2
     * @param _amount Amount of the ERC20 to deposit.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function _initiateERC20Deposit(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    )
        internal
    {
        // When a deposit is initiated on L1, the L1 Bridge transfers the funds to itself for future
        // withdrawals. safeTransferFrom also checks if the contract has code, so this will fail if
        // _from is an EOA or address(0).
        IERC20(_l1Token).safeTransferFrom(
            _from,
            address(this),
            _amount
        );

        // Construct calldata for _l2Token.finalizeDeposit(_to, _amount)
        bytes memory message = abi.encodeWithSelector(
            iOVM_L2ERC20Bridge.finalizeDeposit.selector,
            _l1Token,
            _l2Token,
            _from,
            _to,
            _amount,
            _data
        );

        // Send calldata into L2
        sendCrossDomainMessage(
            l2TokenBridge,
            _l2Gas,
            message
        );

        deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token].add(_amount);

        emit ERC20DepositInitiated(_l1Token, _l2Token, _from, _to, _amount, _data);
    }

    /*************************
     * Cross-chain Functions *
     *************************/

     /**
     * @inheritdoc iOVM_L1StandardBridge
     */
    function finalizeETHWithdrawal(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    )
        external
        override
        onlyFromCrossDomainAccount(l2TokenBridge)
    {
        (bool success, ) = _to.call{value: _amount}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");

        emit ETHWithdrawalFinalized(_from, _to, _amount, _data);
    }

    /**
     * @inheritdoc iOVM_L1ERC20Bridge
     */
    function finalizeERC20Withdrawal(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    )
        external
        override
        onlyFromCrossDomainAccount(l2TokenBridge)
    {
        deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token].sub(_amount);

        // When a withdrawal is finalized on L1, the L1 Bridge transfers the funds to the withdrawer
        IERC20(_l1Token).safeTransfer(_to, _amount);

        emit ERC20WithdrawalFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
    }

    /*****************************
     * Temporary - Migrating ETH *
     *****************************/

    /**
     * @dev Adds ETH balance to the account. This is meant to allow for ETH
     * to be migrated from an old gateway to a new gateway.
     * NOTE: This is left for one upgrade only so we are able to receive the migrated ETH from the
     * old contract
     */
    function donateETH() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_ECDSAContractAccount } from "../../iOVM/predeploys/iOVM_ECDSAContractAccount.sol";

/* Library Imports */
import { Lib_EIP155Tx } from "../../libraries/codec/Lib_EIP155Tx.sol";
import { Lib_ExecutionManagerWrapper } from
    "../../libraries/wrappers/Lib_ExecutionManagerWrapper.sol";
import { Lib_PredeployAddresses } from "../../libraries/constants/Lib_PredeployAddresses.sol";

/* Contract Imports */
import { OVM_ETH } from "../predeploys/OVM_ETH.sol";

/* External Imports */
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";

/**
 * @title OVM_ECDSAContractAccount
 * @dev The ECDSA Contract Account can be used as the implementation for a ProxyEOA deployed by the
 * ovmCREATEEOA operation. It enables backwards compatibility with Ethereum's Layer 1, by
 * providing EIP155 formatted transaction encodings.
 *
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_ECDSAContractAccount is iOVM_ECDSAContractAccount {

    /*************
     * Libraries *
     *************/

    using Lib_EIP155Tx for Lib_EIP155Tx.EIP155Tx;


    /*************
     * Constants *
     *************/

    // TODO: should be the amount sufficient to cover the gas costs of all of the transactions up
    // to and including the CALL/CREATE which forms the entrypoint of the transaction.
    uint256 constant EXECUTION_VALIDATION_GAS_OVERHEAD = 25000;


    /********************
     * Public Functions *
     ********************/

    /**
     * No-op fallback mirrors behavior of calling an EOA on L1.
     */
    fallback()
        external
        payable
    {
        return;
    }

   /**
    * @dev Should return whether the signature provided is valid for the provided data
    * @param hash      Hash of the data to be signed
    * @param signature Signature byte array associated with _data
    */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    )
        public
        view
        returns (
            bytes4 magicValue
        )
    {
        return ECDSA.recover(hash, signature) == address(this) ?
            this.isValidSignature.selector :
            bytes4(0);
    }

    /**
     * Executes a signed transaction.
     * @param _transaction Signed EIP155 transaction.
     * @return Whether or not the call returned (rather than reverted).
     * @return Data returned by the call.
     */
    function execute(
        Lib_EIP155Tx.EIP155Tx memory _transaction
    )
        override
        public
        returns (
            bool,
            bytes memory
        )
    {
        // Address of this contract within the ovm (ovmADDRESS) should be the same as the
        // recovered address of the user who signed this message. This is how we manage to shim
        // account abstraction even though the user isn't a contract.
        require(
            _transaction.sender() == Lib_ExecutionManagerWrapper.ovmADDRESS(),
            "Signature provided for EOA transaction execution is invalid."
        );

        require(
            _transaction.chainId == Lib_ExecutionManagerWrapper.ovmCHAINID(),
            "Transaction signed with wrong chain ID"
        );

        // Need to make sure that the transaction nonce is right.
        require(
            _transaction.nonce == Lib_ExecutionManagerWrapper.ovmGETNONCE(),
            "Transaction nonce does not match the expected nonce."
        );

        // TEMPORARY: Disable gas checks for mainnet.
        // // Need to make sure that the gas is sufficient to execute the transaction.
        // require(
        //    gasleft() >= SafeMath.add(transaction.gasLimit, EXECUTION_VALIDATION_GAS_OVERHEAD),
        //    "Gas is not sufficient to execute the transaction."
        // );

        // Transfer fee to relayer.
        require(
            OVM_ETH(Lib_PredeployAddresses.OVM_ETH).transfer(
                Lib_PredeployAddresses.SEQUENCER_FEE_WALLET,
                SafeMath.mul(_transaction.gasLimit, _transaction.gasPrice)
            ),
            "Fee was not transferred to relayer."
        );

        if (_transaction.isCreate) {
            // TEMPORARY: Disable value transfer for contract creations.
            require(
                _transaction.value == 0,
                "Value transfer in contract creation not supported."
            );

            (address created, bytes memory revertdata) = Lib_ExecutionManagerWrapper.ovmCREATE(
                _transaction.data
            );

            // Return true if the contract creation succeeded, false w/ revertdata otherwise.
            if (created != address(0)) {
                return (true, abi.encode(created));
            } else {
                return (false, revertdata);
            }
        } else {
            // We only want to bump the nonce for `ovmCALL` because `ovmCREATE` automatically bumps
            // the nonce of the calling account. Normally an EOA would bump the nonce for both
            // cases, but since this is a contract we'd end up bumping the nonce twice.
            Lib_ExecutionManagerWrapper.ovmINCREMENTNONCE();

            // NOTE: Upgrades are temporarily disabled because users can, in theory, modify their
            // EOA so that they don't have to pay any fees to the sequencer. Function will remain
            // disabled until a robust solution is in place.
            require(
                _transaction.to != Lib_ExecutionManagerWrapper.ovmADDRESS(),
                "Calls to self are disabled until upgradability is re-enabled."
            );

            return _transaction.to.call{value: _transaction.value}(_transaction.data);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_EIP155Tx } from "../../libraries/codec/Lib_EIP155Tx.sol";

/**
 * @title iOVM_ECDSAContractAccount
 */
interface iOVM_ECDSAContractAccount {

    /********************
     * Public Functions *
     ********************/

    function execute(
        Lib_EIP155Tx.EIP155Tx memory _transaction
    )
        external
        returns (
            bool,
            bytes memory
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPReader } from "../rlp/Lib_RLPReader.sol";
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";

/**
 * @title Lib_EIP155Tx
 * @dev A simple library for dealing with the transaction type defined by EIP155:
 *      https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
 */
library Lib_EIP155Tx {

    /***********
     * Structs *
     ***********/

    // Struct representing an EIP155 transaction. See EIP link above for more information.
    struct EIP155Tx {
        // These fields correspond to the actual RLP-encoded fields specified by EIP155.
        uint256 nonce;
        uint256 gasPrice;
        uint256 gasLimit;
        address to;
        uint256 value;
        bytes data;
        uint8 v;
        bytes32 r;
        bytes32 s;

        // Chain ID to associate this transaction with. Used all over the place, seemed easier to
        // set this once when we create the transaction rather than providing it as an input to
        // each function. I don't see a strong need to have a transaction with a mutable chain ID.
        uint256 chainId;

        // The ECDSA "recovery parameter," should always be 0 or 1. EIP155 specifies that:
        // `v = {0,1} + CHAIN_ID * 2 + 35`
        // Where `{0,1}` is a stand in for our `recovery_parameter`. Now computing our formula for
        // the recovery parameter:
        // 1. `v = {0,1} + CHAIN_ID * 2 + 35`
        // 2. `v = recovery_parameter + CHAIN_ID * 2 + 35`
        // 3. `v - CHAIN_ID * 2 - 35 = recovery_parameter`
        // So we're left with the final formula:
        // `recovery_parameter = v - CHAIN_ID * 2 - 35`
        // NOTE: This variable is a uint8 because `v` is inherently limited to a uint8. If we
        // didn't use a uint8, then recovery_parameter would always be a negative number for chain
        // IDs greater than 110 (`255 - 110 * 2 - 35 = 0`). So we need to wrap around to support
        // anything larger.
        uint8 recoveryParam;

        // Whether or not the transaction is a creation. Necessary because we can't make an address
        // "nil". Using the zero address creates a potential conflict if the user did actually
        // intend to send a transaction to the zero address.
        bool isCreate;
    }

    // Lets us use nicer syntax.
    using Lib_EIP155Tx for EIP155Tx;


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Decodes an EIP155 transaction and attaches a given Chain ID.
     * Transaction *must* be RLP-encoded.
     * @param _encoded RLP-encoded EIP155 transaction.
     * @param _chainId Chain ID to assocaite with this transaction.
     * @return Parsed transaction.
     */
    function decode(
        bytes memory _encoded,
        uint256 _chainId
    )
        internal
        pure
        returns (
            EIP155Tx memory
        )
    {
        Lib_RLPReader.RLPItem[] memory decoded = Lib_RLPReader.readList(_encoded);

        // Note formula above about how recoveryParam is computed.
        uint8 v = uint8(Lib_RLPReader.readUint256(decoded[6]));
        uint8 recoveryParam = uint8(v - 2 * _chainId - 35);

        // Recovery param being anything other than 0 or 1 indicates that we have the wrong chain
        // ID.
        require(
            recoveryParam < 2,
            "Lib_EIP155Tx: Transaction signed with wrong chain ID"
        );

        // Creations can be detected by looking at the byte length here.
        bool isCreate = Lib_RLPReader.readBytes(decoded[3]).length == 0;

        return EIP155Tx({
            nonce: Lib_RLPReader.readUint256(decoded[0]),
            gasPrice: Lib_RLPReader.readUint256(decoded[1]),
            gasLimit: Lib_RLPReader.readUint256(decoded[2]),
            to: Lib_RLPReader.readAddress(decoded[3]),
            value: Lib_RLPReader.readUint256(decoded[4]),
            data: Lib_RLPReader.readBytes(decoded[5]),
            v: v,
            r: Lib_RLPReader.readBytes32(decoded[7]),
            s: Lib_RLPReader.readBytes32(decoded[8]),
            chainId: _chainId,
            recoveryParam: recoveryParam,
            isCreate: isCreate
        });
    }

    /**
     * Encodes an EIP155 transaction into RLP.
     * @param _transaction EIP155 transaction to encode.
     * @param _includeSignature Whether or not to encode the signature.
     * @return RLP-encoded transaction.
     */
    function encode(
        EIP155Tx memory _transaction,
        bool _includeSignature
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes[] memory raw = new bytes[](9);

        raw[0] = Lib_RLPWriter.writeUint(_transaction.nonce);
        raw[1] = Lib_RLPWriter.writeUint(_transaction.gasPrice);
        raw[2] = Lib_RLPWriter.writeUint(_transaction.gasLimit);

        // We write the encoding of empty bytes when the transaction is a creation, *not* the zero
        // address as one might assume.
        if (_transaction.isCreate) {
            raw[3] = Lib_RLPWriter.writeBytes("");
        } else {
            raw[3] = Lib_RLPWriter.writeAddress(_transaction.to);
        }

        raw[4] = Lib_RLPWriter.writeUint(_transaction.value);
        raw[5] = Lib_RLPWriter.writeBytes(_transaction.data);

        if (_includeSignature) {
            raw[6] = Lib_RLPWriter.writeUint(_transaction.v);
            raw[7] = Lib_RLPWriter.writeBytes32(_transaction.r);
            raw[8] = Lib_RLPWriter.writeBytes32(_transaction.s);
        } else {
            // Chain ID *is* included in the unsigned transaction.
            raw[6] = Lib_RLPWriter.writeUint(_transaction.chainId);
            raw[7] = Lib_RLPWriter.writeBytes("");
            raw[8] = Lib_RLPWriter.writeBytes("");
        }

        return Lib_RLPWriter.writeList(raw);
    }

    /**
     * Computes the hash of an EIP155 transaction. Assumes that you don't want to include the
     * signature in this hash because that's a very uncommon usecase. If you really want to include
     * the signature, just encode with the signature and take the hash yourself.
     */
    function hash(
        EIP155Tx memory _transaction
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(
            _transaction.encode(false)
        );
    }

    /**
     * Computes the sender of an EIP155 transaction.
     * @param _transaction EIP155 transaction to get a sender for.
     * @return Address corresponding to the private key that signed this transaction.
     */
    function sender(
        EIP155Tx memory _transaction
    )
        internal
        pure
        returns (
            address
        )
    {
        return ecrecover(
            _transaction.hash(),
            _transaction.recoveryParam + 27,
            _transaction.r,
            _transaction.s
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_ErrorUtils } from "../utils/Lib_ErrorUtils.sol";
import { Lib_PredeployAddresses } from "../constants/Lib_PredeployAddresses.sol";

/**
 * @title Lib_ExecutionManagerWrapper
 * @dev This library acts as a utility for easily calling the OVM_ExecutionManagerWrapper, the
 *  predeployed contract which exposes the `kall` builtin. Effectively, this contract allows the
 *  user to trigger OVM opcodes by directly calling the OVM_ExecutionManger.
 *
 * Compiler used: solc
 * Runtime target: OVM
 */
library Lib_ExecutionManagerWrapper {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Performs a safe ovmCREATE call.
     * @param _bytecode Code for the new contract.
     * @return Address of the created contract.
     */
    function ovmCREATE(
        bytes memory _bytecode
    )
        internal
        returns (
            address,
            bytes memory
        )
    {
        bytes memory returndata = _callWrapperContract(
            abi.encodeWithSignature(
                "ovmCREATE(bytes)",
                _bytecode
            )
        );

        return abi.decode(returndata, (address, bytes));
    }

    /**
     * Performs a safe ovmGETNONCE call.
     * @return Result of calling ovmGETNONCE.
     */
    function ovmGETNONCE()
        internal
        returns (
            uint256
        )
    {
        bytes memory returndata = _callWrapperContract(
            abi.encodeWithSignature(
                "ovmGETNONCE()"
            )
        );

        return abi.decode(returndata, (uint256));
    }

    /**
     * Performs a safe ovmINCREMENTNONCE call.
     */
    function ovmINCREMENTNONCE()
        internal
    {
        _callWrapperContract(
            abi.encodeWithSignature(
                "ovmINCREMENTNONCE()"
            )
        );
    }

    /**
     * Performs a safe ovmCREATEEOA call.
     * @param _messageHash Message hash which was signed by EOA
     * @param _v v value of signature (0 or 1)
     * @param _r r value of signature
     * @param _s s value of signature
     */
    function ovmCREATEEOA(
        bytes32 _messageHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
    {
        _callWrapperContract(
            abi.encodeWithSignature(
                "ovmCREATEEOA(bytes32,uint8,bytes32,bytes32)",
                _messageHash,
                _v,
                _r,
                _s
            )
        );
    }

    /**
     * Calls the ovmL1TXORIGIN opcode.
     * @return Address that sent this message from L1.
     */
    function ovmL1TXORIGIN()
        internal
        returns (
            address
        )
    {
        bytes memory returndata = _callWrapperContract(
            abi.encodeWithSignature(
                "ovmL1TXORIGIN()"
            )
        );

        return abi.decode(returndata, (address));
    }

    /**
     * Calls the ovmCHAINID opcode.
     * @return Chain ID of the current network.
     */
    function ovmCHAINID()
        internal
        returns (
            uint256
        )
    {
        bytes memory returndata = _callWrapperContract(
            abi.encodeWithSignature(
                "ovmCHAINID()"
            )
        );

        return abi.decode(returndata, (uint256));
    }

    /**
     * Performs a safe ovmADDRESS call.
     * @return Result of calling ovmADDRESS.
     */
    function ovmADDRESS()
        internal
        returns (
            address
        )
    {
        bytes memory returndata = _callWrapperContract(
            abi.encodeWithSignature(
                "ovmADDRESS()"
            )
        );

        return abi.decode(returndata, (address));
    }

    /**
     * Calls the value-enabled ovmCALL opcode.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _address Address of the contract to call.
     * @param _value ETH value to pass with the call.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function ovmCALL(
        uint256 _gasLimit,
        address _address,
        uint256 _value,
        bytes memory _calldata
    )
        internal
        returns (
            bool,
            bytes memory
        )
    {
        bytes memory returndata = _callWrapperContract(
            abi.encodeWithSignature(
                "ovmCALL(uint256,address,uint256,bytes)",
                _gasLimit,
                _address,
                _value,
                _calldata
            )
        );

        return abi.decode(returndata, (bool, bytes));
    }

    /**
     * Calls the ovmBALANCE opcode.
     * @param _address OVM account to query the balance of.
     * @return Balance of the account.
     */
    function ovmBALANCE(
        address _address
    )
        internal
        returns (
            uint256
        )
    {
        bytes memory returndata = _callWrapperContract(
            abi.encodeWithSignature(
                "ovmBALANCE(address)",
                _address
            )
        );

        return abi.decode(returndata, (uint256));
    }

    /**
     * Calls the ovmCALLVALUE opcode.
     * @return Value of the current call frame.
     */
    function ovmCALLVALUE()
        internal
        returns (
            uint256
        )
    {
        bytes memory returndata = _callWrapperContract(
            abi.encodeWithSignature(
                "ovmCALLVALUE()"
            )
        );

        return abi.decode(returndata, (uint256));
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Performs an ovm interaction and the necessary safety checks.
     * @param _calldata Data to send to the OVM_ExecutionManager (encoded with sighash).
     * @return Data sent back by the OVM_ExecutionManager.
     */
    function _callWrapperContract(
        bytes memory _calldata
    )
        private
        returns (
            bytes memory
        )
    {
        (bool success, bytes memory returndata) =
            Lib_PredeployAddresses.EXECUTION_MANAGER_WRAPPER.delegatecall(_calldata);

        if (success == true) {
            return returndata;
        } else {
            assembly {
                revert(add(returndata, 0x20), mload(returndata))
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_RLPReader
 * @dev Adapted from "RLPReader" by Hamdi Allam ([email protected]).
 */
library Lib_RLPReader {

    /*************
     * Constants *
     *************/

    uint256 constant internal MAX_LIST_LENGTH = 32;


    /*********
     * Enums *
     *********/

    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }


    /***********
     * Structs *
     ***********/

    struct RLPItem {
        uint256 length;
        uint256 ptr;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts bytes to a reference to memory position and length.
     * @param _in Input bytes to convert.
     * @return Output memory reference.
     */
    function toRLPItem(
        bytes memory _in
    )
        internal
        pure
        returns (
            RLPItem memory
        )
    {
        uint256 ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({
            length: _in.length,
            ptr: ptr
        });
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            RLPItem[] memory
        )
    {
        (
            uint256 listOffset,
            ,
            RLPItemType itemType
        ) = _decodeLength(_in);

        require(
            itemType == RLPItemType.LIST_ITEM,
            "Invalid RLP list value."
        );

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            require(
                itemCount < MAX_LIST_LENGTH,
                "Provided RLP list exceeds max list length."
            );

            (
                uint256 itemOffset,
                uint256 itemLength,
            ) = _decodeLength(RLPItem({
                length: _in.length - offset,
                ptr: _in.ptr + offset
            }));

            out[itemCount] = RLPItem({
                length: itemLength + itemOffset,
                ptr: _in.ptr + offset
            });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(
        bytes memory _in
    )
        internal
        pure
        returns (
            RLPItem[] memory
        )
    {
        return readList(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        (
            uint256 itemOffset,
            uint256 itemLength,
            RLPItemType itemType
        ) = _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "Invalid RLP bytes value."
        );

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return readBytes(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            string memory
        )
    {
        return string(readBytes(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(
        bytes memory _in
    )
        internal
        pure
        returns (
            string memory
        )
    {
        return readString(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        require(
            _in.length <= 33,
            "Invalid RLP bytes32 value."
        );

        (
            uint256 itemOffset,
            uint256 itemLength,
            RLPItemType itemType
        ) = _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "Invalid RLP bytes32 value."
        );

        uint256 ptr = _in.ptr + itemOffset;
        bytes32 out;
        assembly {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) {
                out := div(out, exp(256, sub(32, itemLength)))
            }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return readBytes32(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            uint256
        )
    {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(
        bytes memory _in
    )
        internal
        pure
        returns (
            uint256
        )
    {
        return readUint256(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bool
        )
    {
        require(
            _in.length == 1,
            "Invalid RLP boolean value."
        );

        uint256 ptr = _in.ptr;
        uint256 out;
        assembly {
            out := byte(0, mload(ptr))
        }

        require(
            out == 0 || out == 1,
            "Lib_RLPReader: Invalid RLP boolean value, must be 0 or 1"
        );

        return out != 0;
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(
        bytes memory _in
    )
        internal
        pure
        returns (
            bool
        )
    {
        return readBool(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            address
        )
    {
        if (_in.length == 1) {
            return address(0);
        }

        require(
            _in.length == 21,
            "Invalid RLP address value."
        );

        return address(readUint256(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(
        bytes memory _in
    )
        internal
        pure
        returns (
            address
        )
    {
        return readAddress(
            toRLPItem(_in)
        );
    }

    /**
     * Reads the raw bytes of an RLP item.
     * @param _in RLP item to read.
     * @return Raw RLP bytes.
     */
    function readRawBytes(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return _copy(_in);
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Decodes the length of an RLP item.
     * @param _in RLP item to decode.
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(
        RLPItem memory _in
    )
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        require(
            _in.length > 0,
            "RLP item cannot be null."
        );

        uint256 ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.

            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            uint256 strLen = prefix - 0x80;

            require(
                _in.length > strLen,
                "Invalid RLP short string."
            );

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(
                _in.length > lenOfStrLen,
                "Invalid RLP long string length."
            );

            uint256 strLen;
            assembly {
                // Pick out the string length.
                strLen := div(
                    mload(add(ptr, 1)),
                    exp(256, sub(32, lenOfStrLen))
                )
            }

            require(
                _in.length > lenOfStrLen + strLen,
                "Invalid RLP long string."
            );

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            uint256 listLen = prefix - 0xc0;

            require(
                _in.length > listLen,
                "Invalid RLP short list."
            );

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(
                _in.length > lenOfListLen,
                "Invalid RLP long list length."
            );

            uint256 listLen;
            assembly {
                // Pick out the list length.
                listLen := div(
                    mload(add(ptr, 1)),
                    exp(256, sub(32, lenOfListLen))
                )
            }

            require(
                _in.length > lenOfListLen + listLen,
                "Invalid RLP long list."
            );

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * Copies the bytes from a memory location.
     * @param _src Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Copied bytes.
     */
    function _copy(
        uint256 _src,
        uint256 _offset,
        uint256 _length
    )
        private
        pure
        returns (
            bytes memory
        )
    {
        bytes memory out = new bytes(_length);
        if (out.length == 0) {
            return out;
        }

        uint256 src = _src + _offset;
        uint256 dest;
        assembly {
            dest := add(out, 32)
        }

        // Copy over as many complete words as we can.
        for (uint256 i = 0; i < _length / 32; i++) {
            assembly {
                mstore(dest, mload(src))
            }

            src += 32;
            dest += 32;
        }

        // Pick out the remaining bytes.
        uint256 mask = 256 ** (32 - (_length % 32)) - 1;
        assembly {
            mstore(
                dest,
                or(
                    and(mload(src), not(mask)),
                    and(mload(dest), mask)
                )
            )
        }

        return out;
    }

    /**
     * Copies an RLP item into bytes.
     * @param _in RLP item to copy.
     * @return Copied bytes.
     */
    function _copy(
        RLPItem memory _in
    )
        private
        pure
        returns (
            bytes memory
        )
    {
        return _copy(_in.ptr, 0, _in.length);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Lib_RLPWriter
 * @author Bakaoh (with modifications)
 */
library Lib_RLPWriter {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * RLP encodes a byte string.
     * @param _in The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * RLP encodes a list of RLP encoded byte byte strings.
     * @param _in The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(
        bytes[] memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * RLP encodes a string.
     * @param _in The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeString(
        string memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return writeBytes(bytes(_in));
    }

    /**
     * RLP encodes an address.
     * @param _in The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(
        address _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a bytes32 value.
     * @param _in The bytes32 to encode.
     * @return _out The RLP encoded bytes32 in bytes.
     */
    function writeBytes32(
        bytes32 _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a uint.
     * @param _in The uint256 to encode.
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(
        uint256 _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return writeBytes(_toBinary(_in));
    }

    /**
     * RLP encodes a bool.
     * @param _in The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(
        bool _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param _len The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function _writeLength(
        uint256 _len,
        uint256 _offset
    )
        private
        pure
        returns (
            bytes memory
        )
    {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = byte(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = byte(uint8(lenLen) + uint8(_offset) + 55);
            for(i = 1; i <= lenLen; i++) {
                encoded[i] = byte(uint8((_len / (256**(lenLen-i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function _toBinary(
        uint256 _x
    )
        private
        pure
        returns (
            bytes memory
        )
    {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    )
        private
        pure
    {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function _flatten(
        bytes[] memory _list
    )
        private
        pure
        returns (
            bytes memory
        )
    {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly { flattenedPtr := add(flattened, 0x20) }

        for(i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly { listPtr := add(item, 0x20)}

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Lib_ErrorUtils
 */
library Lib_ErrorUtils {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Encodes an error string into raw solidity-style revert data.
     * (i.e. ascii bytes, prefixed with bytes4(keccak("Error(string))"))
     * Ref: https://docs.soliditylang.org/en/v0.8.2/control-structures.html?highlight=Error(string)
     * #panic-via-assert-and-error-via-require
     * @param _reason Reason for the reversion.
     * @return Standard solidity revert data for the given reason.
     */
    function encodeRevertString(
        string memory _reason
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return abi.encodeWithSignature(
            "Error(string)",
            _reason
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_Bytes32Utils } from "../../libraries/utils/Lib_Bytes32Utils.sol";
import { Lib_PredeployAddresses } from "../../libraries/constants/Lib_PredeployAddresses.sol";
import { Lib_ExecutionManagerWrapper } from
    "../../libraries/wrappers/Lib_ExecutionManagerWrapper.sol";

/**
 * @title OVM_ProxyEOA
 * @dev The Proxy EOA contract uses a delegate call to execute the logic in an implementation
 * contract. In combination with the logic implemented in the ECDSA Contract Account, this enables
 * a form of upgradable 'account abstraction' on layer 2.
 *
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_ProxyEOA {

    /**********
     * Events *
     **********/

    event Upgraded(
        address indexed implementation
    );


    /*************
     * Constants *
     *************/
    // solhint-disable-next-line max-line-length
    bytes32 constant IMPLEMENTATION_KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; //bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);

    /*********************
     * Fallback Function *
     *********************/

    fallback()
        external
        payable
    {
        (bool success, bytes memory returndata) = getImplementation().delegatecall(msg.data);

        if (success) {
            assembly {
                return(add(returndata, 0x20), mload(returndata))
            }
        } else {
            assembly {
                revert(add(returndata, 0x20), mload(returndata))
            }
        }
    }

    // WARNING: We use the deployed bytecode of this contract as a template to create ProxyEOA
    // contracts. As a result, we must *not* perform any constructor logic. Use initialization
    // functions if necessary.


    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the implementation address.
     * @param _implementation New implementation address.
     */
    function upgrade(
        address _implementation
    )
        external
    {
        require(
            msg.sender == Lib_ExecutionManagerWrapper.ovmADDRESS(),
            "EOAs can only upgrade their own EOA implementation."
        );

        _setImplementation(_implementation);
        emit Upgraded(_implementation);
    }

    /**
     * Gets the address of the current implementation.
     * @return Current implementation address.
     */
    function getImplementation()
        public
        view
        returns (
            address
        )
    {
        bytes32 addr32;
        assembly {
            addr32 := sload(IMPLEMENTATION_KEY)
        }

        address implementation = Lib_Bytes32Utils.toAddress(addr32);
        if (implementation == address(0)) {
            return Lib_PredeployAddresses.ECDSA_CONTRACT_ACCOUNT;
        } else {
            return implementation;
        }
    }


    /**********************
     * Internal Functions *
     **********************/

    function _setImplementation(
        address _implementation
    )
        internal
    {
        bytes32 addr32 = Lib_Bytes32Utils.fromAddress(_implementation);
        assembly {
            sstore(IMPLEMENTATION_KEY, addr32)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_Byte32Utils
 */
library Lib_Bytes32Utils {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts a bytes32 value to a boolean. Anything non-zero will be converted to "true."
     * @param _in Input bytes32 value.
     * @return Bytes32 as a boolean.
     */
    function toBool(
        bytes32 _in
    )
        internal
        pure
        returns (
            bool
        )
    {
        return _in != 0;
    }

    /**
     * Converts a boolean to a bytes32 value.
     * @param _in Input boolean value.
     * @return Boolean as a bytes32.
     */
    function fromBool(
        bool _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return bytes32(uint256(_in ? 1 : 0));
    }

    /**
     * Converts a bytes32 value to an address. Takes the *last* 20 bytes.
     * @param _in Input bytes32 value.
     * @return Bytes32 as an address.
     */
    function toAddress(
        bytes32 _in
    )
        internal
        pure
        returns (
            address
        )
    {
        return address(uint160(uint256(_in)));
    }

    /**
     * Converts an address to a bytes32.
     * @param _in Input address value.
     * @return Address as a bytes32.
     */
    function fromAddress(
        address _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return bytes32(uint256(_in));
    }

    /**
     * Removes the leading zeros from a bytes32 value and returns a new (smaller) bytes value.
     * @param _in Input bytes32 value.
     * @return Bytes32 without any leading zeros.
     */
    function removeLeadingZeros(
        bytes32 _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes memory out;

        assembly {
            // Figure out how many leading zero bytes to remove.
            let shift := 0
            for { let i := 0 } and(lt(i, 32), eq(byte(i, _in), 0)) { i := add(i, 1) } {
                shift := add(shift, 1)
            }

            // Reserve some space for our output and fix the free memory pointer.
            out := mload(0x40)
            mstore(0x40, add(out, 0x40))

            // Shift the value and store it into the output bytes.
            mstore(add(out, 0x20), shl(mul(shift, 8), _in))

            // Store the new size (with leading zero bytes removed) in the output byte size.
            mstore(out, sub(32, shift))
        }

        return out;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_EIP155Tx } from "../../libraries/codec/Lib_EIP155Tx.sol";
import { Lib_ExecutionManagerWrapper } from
    "../../libraries/wrappers/Lib_ExecutionManagerWrapper.sol";
import { iOVM_ECDSAContractAccount } from "../../iOVM/predeploys/iOVM_ECDSAContractAccount.sol";

/**
 * @title OVM_SequencerEntrypoint
 * @dev The Sequencer Entrypoint is a predeploy which, despite its name, can in fact be called by
 * any account. It accepts a more efficient compressed calldata format, which it decompresses and
 * encodes to the standard EIP155 transaction format.
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_SequencerEntrypoint {

    /*************
     * Libraries *
     *************/

    using Lib_EIP155Tx for Lib_EIP155Tx.EIP155Tx;


    /*********************
     * Fallback Function *
     *********************/

    /**
     * Expects an RLP-encoded EIP155 transaction as input. See the EIP for a more detailed
     * description of this transaction format:
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
     */
    fallback()
        external
    {
        // We use this twice, so it's more gas efficient to store a copy of it (barely).
        bytes memory encodedTx = msg.data;

        // Decode the tx with the correct chain ID.
        Lib_EIP155Tx.EIP155Tx memory transaction = Lib_EIP155Tx.decode(
            encodedTx,
            Lib_ExecutionManagerWrapper.ovmCHAINID()
        );

        // Value is computed on the fly. Keep it in the stack to save some gas.
        address target = transaction.sender();

        bool isEmptyContract;
        assembly {
            isEmptyContract := iszero(extcodesize(target))
        }

        // If the account is empty, deploy the default EOA to that address.
        if (isEmptyContract) {
            Lib_ExecutionManagerWrapper.ovmCREATEEOA(
                transaction.hash(),
                transaction.recoveryParam,
                transaction.r,
                transaction.s
            );
        }

        // Forward the transaction over to the EOA.
        (bool success, bytes memory returndata) = target.call(
            abi.encodeWithSelector(iOVM_ECDSAContractAccount.execute.selector, transaction)
        );

        if (success) {
            assembly {
                return(add(returndata, 0x20), mload(returndata))
            }
        } else {
            assembly {
                revert(add(returndata, 0x20), mload(returndata))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_EIP155Tx } from "../../optimistic-ethereum/libraries/codec/Lib_EIP155Tx.sol";

/**
 * @title TestLib_EIP155Tx
 */
contract TestLib_EIP155Tx {
    function decode(
        bytes memory _encoded,
        uint256 _chainId
    )
        public
        pure
        returns (
            Lib_EIP155Tx.EIP155Tx memory
        )
    {
        return Lib_EIP155Tx.decode(
            _encoded,
            _chainId
        );
    }

    function encode(
        Lib_EIP155Tx.EIP155Tx memory _transaction,
        bool _includeSignature
    )
        public
        pure
        returns (
            bytes memory
        )
    {
        return Lib_EIP155Tx.encode(
            _transaction,
            _includeSignature
        );
    }

    function hash(
        Lib_EIP155Tx.EIP155Tx memory _transaction
    )
        public
        pure
        returns (
            bytes32
        )
    {
        return Lib_EIP155Tx.hash(
            _transaction
        );
    }

    function sender(
        Lib_EIP155Tx.EIP155Tx memory _transaction
    )
        public
        pure
        returns (
            address
        )
    {
        return Lib_EIP155Tx.sender(
            _transaction
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPWriter } from "../../optimistic-ethereum/libraries/rlp/Lib_RLPWriter.sol";
import { TestERC20 } from "../../test-helpers/TestERC20.sol";

/**
 * @title TestLib_RLPWriter
 */
contract TestLib_RLPWriter {

    function writeBytes(
        bytes memory _in
    )
        public
        pure
        returns (
            bytes memory _out
        )
    {
        return Lib_RLPWriter.writeBytes(_in);
    }

    function writeList(
        bytes[] memory _in
    )
        public
        pure
        returns (
            bytes memory _out
        )
    {
        return Lib_RLPWriter.writeList(_in);
    }

    function writeString(
        string memory _in
    )
        public
        pure
        returns (
            bytes memory _out
        )
    {
        return Lib_RLPWriter.writeString(_in);
    }

    function writeAddress(
        address _in
    )
        public
        pure
        returns (
            bytes memory _out
        )
    {
        return Lib_RLPWriter.writeAddress(_in);
    }

    function writeUint(
        uint256 _in
    )
        public
        pure
        returns (
            bytes memory _out
        )
    {
        return Lib_RLPWriter.writeUint(_in);
    }

    function writeBool(
        bool _in
    )
        public
        pure
        returns (
            bytes memory _out
        )
    {
        return Lib_RLPWriter.writeBool(_in);
    }

    function writeAddressWithTaintedMemory(
        address _in
    )
        public
        returns (
            bytes memory _out
        )
    {
        new TestERC20();
        return Lib_RLPWriter.writeAddress(_in);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

// a test ERC20 token with an open mint function
contract TestERC20 {
    using SafeMath for uint;

    string public constant name = 'Test';
    string public constant symbol = 'TST';
    uint8 public constant decimals = 18;
    uint256  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {}

    function mint(address to, uint256 value) public {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_BytesUtils } from "../../optimistic-ethereum/libraries/utils/Lib_BytesUtils.sol";
import { TestERC20 } from "../../test-helpers/TestERC20.sol";

/**
 * @title TestLib_BytesUtils
 */
contract TestLib_BytesUtils {

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _preBytes,
            _postBytes
        );
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        public
        pure
        returns (bytes memory)
    {
        return Lib_BytesUtils.slice(
            _bytes,
            _start,
            _length
        );
    }

    function toBytes32(
        bytes memory _bytes
    )
        public
        pure
        returns (bytes32)
    {
        return Lib_BytesUtils.toBytes32(
            _bytes
        );
    }

    function toUint256(
        bytes memory _bytes
    )
        public
        pure
        returns (uint256)
    {
        return Lib_BytesUtils.toUint256(
            _bytes
        );
    }

    function toNibbles(
        bytes memory _bytes
    )
        public
        pure
        returns (bytes memory)
    {
        return Lib_BytesUtils.toNibbles(
            _bytes
        );
    }

    function fromNibbles(
        bytes memory _bytes
    )
        public
        pure
        returns (bytes memory)
    {
        return Lib_BytesUtils.fromNibbles(
            _bytes
        );
    }

    function equal(
        bytes memory _bytes,
        bytes memory _other
    )
        public
        pure
        returns (bool)
    {
        return Lib_BytesUtils.equal(
            _bytes,
            _other
        );
    }

    function sliceWithTaintedMemory(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        public
        returns (bytes memory)
    {
        new TestERC20();
        return Lib_BytesUtils.slice(
            _bytes,
            _start,
            _length
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_BytesUtils
 */
library Lib_BytesUtils {

    /**********************
     * Internal Functions *
     **********************/

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        if (_start >= _bytes.length) {
            return bytes("");
        }

        return slice(_bytes, _start, _bytes.length - _start);
    }

    function toBytes32PadLeft(
        bytes memory _bytes
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        bytes32 ret;
        uint256 len = _bytes.length <= 32 ? _bytes.length : 32;
        assembly {
            ret := shr(mul(sub(32, len), 8), mload(add(_bytes, 32)))
        }
        return ret;
    }

    function toBytes32(
        bytes memory _bytes
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        if (_bytes.length < 32) {
            bytes32 ret;
            assembly {
                ret := mload(add(_bytes, 32))
            }
            return ret;
        }

        return abi.decode(_bytes,(bytes32)); // will truncate if input length > 32 bytes
    }

    function toUint256(
        bytes memory _bytes
    )
        internal
        pure
        returns (
            uint256
        )
    {
        return uint256(toBytes32(_bytes));
    }

    function toUint24(
        bytes memory _bytes,
        uint256 _start
    )
        internal
        pure
        returns (
            uint24
        )
    {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3 , "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint8(
        bytes memory _bytes,
        uint256 _start
    )
        internal
        pure
        returns (
            uint8
        )
    {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toAddress(
        bytes memory _bytes,
        uint256 _start
    )
        internal
        pure
        returns (
            address
        )
    {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toNibbles(
        bytes memory _bytes
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes memory nibbles = new bytes(_bytes.length * 2);

        for (uint256 i = 0; i < _bytes.length; i++) {
            nibbles[i * 2] = _bytes[i] >> 4;
            nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
        }

        return nibbles;
    }

    function fromNibbles(
        bytes memory _bytes
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes memory ret = new bytes(_bytes.length / 2);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = (_bytes[i * 2] << 4) | (_bytes[i * 2 + 1]);
        }

        return ret;
    }

    function equal(
        bytes memory _bytes,
        bytes memory _other
    )
        internal
        pure
        returns (
            bool
        )
    {
        return keccak256(_bytes) == keccak256(_other);
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_EthUtils } from "../../libraries/utils/Lib_EthUtils.sol";
import { Lib_Bytes32Utils } from "../../libraries/utils/Lib_Bytes32Utils.sol";
import { Lib_BytesUtils } from "../../libraries/utils/Lib_BytesUtils.sol";
import { Lib_SecureMerkleTrie } from "../../libraries/trie/Lib_SecureMerkleTrie.sol";
import { Lib_RLPWriter } from "../../libraries/rlp/Lib_RLPWriter.sol";
import { Lib_RLPReader } from "../../libraries/rlp/Lib_RLPReader.sol";

/* Interface Imports */
import { iOVM_StateTransitioner } from "../../iOVM/verification/iOVM_StateTransitioner.sol";
import { iOVM_BondManager } from "../../iOVM/verification/iOVM_BondManager.sol";
import { iOVM_ExecutionManager } from "../../iOVM/execution/iOVM_ExecutionManager.sol";
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";
import { iOVM_StateManagerFactory } from "../../iOVM/execution/iOVM_StateManagerFactory.sol";

/* Contract Imports */
import { Abs_FraudContributor } from "./Abs_FraudContributor.sol";

/**
 * @title OVM_StateTransitioner
 * @dev The State Transitioner coordinates the execution of a state transition during the evaluation
 * of a fraud proof. It feeds verified input to the Execution Manager's run(), and controls a
 * State Manager (which is uniquely created for each fraud proof).
 * Once a fraud proof has been initialized, this contract is provided with the pre-state root and
 * verifies that the OVM storage slots committed to the State Mangager are contained in that state
 * This contract controls the State Manager and Execution Manager, and uses them to calculate the
 * post-state root by applying the transaction. The Fraud Verifier can then check for fraud by
 * comparing the calculated post-state root with the proposed post-state root.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_StateTransitioner is Lib_AddressResolver, Abs_FraudContributor, iOVM_StateTransitioner
{

    /*******************
     * Data Structures *
     *******************/

    enum TransitionPhase {
        PRE_EXECUTION,
        POST_EXECUTION,
        COMPLETE
    }


    /*******************************************
     * Contract Variables: Contract References *
     *******************************************/

    iOVM_StateManager public ovmStateManager;


    /*******************************************
     * Contract Variables: Internal Accounting *
     *******************************************/

    bytes32 internal preStateRoot;
    bytes32 internal postStateRoot;
    TransitionPhase public phase;
    uint256 internal stateTransitionIndex;
    bytes32 internal transactionHash;


    /*************
     * Constants *
     *************/

    // solhint-disable-next-line max-line-length
    bytes32 internal constant EMPTY_ACCOUNT_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line max-line-length
    bytes32 internal constant EMPTY_ACCOUNT_STORAGE_ROOT = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     * @param _stateTransitionIndex Index of the state transition being verified.
     * @param _preStateRoot State root before the transition was executed.
     * @param _transactionHash Hash of the executed transaction.
     */
    constructor(
        address _libAddressManager,
        uint256 _stateTransitionIndex,
        bytes32 _preStateRoot,
        bytes32 _transactionHash
    )
        Lib_AddressResolver(_libAddressManager)
    {
        stateTransitionIndex = _stateTransitionIndex;
        preStateRoot = _preStateRoot;
        postStateRoot = _preStateRoot;
        transactionHash = _transactionHash;

        ovmStateManager = iOVM_StateManagerFactory(resolve("OVM_StateManagerFactory"))
            .create(address(this));
    }


    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Checks that a function is only run during a specific phase.
     * @param _phase Phase the function must run within.
     */
    modifier onlyDuringPhase(
        TransitionPhase _phase
    ) {
        require(
            phase == _phase,
            "Function must be called during the correct phase."
        );
        _;
    }


    /**********************************
     * Public Functions: State Access *
     **********************************/

    /**
     * Retrieves the state root before execution.
     * @return _preStateRoot State root before execution.
     */
    function getPreStateRoot()
        override
        external
        view
        returns (
            bytes32 _preStateRoot
        )
    {
        return preStateRoot;
    }

    /**
     * Retrieves the state root after execution.
     * @return _postStateRoot State root after execution.
     */
    function getPostStateRoot()
        override
        external
        view
        returns (
            bytes32 _postStateRoot
        )
    {
        return postStateRoot;
    }

    /**
     * Checks whether the transitioner is complete.
     * @return _complete Whether or not the transition process is finished.
     */
    function isComplete()
        override
        external
        view
        returns (
            bool _complete
        )
    {
        return phase == TransitionPhase.COMPLETE;
    }


    /***********************************
     * Public Functions: Pre-Execution *
     ***********************************/

    /**
     * Allows a user to prove the initial state of a contract.
     * @param _ovmContractAddress Address of the contract on the OVM.
     * @param _ethContractAddress Address of the corresponding contract on L1.
     * @param _stateTrieWitness Proof of the account state.
     */
    function proveContractState(
        address _ovmContractAddress,
        address _ethContractAddress,
        bytes memory _stateTrieWitness
    )
        override
        external
        onlyDuringPhase(TransitionPhase.PRE_EXECUTION)
        contributesToFraudProof(preStateRoot, transactionHash)
    {
        // Exit quickly to avoid unnecessary work.
        require(
            (
                ovmStateManager.hasAccount(_ovmContractAddress) == false
                && ovmStateManager.hasEmptyAccount(_ovmContractAddress) == false
            ),
            "Account state has already been proven."
        );

        // Function will fail if the proof is not a valid inclusion or exclusion proof.
        (
            bool exists,
            bytes memory encodedAccount
        ) = Lib_SecureMerkleTrie.get(
            abi.encodePacked(_ovmContractAddress),
            _stateTrieWitness,
            preStateRoot
        );

        if (exists == true) {
            // Account exists, this was an inclusion proof.
            Lib_OVMCodec.EVMAccount memory account = Lib_OVMCodec.decodeEVMAccount(
                encodedAccount
            );

            address ethContractAddress = _ethContractAddress;
            if (account.codeHash == EMPTY_ACCOUNT_CODE_HASH) {
                // Use a known empty contract to prevent an attack in which a user provides a
                // contract address here and then later deploys code to it.
                ethContractAddress = 0x0000000000000000000000000000000000000000;
            } else {
                // Otherwise, make sure that the code at the provided eth address matches the hash
                // of the code stored on L2.
                require(
                    Lib_EthUtils.getCodeHash(ethContractAddress) == account.codeHash,
                    // solhint-disable-next-line max-line-length
                    "OVM_StateTransitioner: Provided L1 contract code hash does not match L2 contract code hash."
                );
            }

            ovmStateManager.putAccount(
                _ovmContractAddress,
                Lib_OVMCodec.Account({
                    nonce: account.nonce,
                    balance: account.balance,
                    storageRoot: account.storageRoot,
                    codeHash: account.codeHash,
                    ethAddress: ethContractAddress,
                    isFresh: false
                })
            );
        } else {
            // Account does not exist, this was an exclusion proof.
            ovmStateManager.putEmptyAccount(_ovmContractAddress);
        }
    }

    /**
     * Allows a user to prove the initial state of a contract storage slot.
     * @param _ovmContractAddress Address of the contract on the OVM.
     * @param _key Claimed account slot key.
     * @param _storageTrieWitness Proof of the storage slot.
     */
    function proveStorageSlot(
        address _ovmContractAddress,
        bytes32 _key,
        bytes memory _storageTrieWitness
    )
        override
        external
        onlyDuringPhase(TransitionPhase.PRE_EXECUTION)
        contributesToFraudProof(preStateRoot, transactionHash)
    {
        // Exit quickly to avoid unnecessary work.
        require(
            ovmStateManager.hasContractStorage(_ovmContractAddress, _key) == false,
            "Storage slot has already been proven."
        );

        require(
            ovmStateManager.hasAccount(_ovmContractAddress) == true,
            "Contract must be verified before proving a storage slot."
        );

        bytes32 storageRoot = ovmStateManager.getAccountStorageRoot(_ovmContractAddress);
        bytes32 value;

        if (storageRoot == EMPTY_ACCOUNT_STORAGE_ROOT) {
            // Storage trie was empty, so the user is always allowed to insert zero-byte values.
            value = bytes32(0);
        } else {
            // Function will fail if the proof is not a valid inclusion or exclusion proof.
            (
                bool exists,
                bytes memory encodedValue
            ) = Lib_SecureMerkleTrie.get(
                abi.encodePacked(_key),
                _storageTrieWitness,
                storageRoot
            );

            if (exists == true) {
                // Inclusion proof.
                // Stored values are RLP encoded, with leading zeros removed.
                value = Lib_BytesUtils.toBytes32PadLeft(
                    Lib_RLPReader.readBytes(encodedValue)
                );
            } else {
                // Exclusion proof, can only be zero bytes.
                value = bytes32(0);
            }
        }

        ovmStateManager.putContractStorage(
            _ovmContractAddress,
            _key,
            value
        );
    }


    /*******************************
     * Public Functions: Execution *
     *******************************/

    /**
     * Executes the state transition.
     * @param _transaction OVM transaction to execute.
     */
    function applyTransaction(
        Lib_OVMCodec.Transaction memory _transaction
    )
        override
        external
        onlyDuringPhase(TransitionPhase.PRE_EXECUTION)
        contributesToFraudProof(preStateRoot, transactionHash)
    {
        require(
            Lib_OVMCodec.hashTransaction(_transaction) == transactionHash,
            "Invalid transaction provided."
        );

        // We require gas to complete the logic here in run() before/after execution,
        // But must ensure the full _tx.gasLimit can be given to the ovmCALL (determinism)
        // This includes 1/64 of the gas getting lost because of EIP-150 (lost twice--first
        // going into EM, then going into the code contract).
        require(
            // 1032/1000 = 1.032 = (64/63)^2 rounded up
            gasleft() >= 100000 + _transaction.gasLimit * 1032 / 1000,
            "Not enough gas to execute transaction deterministically."
        );

        iOVM_ExecutionManager ovmExecutionManager =
            iOVM_ExecutionManager(resolve("OVM_ExecutionManager"));

        // We call `setExecutionManager` right before `run` (and not earlier) just in case the
        // OVM_ExecutionManager address was updated between the time when this contract was created
        // and when `applyTransaction` was called.
        ovmStateManager.setExecutionManager(address(ovmExecutionManager));

        // `run` always succeeds *unless* the user hasn't provided enough gas to `applyTransaction`
        // or an INVALID_STATE_ACCESS flag was triggered. Either way, we won't get beyond this line
        // if that's the case.
        ovmExecutionManager.run(_transaction, address(ovmStateManager));

        // Prevent the Execution Manager from calling this SM again.
        ovmStateManager.setExecutionManager(address(0));
        phase = TransitionPhase.POST_EXECUTION;
    }


    /************************************
     * Public Functions: Post-Execution *
     ************************************/

    /**
     * Allows a user to commit the final state of a contract.
     * @param _ovmContractAddress Address of the contract on the OVM.
     * @param _stateTrieWitness Proof of the account state.
     */
    function commitContractState(
        address _ovmContractAddress,
        bytes memory _stateTrieWitness
    )
        override
        external
        onlyDuringPhase(TransitionPhase.POST_EXECUTION)
        contributesToFraudProof(preStateRoot, transactionHash)
    {
        require(
            ovmStateManager.getTotalUncommittedContractStorage() == 0,
            "All storage must be committed before committing account states."
        );

        require (
            ovmStateManager.commitAccount(_ovmContractAddress) == true,
            "Account state wasn't changed or has already been committed."
        );

        Lib_OVMCodec.Account memory account = ovmStateManager.getAccount(_ovmContractAddress);

        postStateRoot = Lib_SecureMerkleTrie.update(
            abi.encodePacked(_ovmContractAddress),
            Lib_OVMCodec.encodeEVMAccount(
                Lib_OVMCodec.toEVMAccount(account)
            ),
            _stateTrieWitness,
            postStateRoot
        );

        // Emit an event to help clients figure out the proof ordering.
        emit AccountCommitted(
            _ovmContractAddress
        );
    }

    /**
     * Allows a user to commit the final state of a contract storage slot.
     * @param _ovmContractAddress Address of the contract on the OVM.
     * @param _key Claimed account slot key.
     * @param _storageTrieWitness Proof of the storage slot.
     */
    function commitStorageSlot(
        address _ovmContractAddress,
        bytes32 _key,
        bytes memory _storageTrieWitness
    )
        override
        external
        onlyDuringPhase(TransitionPhase.POST_EXECUTION)
        contributesToFraudProof(preStateRoot, transactionHash)
    {
        require(
            ovmStateManager.commitContractStorage(_ovmContractAddress, _key) == true,
            "Storage slot value wasn't changed or has already been committed."
        );

        Lib_OVMCodec.Account memory account = ovmStateManager.getAccount(_ovmContractAddress);
        bytes32 value = ovmStateManager.getContractStorage(_ovmContractAddress, _key);

        account.storageRoot = Lib_SecureMerkleTrie.update(
            abi.encodePacked(_key),
            Lib_RLPWriter.writeBytes(
                Lib_Bytes32Utils.removeLeadingZeros(value)
            ),
            _storageTrieWitness,
            account.storageRoot
        );

        ovmStateManager.putAccount(_ovmContractAddress, account);

        // Emit an event to help clients figure out the proof ordering.
        emit ContractStorageCommitted(
            _ovmContractAddress,
            _key
        );
    }


    /**********************************
     * Public Functions: Finalization *
     **********************************/

    /**
     * Finalizes the transition process.
     */
    function completeTransition()
        override
        external
        onlyDuringPhase(TransitionPhase.POST_EXECUTION)
    {
        require(
            ovmStateManager.getTotalUncommittedAccounts() == 0,
            "All accounts must be committed before completing a transition."
        );

        require(
            ovmStateManager.getTotalUncommittedContractStorage() == 0,
            "All storage must be committed before completing a transition."
        );

        phase = TransitionPhase.COMPLETE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPReader } from "../rlp/Lib_RLPReader.sol";
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";
import { Lib_BytesUtils } from "../utils/Lib_BytesUtils.sol";
import { Lib_Bytes32Utils } from "../utils/Lib_Bytes32Utils.sol";

/**
 * @title Lib_OVMCodec
 */
library Lib_OVMCodec {

    /*********
     * Enums *
     *********/

    enum QueueOrigin {
        SEQUENCER_QUEUE,
        L1TOL2_QUEUE
    }


    /***********
     * Structs *
     ***********/

    struct Account {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
        address ethAddress;
        bool isFresh;
    }

    struct EVMAccount {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct ChainBatchHeader {
        uint256 batchIndex;
        bytes32 batchRoot;
        uint256 batchSize;
        uint256 prevTotalElements;
        bytes extraData;
    }

    struct ChainInclusionProof {
        uint256 index;
        bytes32[] siblings;
    }

    struct Transaction {
        uint256 timestamp;
        uint256 blockNumber;
        QueueOrigin l1QueueOrigin;
        address l1TxOrigin;
        address entrypoint;
        uint256 gasLimit;
        bytes data;
    }

    struct TransactionChainElement {
        bool isSequenced;
        uint256 queueIndex;  // QUEUED TX ONLY
        uint256 timestamp;   // SEQUENCER TX ONLY
        uint256 blockNumber; // SEQUENCER TX ONLY
        bytes txData;        // SEQUENCER TX ONLY
    }

    struct QueueElement {
        bytes32 transactionHash;
        uint40 timestamp;
        uint40 blockNumber;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Encodes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return Encoded transaction bytes.
     */
    function encodeTransaction(
        Transaction memory _transaction
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return abi.encodePacked(
            _transaction.timestamp,
            _transaction.blockNumber,
            _transaction.l1QueueOrigin,
            _transaction.l1TxOrigin,
            _transaction.entrypoint,
            _transaction.gasLimit,
            _transaction.data
        );
    }

    /**
     * Hashes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return Hashed transaction
     */
    function hashTransaction(
        Transaction memory _transaction
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(encodeTransaction(_transaction));
    }

    /**
     * Converts an OVM account to an EVM account.
     * @param _in OVM account to convert.
     * @return Converted EVM account.
     */
    function toEVMAccount(
        Account memory _in
    )
        internal
        pure
        returns (
            EVMAccount memory
        )
    {
        return EVMAccount({
            nonce: _in.nonce,
            balance: _in.balance,
            storageRoot: _in.storageRoot,
            codeHash: _in.codeHash
        });
    }

    /**
     * @notice RLP-encodes an account state struct.
     * @param _account Account state struct.
     * @return RLP-encoded account state.
     */
    function encodeEVMAccount(
        EVMAccount memory _account
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        bytes[] memory raw = new bytes[](4);

        // Unfortunately we can't create this array outright because
        // Lib_RLPWriter.writeList will reject fixed-size arrays. Assigning
        // index-by-index circumvents this issue.
        raw[0] = Lib_RLPWriter.writeBytes(
            Lib_Bytes32Utils.removeLeadingZeros(
                bytes32(_account.nonce)
            )
        );
        raw[1] = Lib_RLPWriter.writeBytes(
            Lib_Bytes32Utils.removeLeadingZeros(
                bytes32(_account.balance)
            )
        );
        raw[2] = Lib_RLPWriter.writeBytes(abi.encodePacked(_account.storageRoot));
        raw[3] = Lib_RLPWriter.writeBytes(abi.encodePacked(_account.codeHash));

        return Lib_RLPWriter.writeList(raw);
    }

    /**
     * @notice Decodes an RLP-encoded account state into a useful struct.
     * @param _encoded RLP-encoded account state.
     * @return Account state struct.
     */
    function decodeEVMAccount(
        bytes memory _encoded
    )
        internal
        pure
        returns (
            EVMAccount memory
        )
    {
        Lib_RLPReader.RLPItem[] memory accountState = Lib_RLPReader.readList(_encoded);

        return EVMAccount({
            nonce: Lib_RLPReader.readUint256(accountState[0]),
            balance: Lib_RLPReader.readUint256(accountState[1]),
            storageRoot: Lib_RLPReader.readBytes32(accountState[2]),
            codeHash: Lib_RLPReader.readBytes32(accountState[3])
        });
    }

    /**
     * Calculates a hash for a given batch header.
     * @param _batchHeader Header to hash.
     * @return Hash of the header.
     */
    function hashBatchHeader(
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(
            abi.encode(
                _batchHeader.batchRoot,
                _batchHeader.batchSize,
                _batchHeader.prevTotalElements,
                _batchHeader.extraData
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_AddressManager } from "./Lib_AddressManager.sol";

/**
 * @title Lib_AddressResolver
 */
abstract contract Lib_AddressResolver {

    /*************
     * Variables *
     *************/

    Lib_AddressManager public libAddressManager;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(
        address _libAddressManager
    ) {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Resolves the address associated with a given name.
     * @param _name Name to resolve an address for.
     * @return Address associated with the given name.
     */
    function resolve(
        string memory _name
    )
        public
        view
        returns (
            address
        )
    {
        return libAddressManager.getAddress(_name);
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";
import { Lib_Bytes32Utils } from "./Lib_Bytes32Utils.sol";

/**
 * @title Lib_EthUtils
 */
library Lib_EthUtils {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the code for a given address.
     * @param _address Address to get code for.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Code read from the contract.
     */
    function getCode(
        address _address,
        uint256 _offset,
        uint256 _length
    )
        internal
        view
        returns (
            bytes memory
        )
    {
        bytes memory code;
        assembly {
            code := mload(0x40)
            mstore(0x40, add(code, add(_length, 0x20)))
            mstore(code, _length)
            extcodecopy(_address, add(code, 0x20), _offset, _length)
        }

        return code;
    }

    /**
     * Gets the full code for a given address.
     * @param _address Address to get code for.
     * @return Full code of the contract.
     */
    function getCode(
        address _address
    )
        internal
        view
        returns (
            bytes memory
        )
    {
        return getCode(
            _address,
            0,
            getCodeSize(_address)
        );
    }

    /**
     * Gets the size of a contract's code in bytes.
     * @param _address Address to get code size for.
     * @return Size of the contract's code in bytes.
     */
    function getCodeSize(
        address _address
    )
        internal
        view
        returns (
            uint256
        )
    {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }

        return codeSize;
    }

    /**
     * Gets the hash of a contract's code.
     * @param _address Address to get a code hash for.
     * @return Hash of the contract's code.
     */
    function getCodeHash(
        address _address
    )
        internal
        view
        returns (
            bytes32
        )
    {
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(_address)
        }

        return codeHash;
    }

    /**
     * Creates a contract with some given initialization code.
     * @param _code Contract initialization code.
     * @return Address of the created contract.
     */
    function createContract(
        bytes memory _code
    )
        internal
        returns (
            address
        )
    {
        address created;
        assembly {
            created := create(
                0,
                add(_code, 0x20),
                mload(_code)
            )
        }

        return created;
    }

    /**
     * Computes the address that would be generated by CREATE.
     * @param _creator Address creating the contract.
     * @param _nonce Creator's nonce.
     * @return Address to be generated by CREATE.
     */
    function getAddressForCREATE(
        address _creator,
        uint256 _nonce
    )
        internal
        pure
        returns (
            address
        )
    {
        bytes[] memory encoded = new bytes[](2);
        encoded[0] = Lib_RLPWriter.writeAddress(_creator);
        encoded[1] = Lib_RLPWriter.writeUint(_nonce);

        bytes memory encodedList = Lib_RLPWriter.writeList(encoded);
        return Lib_Bytes32Utils.toAddress(keccak256(encodedList));
    }

    /**
     * Computes the address that would be generated by CREATE2.
     * @param _creator Address creating the contract.
     * @param _bytecode Bytecode of the contract to be created.
     * @param _salt 32 byte salt value mixed into the hash.
     * @return Address to be generated by CREATE2.
     */
    function getAddressForCREATE2(
        address _creator,
        bytes memory _bytecode,
        bytes32 _salt
    )
        internal
        pure
        returns (
            address
        )
    {
        bytes32 hashedData = keccak256(abi.encodePacked(
            byte(0xff),
            _creator,
            _salt,
            keccak256(_bytecode)
        ));

        return Lib_Bytes32Utils.toAddress(hashedData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_MerkleTrie } from "./Lib_MerkleTrie.sol";

/**
 * @title Lib_SecureMerkleTrie
 */
library Lib_SecureMerkleTrie {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * @notice Verifies a proof that a given key/value pair is present in the
     * Merkle trie.
     * @param _key Key of the node to search for, as a hex string.
     * @param _value Value of the node to search for, as a hex string.
     * @param _proof Merkle trie inclusion proof for the desired node. Unlike
     * traditional Merkle trees, this proof is executed top-down and consists
     * of a list of RLP-encoded nodes that make a path down to the target node.
     * @param _root Known root of the Merkle trie. Used to verify that the
     * included proof is correctly constructed.
     * @return _verified `true` if the k/v pair exists in the trie, `false` otherwise.
     */
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        internal
        pure
        returns (
            bool _verified
        )
    {
        bytes memory key = _getSecureKey(_key);
        return Lib_MerkleTrie.verifyInclusionProof(key, _value, _proof, _root);
    }

    /**
     * @notice Updates a Merkle trie and returns a new root hash.
     * @param _key Key of the node to update, as a hex string.
     * @param _value Value of the node to update, as a hex string.
     * @param _proof Merkle trie inclusion proof for the node *nearest* the
     * target node. If the key exists, we can simply update the value.
     * Otherwise, we need to modify the trie to handle the new k/v pair.
     * @param _root Known root of the Merkle trie. Used to verify that the
     * included proof is correctly constructed.
     * @return _updatedRoot Root hash of the newly constructed trie.
     */
    function update(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        internal
        pure
        returns (
            bytes32 _updatedRoot
        )
    {
        bytes memory key = _getSecureKey(_key);
        return Lib_MerkleTrie.update(key, _value, _proof, _root);
    }

    /**
     * @notice Retrieves the value associated with a given key.
     * @param _key Key to search for, as hex bytes.
     * @param _proof Merkle trie inclusion proof for the key.
     * @param _root Known root of the Merkle trie.
     * @return _exists Whether or not the key exists.
     * @return _value Value of the key if it exists.
     */
    function get(
        bytes memory _key,
        bytes memory _proof,
        bytes32 _root
    )
        internal
        pure
        returns (
            bool _exists,
            bytes memory _value
        )
    {
        bytes memory key = _getSecureKey(_key);
        return Lib_MerkleTrie.get(key, _proof, _root);
    }

    /**
     * Computes the root hash for a trie with a single node.
     * @param _key Key for the single node.
     * @param _value Value for the single node.
     * @return _updatedRoot Hash of the trie.
     */
    function getSingleNodeRootHash(
        bytes memory _key,
        bytes memory _value
    )
        internal
        pure
        returns (
            bytes32 _updatedRoot
        )
    {
        bytes memory key = _getSecureKey(_key);
        return Lib_MerkleTrie.getSingleNodeRootHash(key, _value);
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Computes the secure counterpart to a key.
     * @param _key Key to get a secure key from.
     * @return _secureKey Secure version of the key.
     */
    function _getSecureKey(
        bytes memory _key
    )
        private
        pure
        returns (
            bytes memory _secureKey
        )
    {
        return abi.encodePacked(keccak256(_key));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/**
 * @title iOVM_StateTransitioner
 */
interface iOVM_StateTransitioner {

    /**********
     * Events *
     **********/

    event AccountCommitted(
        address _address
    );

    event ContractStorageCommitted(
        address _address,
        bytes32 _key
    );


    /**********************************
     * Public Functions: State Access *
     **********************************/

    function getPreStateRoot() external view returns (bytes32 _preStateRoot);
    function getPostStateRoot() external view returns (bytes32 _postStateRoot);
    function isComplete() external view returns (bool _complete);


    /***********************************
     * Public Functions: Pre-Execution *
     ***********************************/

    function proveContractState(
        address _ovmContractAddress,
        address _ethContractAddress,
        bytes calldata _stateTrieWitness
    ) external;

    function proveStorageSlot(
        address _ovmContractAddress,
        bytes32 _key,
        bytes calldata _storageTrieWitness
    ) external;


    /*******************************
     * Public Functions: Execution *
     *******************************/

    function applyTransaction(
        Lib_OVMCodec.Transaction calldata _transaction
    ) external;


    /************************************
     * Public Functions: Post-Execution *
     ************************************/

    function commitContractState(
        address _ovmContractAddress,
        bytes calldata _stateTrieWitness
    ) external;

    function commitStorageSlot(
        address _ovmContractAddress,
        bytes32 _key,
        bytes calldata _storageTrieWitness
    ) external;


    /**********************************
     * Public Functions: Finalization *
     **********************************/

    function completeTransition() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

interface ERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

/// All the errors which may be encountered on the bond manager
library Errors {
    string constant ERC20_ERR = "BondManager: Could not post bond";
    // solhint-disable-next-line max-line-length
    string constant ALREADY_FINALIZED = "BondManager: Fraud proof for this pre-state root has already been finalized";
    string constant SLASHED = "BondManager: Cannot finalize withdrawal, you probably got slashed";
    string constant WRONG_STATE = "BondManager: Wrong bond state for proposer";
    string constant CANNOT_CLAIM = "BondManager: Cannot claim yet. Dispute must be finalized first";

    string constant WITHDRAWAL_PENDING = "BondManager: Withdrawal already pending";
    string constant TOO_EARLY = "BondManager: Too early to finalize your withdrawal";
    // solhint-disable-next-line max-line-length
    string constant ONLY_TRANSITIONER = "BondManager: Only the transitioner for this pre-state root may call this function";
    // solhint-disable-next-line max-line-length
    string constant ONLY_FRAUD_VERIFIER = "BondManager: Only the fraud verifier may call this function";
    // solhint-disable-next-line max-line-length
    string constant ONLY_STATE_COMMITMENT_CHAIN = "BondManager: Only the state commitment chain may call this function";
    string constant WAIT_FOR_DISPUTES = "BondManager: Wait for other potential disputes";
}

/**
 * @title iOVM_BondManager
 */
interface iOVM_BondManager {

    /*******************
     * Data Structures *
     *******************/

    /// The lifecycle of a proposer's bond
    enum State {
        // Before depositing or after getting slashed, a user is uncollateralized
        NOT_COLLATERALIZED,
        // After depositing, a user is collateralized
        COLLATERALIZED,
        // After a user has initiated a withdrawal
        WITHDRAWING
    }

    /// A bond posted by a proposer
    struct Bond {
        // The user's state
        State state;
        // The timestamp at which a proposer issued their withdrawal request
        uint32 withdrawalTimestamp;
        // The time when the first disputed was initiated for this bond
        uint256 firstDisputeAt;
        // The earliest observed state root for this bond which has had fraud
        bytes32 earliestDisputedStateRoot;
        // The state root's timestamp
        uint256 earliestTimestamp;
    }

    // Per pre-state root, store the number of state provisions that were made
    // and how many of these calls were made by each user. Payouts will then be
    // claimed by users proportionally for that dispute.
    struct Rewards {
        // Flag to check if rewards for a fraud proof are claimable
        bool canClaim;
        // Total number of `recordGasSpent` calls made
        uint256 total;
        // The gas spent by each user to provide witness data. The sum of all
        // values inside this map MUST be equal to the value of `total`
        mapping(address => uint256) gasSpent;
    }


    /********************
     * Public Functions *
     ********************/

    function recordGasSpent(
        bytes32 _preStateRoot,
        bytes32 _txHash,
        address _who,
        uint256 _gasSpent
    ) external;

    function finalize(
        bytes32 _preStateRoot,
        address _publisher,
        uint256 _timestamp
    ) external;

    function deposit() external;

    function startWithdrawal() external;

    function finalizeWithdrawal() external;

    function claim(
        address _who
    ) external;

    function isCollateralized(
        address _who
    ) external view returns (bool);

    function getGasSpent(
        bytes32 _preStateRoot,
        address _who
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

interface iOVM_ExecutionManager {
    /**********
     * Enums *
     *********/

    enum RevertFlag {
        OUT_OF_GAS,
        INTENTIONAL_REVERT,
        EXCEEDS_NUISANCE_GAS,
        INVALID_STATE_ACCESS,
        UNSAFE_BYTECODE,
        CREATE_COLLISION,
        STATIC_VIOLATION,
        CREATOR_NOT_ALLOWED
    }

    enum GasMetadataKey {
        CURRENT_EPOCH_START_TIMESTAMP,
        CUMULATIVE_SEQUENCER_QUEUE_GAS,
        CUMULATIVE_L1TOL2_QUEUE_GAS,
        PREV_EPOCH_SEQUENCER_QUEUE_GAS,
        PREV_EPOCH_L1TOL2_QUEUE_GAS
    }

    enum MessageType {
        ovmCALL,
        ovmSTATICCALL,
        ovmDELEGATECALL,
        ovmCREATE,
        ovmCREATE2
    }

    /***********
     * Structs *
     ***********/

    struct GasMeterConfig {
        uint256 minTransactionGasLimit;
        uint256 maxTransactionGasLimit;
        uint256 maxGasPerQueuePerEpoch;
        uint256 secondsPerEpoch;
    }

    struct GlobalContext {
        uint256 ovmCHAINID;
    }

    struct TransactionContext {
        Lib_OVMCodec.QueueOrigin ovmL1QUEUEORIGIN;
        uint256 ovmTIMESTAMP;
        uint256 ovmNUMBER;
        uint256 ovmGASLIMIT;
        uint256 ovmTXGASLIMIT;
        address ovmL1TXORIGIN;
    }

    struct TransactionRecord {
        uint256 ovmGasRefund;
    }

    struct MessageContext {
        address ovmCALLER;
        address ovmADDRESS;
        uint256 ovmCALLVALUE;
        bool isStatic;
    }

    struct MessageRecord {
        uint256 nuisanceGasLeft;
    }


    /************************************
     * Transaction Execution Entrypoint *
     ************************************/

    function run(
        Lib_OVMCodec.Transaction calldata _transaction,
        address _txStateManager
    ) external returns (bytes memory);


    /*******************
     * Context Opcodes *
     *******************/

    function ovmCALLER() external view returns (address _caller);
    function ovmADDRESS() external view returns (address _address);
    function ovmCALLVALUE() external view returns (uint _callValue);
    function ovmTIMESTAMP() external view returns (uint256 _timestamp);
    function ovmNUMBER() external view returns (uint256 _number);
    function ovmGASLIMIT() external view returns (uint256 _gasLimit);
    function ovmCHAINID() external view returns (uint256 _chainId);


    /**********************
     * L2 Context Opcodes *
     **********************/

    function ovmL1QUEUEORIGIN() external view returns (Lib_OVMCodec.QueueOrigin _queueOrigin);
    function ovmL1TXORIGIN() external view returns (address _l1TxOrigin);


    /*******************
     * Halting Opcodes *
     *******************/

    function ovmREVERT(bytes memory _data) external;


    /*****************************
     * Contract Creation Opcodes *
     *****************************/

    function ovmCREATE(bytes memory _bytecode) external
        returns (address _contract, bytes memory _revertdata);
    function ovmCREATE2(bytes memory _bytecode, bytes32 _salt) external
        returns (address _contract, bytes memory _revertdata);


    /*******************************
     * Account Abstraction Opcodes *
     ******************************/

    function ovmGETNONCE() external returns (uint256 _nonce);
    function ovmINCREMENTNONCE() external;
    function ovmCREATEEOA(bytes32 _messageHash, uint8 _v, bytes32 _r, bytes32 _s) external;


    /****************************
     * Contract Calling Opcodes *
     ****************************/

    // Valueless ovmCALL for maintaining backwards compatibility with legacy OVM bytecode.
    function ovmCALL(uint256 _gasLimit, address _address, bytes memory _calldata) external
        returns (bool _success, bytes memory _returndata);
    function ovmCALL(uint256 _gasLimit, address _address, uint256 _value, bytes memory _calldata)
        external returns (bool _success, bytes memory _returndata);
    function ovmSTATICCALL(uint256 _gasLimit, address _address, bytes memory _calldata) external
        returns (bool _success, bytes memory _returndata);
    function ovmDELEGATECALL(uint256 _gasLimit, address _address, bytes memory _calldata) external
        returns (bool _success, bytes memory _returndata);


    /****************************
     * Contract Storage Opcodes *
     ****************************/

    function ovmSLOAD(bytes32 _key) external returns (bytes32 _value);
    function ovmSSTORE(bytes32 _key, bytes32 _value) external;


    /*************************
     * Contract Code Opcodes *
     *************************/

    function ovmEXTCODECOPY(address _contract, uint256 _offset, uint256 _length) external
        returns (bytes memory _code);
    function ovmEXTCODESIZE(address _contract) external returns (uint256 _size);
    function ovmEXTCODEHASH(address _contract) external returns (bytes32 _hash);


    /*********************
     * ETH Value Opcodes *
     *********************/

    function ovmBALANCE(address _contract) external returns (uint256 _balance);
    function ovmSELFBALANCE() external returns (uint256 _balance);


    /***************************************
     * Public Functions: Execution Context *
     ***************************************/

    function getMaxTransactionGasLimit() external view returns (uint _maxTransactionGasLimit);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/**
 * @title iOVM_StateManager
 */
interface iOVM_StateManager {

    /*******************
     * Data Structures *
     *******************/

    enum ItemState {
        ITEM_UNTOUCHED,
        ITEM_LOADED,
        ITEM_CHANGED,
        ITEM_COMMITTED
    }

    /***************************
     * Public Functions: Misc *
     ***************************/

    function isAuthenticated(address _address) external view returns (bool);

    /***************************
     * Public Functions: Setup *
     ***************************/

    function owner() external view returns (address _owner);
    function ovmExecutionManager() external view returns (address _ovmExecutionManager);
    function setExecutionManager(address _ovmExecutionManager) external;


    /************************************
     * Public Functions: Account Access *
     ************************************/

    function putAccount(address _address, Lib_OVMCodec.Account memory _account) external;
    function putEmptyAccount(address _address) external;
    function getAccount(address _address) external view
        returns (Lib_OVMCodec.Account memory _account);
    function hasAccount(address _address) external view returns (bool _exists);
    function hasEmptyAccount(address _address) external view returns (bool _exists);
    function setAccountNonce(address _address, uint256 _nonce) external;
    function getAccountNonce(address _address) external view returns (uint256 _nonce);
    function getAccountEthAddress(address _address) external view returns (address _ethAddress);
    function getAccountStorageRoot(address _address) external view returns (bytes32 _storageRoot);
    function initPendingAccount(address _address) external;
    function commitPendingAccount(address _address, address _ethAddress, bytes32 _codeHash)
        external;
    function testAndSetAccountLoaded(address _address) external
        returns (bool _wasAccountAlreadyLoaded);
    function testAndSetAccountChanged(address _address) external
        returns (bool _wasAccountAlreadyChanged);
    function commitAccount(address _address) external returns (bool _wasAccountCommitted);
    function incrementTotalUncommittedAccounts() external;
    function getTotalUncommittedAccounts() external view returns (uint256 _total);
    function wasAccountChanged(address _address) external view returns (bool);
    function wasAccountCommitted(address _address) external view returns (bool);


    /************************************
     * Public Functions: Storage Access *
     ************************************/

    function putContractStorage(address _contract, bytes32 _key, bytes32 _value) external;
    function getContractStorage(address _contract, bytes32 _key) external view
        returns (bytes32 _value);
    function hasContractStorage(address _contract, bytes32 _key) external view
        returns (bool _exists);
    function testAndSetContractStorageLoaded(address _contract, bytes32 _key) external
        returns (bool _wasContractStorageAlreadyLoaded);
    function testAndSetContractStorageChanged(address _contract, bytes32 _key) external
        returns (bool _wasContractStorageAlreadyChanged);
    function commitContractStorage(address _contract, bytes32 _key) external
        returns (bool _wasContractStorageCommitted);
    function incrementTotalUncommittedContractStorage() external;
    function getTotalUncommittedContractStorage() external view returns (uint256 _total);
    function wasContractStorageChanged(address _contract, bytes32 _key) external view
        returns (bool);
    function wasContractStorageCommitted(address _contract, bytes32 _key) external view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Contract Imports */
import { iOVM_StateManager } from "./iOVM_StateManager.sol";

/**
 * @title iOVM_StateManagerFactory
 */
interface iOVM_StateManagerFactory {

    /***************************************
     * Public Functions: Contract Creation *
     ***************************************/

    function create(
        address _owner
    )
        external
        returns (
            iOVM_StateManager _ovmStateManager
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

import { iOVM_BondManager } from "../../iOVM/verification/iOVM_BondManager.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";

/// Minimal contract to be inherited by contracts consumed by users that provide
/// data for fraud proofs
abstract contract Abs_FraudContributor is Lib_AddressResolver {
    /// Decorate your functions with this modifier to store how much total gas was
    /// consumed by the sender, to reward users fairly
    modifier contributesToFraudProof(bytes32 preStateRoot, bytes32 txHash) {
        uint256 startGas = gasleft();
        _;
        uint256 gasSpent = startGas - gasleft();
        iOVM_BondManager(resolve("OVM_BondManager"))
            .recordGasSpent(preStateRoot, txHash, msg.sender, gasSpent);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {

    /**********
     * Events *
     **********/

    event AddressSet(
        string indexed _name,
        address _newAddress,
        address _oldAddress
    );


    /*************
     * Variables *
     *************/

    mapping (bytes32 => address) private addresses;


    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(
        string memory _name,
        address _address
    )
        external
        onlyOwner
    {
        bytes32 nameHash = _getNameHash(_name);
        address oldAddress = addresses[nameHash];
        addresses[nameHash] = _address;

        emit AddressSet(
            _name,
            _address,
            oldAddress
        );
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(
        string memory _name
    )
        external
        view
        returns (
            address
        )
    {
        return addresses[_getNameHash(_name)];
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Computes the hash of a name.
     * @param _name Name to compute a hash for.
     * @return Hash of the given name.
     */
    function _getNameHash(
        string memory _name
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(abi.encodePacked(_name));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_BytesUtils } from "../utils/Lib_BytesUtils.sol";
import { Lib_RLPReader } from "../rlp/Lib_RLPReader.sol";
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";

/**
 * @title Lib_MerkleTrie
 */
library Lib_MerkleTrie {

    /*******************
     * Data Structures *
     *******************/

    enum NodeType {
        BranchNode,
        ExtensionNode,
        LeafNode
    }

    struct TrieNode {
        bytes encoded;
        Lib_RLPReader.RLPItem[] decoded;
    }


    /**********************
     * Contract Constants *
     **********************/

    // TREE_RADIX determines the number of elements per branch node.
    uint256 constant TREE_RADIX = 16;
    // Branch nodes have TREE_RADIX elements plus an additional `value` slot.
    uint256 constant BRANCH_NODE_LENGTH = TREE_RADIX + 1;
    // Leaf nodes and extension nodes always have two elements, a `path` and a `value`.
    uint256 constant LEAF_OR_EXTENSION_NODE_LENGTH = 2;

    // Prefixes are prepended to the `path` within a leaf or extension node and
    // allow us to differentiate between the two node types. `ODD` or `EVEN` is
    // determined by the number of nibbles within the unprefixed `path`. If the
    // number of nibbles if even, we need to insert an extra padding nibble so
    // the resulting prefixed `path` has an even number of nibbles.
    uint8 constant PREFIX_EXTENSION_EVEN = 0;
    uint8 constant PREFIX_EXTENSION_ODD = 1;
    uint8 constant PREFIX_LEAF_EVEN = 2;
    uint8 constant PREFIX_LEAF_ODD = 3;

    // Just a utility constant. RLP represents `NULL` as 0x80.
    bytes1 constant RLP_NULL = bytes1(0x80);
    bytes constant RLP_NULL_BYTES = hex'80';
    bytes32 constant internal KECCAK256_RLP_NULL_BYTES = keccak256(RLP_NULL_BYTES);


    /**********************
     * Internal Functions *
     **********************/

    /**
     * @notice Verifies a proof that a given key/value pair is present in the
     * Merkle trie.
     * @param _key Key of the node to search for, as a hex string.
     * @param _value Value of the node to search for, as a hex string.
     * @param _proof Merkle trie inclusion proof for the desired node. Unlike
     * traditional Merkle trees, this proof is executed top-down and consists
     * of a list of RLP-encoded nodes that make a path down to the target node.
     * @param _root Known root of the Merkle trie. Used to verify that the
     * included proof is correctly constructed.
     * @return _verified `true` if the k/v pair exists in the trie, `false` otherwise.
     */
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        internal
        pure
        returns (
            bool _verified
        )
    {
        (
            bool exists,
            bytes memory value
        ) = get(_key, _proof, _root);

        return (
            exists && Lib_BytesUtils.equal(_value, value)
        );
    }

    /**
     * @notice Updates a Merkle trie and returns a new root hash.
     * @param _key Key of the node to update, as a hex string.
     * @param _value Value of the node to update, as a hex string.
     * @param _proof Merkle trie inclusion proof for the node *nearest* the
     * target node. If the key exists, we can simply update the value.
     * Otherwise, we need to modify the trie to handle the new k/v pair.
     * @param _root Known root of the Merkle trie. Used to verify that the
     * included proof is correctly constructed.
     * @return _updatedRoot Root hash of the newly constructed trie.
     */
    function update(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        internal
        pure
        returns (
            bytes32 _updatedRoot
        )
    {
        // Special case when inserting the very first node.
        if (_root == KECCAK256_RLP_NULL_BYTES) {
            return getSingleNodeRootHash(_key, _value);
        }

        TrieNode[] memory proof = _parseProof(_proof);
        (uint256 pathLength, bytes memory keyRemainder, ) = _walkNodePath(proof, _key, _root);
        TrieNode[] memory newPath = _getNewPath(proof, pathLength, _key, keyRemainder, _value);

        return _getUpdatedTrieRoot(newPath, _key);
    }

    /**
     * @notice Retrieves the value associated with a given key.
     * @param _key Key to search for, as hex bytes.
     * @param _proof Merkle trie inclusion proof for the key.
     * @param _root Known root of the Merkle trie.
     * @return _exists Whether or not the key exists.
     * @return _value Value of the key if it exists.
     */
    function get(
        bytes memory _key,
        bytes memory _proof,
        bytes32 _root
    )
        internal
        pure
        returns (
            bool _exists,
            bytes memory _value
        )
    {
        TrieNode[] memory proof = _parseProof(_proof);
        (uint256 pathLength, bytes memory keyRemainder, bool isFinalNode) =
            _walkNodePath(proof, _key, _root);

        bool exists = keyRemainder.length == 0;

        require(
            exists || isFinalNode,
            "Provided proof is invalid."
        );

        bytes memory value = exists ? _getNodeValue(proof[pathLength - 1]) : bytes("");

        return (
            exists,
            value
        );
    }

    /**
     * Computes the root hash for a trie with a single node.
     * @param _key Key for the single node.
     * @param _value Value for the single node.
     * @return _updatedRoot Hash of the trie.
     */
    function getSingleNodeRootHash(
        bytes memory _key,
        bytes memory _value
    )
        internal
        pure
        returns (
            bytes32 _updatedRoot
        )
    {
        return keccak256(_makeLeafNode(
            Lib_BytesUtils.toNibbles(_key),
            _value
        ).encoded);
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * @notice Walks through a proof using a provided key.
     * @param _proof Inclusion proof to walk through.
     * @param _key Key to use for the walk.
     * @param _root Known root of the trie.
     * @return _pathLength Length of the final path
     * @return _keyRemainder Portion of the key remaining after the walk.
     * @return _isFinalNode Whether or not we've hit a dead end.
     */
    function _walkNodePath(
        TrieNode[] memory _proof,
        bytes memory _key,
        bytes32 _root
    )
        private
        pure
        returns (
            uint256 _pathLength,
            bytes memory _keyRemainder,
            bool _isFinalNode
        )
    {
        uint256 pathLength = 0;
        bytes memory key = Lib_BytesUtils.toNibbles(_key);

        bytes32 currentNodeID = _root;
        uint256 currentKeyIndex = 0;
        uint256 currentKeyIncrement = 0;
        TrieNode memory currentNode;

        // Proof is top-down, so we start at the first element (root).
        for (uint256 i = 0; i < _proof.length; i++) {
            currentNode = _proof[i];
            currentKeyIndex += currentKeyIncrement;

            // Keep track of the proof elements we actually need.
            // It's expensive to resize arrays, so this simply reduces gas costs.
            pathLength += 1;

            if (currentKeyIndex == 0) {
                // First proof element is always the root node.
                require(
                    keccak256(currentNode.encoded) == currentNodeID,
                    "Invalid root hash"
                );
            } else if (currentNode.encoded.length >= 32) {
                // Nodes 32 bytes or larger are hashed inside branch nodes.
                require(
                    keccak256(currentNode.encoded) == currentNodeID,
                    "Invalid large internal hash"
                );
            } else {
                // Nodes smaller than 31 bytes aren't hashed.
                require(
                    Lib_BytesUtils.toBytes32(currentNode.encoded) == currentNodeID,
                    "Invalid internal node hash"
                );
            }

            if (currentNode.decoded.length == BRANCH_NODE_LENGTH) {
                if (currentKeyIndex == key.length) {
                    // We've hit the end of the key
                    // meaning the value should be within this branch node.
                    break;
                } else {
                    // We're not at the end of the key yet.
                    // Figure out what the next node ID should be and continue.
                    uint8 branchKey = uint8(key[currentKeyIndex]);
                    Lib_RLPReader.RLPItem memory nextNode = currentNode.decoded[branchKey];
                    currentNodeID = _getNodeID(nextNode);
                    currentKeyIncrement = 1;
                    continue;
                }
            } else if (currentNode.decoded.length == LEAF_OR_EXTENSION_NODE_LENGTH) {
                bytes memory path = _getNodePath(currentNode);
                uint8 prefix = uint8(path[0]);
                uint8 offset = 2 - prefix % 2;
                bytes memory pathRemainder = Lib_BytesUtils.slice(path, offset);
                bytes memory keyRemainder = Lib_BytesUtils.slice(key, currentKeyIndex);
                uint256 sharedNibbleLength = _getSharedNibbleLength(pathRemainder, keyRemainder);

                if (prefix == PREFIX_LEAF_EVEN || prefix == PREFIX_LEAF_ODD) {
                    if (
                        pathRemainder.length == sharedNibbleLength &&
                        keyRemainder.length == sharedNibbleLength
                    ) {
                        // The key within this leaf matches our key exactly.
                        // Increment the key index to reflect that we have no remainder.
                        currentKeyIndex += sharedNibbleLength;
                    }

                    // We've hit a leaf node, so our next node should be NULL.
                    currentNodeID = bytes32(RLP_NULL);
                    break;
                } else if (prefix == PREFIX_EXTENSION_EVEN || prefix == PREFIX_EXTENSION_ODD) {
                    if (sharedNibbleLength != pathRemainder.length) {
                        // Our extension node is not identical to the remainder.
                        // We've hit the end of this path
                        // updates will need to modify this extension.
                        currentNodeID = bytes32(RLP_NULL);
                        break;
                    } else {
                        // Our extension shares some nibbles.
                        // Carry on to the next node.
                        currentNodeID = _getNodeID(currentNode.decoded[1]);
                        currentKeyIncrement = sharedNibbleLength;
                        continue;
                    }
                } else {
                    revert("Received a node with an unknown prefix");
                }
            } else {
                revert("Received an unparseable node.");
            }
        }

        // If our node ID is NULL, then we're at a dead end.
        bool isFinalNode = currentNodeID == bytes32(RLP_NULL);
        return (pathLength, Lib_BytesUtils.slice(key, currentKeyIndex), isFinalNode);
    }

    /**
     * @notice Creates new nodes to support a k/v pair insertion into a given Merkle trie path.
     * @param _path Path to the node nearest the k/v pair.
     * @param _pathLength Length of the path. Necessary because the provided path may include
     *  additional nodes (e.g., it comes directly from a proof) and we can't resize in-memory
     *  arrays without costly duplication.
     * @param _key Full original key.
     * @param _keyRemainder Portion of the initial key that must be inserted into the trie.
     * @param _value Value to insert at the given key.
     * @return _newPath A new path with the inserted k/v pair and extra supporting nodes.
     */
    function _getNewPath(
        TrieNode[] memory _path,
        uint256 _pathLength,
        bytes memory _key,
        bytes memory _keyRemainder,
        bytes memory _value
    )
        private
        pure
        returns (
            TrieNode[] memory _newPath
        )
    {
        bytes memory keyRemainder = _keyRemainder;

        // Most of our logic depends on the status of the last node in the path.
        TrieNode memory lastNode = _path[_pathLength - 1];
        NodeType lastNodeType = _getNodeType(lastNode);

        // Create an array for newly created nodes.
        // We need up to three new nodes, depending on the contents of the last node.
        // Since array resizing is expensive, we'll keep track of the size manually.
        // We're using an explicit `totalNewNodes += 1` after insertions for clarity.
        TrieNode[] memory newNodes = new TrieNode[](3);
        uint256 totalNewNodes = 0;

        // solhint-disable-next-line max-line-length
        // Reference: https://github.com/ethereumjs/merkle-patricia-tree/blob/c0a10395aab37d42c175a47114ebfcbd7efcf059/src/baseTrie.ts#L294-L313
        bool matchLeaf = false;
        if (lastNodeType == NodeType.LeafNode) {
            uint256 l = 0;
            if (_path.length > 0) {
                for (uint256 i = 0; i < _path.length - 1; i++) {
                    if (_getNodeType(_path[i]) == NodeType.BranchNode) {
                        l++;
                    } else {
                        l += _getNodeKey(_path[i]).length;
                    }
                }
            }

            if (
                _getSharedNibbleLength(
                    _getNodeKey(lastNode),
                    Lib_BytesUtils.slice(Lib_BytesUtils.toNibbles(_key), l)
                ) == _getNodeKey(lastNode).length
                && keyRemainder.length == 0
            ) {
                matchLeaf = true;
            }
        }

        if (matchLeaf) {
            // We've found a leaf node with the given key.
            // Simply need to update the value of the node to match.
            newNodes[totalNewNodes] = _makeLeafNode(_getNodeKey(lastNode), _value);
            totalNewNodes += 1;
        } else if (lastNodeType == NodeType.BranchNode) {
            if (keyRemainder.length == 0) {
                // We've found a branch node with the given key.
                // Simply need to update the value of the node to match.
                newNodes[totalNewNodes] = _editBranchValue(lastNode, _value);
                totalNewNodes += 1;
            } else {
                // We've found a branch node, but it doesn't contain our key.
                // Reinsert the old branch for now.
                newNodes[totalNewNodes] = lastNode;
                totalNewNodes += 1;
                // Create a new leaf node, slicing our remainder since the first byte points
                // to our branch node.
                newNodes[totalNewNodes] =
                    _makeLeafNode(Lib_BytesUtils.slice(keyRemainder, 1), _value);
                totalNewNodes += 1;
            }
        } else {
            // Our last node is either an extension node or a leaf node with a different key.
            bytes memory lastNodeKey = _getNodeKey(lastNode);
            uint256 sharedNibbleLength = _getSharedNibbleLength(lastNodeKey, keyRemainder);

            if (sharedNibbleLength != 0) {
                // We've got some shared nibbles between the last node and our key remainder.
                // We'll need to insert an extension node that covers these shared nibbles.
                bytes memory nextNodeKey = Lib_BytesUtils.slice(lastNodeKey, 0, sharedNibbleLength);
                newNodes[totalNewNodes] = _makeExtensionNode(nextNodeKey, _getNodeHash(_value));
                totalNewNodes += 1;

                // Cut down the keys since we've just covered these shared nibbles.
                lastNodeKey = Lib_BytesUtils.slice(lastNodeKey, sharedNibbleLength);
                keyRemainder = Lib_BytesUtils.slice(keyRemainder, sharedNibbleLength);
            }

            // Create an empty branch to fill in.
            TrieNode memory newBranch = _makeEmptyBranchNode();

            if (lastNodeKey.length == 0) {
                // Key remainder was larger than the key for our last node.
                // The value within our last node is therefore going to be shifted into
                // a branch value slot.
                newBranch = _editBranchValue(newBranch, _getNodeValue(lastNode));
            } else {
                // Last node key was larger than the key remainder.
                // We're going to modify some index of our branch.
                uint8 branchKey = uint8(lastNodeKey[0]);
                // Move on to the next nibble.
                lastNodeKey = Lib_BytesUtils.slice(lastNodeKey, 1);

                if (lastNodeType == NodeType.LeafNode) {
                    // We're dealing with a leaf node.
                    // We'll modify the key and insert the old leaf node into the branch index.
                    TrieNode memory modifiedLastNode =
                        _makeLeafNode(lastNodeKey, _getNodeValue(lastNode));
                    newBranch =
                        _editBranchIndex(
                                newBranch,
                                branchKey,
                                _getNodeHash(modifiedLastNode.encoded));
                } else if (lastNodeKey.length != 0) {
                    // We're dealing with a shrinking extension node.
                    // We need to modify the node to decrease the size of the key.
                    TrieNode memory modifiedLastNode =
                        _makeExtensionNode(lastNodeKey, _getNodeValue(lastNode));
                    newBranch =
                        _editBranchIndex(
                            newBranch,
                            branchKey,
                            _getNodeHash(modifiedLastNode.encoded));
                } else {
                    // We're dealing with an unnecessary extension node.
                    // We're going to delete the node entirely.
                    // Simply insert its current value into the branch index.
                    newBranch = _editBranchIndex(newBranch, branchKey, _getNodeValue(lastNode));
                }
            }

            if (keyRemainder.length == 0) {
                // We've got nothing left in the key remainder.
                // Simply insert the value into the branch value slot.
                newBranch = _editBranchValue(newBranch, _value);
                // Push the branch into the list of new nodes.
                newNodes[totalNewNodes] = newBranch;
                totalNewNodes += 1;
            } else {
                // We've got some key remainder to work with.
                // We'll be inserting a leaf node into the trie.
                // First, move on to the next nibble.
                keyRemainder = Lib_BytesUtils.slice(keyRemainder, 1);
                // Push the branch into the list of new nodes.
                newNodes[totalNewNodes] = newBranch;
                totalNewNodes += 1;
                // Push a new leaf node for our k/v pair.
                newNodes[totalNewNodes] = _makeLeafNode(keyRemainder, _value);
                totalNewNodes += 1;
            }
        }

        // Finally, join the old path with our newly created nodes.
        // Since we're overwriting the last node in the path, we use `_pathLength - 1`.
        return _joinNodeArrays(_path, _pathLength - 1, newNodes, totalNewNodes);
    }

    /**
     * @notice Computes the trie root from a given path.
     * @param _nodes Path to some k/v pair.
     * @param _key Key for the k/v pair.
     * @return _updatedRoot Root hash for the updated trie.
     */
    function _getUpdatedTrieRoot(
        TrieNode[] memory _nodes,
        bytes memory _key
    )
        private
        pure
        returns (
            bytes32 _updatedRoot
        )
    {
        bytes memory key = Lib_BytesUtils.toNibbles(_key);

        // Some variables to keep track of during iteration.
        TrieNode memory currentNode;
        NodeType currentNodeType;
        bytes memory previousNodeHash;

        // Run through the path backwards to rebuild our root hash.
        for (uint256 i = _nodes.length; i > 0; i--) {
            // Pick out the current node.
            currentNode = _nodes[i - 1];
            currentNodeType = _getNodeType(currentNode);

            if (currentNodeType == NodeType.LeafNode) {
                // Leaf nodes are already correctly encoded.
                // Shift the key over to account for the nodes key.
                bytes memory nodeKey = _getNodeKey(currentNode);
                key = Lib_BytesUtils.slice(key, 0, key.length - nodeKey.length);
            } else if (currentNodeType == NodeType.ExtensionNode) {
                // Shift the key over to account for the nodes key.
                bytes memory nodeKey = _getNodeKey(currentNode);
                key = Lib_BytesUtils.slice(key, 0, key.length - nodeKey.length);

                // If this node is the last element in the path, it'll be correctly encoded
                // and we can skip this part.
                if (previousNodeHash.length > 0) {
                    // Re-encode the node based on the previous node.
                    currentNode = _editExtensionNodeValue(currentNode, previousNodeHash);
                }
            } else if (currentNodeType == NodeType.BranchNode) {
                // If this node is the last element in the path, it'll be correctly encoded
                // and we can skip this part.
                if (previousNodeHash.length > 0) {
                    // Re-encode the node based on the previous node.
                    uint8 branchKey = uint8(key[key.length - 1]);
                    key = Lib_BytesUtils.slice(key, 0, key.length - 1);
                    currentNode = _editBranchIndex(currentNode, branchKey, previousNodeHash);
                }
            }

            // Compute the node hash for the next iteration.
            previousNodeHash = _getNodeHash(currentNode.encoded);
        }

        // Current node should be the root at this point.
        // Simply return the hash of its encoding.
        return keccak256(currentNode.encoded);
    }

    /**
     * @notice Parses an RLP-encoded proof into something more useful.
     * @param _proof RLP-encoded proof to parse.
     * @return _parsed Proof parsed into easily accessible structs.
     */
    function _parseProof(
        bytes memory _proof
    )
        private
        pure
        returns (
            TrieNode[] memory _parsed
        )
    {
        Lib_RLPReader.RLPItem[] memory nodes = Lib_RLPReader.readList(_proof);
        TrieNode[] memory proof = new TrieNode[](nodes.length);

        for (uint256 i = 0; i < nodes.length; i++) {
            bytes memory encoded = Lib_RLPReader.readBytes(nodes[i]);
            proof[i] = TrieNode({
                encoded: encoded,
                decoded: Lib_RLPReader.readList(encoded)
            });
        }

        return proof;
    }

    /**
     * @notice Picks out the ID for a node. Node ID is referred to as the
     * "hash" within the specification, but nodes < 32 bytes are not actually
     * hashed.
     * @param _node Node to pull an ID for.
     * @return _nodeID ID for the node, depending on the size of its contents.
     */
    function _getNodeID(
        Lib_RLPReader.RLPItem memory _node
    )
        private
        pure
        returns (
            bytes32 _nodeID
        )
    {
        bytes memory nodeID;

        if (_node.length < 32) {
            // Nodes smaller than 32 bytes are RLP encoded.
            nodeID = Lib_RLPReader.readRawBytes(_node);
        } else {
            // Nodes 32 bytes or larger are hashed.
            nodeID = Lib_RLPReader.readBytes(_node);
        }

        return Lib_BytesUtils.toBytes32(nodeID);
    }

    /**
     * @notice Gets the path for a leaf or extension node.
     * @param _node Node to get a path for.
     * @return _path Node path, converted to an array of nibbles.
     */
    function _getNodePath(
        TrieNode memory _node
    )
        private
        pure
        returns (
            bytes memory _path
        )
    {
        return Lib_BytesUtils.toNibbles(Lib_RLPReader.readBytes(_node.decoded[0]));
    }

    /**
     * @notice Gets the key for a leaf or extension node. Keys are essentially
     * just paths without any prefix.
     * @param _node Node to get a key for.
     * @return _key Node key, converted to an array of nibbles.
     */
    function _getNodeKey(
        TrieNode memory _node
    )
        private
        pure
        returns (
            bytes memory _key
        )
    {
        return _removeHexPrefix(_getNodePath(_node));
    }

    /**
     * @notice Gets the path for a node.
     * @param _node Node to get a value for.
     * @return _value Node value, as hex bytes.
     */
    function _getNodeValue(
        TrieNode memory _node
    )
        private
        pure
        returns (
            bytes memory _value
        )
    {
        return Lib_RLPReader.readBytes(_node.decoded[_node.decoded.length - 1]);
    }

    /**
     * @notice Computes the node hash for an encoded node. Nodes < 32 bytes
     * are not hashed, all others are keccak256 hashed.
     * @param _encoded Encoded node to hash.
     * @return _hash Hash of the encoded node. Simply the input if < 32 bytes.
     */
    function _getNodeHash(
        bytes memory _encoded
    )
        private
        pure
        returns (
            bytes memory _hash
        )
    {
        if (_encoded.length < 32) {
            return _encoded;
        } else {
            return abi.encodePacked(keccak256(_encoded));
        }
    }

    /**
     * @notice Determines the type for a given node.
     * @param _node Node to determine a type for.
     * @return _type Type of the node; BranchNode/ExtensionNode/LeafNode.
     */
    function _getNodeType(
        TrieNode memory _node
    )
        private
        pure
        returns (
            NodeType _type
        )
    {
        if (_node.decoded.length == BRANCH_NODE_LENGTH) {
            return NodeType.BranchNode;
        } else if (_node.decoded.length == LEAF_OR_EXTENSION_NODE_LENGTH) {
            bytes memory path = _getNodePath(_node);
            uint8 prefix = uint8(path[0]);

            if (prefix == PREFIX_LEAF_EVEN || prefix == PREFIX_LEAF_ODD) {
                return NodeType.LeafNode;
            } else if (prefix == PREFIX_EXTENSION_EVEN || prefix == PREFIX_EXTENSION_ODD) {
                return NodeType.ExtensionNode;
            }
        }

        revert("Invalid node type");
    }

    /**
     * @notice Utility; determines the number of nibbles shared between two
     * nibble arrays.
     * @param _a First nibble array.
     * @param _b Second nibble array.
     * @return _shared Number of shared nibbles.
     */
    function _getSharedNibbleLength(
        bytes memory _a,
        bytes memory _b
    )
        private
        pure
        returns (
            uint256 _shared
        )
    {
        uint256 i = 0;
        while (_a.length > i && _b.length > i && _a[i] == _b[i]) {
            i++;
        }
        return i;
    }

    /**
     * @notice Utility; converts an RLP-encoded node into our nice struct.
     * @param _raw RLP-encoded node to convert.
     * @return _node Node as a TrieNode struct.
     */
    function _makeNode(
        bytes[] memory _raw
    )
        private
        pure
        returns (
            TrieNode memory _node
        )
    {
        bytes memory encoded = Lib_RLPWriter.writeList(_raw);

        return TrieNode({
            encoded: encoded,
            decoded: Lib_RLPReader.readList(encoded)
        });
    }

    /**
     * @notice Utility; converts an RLP-decoded node into our nice struct.
     * @param _items RLP-decoded node to convert.
     * @return _node Node as a TrieNode struct.
     */
    function _makeNode(
        Lib_RLPReader.RLPItem[] memory _items
    )
        private
        pure
        returns (
            TrieNode memory _node
        )
    {
        bytes[] memory raw = new bytes[](_items.length);
        for (uint256 i = 0; i < _items.length; i++) {
            raw[i] = Lib_RLPReader.readRawBytes(_items[i]);
        }
        return _makeNode(raw);
    }

    /**
     * @notice Creates a new extension node.
     * @param _key Key for the extension node, unprefixed.
     * @param _value Value for the extension node.
     * @return _node New extension node with the given k/v pair.
     */
    function _makeExtensionNode(
        bytes memory _key,
        bytes memory _value
    )
        private
        pure
        returns (
            TrieNode memory _node
        )
    {
        bytes[] memory raw = new bytes[](2);
        bytes memory key = _addHexPrefix(_key, false);
        raw[0] = Lib_RLPWriter.writeBytes(Lib_BytesUtils.fromNibbles(key));
        raw[1] = Lib_RLPWriter.writeBytes(_value);
        return _makeNode(raw);
    }

    /**
     * Creates a new extension node with the same key but a different value.
     * @param _node Extension node to copy and modify.
     * @param _value New value for the extension node.
     * @return New node with the same key and different value.
     */
    function _editExtensionNodeValue(
        TrieNode memory _node,
        bytes memory _value
    )
        private
        pure
        returns (
            TrieNode memory
        )
    {
        bytes[] memory raw = new bytes[](2);
        bytes memory key = _addHexPrefix(_getNodeKey(_node), false);
        raw[0] = Lib_RLPWriter.writeBytes(Lib_BytesUtils.fromNibbles(key));
        if (_value.length < 32) {
            raw[1] = _value;
        } else {
            raw[1] = Lib_RLPWriter.writeBytes(_value);
        }
        return _makeNode(raw);
    }

    /**
     * @notice Creates a new leaf node.
     * @dev This function is essentially identical to `_makeExtensionNode`.
     * Although we could route both to a single method with a flag, it's
     * more gas efficient to keep them separate and duplicate the logic.
     * @param _key Key for the leaf node, unprefixed.
     * @param _value Value for the leaf node.
     * @return _node New leaf node with the given k/v pair.
     */
    function _makeLeafNode(
        bytes memory _key,
        bytes memory _value
    )
        private
        pure
        returns (
            TrieNode memory _node
        )
    {
        bytes[] memory raw = new bytes[](2);
        bytes memory key = _addHexPrefix(_key, true);
        raw[0] = Lib_RLPWriter.writeBytes(Lib_BytesUtils.fromNibbles(key));
        raw[1] = Lib_RLPWriter.writeBytes(_value);
        return _makeNode(raw);
    }

    /**
     * @notice Creates an empty branch node.
     * @return _node Empty branch node as a TrieNode struct.
     */
    function _makeEmptyBranchNode()
        private
        pure
        returns (
            TrieNode memory _node
        )
    {
        bytes[] memory raw = new bytes[](BRANCH_NODE_LENGTH);
        for (uint256 i = 0; i < raw.length; i++) {
            raw[i] = RLP_NULL_BYTES;
        }
        return _makeNode(raw);
    }

    /**
     * @notice Modifies the value slot for a given branch.
     * @param _branch Branch node to modify.
     * @param _value Value to insert into the branch.
     * @return _updatedNode Modified branch node.
     */
    function _editBranchValue(
        TrieNode memory _branch,
        bytes memory _value
    )
        private
        pure
        returns (
            TrieNode memory _updatedNode
        )
    {
        bytes memory encoded = Lib_RLPWriter.writeBytes(_value);
        _branch.decoded[_branch.decoded.length - 1] = Lib_RLPReader.toRLPItem(encoded);
        return _makeNode(_branch.decoded);
    }

    /**
     * @notice Modifies a slot at an index for a given branch.
     * @param _branch Branch node to modify.
     * @param _index Slot index to modify.
     * @param _value Value to insert into the slot.
     * @return _updatedNode Modified branch node.
     */
    function _editBranchIndex(
        TrieNode memory _branch,
        uint8 _index,
        bytes memory _value
    )
        private
        pure
        returns (
            TrieNode memory _updatedNode
        )
    {
        bytes memory encoded = _value.length < 32 ? _value : Lib_RLPWriter.writeBytes(_value);
        _branch.decoded[_index] = Lib_RLPReader.toRLPItem(encoded);
        return _makeNode(_branch.decoded);
    }

    /**
     * @notice Utility; adds a prefix to a key.
     * @param _key Key to prefix.
     * @param _isLeaf Whether or not the key belongs to a leaf.
     * @return _prefixedKey Prefixed key.
     */
    function _addHexPrefix(
        bytes memory _key,
        bool _isLeaf
    )
        private
        pure
        returns (
            bytes memory _prefixedKey
        )
    {
        uint8 prefix = _isLeaf ? uint8(0x02) : uint8(0x00);
        uint8 offset = uint8(_key.length % 2);
        bytes memory prefixed = new bytes(2 - offset);
        prefixed[0] = bytes1(prefix + offset);
        return abi.encodePacked(prefixed, _key);
    }

    /**
     * @notice Utility; removes a prefix from a path.
     * @param _path Path to remove the prefix from.
     * @return _unprefixedKey Unprefixed key.
     */
    function _removeHexPrefix(
        bytes memory _path
    )
        private
        pure
        returns (
            bytes memory _unprefixedKey
        )
    {
        if (uint8(_path[0]) % 2 == 0) {
            return Lib_BytesUtils.slice(_path, 2);
        } else {
            return Lib_BytesUtils.slice(_path, 1);
        }
    }

    /**
     * @notice Utility; combines two node arrays. Array lengths are required
     * because the actual lengths may be longer than the filled lengths.
     * Array resizing is extremely costly and should be avoided.
     * @param _a First array to join.
     * @param _aLength Length of the first array.
     * @param _b Second array to join.
     * @param _bLength Length of the second array.
     * @return _joined Combined node array.
     */
    function _joinNodeArrays(
        TrieNode[] memory _a,
        uint256 _aLength,
        TrieNode[] memory _b,
        uint256 _bLength
    )
        private
        pure
        returns (
            TrieNode[] memory _joined
        )
    {
        TrieNode[] memory ret = new TrieNode[](_aLength + _bLength);

        // Copy elements from the first array.
        for (uint256 i = 0; i < _aLength; i++) {
            ret[i] = _a[i];
        }

        // Copy elements from the second array.
        for (uint256 i = 0; i < _bLength; i++) {
            ret[i + _aLength] = _b[i];
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";

/* Interface Imports */
import { iOVM_StateTransitioner } from "../../iOVM/verification/iOVM_StateTransitioner.sol";
import { iOVM_StateTransitionerFactory } from
    "../../iOVM/verification/iOVM_StateTransitionerFactory.sol";
import { iOVM_FraudVerifier } from "../../iOVM/verification/iOVM_FraudVerifier.sol";

/* Contract Imports */
import { OVM_StateTransitioner } from "./OVM_StateTransitioner.sol";

/**
 * @title OVM_StateTransitionerFactory
 * @dev The State Transitioner Factory is used by the Fraud Verifier to create a new State
 * Transitioner during the initialization of a fraud proof.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_StateTransitionerFactory is iOVM_StateTransitionerFactory, Lib_AddressResolver {

    /***************
     * Constructor *
     ***************/

    constructor(
        address _libAddressManager
    )
        Lib_AddressResolver(_libAddressManager)
    {}


    /********************
     * Public Functions *
     ********************/

    /**
     * Creates a new OVM_StateTransitioner
     * @param _libAddressManager Address of the Address Manager.
     * @param _stateTransitionIndex Index of the state transition being verified.
     * @param _preStateRoot State root before the transition was executed.
     * @param _transactionHash Hash of the executed transaction.
     * @return New OVM_StateTransitioner instance.
     */
    function create(
        address _libAddressManager,
        uint256 _stateTransitionIndex,
        bytes32 _preStateRoot,
        bytes32 _transactionHash
    )
        override
        public
        returns (
            iOVM_StateTransitioner
        )
    {
        require(
            msg.sender == resolve("OVM_FraudVerifier"),
            "Create can only be done by the OVM_FraudVerifier."
        );

        return new OVM_StateTransitioner(
            _libAddressManager,
            _stateTransitionIndex,
            _preStateRoot,
            _transactionHash
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Contract Imports */
import { iOVM_StateTransitioner } from "./iOVM_StateTransitioner.sol";

/**
 * @title iOVM_StateTransitionerFactory
 */
interface iOVM_StateTransitionerFactory {

    /***************************************
     * Public Functions: Contract Creation *
     ***************************************/

    function create(
        address _proxyManager,
        uint256 _stateTransitionIndex,
        bytes32 _preStateRoot,
        bytes32 _transactionHash
    )
        external
        returns (
            iOVM_StateTransitioner _ovmStateTransitioner
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/* Interface Imports */
import { iOVM_StateTransitioner } from "./iOVM_StateTransitioner.sol";

/**
 * @title iOVM_FraudVerifier
 */
interface iOVM_FraudVerifier {

    /**********
     * Events *
     **********/

    event FraudProofInitialized(
        bytes32 _preStateRoot,
        uint256 _preStateRootIndex,
        bytes32 _transactionHash,
        address _who
    );

    event FraudProofFinalized(
        bytes32 _preStateRoot,
        uint256 _preStateRootIndex,
        bytes32 _transactionHash,
        address _who
    );


    /***************************************
     * Public Functions: Transition Status *
     ***************************************/

    function getStateTransitioner(bytes32 _preStateRoot, bytes32 _txHash) external view
        returns (iOVM_StateTransitioner _transitioner);


    /****************************************
     * Public Functions: Fraud Verification *
     ****************************************/

    function initializeFraudVerification(
        bytes32 _preStateRoot,
        Lib_OVMCodec.ChainBatchHeader calldata _preStateRootBatchHeader,
        Lib_OVMCodec.ChainInclusionProof calldata _preStateRootProof,
        Lib_OVMCodec.Transaction calldata _transaction,
        Lib_OVMCodec.TransactionChainElement calldata _txChainElement,
        Lib_OVMCodec.ChainBatchHeader calldata _transactionBatchHeader,
        Lib_OVMCodec.ChainInclusionProof calldata _transactionProof
    ) external;

    function finalizeFraudVerification(
        bytes32 _preStateRoot,
        Lib_OVMCodec.ChainBatchHeader calldata _preStateRootBatchHeader,
        Lib_OVMCodec.ChainInclusionProof calldata _preStateRootProof,
        bytes32 _txHash,
        bytes32 _postStateRoot,
        Lib_OVMCodec.ChainBatchHeader calldata _postStateRootBatchHeader,
        Lib_OVMCodec.ChainInclusionProof calldata _postStateRootProof
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";

/* Interface Imports */
import { iOVM_FraudVerifier } from "../../iOVM/verification/iOVM_FraudVerifier.sol";
import { iOVM_StateTransitioner } from "../../iOVM/verification/iOVM_StateTransitioner.sol";
import { iOVM_StateTransitionerFactory } from
    "../../iOVM/verification/iOVM_StateTransitionerFactory.sol";
import { iOVM_BondManager } from "../../iOVM/verification/iOVM_BondManager.sol";
import { iOVM_StateCommitmentChain } from "../../iOVM/chain/iOVM_StateCommitmentChain.sol";
import { iOVM_CanonicalTransactionChain } from
    "../../iOVM/chain/iOVM_CanonicalTransactionChain.sol";

/* Contract Imports */
import { Abs_FraudContributor } from "./Abs_FraudContributor.sol";



/**
 * @title OVM_FraudVerifier
 * @dev The Fraud Verifier contract coordinates the entire fraud proof verification process.
 * If the fraud proof was successful it prunes any state batches from State Commitment Chain
 * which were published after the fraudulent state root.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_FraudVerifier is Lib_AddressResolver, Abs_FraudContributor, iOVM_FraudVerifier {

    /*******************************************
     * Contract Variables: Internal Accounting *
     *******************************************/

    mapping (bytes32 => iOVM_StateTransitioner) internal transitioners;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    constructor(
        address _libAddressManager
    )
        Lib_AddressResolver(_libAddressManager)
    {}


    /***************************************
     * Public Functions: Transition Status *
     ***************************************/

    /**
     * Retrieves the state transitioner for a given root.
     * @param _preStateRoot State root to query a transitioner for.
     * @return _transitioner Corresponding state transitioner contract.
     */
    function getStateTransitioner(
        bytes32 _preStateRoot,
        bytes32 _txHash
    )
        override
        public
        view
        returns (
            iOVM_StateTransitioner _transitioner
        )
    {
        return transitioners[keccak256(abi.encodePacked(_preStateRoot, _txHash))];
    }


    /****************************************
     * Public Functions: Fraud Verification *
     ****************************************/

    /**
     * Begins the fraud verification process.
     * @param _preStateRoot State root before the fraudulent transaction.
     * @param _preStateRootBatchHeader Batch header for the provided pre-state root.
     * @param _preStateRootProof Inclusion proof for the provided pre-state root.
     * @param _transaction OVM transaction claimed to be fraudulent.
     * @param _txChainElement OVM transaction chain element.
     * @param _transactionBatchHeader Batch header for the provided transaction.
     * @param _transactionProof Inclusion proof for the provided transaction.
     */
    function initializeFraudVerification(
        bytes32 _preStateRoot,
        Lib_OVMCodec.ChainBatchHeader memory _preStateRootBatchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _preStateRootProof,
        Lib_OVMCodec.Transaction memory _transaction,
        Lib_OVMCodec.TransactionChainElement memory _txChainElement,
        Lib_OVMCodec.ChainBatchHeader memory _transactionBatchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _transactionProof
    )
        override
        public
        contributesToFraudProof(_preStateRoot, Lib_OVMCodec.hashTransaction(_transaction))
    {
        bytes32 _txHash = Lib_OVMCodec.hashTransaction(_transaction);

        if (_hasStateTransitioner(_preStateRoot, _txHash)) {
            return;
        }

        iOVM_StateCommitmentChain ovmStateCommitmentChain =
            iOVM_StateCommitmentChain(resolve("OVM_StateCommitmentChain"));
        iOVM_CanonicalTransactionChain ovmCanonicalTransactionChain =
            iOVM_CanonicalTransactionChain(resolve("OVM_CanonicalTransactionChain"));

        require(
            ovmStateCommitmentChain.verifyStateCommitment(
                _preStateRoot,
                _preStateRootBatchHeader,
                _preStateRootProof
            ),
            "Invalid pre-state root inclusion proof."
        );

        require(
            ovmCanonicalTransactionChain.verifyTransaction(
                _transaction,
                _txChainElement,
                _transactionBatchHeader,
                _transactionProof
            ),
            "Invalid transaction inclusion proof."
        );

        require (
            // solhint-disable-next-line max-line-length
            _preStateRootBatchHeader.prevTotalElements + _preStateRootProof.index + 1 == _transactionBatchHeader.prevTotalElements + _transactionProof.index,
            "Pre-state root global index must equal to the transaction root global index."
        );

        _deployTransitioner(_preStateRoot, _txHash, _preStateRootProof.index);

        emit FraudProofInitialized(
            _preStateRoot,
            _preStateRootProof.index,
            _txHash,
            msg.sender
        );
    }

    /**
     * Finalizes the fraud verification process.
     * @param _preStateRoot State root before the fraudulent transaction.
     * @param _preStateRootBatchHeader Batch header for the provided pre-state root.
     * @param _preStateRootProof Inclusion proof for the provided pre-state root.
     * @param _txHash The transaction for the state root
     * @param _postStateRoot State root after the fraudulent transaction.
     * @param _postStateRootBatchHeader Batch header for the provided post-state root.
     * @param _postStateRootProof Inclusion proof for the provided post-state root.
     */
    function finalizeFraudVerification(
        bytes32 _preStateRoot,
        Lib_OVMCodec.ChainBatchHeader memory _preStateRootBatchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _preStateRootProof,
        bytes32 _txHash,
        bytes32 _postStateRoot,
        Lib_OVMCodec.ChainBatchHeader memory _postStateRootBatchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _postStateRootProof
    )
        override
        public
        contributesToFraudProof(_preStateRoot, _txHash)
    {
        iOVM_StateTransitioner transitioner = getStateTransitioner(_preStateRoot, _txHash);
        iOVM_StateCommitmentChain ovmStateCommitmentChain =
            iOVM_StateCommitmentChain(resolve("OVM_StateCommitmentChain"));

        require(
            transitioner.isComplete() == true,
            "State transition process must be completed prior to finalization."
        );

        require (
            // solhint-disable-next-line max-line-length
            _postStateRootBatchHeader.prevTotalElements + _postStateRootProof.index == _preStateRootBatchHeader.prevTotalElements + _preStateRootProof.index + 1,
            "Post-state root global index must equal to the pre state root global index plus one."
        );

        require(
            ovmStateCommitmentChain.verifyStateCommitment(
                _preStateRoot,
                _preStateRootBatchHeader,
                _preStateRootProof
            ),
            "Invalid pre-state root inclusion proof."
        );

        require(
            ovmStateCommitmentChain.verifyStateCommitment(
                _postStateRoot,
                _postStateRootBatchHeader,
                _postStateRootProof
            ),
            "Invalid post-state root inclusion proof."
        );

        // If the post state root did not match, then there was fraud and we should delete the batch
        require(
            _postStateRoot != transitioner.getPostStateRoot(),
            "State transition has not been proven fraudulent."
        );

        _cancelStateTransition(_postStateRootBatchHeader, _preStateRoot);

        // TEMPORARY: Remove the transitioner; for minnet.
        transitioners[keccak256(abi.encodePacked(_preStateRoot, _txHash))] =
            iOVM_StateTransitioner(0x0000000000000000000000000000000000000000);

        emit FraudProofFinalized(
            _preStateRoot,
            _preStateRootProof.index,
            _txHash,
            msg.sender
        );
    }


    /************************************
     * Internal Functions: Verification *
     ************************************/

    /**
     * Checks whether a transitioner already exists for a given pre-state root.
     * @param _preStateRoot Pre-state root to check.
     * @return _exists Whether or not we already have a transitioner for the root.
     */
    function _hasStateTransitioner(
        bytes32 _preStateRoot,
        bytes32 _txHash
    )
        internal
        view
        returns (
            bool _exists
        )
    {
        return address(getStateTransitioner(_preStateRoot, _txHash)) != address(0);
    }

    /**
     * Deploys a new state transitioner.
     * @param _preStateRoot Pre-state root to initialize the transitioner with.
     * @param _txHash Hash of the transaction this transitioner will execute.
     * @param _stateTransitionIndex Index of the transaction in the chain.
     */
    function _deployTransitioner(
        bytes32 _preStateRoot,
        bytes32 _txHash,
        uint256 _stateTransitionIndex
    )
        internal
    {
        transitioners[keccak256(abi.encodePacked(_preStateRoot, _txHash))] =
            iOVM_StateTransitionerFactory(
                resolve("OVM_StateTransitionerFactory")
            ).create(
                address(libAddressManager),
                _stateTransitionIndex,
                _preStateRoot,
                _txHash
            );
    }

    /**
     * Removes a state transition from the state commitment chain.
     * @param _postStateRootBatchHeader Header for the post-state root.
     * @param _preStateRoot Pre-state root hash.
     */
    function _cancelStateTransition(
        Lib_OVMCodec.ChainBatchHeader memory _postStateRootBatchHeader,
        bytes32 _preStateRoot
    )
        internal
    {
        iOVM_StateCommitmentChain ovmStateCommitmentChain =
            iOVM_StateCommitmentChain(resolve("OVM_StateCommitmentChain"));
        iOVM_BondManager ovmBondManager = iOVM_BondManager(resolve("OVM_BondManager"));

        // Delete the state batch.
        ovmStateCommitmentChain.deleteStateBatch(
            _postStateRootBatchHeader
        );

        // Get the timestamp and publisher for that block.
        (uint256 timestamp, address publisher) =
            abi.decode(_postStateRootBatchHeader.extraData, (uint256, address));

        // Slash the bonds at the bond manager.
        ovmBondManager.finalize(
            _preStateRoot,
            publisher,
            timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/**
 * @title iOVM_StateCommitmentChain
 */
interface iOVM_StateCommitmentChain {

    /**********
     * Events *
     **********/

    event StateBatchAppended(
        uint256 indexed _batchIndex,
        bytes32 _batchRoot,
        uint256 _batchSize,
        uint256 _prevTotalElements,
        bytes _extraData
    );

    event StateBatchDeleted(
        uint256 indexed _batchIndex,
        bytes32 _batchRoot
    );


    /********************
     * Public Functions *
     ********************/

    /**
     * Retrieves the total number of elements submitted.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElements()
        external
        view
        returns (
            uint256 _totalElements
        );

    /**
     * Retrieves the total number of batches submitted.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatches()
        external
        view
        returns (
            uint256 _totalBatches
        );

    /**
     * Retrieves the timestamp of the last batch submitted by the sequencer.
     * @return _lastSequencerTimestamp Last sequencer batch timestamp.
     */
    function getLastSequencerTimestamp()
        external
        view
        returns (
            uint256 _lastSequencerTimestamp
        );

    /**
     * Appends a batch of state roots to the chain.
     * @param _batch Batch of state roots.
     * @param _shouldStartAtElement Index of the element at which this batch should start.
     */
    function appendStateBatch(
        bytes32[] calldata _batch,
        uint256 _shouldStartAtElement
    )
        external;

    /**
     * Deletes all state roots after (and including) a given batch.
     * @param _batchHeader Header of the batch to start deleting from.
     */
    function deleteStateBatch(
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        external;

    /**
     * Verifies a batch inclusion proof.
     * @param _element Hash of the element to verify a proof for.
     * @param _batchHeader Header of the batch in which the element was included.
     * @param _proof Merkle inclusion proof for the element.
     */
    function verifyStateCommitment(
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    )
        external
        view
        returns (
            bool _verified
        );

    /**
     * Checks whether a given batch is still inside its fraud proof window.
     * @param _batchHeader Header of the batch to check.
     * @return _inside Whether or not the batch is inside the fraud proof window.
     */
    function insideFraudProofWindow(
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        external
        view
        returns (
            bool _inside
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/* Interface Imports */
import { iOVM_ChainStorageContainer } from "./iOVM_ChainStorageContainer.sol";

/**
 * @title iOVM_CanonicalTransactionChain
 */
interface iOVM_CanonicalTransactionChain {

    /**********
     * Events *
     **********/

    event TransactionEnqueued(
        address _l1TxOrigin,
        address _target,
        uint256 _gasLimit,
        bytes _data,
        uint256 _queueIndex,
        uint256 _timestamp
    );

    event QueueBatchAppended(
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event SequencerBatchAppended(
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event TransactionBatchAppended(
        uint256 indexed _batchIndex,
        bytes32 _batchRoot,
        uint256 _batchSize,
        uint256 _prevTotalElements,
        bytes _extraData
    );


    /***********
     * Structs *
     ***********/

    struct BatchContext {
        uint256 numSequencedTransactions;
        uint256 numSubsequentQueueTransactions;
        uint256 timestamp;
        uint256 blockNumber;
    }


    /********************
     * Public Functions *
     ********************/


    /**
     * Accesses the batch storage container.
     * @return Reference to the batch storage container.
     */
    function batches()
        external
        view
        returns (
            iOVM_ChainStorageContainer
        );

    /**
     * Accesses the queue storage container.
     * @return Reference to the queue storage container.
     */
    function queue()
        external
        view
        returns (
            iOVM_ChainStorageContainer
        );

    /**
     * Retrieves the total number of elements submitted.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElements()
        external
        view
        returns (
            uint256 _totalElements
        );

    /**
     * Retrieves the total number of batches submitted.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatches()
        external
        view
        returns (
            uint256 _totalBatches
        );

    /**
     * Returns the index of the next element to be enqueued.
     * @return Index for the next queue element.
     */
    function getNextQueueIndex()
        external
        view
        returns (
            uint40
        );

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function getQueueElement(
        uint256 _index
    )
        external
        view
        returns (
            Lib_OVMCodec.QueueElement memory _element
        );

    /**
     * Returns the timestamp of the last transaction.
     * @return Timestamp for the last transaction.
     */
    function getLastTimestamp()
        external
        view
        returns (
            uint40
        );

    /**
     * Returns the blocknumber of the last transaction.
     * @return Blocknumber for the last transaction.
     */
    function getLastBlockNumber()
        external
        view
        returns (
            uint40
        );

    /**
     * Get the number of queue elements which have not yet been included.
     * @return Number of pending queue elements.
     */
    function getNumPendingQueueElements()
        external
        view
        returns (
            uint40
        );

    /**
     * Retrieves the length of the queue, including
     * both pending and canonical transactions.
     * @return Length of the queue.
     */
    function getQueueLength()
        external
        view
        returns (
            uint40
        );


    /**
     * Adds a transaction to the queue.
     * @param _target Target contract to send the transaction to.
     * @param _gasLimit Gas limit for the given transaction.
     * @param _data Transaction data.
     */
    function enqueue(
        address _target,
        uint256 _gasLimit,
        bytes memory _data
    )
        external;

    /**
     * Appends a given number of queued transactions as a single batch.
     * @param _numQueuedTransactions Number of transactions to append.
     */
    function appendQueueBatch(
        uint256 _numQueuedTransactions
    )
        external;

    /**
     * Allows the sequencer to append a batch of transactions.
     * @dev This function uses a custom encoding scheme for efficiency reasons.
     * .param _shouldStartAtElement Specific batch we expect to start appending to.
     * .param _totalElementsToAppend Total number of batch elements we expect to append.
     * .param _contexts Array of batch contexts.
     * .param _transactionDataFields Array of raw transaction data.
     */
    function appendSequencerBatch(
        // uint40 _shouldStartAtElement,
        // uint24 _totalElementsToAppend,
        // BatchContext[] _contexts,
        // bytes[] _transactionDataFields
    )
        external;

    /**
     * Verifies whether a transaction is included in the chain.
     * @param _transaction Transaction to verify.
     * @param _txChainElement Transaction chain element corresponding to the transaction.
     * @param _batchHeader Header of the batch the transaction was included in.
     * @param _inclusionProof Inclusion proof for the provided transaction chain element.
     * @return True if the transaction exists in the CTC, false if not.
     */
    function verifyTransaction(
        Lib_OVMCodec.Transaction memory _transaction,
        Lib_OVMCodec.TransactionChainElement memory _txChainElement,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _inclusionProof
    )
        external
        view
        returns (
            bool
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iOVM_ChainStorageContainer
 */
interface iOVM_ChainStorageContainer {

    /********************
     * Public Functions *
     ********************/

    /**
     * Sets the container's global metadata field. We're using `bytes27` here because we use five
     * bytes to maintain the length of the underlying data structure, meaning we have an extra
     * 27 bytes to store arbitrary data.
     * @param _globalMetadata New global metadata to set.
     */
    function setGlobalMetadata(
        bytes27 _globalMetadata
    )
        external;

    /**
     * Retrieves the container's global metadata field.
     * @return Container global metadata field.
     */
    function getGlobalMetadata()
        external
        view
        returns (
            bytes27
        );

    /**
     * Retrieves the number of objects stored in the container.
     * @return Number of objects in the container.
     */
    function length()
        external
        view
        returns (
            uint256
        );

    /**
     * Pushes an object into the container.
     * @param _object A 32 byte value to insert into the container.
     */
    function push(
        bytes32 _object
    )
        external;

    /**
     * Pushes an object into the container. Function allows setting the global metadata since
     * we'll need to touch the "length" storage slot anyway, which also contains the global
     * metadata (it's an optimization).
     * @param _object A 32 byte value to insert into the container.
     * @param _globalMetadata New global metadata for the container.
     */
    function push(
        bytes32 _object,
        bytes27 _globalMetadata
    )
        external;

    /**
     * Retrieves an object from the container.
     * @param _index Index of the particular object to access.
     * @return 32 byte object value.
     */
    function get(
        uint256 _index
    )
        external
        view
        returns (
            bytes32
        );

    /**
     * Removes all objects after and including a given index.
     * @param _index Object index to delete from.
     */
    function deleteElementsAfterInclusive(
        uint256 _index
    )
        external;

    /**
     * Removes all objects after and including a given index. Also allows setting the global
     * metadata field.
     * @param _index Object index to delete from.
     * @param _globalMetadata New global metadata for the container.
     */
    function deleteElementsAfterInclusive(
        uint256 _index,
        bytes27 _globalMetadata
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";

/* Interface Imports */
import { iOVM_BondManager, Errors, ERC20 } from "../../iOVM/verification/iOVM_BondManager.sol";
import { iOVM_FraudVerifier } from "../../iOVM/verification/iOVM_FraudVerifier.sol";

/**
 * @title OVM_BondManager
 * @dev The Bond Manager contract handles deposits in the form of an ERC20 token from bonded
 * Proposers. It also handles the accounting of gas costs spent by a Verifier during the course of a
 * fraud proof. In the event of a successful fraud proof, the fraudulent Proposer's bond is slashed,
 * and the Verifier's gas costs are refunded.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_BondManager is iOVM_BondManager, Lib_AddressResolver {

    /****************************
     * Constants and Parameters *
     ****************************/

    /// The period to find the earliest fraud proof for a publisher
    uint256 public constant multiFraudProofPeriod = 7 days;

    /// The dispute period
    uint256 public constant disputePeriodSeconds = 7 days;

    /// The minimum collateral a sequencer must post
    uint256 public constant requiredCollateral = 1 ether;


    /*******************************************
     * Contract Variables: Contract References *
     *******************************************/

    /// The bond token
    ERC20 immutable public token;


    /********************************************
     * Contract Variables: Internal Accounting  *
     *******************************************/

    /// The bonds posted by each proposer
    mapping(address => Bond) public bonds;

    /// For each pre-state root, there's an array of witnessProviders that must be rewarded
    /// for posting witnesses
    mapping(bytes32 => Rewards) public witnessProviders;


    /***************
     * Constructor *
     ***************/

    /// Initializes with a ERC20 token to be used for the fidelity bonds
    /// and with the Address Manager
    constructor(
        ERC20 _token,
        address _libAddressManager
    )
        Lib_AddressResolver(_libAddressManager)
    {
        token = _token;
    }


    /********************
     * Public Functions *
     ********************/

    /// Adds `who` to the list of witnessProviders for the provided `preStateRoot`.
    function recordGasSpent(bytes32 _preStateRoot, bytes32 _txHash, address who, uint256 gasSpent)
    override public {
        // The sender must be the transitioner that corresponds to the claimed pre-state root
        address transitioner =
            address(iOVM_FraudVerifier(resolve("OVM_FraudVerifier"))
            .getStateTransitioner(_preStateRoot, _txHash));
        require(transitioner == msg.sender, Errors.ONLY_TRANSITIONER);

        witnessProviders[_preStateRoot].total += gasSpent;
        witnessProviders[_preStateRoot].gasSpent[who] += gasSpent;
    }

    /// Slashes + distributes rewards or frees up the sequencer's bond, only called by
    /// `FraudVerifier.finalizeFraudVerification`
    function finalize(bytes32 _preStateRoot, address publisher, uint256 timestamp) override public {
        require(msg.sender == resolve("OVM_FraudVerifier"), Errors.ONLY_FRAUD_VERIFIER);
        require(witnessProviders[_preStateRoot].canClaim == false, Errors.ALREADY_FINALIZED);

        // allow users to claim from that state root's
        // pool of collateral (effectively slashing the sequencer)
        witnessProviders[_preStateRoot].canClaim = true;

        Bond storage bond = bonds[publisher];
        if (bond.firstDisputeAt == 0) {
            bond.firstDisputeAt = block.timestamp;
            bond.earliestDisputedStateRoot = _preStateRoot;
            bond.earliestTimestamp = timestamp;
        } else if (
            // only update the disputed state root for the publisher if it's within
            // the dispute period _and_ if it's before the previous one
            block.timestamp < bond.firstDisputeAt + multiFraudProofPeriod &&
            timestamp < bond.earliestTimestamp
        ) {
            bond.earliestDisputedStateRoot = _preStateRoot;
            bond.earliestTimestamp = timestamp;
        }

        // if the fraud proof's dispute period does not intersect with the
        // withdrawal's timestamp, then the user should not be slashed
        // e.g if a user at day 10 submits a withdrawal, and a fraud proof
        // from day 1 gets published, the user won't be slashed since day 8 (1d + 7d)
        // is before the user started their withdrawal. on the contrary, if the user
        // had started their withdrawal at, say, day 6, they would be slashed
        if (
            bond.withdrawalTimestamp != 0 &&
            uint256(bond.withdrawalTimestamp) > timestamp + disputePeriodSeconds &&
            bond.state == State.WITHDRAWING
        ) {
            return;
        }

        // slash!
        bond.state = State.NOT_COLLATERALIZED;
    }

    /// Sequencers call this function to post collateral which will be used for
    /// the `appendBatch` call
    function deposit() override public {
        require(
            token.transferFrom(msg.sender, address(this), requiredCollateral),
            Errors.ERC20_ERR
        );

        // This cannot overflow
        bonds[msg.sender].state = State.COLLATERALIZED;
    }

    /// Starts the withdrawal for a publisher
    function startWithdrawal() override public {
        Bond storage bond = bonds[msg.sender];
        require(bond.withdrawalTimestamp == 0, Errors.WITHDRAWAL_PENDING);
        require(bond.state == State.COLLATERALIZED, Errors.WRONG_STATE);

        bond.state = State.WITHDRAWING;
        bond.withdrawalTimestamp = uint32(block.timestamp);
    }

    /// Finalizes a pending withdrawal from a publisher
    function finalizeWithdrawal() override public {
        Bond storage bond = bonds[msg.sender];

        require(
            block.timestamp >= uint256(bond.withdrawalTimestamp) + disputePeriodSeconds,
            Errors.TOO_EARLY
        );
        require(bond.state == State.WITHDRAWING, Errors.SLASHED);

        // refunds!
        bond.state = State.NOT_COLLATERALIZED;
        bond.withdrawalTimestamp = 0;

        require(
            token.transfer(msg.sender, requiredCollateral),
            Errors.ERC20_ERR
        );
    }

    /// Claims the user's reward for the witnesses they provided for the earliest
    /// disputed state root of the designated publisher
    function claim(address who) override public {
        Bond storage bond = bonds[who];
        require(
            block.timestamp >= bond.firstDisputeAt + multiFraudProofPeriod,
            Errors.WAIT_FOR_DISPUTES
        );

        // reward the earliest state root for this publisher
        bytes32 _preStateRoot = bond.earliestDisputedStateRoot;
        Rewards storage rewards = witnessProviders[_preStateRoot];

        // only allow claiming if fraud was proven in `finalize`
        require(rewards.canClaim, Errors.CANNOT_CLAIM);

        // proportional allocation - only reward 50% (rest gets locked in the
        // contract forever
        uint256 amount = (requiredCollateral * rewards.gasSpent[msg.sender]) / (2 * rewards.total);

        // reset the user's spent gas so they cannot double claim
        rewards.gasSpent[msg.sender] = 0;

        // transfer
        require(token.transfer(msg.sender, amount), Errors.ERC20_ERR);
    }

    /// Checks if the user is collateralized
    function isCollateralized(address who) override public view returns (bool) {
        return bonds[who].state == State.COLLATERALIZED;
    }

    /// Gets how many witnesses the user has provided for the state root
    function getGasSpent(bytes32 preStateRoot, address who) override public view returns (uint256) {
        return witnessProviders[preStateRoot].gasSpent[who];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

import { OVM_BondManager } from "./../optimistic-ethereum/OVM/verification/OVM_BondManager.sol";

contract Mock_FraudVerifier {
    OVM_BondManager bondManager;

    mapping (bytes32 => address) transitioners;

    function setBondManager(OVM_BondManager _bondManager) public {
        bondManager = _bondManager;
    }

    function setStateTransitioner(bytes32 preStateRoot, bytes32 txHash, address addr) public {
        transitioners[keccak256(abi.encodePacked(preStateRoot, txHash))] = addr;
    }

    function getStateTransitioner(
        bytes32 _preStateRoot,
        bytes32 _txHash
    )
        public
        view
        returns (
            address
        )
    {
        return transitioners[keccak256(abi.encodePacked(_preStateRoot, _txHash))];
    }

    function finalize(bytes32 _preStateRoot, address publisher, uint256 timestamp) public {
        bondManager.finalize(_preStateRoot, publisher, timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_MerkleTree } from "../../libraries/utils/Lib_MerkleTree.sol";

/* Interface Imports */
import { iOVM_FraudVerifier } from "../../iOVM/verification/iOVM_FraudVerifier.sol";
import { iOVM_StateCommitmentChain } from "../../iOVM/chain/iOVM_StateCommitmentChain.sol";
import { iOVM_CanonicalTransactionChain } from
    "../../iOVM/chain/iOVM_CanonicalTransactionChain.sol";
import { iOVM_BondManager } from "../../iOVM/verification/iOVM_BondManager.sol";
import { iOVM_ChainStorageContainer } from "../../iOVM/chain/iOVM_ChainStorageContainer.sol";

/* External Imports */
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title OVM_StateCommitmentChain
 * @dev The State Commitment Chain (SCC) contract contains a list of proposed state roots which
 * Proposers assert to be a result of each transaction in the Canonical Transaction Chain (CTC).
 * Elements here have a 1:1 correspondence with transactions in the CTC, and should be the unique
 * state root calculated off-chain by applying the canonical transactions one by one.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_StateCommitmentChain is iOVM_StateCommitmentChain, Lib_AddressResolver {

    /*************
     * Constants *
     *************/

    uint256 public FRAUD_PROOF_WINDOW;
    uint256 public SEQUENCER_PUBLISH_WINDOW;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    constructor(
        address _libAddressManager,
        uint256 _fraudProofWindow,
        uint256 _sequencerPublishWindow
    )
        Lib_AddressResolver(_libAddressManager)
    {
        FRAUD_PROOF_WINDOW = _fraudProofWindow;
        SEQUENCER_PUBLISH_WINDOW = _sequencerPublishWindow;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Accesses the batch storage container.
     * @return Reference to the batch storage container.
     */
    function batches()
        public
        view
        returns (
            iOVM_ChainStorageContainer
        )
    {
        return iOVM_ChainStorageContainer(
            resolve("OVM_ChainStorageContainer-SCC-batches")
        );
    }

    /**
     * @inheritdoc iOVM_StateCommitmentChain
     */
    function getTotalElements()
        override
        public
        view
        returns (
            uint256 _totalElements
        )
    {
        (uint40 totalElements, ) = _getBatchExtraData();
        return uint256(totalElements);
    }

    /**
     * @inheritdoc iOVM_StateCommitmentChain
     */
    function getTotalBatches()
        override
        public
        view
        returns (
            uint256 _totalBatches
        )
    {
        return batches().length();
    }

    /**
     * @inheritdoc iOVM_StateCommitmentChain
     */
    function getLastSequencerTimestamp()
        override
        public
        view
        returns (
            uint256 _lastSequencerTimestamp
        )
    {
        (, uint40 lastSequencerTimestamp) = _getBatchExtraData();
        return uint256(lastSequencerTimestamp);
    }

    /**
     * @inheritdoc iOVM_StateCommitmentChain
     */
    function appendStateBatch(
        bytes32[] memory _batch,
        uint256 _shouldStartAtElement
    )
        override
        public
    {
        // Fail fast in to make sure our batch roots aren't accidentally made fraudulent by the
        // publication of batches by some other user.
        require(
            _shouldStartAtElement == getTotalElements(),
            "Actual batch start index does not match expected start index."
        );

        // Proposers must have previously staked at the BondManager
        require(
            iOVM_BondManager(resolve("OVM_BondManager")).isCollateralized(msg.sender),
            "Proposer does not have enough collateral posted"
        );

        require(
            _batch.length > 0,
            "Cannot submit an empty state batch."
        );

        require(
            getTotalElements() + _batch.length <=
                iOVM_CanonicalTransactionChain(resolve("OVM_CanonicalTransactionChain"))
                .getTotalElements(),
            "Number of state roots cannot exceed the number of canonical transactions."
        );

        // Pass the block's timestamp and the publisher of the data
        // to be used in the fraud proofs
        _appendBatch(
            _batch,
            abi.encode(block.timestamp, msg.sender)
        );
    }

    /**
     * @inheritdoc iOVM_StateCommitmentChain
     */
    function deleteStateBatch(
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        override
        public
    {
        require(
            msg.sender == resolve("OVM_FraudVerifier"),
            "State batches can only be deleted by the OVM_FraudVerifier."
        );

        require(
            _isValidBatchHeader(_batchHeader),
            "Invalid batch header."
        );

        require(
            insideFraudProofWindow(_batchHeader),
            "State batches can only be deleted within the fraud proof window."
        );

        _deleteBatch(_batchHeader);
    }

    /**
     * @inheritdoc iOVM_StateCommitmentChain
     */
    function verifyStateCommitment(
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    )
        override
        public
        view
        returns (
            bool
        )
    {
        require(
            _isValidBatchHeader(_batchHeader),
            "Invalid batch header."
        );

        require(
            Lib_MerkleTree.verify(
                _batchHeader.batchRoot,
                _element,
                _proof.index,
                _proof.siblings,
                _batchHeader.batchSize
            ),
            "Invalid inclusion proof."
        );

        return true;
    }

    /**
     * @inheritdoc iOVM_StateCommitmentChain
     */
    function insideFraudProofWindow(
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        override
        public
        view
        returns (
            bool _inside
        )
    {
        (uint256 timestamp,) = abi.decode(
            _batchHeader.extraData,
            (uint256, address)
        );

        require(
            timestamp != 0,
            "Batch header timestamp cannot be zero"
        );
        return SafeMath.add(timestamp, FRAUD_PROOF_WINDOW) > block.timestamp;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Parses the batch context from the extra data.
     * @return Total number of elements submitted.
     * @return Timestamp of the last batch submitted by the sequencer.
     */
    function _getBatchExtraData()
        internal
        view
        returns (
            uint40,
            uint40
        )
    {
        bytes27 extraData = batches().getGlobalMetadata();

        // solhint-disable max-line-length
        uint40 totalElements;
        uint40 lastSequencerTimestamp;
        assembly {
            extraData              := shr(40, extraData)
            totalElements          :=         and(extraData, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            lastSequencerTimestamp := shr(40, and(extraData, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000))
        }
        // solhint-enable max-line-length

        return (
            totalElements,
            lastSequencerTimestamp
        );
    }

    /**
     * Encodes the batch context for the extra data.
     * @param _totalElements Total number of elements submitted.
     * @param _lastSequencerTimestamp Timestamp of the last batch submitted by the sequencer.
     * @return Encoded batch context.
     */
    function _makeBatchExtraData(
        uint40 _totalElements,
        uint40 _lastSequencerTimestamp
    )
        internal
        pure
        returns (
            bytes27
        )
    {
        bytes27 extraData;
        assembly {
            extraData := _totalElements
            extraData := or(extraData, shl(40, _lastSequencerTimestamp))
            extraData := shl(40, extraData)
        }

        return extraData;
    }

    /**
     * Appends a batch to the chain.
     * @param _batch Elements within the batch.
     * @param _extraData Any extra data to append to the batch.
     */
    function _appendBatch(
        bytes32[] memory _batch,
        bytes memory _extraData
    )
        internal
    {
        address sequencer = resolve("OVM_Proposer");
        (uint40 totalElements, uint40 lastSequencerTimestamp) = _getBatchExtraData();

        if (msg.sender == sequencer) {
            lastSequencerTimestamp = uint40(block.timestamp);
        } else {
            // We keep track of the last batch submitted by the sequencer so there's a window in
            // which only the sequencer can publish state roots. A window like this just reduces
            // the chance of "system breaking" state roots being published while we're still in
            // testing mode. This window should be removed or significantly reduced in the future.
            require(
                lastSequencerTimestamp + SEQUENCER_PUBLISH_WINDOW < block.timestamp,
                "Cannot publish state roots within the sequencer publication window."
            );
        }

        // For efficiency reasons getMerkleRoot modifies the `_batch` argument in place
        // while calculating the root hash therefore any arguments passed to it must not
        // be used again afterwards
        Lib_OVMCodec.ChainBatchHeader memory batchHeader = Lib_OVMCodec.ChainBatchHeader({
            batchIndex: getTotalBatches(),
            batchRoot: Lib_MerkleTree.getMerkleRoot(_batch),
            batchSize: _batch.length,
            prevTotalElements: totalElements,
            extraData: _extraData
        });

        emit StateBatchAppended(
            batchHeader.batchIndex,
            batchHeader.batchRoot,
            batchHeader.batchSize,
            batchHeader.prevTotalElements,
            batchHeader.extraData
        );

        batches().push(
            Lib_OVMCodec.hashBatchHeader(batchHeader),
            _makeBatchExtraData(
                uint40(batchHeader.prevTotalElements + batchHeader.batchSize),
                lastSequencerTimestamp
            )
        );
    }

    /**
     * Removes a batch and all subsequent batches from the chain.
     * @param _batchHeader Header of the batch to remove.
     */
    function _deleteBatch(
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        internal
    {
        require(
            _batchHeader.batchIndex < batches().length(),
            "Invalid batch index."
        );

        require(
            _isValidBatchHeader(_batchHeader),
            "Invalid batch header."
        );

        batches().deleteElementsAfterInclusive(
            _batchHeader.batchIndex,
            _makeBatchExtraData(
                uint40(_batchHeader.prevTotalElements),
                0
            )
        );

        emit StateBatchDeleted(
            _batchHeader.batchIndex,
            _batchHeader.batchRoot
        );
    }

    /**
     * Checks that a batch header matches the stored hash for the given index.
     * @param _batchHeader Batch header to validate.
     * @return Whether or not the header matches the stored one.
     */
    function _isValidBatchHeader(
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        internal
        view
        returns (
            bool
        )
    {
        return Lib_OVMCodec.hashBatchHeader(_batchHeader) == batches().get(_batchHeader.batchIndex);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_MerkleTree
 * @author River Keefer
 */
library Lib_MerkleTree {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Calculates a merkle root for a list of 32-byte leaf hashes.  WARNING: If the number
     * of leaves passed in is not a power of two, it pads out the tree with zero hashes.
     * If you do not know the original length of elements for the tree you are verifying, then
     * this may allow empty leaves past _elements.length to pass a verification check down the line.
     * Note that the _elements argument is modified, therefore it must not be used again afterwards
     * @param _elements Array of hashes from which to generate a merkle root.
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(
        bytes32[] memory _elements
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        require(
            _elements.length > 0,
            "Lib_MerkleTree: Must provide at least one leaf hash."
        );

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[16] memory defaults = [
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
            0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
            0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
            0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
            0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
            0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
            0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
            0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
            0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
            0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
            0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
            0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
            0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
            0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
            0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
            0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10
        ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize;         // rowSize / 2
        bool rowSizeIsOdd;           // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling  = _elements[(2 * i)    ];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling )
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling  = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * Verifies a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _root The Merkle root to verify against.
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibline nodes in the inclusion proof, starting from depth 0
     * (bottom of the tree).
     * @param _totalLeaves The total number of leaves originally passed into.
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings,
        uint256 _totalLeaves
    )
        internal
        pure
        returns (
            bool
        )
    {
        require(
            _totalLeaves > 0,
            "Lib_MerkleTree: Total leaves must be greater than zero."
        );

        require(
            _index < _totalLeaves,
            "Lib_MerkleTree: Index out of bounds."
        );

        require(
            _siblings.length == _ceilLog2(_totalLeaves),
            "Lib_MerkleTree: Total siblings does not correctly correspond to total leaves."
        );

        bytes32 computedRoot = _leaf;

        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(
                    abi.encodePacked(
                        _siblings[i],
                        computedRoot
                    )
                );
            } else {
                computedRoot = keccak256(
                    abi.encodePacked(
                        computedRoot,
                        _siblings[i]
                    )
                );
            }

            _index >>= 1;
        }

        return _root == computedRoot;
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Calculates the integer ceiling of the log base 2 of an input.
     * @param _in Unsigned input to calculate the log.
     * @return ceil(log_base_2(_in))
     */
    function _ceilLog2(
        uint256 _in
    )
        private
        pure
        returns (
            uint256
        )
    {
        require(
            _in > 0,
            "Lib_MerkleTree: Cannot compute ceil(log_2) of 0."
        );

        if (_in == 1) {
            return 0;
        }

        // Find the highest set bit (will be floor(log_2)).
        // Borrowed with <3 from https://github.com/ethereum/solidity-examples
        uint256 val = _in;
        uint256 highest = 0;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (uint(1) << i) - 1 << i != 0) {
                highest += i;
                val >>= i;
            }
        }

        // Increment by one if this is not a perfect logarithm.
        if ((uint(1) << highest) != _in) {
            highest += 1;
        }

        return highest;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_Buffer } from "../../libraries/utils/Lib_Buffer.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";

/* Interface Imports */
import { iOVM_ChainStorageContainer } from "../../iOVM/chain/iOVM_ChainStorageContainer.sol";

/**
 * @title OVM_ChainStorageContainer
 * @dev The Chain Storage Container provides its owner contract with read, write and delete
 * functionality. This provides gas efficiency gains by enabling it to overwrite storage slots which
 * can no longer be used in a fraud proof due to the fraud window having passed, and the associated
 * chain state or transactions being finalized.
 * Three distinct Chain Storage Containers will be deployed on Layer 1:
 * 1. Stores transaction batches for the Canonical Transaction Chain
 * 2. Stores queued transactions for the Canonical Transaction Chain
 * 3. Stores chain state batches for the State Commitment Chain
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_ChainStorageContainer is iOVM_ChainStorageContainer, Lib_AddressResolver {

    /*************
     * Libraries *
     *************/

    using Lib_Buffer for Lib_Buffer.Buffer;


    /*************
     * Variables *
     *************/

    string public owner;
    Lib_Buffer.Buffer internal buffer;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     * @param _owner Name of the contract that owns this container (will be resolved later).
     */
    constructor(
        address _libAddressManager,
        string memory _owner
    )
        Lib_AddressResolver(_libAddressManager)
    {
        owner = _owner;
    }


    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyOwner() {
        require(
            msg.sender == resolve(owner),
            "OVM_ChainStorageContainer: Function can only be called by the owner."
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function setGlobalMetadata(
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        return buffer.setExtraData(_globalMetadata);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function getGlobalMetadata()
        override
        public
        view
        returns (
            bytes27
        )
    {
        return buffer.getExtraData();
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function length()
        override
        public
        view
        returns (
            uint256
        )
    {
        return uint256(buffer.getLength());
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function push(
        bytes32 _object
    )
        override
        public
        onlyOwner
    {
        buffer.push(_object);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function push(
        bytes32 _object,
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        buffer.push(_object, _globalMetadata);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function get(
        uint256 _index
    )
        override
        public
        view
        returns (
            bytes32
        )
    {
        return buffer.get(uint40(_index));
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function deleteElementsAfterInclusive(
        uint256 _index
    )
        override
        public
        onlyOwner
    {
        buffer.deleteElementsAfterInclusive(
            uint40(_index)
        );
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function deleteElementsAfterInclusive(
        uint256 _index,
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        buffer.deleteElementsAfterInclusive(
            uint40(_index),
            _globalMetadata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_Buffer
 * @dev This library implements a bytes32 storage array with some additional gas-optimized
 * functionality. In particular, it encodes its length as a uint40, and tightly packs this with an
 * overwritable "extra data" field so we can store more information with a single SSTORE.
 */
library Lib_Buffer {

    /*************
     * Libraries *
     *************/

    using Lib_Buffer for Buffer;


    /***********
     * Structs *
     ***********/

    struct Buffer {
        bytes32 context;
        mapping (uint256 => bytes32) buf;
    }

    struct BufferContext {
        // Stores the length of the array. Uint40 is way more elements than we'll ever reasonably
        // need in an array and we get an extra 27 bytes of extra data to play with.
        uint40 length;

        // Arbitrary extra data that can be modified whenever the length is updated. Useful for
        // squeezing out some gas optimizations.
        bytes27 extraData;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Pushes a single element to the buffer.
     * @param _self Buffer to access.
     * @param _value Value to push to the buffer.
     * @param _extraData Global extra data.
     */
    function push(
        Buffer storage _self,
        bytes32 _value,
        bytes27 _extraData
    )
        internal
    {
        BufferContext memory ctx = _self.getContext();

        _self.buf[ctx.length] = _value;

        // Bump the global index and insert our extra data, then save the context.
        ctx.length++;
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }

    /**
     * Pushes a single element to the buffer.
     * @param _self Buffer to access.
     * @param _value Value to push to the buffer.
     */
    function push(
        Buffer storage _self,
        bytes32 _value
    )
        internal
    {
        BufferContext memory ctx = _self.getContext();

        _self.push(
            _value,
            ctx.extraData
        );
    }

    /**
     * Retrieves an element from the buffer.
     * @param _self Buffer to access.
     * @param _index Element index to retrieve.
     * @return Value of the element at the given index.
     */
    function get(
        Buffer storage _self,
        uint256 _index
    )
        internal
        view
        returns (
            bytes32
        )
    {
        BufferContext memory ctx = _self.getContext();

        require(
            _index < ctx.length,
            "Index out of bounds."
        );

        return _self.buf[_index];
    }

    /**
     * Deletes all elements after (and including) a given index.
     * @param _self Buffer to access.
     * @param _index Index of the element to delete from (inclusive).
     * @param _extraData Optional global extra data.
     */
    function deleteElementsAfterInclusive(
        Buffer storage _self,
        uint40 _index,
        bytes27 _extraData
    )
        internal
    {
        BufferContext memory ctx = _self.getContext();

        require(
            _index < ctx.length,
            "Index out of bounds."
        );

        // Set our length and extra data, save the context.
        ctx.length = _index;
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }

    /**
     * Deletes all elements after (and including) a given index.
     * @param _self Buffer to access.
     * @param _index Index of the element to delete from (inclusive).
     */
    function deleteElementsAfterInclusive(
        Buffer storage _self,
        uint40 _index
    )
        internal
    {
        BufferContext memory ctx = _self.getContext();
        _self.deleteElementsAfterInclusive(
            _index,
            ctx.extraData
        );
    }

    /**
     * Retrieves the current global index.
     * @param _self Buffer to access.
     * @return Current global index.
     */
    function getLength(
        Buffer storage _self
    )
        internal
        view
        returns (
            uint40
        )
    {
        BufferContext memory ctx = _self.getContext();
        return ctx.length;
    }

    /**
     * Changes current global extra data.
     * @param _self Buffer to access.
     * @param _extraData New global extra data.
     */
    function setExtraData(
        Buffer storage _self,
        bytes27 _extraData
    )
        internal
    {
        BufferContext memory ctx = _self.getContext();
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }

    /**
     * Retrieves the current global extra data.
     * @param _self Buffer to access.
     * @return Current global extra data.
     */
    function getExtraData(
        Buffer storage _self
    )
        internal
        view
        returns (
            bytes27
        )
    {
        BufferContext memory ctx = _self.getContext();
        return ctx.extraData;
    }

    /**
     * Sets the current buffer context.
     * @param _self Buffer to access.
     * @param _ctx Current buffer context.
     */
    function setContext(
        Buffer storage _self,
        BufferContext memory _ctx
    )
        internal
    {
        bytes32 context;
        uint40 length = _ctx.length;
        bytes27 extraData = _ctx.extraData;
        assembly {
            context := length
            context := or(context, extraData)
        }

        if (_self.context != context) {
            _self.context = context;
        }
    }

    /**
     * Retrieves the current buffer context.
     * @param _self Buffer to access.
     * @return Current buffer context.
     */
    function getContext(
        Buffer storage _self
    )
        internal
        view
        returns (
            BufferContext memory
        )
    {
        bytes32 context = _self.context;
        uint40 length;
        bytes27 extraData;
        assembly {
            // solhint-disable-next-line max-line-length
            length    := and(context, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            // solhint-disable-next-line max-line-length
            extraData := and(context, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000)
        }

        return BufferContext({
            length: length,
            extraData: extraData
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_Buffer } from "../../optimistic-ethereum/libraries/utils/Lib_Buffer.sol";

/**
 * @title TestLib_Buffer
 */
contract TestLib_Buffer {
    using Lib_Buffer for Lib_Buffer.Buffer;

    Lib_Buffer.Buffer internal buf;

    function push(
        bytes32 _value,
        bytes27 _extraData
    )
        public
    {
        buf.push(
            _value,
            _extraData
        );
    }

    function get(
        uint256 _index
    )
        public
        view
        returns (
            bytes32
        )
    {
        return buf.get(_index);
    }

    function deleteElementsAfterInclusive(
        uint40 _index
    )
        public
    {
        return buf.deleteElementsAfterInclusive(
            _index
        );
    }

    function deleteElementsAfterInclusive(
        uint40 _index,
        bytes27 _extraData
    )
        public
    {
        return buf.deleteElementsAfterInclusive(
            _index,
            _extraData
        );
    }

    function getLength()
        public
        view
        returns (
            uint40
        )
    {
        return buf.getLength();
    }

    function setExtraData(
        bytes27 _extraData
    )
        public
    {
        return buf.setExtraData(
            _extraData
        );
    }

    function getExtraData()
        public
        view
        returns (
            bytes27
        )
    {
        return buf.getExtraData();
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_MerkleTree } from "../../libraries/utils/Lib_MerkleTree.sol";

/* Interface Imports */
import { iOVM_CanonicalTransactionChain } from
    "../../iOVM/chain/iOVM_CanonicalTransactionChain.sol";
import { iOVM_ChainStorageContainer } from "../../iOVM/chain/iOVM_ChainStorageContainer.sol";

/* Contract Imports */
import { OVM_ExecutionManager } from "../execution/OVM_ExecutionManager.sol";

/* External Imports */
import { Math } from "@openzeppelin/contracts/math/Math.sol";

/**
 * @title OVM_CanonicalTransactionChain
 * @dev The Canonical Transaction Chain (CTC) contract is an append-only log of transactions
 * which must be applied to the rollup state. It defines the ordering of rollup transactions by
 * writing them to the 'CTC:batches' instance of the Chain Storage Container.
 * The CTC also allows any account to 'enqueue' an L2 transaction, which will require that the
 * Sequencer will eventually append it to the rollup state.
 * If the Sequencer does not include an enqueued transaction within the 'force inclusion period',
 * then any account may force it to be included by calling appendQueueBatch().
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_CanonicalTransactionChain is iOVM_CanonicalTransactionChain, Lib_AddressResolver {

    /*************
     * Constants *
     *************/

    // L2 tx gas-related
    uint256 constant public MIN_ROLLUP_TX_GAS = 100000;
    uint256 constant public MAX_ROLLUP_TX_SIZE = 50000;
    uint256 constant public L2_GAS_DISCOUNT_DIVISOR = 32;

    // Encoding-related (all in bytes)
    uint256 constant internal BATCH_CONTEXT_SIZE = 16;
    uint256 constant internal BATCH_CONTEXT_LENGTH_POS = 12;
    uint256 constant internal BATCH_CONTEXT_START_POS = 15;
    uint256 constant internal TX_DATA_HEADER_SIZE = 3;
    uint256 constant internal BYTES_TILL_TX_DATA = 65;


    /*************
     * Variables *
     *************/

    uint256 public forceInclusionPeriodSeconds;
    uint256 public forceInclusionPeriodBlocks;
    uint256 public maxTransactionGasLimit;


    /***************
     * Constructor *
     ***************/

    constructor(
        address _libAddressManager,
        uint256 _forceInclusionPeriodSeconds,
        uint256 _forceInclusionPeriodBlocks,
        uint256 _maxTransactionGasLimit
    )
        Lib_AddressResolver(_libAddressManager)
    {
        forceInclusionPeriodSeconds = _forceInclusionPeriodSeconds;
        forceInclusionPeriodBlocks = _forceInclusionPeriodBlocks;
        maxTransactionGasLimit = _maxTransactionGasLimit;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Accesses the batch storage container.
     * @return Reference to the batch storage container.
     */
    function batches()
        override
        public
        view
        returns (
            iOVM_ChainStorageContainer
        )
    {
        return iOVM_ChainStorageContainer(
            resolve("OVM_ChainStorageContainer-CTC-batches")
        );
    }

    /**
     * Accesses the queue storage container.
     * @return Reference to the queue storage container.
     */
    function queue()
        override
        public
        view
        returns (
            iOVM_ChainStorageContainer
        )
    {
        return iOVM_ChainStorageContainer(
            resolve("OVM_ChainStorageContainer-CTC-queue")
        );
    }

    /**
     * Retrieves the total number of elements submitted.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElements()
        override
        public
        view
        returns (
            uint256 _totalElements
        )
    {
        (uint40 totalElements,,,) = _getBatchExtraData();
        return uint256(totalElements);
    }

    /**
     * Retrieves the total number of batches submitted.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatches()
        override
        public
        view
        returns (
            uint256 _totalBatches
        )
    {
        return batches().length();
    }

    /**
     * Returns the index of the next element to be enqueued.
     * @return Index for the next queue element.
     */
    function getNextQueueIndex()
        override
        public
        view
        returns (
            uint40
        )
    {
        (,uint40 nextQueueIndex,,) = _getBatchExtraData();
        return nextQueueIndex;
    }

    /**
     * Returns the timestamp of the last transaction.
     * @return Timestamp for the last transaction.
     */
    function getLastTimestamp()
        override
        public
        view
        returns (
            uint40
        )
    {
        (,,uint40 lastTimestamp,) = _getBatchExtraData();
        return lastTimestamp;
    }

    /**
     * Returns the blocknumber of the last transaction.
     * @return Blocknumber for the last transaction.
     */
    function getLastBlockNumber()
        override
        public
        view
        returns (
            uint40
        )
    {
        (,,,uint40 lastBlockNumber) = _getBatchExtraData();
        return lastBlockNumber;
    }

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function getQueueElement(
        uint256 _index
    )
        override
        public
        view
        returns (
            Lib_OVMCodec.QueueElement memory _element
        )
    {
        return _getQueueElement(
            _index,
            queue()
        );
    }

    /**
     * Get the number of queue elements which have not yet been included.
     * @return Number of pending queue elements.
     */
    function getNumPendingQueueElements()
        override
        public
        view
        returns (
            uint40
        )
    {
        return getQueueLength() - getNextQueueIndex();
    }

   /**
     * Retrieves the length of the queue, including
     * both pending and canonical transactions.
     * @return Length of the queue.
     */
    function getQueueLength()
        override
        public
        view
        returns (
            uint40
        )
    {
        return _getQueueLength(
            queue()
        );
    }

    /**
     * Adds a transaction to the queue.
     * @param _target Target L2 contract to send the transaction to.
     * @param _gasLimit Gas limit for the enqueued L2 transaction.
     * @param _data Transaction data.
     */
    function enqueue(
        address _target,
        uint256 _gasLimit,
        bytes memory _data
    )
        override
        public
    {
        require(
            _data.length <= MAX_ROLLUP_TX_SIZE,
            "Transaction data size exceeds maximum for rollup transaction."
        );

        require(
            _gasLimit <= maxTransactionGasLimit,
            "Transaction gas limit exceeds maximum for rollup transaction."
        );

        require(
            _gasLimit >= MIN_ROLLUP_TX_GAS,
            "Transaction gas limit too low to enqueue."
        );

        // We need to consume some amount of L1 gas in order to rate limit transactions going into
        // L2. However, L2 is cheaper than L1 so we only need to burn some small proportion of the
        // provided L1 gas.
        uint256 gasToConsume = _gasLimit/L2_GAS_DISCOUNT_DIVISOR;
        uint256 startingGas = gasleft();

        // Although this check is not necessary (burn below will run out of gas if not true), it
        // gives the user an explicit reason as to why the enqueue attempt failed.
        require(
            startingGas > gasToConsume,
            "Insufficient gas for L2 rate limiting burn."
        );

        // Here we do some "dumb" work in order to burn gas, although we should probably replace
        // this with something like minting gas token later on.
        uint256 i;
        while(startingGas - gasleft() < gasToConsume) {
            i++;
        }

        bytes32 transactionHash = keccak256(
            abi.encode(
                msg.sender,
                _target,
                _gasLimit,
                _data
            )
        );

        bytes32 timestampAndBlockNumber;
        assembly {
            timestampAndBlockNumber := timestamp()
            timestampAndBlockNumber := or(timestampAndBlockNumber, shl(40, number()))
        }

        iOVM_ChainStorageContainer queueRef = queue();

        queueRef.push(transactionHash);
        queueRef.push(timestampAndBlockNumber);

        // The underlying queue data structure stores 2 elements
        // per insertion, so to get the real queue length we need
        // to divide by 2 and subtract 1.
        uint256 queueIndex = queueRef.length() / 2 - 1;
        emit TransactionEnqueued(
            msg.sender,
            _target,
            _gasLimit,
            _data,
            queueIndex,
            block.timestamp
        );
    }

    /**
     * Appends a given number of queued transactions as a single batch.
     * param _numQueuedTransactions Number of transactions to append.
     */
    function appendQueueBatch(
        uint256 // _numQueuedTransactions
    )
        override
        public
        pure
    {
        // TEMPORARY: Disable `appendQueueBatch` for minnet
        revert("appendQueueBatch is currently disabled.");

        // solhint-disable max-line-length
        // _numQueuedTransactions = Math.min(_numQueuedTransactions, getNumPendingQueueElements());
        // require(
        //     _numQueuedTransactions > 0,
        //     "Must append more than zero transactions."
        // );

        // bytes32[] memory leaves = new bytes32[](_numQueuedTransactions);
        // uint40 nextQueueIndex = getNextQueueIndex();

        // for (uint256 i = 0; i < _numQueuedTransactions; i++) {
        //     if (msg.sender != resolve("OVM_Sequencer")) {
        //         Lib_OVMCodec.QueueElement memory el = getQueueElement(nextQueueIndex);
        //         require(
        //             el.timestamp + forceInclusionPeriodSeconds < block.timestamp,
        //             "Queue transactions cannot be submitted during the sequencer inclusion period."
        //         );
        //     }
        //     leaves[i] = _getQueueLeafHash(nextQueueIndex);
        //     nextQueueIndex++;
        // }

        // Lib_OVMCodec.QueueElement memory lastElement = getQueueElement(nextQueueIndex - 1);

        // _appendBatch(
        //     Lib_MerkleTree.getMerkleRoot(leaves),
        //     _numQueuedTransactions,
        //     _numQueuedTransactions,
        //     lastElement.timestamp,
        //     lastElement.blockNumber
        // );

        // emit QueueBatchAppended(
        //     nextQueueIndex - _numQueuedTransactions,
        //     _numQueuedTransactions,
        //     getTotalElements()
        // );
        // solhint-enable max-line-length
    }

    /**
     * Allows the sequencer to append a batch of transactions.
     * @dev This function uses a custom encoding scheme for efficiency reasons.
     * .param _shouldStartAtElement Specific batch we expect to start appending to.
     * .param _totalElementsToAppend Total number of batch elements we expect to append.
     * .param _contexts Array of batch contexts.
     * .param _transactionDataFields Array of raw transaction data.
     */
    function appendSequencerBatch()
        override
        public
    {
        uint40 shouldStartAtElement;
        uint24 totalElementsToAppend;
        uint24 numContexts;
        assembly {
            shouldStartAtElement  := shr(216, calldataload(4))
            totalElementsToAppend := shr(232, calldataload(9))
            numContexts           := shr(232, calldataload(12))
        }

        require(
            shouldStartAtElement == getTotalElements(),
            "Actual batch start index does not match expected start index."
        );

        require(
            msg.sender == resolve("OVM_Sequencer"),
            "Function can only be called by the Sequencer."
        );

        require(
            numContexts > 0,
            "Must provide at least one batch context."
        );

        require(
            totalElementsToAppend > 0,
            "Must append at least one element."
        );

        uint40 nextTransactionPtr = uint40(
            BATCH_CONTEXT_START_POS + BATCH_CONTEXT_SIZE * numContexts
        );

        require(
            msg.data.length >= nextTransactionPtr,
            "Not enough BatchContexts provided."
        );

        // Take a reference to the queue and its length so we don't have to keep resolving it.
        // Length isn't going to change during the course of execution, so it's fine to simply
        // resolve this once at the start. Saves gas.
        iOVM_ChainStorageContainer queueRef = queue();
        uint40 queueLength = _getQueueLength(queueRef);

        // Reserve some memory to save gas on hashing later on. This is a relatively safe estimate
        // for the average transaction size that will prevent having to resize this chunk of memory
        // later on. Saves gas.
        bytes memory hashMemory = new bytes((msg.data.length / totalElementsToAppend) * 2);

        // Initialize the array of canonical chain leaves that we will append.
        bytes32[] memory leaves = new bytes32[](totalElementsToAppend);

        // Each leaf index corresponds to a tx, either sequenced or enqueued.
        uint32 leafIndex = 0;

        // Counter for number of sequencer transactions appended so far.
        uint32 numSequencerTransactions = 0;

        // We will sequentially append leaves which are pointers to the queue.
        // The initial queue index is what is currently in storage.
        uint40 nextQueueIndex = getNextQueueIndex();

        BatchContext memory curContext;
        for (uint32 i = 0; i < numContexts; i++) {
            BatchContext memory nextContext = _getBatchContext(i);

            if (i == 0) {
                // Execute a special check for the first batch.
                _validateFirstBatchContext(nextContext);
            }

            // Execute this check on every single batch, including the first one.
            _validateNextBatchContext(
                curContext,
                nextContext,
                nextQueueIndex,
                queueRef
            );

            // Now we can update our current context.
            curContext = nextContext;

            // Process sequencer transactions first.
            for (uint32 j = 0; j < curContext.numSequencedTransactions; j++) {
                uint256 txDataLength;
                assembly {
                    txDataLength := shr(232, calldataload(nextTransactionPtr))
                }
                require(
                    txDataLength <= MAX_ROLLUP_TX_SIZE,
                    "Transaction data size exceeds maximum for rollup transaction."
                );

                leaves[leafIndex] = _getSequencerLeafHash(
                    curContext,
                    nextTransactionPtr,
                    txDataLength,
                    hashMemory
                );

                nextTransactionPtr += uint40(TX_DATA_HEADER_SIZE + txDataLength);
                numSequencerTransactions++;
                leafIndex++;
            }

            // Now process any subsequent queue transactions.
            for (uint32 j = 0; j < curContext.numSubsequentQueueTransactions; j++) {
                require(
                    nextQueueIndex < queueLength,
                    "Not enough queued transactions to append."
                );

                leaves[leafIndex] = _getQueueLeafHash(nextQueueIndex);
                nextQueueIndex++;
                leafIndex++;
            }
        }

        _validateFinalBatchContext(
            curContext,
            nextQueueIndex,
            queueLength,
            queueRef
        );

        require(
            msg.data.length == nextTransactionPtr,
            "Not all sequencer transactions were processed."
        );

        require(
            leafIndex == totalElementsToAppend,
            "Actual transaction index does not match expected total elements to append."
        );

        // Generate the required metadata that we need to append this batch
        uint40 numQueuedTransactions = totalElementsToAppend - numSequencerTransactions;
        uint40 blockTimestamp;
        uint40 blockNumber;
        if (curContext.numSubsequentQueueTransactions == 0) {
            // The last element is a sequencer tx, therefore pull timestamp and block number from
            // the last context.
            blockTimestamp = uint40(curContext.timestamp);
            blockNumber = uint40(curContext.blockNumber);
        } else {
            // The last element is a queue tx, therefore pull timestamp and block number from the
            // queue element.
            // curContext.numSubsequentQueueTransactions > 0 which means that we've processed at
            // least one queue element. We increment nextQueueIndex after processing each queue
            // element, so the index of the last element we processed is nextQueueIndex - 1.
            Lib_OVMCodec.QueueElement memory lastElement = _getQueueElement(
                nextQueueIndex - 1,
                queueRef
            );

            blockTimestamp = lastElement.timestamp;
            blockNumber = lastElement.blockNumber;
        }

        // For efficiency reasons getMerkleRoot modifies the `leaves` argument in place
        // while calculating the root hash therefore any arguments passed to it must not
        // be used again afterwards
        _appendBatch(
            Lib_MerkleTree.getMerkleRoot(leaves),
            totalElementsToAppend,
            numQueuedTransactions,
            blockTimestamp,
            blockNumber
        );

        emit SequencerBatchAppended(
            nextQueueIndex - numQueuedTransactions,
            numQueuedTransactions,
            getTotalElements()
        );
    }

    /**
     * Verifies whether a transaction is included in the chain.
     * @param _transaction Transaction to verify.
     * @param _txChainElement Transaction chain element corresponding to the transaction.
     * @param _batchHeader Header of the batch the transaction was included in.
     * @param _inclusionProof Inclusion proof for the provided transaction chain element.
     * @return True if the transaction exists in the CTC, false if not.
     */
    function verifyTransaction(
        Lib_OVMCodec.Transaction memory _transaction,
        Lib_OVMCodec.TransactionChainElement memory _txChainElement,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _inclusionProof
    )
        override
        public
        view
        returns (
            bool
        )
    {
        if (_txChainElement.isSequenced == true) {
            return _verifySequencerTransaction(
                _transaction,
                _txChainElement,
                _batchHeader,
                _inclusionProof
            );
        } else {
            return _verifyQueueTransaction(
                _transaction,
                _txChainElement.queueIndex,
                _batchHeader,
                _inclusionProof
            );
        }
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Returns the BatchContext located at a particular index.
     * @param _index The index of the BatchContext
     * @return The BatchContext at the specified index.
     */
    function _getBatchContext(
        uint256 _index
    )
        internal
        pure
        returns (
            BatchContext memory
        )
    {
        uint256 contextPtr = 15 + _index * BATCH_CONTEXT_SIZE;
        uint256 numSequencedTransactions;
        uint256 numSubsequentQueueTransactions;
        uint256 ctxTimestamp;
        uint256 ctxBlockNumber;

        assembly {
            numSequencedTransactions       := shr(232, calldataload(contextPtr))
            numSubsequentQueueTransactions := shr(232, calldataload(add(contextPtr, 3)))
            ctxTimestamp                   := shr(216, calldataload(add(contextPtr, 6)))
            ctxBlockNumber                 := shr(216, calldataload(add(contextPtr, 11)))
        }

        return BatchContext({
            numSequencedTransactions: numSequencedTransactions,
            numSubsequentQueueTransactions: numSubsequentQueueTransactions,
            timestamp: ctxTimestamp,
            blockNumber: ctxBlockNumber
        });
    }

    /**
     * Parses the batch context from the extra data.
     * @return Total number of elements submitted.
     * @return Index of the next queue element.
     */
    function _getBatchExtraData()
        internal
        view
        returns (
            uint40,
            uint40,
            uint40,
            uint40
        )
    {
        bytes27 extraData = batches().getGlobalMetadata();

        uint40 totalElements;
        uint40 nextQueueIndex;
        uint40 lastTimestamp;
        uint40 lastBlockNumber;

        // solhint-disable max-line-length
        assembly {
            extraData       :=  shr(40, extraData)
            totalElements   :=  and(extraData, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            nextQueueIndex  :=  shr(40, and(extraData, 0x00000000000000000000000000000000000000000000FFFFFFFFFF0000000000))
            lastTimestamp   :=  shr(80, and(extraData, 0x0000000000000000000000000000000000FFFFFFFFFF00000000000000000000))
            lastBlockNumber :=  shr(120, and(extraData, 0x000000000000000000000000FFFFFFFFFF000000000000000000000000000000))
        }
        // solhint-enable max-line-length

        return (
            totalElements,
            nextQueueIndex,
            lastTimestamp,
            lastBlockNumber
        );
    }

    /**
     * Encodes the batch context for the extra data.
     * @param _totalElements Total number of elements submitted.
     * @param _nextQueueIndex Index of the next queue element.
     * @param _timestamp Timestamp for the last batch.
     * @param _blockNumber Block number of the last batch.
     * @return Encoded batch context.
     */
    function _makeBatchExtraData(
        uint40 _totalElements,
        uint40 _nextQueueIndex,
        uint40 _timestamp,
        uint40 _blockNumber
    )
        internal
        pure
        returns (
            bytes27
        )
    {
        bytes27 extraData;
        assembly {
            extraData := _totalElements
            extraData := or(extraData, shl(40, _nextQueueIndex))
            extraData := or(extraData, shl(80, _timestamp))
            extraData := or(extraData, shl(120, _blockNumber))
            extraData := shl(40, extraData)
        }

        return extraData;
    }

    /**
     * Retrieves the hash of a queue element.
     * @param _index Index of the queue element to retrieve a hash for.
     * @return Hash of the queue element.
     */
    function _getQueueLeafHash(
        uint256 _index
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return _hashTransactionChainElement(
            Lib_OVMCodec.TransactionChainElement({
                isSequenced: false,
                queueIndex: _index,
                timestamp: 0,
                blockNumber: 0,
                txData: hex""
            })
        );
    }

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function _getQueueElement(
        uint256 _index,
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
        returns (
            Lib_OVMCodec.QueueElement memory _element
        )
    {
        // The underlying queue data structure stores 2 elements
        // per insertion, so to get the actual desired queue index
        // we need to multiply by 2.
        uint40 trueIndex = uint40(_index * 2);
        bytes32 transactionHash = _queueRef.get(trueIndex);
        bytes32 timestampAndBlockNumber = _queueRef.get(trueIndex + 1);

        uint40 elementTimestamp;
        uint40 elementBlockNumber;
        // solhint-disable max-line-length
        assembly {
            elementTimestamp   :=         and(timestampAndBlockNumber, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            elementBlockNumber := shr(40, and(timestampAndBlockNumber, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000))
        }
        // solhint-enable max-line-length

        return Lib_OVMCodec.QueueElement({
            transactionHash: transactionHash,
            timestamp: elementTimestamp,
            blockNumber: elementBlockNumber
        });
    }

    /**
     * Retrieves the length of the queue.
     * @return Length of the queue.
     */
    function _getQueueLength(
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
        returns (
            uint40
        )
    {
        // The underlying queue data structure stores 2 elements
        // per insertion, so to get the real queue length we need
        // to divide by 2.
        return uint40(_queueRef.length() / 2);
    }

    /**
     * Retrieves the hash of a sequencer element.
     * @param _context Batch context for the given element.
     * @param _nextTransactionPtr Pointer to the next transaction in the calldata.
     * @param _txDataLength Length of the transaction item.
     * @return Hash of the sequencer element.
     */
    function _getSequencerLeafHash(
        BatchContext memory _context,
        uint256 _nextTransactionPtr,
        uint256 _txDataLength,
        bytes memory _hashMemory
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        // Only allocate more memory if we didn't reserve enough to begin with.
        if (BYTES_TILL_TX_DATA + _txDataLength > _hashMemory.length) {
            _hashMemory = new bytes(BYTES_TILL_TX_DATA + _txDataLength);
        }

        uint256 ctxTimestamp = _context.timestamp;
        uint256 ctxBlockNumber = _context.blockNumber;

        bytes32 leafHash;
        assembly {
            let chainElementStart := add(_hashMemory, 0x20)

            // Set the first byte equal to `1` to indicate this is a sequencer chain element.
            // This distinguishes sequencer ChainElements from queue ChainElements because
            // all queue ChainElements are ABI encoded and the first byte of ABI encoded
            // elements is always zero
            mstore8(chainElementStart, 1)

            mstore(add(chainElementStart, 1), ctxTimestamp)
            mstore(add(chainElementStart, 33), ctxBlockNumber)
            // solhint-disable-next-line max-line-length
            calldatacopy(add(chainElementStart, BYTES_TILL_TX_DATA), add(_nextTransactionPtr, 3), _txDataLength)

            leafHash := keccak256(chainElementStart, add(BYTES_TILL_TX_DATA, _txDataLength))
        }

        return leafHash;
    }

    /**
     * Retrieves the hash of a sequencer element.
     * @param _txChainElement The chain element which is hashed to calculate the leaf.
     * @return Hash of the sequencer element.
     */
    function _getSequencerLeafHash(
        Lib_OVMCodec.TransactionChainElement memory _txChainElement
    )
        internal
        view
        returns(
            bytes32
        )
    {
        bytes memory txData = _txChainElement.txData;
        uint256 txDataLength = _txChainElement.txData.length;

        bytes memory chainElement = new bytes(BYTES_TILL_TX_DATA + txDataLength);
        uint256 ctxTimestamp = _txChainElement.timestamp;
        uint256 ctxBlockNumber = _txChainElement.blockNumber;

        bytes32 leafHash;
        assembly {
            let chainElementStart := add(chainElement, 0x20)

            // Set the first byte equal to `1` to indicate this is a sequencer chain element.
            // This distinguishes sequencer ChainElements from queue ChainElements because
            // all queue ChainElements are ABI encoded and the first byte of ABI encoded
            // elements is always zero
            mstore8(chainElementStart, 1)

            mstore(add(chainElementStart, 1), ctxTimestamp)
            mstore(add(chainElementStart, 33), ctxBlockNumber)
            // solhint-disable-next-line max-line-length
            pop(staticcall(gas(), 0x04, add(txData, 0x20), txDataLength, add(chainElementStart, BYTES_TILL_TX_DATA), txDataLength))

            leafHash := keccak256(chainElementStart, add(BYTES_TILL_TX_DATA, txDataLength))
        }

        return leafHash;
    }

    /**
     * Inserts a batch into the chain of batches.
     * @param _transactionRoot Root of the transaction tree for this batch.
     * @param _batchSize Number of elements in the batch.
     * @param _numQueuedTransactions Number of queue transactions in the batch.
     * @param _timestamp The latest batch timestamp.
     * @param _blockNumber The latest batch blockNumber.
     */
    function _appendBatch(
        bytes32 _transactionRoot,
        uint256 _batchSize,
        uint256 _numQueuedTransactions,
        uint40 _timestamp,
        uint40 _blockNumber
    )
        internal
    {
        iOVM_ChainStorageContainer batchesRef = batches();
        (uint40 totalElements, uint40 nextQueueIndex,,) = _getBatchExtraData();

        Lib_OVMCodec.ChainBatchHeader memory header = Lib_OVMCodec.ChainBatchHeader({
            batchIndex: batchesRef.length(),
            batchRoot: _transactionRoot,
            batchSize: _batchSize,
            prevTotalElements: totalElements,
            extraData: hex""
        });

        emit TransactionBatchAppended(
            header.batchIndex,
            header.batchRoot,
            header.batchSize,
            header.prevTotalElements,
            header.extraData
        );

        bytes32 batchHeaderHash = Lib_OVMCodec.hashBatchHeader(header);
        bytes27 latestBatchContext = _makeBatchExtraData(
            totalElements + uint40(header.batchSize),
            nextQueueIndex + uint40(_numQueuedTransactions),
            _timestamp,
            _blockNumber
        );

        batchesRef.push(batchHeaderHash, latestBatchContext);
    }

    /**
     * Checks that the first batch context in a sequencer submission is valid
     * @param _firstContext The batch context to validate.
     */
    function _validateFirstBatchContext(
        BatchContext memory _firstContext
    )
        internal
        view
    {
        // If there are existing elements, this batch must have the same context
        // or a later timestamp and block number.
        if (getTotalElements() > 0) {
            (,, uint40 lastTimestamp, uint40 lastBlockNumber) = _getBatchExtraData();

            require(
                _firstContext.blockNumber >= lastBlockNumber,
                "Context block number is lower than last submitted."
            );

            require(
                _firstContext.timestamp >= lastTimestamp,
                "Context timestamp is lower than last submitted."
            );
        }

        // Sequencer cannot submit contexts which are more than the force inclusion period old.
        require(
            _firstContext.timestamp + forceInclusionPeriodSeconds >= block.timestamp,
            "Context timestamp too far in the past."
        );

        require(
            _firstContext.blockNumber + forceInclusionPeriodBlocks >= block.number,
            "Context block number too far in the past."
        );
    }

    /**
     * Checks that a given batch context has a time context which is below a given que element
     * @param _context The batch context to validate has values lower.
     * @param _queueIndex Index of the queue element we are validating came later than the context.
     * @param _queueRef The storage container for the queue.
     */
    function _validateContextBeforeEnqueue(
        BatchContext memory _context,
        uint40 _queueIndex,
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
    {
            Lib_OVMCodec.QueueElement memory nextQueueElement = _getQueueElement(
                _queueIndex,
                _queueRef
            );

            // If the force inclusion period has passed for an enqueued transaction, it MUST be the
            // next chain element.
            require(
                block.timestamp < nextQueueElement.timestamp + forceInclusionPeriodSeconds,
                // solhint-disable-next-line max-line-length
                "Previously enqueued batches have expired and must be appended before a new sequencer batch."
            );

            // Just like sequencer transaction times must be increasing relative to each other,
            // We also require that they be increasing relative to any interspersed queue elements.
            require(
                _context.timestamp <= nextQueueElement.timestamp,
                "Sequencer transaction timestamp exceeds that of next queue element."
            );

            require(
                _context.blockNumber <= nextQueueElement.blockNumber,
                "Sequencer transaction blockNumber exceeds that of next queue element."
            );
    }

    /**
     * Checks that a given batch context is valid based on its previous context, and the next queue
     * elemtent.
     * @param _prevContext The previously validated batch context.
     * @param _nextContext The batch context to validate with this call.
     * @param _nextQueueIndex Index of the next queue element to process for the _nextContext's
     * subsequentQueueElements.
     * @param _queueRef The storage container for the queue.
     */
    function _validateNextBatchContext(
        BatchContext memory _prevContext,
        BatchContext memory _nextContext,
        uint40 _nextQueueIndex,
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
    {
        // All sequencer transactions' times must be greater than or equal to the previous ones.
        require(
            _nextContext.timestamp >= _prevContext.timestamp,
            "Context timestamp values must monotonically increase."
        );

        require(
            _nextContext.blockNumber >= _prevContext.blockNumber,
            "Context blockNumber values must monotonically increase."
        );

        // If there is going to be a queue element pulled in from this context:
        if (_nextContext.numSubsequentQueueTransactions > 0) {
            _validateContextBeforeEnqueue(
                _nextContext,
                _nextQueueIndex,
                _queueRef
            );
        }
    }

    /**
     * Checks that the final batch context in a sequencer submission is valid.
     * @param _finalContext The batch context to validate.
     * @param _queueLength The length of the queue at the start of the batchAppend call.
     * @param _nextQueueIndex The next element in the queue that will be pulled into the CTC.
     * @param _queueRef The storage container for the queue.
     */
    function _validateFinalBatchContext(
        BatchContext memory _finalContext,
        uint40 _nextQueueIndex,
        uint40 _queueLength,
        iOVM_ChainStorageContainer _queueRef
    )
        internal
        view
    {
        // If the queue is not now empty, check the mononoticity of whatever the next batch that
        // will come in is.
        if (_queueLength - _nextQueueIndex > 0 && _finalContext.numSubsequentQueueTransactions == 0)
        {
            _validateContextBeforeEnqueue(
                _finalContext,
                _nextQueueIndex,
                _queueRef
            );
        }
        // Batches cannot be added from the future, or subsequent enqueue() contexts would violate
        // monotonicity.
        require(_finalContext.timestamp <= block.timestamp,
            "Context timestamp is from the future.");
        require(_finalContext.blockNumber <= block.number,
            "Context block number is from the future.");
    }

    /**
     * Hashes a transaction chain element.
     * @param _element Chain element to hash.
     * @return Hash of the chain element.
     */
    function _hashTransactionChainElement(
        Lib_OVMCodec.TransactionChainElement memory _element
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(
            abi.encode(
                _element.isSequenced,
                _element.queueIndex,
                _element.timestamp,
                _element.blockNumber,
                _element.txData
            )
        );
    }

    /**
     * Verifies a sequencer transaction, returning true if it was indeed included in the CTC
     * @param _transaction The transaction we are verifying inclusion of.
     * @param _txChainElement The chain element that the transaction is claimed to be a part of.
     * @param _batchHeader Header of the batch the transaction was included in.
     * @param _inclusionProof An inclusion proof into the CTC at a particular index.
     * @return True if the transaction was included in the specified location, else false.
     */
    function _verifySequencerTransaction(
        Lib_OVMCodec.Transaction memory _transaction,
        Lib_OVMCodec.TransactionChainElement memory _txChainElement,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _inclusionProof
    )
        internal
        view
        returns (
            bool
        )
    {
        OVM_ExecutionManager ovmExecutionManager =
            OVM_ExecutionManager(resolve("OVM_ExecutionManager"));
        uint256 gasLimit = ovmExecutionManager.getMaxTransactionGasLimit();
        bytes32 leafHash = _getSequencerLeafHash(_txChainElement);

        require(
            _verifyElement(
                leafHash,
                _batchHeader,
                _inclusionProof
            ),
            "Invalid Sequencer transaction inclusion proof."
        );

        require(
            _transaction.blockNumber        == _txChainElement.blockNumber
            && _transaction.timestamp       == _txChainElement.timestamp
            && _transaction.entrypoint      == resolve("OVM_DecompressionPrecompileAddress")
            && _transaction.gasLimit        == gasLimit
            && _transaction.l1TxOrigin      == address(0)
            && _transaction.l1QueueOrigin   == Lib_OVMCodec.QueueOrigin.SEQUENCER_QUEUE
            && keccak256(_transaction.data) == keccak256(_txChainElement.txData),
            "Invalid Sequencer transaction."
        );

        return true;
    }

    /**
     * Verifies a queue transaction, returning true if it was indeed included in the CTC
     * @param _transaction The transaction we are verifying inclusion of.
     * @param _queueIndex The queueIndex of the queued transaction.
     * @param _batchHeader Header of the batch the transaction was included in.
     * @param _inclusionProof An inclusion proof into the CTC at a particular index (should point to
     * queue tx).
     * @return True if the transaction was included in the specified location, else false.
     */
    function _verifyQueueTransaction(
        Lib_OVMCodec.Transaction memory _transaction,
        uint256 _queueIndex,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _inclusionProof
    )
        internal
        view
        returns (
            bool
        )
    {
        bytes32 leafHash = _getQueueLeafHash(_queueIndex);

        require(
            _verifyElement(
                leafHash,
                _batchHeader,
                _inclusionProof
            ),
            "Invalid Queue transaction inclusion proof."
        );

        bytes32 transactionHash = keccak256(
            abi.encode(
                _transaction.l1TxOrigin,
                _transaction.entrypoint,
                _transaction.gasLimit,
                _transaction.data
            )
        );

        Lib_OVMCodec.QueueElement memory el = getQueueElement(_queueIndex);
        require(
            el.transactionHash      == transactionHash
            && el.timestamp   == _transaction.timestamp
            && el.blockNumber == _transaction.blockNumber,
            "Invalid Queue transaction."
        );

        return true;
    }

    /**
     * Verifies a batch inclusion proof.
     * @param _element Hash of the element to verify a proof for.
     * @param _batchHeader Header of the batch in which the element was included.
     * @param _proof Merkle inclusion proof for the element.
     */
    function _verifyElement(
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        require(
            Lib_OVMCodec.hashBatchHeader(_batchHeader) ==
                batches().get(uint32(_batchHeader.batchIndex)),
            "Invalid batch header."
        );

        require(
            Lib_MerkleTree.verify(
                _batchHeader.batchRoot,
                _element,
                _proof.index,
                _proof.siblings,
                _batchHeader.batchSize
            ),
            "Invalid inclusion proof."
        );

        return true;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_Bytes32Utils } from "../../libraries/utils/Lib_Bytes32Utils.sol";
import { Lib_EthUtils } from "../../libraries/utils/Lib_EthUtils.sol";
import { Lib_ErrorUtils } from "../../libraries/utils/Lib_ErrorUtils.sol";
import { Lib_PredeployAddresses } from "../../libraries/constants/Lib_PredeployAddresses.sol";

/* Interface Imports */
import { iOVM_ExecutionManager } from "../../iOVM/execution/iOVM_ExecutionManager.sol";
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";
import { iOVM_SafetyChecker } from "../../iOVM/execution/iOVM_SafetyChecker.sol";

/* Contract Imports */
import { OVM_DeployerWhitelist } from "../predeploys/OVM_DeployerWhitelist.sol";

/* External Imports */
import { Math } from "@openzeppelin/contracts/math/Math.sol";

/**
 * @title OVM_ExecutionManager
 * @dev The Execution Manager (EM) is the core of our OVM implementation, and provides a sandboxed
 * environment allowing us to execute OVM transactions deterministically on either Layer 1 or
 * Layer 2.
 * The EM's run() function is the first function called during the execution of any
 * transaction on L2.
 * For each context-dependent EVM operation the EM has a function which implements a corresponding
 * OVM operation, which will read state from the State Manager contract.
 * The EM relies on the Safety Checker to verify that code deployed to Layer 2 does not contain any
 * context-dependent operations.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_ExecutionManager is iOVM_ExecutionManager, Lib_AddressResolver {

    /********************************
     * External Contract References *
     ********************************/

    iOVM_SafetyChecker internal ovmSafetyChecker;
    iOVM_StateManager internal ovmStateManager;


    /*******************************
     * Execution Context Variables *
     *******************************/

    GasMeterConfig internal gasMeterConfig;
    GlobalContext internal globalContext;
    TransactionContext internal transactionContext;
    MessageContext internal messageContext;
    TransactionRecord internal transactionRecord;
    MessageRecord internal messageRecord;


    /**************************
     * Gas Metering Constants *
     **************************/

    address constant GAS_METADATA_ADDRESS = 0x06a506A506a506A506a506a506A506A506A506A5;
    uint256 constant NUISANCE_GAS_SLOAD = 20000;
    uint256 constant NUISANCE_GAS_SSTORE = 20000;
    uint256 constant MIN_NUISANCE_GAS_PER_CONTRACT = 30000;
    uint256 constant NUISANCE_GAS_PER_CONTRACT_BYTE = 100;
    uint256 constant MIN_GAS_FOR_INVALID_STATE_ACCESS = 30000;


    /**************************
     * Native Value Constants *
     **************************/

    // Public so we can access and make assertions in integration tests.
    uint256 public constant CALL_WITH_VALUE_INTRINSIC_GAS = 90000;


    /**************************
     * Default Context Values *
     **************************/

    uint256 constant DEFAULT_UINT256 =
        0xdefa017defa017defa017defa017defa017defa017defa017defa017defa017d;
    address constant DEFAULT_ADDRESS = 0xdEfa017defA017DeFA017DEfa017DeFA017DeFa0;


    /*************************************
     * Container Contract Address Prefix *
     *************************************/

    /**
     * @dev The Execution Manager and State Manager each have this 30 byte prefix,
     * and are uncallable.
     */
    address constant CONTAINER_CONTRACT_PREFIX = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    constructor(
        address _libAddressManager,
        GasMeterConfig memory _gasMeterConfig,
        GlobalContext memory _globalContext
    )
        Lib_AddressResolver(_libAddressManager)
    {
        ovmSafetyChecker = iOVM_SafetyChecker(resolve("OVM_SafetyChecker"));
        gasMeterConfig = _gasMeterConfig;
        globalContext = _globalContext;
        _resetContext();
    }


    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Applies dynamically-sized refund to a transaction to account for the difference in execution
     * between L1 and L2, so that the overall cost of the ovmOPCODE is fixed.
     * @param _cost Desired gas cost for the function after the refund.
     */
    modifier netGasCost(
        uint256 _cost
    ) {
        uint256 gasProvided = gasleft();
        _;
        uint256 gasUsed = gasProvided - gasleft();

        // We want to refund everything *except* the specified cost.
        if (_cost < gasUsed) {
            transactionRecord.ovmGasRefund += gasUsed - _cost;
        }
    }

    /**
     * Applies a fixed-size gas refund to a transaction to account for the difference in execution
     * between L1 and L2, so that the overall cost of an ovmOPCODE can be lowered.
     * @param _discount Amount of gas cost to refund for the ovmOPCODE.
     */
    modifier fixedGasDiscount(
        uint256 _discount
    ) {
        uint256 gasProvided = gasleft();
        _;
        uint256 gasUsed = gasProvided - gasleft();

        // We want to refund the specified _discount, unless this risks underflow.
        if (_discount < gasUsed) {
            transactionRecord.ovmGasRefund += _discount;
        } else {
            // refund all we can without risking underflow.
            transactionRecord.ovmGasRefund += gasUsed;
        }
    }

    /**
     * Makes sure we're not inside a static context.
     */
    modifier notStatic() {
        if (messageContext.isStatic == true) {
            _revertWithFlag(RevertFlag.STATIC_VIOLATION);
        }
        _;
    }


    /************************************
     * Transaction Execution Entrypoint *
     ************************************/

    /**
     * Starts the execution of a transaction via the OVM_ExecutionManager.
     * @param _transaction Transaction data to be executed.
     * @param _ovmStateManager iOVM_StateManager implementation providing account state.
     */
    function run(
        Lib_OVMCodec.Transaction memory _transaction,
        address _ovmStateManager
    )
        override
        external
        returns (
            bytes memory
        )
    {
        // Make sure that run() is not re-enterable.  This condition should always be satisfied
        // Once run has been called once, due to the behavior of _isValidInput().
        if (transactionContext.ovmNUMBER != DEFAULT_UINT256) {
            return bytes("");
        }

        // Store our OVM_StateManager instance (significantly easier than attempting to pass the
        // address around in calldata).
        ovmStateManager = iOVM_StateManager(_ovmStateManager);

        // Make sure this function can't be called by anyone except the owner of the
        // OVM_StateManager (expected to be an OVM_StateTransitioner). We can revert here because
        // this would make the `run` itself invalid.
        require(
            // This method may return false during fraud proofs, but always returns true in
            // L2 nodes' State Manager precompile.
            ovmStateManager.isAuthenticated(msg.sender),
            "Only authenticated addresses in ovmStateManager can call this function"
        );

        // Initialize the execution context, must be initialized before we perform any gas metering
        // or we'll throw a nuisance gas error.
        _initContext(_transaction);

        // TEMPORARY: Gas metering is disabled for minnet.
        // // Check whether we need to start a new epoch, do so if necessary.
        // _checkNeedsNewEpoch(_transaction.timestamp);

        // Make sure the transaction's gas limit is valid. We don't revert here because we reserve
        // reverts for INVALID_STATE_ACCESS.
        if (_isValidInput(_transaction) == false) {
            _resetContext();
            return bytes("");
        }

        // TEMPORARY: Gas metering is disabled for minnet.
        // // Check gas right before the call to get total gas consumed by OVM transaction.
        // uint256 gasProvided = gasleft();

        // Run the transaction, make sure to meter the gas usage.
        (, bytes memory returndata) = ovmCALL(
            _transaction.gasLimit - gasMeterConfig.minTransactionGasLimit,
            _transaction.entrypoint,
            0,
            _transaction.data
        );

        // TEMPORARY: Gas metering is disabled for minnet.
        // // Update the cumulative gas based on the amount of gas used.
        // uint256 gasUsed = gasProvided - gasleft();
        // _updateCumulativeGas(gasUsed, _transaction.l1QueueOrigin);

        // Wipe the execution context.
        _resetContext();

        return returndata;
    }


    /******************************
     * Opcodes: Execution Context *
     ******************************/

    /**
     * @notice Overrides CALLER.
     * @return _CALLER Address of the CALLER within the current message context.
     */
    function ovmCALLER()
        override
        external
        view
        returns (
            address _CALLER
        )
    {
        return messageContext.ovmCALLER;
    }

    /**
     * @notice Overrides ADDRESS.
     * @return _ADDRESS Active ADDRESS within the current message context.
     */
    function ovmADDRESS()
        override
        public
        view
        returns (
            address _ADDRESS
        )
    {
        return messageContext.ovmADDRESS;
    }

    /**
     * @notice Overrides CALLVALUE.
     * @return _CALLVALUE Value sent along with the call according to the current message context.
     */
    function ovmCALLVALUE()
        override
        public
        view
        returns (
            uint256 _CALLVALUE
        )
    {
        return messageContext.ovmCALLVALUE;
    }

    /**
     * @notice Overrides TIMESTAMP.
     * @return _TIMESTAMP Value of the TIMESTAMP within the transaction context.
     */
    function ovmTIMESTAMP()
        override
        external
        view
        returns (
            uint256 _TIMESTAMP
        )
    {
        return transactionContext.ovmTIMESTAMP;
    }

    /**
     * @notice Overrides NUMBER.
     * @return _NUMBER Value of the NUMBER within the transaction context.
     */
    function ovmNUMBER()
        override
        external
        view
        returns (
            uint256 _NUMBER
        )
    {
        return transactionContext.ovmNUMBER;
    }

    /**
     * @notice Overrides GASLIMIT.
     * @return _GASLIMIT Value of the block's GASLIMIT within the transaction context.
     */
    function ovmGASLIMIT()
        override
        external
        view
        returns (
            uint256 _GASLIMIT
        )
    {
        return transactionContext.ovmGASLIMIT;
    }

    /**
     * @notice Overrides CHAINID.
     * @return _CHAINID Value of the chain's CHAINID within the global context.
     */
    function ovmCHAINID()
        override
        external
        view
        returns (
            uint256 _CHAINID
        )
    {
        return globalContext.ovmCHAINID;
    }

    /*********************************
     * Opcodes: L2 Execution Context *
     *********************************/

    /**
     * @notice Specifies from which source (Sequencer or Queue) this transaction originated from.
     * @return _queueOrigin Enum indicating the ovmL1QUEUEORIGIN within the current message context.
     */
    function ovmL1QUEUEORIGIN()
        override
        external
        view
        returns (
            Lib_OVMCodec.QueueOrigin _queueOrigin
        )
    {
        return transactionContext.ovmL1QUEUEORIGIN;
    }

    /**
     * @notice Specifies which L1 account, if any, sent this transaction by calling enqueue().
     * @return _l1TxOrigin Address of the account which sent the tx into L2 from L1.
     */
    function ovmL1TXORIGIN()
        override
        external
        view
        returns (
            address _l1TxOrigin
        )
    {
        return transactionContext.ovmL1TXORIGIN;
    }

    /********************
     * Opcodes: Halting *
     ********************/

    /**
     * @notice Overrides REVERT.
     * @param _data Bytes data to pass along with the REVERT.
     */
    function ovmREVERT(
        bytes memory _data
    )
        override
        public
    {
        _revertWithFlag(RevertFlag.INTENTIONAL_REVERT, _data);
    }


    /******************************
     * Opcodes: Contract Creation *
     ******************************/

    /**
     * @notice Overrides CREATE.
     * @param _bytecode Code to be used to CREATE a new contract.
     * @return Address of the created contract.
     * @return Revert data, if and only if the creation threw an exception.
     */
    function ovmCREATE(
        bytes memory _bytecode
    )
        override
        public
        notStatic
        fixedGasDiscount(40000)
        returns (
            address,
            bytes memory
        )
    {
        // Creator is always the current ADDRESS.
        address creator = ovmADDRESS();

        // Check that the deployer is whitelisted, or
        // that arbitrary contract deployment has been enabled.
        _checkDeployerAllowed(creator);

        // Generate the correct CREATE address.
        address contractAddress = Lib_EthUtils.getAddressForCREATE(
            creator,
            _getAccountNonce(creator)
        );

        return _createContract(
            contractAddress,
            _bytecode,
            MessageType.ovmCREATE
        );
    }

    /**
     * @notice Overrides CREATE2.
     * @param _bytecode Code to be used to CREATE2 a new contract.
     * @param _salt Value used to determine the contract's address.
     * @return Address of the created contract.
     * @return Revert data, if and only if the creation threw an exception.
     */
    function ovmCREATE2(
        bytes memory _bytecode,
        bytes32 _salt
    )
        override
        external
        notStatic
        fixedGasDiscount(40000)
        returns (
            address,
            bytes memory
        )
    {
        // Creator is always the current ADDRESS.
        address creator = ovmADDRESS();

        // Check that the deployer is whitelisted, or
        // that arbitrary contract deployment has been enabled.
        _checkDeployerAllowed(creator);

        // Generate the correct CREATE2 address.
        address contractAddress = Lib_EthUtils.getAddressForCREATE2(
            creator,
            _bytecode,
            _salt
        );

        return _createContract(
            contractAddress,
            _bytecode,
            MessageType.ovmCREATE2
        );
    }


    /*******************************
     * Account Abstraction Opcodes *
     ******************************/

    /**
     * Retrieves the nonce of the current ovmADDRESS.
     * @return _nonce Nonce of the current contract.
     */
    function ovmGETNONCE()
        override
        external
        returns (
            uint256 _nonce
        )
    {
        return _getAccountNonce(ovmADDRESS());
    }

    /**
     * Bumps the nonce of the current ovmADDRESS by one.
     */
    function ovmINCREMENTNONCE()
        override
        external
        notStatic
    {
        address account = ovmADDRESS();
        uint256 nonce = _getAccountNonce(account);

        // Prevent overflow.
        if (nonce + 1 > nonce) {
            _setAccountNonce(account, nonce + 1);
        }
    }

    /**
     * Creates a new EOA contract account, for account abstraction.
     * @dev Essentially functions like ovmCREATE or ovmCREATE2, but we can bypass a lot of checks
     *      because the contract we're creating is trusted (no need to do safety checking or to
     *      handle unexpected reverts). Doesn't need to return an address because the address is
     *      assumed to be the user's actual address.
     * @param _messageHash Hash of a message signed by some user, for verification.
     * @param _v Signature `v` parameter.
     * @param _r Signature `r` parameter.
     * @param _s Signature `s` parameter.
     */
    function ovmCREATEEOA(
        bytes32 _messageHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        override
        public
        notStatic
    {
        // Recover the EOA address from the message hash and signature parameters. Since we do the
        // hashing in advance, we don't have handle different message hashing schemes. Even if this
        // function were to return the wrong address (rather than explicitly returning the zero
        // address), the rest of the transaction would simply fail (since there's no EOA account to
        // actually execute the transaction).
        address eoa = ecrecover(
            _messageHash,
            _v + 27,
            _r,
            _s
        );

        // Invalid signature is a case we proactively handle with a revert. We could alternatively
        // have this function return a `success` boolean, but this is just easier.
        if (eoa == address(0)) {
            ovmREVERT(bytes("Signature provided for EOA contract creation is invalid."));
        }

        // If the user already has an EOA account, then there's no need to perform this operation.
        if (_hasEmptyAccount(eoa) == false) {
            return;
        }

        // We always need to initialize the contract with the default account values.
        _initPendingAccount(eoa);

        // Temporarily set the current address so it's easier to access on L2.
        address prevADDRESS = messageContext.ovmADDRESS;
        messageContext.ovmADDRESS = eoa;

        // Creates a duplicate of the OVM_ProxyEOA located at 0x42....09. Uses the following
        // "magic" prefix to deploy an exact copy of the code:
        // PUSH1 0x0D   # size of this prefix in bytes
        // CODESIZE
        // SUB          # subtract prefix size from codesize
        // DUP1
        // PUSH1 0x0D
        // PUSH1 0x00
        // CODECOPY     # copy everything after prefix into memory at pos 0
        // PUSH1 0x00
        // RETURN       # return the copied code
        address proxyEOA = Lib_EthUtils.createContract(abi.encodePacked(
            hex"600D380380600D6000396000f3",
            ovmEXTCODECOPY(
                Lib_PredeployAddresses.PROXY_EOA,
                0,
                ovmEXTCODESIZE(Lib_PredeployAddresses.PROXY_EOA)
            )
        ));

        // Reset the address now that we're done deploying.
        messageContext.ovmADDRESS = prevADDRESS;

        // Commit the account with its final values.
        _commitPendingAccount(
            eoa,
            address(proxyEOA),
            keccak256(Lib_EthUtils.getCode(address(proxyEOA)))
        );

        _setAccountNonce(eoa, 0);
    }


    /*********************************
     * Opcodes: Contract Interaction *
     *********************************/

    /**
     * @notice Overrides CALL.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _address Address of the contract to call.
     * @param _value ETH value to pass with the call.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function ovmCALL(
        uint256 _gasLimit,
        address _address,
        uint256 _value,
        bytes memory _calldata
    )
        override
        public
        fixedGasDiscount(100000)
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        // CALL updates the CALLER and ADDRESS.
        MessageContext memory nextMessageContext = messageContext;
        nextMessageContext.ovmCALLER = nextMessageContext.ovmADDRESS;
        nextMessageContext.ovmADDRESS = _address;
        nextMessageContext.ovmCALLVALUE = _value;

        return _callContract(
            nextMessageContext,
            _gasLimit,
            _address,
            _calldata,
            MessageType.ovmCALL
        );
    }

    /**
     * @notice Overrides STATICCALL.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _address Address of the contract to call.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function ovmSTATICCALL(
        uint256 _gasLimit,
        address _address,
        bytes memory _calldata
    )
        override
        public
        fixedGasDiscount(80000)
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        // STATICCALL updates the CALLER, updates the ADDRESS, and runs in a static,
        // valueless context.
        MessageContext memory nextMessageContext = messageContext;
        nextMessageContext.ovmCALLER = nextMessageContext.ovmADDRESS;
        nextMessageContext.ovmADDRESS = _address;
        nextMessageContext.isStatic = true;
        nextMessageContext.ovmCALLVALUE = 0;

        return _callContract(
            nextMessageContext,
            _gasLimit,
            _address,
            _calldata,
            MessageType.ovmSTATICCALL
        );
    }

    /**
     * @notice Overrides DELEGATECALL.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _address Address of the contract to call.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function ovmDELEGATECALL(
        uint256 _gasLimit,
        address _address,
        bytes memory _calldata
    )
        override
        public
        fixedGasDiscount(40000)
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        // DELEGATECALL does not change anything about the message context.
        MessageContext memory nextMessageContext = messageContext;

        return _callContract(
            nextMessageContext,
            _gasLimit,
            _address,
            _calldata,
            MessageType.ovmDELEGATECALL
        );
    }

    /**
     * @notice Legacy ovmCALL function which did not support ETH value; this maintains backwards
     * compatibility.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _address Address of the contract to call.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function ovmCALL(
        uint256 _gasLimit,
        address _address,
        bytes memory _calldata
    )
        override
        public
        returns(
            bool _success,
            bytes memory _returndata
        )
    {
        // Legacy ovmCALL assumed always-0 value.
        return ovmCALL(
            _gasLimit,
            _address,
            0,
            _calldata
        );
    }


    /************************************
     * Opcodes: Contract Storage Access *
     ************************************/

    /**
     * @notice Overrides SLOAD.
     * @param _key 32 byte key of the storage slot to load.
     * @return _value 32 byte value of the requested storage slot.
     */
    function ovmSLOAD(
        bytes32 _key
    )
        override
        external
        netGasCost(40000)
        returns (
            bytes32 _value
        )
    {
        // We always SLOAD from the storage of ADDRESS.
        address contractAddress = ovmADDRESS();

        return _getContractStorage(
            contractAddress,
            _key
        );
    }

    /**
     * @notice Overrides SSTORE.
     * @param _key 32 byte key of the storage slot to set.
     * @param _value 32 byte value for the storage slot.
     */
    function ovmSSTORE(
        bytes32 _key,
        bytes32 _value
    )
        override
        external
        notStatic
        netGasCost(60000)
    {
        // We always SSTORE to the storage of ADDRESS.
        address contractAddress = ovmADDRESS();

        _putContractStorage(
            contractAddress,
            _key,
            _value
        );
    }


    /*********************************
     * Opcodes: Contract Code Access *
     *********************************/

    /**
     * @notice Overrides EXTCODECOPY.
     * @param _contract Address of the contract to copy code from.
     * @param _offset Offset in bytes from the start of contract code to copy beyond.
     * @param _length Total number of bytes to copy from the contract's code.
     * @return _code Bytes of code copied from the requested contract.
     */
    function ovmEXTCODECOPY(
        address _contract,
        uint256 _offset,
        uint256 _length
    )
        override
        public
        returns (
            bytes memory _code
        )
    {
        return Lib_EthUtils.getCode(
            _getAccountEthAddress(_contract),
            _offset,
            _length
        );
    }

    /**
     * @notice Overrides EXTCODESIZE.
     * @param _contract Address of the contract to query the size of.
     * @return _EXTCODESIZE Size of the requested contract in bytes.
     */
    function ovmEXTCODESIZE(
        address _contract
    )
        override
        public
        returns (
            uint256 _EXTCODESIZE
        )
    {
        return Lib_EthUtils.getCodeSize(
            _getAccountEthAddress(_contract)
        );
    }

    /**
     * @notice Overrides EXTCODEHASH.
     * @param _contract Address of the contract to query the hash of.
     * @return _EXTCODEHASH Hash of the requested contract.
     */
    function ovmEXTCODEHASH(
        address _contract
    )
        override
        external
        returns (
            bytes32 _EXTCODEHASH
        )
    {
        return Lib_EthUtils.getCodeHash(
            _getAccountEthAddress(_contract)
        );
    }


    /***************************************
     * Public Functions: ETH Value Opcodes *
     ***************************************/

    /**
     * @notice Overrides BALANCE.
     * NOTE: In the future, this could be optimized to directly invoke EM._getContractStorage(...).
     * @param _contract Address of the contract to query the OVM_ETH balance of.
     * @return _BALANCE OVM_ETH balance of the requested contract.
     */
    function ovmBALANCE(
        address _contract
    )
        override
        public
        returns (
            uint256 _BALANCE
        )
    {
        // Easiest way to get the balance is query OVM_ETH as normal.
        bytes memory balanceOfCalldata = abi.encodeWithSignature(
            "balanceOf(address)",
            _contract
        );

        // Static call because this should be a read-only query.
        (bool success, bytes memory returndata) = ovmSTATICCALL(
            gasleft(),
            Lib_PredeployAddresses.OVM_ETH,
            balanceOfCalldata
        );

        // All balanceOf queries should successfully return a uint, otherwise this must be an OOG.
        if (!success || returndata.length != 32) {
            _revertWithFlag(RevertFlag.OUT_OF_GAS);
        }

        // Return the decoded balance.
        return abi.decode(returndata, (uint256));
    }

    /**
     * @notice Overrides SELFBALANCE.
     * @return _BALANCE OVM_ETH balance of the requesting contract.
     */
    function ovmSELFBALANCE()
        override
        external
        returns (
            uint256 _BALANCE
        )
    {
        return ovmBALANCE(ovmADDRESS());
    }


    /***************************************
     * Public Functions: Execution Context *
     ***************************************/

    function getMaxTransactionGasLimit()
        external
        view
        override
        returns (
            uint256 _maxTransactionGasLimit
        )
    {
        return gasMeterConfig.maxTransactionGasLimit;
    }

    /********************************************
     * Public Functions: Deployment Whitelisting *
     ********************************************/

    /**
     * Checks whether the given address is on the whitelist to ovmCREATE/ovmCREATE2,
     * and reverts if not.
     * @param _deployerAddress Address attempting to deploy a contract.
     */
    function _checkDeployerAllowed(
        address _deployerAddress
    )
        internal
    {
        // From an OVM semantics perspective, this will appear identical to
        // the deployer ovmCALLing the whitelist.  This is fine--in a sense, we are forcing them to.
        (bool success, bytes memory data) = ovmSTATICCALL(
            gasleft(),
            Lib_PredeployAddresses.DEPLOYER_WHITELIST,
            abi.encodeWithSelector(
                OVM_DeployerWhitelist.isDeployerAllowed.selector,
                _deployerAddress
            )
        );
        bool isAllowed = abi.decode(data, (bool));

        if (!isAllowed || !success) {
            _revertWithFlag(RevertFlag.CREATOR_NOT_ALLOWED);
        }
    }

    /********************************************
     * Internal Functions: Contract Interaction *
     ********************************************/

    /**
     * Creates a new contract and associates it with some contract address.
     * @param _contractAddress Address to associate the created contract with.
     * @param _bytecode Bytecode to be used to create the contract.
     * @return Final OVM contract address.
     * @return Revertdata, if and only if the creation threw an exception.
     */
    function _createContract(
        address _contractAddress,
        bytes memory _bytecode,
        MessageType _messageType
    )
        internal
        returns (
            address,
            bytes memory
        )
    {
        // We always update the nonce of the creating account, even if the creation fails.
        _setAccountNonce(ovmADDRESS(), _getAccountNonce(ovmADDRESS()) + 1);

        // We're stepping into a CREATE or CREATE2, so we need to update ADDRESS to point
        // to the contract's associated address and CALLER to point to the previous ADDRESS.
        MessageContext memory nextMessageContext = messageContext;
        nextMessageContext.ovmCALLER = messageContext.ovmADDRESS;
        nextMessageContext.ovmADDRESS = _contractAddress;

        // Run the common logic which occurs between call-type and create-type messages,
        // passing in the creation bytecode and `true` to trigger create-specific logic.
        (bool success, bytes memory data) = _handleExternalMessage(
            nextMessageContext,
            gasleft(),
            _contractAddress,
            _bytecode,
            _messageType
        );

        // Yellow paper requires that address returned is zero if the contract deployment fails.
        return (
            success ? _contractAddress : address(0),
            data
        );
    }

    /**
     * Calls the deployed contract associated with a given address.
     * @param _nextMessageContext Message context to be used for the call.
     * @param _gasLimit Amount of gas to be passed into this call.
     * @param _contract OVM address to be called.
     * @param _calldata Data to send along with the call.
     * @return _success Whether or not the call returned (rather than reverted).
     * @return _returndata Data returned by the call.
     */
    function _callContract(
        MessageContext memory _nextMessageContext,
        uint256 _gasLimit,
        address _contract,
        bytes memory _calldata,
        MessageType _messageType
    )
        internal
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        // We reserve addresses of the form 0xdeaddeaddead...NNNN for the container contracts in L2
        // geth. So, we block calls to these addresses since they are not safe to run as an OVM
        // contract itself.
        if (
            (uint256(_contract) &
            uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000))
            == uint256(CONTAINER_CONTRACT_PREFIX)
        ) {
            // solhint-disable-next-line max-line-length
            // EVM does not return data in the success case, see: https://github.com/ethereum/go-ethereum/blob/aae7660410f0ef90279e14afaaf2f429fdc2a186/core/vm/instructions.go#L600-L604
            return (true, hex'');
        }

        // Both 0x0000... and the EVM precompiles have the same address on L1 and L2 -->
        // no trie lookup needed.
        address codeContractAddress =
            uint(_contract) < 100
            ? _contract
            : _getAccountEthAddress(_contract);

        return _handleExternalMessage(
            _nextMessageContext,
            _gasLimit,
            codeContractAddress,
            _calldata,
            _messageType
        );
    }

    /**
     * Handles all interactions which involve the execution manager calling out to untrusted code
     * (both calls and creates). Ensures that OVM-related measures are enforced, including L2 gas
     * refunds, nuisance gas, and flagged reversions.
     *
     * @param _nextMessageContext Message context to be used for the external message.
     * @param _gasLimit Amount of gas to be passed into this message. NOTE: this argument is
     * overwritten in some cases to avoid stack-too-deep.
     * @param _contract OVM address being called or deployed to
     * @param _data Data for the message (either calldata or creation code)
     * @param _messageType What type of ovmOPCODE this message corresponds to.
     * @return Whether or not the message (either a call or deployment) succeeded.
     * @return Data returned by the message.
     */
    function _handleExternalMessage(
        MessageContext memory _nextMessageContext,
        // NOTE: this argument is overwritten in some cases to avoid stack-too-deep.
        uint256 _gasLimit,
        address _contract,
        bytes memory _data,
        MessageType _messageType
    )
        internal
        returns (
            bool,
            bytes memory
        )
    {
        uint256 messageValue = _nextMessageContext.ovmCALLVALUE;
        // If there is value in this message, we need to transfer the ETH over before switching
        // contexts.
        if (
            messageValue > 0
            && _isValueType(_messageType)
        ) {
            // Handle out-of-intrinsic gas consistent with EVM behavior -- the subcall "appears to
            // revert" if we don't have enough gas to transfer the ETH.
            // Similar to dynamic gas cost of value exceeding gas here:
            // solhint-disable-next-line max-line-length
            // https://github.com/ethereum/go-ethereum/blob/c503f98f6d5e80e079c1d8a3601d188af2a899da/core/vm/interpreter.go#L268-L273
            if (gasleft() < CALL_WITH_VALUE_INTRINSIC_GAS) {
                return (false, hex"");
            }

            // If there *is* enough gas to transfer ETH, then we need to make sure this amount of
            // gas is reserved (i.e. not given to the _contract.call below) to guarantee that
            // _handleExternalMessage can't run out of gas. In particular, in the event that
            // the call fails, we will need to transfer the ETH back to the sender.
            // Taking the lesser of _gasLimit and gasleft() - CALL_WITH_VALUE_INTRINSIC_GAS
            // guarantees that the second _attemptForcedEthTransfer below, if needed, always has
            // enough gas to succeed.
            _gasLimit = Math.min(
                _gasLimit,
                gasleft() - CALL_WITH_VALUE_INTRINSIC_GAS // Cannot overflow due to the above check.
            );

            // Now transfer the value of the call.
            // The target is interpreted to be the next message's ovmADDRESS account.
            bool transferredOvmEth = _attemptForcedEthTransfer(
                _nextMessageContext.ovmADDRESS,
                messageValue
            );

            // If the ETH transfer fails (should only be possible in the case of insufficient
            // balance), then treat this as a revert. This mirrors EVM behavior, see
            // solhint-disable-next-line max-line-length
            // https://github.com/ethereum/go-ethereum/blob/2dee31930c9977af2a9fcb518fb9838aa609a7cf/core/vm/evm.go#L298
            if (!transferredOvmEth) {
                return (false, hex"");
            }
        }

        // We need to switch over to our next message context for the duration of this call.
        MessageContext memory prevMessageContext = messageContext;
        _switchMessageContext(prevMessageContext, _nextMessageContext);

        // Nuisance gas is a system used to bound the ability for an attacker to make fraud proofs
        // expensive by touching a lot of different accounts or storage slots. Since most contracts
        // only use a few storage slots during any given transaction, this shouldn't be a limiting
        // factor.
        uint256 prevNuisanceGasLeft = messageRecord.nuisanceGasLeft;
        uint256 nuisanceGasLimit = _getNuisanceGasLimit(_gasLimit);
        messageRecord.nuisanceGasLeft = nuisanceGasLimit;

        // Make the call and make sure to pass in the gas limit. Another instance of hidden
        // complexity. `_contract` is guaranteed to be a safe contract, meaning its return/revert
        // behavior can be controlled. In particular, we enforce that flags are passed through
        // revert data as to retrieve execution metadata that would normally be reverted out of
        // existence.

        bool success;
        bytes memory returndata;
        if (_isCreateType(_messageType)) {
            // safeCREATE() is a function which replicates a CREATE message, but uses return values
            // Which match that of CALL (i.e. bool, bytes).  This allows many security checks to be
            // to be shared between untrusted call and create call frames.
            (success, returndata) = address(this).call{gas: _gasLimit}(
                abi.encodeWithSelector(
                    this.safeCREATE.selector,
                    _data,
                    _contract
                )
            );
        } else {
            (success, returndata) = _contract.call{gas: _gasLimit}(_data);
        }

        // If the message threw an exception, its value should be returned back to the sender.
        // So, we force it back, BEFORE returning the messageContext to the previous addresses.
        // This operation is part of the reason we "reserved the intrinsic gas" above.
        if (
            messageValue > 0
            && _isValueType(_messageType)
            && !success
        ) {
            bool transferredOvmEth = _attemptForcedEthTransfer(
                prevMessageContext.ovmADDRESS,
                messageValue
            );

            // Since we transferred it in above and the call reverted, the transfer back should
            // always pass. This code path should NEVER be triggered since we sent `messageValue`
            // worth of OVM_ETH into the target and reserved sufficient gas to execute the transfer,
            // but in case there is some edge case which has been missed, we revert the entire frame
            // (and its parent) to make sure the ETH gets sent back.
            if (!transferredOvmEth) {
                _revertWithFlag(RevertFlag.OUT_OF_GAS);
            }
        }

        // Switch back to the original message context now that we're out of the call and all
        // OVM_ETH is in the right place.
        _switchMessageContext(_nextMessageContext, prevMessageContext);

        // Assuming there were no reverts, the message record should be accurate here. We'll update
        // this value in the case of a revert.
        uint256 nuisanceGasLeft = messageRecord.nuisanceGasLeft;

        // Reverts at this point are completely OK, but we need to make a few updates based on the
        // information passed through the revert.
        if (success == false) {
            (
                RevertFlag flag,
                uint256 nuisanceGasLeftPostRevert,
                uint256 ovmGasRefund,
                bytes memory returndataFromFlag
            ) = _decodeRevertData(returndata);

            // INVALID_STATE_ACCESS is the only flag that triggers an immediate abort of the
            // parent EVM message. This behavior is necessary because INVALID_STATE_ACCESS must
            // halt any further transaction execution that could impact the execution result.
            if (flag == RevertFlag.INVALID_STATE_ACCESS) {
                _revertWithFlag(flag);
            }

            // INTENTIONAL_REVERT, UNSAFE_BYTECODE, STATIC_VIOLATION, and CREATOR_NOT_ALLOWED aren't
            // dependent on the input state, so we can just handle them like standard reverts.
            // Our only change here is to record the gas refund reported by the call (enforced by
            // safety checking).
            if (
                flag == RevertFlag.INTENTIONAL_REVERT
                || flag == RevertFlag.UNSAFE_BYTECODE
                || flag == RevertFlag.STATIC_VIOLATION
                || flag == RevertFlag.CREATOR_NOT_ALLOWED
            ) {
                transactionRecord.ovmGasRefund = ovmGasRefund;
            }

            // INTENTIONAL_REVERT needs to pass up the user-provided return data encoded into the
            // flag, *not* the full encoded flag.  Additionally, we surface custom error messages
            // to developers in the case of unsafe creations for improved devex.
            // All other revert types return no data.
            if (
                flag == RevertFlag.INTENTIONAL_REVERT
                || flag == RevertFlag.UNSAFE_BYTECODE
            ) {
                returndata = returndataFromFlag;
            } else {
                returndata = hex'';
            }

            // Reverts mean we need to use up whatever "nuisance gas" was used by the call.
            // EXCEEDS_NUISANCE_GAS explicitly reduces the remaining nuisance gas for this message
            // to zero. OUT_OF_GAS is a "pseudo" flag given that messages return no data when they
            // run out of gas, so we have to treat this like EXCEEDS_NUISANCE_GAS. All other flags
            // will simply pass up the remaining nuisance gas.
            nuisanceGasLeft = nuisanceGasLeftPostRevert;
        }

        // We need to reset the nuisance gas back to its original value minus the amount used here.
        messageRecord.nuisanceGasLeft = prevNuisanceGasLeft - (nuisanceGasLimit - nuisanceGasLeft);

        return (
            success,
            returndata
        );
    }

    /**
     * Handles the creation-specific safety measures required for OVM contract deployment.
     * This function sanitizes the return types for creation messages to match calls (bool, bytes),
     * by being an external function which the EM can call, that mimics the success/fail case of the
     * CREATE.
     * This allows for consistent handling of both types of messages in _handleExternalMessage().
     * Having this step occur as a separate call frame also allows us to easily revert the
     * contract deployment in the event that the code is unsafe.
     *
     * @param _creationCode Code to pass into CREATE for deployment.
     * @param _address OVM address being deployed to.
     */
    function safeCREATE(
        bytes memory _creationCode,
        address _address
    )
        external
    {
        // The only way this should callable is from within _createContract(),
        // and it should DEFINITELY not be callable by a non-EM code contract.
        if (msg.sender != address(this)) {
            return;
        }
        // Check that there is not already code at this address.
        if (_hasEmptyAccount(_address) == false) {
            // Note: in the EVM, this case burns all allotted gas.  For improved
            // developer experience, we do return the remaining gas.
            _revertWithFlag(
                RevertFlag.CREATE_COLLISION
            );
        }

        // Check the creation bytecode against the OVM_SafetyChecker.
        if (ovmSafetyChecker.isBytecodeSafe(_creationCode) == false) {
            // Note: in the EVM, this case burns all allotted gas.  For improved
            // developer experience, we do return the remaining gas.
            _revertWithFlag(
                RevertFlag.UNSAFE_BYTECODE,
                // solhint-disable-next-line max-line-length
                Lib_ErrorUtils.encodeRevertString("Contract creation code contains unsafe opcodes. Did you use the right compiler or pass an unsafe constructor argument?")
            );
        }

        // We always need to initialize the contract with the default account values.
        _initPendingAccount(_address);

        // Actually execute the EVM create message.
        // NOTE: The inline assembly below means we can NOT make any evm calls between here and then
        address ethAddress = Lib_EthUtils.createContract(_creationCode);

        if (ethAddress == address(0)) {
            // If the creation fails, the EVM lets us grab its revert data. This may contain a
            // revert flag to be used above in _handleExternalMessage, so we pass the revert data
            // back up unmodified.
            assembly {
                returndatacopy(0,0,returndatasize())
                revert(0, returndatasize())
            }
        }

        // Again simply checking that the deployed code is safe too. Contracts can generate
        // arbitrary deployment code, so there's no easy way to analyze this beforehand.
        bytes memory deployedCode = Lib_EthUtils.getCode(ethAddress);
        if (ovmSafetyChecker.isBytecodeSafe(deployedCode) == false) {
            _revertWithFlag(
                RevertFlag.UNSAFE_BYTECODE,
                // solhint-disable-next-line max-line-length
                Lib_ErrorUtils.encodeRevertString("Constructor attempted to deploy unsafe bytecode.")
            );
        }

        // Contract creation didn't need to be reverted and the bytecode is safe. We finish up by
        // associating the desired address with the newly created contract's code hash and address.
        _commitPendingAccount(
            _address,
            ethAddress,
            Lib_EthUtils.getCodeHash(ethAddress)
        );
    }

    /******************************************
     * Internal Functions: Value Manipulation *
     ******************************************/

    /**
     * Invokes an ovmCALL to OVM_ETH.transfer on behalf of the current ovmADDRESS, allowing us to
     * force movement of OVM_ETH in correspondence with ETH's native value functionality.
     * WARNING: this will send on behalf of whatever the messageContext.ovmADDRESS is in storage
     * at the time of the call.
     * NOTE: In the future, this could be optimized to directly invoke EM._setContractStorage(...).
     * @param _to Amount of OVM_ETH to be sent.
     * @param _value Amount of OVM_ETH to send.
     * @return _success Whether or not the transfer worked.
     */
    function _attemptForcedEthTransfer(
        address _to,
        uint256 _value
    )
        internal
        returns(
            bool _success
        )
    {
        bytes memory transferCalldata = abi.encodeWithSignature(
            "transfer(address,uint256)",
            _to,
            _value
        );

        // OVM_ETH inherits from the UniswapV2ERC20 standard.  In this implementation, its return
        // type is a boolean.  However, the implementation always returns true if it does not revert
        // Thus, success of the call frame is sufficient to infer success of the transfer itself.
        (bool success, ) = ovmCALL(
            gasleft(),
            Lib_PredeployAddresses.OVM_ETH,
            0,
            transferCalldata
        );

        return success;
    }

    /******************************************
     * Internal Functions: State Manipulation *
     ******************************************/

    /**
     * Checks whether an account exists within the OVM_StateManager.
     * @param _address Address of the account to check.
     * @return _exists Whether or not the account exists.
     */
    function _hasAccount(
        address _address
    )
        internal
        returns (
            bool _exists
        )
    {
        _checkAccountLoad(_address);
        return ovmStateManager.hasAccount(_address);
    }

    /**
     * Checks whether a known empty account exists within the OVM_StateManager.
     * @param _address Address of the account to check.
     * @return _exists Whether or not the account empty exists.
     */
    function _hasEmptyAccount(
        address _address
    )
        internal
        returns (
            bool _exists
        )
    {
        _checkAccountLoad(_address);
        return ovmStateManager.hasEmptyAccount(_address);
    }

    /**
     * Sets the nonce of an account.
     * @param _address Address of the account to modify.
     * @param _nonce New account nonce.
     */
    function _setAccountNonce(
        address _address,
        uint256 _nonce
    )
        internal
    {
        _checkAccountChange(_address);
        ovmStateManager.setAccountNonce(_address, _nonce);
    }

    /**
     * Gets the nonce of an account.
     * @param _address Address of the account to access.
     * @return _nonce Nonce of the account.
     */
    function _getAccountNonce(
        address _address
    )
        internal
        returns (
            uint256 _nonce
        )
    {
        _checkAccountLoad(_address);
        return ovmStateManager.getAccountNonce(_address);
    }

    /**
     * Retrieves the Ethereum address of an account.
     * @param _address Address of the account to access.
     * @return _ethAddress Corresponding Ethereum address.
     */
    function _getAccountEthAddress(
        address _address
    )
        internal
        returns (
            address _ethAddress
        )
    {
        _checkAccountLoad(_address);
        return ovmStateManager.getAccountEthAddress(_address);
    }

    /**
     * Creates the default account object for the given address.
     * @param _address Address of the account create.
     */
    function _initPendingAccount(
        address _address
    )
        internal
    {
        // Although it seems like `_checkAccountChange` would be more appropriate here, we don't
        // actually consider an account "changed" until it's inserted into the state (in this case
        // by `_commitPendingAccount`).
        _checkAccountLoad(_address);
        ovmStateManager.initPendingAccount(_address);
    }

    /**
     * Stores additional relevant data for a new account, thereby "committing" it to the state.
     * This function is only called during `ovmCREATE` and `ovmCREATE2` after a successful contract
     * creation.
     * @param _address Address of the account to commit.
     * @param _ethAddress Address of the associated deployed contract.
     * @param _codeHash Hash of the code stored at the address.
     */
    function _commitPendingAccount(
        address _address,
        address _ethAddress,
        bytes32 _codeHash
    )
        internal
    {
        _checkAccountChange(_address);
        ovmStateManager.commitPendingAccount(
            _address,
            _ethAddress,
            _codeHash
        );
    }

    /**
     * Retrieves the value of a storage slot.
     * @param _contract Address of the contract to query.
     * @param _key 32 byte key of the storage slot.
     * @return _value 32 byte storage slot value.
     */
    function _getContractStorage(
        address _contract,
        bytes32 _key
    )
        internal
        returns (
            bytes32 _value
        )
    {
        _checkContractStorageLoad(_contract, _key);
        return ovmStateManager.getContractStorage(_contract, _key);
    }

    /**
     * Sets the value of a storage slot.
     * @param _contract Address of the contract to modify.
     * @param _key 32 byte key of the storage slot.
     * @param _value 32 byte storage slot value.
     */
    function _putContractStorage(
        address _contract,
        bytes32 _key,
        bytes32 _value
    )
        internal
    {
        // We don't set storage if the value didn't change. Although this acts as a convenient
        // optimization, it's also necessary to avoid the case in which a contract with no storage
        // attempts to store the value "0" at any key. Putting this value (and therefore requiring
        // that the value be committed into the storage trie after execution) would incorrectly
        // modify the storage root.
        if (_getContractStorage(_contract, _key) == _value) {
            return;
        }

        _checkContractStorageChange(_contract, _key);
        ovmStateManager.putContractStorage(_contract, _key, _value);
    }

    /**
     * Validation whenever a contract needs to be loaded. Checks that the account exists, charges
     * nuisance gas if the account hasn't been loaded before.
     * @param _address Address of the account to load.
     */
    function _checkAccountLoad(
        address _address
    )
        internal
    {
        // See `_checkContractStorageLoad` for more information.
        if (gasleft() < MIN_GAS_FOR_INVALID_STATE_ACCESS) {
            _revertWithFlag(RevertFlag.OUT_OF_GAS);
        }

        // See `_checkContractStorageLoad` for more information.
        if (ovmStateManager.hasAccount(_address) == false) {
            _revertWithFlag(RevertFlag.INVALID_STATE_ACCESS);
        }

        // Check whether the account has been loaded before and mark it as loaded if not. We need
        // this because "nuisance gas" only applies to the first time that an account is loaded.
        (
            bool _wasAccountAlreadyLoaded
        ) = ovmStateManager.testAndSetAccountLoaded(_address);

        // If we hadn't already loaded the account, then we'll need to charge "nuisance gas" based
        // on the size of the contract code.
        if (_wasAccountAlreadyLoaded == false) {
            _useNuisanceGas(
                (Lib_EthUtils.getCodeSize(_getAccountEthAddress(_address))
                * NUISANCE_GAS_PER_CONTRACT_BYTE) + MIN_NUISANCE_GAS_PER_CONTRACT
            );
        }
    }

    /**
     * Validation whenever a contract needs to be changed. Checks that the account exists, charges
     * nuisance gas if the account hasn't been changed before.
     * @param _address Address of the account to change.
     */
    function _checkAccountChange(
        address _address
    )
        internal
    {
        // Start by checking for a load as we only want to charge nuisance gas proportional to
        // contract size once.
        _checkAccountLoad(_address);

        // Check whether the account has been changed before and mark it as changed if not. We need
        // this because "nuisance gas" only applies to the first time that an account is changed.
        (
            bool _wasAccountAlreadyChanged
        ) = ovmStateManager.testAndSetAccountChanged(_address);

        // If we hadn't already loaded the account, then we'll need to charge "nuisance gas" based
        // on the size of the contract code.
        if (_wasAccountAlreadyChanged == false) {
            ovmStateManager.incrementTotalUncommittedAccounts();
            _useNuisanceGas(
                (Lib_EthUtils.getCodeSize(_getAccountEthAddress(_address))
                * NUISANCE_GAS_PER_CONTRACT_BYTE) + MIN_NUISANCE_GAS_PER_CONTRACT
            );
        }
    }

    /**
     * Validation whenever a slot needs to be loaded. Checks that the account exists, charges
     * nuisance gas if the slot hasn't been loaded before.
     * @param _contract Address of the account to load from.
     * @param _key 32 byte key to load.
     */
    function _checkContractStorageLoad(
        address _contract,
        bytes32 _key
    )
        internal
    {
        // Another case of hidden complexity. If we didn't enforce this requirement, then a
        // contract could pass in just enough gas to cause the INVALID_STATE_ACCESS check to fail
        // on L1 but not on L2. A contract could use this behavior to prevent the
        // OVM_ExecutionManager from detecting an invalid state access. Reverting with OUT_OF_GAS
        // allows us to also charge for the full message nuisance gas, because you deserve that for
        // trying to break the contract in this way.
        if (gasleft() < MIN_GAS_FOR_INVALID_STATE_ACCESS) {
            _revertWithFlag(RevertFlag.OUT_OF_GAS);
        }

        // We need to make sure that the transaction isn't trying to access storage that hasn't
        // been provided to the OVM_StateManager. We'll immediately abort if this is the case.
        // We know that we have enough gas to do this check because of the above test.
        if (ovmStateManager.hasContractStorage(_contract, _key) == false) {
            _revertWithFlag(RevertFlag.INVALID_STATE_ACCESS);
        }

        // Check whether the slot has been loaded before and mark it as loaded if not. We need
        // this because "nuisance gas" only applies to the first time that a slot is loaded.
        (
            bool _wasContractStorageAlreadyLoaded
        ) = ovmStateManager.testAndSetContractStorageLoaded(_contract, _key);

        // If we hadn't already loaded the account, then we'll need to charge some fixed amount of
        // "nuisance gas".
        if (_wasContractStorageAlreadyLoaded == false) {
            _useNuisanceGas(NUISANCE_GAS_SLOAD);
        }
    }

    /**
     * Validation whenever a slot needs to be changed. Checks that the account exists, charges
     * nuisance gas if the slot hasn't been changed before.
     * @param _contract Address of the account to change.
     * @param _key 32 byte key to change.
     */
    function _checkContractStorageChange(
        address _contract,
        bytes32 _key
    )
        internal
    {
        // Start by checking for load to make sure we have the storage slot and that we charge the
        // "nuisance gas" necessary to prove the storage slot state.
        _checkContractStorageLoad(_contract, _key);

        // Check whether the slot has been changed before and mark it as changed if not. We need
        // this because "nuisance gas" only applies to the first time that a slot is changed.
        (
            bool _wasContractStorageAlreadyChanged
        ) = ovmStateManager.testAndSetContractStorageChanged(_contract, _key);

        // If we hadn't already changed the account, then we'll need to charge some fixed amount of
        // "nuisance gas".
        if (_wasContractStorageAlreadyChanged == false) {
            // Changing a storage slot means that we're also going to have to change the
            // corresponding account, so do an account change check.
            _checkAccountChange(_contract);

            ovmStateManager.incrementTotalUncommittedContractStorage();
            _useNuisanceGas(NUISANCE_GAS_SSTORE);
        }
    }


    /************************************
     * Internal Functions: Revert Logic *
     ************************************/

    /**
     * Simple encoding for revert data.
     * @param _flag Flag to revert with.
     * @param _data Additional user-provided revert data.
     * @return _revertdata Encoded revert data.
     */
    function _encodeRevertData(
        RevertFlag _flag,
        bytes memory _data
    )
        internal
        view
        returns (
            bytes memory _revertdata
        )
    {
        // Out of gas and create exceptions will fundamentally return no data, so simulating it
        // shouldn't either.
        if (
            _flag == RevertFlag.OUT_OF_GAS
        ) {
            return bytes("");
        }

        // INVALID_STATE_ACCESS doesn't need to return any data other than the flag.
        if (_flag == RevertFlag.INVALID_STATE_ACCESS) {
            return abi.encode(
                _flag,
                0,
                0,
                bytes("")
            );
        }

        // Just ABI encode the rest of the parameters.
        return abi.encode(
            _flag,
            messageRecord.nuisanceGasLeft,
            transactionRecord.ovmGasRefund,
            _data
        );
    }

    /**
     * Simple decoding for revert data.
     * @param _revertdata Revert data to decode.
     * @return _flag Flag used to revert.
     * @return _nuisanceGasLeft Amount of nuisance gas unused by the message.
     * @return _ovmGasRefund Amount of gas refunded during the message.
     * @return _data Additional user-provided revert data.
     */
    function _decodeRevertData(
        bytes memory _revertdata
    )
        internal
        pure
        returns (
            RevertFlag _flag,
            uint256 _nuisanceGasLeft,
            uint256 _ovmGasRefund,
            bytes memory _data
        )
    {
        // A length of zero means the call ran out of gas, just return empty data.
        if (_revertdata.length == 0) {
            return (
                RevertFlag.OUT_OF_GAS,
                0,
                0,
                bytes("")
            );
        }

        // ABI decode the incoming data.
        return abi.decode(_revertdata, (RevertFlag, uint256, uint256, bytes));
    }

    /**
     * Causes a message to revert or abort.
     * @param _flag Flag to revert with.
     * @param _data Additional user-provided data.
     */
    function _revertWithFlag(
        RevertFlag _flag,
        bytes memory _data
    )
        internal
        view
    {
        bytes memory revertdata = _encodeRevertData(
            _flag,
            _data
        );

        assembly {
            revert(add(revertdata, 0x20), mload(revertdata))
        }
    }

    /**
     * Causes a message to revert or abort.
     * @param _flag Flag to revert with.
     */
    function _revertWithFlag(
        RevertFlag _flag
    )
        internal
    {
        _revertWithFlag(_flag, bytes(""));
    }


    /******************************************
     * Internal Functions: Nuisance Gas Logic *
     ******************************************/

    /**
     * Computes the nuisance gas limit from the gas limit.
     * @dev This function is currently using a naive implementation whereby the nuisance gas limit
     *      is set to exactly equal the lesser of the gas limit or remaining gas. It's likely that
     *      this implementation is perfectly fine, but we may change this formula later.
     * @param _gasLimit Gas limit to compute from.
     * @return _nuisanceGasLimit Computed nuisance gas limit.
     */
    function _getNuisanceGasLimit(
        uint256 _gasLimit
    )
        internal
        view
        returns (
            uint256 _nuisanceGasLimit
        )
    {
        return _gasLimit < gasleft() ? _gasLimit : gasleft();
    }

    /**
     * Uses a certain amount of nuisance gas.
     * @param _amount Amount of nuisance gas to use.
     */
    function _useNuisanceGas(
        uint256 _amount
    )
        internal
    {
        // Essentially the same as a standard OUT_OF_GAS, except we also retain a record of the gas
        // refund to be given at the end of the transaction.
        if (messageRecord.nuisanceGasLeft < _amount) {
            _revertWithFlag(RevertFlag.EXCEEDS_NUISANCE_GAS);
        }

        messageRecord.nuisanceGasLeft -= _amount;
    }


    /************************************
     * Internal Functions: Gas Metering *
     ************************************/

    /**
     * Checks whether a transaction needs to start a new epoch and does so if necessary.
     * @param _timestamp Transaction timestamp.
     */
    function _checkNeedsNewEpoch(
        uint256 _timestamp
    )
        internal
    {
        if (
            _timestamp >= (
                _getGasMetadata(GasMetadataKey.CURRENT_EPOCH_START_TIMESTAMP)
                + gasMeterConfig.secondsPerEpoch
            )
        ) {
            _putGasMetadata(
                GasMetadataKey.CURRENT_EPOCH_START_TIMESTAMP,
                _timestamp
            );

            _putGasMetadata(
                GasMetadataKey.PREV_EPOCH_SEQUENCER_QUEUE_GAS,
                _getGasMetadata(
                    GasMetadataKey.CUMULATIVE_SEQUENCER_QUEUE_GAS
                )
            );

            _putGasMetadata(
                GasMetadataKey.PREV_EPOCH_L1TOL2_QUEUE_GAS,
                _getGasMetadata(
                    GasMetadataKey.CUMULATIVE_L1TOL2_QUEUE_GAS
                )
            );
        }
    }

    /**
     * Validates the input values of a transaction.
     * @return _valid Whether or not the transaction data is valid.
     */
    function _isValidInput(
        Lib_OVMCodec.Transaction memory _transaction
    )
        view
        internal
        returns (
            bool
        )
    {
        // Prevent reentrancy to run():
        // This check prevents calling run with the default ovmNumber.
        // Combined with the first check in run():
        //      if (transactionContext.ovmNUMBER != DEFAULT_UINT256) { return; }
        // It should be impossible to re-enter since run() returns before any other call frames are
        // created. Since this value is already being written to storage, we save much gas compared
        // to using the standard nonReentrant pattern.
        if (_transaction.blockNumber == DEFAULT_UINT256)  {
            return false;
        }

        if (_isValidGasLimit(_transaction.gasLimit, _transaction.l1QueueOrigin) == false) {
            return false;
        }

        return true;
    }

    /**
     * Validates the gas limit for a given transaction.
     * @param _gasLimit Gas limit provided by the transaction.
     * param _queueOrigin Queue from which the transaction originated.
     * @return _valid Whether or not the gas limit is valid.
     */
    function _isValidGasLimit(
        uint256 _gasLimit,
        Lib_OVMCodec.QueueOrigin // _queueOrigin
    )
        view
        internal
        returns (
            bool _valid
        )
    {
        // Always have to be below the maximum gas limit.
        if (_gasLimit > gasMeterConfig.maxTransactionGasLimit) {
            return false;
        }

        // Always have to be above the minimum gas limit.
        if (_gasLimit < gasMeterConfig.minTransactionGasLimit) {
            return false;
        }

        // TEMPORARY: Gas metering is disabled for minnet.
        return true;
        // GasMetadataKey cumulativeGasKey;
        // GasMetadataKey prevEpochGasKey;
        // if (_queueOrigin == Lib_OVMCodec.QueueOrigin.SEQUENCER_QUEUE) {
        //     cumulativeGasKey = GasMetadataKey.CUMULATIVE_SEQUENCER_QUEUE_GAS;
        //     prevEpochGasKey = GasMetadataKey.PREV_EPOCH_SEQUENCER_QUEUE_GAS;
        // } else {
        //     cumulativeGasKey = GasMetadataKey.CUMULATIVE_L1TOL2_QUEUE_GAS;
        //     prevEpochGasKey = GasMetadataKey.PREV_EPOCH_L1TOL2_QUEUE_GAS;
        // }

        // return (
        //     (
        //         _getGasMetadata(cumulativeGasKey)
        //         - _getGasMetadata(prevEpochGasKey)
        //         + _gasLimit
        //     ) < gasMeterConfig.maxGasPerQueuePerEpoch
        // );
    }

    /**
     * Updates the cumulative gas after a transaction.
     * @param _gasUsed Gas used by the transaction.
     * @param _queueOrigin Queue from which the transaction originated.
     */
    function _updateCumulativeGas(
        uint256 _gasUsed,
        Lib_OVMCodec.QueueOrigin _queueOrigin
    )
        internal
    {
        GasMetadataKey cumulativeGasKey;
        if (_queueOrigin == Lib_OVMCodec.QueueOrigin.SEQUENCER_QUEUE) {
            cumulativeGasKey = GasMetadataKey.CUMULATIVE_SEQUENCER_QUEUE_GAS;
        } else {
            cumulativeGasKey = GasMetadataKey.CUMULATIVE_L1TOL2_QUEUE_GAS;
        }

        _putGasMetadata(
            cumulativeGasKey,
            (
                _getGasMetadata(cumulativeGasKey)
                + gasMeterConfig.minTransactionGasLimit
                + _gasUsed
                - transactionRecord.ovmGasRefund
            )
        );
    }

    /**
     * Retrieves the value of a gas metadata key.
     * @param _key Gas metadata key to retrieve.
     * @return _value Value stored at the given key.
     */
    function _getGasMetadata(
        GasMetadataKey _key
    )
        internal
        returns (
            uint256 _value
        )
    {
        return uint256(_getContractStorage(
            GAS_METADATA_ADDRESS,
            bytes32(uint256(_key))
        ));
    }

    /**
     * Sets the value of a gas metadata key.
     * @param _key Gas metadata key to set.
     * @param _value Value to store at the given key.
     */
    function _putGasMetadata(
        GasMetadataKey _key,
        uint256 _value
    )
        internal
    {
        _putContractStorage(
            GAS_METADATA_ADDRESS,
            bytes32(uint256(_key)),
            bytes32(uint256(_value))
        );
    }


    /*****************************************
     * Internal Functions: Execution Context *
     *****************************************/

    /**
     * Swaps over to a new message context.
     * @param _prevMessageContext Context we're switching from.
     * @param _nextMessageContext Context we're switching to.
     */
    function _switchMessageContext(
        MessageContext memory _prevMessageContext,
        MessageContext memory _nextMessageContext
    )
        internal
    {
        // These conditionals allow us to avoid unneccessary SSTOREs.  However, they do mean that
        // the current storage value for the messageContext MUST equal the _prevMessageContext
        // argument, or an SSTORE might be erroneously skipped.
        if (_prevMessageContext.ovmCALLER != _nextMessageContext.ovmCALLER) {
            messageContext.ovmCALLER = _nextMessageContext.ovmCALLER;
        }

        if (_prevMessageContext.ovmADDRESS != _nextMessageContext.ovmADDRESS) {
            messageContext.ovmADDRESS = _nextMessageContext.ovmADDRESS;
        }

        if (_prevMessageContext.isStatic != _nextMessageContext.isStatic) {
            messageContext.isStatic = _nextMessageContext.isStatic;
        }

        if (_prevMessageContext.ovmCALLVALUE != _nextMessageContext.ovmCALLVALUE) {
            messageContext.ovmCALLVALUE = _nextMessageContext.ovmCALLVALUE;
        }
    }

    /**
     * Initializes the execution context.
     * @param _transaction OVM transaction being executed.
     */
    function _initContext(
        Lib_OVMCodec.Transaction memory _transaction
    )
        internal
    {
        transactionContext.ovmTIMESTAMP = _transaction.timestamp;
        transactionContext.ovmNUMBER = _transaction.blockNumber;
        transactionContext.ovmTXGASLIMIT = _transaction.gasLimit;
        transactionContext.ovmL1QUEUEORIGIN = _transaction.l1QueueOrigin;
        transactionContext.ovmL1TXORIGIN = _transaction.l1TxOrigin;
        transactionContext.ovmGASLIMIT = gasMeterConfig.maxGasPerQueuePerEpoch;

        messageRecord.nuisanceGasLeft = _getNuisanceGasLimit(_transaction.gasLimit);
    }

    /**
     * Resets the transaction and message context.
     */
    function _resetContext()
        internal
    {
        transactionContext.ovmL1TXORIGIN = DEFAULT_ADDRESS;
        transactionContext.ovmTIMESTAMP = DEFAULT_UINT256;
        transactionContext.ovmNUMBER = DEFAULT_UINT256;
        transactionContext.ovmGASLIMIT = DEFAULT_UINT256;
        transactionContext.ovmTXGASLIMIT = DEFAULT_UINT256;
        transactionContext.ovmL1QUEUEORIGIN = Lib_OVMCodec.QueueOrigin.SEQUENCER_QUEUE;

        transactionRecord.ovmGasRefund = DEFAULT_UINT256;

        messageContext.ovmCALLER = DEFAULT_ADDRESS;
        messageContext.ovmADDRESS = DEFAULT_ADDRESS;
        messageContext.isStatic = false;

        messageRecord.nuisanceGasLeft = DEFAULT_UINT256;

        // Reset the ovmStateManager.
        ovmStateManager = iOVM_StateManager(address(0));
    }


    /******************************************
     * Internal Functions: Message Typechecks *
     ******************************************/

    /**
     * Returns whether or not the given message type is a CREATE-type.
     * @param _messageType the message type in question.
     */
    function _isCreateType(
        MessageType _messageType
    )
        internal
        pure
        returns(
            bool
        )
    {
        return (
            _messageType == MessageType.ovmCREATE
            || _messageType == MessageType.ovmCREATE2
        );
    }

    /**
     * Returns whether or not the given message type (potentially) requires the transfer of ETH
     * value along with the message.
     * @param _messageType the message type in question.
     */
    function _isValueType(
        MessageType _messageType
    )
        internal
        pure
        returns(
            bool
        )
    {
        // ovmSTATICCALL and ovmDELEGATECALL types do not accept or transfer value.
        return (
            _messageType == MessageType.ovmCALL
            || _messageType == MessageType.ovmCREATE
            || _messageType == MessageType.ovmCREATE2
        );
    }


    /*****************************
     * L2-only Helper Functions *
     *****************************/

    /**
     * Unreachable helper function for simulating eth_calls with an OVM message context.
     * This function will throw an exception in all cases other than when used as a custom
     * entrypoint in L2 Geth to simulate eth_call.
     * @param _transaction the message transaction to simulate.
     * @param _from the OVM account the simulated call should be from.
     * @param _value the amount of ETH value to send.
     * @param _ovmStateManager the address of the OVM_StateManager precompile in the L2 state.
     */
    function simulateMessage(
        Lib_OVMCodec.Transaction memory _transaction,
        address _from,
        uint256 _value,
        iOVM_StateManager _ovmStateManager
    )
        external
        returns (
            bytes memory
        )
    {
        // Prevent this call from having any effect unless in a custom-set VM frame
        require(msg.sender == address(0));

        // Initialize the EM's internal state, ignoring nuisance gas.
        ovmStateManager = _ovmStateManager;
        _initContext(_transaction);
        messageRecord.nuisanceGasLeft = uint(-1);

        // Set the ovmADDRESS to the _from so that the subsequent call frame "comes from" them.
        messageContext.ovmADDRESS = _from;

        // Execute the desired message.
        bool isCreate = _transaction.entrypoint == address(0);
        if (isCreate) {
            (address created, bytes memory revertData) = ovmCREATE(_transaction.data);
            if (created == address(0)) {
                return abi.encode(false, revertData);
            } else {
                // The eth_call RPC endpoint for to = undefined will return the deployed bytecode
                // in the success case, differing from standard create messages.
                return abi.encode(true, Lib_EthUtils.getCode(created));
            }
        } else {
            (bool success, bytes memory returndata) = ovmCALL(
                _transaction.gasLimit,
                _transaction.entrypoint,
                _value,
                _transaction.data
            );
            return abi.encode(success, returndata);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iOVM_SafetyChecker
 */
interface iOVM_SafetyChecker {

    /********************
     * Public Functions *
     ********************/

    function isBytecodeSafe(bytes calldata _bytecode) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_DeployerWhitelist } from "../../iOVM/predeploys/iOVM_DeployerWhitelist.sol";

/**
 * @title OVM_DeployerWhitelist
 * @dev The Deployer Whitelist is a temporary predeploy used to provide additional safety during the
 * initial phases of our mainnet roll out. It is owned by the Optimism team, and defines accounts
 * which are allowed to deploy contracts on Layer2. The Execution Manager will only allow an
 * ovmCREATE or ovmCREATE2 operation to proceed if the deployer's address whitelisted.
 *
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_DeployerWhitelist is iOVM_DeployerWhitelist {

    /**********************
     * Contract Constants *
     **********************/

    bool public initialized;
    bool public allowArbitraryDeployment;
    address override public owner;
    mapping (address => bool) public whitelist;


    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Blocks functions to anyone except the contract owner.
     */
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Function can only be called by the owner of this contract."
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Initializes the whitelist.
     * @param _owner Address of the owner for this contract.
     * @param _allowArbitraryDeployment Whether or not to allow arbitrary contract deployment.
     */
    function initialize(
        address _owner,
        bool _allowArbitraryDeployment
    )
        override
        external
    {
        if (initialized == true) {
            return;
        }

        initialized = true;
        allowArbitraryDeployment = _allowArbitraryDeployment;
        owner = _owner;
    }

    /**
     * Adds or removes an address from the deployment whitelist.
     * @param _deployer Address to update permissions for.
     * @param _isWhitelisted Whether or not the address is whitelisted.
     */
    function setWhitelistedDeployer(
        address _deployer,
        bool _isWhitelisted
    )
        override
        external
        onlyOwner
    {
        whitelist[_deployer] = _isWhitelisted;
    }

    /**
     * Updates the owner of this contract.
     * @param _owner Address of the new owner.
     */
    function setOwner(
        address _owner
    )
        override
        public
        onlyOwner
    {
        owner = _owner;
    }

    /**
     * Updates the arbitrary deployment flag.
     * @param _allowArbitraryDeployment Whether or not to allow arbitrary contract deployment.
     */
    function setAllowArbitraryDeployment(
        bool _allowArbitraryDeployment
    )
        override
        public
        onlyOwner
    {
        allowArbitraryDeployment = _allowArbitraryDeployment;
    }

    /**
     * Permanently enables arbitrary contract deployment and deletes the owner.
     */
    function enableArbitraryContractDeployment()
        override
        external
        onlyOwner
    {
        setAllowArbitraryDeployment(true);
        setOwner(address(0));
    }

    /**
     * Checks whether an address is allowed to deploy contracts.
     * @param _deployer Address to check.
     * @return _allowed Whether or not the address can deploy contracts.
     */
    function isDeployerAllowed(
        address _deployer
    )
        override
        external
        returns (
            bool
        )
    {
        return (
            initialized == false
            || allowArbitraryDeployment == true
            || whitelist[_deployer]
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iOVM_DeployerWhitelist
 */
interface iOVM_DeployerWhitelist {

    /********************
     * Public Functions *
     ********************/

    function initialize(address _owner, bool _allowArbitraryDeployment) external;
    function owner() external returns (address _owner);
    function setWhitelistedDeployer(address _deployer, bool _isWhitelisted) external;
    function setOwner(address _newOwner) external;
    function setAllowArbitraryDeployment(bool _allowArbitraryDeployment) external;
    function enableArbitraryContractDeployment() external;
    function isDeployerAllowed(address _deployer) external returns (bool _allowed);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_SafetyChecker } from "../../iOVM/execution/iOVM_SafetyChecker.sol";

/**
 * @title OVM_SafetyChecker
 * @dev  The Safety Checker verifies that contracts deployed on L2 do not contain any
 * "unsafe" operations. An operation is considered unsafe if it would access state variables which
 * are specific to the environment (ie. L1 or L2) in which it is executed, as this could be used
 * to "escape the sandbox" of the OVM, resulting in non-deterministic fraud proofs.
 * That is, an attacker would be able to "prove fraud" on an honestly applied transaction.
 * Note that a "safe" contract requires opcodes to appear in a particular pattern;
 * omission of "unsafe" opcodes is necessary, but not sufficient.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_SafetyChecker is iOVM_SafetyChecker {

    /********************
     * Public Functions *
     ********************/

    /**
     * Returns whether or not all of the provided bytecode is safe.
     * @param _bytecode The bytecode to safety check.
     * @return `true` if the bytecode is safe, `false` otherwise.
     */
    function isBytecodeSafe(
        bytes memory _bytecode
    )
        override
        external
        pure
        returns (
            bool
        )
    {
        // autogenerated by gen_safety_checker_constants.py
        // number of bytes to skip for each opcode
        uint256[8] memory opcodeSkippableBytes = [
            uint256(0x0001010101010101010101010000000001010101010101010101010101010000),
            uint256(0x0100000000000000000000000000000000000000010101010101000000010100),
            uint256(0x0000000000000000000000000000000001010101000000010101010100000000),
            uint256(0x0203040500000000000000000000000000000000000000000000000000000000),
            uint256(0x0101010101010101010101010101010101010101010101010101010101010101),
            uint256(0x0101010101000000000000000000000000000000000000000000000000000000),
            uint256(0x0000000000000000000000000000000000000000000000000000000000000000),
            uint256(0x0000000000000000000000000000000000000000000000000000000000000000)
        ];
        // Mask to gate opcode specific cases
        // solhint-disable-next-line max-line-length
        uint256 opcodeGateMask = ~uint256(0xffffffffffffffffffffffe000000000fffffffff070ffff9c0ffffec000f001);
        // Halting opcodes
        // solhint-disable-next-line max-line-length
        uint256 opcodeHaltingMask = ~uint256(0x4008000000000000000000000000000000000000004000000000000000000001);
        // PUSH opcodes
        uint256 opcodePushMask = ~uint256(0xffffffff000000000000000000000000);

        uint256 codeLength;
        uint256 _pc;
        assembly {
            _pc := add(_bytecode, 0x20)
        }
        codeLength = _pc + _bytecode.length;
        do {
            // current opcode: 0x00...0xff
            uint256 opNum;

            /* solhint-disable max-line-length */
            // inline assembly removes the extra add + bounds check
            assembly {
                let word := mload(_pc) //load the next 32 bytes at pc into word

                // Look up number of bytes to skip from opcodeSkippableBytes and then update indexInWord
                // E.g. the 02030405 in opcodeSkippableBytes is the number of bytes to skip for PUSH1->4
                // We repeat this 6 times, thus we can only skip bytes for up to PUSH4 ((1+4) * 6 = 30 < 32).
                // If we see an opcode that is listed as 0 skippable bytes e.g. PUSH5,
                // then we will get stuck on that indexInWord and then opNum will be set to the PUSH5 opcode.
                let indexInWord := byte(0, mload(add(opcodeSkippableBytes, byte(0, word))))
                indexInWord := add(indexInWord, byte(0, mload(add(opcodeSkippableBytes, byte(indexInWord, word)))))
                indexInWord := add(indexInWord, byte(0, mload(add(opcodeSkippableBytes, byte(indexInWord, word)))))
                indexInWord := add(indexInWord, byte(0, mload(add(opcodeSkippableBytes, byte(indexInWord, word)))))
                indexInWord := add(indexInWord, byte(0, mload(add(opcodeSkippableBytes, byte(indexInWord, word)))))
                indexInWord := add(indexInWord, byte(0, mload(add(opcodeSkippableBytes, byte(indexInWord, word)))))
                _pc := add(_pc, indexInWord)

                opNum := byte(indexInWord, word)
            }
            /* solhint-enable max-line-length */

            // + push opcodes
            // + stop opcodes [STOP(0x00),JUMP(0x56),RETURN(0xf3),INVALID(0xfe)]
            // + caller opcode CALLER(0x33)
            // + blacklisted opcodes
            uint256 opBit = 1 << opNum;
            if (opBit & opcodeGateMask == 0) {
                if (opBit & opcodePushMask == 0) {
                    // all pushes are valid opcodes
                    // subsequent bytes are not opcodes. Skip them.
                    _pc += (opNum - 0x5e); // PUSH1 is 0x60, so opNum-0x5f = PUSHed bytes and we
                    // +1 to skip the _pc++; line below in order to save gas ((-0x5f + 1) = -0x5e)
                    continue;
                } else if (opBit & opcodeHaltingMask == 0) {
                    // STOP or JUMP or RETURN or INVALID (Note: REVERT is blacklisted, so not
                    // included here)
                    // We are now inside unreachable code until we hit a JUMPDEST!
                    do {
                        _pc++;
                        assembly {
                            opNum := byte(0, mload(_pc))
                        }
                        // encountered a JUMPDEST
                        if (opNum == 0x5b) break;
                        // skip PUSHed bytes
                        // opNum-0x5f = PUSHed bytes (PUSH1 is 0x60)
                        if ((1 << opNum) & opcodePushMask == 0) _pc += (opNum - 0x5f);
                    } while (_pc < codeLength);
                    // opNum is 0x5b, so we don't continue here since the pc++ is fine
                } else if (opNum == 0x33) { // Caller opcode
                    uint256 firstOps; // next 32 bytes of bytecode
                    uint256 secondOps; // following 32 bytes of bytecode

                    assembly {
                        firstOps := mload(_pc)
                        // 37 bytes total, 5 left over --> 32 - 5 bytes = 27 bytes = 216 bits
                        secondOps := shr(216, mload(add(_pc, 0x20)))
                    }

                    // Call identity precompile
                    // CALLER POP PUSH1 0x00 PUSH1 0x04 GAS CALL
                    // 32 - 8 bytes = 24 bytes = 192
                    if ((firstOps >> 192) == 0x3350600060045af1) {
                        _pc += 8;
                    // Call EM and abort execution if instructed
                    // CALLER PUSH1 0x00 SWAP1 GAS CALL PC PUSH1 0x0E ADD JUMPI RETURNDATASIZE
                    // PUSH1 0x00 DUP1 RETURNDATACOPY RETURNDATASIZE PUSH1 0x00 REVERT JUMPDEST
                    // RETURNDATASIZE PUSH1 0x01 EQ ISZERO PC PUSH1 0x0a ADD JUMPI PUSH1 0x01 PUSH1
                    // 0x00 RETURN JUMPDEST
                    // solhint-disable-next-line max-line-length
                    } else if (firstOps == 0x336000905af158600e01573d6000803e3d6000fd5b3d6001141558600a015760 && secondOps == 0x016000f35b) {
                        _pc += 37;
                    } else {
                        return false;
                    }
                    continue;
                } else {
                    // encountered a non-whitelisted opcode!
                    return false;
                }
            }
            _pc++;
        } while (_pc < codeLength);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";
import { iOVM_StateManagerFactory } from "../../iOVM/execution/iOVM_StateManagerFactory.sol";

/* Contract Imports */
import { OVM_StateManager } from "./OVM_StateManager.sol";

/**
 * @title OVM_StateManagerFactory
 * @dev The State Manager Factory is called by a State Transitioner's init code, to create a new
 * State Manager for use in the Fraud Verification process.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_StateManagerFactory is iOVM_StateManagerFactory {

    /********************
     * Public Functions *
     ********************/

    /**
     * Creates a new OVM_StateManager
     * @param _owner Owner of the created contract.
     * @return New OVM_StateManager instance.
     */
    function create(
        address _owner
    )
        override
        public
        returns (
            iOVM_StateManager
        )
    {
        return new OVM_StateManager(_owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/* Interface Imports */
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";

/**
 * @title OVM_StateManager
 * @dev The State Manager contract holds all storage values for contracts in the OVM. It can only be
 *  written to by the Execution Manager and State Transitioner. It runs on L1 during the setup and
 * execution of a fraud proof.
 * The same logic runs on L2, but has been implemented as a precompile in the L2 go-ethereum client
 * (see https://github.com/ethereum-optimism/go-ethereum/blob/master/core/vm/ovm_state_manager.go).
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_StateManager is iOVM_StateManager {

    /*************
     * Constants *
     *************/

    bytes32 constant internal EMPTY_ACCOUNT_STORAGE_ROOT =
        0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 constant internal EMPTY_ACCOUNT_CODE_HASH =
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    bytes32 constant internal STORAGE_XOR_VALUE =
        0xFEEDFACECAFEBEEFFEEDFACECAFEBEEFFEEDFACECAFEBEEFFEEDFACECAFEBEEF;

    /*************
     * Variables *
     *************/

    address override public owner;
    address override public ovmExecutionManager;
    mapping (address => Lib_OVMCodec.Account) internal accounts;
    mapping (address => mapping (bytes32 => bytes32)) internal contractStorage;
    mapping (address => mapping (bytes32 => bool)) internal verifiedContractStorage;
    mapping (bytes32 => ItemState) internal itemStates;
    uint256 internal totalUncommittedAccounts;
    uint256 internal totalUncommittedContractStorage;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _owner Address of the owner of this contract.
     */
    constructor(
        address _owner
    )
    {
        owner = _owner;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Simple authentication, this contract should only be accessible to the owner
     * (which is expected to be the State Transitioner during `PRE_EXECUTION`
     * or the OVM_ExecutionManager during transaction execution.
     */
    modifier authenticated() {
        // owner is the State Transitioner
        require(
            msg.sender == owner || msg.sender == ovmExecutionManager,
            "Function can only be called by authenticated addresses"
        );
        _;
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Checks whether a given address is allowed to modify this contract.
     * @param _address Address to check.
     * @return Whether or not the address can modify this contract.
     */
    function isAuthenticated(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        return (_address == owner || _address == ovmExecutionManager);
    }

    /**
     * Sets the address of the OVM_ExecutionManager.
     * @param _ovmExecutionManager Address of the OVM_ExecutionManager.
     */
    function setExecutionManager(
        address _ovmExecutionManager
    )
        override
        public
        authenticated
    {
        ovmExecutionManager = _ovmExecutionManager;
    }

    /**
     * Inserts an account into the state.
     * @param _address Address of the account to insert.
     * @param _account Account to insert for the given address.
     */
    function putAccount(
        address _address,
        Lib_OVMCodec.Account memory _account
    )
        override
        public
        authenticated
    {
        accounts[_address] = _account;
    }

    /**
     * Marks an account as empty.
     * @param _address Address of the account to mark.
     */
    function putEmptyAccount(
        address _address
    )
        override
        public
        authenticated
    {
        Lib_OVMCodec.Account storage account = accounts[_address];
        account.storageRoot = EMPTY_ACCOUNT_STORAGE_ROOT;
        account.codeHash = EMPTY_ACCOUNT_CODE_HASH;
    }

    /**
     * Retrieves an account from the state.
     * @param _address Address of the account to retrieve.
     * @return Account for the given address.
     */
    function getAccount(
        address _address
    )
        override
        public
        view
        returns (
            Lib_OVMCodec.Account memory
        )
    {
        return accounts[_address];
    }

    /**
     * Checks whether the state has a given account.
     * @param _address Address of the account to check.
     * @return Whether or not the state has the account.
     */
    function hasAccount(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        return accounts[_address].codeHash != bytes32(0);
    }

    /**
     * Checks whether the state has a given known empty account.
     * @param _address Address of the account to check.
     * @return Whether or not the state has the empty account.
     */
    function hasEmptyAccount(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        return (
            accounts[_address].codeHash == EMPTY_ACCOUNT_CODE_HASH
            && accounts[_address].nonce == 0
        );
    }

    /**
     * Sets the nonce of an account.
     * @param _address Address of the account to modify.
     * @param _nonce New account nonce.
     */
    function setAccountNonce(
        address _address,
        uint256 _nonce
    )
        override
        public
        authenticated
    {
        accounts[_address].nonce = _nonce;
    }

    /**
     * Gets the nonce of an account.
     * @param _address Address of the account to access.
     * @return Nonce of the account.
     */
    function getAccountNonce(
        address _address
    )
        override
        public
        view
        returns (
            uint256
        )
    {
        return accounts[_address].nonce;
    }

    /**
     * Retrieves the Ethereum address of an account.
     * @param _address Address of the account to access.
     * @return Corresponding Ethereum address.
     */
    function getAccountEthAddress(
        address _address
    )
        override
        public
        view
        returns (
            address
        )
    {
        return accounts[_address].ethAddress;
    }

    /**
     * Retrieves the storage root of an account.
     * @param _address Address of the account to access.
     * @return Corresponding storage root.
     */
    function getAccountStorageRoot(
        address _address
    )
        override
        public
        view
        returns (
            bytes32
        )
    {
        return accounts[_address].storageRoot;
    }

    /**
     * Initializes a pending account (during CREATE or CREATE2) with the default values.
     * @param _address Address of the account to initialize.
     */
    function initPendingAccount(
        address _address
    )
        override
        public
        authenticated
    {
        Lib_OVMCodec.Account storage account = accounts[_address];
        account.nonce = 1;
        account.storageRoot = EMPTY_ACCOUNT_STORAGE_ROOT;
        account.codeHash = EMPTY_ACCOUNT_CODE_HASH;
        account.isFresh = true;
    }

    /**
     * Finalizes the creation of a pending account (during CREATE or CREATE2).
     * @param _address Address of the account to finalize.
     * @param _ethAddress Address of the account's associated contract on Ethereum.
     * @param _codeHash Hash of the account's code.
     */
    function commitPendingAccount(
        address _address,
        address _ethAddress,
        bytes32 _codeHash
    )
        override
        public
        authenticated
    {
        Lib_OVMCodec.Account storage account = accounts[_address];
        account.ethAddress = _ethAddress;
        account.codeHash = _codeHash;
    }

    /**
     * Checks whether an account has already been retrieved, and marks it as retrieved if not.
     * @param _address Address of the account to check.
     * @return Whether or not the account was already loaded.
     */
    function testAndSetAccountLoaded(
        address _address
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        return _testAndSetItemState(
            _getItemHash(_address),
            ItemState.ITEM_LOADED
        );
    }

    /**
     * Checks whether an account has already been modified, and marks it as modified if not.
     * @param _address Address of the account to check.
     * @return Whether or not the account was already modified.
     */
    function testAndSetAccountChanged(
        address _address
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        return _testAndSetItemState(
            _getItemHash(_address),
            ItemState.ITEM_CHANGED
        );
    }

    /**
     * Attempts to mark an account as committed.
     * @param _address Address of the account to commit.
     * @return Whether or not the account was committed.
     */
    function commitAccount(
        address _address
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_address);
        if (itemStates[item] != ItemState.ITEM_CHANGED) {
            return false;
        }

        itemStates[item] = ItemState.ITEM_COMMITTED;
        totalUncommittedAccounts -= 1;

        return true;
    }

    /**
     * Increments the total number of uncommitted accounts.
     */
    function incrementTotalUncommittedAccounts()
        override
        public
        authenticated
    {
        totalUncommittedAccounts += 1;
    }

    /**
     * Gets the total number of uncommitted accounts.
     * @return Total uncommitted accounts.
     */
    function getTotalUncommittedAccounts()
        override
        public
        view
        returns (
            uint256
        )
    {
        return totalUncommittedAccounts;
    }

    /**
     * Checks whether a given account was changed during execution.
     * @param _address Address to check.
     * @return Whether or not the account was changed.
     */
    function wasAccountChanged(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_address);
        return itemStates[item] >= ItemState.ITEM_CHANGED;
    }

    /**
     * Checks whether a given account was committed after execution.
     * @param _address Address to check.
     * @return Whether or not the account was committed.
     */
    function wasAccountCommitted(
        address _address
    )
        override
        public
        view
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_address);
        return itemStates[item] >= ItemState.ITEM_COMMITTED;
    }


    /************************************
     * Public Functions: Storage Access *
     ************************************/

    /**
     * Changes a contract storage slot value.
     * @param _contract Address of the contract to modify.
     * @param _key 32 byte storage slot key.
     * @param _value 32 byte storage slot value.
     */
    function putContractStorage(
        address _contract,
        bytes32 _key,
        bytes32 _value
    )
        override
        public
        authenticated
    {
        // A hilarious optimization. `SSTORE`ing a value of `bytes32(0)` is common enough that it's
        // worth populating this with a non-zero value in advance (during the fraud proof
        // initialization phase) to cut the execution-time cost down to 5000 gas.
        contractStorage[_contract][_key] = _value ^ STORAGE_XOR_VALUE;

        // Only used when initially populating the contract storage. OVM_ExecutionManager will
        // perform a `hasContractStorage` INVALID_STATE_ACCESS check before putting any contract
        // storage because writing to zero when the actual value is nonzero causes a gas
        // discrepancy. Could be moved into a new `putVerifiedContractStorage` function, or
        // something along those lines.
        if (verifiedContractStorage[_contract][_key] == false) {
            verifiedContractStorage[_contract][_key] = true;
        }
    }

    /**
     * Retrieves a contract storage slot value.
     * @param _contract Address of the contract to access.
     * @param _key 32 byte storage slot key.
     * @return 32 byte storage slot value.
     */
    function getContractStorage(
        address _contract,
        bytes32 _key
    )
        override
        public
        view
        returns (
            bytes32
        )
    {
        // Storage XOR system doesn't work for newly created contracts that haven't set this
        // storage slot value yet.
        if (
            verifiedContractStorage[_contract][_key] == false
            && accounts[_contract].isFresh
        ) {
            return bytes32(0);
        }

        // See `putContractStorage` for more information about the XOR here.
        return contractStorage[_contract][_key] ^ STORAGE_XOR_VALUE;
    }

    /**
     * Checks whether a contract storage slot exists in the state.
     * @param _contract Address of the contract to access.
     * @param _key 32 byte storage slot key.
     * @return Whether or not the key was set in the state.
     */
    function hasContractStorage(
        address _contract,
        bytes32 _key
    )
        override
        public
        view
        returns (
            bool
        )
    {
        return verifiedContractStorage[_contract][_key] || accounts[_contract].isFresh;
    }

    /**
     * Checks whether a storage slot has already been retrieved, and marks it as retrieved if not.
     * @param _contract Address of the contract to check.
     * @param _key 32 byte storage slot key.
     * @return Whether or not the slot was already loaded.
     */
    function testAndSetContractStorageLoaded(
        address _contract,
        bytes32 _key
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        return _testAndSetItemState(
            _getItemHash(_contract, _key),
            ItemState.ITEM_LOADED
        );
    }

    /**
     * Checks whether a storage slot has already been modified, and marks it as modified if not.
     * @param _contract Address of the contract to check.
     * @param _key 32 byte storage slot key.
     * @return Whether or not the slot was already modified.
     */
    function testAndSetContractStorageChanged(
        address _contract,
        bytes32 _key
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        return _testAndSetItemState(
            _getItemHash(_contract, _key),
            ItemState.ITEM_CHANGED
        );
    }

    /**
     * Attempts to mark a storage slot as committed.
     * @param _contract Address of the account to commit.
     * @param _key 32 byte slot key to commit.
     * @return Whether or not the slot was committed.
     */
    function commitContractStorage(
        address _contract,
        bytes32 _key
    )
        override
        public
        authenticated
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_contract, _key);
        if (itemStates[item] != ItemState.ITEM_CHANGED) {
            return false;
        }

        itemStates[item] = ItemState.ITEM_COMMITTED;
        totalUncommittedContractStorage -= 1;

        return true;
    }

    /**
     * Increments the total number of uncommitted storage slots.
     */
    function incrementTotalUncommittedContractStorage()
        override
        public
        authenticated
    {
        totalUncommittedContractStorage += 1;
    }

    /**
     * Gets the total number of uncommitted storage slots.
     * @return Total uncommitted storage slots.
     */
    function getTotalUncommittedContractStorage()
        override
        public
        view
        returns (
            uint256
        )
    {
        return totalUncommittedContractStorage;
    }

    /**
     * Checks whether a given storage slot was changed during execution.
     * @param _contract Address to check.
     * @param _key Key of the storage slot to check.
     * @return Whether or not the storage slot was changed.
     */
    function wasContractStorageChanged(
        address _contract,
        bytes32 _key
    )
        override
        public
        view
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_contract, _key);
        return itemStates[item] >= ItemState.ITEM_CHANGED;
    }

    /**
     * Checks whether a given storage slot was committed after execution.
     * @param _contract Address to check.
     * @param _key Key of the storage slot to check.
     * @return Whether or not the storage slot was committed.
     */
    function wasContractStorageCommitted(
        address _contract,
        bytes32 _key
    )
        override
        public
        view
        returns (
            bool
        )
    {
        bytes32 item = _getItemHash(_contract, _key);
        return itemStates[item] >= ItemState.ITEM_COMMITTED;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Generates a unique hash for an address.
     * @param _address Address to generate a hash for.
     * @return Unique hash for the given address.
     */
    function _getItemHash(
        address _address
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(abi.encodePacked(_address));
    }

    /**
     * Generates a unique hash for an address/key pair.
     * @param _contract Address to generate a hash for.
     * @param _key Key to generate a hash for.
     * @return Unique hash for the given pair.
     */
    function _getItemHash(
        address _contract,
        bytes32 _key
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(abi.encodePacked(
            _contract,
            _key
        ));
    }

    /**
     * Checks whether an item is in a particular state (ITEM_LOADED or ITEM_CHANGED) and sets the
     * item to the provided state if not.
     * @param _item 32 byte item ID to check.
     * @param _minItemState Minimum state that must be satisfied by the item.
     * @return Whether or not the item was already in the state.
     */
    function _testAndSetItemState(
        bytes32 _item,
        ItemState _minItemState
    )
        internal
        returns (
            bool
        )
    {
        bool wasItemState = itemStates[_item] >= _minItemState;

        if (wasItemState == false) {
            itemStates[_item] = _minItemState;
        }

        return wasItemState;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../optimistic-ethereum/libraries/codec/Lib_OVMCodec.sol";

/**
 * @title TestLib_OVMCodec
 */
contract TestLib_OVMCodec {
    function encodeTransaction(
        Lib_OVMCodec.Transaction memory _transaction
    )
        public
        pure
        returns (
            bytes memory _encoded
        )
    {
        return Lib_OVMCodec.encodeTransaction(_transaction);
    }

    function hashTransaction(
        Lib_OVMCodec.Transaction memory _transaction
    )
        public
        pure
        returns (
            bytes32 _hash
        )
    {
        return Lib_OVMCodec.hashTransaction(_transaction);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_AddressResolver } from "../../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_OVMCodec } from "../../../libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressManager } from "../../../libraries/resolver/Lib_AddressManager.sol";
import { Lib_SecureMerkleTrie } from "../../../libraries/trie/Lib_SecureMerkleTrie.sol";
import { Lib_PredeployAddresses } from "../../../libraries/constants/Lib_PredeployAddresses.sol";
import { Lib_CrossDomainUtils } from "../../../libraries/bridge/Lib_CrossDomainUtils.sol";

/* Interface Imports */
import { iOVM_L1CrossDomainMessenger } from
    "../../../iOVM/bridge/messaging/iOVM_L1CrossDomainMessenger.sol";
import { iOVM_CanonicalTransactionChain } from
    "../../../iOVM/chain/iOVM_CanonicalTransactionChain.sol";
import { iOVM_StateCommitmentChain } from "../../../iOVM/chain/iOVM_StateCommitmentChain.sol";

/* External Imports */
import { OwnableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from
    "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title OVM_L1CrossDomainMessenger
 * @dev The L1 Cross Domain Messenger contract sends messages from L1 to L2, and relays messages
 * from L2 onto L1. In the event that a message sent from L1 to L2 is rejected for exceeding the L2
 * epoch gas limit, it can be resubmitted via this contract's replay function.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_L1CrossDomainMessenger is
        iOVM_L1CrossDomainMessenger,
        Lib_AddressResolver,
        OwnableUpgradeable,
        PausableUpgradeable,
        ReentrancyGuardUpgradeable
{

    /**********
     * Events *
     **********/

    event MessageBlocked(
        bytes32 indexed _xDomainCalldataHash
    );

    event MessageAllowed(
        bytes32 indexed _xDomainCalldataHash
    );

    /*************
     * Constants *
     *************/

    // The default x-domain message sender being set to a non-zero value makes
    // deployment a bit more expensive, but in exchange the refund on every call to
    // `relayMessage` by the L1 and L2 messengers will be higher.
    address internal constant DEFAULT_XDOMAIN_SENDER = 0x000000000000000000000000000000000000dEaD;

    /**********************
     * Contract Variables *
     **********************/

    mapping (bytes32 => bool) public blockedMessages;
    mapping (bytes32 => bool) public relayedMessages;
    mapping (bytes32 => bool) public successfulMessages;

    address internal xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

    /***************
     * Constructor *
     ***************/

    /**
     * This contract is intended to be behind a delegate proxy.
     * We pass the zero address to the address resolver just to satisfy the constructor.
     * We still need to set this value in initialize().
     */
    constructor()
        Lib_AddressResolver(address(0))
    {}

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Modifier to enforce that, if configured, only the OVM_L2MessageRelayer contract may
     * successfully call a method.
     */
    modifier onlyRelayer() {
        address relayer = resolve("OVM_L2MessageRelayer");
        if (relayer != address(0)) {
            require(
                msg.sender == relayer,
                "Only OVM_L2MessageRelayer can relay L2-to-L1 messages."
            );
        }
        _;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    function initialize(
        address _libAddressManager
    )
        public
        initializer
    {
        require(
            address(libAddressManager) == address(0),
            "L1CrossDomainMessenger already intialized."
        );
        libAddressManager = Lib_AddressManager(_libAddressManager);
        xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

        // Initialize upgradable OZ contracts
        __Context_init_unchained(); // Context is a dependency for both Ownable and Pausable
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /**
     * Pause relaying.
     */
    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    /**
     * Block a message.
     * @param _xDomainCalldataHash Hash of the message to block.
     */
    function blockMessage(
        bytes32 _xDomainCalldataHash
    )
        external
        onlyOwner
    {
        blockedMessages[_xDomainCalldataHash] = true;
        emit MessageBlocked(_xDomainCalldataHash);
    }

    /**
     * Allow a message.
     * @param _xDomainCalldataHash Hash of the message to block.
     */
    function allowMessage(
        bytes32 _xDomainCalldataHash
    )
        external
        onlyOwner
    {
        blockedMessages[_xDomainCalldataHash] = false;
        emit MessageAllowed(_xDomainCalldataHash);
    }

    function xDomainMessageSender()
        public
        override
        view
        returns (
            address
        )
    {
        require(xDomainMsgSender != DEFAULT_XDOMAIN_SENDER, "xDomainMessageSender is not set");
        return xDomainMsgSender;
    }

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    )
        override
        public
    {
        address ovmCanonicalTransactionChain = resolve("OVM_CanonicalTransactionChain");
        // Use the CTC queue length as nonce
        uint40 nonce =
            iOVM_CanonicalTransactionChain(ovmCanonicalTransactionChain).getQueueLength();

        bytes memory xDomainCalldata = Lib_CrossDomainUtils.encodeXDomainCalldata(
            _target,
            msg.sender,
            _message,
            nonce
        );

        address l2CrossDomainMessenger = resolve("OVM_L2CrossDomainMessenger");
        _sendXDomainMessage(
            ovmCanonicalTransactionChain,
            l2CrossDomainMessenger,
            xDomainCalldata,
            _gasLimit
        );
        emit SentMessage(xDomainCalldata);
    }

    /**
     * Relays a cross domain message to a contract.
     * @inheritdoc iOVM_L1CrossDomainMessenger
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce,
        L2MessageInclusionProof memory _proof
    )
        override
        public
        nonReentrant
        onlyRelayer
        whenNotPaused
    {
        bytes memory xDomainCalldata = Lib_CrossDomainUtils.encodeXDomainCalldata(
            _target,
            _sender,
            _message,
            _messageNonce
        );

        require(
            _verifyXDomainMessage(
                xDomainCalldata,
                _proof
            ) == true,
            "Provided message could not be verified."
        );

        bytes32 xDomainCalldataHash = keccak256(xDomainCalldata);

        require(
            successfulMessages[xDomainCalldataHash] == false,
            "Provided message has already been received."
        );

        require(
            blockedMessages[xDomainCalldataHash] == false,
            "Provided message has been blocked."
        );

        require(
            _target != resolve("OVM_CanonicalTransactionChain"),
            "Cannot send L2->L1 messages to L1 system contracts."
        );

        xDomainMsgSender = _sender;
        (bool success, ) = _target.call(_message);
        xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

        // Mark the message as received if the call was successful. Ensures that a message can be
        // relayed multiple times in the case that the call reverted.
        if (success == true) {
            successfulMessages[xDomainCalldataHash] = true;
            emit RelayedMessage(xDomainCalldataHash);
        } else {
            emit FailedRelayedMessage(xDomainCalldataHash);
        }

        // Store an identifier that can be used to prove that the given message was relayed by some
        // user. Gives us an easy way to pay relayers for their work.
        bytes32 relayId = keccak256(
            abi.encodePacked(
                xDomainCalldata,
                msg.sender,
                block.number
            )
        );
        relayedMessages[relayId] = true;
    }

    /**
     * Replays a cross domain message to the target messenger.
     * @inheritdoc iOVM_L1CrossDomainMessenger
     */
    function replayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _queueIndex,
        uint32 _gasLimit
    )
        override
        public
    {
        // Verify that the message is in the queue:
        address canonicalTransactionChain = resolve("OVM_CanonicalTransactionChain");
        Lib_OVMCodec.QueueElement memory element =
            iOVM_CanonicalTransactionChain(canonicalTransactionChain).getQueueElement(_queueIndex);

        address l2CrossDomainMessenger = resolve("OVM_L2CrossDomainMessenger");
        // Compute the transactionHash
        bytes32 transactionHash = keccak256(
            abi.encode(
                address(this),
                l2CrossDomainMessenger,
                _gasLimit,
                _message
            )
        );

        require(
            transactionHash == element.transactionHash,
            "Provided message has not been enqueued."
        );

        bytes memory xDomainCalldata = Lib_CrossDomainUtils.encodeXDomainCalldata(
            _target,
            _sender,
            _message,
            _queueIndex
        );

        _sendXDomainMessage(
            canonicalTransactionChain,
            l2CrossDomainMessenger,
            xDomainCalldata,
            _gasLimit
        );
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Verifies that the given message is valid.
     * @param _xDomainCalldata Calldata to verify.
     * @param _proof Inclusion proof for the message.
     * @return Whether or not the provided message is valid.
     */
    function _verifyXDomainMessage(
        bytes memory _xDomainCalldata,
        L2MessageInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        return (
            _verifyStateRootProof(_proof)
            && _verifyStorageProof(_xDomainCalldata, _proof)
        );
    }

    /**
     * Verifies that the state root within an inclusion proof is valid.
     * @param _proof Message inclusion proof.
     * @return Whether or not the provided proof is valid.
     */
    function _verifyStateRootProof(
        L2MessageInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        iOVM_StateCommitmentChain ovmStateCommitmentChain = iOVM_StateCommitmentChain(
            resolve("OVM_StateCommitmentChain")
        );

        return (
            ovmStateCommitmentChain.insideFraudProofWindow(_proof.stateRootBatchHeader) == false
            && ovmStateCommitmentChain.verifyStateCommitment(
                _proof.stateRoot,
                _proof.stateRootBatchHeader,
                _proof.stateRootProof
            )
        );
    }

    /**
     * Verifies that the storage proof within an inclusion proof is valid.
     * @param _xDomainCalldata Encoded message calldata.
     * @param _proof Message inclusion proof.
     * @return Whether or not the provided proof is valid.
     */
    function _verifyStorageProof(
        bytes memory _xDomainCalldata,
        L2MessageInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        bytes32 storageKey = keccak256(
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(
                        _xDomainCalldata,
                        resolve("OVM_L2CrossDomainMessenger")
                    )
                ),
                uint256(0)
            )
        );

        (
            bool exists,
            bytes memory encodedMessagePassingAccount
        ) = Lib_SecureMerkleTrie.get(
            abi.encodePacked(Lib_PredeployAddresses.L2_TO_L1_MESSAGE_PASSER),
            _proof.stateTrieWitness,
            _proof.stateRoot
        );

        require(
            exists == true,
            "Message passing predeploy has not been initialized or invalid proof provided."
        );

        Lib_OVMCodec.EVMAccount memory account = Lib_OVMCodec.decodeEVMAccount(
            encodedMessagePassingAccount
        );

        return Lib_SecureMerkleTrie.verifyInclusionProof(
            abi.encodePacked(storageKey),
            abi.encodePacked(uint8(1)),
            _proof.storageTrieWitness,
            account.storageRoot
        );
    }

    /**
     * Sends a cross domain message.
     * @param _canonicalTransactionChain Address of the OVM_CanonicalTransactionChain instance.
     * @param _l2CrossDomainMessenger Address of the OVM_L2CrossDomainMessenger instance.
     * @param _message Message to send.
     * @param _gasLimit OVM gas limit for the message.
     */
    function _sendXDomainMessage(
        address _canonicalTransactionChain,
        address _l2CrossDomainMessenger,
        bytes memory _message,
        uint256 _gasLimit
    )
        internal
    {
        iOVM_CanonicalTransactionChain(_canonicalTransactionChain).enqueue(
            _l2CrossDomainMessenger,
            _gasLimit,
            _message
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPReader } from "../rlp/Lib_RLPReader.sol";

/**
 * @title Lib_CrossDomainUtils
 */
library Lib_CrossDomainUtils {
    /**
     * Generates the correct cross domain calldata for a message.
     * @param _target Target contract address.
     * @param _sender Message sender address.
     * @param _message Message to send to the target.
     * @param _messageNonce Nonce for the provided message.
     * @return ABI encoded cross domain calldata.
     */
    function encodeXDomainCalldata(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return abi.encodeWithSignature(
            "relayMessage(address,address,bytes,uint256)",
            _target,
            _sender,
            _message,
            _messageNonce
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../../libraries/codec/Lib_OVMCodec.sol";

/* Interface Imports */
import { iOVM_CrossDomainMessenger } from "./iOVM_CrossDomainMessenger.sol";

/**
 * @title iOVM_L1CrossDomainMessenger
 */
interface iOVM_L1CrossDomainMessenger is iOVM_CrossDomainMessenger {

    /*******************
     * Data Structures *
     *******************/

    struct L2MessageInclusionProof {
        bytes32 stateRoot;
        Lib_OVMCodec.ChainBatchHeader stateRootBatchHeader;
        Lib_OVMCodec.ChainInclusionProof stateRootProof;
        bytes stateTrieWitness;
        bytes storageTrieWitness;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Relays a cross domain message to a contract.
     * @param _target Target contract address.
     * @param _sender Message sender address.
     * @param _message Message to send to the target.
     * @param _messageNonce Nonce for the provided message.
     * @param _proof Inclusion proof for the given message.
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce,
        L2MessageInclusionProof memory _proof
    ) external;

    /**
     * Replays a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _sender Original sender address.
     * @param _message Message to send to the target.
     * @param _queueIndex CTC Queue index for the message to replay.
     * @param _gasLimit Gas limit for the provided message.
     */
    function replayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _queueIndex,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_L1CrossDomainMessenger } from
    "../../../iOVM/bridge/messaging/iOVM_L1CrossDomainMessenger.sol";
import { iOVM_L1MultiMessageRelayer } from
    "../../../iOVM/bridge/messaging/iOVM_L1MultiMessageRelayer.sol";

/* Library Imports */
import { Lib_AddressResolver } from "../../../libraries/resolver/Lib_AddressResolver.sol";

/**
 * @title OVM_L1MultiMessageRelayer
 * @dev The L1 Multi-Message Relayer contract is a gas efficiency optimization which enables the
 * relayer to submit multiple messages in a single transaction to be relayed by the L1 Cross Domain
 * Message Sender.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_L1MultiMessageRelayer is iOVM_L1MultiMessageRelayer, Lib_AddressResolver {

    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    constructor(
        address _libAddressManager
    )
        Lib_AddressResolver(_libAddressManager)
    {}


    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyBatchRelayer() {
        require(
            msg.sender == resolve("OVM_L2BatchMessageRelayer"),
            // solhint-disable-next-line max-line-length
            "OVM_L1MultiMessageRelayer: Function can only be called by the OVM_L2BatchMessageRelayer"
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * @notice Forwards multiple cross domain messages to the L1 Cross Domain Messenger for relaying
     * @param _messages An array of L2 to L1 messages
     */
    function batchRelayMessages(
        L2ToL1Message[] calldata _messages
    )
        override
        external
        onlyBatchRelayer
    {
        iOVM_L1CrossDomainMessenger messenger = iOVM_L1CrossDomainMessenger(
            resolve("Proxy__OVM_L1CrossDomainMessenger")
        );

        for (uint256 i = 0; i < _messages.length; i++) {
            L2ToL1Message memory message = _messages[i];
            messenger.relayMessage(
                message.target,
                message.sender,
                message.message,
                message.messageNonce,
                message.proof
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_L1CrossDomainMessenger } from
    "../../../iOVM/bridge/messaging/iOVM_L1CrossDomainMessenger.sol";

interface iOVM_L1MultiMessageRelayer {

    struct L2ToL1Message {
        address target;
        address sender;
        bytes message;
        uint256 messageNonce;
        iOVM_L1CrossDomainMessenger.L2MessageInclusionProof proof;
    }

    function batchRelayMessages(L2ToL1Message[] calldata _messages) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_AddressResolver } from "../../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_CrossDomainUtils } from "../../../libraries/bridge/Lib_CrossDomainUtils.sol";

/* Interface Imports */
import { iOVM_L2CrossDomainMessenger } from
    "../../../iOVM/bridge/messaging/iOVM_L2CrossDomainMessenger.sol";
import { iOVM_L1MessageSender } from "../../../iOVM/predeploys/iOVM_L1MessageSender.sol";
import { iOVM_L2ToL1MessagePasser } from "../../../iOVM/predeploys/iOVM_L2ToL1MessagePasser.sol";

/* External Imports */
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/* External Imports */
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title OVM_L2CrossDomainMessenger
 * @dev The L2 Cross Domain Messenger contract sends messages from L2 to L1, and is the entry point
 * for L2 messages sent via the L1 Cross Domain Messenger.
 *
 * Compiler used: optimistic-solc
 * Runtime target: OVM
  */
contract OVM_L2CrossDomainMessenger is
    iOVM_L2CrossDomainMessenger,
    Lib_AddressResolver,
    ReentrancyGuard
{

    /*************
     * Constants *
     *************/

    // The default x-domain message sender being set to a non-zero value makes
    // deployment a bit more expensive, but in exchange the refund on every call to
    // `relayMessage` by the L1 and L2 messengers will be higher.
    address internal constant DEFAULT_XDOMAIN_SENDER = 0x000000000000000000000000000000000000dEaD;

    /*************
     * Variables *
     *************/

    mapping (bytes32 => bool) public relayedMessages;
    mapping (bytes32 => bool) public successfulMessages;
    mapping (bytes32 => bool) public sentMessages;
    uint256 public messageNonce;
    address internal xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    constructor(address _libAddressManager)
        Lib_AddressResolver(_libAddressManager)
        ReentrancyGuard()
        {}

    /********************
     * Public Functions *
     ********************/

    function xDomainMessageSender()
        public
        override
        view
        returns (
            address
        )
    {
        require(xDomainMsgSender != DEFAULT_XDOMAIN_SENDER, "xDomainMessageSender is not set");
        return xDomainMsgSender;
    }

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    )
        override
        public
    {
        bytes memory xDomainCalldata = Lib_CrossDomainUtils.encodeXDomainCalldata(
            _target,
            msg.sender,
            _message,
            messageNonce
        );

        messageNonce += 1;
        sentMessages[keccak256(xDomainCalldata)] = true;

        _sendXDomainMessage(xDomainCalldata, _gasLimit);
        emit SentMessage(xDomainCalldata);
    }

    /**
     * Relays a cross domain message to a contract.
     * @inheritdoc iOVM_L2CrossDomainMessenger
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce
    )
        override
        nonReentrant
        public
    {
        require(
            _verifyXDomainMessage() == true,
            "Provided message could not be verified."
        );

        bytes memory xDomainCalldata = Lib_CrossDomainUtils.encodeXDomainCalldata(
            _target,
            _sender,
            _message,
            _messageNonce
        );

        bytes32 xDomainCalldataHash = keccak256(xDomainCalldata);

        require(
            successfulMessages[xDomainCalldataHash] == false,
            "Provided message has already been received."
        );

        // Prevent calls to OVM_L2ToL1MessagePasser, which would enable
        // an attacker to maliciously craft the _message to spoof
        // a call from any L2 account.
        if(_target == resolve("OVM_L2ToL1MessagePasser")){
            // Write to the successfulMessages mapping and return immediately.
            successfulMessages[xDomainCalldataHash] = true;
            return;
        }

        xDomainMsgSender = _sender;
        (bool success, ) = _target.call(_message);
        xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

        // Mark the message as received if the call was successful. Ensures that a message can be
        // relayed multiple times in the case that the call reverted.
        if (success == true) {
            successfulMessages[xDomainCalldataHash] = true;
            emit RelayedMessage(xDomainCalldataHash);
        } else {
            emit FailedRelayedMessage(xDomainCalldataHash);
        }

        // Store an identifier that can be used to prove that the given message was relayed by some
        // user. Gives us an easy way to pay relayers for their work.
        bytes32 relayId = keccak256(
            abi.encodePacked(
                xDomainCalldata,
                msg.sender,
                block.number
            )
        );

        relayedMessages[relayId] = true;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Verifies that a received cross domain message is valid.
     * @return _valid Whether or not the message is valid.
     */
    function _verifyXDomainMessage()
        view
        internal
        returns (
            bool _valid
        )
    {
        return (
            iOVM_L1MessageSender(
                resolve("OVM_L1MessageSender")
            ).getL1MessageSender() == resolve("OVM_L1CrossDomainMessenger")
        );
    }

    /**
     * Sends a cross domain message.
     * @param _message Message to send.
     * param _gasLimit Gas limit for the provided message.
     */
    function _sendXDomainMessage(
        bytes memory _message,
        uint256 // _gasLimit
    )
        internal
    {
        iOVM_L2ToL1MessagePasser(resolve("OVM_L2ToL1MessagePasser")).passMessageToL1(_message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_CrossDomainMessenger } from "./iOVM_CrossDomainMessenger.sol";

/**
 * @title iOVM_L2CrossDomainMessenger
 */
interface iOVM_L2CrossDomainMessenger is iOVM_CrossDomainMessenger {

    /********************
     * Public Functions *
     ********************/

    /**
     * Relays a cross domain message to a contract.
     * @param _target Target contract address.
     * @param _sender Message sender address.
     * @param _message Message to send to the target.
     * @param _messageNonce Nonce for the provided message.
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iOVM_L1MessageSender
 */
interface iOVM_L1MessageSender {

    /********************
     * Public Functions *
     ********************/

    function getL1MessageSender() external view returns (address _l1MessageSender);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iOVM_L2ToL1MessagePasser
 */
interface iOVM_L2ToL1MessagePasser {

    /**********
     * Events *
     **********/

    event L2ToL1Message(
        uint256 _nonce,
        address _sender,
        bytes _data
    );


    /********************
     * Public Functions *
     ********************/

    function passMessageToL1(bytes calldata _message) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_L2ToL1MessagePasser } from "../../iOVM/predeploys/iOVM_L2ToL1MessagePasser.sol";

/**
 * @title OVM_L2ToL1MessagePasser
 * @dev The L2 to L1 Message Passer is a utility contract which facilitate an L1 proof of the
 * of a message on L2. The L1 Cross Domain Messenger performs this proof in its
 * _verifyStorageProof function, which verifies the existence of the transaction hash in this
 * contract's `sentMessages` mapping.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_L2ToL1MessagePasser is iOVM_L2ToL1MessagePasser {

    /**********************
     * Contract Variables *
     **********************/

    mapping (bytes32 => bool) public sentMessages;

    /********************
     * Public Functions *
     ********************/

    /**
     * Passes a message to L1.
     * @param _message Message to pass to L1.
     */
    function passMessageToL1(
        bytes memory _message
    )
        override
        public
    {
        // Note: although this function is public, only messages sent from the
        // OVM_L2CrossDomainMessenger will be relayed by the OVM_L1CrossDomainMessenger.
        // This is enforced by a check in OVM_L1CrossDomainMessenger._verifyStorageProof().
        sentMessages[keccak256(
            abi.encodePacked(
                _message,
                msg.sender
            )
        )] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_L1MessageSender } from "../../iOVM/predeploys/iOVM_L1MessageSender.sol";
import { iOVM_ExecutionManager } from "../../iOVM/execution/iOVM_ExecutionManager.sol";

/**
 * @title OVM_L1MessageSender
 * @dev The L1MessageSender is a predeploy contract running on L2. During the execution of cross
 * domain transaction from L1 to L2, it returns the address of the L1 account (either an EOA or
 * contract) which sent the message to L2 via the Canonical Transaction Chain's `enqueue()`
 * function.
 *
 * This contract exclusively serves as a getter for the ovmL1TXORIGIN operation. This is necessary
 * because there is no corresponding operation in the EVM which the the optimistic solidity compiler
 * can be replaced with a call to the ExecutionManager's ovmL1TXORIGIN() function.
 *
 *
 * Compiler used: solc
 * Runtime target: OVM
 */
contract OVM_L1MessageSender is iOVM_L1MessageSender {

    /********************
     * Public Functions *
     ********************/

    /**
     * @return _l1MessageSender L1 message sender address (msg.sender).
     */
    function getL1MessageSender()
        override
        public
        view
        returns (
            address _l1MessageSender
        )
    {
        // Note that on L2 msg.sender (ie. evmCALLER) will always be the Execution Manager
        return iOVM_ExecutionManager(msg.sender).ovmL1TXORIGIN();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPReader } from "../../optimistic-ethereum/libraries/rlp/Lib_RLPReader.sol";

/**
 * @title TestLib_RLPReader
 */
contract TestLib_RLPReader {

    function readList(
        bytes memory _in
    )
        public
        pure
        returns (
            bytes[] memory
        )
    {
        Lib_RLPReader.RLPItem[] memory decoded = Lib_RLPReader.readList(_in);
        bytes[] memory out = new bytes[](decoded.length);
        for (uint256 i = 0; i < out.length; i++) {
            out[i] = Lib_RLPReader.readRawBytes(decoded[i]);
        }
        return out;
    }

    function readString(
        bytes memory _in
    )
        public
        pure
        returns (
            string memory
        )
    {
        return Lib_RLPReader.readString(_in);
    }

    function readBytes(
        bytes memory _in
    )
        public
        pure
        returns (
            bytes memory
        )
    {
        return Lib_RLPReader.readBytes(_in);
    }

    function readBytes32(
        bytes memory _in
    )
        public
        pure
        returns (
            bytes32
        )
    {
        return Lib_RLPReader.readBytes32(_in);
    }

    function readUint256(
        bytes memory _in
    )
        public
        pure
        returns (
            uint256
        )
    {
        return Lib_RLPReader.readUint256(_in);
    }

    function readBool(
        bytes memory _in
    )
        public
        pure
        returns (
            bool
        )
    {
        return Lib_RLPReader.readBool(_in);
    }

    function readAddress(
        bytes memory _in
    )
        public
        pure
        returns (
            address
        )
    {
        return Lib_RLPReader.readAddress(_in);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_MerkleTrie } from "../../optimistic-ethereum/libraries/trie/Lib_MerkleTrie.sol";

/**
 * @title TestLib_MerkleTrie
 */
contract TestLib_MerkleTrie {

    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        public
        pure
        returns (
            bool
        )
    {
        return Lib_MerkleTrie.verifyInclusionProof(
            _key,
            _value,
            _proof,
            _root
        );
    }

    function update(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        public
        pure
        returns (
            bytes32
        )
    {
        return Lib_MerkleTrie.update(
            _key,
            _value,
            _proof,
            _root
        );
    }

    function get(
        bytes memory _key,
        bytes memory _proof,
        bytes32 _root
    )
        public
        pure
        returns (
            bool,
            bytes memory
        )
    {
        return Lib_MerkleTrie.get(
            _key,
            _proof,
            _root
        );
    }

    function getSingleNodeRootHash(
        bytes memory _key,
        bytes memory _value
    )
        public
        pure
        returns (
            bytes32
        )
    {
        return Lib_MerkleTrie.getSingleNodeRootHash(
            _key,
            _value
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_SecureMerkleTrie } from "../../optimistic-ethereum/libraries/trie/Lib_SecureMerkleTrie.sol";

/**
 * @title TestLib_SecureMerkleTrie
 */
contract TestLib_SecureMerkleTrie {

    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        public
        pure
        returns (
            bool
        )
    {
        return Lib_SecureMerkleTrie.verifyInclusionProof(
            _key,
            _value,
            _proof,
            _root
        );
    }

    function update(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        public
        pure
        returns (
            bytes32
        )
    {
        return Lib_SecureMerkleTrie.update(
            _key,
            _value,
            _proof,
            _root
        );
    }

    function get(
        bytes memory _key,
        bytes memory _proof,
        bytes32 _root
    )
        public
        pure
        returns (
            bool,
            bytes memory
        )
    {
        return Lib_SecureMerkleTrie.get(
            _key,
            _proof,
            _root
        );
    }

    function getSingleNodeRootHash(
        bytes memory _key,
        bytes memory _value
    )
        public
        pure
        returns (
            bytes32
        )
    {
        return Lib_SecureMerkleTrie.getSingleNodeRootHash(
            _key,
            _value
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_AddressManager } from "./Lib_AddressManager.sol";

/**
 * @title Lib_ResolvedDelegateProxy
 */
contract Lib_ResolvedDelegateProxy {

    /*************
     * Variables *
     *************/

    // Using mappings to store fields to avoid overwriting storage slots in the
    // implementation contract. For example, instead of storing these fields at
    // storage slot `0` & `1`, they are stored at `keccak256(key + slot)`.
    // See: https://solidity.readthedocs.io/en/v0.7.0/internals/layout_in_storage.html
    // NOTE: Do not use this code in your own contract system.
    //      There is a known flaw in this contract, and we will remove it from the repository
    //      in the near future. Due to the very limited way that we are using it, this flaw is
    //      not an issue in our system.
    mapping (address => string) private implementationName;
    mapping (address => Lib_AddressManager) private addressManager;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     * @param _implementationName implementationName of the contract to proxy to.
     */
    constructor(
        address _libAddressManager,
        string memory _implementationName
    ) {
        addressManager[address(this)] = Lib_AddressManager(_libAddressManager);
        implementationName[address(this)] = _implementationName;
    }


    /*********************
     * Fallback Function *
     *********************/

    fallback()
        external
        payable
    {
        address target = addressManager[address(this)].getAddress(
            (implementationName[address(this)])
        );

        require(
            target != address(0),
            "Target address must be initialized."
        );

        (bool success, bytes memory returndata) = target.delegatecall(msg.data);

        if (success == true) {
            assembly {
                return(add(returndata, 0x20), mload(returndata))
            }
        } else {
            assembly {
                revert(add(returndata, 0x20), mload(returndata))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OVM_GasPriceOracle
 * @dev This contract exposes the current l2 gas price, a measure of how congested the network
 * currently is. This measure is used by the Sequencer to determine what fee to charge for
 * transactions. When the system is more congested, the l2 gas price will increase and fees
 * will also increase as a result.
 *
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_GasPriceOracle is Ownable {

    /*************
     * Variables *
     *************/

    // Current l2 gas price
    uint256 public gasPrice;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _owner Address that will initially own this contract.
     */
    constructor(
        address _owner,
        uint256 _initialGasPrice
    )
        Ownable()
    {
        setGasPrice(_initialGasPrice);
        transferOwnership(_owner);
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Allows the owner to modify the l2 gas price.
     * @param _gasPrice New l2 gas price.
     */
    function setGasPrice(
        uint256 _gasPrice
    )
        public
        onlyOwner
    {
        gasPrice = _gasPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Contract Imports */
import { L2StandardERC20 } from "../../../libraries/standards/L2StandardERC20.sol";
import { Lib_PredeployAddresses } from "../../../libraries/constants/Lib_PredeployAddresses.sol";

/**
 * @title OVM_L2StandardTokenFactory
 * @dev Factory contract for creating standard L2 token representations of L1 ERC20s
 * compatible with and working on the standard bridge.
 * Compiler used: optimistic-solc
 * Runtime target: OVM
 */
contract OVM_L2StandardTokenFactory {

    event StandardL2TokenCreated(address indexed _l1Token, address indexed _l2Token);

    /**
     * @dev Creates an instance of the standard ERC20 token on L2.
     * @param _l1Token Address of the corresponding L1 token.
     * @param _name ERC20 name.
     * @param _symbol ERC20 symbol.
     */
    function createStandardL2Token(
        address _l1Token,
        string memory _name,
        string memory _symbol
    )
        external
    {
        require (_l1Token != address(0), "Must provide L1 token address");

        L2StandardERC20 l2Token = new L2StandardERC20(
            Lib_PredeployAddresses.L2_STANDARD_BRIDGE,
            _l1Token,
            _name,
            _symbol
        );

        emit StandardL2TokenCreated(_l1Token, address(l2Token));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_Bytes32Utils } from "../../optimistic-ethereum/libraries/utils/Lib_Bytes32Utils.sol";

/**
 * @title TestLib_Byte32Utils
 */
contract TestLib_Bytes32Utils {

    function toBool(
        bytes32 _in
    )
        public
        pure
        returns (
            bool _out
        )
    {
        return Lib_Bytes32Utils.toBool(_in);
    }

    function fromBool(
        bool _in
    )
        public
        pure
        returns (
            bytes32 _out
        )
    {
        return Lib_Bytes32Utils.fromBool(_in);
    }

    function toAddress(
        bytes32 _in
    )
        public
        pure
        returns (
            address _out
        )
    {
        return Lib_Bytes32Utils.toAddress(_in);
    }

    function fromAddress(
        address _in
    )
        public
        pure
        returns (
            bytes32 _out
        )
    {
        return Lib_Bytes32Utils.fromAddress(_in);
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_EthUtils } from "../../optimistic-ethereum/libraries/utils/Lib_EthUtils.sol";

/**
 * @title TestLib_EthUtils
 */
contract TestLib_EthUtils {

    function getCode(
        address _address,
        uint256 _offset,
        uint256 _length
    )
        public
        view
        returns (
            bytes memory _code
        )
    {
        return Lib_EthUtils.getCode(
            _address,
            _offset,
            _length
        );
    }

    function getCode(
        address _address
    )
        public
        view
        returns (
            bytes memory _code
        )
    {
        return Lib_EthUtils.getCode(
            _address
        );
    }

    function getCodeSize(
        address _address
    )
        public
        view
        returns (
            uint256 _codeSize
        )
    {
        return Lib_EthUtils.getCodeSize(
            _address
        );
    }

    function getCodeHash(
        address _address
    )
        public
        view
        returns (
            bytes32 _codeHash
        )
    {
        return Lib_EthUtils.getCodeHash(
            _address
        );
    }

    function createContract(
        bytes memory _code
    )
        public
        returns (
            address _created
        )
    {
        return Lib_EthUtils.createContract(
            _code
        );
    }

    function getAddressForCREATE(
        address _creator,
        uint256 _nonce
    )
        public
        pure
        returns (
            address _address
        )
    {
        return Lib_EthUtils.getAddressForCREATE(
            _creator,
            _nonce
        );
    }

    function getAddressForCREATE2(
        address _creator,
        bytes memory _bytecode,
        bytes32 _salt
    )
        public
        pure
        returns (address _address)
    {
        return Lib_EthUtils.getAddressForCREATE2(
            _creator,
            _bytecode,
            _salt
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_MerkleTree } from "../../optimistic-ethereum/libraries/utils/Lib_MerkleTree.sol";

/**
 * @title TestLib_MerkleTree
 */
contract TestLib_MerkleTree {

    function getMerkleRoot(
        bytes32[] memory _elements
    )
        public
       pure
        returns (
            bytes32
        )
    {
        return Lib_MerkleTree.getMerkleRoot(
            _elements
        );
    }

    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings,
        uint256 _totalLeaves
    )
        public
        pure
        returns (
            bool
        )
    {
        return Lib_MerkleTree.verify(
            _root,
            _leaf,
            _index,
            _siblings,
            _totalLeaves
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_BondManager } from "../../iOVM/verification/iOVM_BondManager.sol";

/* Contract Imports */
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";

/**
 * @title mockOVM_BondManager
 */
contract mockOVM_BondManager is iOVM_BondManager, Lib_AddressResolver {
    constructor(
        address _libAddressManager
    )
        Lib_AddressResolver(_libAddressManager)
    {}

    function recordGasSpent(
        bytes32 _preStateRoot,
        bytes32 _txHash,
        address _who,
        uint256 _gasSpent
    )
        override
        public
    {}

    function finalize(
        bytes32 _preStateRoot,
        address _publisher,
        uint256 _timestamp
    )
        override
        public
    {}

    function deposit()
        override
        public
    {}

    function startWithdrawal()
        override
        public
    {}

    function finalizeWithdrawal()
        override
        public
    {}

    function claim(
        address _who
    )
        override
        public
    {}

    function isCollateralized(
        address _who
    )
        override
        public
        view
        returns (
            bool
        )
    {
        // Only authenticate sequencer to submit state root batches.
        return _who == resolve("OVM_Proposer");
    }

    function getGasSpent(
        bytes32, // _preStateRoot,
        address // _who
    )
        override
        public
        pure
        returns (
            uint256
        )
    {
        return 0;
    }
}

