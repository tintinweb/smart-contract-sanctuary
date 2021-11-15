// SPDX-License-Identifier: MIT
// @unsupported: ovm 
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_L1TokenGateway } from "../../../iOVM/bridge/tokens/iOVM_L1TokenGateway.sol";
import { iOVM_L2DepositedToken } from "../../../iOVM/bridge/tokens/iOVM_L2DepositedToken.sol";

/* Library Imports */
import { OVM_CrossDomainEnabled } from "../../../libraries/bridge/OVM_CrossDomainEnabled.sol";

/**
 * @title Abs_L1TokenGateway
 * @dev An L1 Token Gateway is a contract which stores deposited L1 funds that are in use on L2.
 * It synchronizes a corresponding L2 representation of the "deposited token", informing it
 * of new deposits and releasing L1 funds when there are newly finalized withdrawals.
 *
 * NOTE: This abstract contract gives all the core functionality of an L1 token gateway, 
 * but provides easy hooks in case developers need extensions in child contracts.
 * In many cases, the default OVM_L1ERC20Gateway will suffice.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
abstract contract Abs_L1TokenGateway is iOVM_L1TokenGateway, OVM_CrossDomainEnabled {

    /********************************
     * External Contract References *
     ********************************/

    address public l2DepositedToken;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _l2DepositedToken iOVM_L2DepositedToken-compatible address on the chain being deposited into.
     * @param _l1messenger L1 Messenger address being used for cross-chain communications.
     */
    constructor(
        address _l2DepositedToken,
        address _l1messenger 
    )
        OVM_CrossDomainEnabled(_l1messenger)
    {
        l2DepositedToken = _l2DepositedToken;
    }

    /********************************
     * Overridable Accounting logic *
     ********************************/

    // Default gas value which can be overridden if more complex logic runs on L2.
    uint32 public DEFAULT_FINALIZE_DEPOSIT_L2_GAS = 1200000;

    /**
     * @dev Core logic to be performed when a withdrawal is finalized on L1.
     * In most cases, this will simply send locked funds to the withdrawer.
     *
     * @param _to Address being withdrawn to.
     * @param _amount Amount being withdrawn.
     */
    function _handleFinalizeWithdrawal(
        address _to,
        uint256 _amount
    )
        internal
        virtual
    {
        revert("Implement me in child contracts");
    }

    /**
     * @dev Core logic to be performed when a deposit is initiated on L1.
     * In most cases, this will simply send locked funds to the withdrawer.
     *
     * @param _from Address being deposited from on L1.
     * @param _to Address being deposited into on L2.
     * @param _amount Amount being deposited.
     */
    function _handleInitiateDeposit(
        address _from,
        address _to,
        uint256 _amount
    )
        internal
        virtual
    {
        revert("Implement me in child contracts");
    }

    /**
     * @dev Overridable getter for the L2 gas limit, in the case it may be
     * dynamic, and the above public constant does not suffice.
     *
     */

    function getFinalizeDepositL2Gas()
        public
        view
        returns(
            uint32
        )
    {
        return DEFAULT_FINALIZE_DEPOSIT_L2_GAS;
    }

    /**************
     * Depositing *
     **************/

    /**
     * @dev deposit an amount of the ERC20 to the caller's balance on L2
     * @param _amount Amount of the ERC20 to deposit
     */
    function deposit(
        uint _amount
    )
        public
        override
    {
        _initiateDeposit(msg.sender, msg.sender, _amount);
    }

    /**
     * @dev deposit an amount of ERC20 to a recipients's balance on L2
     * @param _to L2 address to credit the withdrawal to
     * @param _amount Amount of the ERC20 to deposit
     */
    function depositTo(
        address _to,
        uint _amount
    )
        public
        override
    {
        _initiateDeposit(msg.sender, _to, _amount);
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
        uint _amount
    )
        internal
    {
        // Call our deposit accounting handler implemented by child contracts.
        _handleInitiateDeposit(
            _from,
            _to,
            _amount
        );

        // Construct calldata for l2DepositedToken.finalizeDeposit(_to, _amount)
        bytes memory data = abi.encodeWithSelector(
            iOVM_L2DepositedToken.finalizeDeposit.selector,
            _to,
            _amount
        );

        // Send calldata into L2
        sendCrossDomainMessage(
            l2DepositedToken,
            data,
            getFinalizeDepositL2Gas()
        );

        emit DepositInitiated(_from, _to, _amount);
    }

    /*************************
     * Cross-chain Functions *
     *************************/

    /**
     * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the 
     * L1 ERC20 token. 
     * This call will fail if the initialized withdrawal from L2 has not been finalized. 
     *
     * @param _to L1 address to credit the withdrawal to
     * @param _amount Amount of the ERC20 to withdraw
     */
    function finalizeWithdrawal(
        address _to,
        uint _amount
    )
        external
        override 
        onlyFromCrossDomainAccount(l2DepositedToken)
    {
        // Call our withdrawal accounting handler implemented by child contracts.
        _handleFinalizeWithdrawal(
            _to,
            _amount
        );

        emit WithdrawalFinalized(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm 
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_L1TokenGateway } from "../../../iOVM/bridge/tokens/iOVM_L1TokenGateway.sol";
import { Abs_L1TokenGateway } from "./Abs_L1TokenGateway.sol";
import { iOVM_ERC20 } from "../../../iOVM/precompiles/iOVM_ERC20.sol";

/**
 * @title OVM_L1ERC20Gateway
 * @dev The L1 ERC20 Gateway is a contract which stores deposited L1 funds that are in use on L2.
 * It synchronizes a corresponding L2 ERC20 Gateway, informing it of deposits, and listening to it
 * for newly finalized withdrawals.
 *
 * NOTE: This contract extends Abs_L1TokenGateway, which is where we
 * takes care of most of the initialization and the cross-chain logic.
 * If you are looking to implement your own deposit/withdrawal contracts, you
 * may also want to extend the abstract contract in a similar manner.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_L1ERC20Gateway is Abs_L1TokenGateway {

    /********************************
     * External Contract References *
     ********************************/
    
    iOVM_ERC20 public l1ERC20;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _l1ERC20 L1 ERC20 address this contract stores deposits for
     * @param _l2DepositedERC20 L2 Gateway address on the chain being deposited into
     */
    constructor(
        iOVM_ERC20 _l1ERC20,
        address _l2DepositedERC20,
        address _l1messenger 
    )
        Abs_L1TokenGateway(
            _l2DepositedERC20,
            _l1messenger
        )
    {
        l1ERC20 = _l1ERC20;
    }


    /**************
     * Accounting *
     **************/

    /**
     * @dev When a deposit is initiated on L1, the L1 Gateway
     * transfers the funds to itself for future withdrawals
     *
     * @param _from L1 address ETH is being deposited from
     * @param _to L2 address that the ETH is being deposited to
     * @param _amount Amount of ERC20 to send
     */
    function _handleInitiateDeposit(
        address _from,
        address _to,
        uint256 _amount
    )
        internal
        override
    {
         // Hold on to the newly deposited funds
        l1ERC20.transferFrom(
            _from,
            address(this),
            _amount
        );
    }

    /**
     * @dev When a withdrawal is finalized on L1, the L1 Gateway
     * transfers the funds to the withdrawer
     *
     * @param _to L1 address that the ERC20 is being withdrawn to
     * @param _amount Amount of ERC20 to send
     */
    function _handleFinalizeWithdrawal(
        address _to,
        uint _amount
    )
        internal
        override
    {
        // Transfer withdrawn funds out to withdrawer
        l1ERC20.transfer(_to, _amount);
    }
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

    /**********************
     * Contract Variables *
     **********************/
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

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iOVM_ERC20
 */
interface iOVM_ERC20 {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    function totalSupply() external view returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed _account, uint256 _amount);
    event Burn(address indexed _account, uint256 _amount);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
/* Interface Imports */
import { iAbs_BaseCrossDomainMessenger } from "../../iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

/**
 * @title OVM_CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
contract OVM_CrossDomainEnabled {
    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;

    /***************
     * Constructor *
     ***************/    
    constructor(
        address _messenger
    ) {
        messenger = _messenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * @notice Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is authenticated to call this function.
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
     * @notice Gets the messenger, usually from storage.  This function is exposed in case a child contract needs to override.
     * @return The address of the cross-domain messenger contract which should be used. 
     */
    function getCrossDomainMessenger()
        internal
        virtual
        returns(
            iAbs_BaseCrossDomainMessenger
        )
    {
        return iAbs_BaseCrossDomainMessenger(messenger);
    }

    /**
     * @notice Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _data The data to send to the target (usually calldata to a function with `onlyFromCrossDomainAccount()`)
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
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { OVM_L1ERC20Gateway } from "@eth-optimism/contracts/build/contracts/OVM/bridge/tokens/OVM_L1ERC20Gateway.sol";
import { iOVM_ERC20 } from "@eth-optimism/contracts/build/contracts/iOVM/precompiles/iOVM_ERC20.sol";

/**
 * @title OVM_L1ERC20Gateway
 * @dev The L1 ERC20 Gateway is a contract which stores deposited L1 funds that are in use on L2.
 * It synchronizes a corresponding L2 ERC20 Gateway, informing it of deposits, and listening to it
 * for newly finalized withdrawals.
 *
 * This contract extends OVM_L1ERC20Gateway, which is where we
 * takes care of most of the initialization and the cross-chain logic.
 * If you are looking to implement your own deposit/withdrawal contracts, you
 * may also want to extend this contract in a similar manner.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract L1Gateway is OVM_L1ERC20Gateway {


    constructor(
        iOVM_ERC20 _l1ERC20,
        address _l2DepositedERC20,
        address _l1messenger
    )
        OVM_L1ERC20Gateway(
            _l1ERC20,
            _l2DepositedERC20,
            _l1messenger
        )
    {
    }
}

