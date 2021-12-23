/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// File: oracle/implementation/Constants.sol


pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
    bytes32 public constant SkinnyOptimisticOracle = "SkinnyOptimisticOracle";
    bytes32 public constant ChildMessenger = "ChildMessenger";
    bytes32 public constant XAppConnectionManager = "XAppConnectionManager";
    bytes32 public constant OracleSpoke = "OracleSpoke";
    bytes32 public constant ParentMessenger = "ParentMessenger";
}

/**
 * @title Commonly re-used values for contracts associated with the OptimisticOracle.
 */
library OptimisticOracleConstraints {
    // Any price request submitted to the OptimisticOracle must contain ancillary data no larger than this value.
    // This value must be <= the Voting contract's `ancillaryBytesLimit` constant value otherwise it is possible
    // that a price can be requested to the OptimisticOracle successfully, but cannot be resolved by the DVM which
    // refuses to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;
}

// File: cross-chain-oracle/interfaces/ChildMessengerInterface.sol


pragma solidity ^0.8.0;

interface ChildMessengerInterface {
    // Should send cross-chain message to Parent messenger contract or revert.
    function sendMessageToParent(bytes memory data) external;
}

// File: oracle/interfaces/FinderInterface.sol


pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// File: cross-chain-oracle/SpokeBase.sol


pragma solidity ^0.8.0;




/**
 * @title Cross-chain Oracle L2 Spoke Base.
 * @notice Provides access control to Governance and Oracle spoke L2 contracts.
 */

contract SpokeBase {
    FinderInterface private finder;

    constructor(address _finderAddress) {
        finder = FinderInterface(_finderAddress);
    }

    modifier onlyMessenger() {
        require(msg.sender == address(getChildMessenger()), "Caller must be messenger");
        _;
    }

    /**
     * @notice Returns the child messenger address set in the finder.
     * @return ChildMessengerInterface instance of child messenger deployed on L2.
     */
    function getChildMessenger() public view returns (ChildMessengerInterface) {
        return ChildMessengerInterface(finder.getImplementationAddress(OracleInterfaces.ChildMessenger));
    }
}

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
    // Called on L2 by child messenger.
    function processMessageFromParent(bytes memory data) external;
}

// File: cross-chain-oracle/GovernorSpoke.sol


pragma solidity ^0.8.0;




/**
 * @title Cross-chain Oracle L2 Governor Spoke.
 * @notice Governor contract deployed on L2 that receives governance actions from Ethereum.
 */
contract GovernorSpoke is Lockable, SpokeBase, ChildMessengerConsumerInterface {
    struct Call {
        address to;
        bytes data;
    }

    constructor(address _finderAddress) SpokeBase(_finderAddress) {}

    event ExecutedGovernanceTransaction(address indexed to, bytes data);

    /**
     * @notice Executes governance transaction created on Ethereum.
     * @dev Can only be called by ChildMessenger contract that wants to execute governance action on this child chain
     * that originated from DVM voters on root chain. ChildMessenger should only receive communication from
     * ParentMessenger on mainnet. See the SpokeBase for the onlyMessenger modifier.

     * @param data Contains the target address and the encoded function selector + ABI encoded params to include in
     * delegated transaction.
     */
    function processMessageFromParent(bytes memory data) public override nonReentrant() onlyMessenger() {
        Call[] memory calls = abi.decode(data, (Call[]));

        for (uint256 i = 0; i < calls.length; i++) {
            (address to, bytes memory inputData) = (calls[i].to, calls[i].data);
            require(_executeCall(to, inputData), "execute call failed");
            emit ExecutedGovernanceTransaction(to, inputData);
        }
    }

    // Note: this snippet of code is copied from Governor.sol.
    function _executeCall(address to, bytes memory data) private returns (bool) {
        // Note: this snippet of code is copied from Governor.sol and modified to not include any "value" field.
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