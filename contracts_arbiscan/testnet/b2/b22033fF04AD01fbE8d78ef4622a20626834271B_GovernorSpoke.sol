/**
 *Submitted for verification at arbiscan.io on 2021-11-19
*/

// File: common/implementation/Lockable.sol


pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant` function is not supported. It is possible to
     * prevent this from happening by making the `nonReentrant` function external, and making it call a `private`
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and
    // then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: cross-chain-oracle/interfaces/ChildMessengerConsumerInterface.sol


pragma solidity ^0.8.0;

interface ChildMessengerConsumerInterface {
    // Called on L2 by parent messenger.
    function processMessageFromParent(bytes memory data) external;
}

// File: cross-chain-oracle/GovernorSpoke.sol


pragma solidity ^0.8.0;



/**
 * @title Cross-chain Oracle L2 Governor Spoke.
 * @notice Governor contract deployed on L2 that receives governance actions from Ethereum.
 */
contract GovernorSpoke is Lockable, ChildMessengerConsumerInterface {
    // Messenger contract that receives messages from root chain.
    ChildMessengerConsumerInterface public messenger;

    event ExecutedGovernanceTransaction(address indexed to, bytes data);
    event SetChildMessenger(address indexed childMessenger);

    constructor(ChildMessengerConsumerInterface _messengerAddress) {
        messenger = _messengerAddress;
        emit SetChildMessenger(address(messenger));
    }

    modifier onlyMessenger() {
        require(msg.sender == address(messenger), "Caller must be messenger");
        _;
    }

    /**
     * @notice Executes governance transaction created on Ethereum.
     * @dev Can only called by ChildMessenger contract that wants to execute governance action on this child chain that
     * originated from DVM voters on root chain. ChildMessenger should only receive communication from ParentMessenger
     * on mainnet.

     * @param data Contains the target address and the encoded function selector + ABI encoded params to include in
     * delegated transaction.
     */
    function processMessageFromParent(bytes memory data) public override nonReentrant() onlyMessenger() {
        (address to, bytes memory inputData) = abi.decode(data, (address, bytes));
        // TODO: Consider calling this via <address>.call(): https://docs.soliditylang.org/en/v0.8.10/units-and-global-variables.html?highlight=low%20level%20call#members-of-address-types
        // to avoid inline assembly.

        require(_executeCall(to, inputData), "execute call failed");
        emit ExecutedGovernanceTransaction(to, inputData);
    }

    // Note: this snippet of code is copied from Governor.sol.
    function _executeCall(address to, bytes memory data) private returns (bool) {
        // Note: this snippet of code is copied from Governor.sol.
        // solhint-disable-next-line max-line-length
        // https://github.com/gnosis/safe-contracts/blob/59cfdaebcd8b87a0a32f87b50fead092c10d3a05/contracts/base/Executor.sol#L23-L31
        // solhint-disable-next-line no-inline-assembly

        bool success;
        assembly {
            let inputData := add(data, 0x20)
            let inputDataSize := mload(data)
            // Hardcode value to be 0 for relayed governance calls in order to avoid addressing complexity of bridging
            // value cross-chain.
            success := call(gas(), to, 0, inputData, inputDataSize, 0, 0)
        }
        return success;
    }
}