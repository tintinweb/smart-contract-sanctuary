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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces//BridgePoolInterface.sol";
import "../interfaces/BridgeAdminInterface.sol";
import "../interfaces/MessengerInterface.sol";
import "../../../contracts/oracle/interfaces/IdentifierWhitelistInterface.sol";
import "../../../contracts/oracle/interfaces/FinderInterface.sol";
import "../../../contracts/oracle/implementation/Constants.sol";
import "../../../contracts/common/interfaces/AddressWhitelistInterface.sol";
import "../../../contracts/common/implementation/Lockable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Administrative contract deployed on L1 that has implicit references to all L2 DepositBoxes. This contract is
 * responsible for making global variables accessible to BridgePool contracts, which house passive liquidity and
 * enable relaying of L2 deposits.
 * @dev The owner of this contract can also call permissioned functions on registered L2 DepositBoxes.
 */
contract BridgeAdmin is BridgeAdminInterface, Ownable, Lockable {
    // Finder used to point to latest OptimisticOracle and other DVM contracts.
    address public override finder;

    // This contract can relay messages to any number of L2 DepositBoxes, one per L2 network, each identified by a
    // unique network ID. To relay a message, both the deposit box contract address and a messenger contract address
    // need to be stored. The messenger implementation differs for each L2 beacuse L1 --> L2 messaging is non-standard.
    // The deposit box contract originate the deposits that can be fulfilled by BridgePool contracts on L1.
    mapping(uint256 => DepositUtilityContracts) private _depositContracts;

    // L1 token addresses are mapped to their canonical token address on L2 and the BridgePool contract that houses
    // relay liquidity for any deposits of the canonical L2 token.
    mapping(address => L1TokenRelationships) private _whitelistedTokens;

    // Set upon construction and can be reset by Owner.
    uint64 public override optimisticOracleLiveness;
    uint64 public override proposerBondPct;
    bytes32 public override identifier;

    // Add this modifier to methods that are expected to bridge messages to a L2 Deposit contract, which
    // will cause unexpected behavior if the deposit or messenger helper contract isn't set and valid.
    modifier canRelay(uint256 _chainId) {
        _validateDepositContracts(
            _depositContracts[_chainId].depositContract,
            _depositContracts[_chainId].messengerContract
        );
        _;
    }

    /**
     * @notice Construct the Bridge Admin
     * @param _finder DVM finder to find other UMA ecosystem contracts.
     * @param _optimisticOracleLiveness Timeout that all bridging actions from L2->L1 must wait for a OptimisticOracle response.
     * @param _proposerBondPct Percentage of the bridged amount that a relayer must put up as a bond.
     * @param _identifier Identifier used when querying the OO for a cross bridge transfer action.
     */
    constructor(
        address _finder,
        uint64 _optimisticOracleLiveness,
        uint64 _proposerBondPct,
        bytes32 _identifier
    ) {
        finder = _finder;
        require(address(_getCollateralWhitelist()) != address(0), "Invalid finder");
        _setOptimisticOracleLiveness(_optimisticOracleLiveness);
        _setProposerBondPct(_proposerBondPct);
        _setIdentifier(_identifier);
    }

    /**************************************
     *        ADMIN FUNCTIONS             *
     **************************************/

    /**
     * @notice Sets a price identifier to use for relayed deposits. BridgePools reads the identifier from this contract.
     * @dev Can only be called by the current owner.
     * @param _identifier New identifier to set.
     */
    function setIdentifier(bytes32 _identifier) public onlyOwner nonReentrant() {
        _setIdentifier(_identifier);
    }

    /**
     * @notice Sets challenge period for relayed deposits. BridgePools will read this value from this contract.
     * @dev Can only be called by the current owner.
     * @param _liveness New OptimisticOracle liveness period to set for relay price requests.
     */
    function setOptimisticOracleLiveness(uint64 _liveness) public onlyOwner nonReentrant() {
        _setOptimisticOracleLiveness(_liveness);
    }

    /**
     * @notice Sets challenge period for relayed deposits. BridgePools will read this value from this contract.
     * @dev Can only be called by the current owner.
     * @param _proposerBondPct New OptimisticOracle proposer bond % to set for relay price requests. 1e18 = 100%.
     */
    function setProposerBondPct(uint64 _proposerBondPct) public onlyOwner nonReentrant() {
        _setProposerBondPct(_proposerBondPct);
    }

    /**
     * @notice Associates the L2 deposit and L1 messenger helper addresses with an L2 network ID.
     * @dev Only callable by the current owner.
     * @param _chainId L2 network ID to set addresses for.
     * @param _depositContract Address of L2 deposit contract.
     * @param _messengerContract Address of L1 helper contract that relays messages to L2.
     */
    function setDepositContract(
        uint256 _chainId,
        address _depositContract,
        address _messengerContract
    ) public onlyOwner nonReentrant() {
        _validateDepositContracts(_depositContract, _messengerContract);
        _depositContracts[_chainId].depositContract = _depositContract;
        _depositContracts[_chainId].messengerContract = _messengerContract;
        emit SetDepositContracts(_chainId, _depositContract, _messengerContract);
    }

    /**************************************************
     *        CROSSDOMAIN ADMIN FUNCTIONS             *
     **************************************************/

    /**
     * @notice Set new contract as the admin address in the L2 Deposit contract.
     * @dev Only callable by the current owner.
     * @param _chainId L2 network ID where Deposit contract is deployed.
     * @param _admin New admin address to set on L2.
     * @param _l2Gas Gas limit to set for relayed message on L2.
     * @param _l2GasPrice Gas price bid to set for relayed message on L2.
     */
    function setBridgeAdmin(
        uint256 _chainId,
        address _admin,
        uint32 _l2Gas,
        uint256 _l2GasPrice
    ) public onlyOwner canRelay(_chainId) nonReentrant() {
        require(_admin != address(0), "Admin cannot be zero address");
        MessengerInterface(_depositContracts[_chainId].messengerContract).relayMessage(
            _depositContracts[_chainId].depositContract,
            _l2Gas,
            _l2GasPrice,
            abi.encodeWithSignature("setBridgeAdmin(address)", _admin)
        );
        emit SetBridgeAdmin(_chainId, _admin);
    }

    /**
     * @notice Sets the minimum time between L2-->L1 token withdrawals in the L2 Deposit contract.
     * @dev Only callable by the current owner.
     * @param _chainId L2 network ID where Deposit contract is deployed.
     * @param _minimumBridgingDelay the new minimum delay.
     * @param _l2Gas Gas limit to set for relayed message on L2.
     * @param _l2GasPrice Gas price bid to set for relayed message on L2.
     */
    function setMinimumBridgingDelay(
        uint256 _chainId,
        uint64 _minimumBridgingDelay,
        uint32 _l2Gas,
        uint256 _l2GasPrice
    ) public onlyOwner canRelay(_chainId) nonReentrant() {
        MessengerInterface(_depositContracts[_chainId].messengerContract).relayMessage(
            _depositContracts[_chainId].depositContract,
            _l2Gas,
            _l2GasPrice,
            abi.encodeWithSignature("setMinimumBridgingDelay(uint64)", _minimumBridgingDelay)
        );
        emit SetMinimumBridgingDelay(_chainId, _minimumBridgingDelay);
    }

    /**
     * @notice Owner can pause/unpause L2 deposits for a tokens.
     * @dev Only callable by Owner of this contract. Will set the same setting in the L2 Deposit contract via the cross
     * domain messenger.
     * @param _chainId L2 network ID where Deposit contract is deployed.
     * @param _l2Token address of L2 token to enable/disable deposits for.
     * @param _depositsEnabled bool to set if the deposit box should accept/reject deposits.
     * @param _l2Gas Gas limit to set for relayed message on L2.
     * @param _l2GasPrice Gas price bid to set for relayed message on L2.
     */
    function setEnableDeposits(
        uint256 _chainId,
        address _l2Token,
        bool _depositsEnabled,
        uint32 _l2Gas,
        uint256 _l2GasPrice
    ) public onlyOwner canRelay(_chainId) nonReentrant() {
        MessengerInterface(_depositContracts[_chainId].messengerContract).relayMessage(
            _depositContracts[_chainId].depositContract,
            _l2Gas,
            _l2GasPrice,
            abi.encodeWithSignature("setEnableDeposits(address,bool)", _l2Token, _depositsEnabled)
        );
        emit DepositsEnabled(_chainId, _l2Token, _depositsEnabled);
    }

    /**
     * @notice Privileged account can associate a whitelisted token with its linked token address on L2. The linked L2
     * token can thereafter be deposited into the Deposit contract on L2 and relayed via the BridgePool contract.
     * @dev Only callable by Owner of this contract. Also initiates a cross-chain call to the L2 Deposit contract to
     * whitelist the token mapping.
     * @param _chainId L2 network ID where Deposit contract is deployed.
     * @param _l1Token Address of L1 token that can be used to relay L2 token deposits.
     * @param _l2Token Address of L2 token whose deposits are fulfilled by `_l1Token`.
     * @param _bridgePool Address of BridgePool which manages liquidity to fulfill L2-->L1 relays.
     * @param _l2Gas Gas limit to set for relayed message on L2.
     * @param _l2GasPrice Gas price bid to set for relayed message on L2.
     */
    function whitelistToken(
        uint256 _chainId,
        address _l1Token,
        address _l2Token,
        address _bridgePool,
        uint32 _l2Gas,
        uint256 _l2GasPrice
    ) public onlyOwner canRelay(_chainId) nonReentrant() {
        require(_bridgePool != address(0), "BridgePool cannot be zero address");
        require(_l2Token != address(0), "L2 token cannot be zero address");
        require(_getCollateralWhitelist().isOnWhitelist(address(_l1Token)), "Payment token not whitelisted");

        require(address(BridgePoolInterface(_bridgePool).l1Token()) == _l1Token, "Bridge pool has different L1 token");

        _whitelistedTokens[_l1Token] = L1TokenRelationships({ l2Token: _l2Token, bridgePool: _bridgePool });

        MessengerInterface(_depositContracts[_chainId].messengerContract).relayMessage(
            _depositContracts[_chainId].depositContract,
            _l2Gas,
            _l2GasPrice,
            abi.encodeWithSignature("whitelistToken(address,address,address)", _l1Token, _l2Token, _bridgePool)
        );
        emit WhitelistToken(_chainId, _l1Token, _l2Token, _bridgePool);
    }

    /**************************************
     *        VIEW FUNCTIONS              *
     **************************************/
    function depositContracts(uint256 _chainId) external view override returns (DepositUtilityContracts memory) {
        return _depositContracts[_chainId];
    }

    function whitelistedTokens(address _l1Token) external view override returns (L1TokenRelationships memory) {
        return _whitelistedTokens[_l1Token];
    }

    /**************************************
     *        INTERNAL FUNCTIONS          *
     **************************************/

    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface) {
        return
            IdentifierWhitelistInterface(
                FinderInterface(finder).getImplementationAddress(OracleInterfaces.IdentifierWhitelist)
            );
    }

    function _getCollateralWhitelist() private view returns (AddressWhitelistInterface) {
        return
            AddressWhitelistInterface(
                FinderInterface(finder).getImplementationAddress(OracleInterfaces.CollateralWhitelist)
            );
    }

    function _setIdentifier(bytes32 _identifier) private {
        require(_getIdentifierWhitelist().isIdentifierSupported(_identifier), "Identifier not registered");
        identifier = _identifier;
        emit SetRelayIdentifier(identifier);
    }

    function _setOptimisticOracleLiveness(uint64 _liveness) private {
        // The following constraints are copied from a similar function in the OptimisticOracle contract:
        // - https://github.com/UMAprotocol/protocol/blob/dd211c4e3825fe007d1161025a34e9901b26031a/packages/core/contracts/oracle/implementation/OptimisticOracle.sol#L621
        require(_liveness < 5200 weeks, "Liveness too large");
        require(_liveness > 0, "Liveness cannot be 0");
        optimisticOracleLiveness = _liveness;
        emit SetOptimisticOracleLiveness(optimisticOracleLiveness);
    }

    function _setProposerBondPct(uint64 _proposerBondPct) private {
        proposerBondPct = _proposerBondPct;
        emit SetProposerBondPct(proposerBondPct);
    }

    function _validateDepositContracts(address _depositContract, address _messengerContract) private {
        require(
            (_depositContract != address(0)) && (_messengerContract != address(0)),
            "Invalid deposit or messenger contract"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @notice Helper view methods designed to be called by BridgePool contracts.
 */
interface BridgeAdminInterface {
    event SetDepositContracts(
        uint256 indexed chainId,
        address indexed l2DepositContract,
        address indexed l2MessengerContract
    );
    event SetBridgeAdmin(uint256 indexed chainId, address indexed bridgeAdmin);
    event SetRelayIdentifier(bytes32 indexed identifier);
    event SetOptimisticOracleLiveness(uint64 indexed liveness);
    event SetProposerBondPct(uint64 indexed proposerBondPct);
    event WhitelistToken(uint256 chainId, address indexed l1Token, address indexed l2Token, address indexed bridgePool);
    event SetMinimumBridgingDelay(uint256 indexed chainId, uint64 newMinimumBridgingDelay);
    event DepositsEnabled(uint256 indexed chainId, address indexed l2Token, bool depositsEnabled);

    function finder() external view returns (address);

    struct DepositUtilityContracts {
        address depositContract; // L2 deposit contract where cross-chain relays originate.
        address messengerContract; // L1 helper contract that can send a message to the L2 with the mapped network ID.
    }

    function depositContracts(uint256) external view returns (DepositUtilityContracts memory);

    struct L1TokenRelationships {
        address l2Token;
        address bridgePool;
    }

    function whitelistedTokens(address) external view returns (L1TokenRelationships memory);

    function optimisticOracleLiveness() external view returns (uint64);

    function proposerBondPct() external view returns (uint64);

    function identifier() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface BridgePoolInterface {
    function l1Token() external view returns (IERC20);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @notice Sends cross chain messages to contracts on a specific L2 network. The `relayMessage` implementation will
 * differ for each L2.
 */
interface MessengerInterface {
    function relayMessage(
        address target,
        uint256 gasLimit,
        uint256 gasPrice,
        bytes memory message
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface AddressWhitelistInterface {
    function addToWhitelist(address newElement) external;

    function removeFromWhitelist(address newElement) external virtual;

    function isOnWhitelist(address newElement) external view virtual returns (bool);

    function getWhitelist() external view virtual returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
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
}

// SPDX-License-Identifier: AGPL-3.0-only
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view returns (bool);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}