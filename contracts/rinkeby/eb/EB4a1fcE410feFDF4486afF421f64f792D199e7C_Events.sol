pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "./interfaces/IRigor.sol";
import "./external/contracts/proxy/Initializable.sol";
import "./external/contracts/proxy/OwnedUpgradeabilityProxy.sol";

contract Events is Initializable {
    IRigor public rigor;

    function initialize(address _rigor) public initializer {
        rigor = IRigor(_rigor);
    }

    /// IPROJECT.SOL EVENT ///
    event HashUpdated(address indexed _project, bytes _hash);
    event ContractorInvited(
        address indexed _project,
        address indexed _newContractor,
        uint256[] _feeSchedule
    );
    event ContractorSwapped(
        address indexed _project,
        address indexed _oldContractor,
        address indexed _newContractor
    );
    event BuilderConfirmed(address indexed _project, address indexed _builder);
    event ContractorConfirmed(
        address indexed _project,
        address indexed _contractor
    );
    event PhasesAdded(address indexed _project, uint256[] _phaseCost);
    event PhaseUpdated(
        address indexed _project,
        uint256[] _phase,
        uint256[] _updatedCost
    );
    event ProjectFunded(address indexed _project, uint256 indexed _value);
    event InvestedInProject(address indexed _project, uint256 _cost);
    event TaskCreated(address indexed _project, uint256 indexed _taskID);
    event TaskHashUpdated(
        address indexed _project,
        uint256 _taskId,
        bytes32[2] _taskHash
    );
    event SCInvited(
        address indexed _project,
        uint256 indexed _taskID,
        address indexed _sc
    );
    event SCSwapped(
        address indexed _project,
        uint256 _taskID,
        address indexed _old,
        address indexed _new
    );
    event SCConfirmed(
        address indexed _project,
        uint256 _taskID,
        address indexed _sc
    );
    event TaskFunded(address indexed _project, uint256 _taskID);
    event TaskComplete(address indexed _project, uint256 _taskID);
    event ContractorFeeReleased(address indexed _project, uint256 _phase);
    event ChangeOrderFee(address _project, uint256 _taskID, uint256 _newCost);
    event ChangeOrderSC(address _project, uint256 _taskID, address _sc);

    /// IRIGOR.SOL EVENTS ///
    event ProjectAdded(
        uint256 _projectID,
        address indexed _projectAddress,
        address indexed _builder
    );
    event RepayInvestor(
        uint256 indexed _index,
        address indexed _projectAddress,
        address indexed _investor,
        uint256 _tAmount
    );

    /// DISPUTE.SOL ///
    event DisputeRaised(
        address indexed _raisedBy,
        address indexed _project,
        uint256 indexed _taskId,
        uint256 _disputeId
    );
    event DisputeResolved(uint256 disputeId, uint256 result, bytes resultHash);

    /// COMMUNITY.SOL ///

    event CommunityAdded(
        uint256 _communityID,
        address indexed _owner,
        address indexed _currency,
        bytes _hash
    );
    event UpdateCommunityHash(
        uint256 _communityID,
        bytes _oldHash,
        bytes _newHash
    );
    event MemberAdded(uint256 indexed _communityID, address indexed _member);
    event ProjectPublished(
        uint256 indexed _communityID,
        uint256 _apr,
        address indexed _project,
        address indexed _builder
    );
    event InvestorInvested(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        uint256 _cost
    );
    event DebtTransferred(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        address to,
        uint256 _totalAmount
    );
    event ClaimedInterest(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        uint256 _interestEarned,
        uint256 _totalAmount
    );

    event NftCreated(uint256 _id, address _owner);

    modifier validProject() {
        require(rigor.projectExist(msg.sender), "Invalid projectContract");
        _;
    }

    modifier onlyDisputeContract() {
        require(
            rigor.disputeContract() == msg.sender,
            "Invalid disputeContract"
        );
        _;
    }

    modifier onlyRigor() {
        require(address(rigor) == msg.sender, "Only rigorContract");
        _;
    }

    modifier onlyCommunityContract() {
        require(
            rigor.communityContract() == msg.sender,
            "Only communityContract"
        );
        _;
    }

    /// PROJECT EVENT FUNCTIONS ///
    function hashUpdated(bytes calldata _updatedHash) external {
        require(
            rigor.projectExist(msg.sender) || address(rigor) == msg.sender,
            "Invalid sender"
        );
        emit HashUpdated(msg.sender, _updatedHash);
    }

    function contractorInvited(
        address _contractor,
        uint256[] calldata _feeSchedule
    ) external validProject {
        emit ContractorInvited(msg.sender, _contractor, _feeSchedule);
    }

    function contractorSwapped(address _oldContractor, address _newContractor)
        external
        validProject
    {
        emit ContractorSwapped(msg.sender, _oldContractor, _newContractor);
    }

    function builderConfirmed(address _builder) external validProject {
        emit BuilderConfirmed(msg.sender, _builder);
    }

    function contractorConfirmed(address _builder) external validProject {
        emit ContractorConfirmed(msg.sender, _builder);
    }

    function phasesAdded(uint256[] calldata _phaseCost) external validProject {
        emit PhasesAdded(msg.sender, _phaseCost);
    }

    function phaseUpdated(uint256[] calldata _phases, uint256[] calldata _costs)
        external
        validProject
    {
        emit PhaseUpdated(msg.sender, _phases, _costs);
    }

    function taskHashUpdated(uint256 _taskId, bytes32[2] calldata _taskHash)
        external
        validProject
    {
        emit TaskHashUpdated(msg.sender, _taskId, _taskHash);
    }

    function taskCreated(uint256 _taskID) external validProject {
        emit TaskCreated(msg.sender, _taskID);
    }

    function investedInProject(uint256 _cost) external validProject {
        emit InvestedInProject(msg.sender, _cost);
    }

    function scInvited(uint256 _taskID, address _sc) external validProject {
        emit SCInvited(msg.sender, _taskID, _sc);
    }

    function scSwapped(
        uint256 _taskID,
        address _old,
        address _new
    ) external validProject {
        emit SCSwapped(msg.sender, _taskID, _old, _new);
    }

    function scConfirmed(uint256 _taskID, address _sc) external validProject {
        emit SCConfirmed(msg.sender, _taskID, _sc);
    }

    function taskFunded(uint256 _taskID) external validProject {
        emit TaskFunded(msg.sender, _taskID);
    }

    function taskComplete(uint256 _taskID) external validProject {
        emit TaskComplete(msg.sender, _taskID);
    }

    function contractorFeeReleased(uint256 _phase) external validProject {
        emit ContractorFeeReleased(msg.sender, _phase);
    }

    function changeOrderFee(uint256 _taskID, uint256 _newCost)
        external
        validProject
    {
        emit ChangeOrderFee(msg.sender, _taskID, _newCost);
    }

    function changeOrderSC(uint256 _taskID, address _sc) external validProject {
        emit ChangeOrderSC(msg.sender, _taskID, _sc);
    }

    function projectAdded(
        uint256 _projectID,
        address _projectAddress,
        address _builder
    ) external onlyRigor {
        emit ProjectAdded(_projectID, _projectAddress, _builder);
    }

    function repayInvestor(
        uint256 _index,
        address _projectAddress,
        address _investor,
        uint256 _tAmount
    ) external onlyCommunityContract {
        emit RepayInvestor(_index, _projectAddress, _investor, _tAmount);
    }

    function disputeRaised(
        address _sender,
        address _project,
        uint256 _taskId,
        uint256 _disputeId
    ) external onlyDisputeContract {
        DisputeRaised(_sender, _project, _taskId, _disputeId);
    }

    function disputeResolved(
        uint256 _disputeId,
        uint256 _result,
        bytes calldata _resultHash
    ) external onlyDisputeContract {
        DisputeResolved(_disputeId, _result, _resultHash);
    }

    function communityAdded(
        uint256 _communityID,
        address _owner,
        address _currency,
        bytes calldata _hash
    ) external onlyCommunityContract {
        emit CommunityAdded(_communityID, _owner, _currency, _hash);
    }

    function updateCommunityHash(
        uint256 _communityID,
        bytes calldata _oldHash,
        bytes calldata _newHash
    ) external onlyCommunityContract {
        emit UpdateCommunityHash(_communityID, _oldHash, _newHash);
    }

    function memberAdded(uint256 _communityID, address _member)
        external
        onlyCommunityContract
    {
        emit MemberAdded(_communityID, _member);
    }

    function projectPublished(
        uint256 _communityID,
        uint256 _apr,
        address _project,
        address _builder
    ) external onlyCommunityContract {
        emit ProjectPublished(_communityID, _apr, _project, _builder);
    }

    function investorInvested(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _cost
    ) external onlyCommunityContract {
        emit InvestorInvested(_communityID, _project, _investor, _cost);
    }

    function nftCreated(uint256 _id, address _owner) external onlyRigor {
        emit NftCreated(_id, _owner);
    }

    function debtTransferred(
        uint256 _index,
        address _project,
        address _investor,
        address _to,
        uint256 _totalAmount
    ) external onlyCommunityContract {
        emit DebtTransferred(_index, _project, _investor, _to, _totalAmount);
    }

    function claimedInterest(
        uint256 _index,
        address _project,
        address _investor,
        uint256 _interestEarned,
        uint256 _totalAmount
    ) external onlyCommunityContract {
        emit ClaimedInterest(
            _index,
            _project,
            _investor,
            _interestEarned,
            _totalAmount
        );
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

import "./math/SafeMath.sol";

contract BasicMetaTransaction {
    using SafeMath for uint256;

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Main function to be called when user wants to execute meta transaction.
     * The actual function to be called should be passed as param with name functionSignature
     * Here the basic signature recovery is being used. Signature is expected to be generated using
     * personal_sign method.
     * @param userAddress Address of user trying to do meta transaction
     * @param functionSignature Signature of the actual function to be called via meta transaction
     * @param sigR R part of the signature
     * @param sigS S part of the signature
     * @param sigV V part of the signature
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        require(
            verify(
                userAddress,
                nonces[userAddress],
                getChainID(),
                functionSignature,
                sigR,
                sigS,
                sigV
            ),
            "Signer and signature do not match"
        );
        nonces[userAddress] = nonces[userAddress].add(1);

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) =
            address(this).call(
                abi.encodePacked(functionSignature, userAddress)
            );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );
        return returnData;
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function verify(
        address owner,
        uint256 nonce,
        uint256 chainID,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        bytes32 hash =
            prefixed(
                keccak256(
                    abi.encodePacked(nonce, this, chainID, functionSignature)
                )
            );
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return (owner == signer);
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

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

pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED
import "./UpgradeabilityProxy.sol";


/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    // Storage position of the owner of the contract
    bytes32 private constant PROXY_OWNER_POSITION = keccak256("org.rigour.proxy.owner");

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor(address _implementation) {
        _setUpgradeabilityOwner(msg.sender);
        _upgradeTo(_implementation);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    
    function proxyOwner() public view returns (address owner) {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
    }

    /**
    * @dev Allows the proxy owner to upgrade the current version of the proxy.
    * @param _implementation representing the address of the new implementation to be set.
    */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}

pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    fallback() external payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
            }
    }

  

 function implementation() public view virtual returns (address);
    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
}

pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED
import "./Proxy.sol";


/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param implementation representing the address of the upgraded implementation
    */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant IMPLEMENTATION_POSITION = keccak256("org.govblocks.proxy.implementation");

    /**
    * @dev Constructor function
    */
    constructor()  {}

   
    function implementation() public view override returns (address impl) {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            impl := sload(position)
        }
    }

    /**
    * @dev Sets the address of the current implementation
    * @param _newImplementation address representing the new implementation to be set
    */
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
        sstore(position, _newImplementation)
        }
    }

    /**
    * @dev Upgrades the implementation address
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}

pragma solidity >=0.7.0 <0.8.0;

//SPDX-License-Identifier: UNLICENSED

interface IEvents {
    function hashUpdated(bytes calldata _updatedHash) external;

    function contractorInvited(
        address _contractor,
        uint256[] calldata _feeSchedule
    ) external;

    function contractorSwapped(address _oldContractor, address _newContractor)
        external;

    function builderConfirmed(address _builder) external;

    function contractorConfirmed(address _builder) external;

    function phasesAdded(uint256[] calldata _phaseCosts) external;

    function phaseUpdated(uint256[] calldata _phases, uint256[] calldata _costs)
        external;

    function taskHashUpdated(uint256 _taskId, bytes32[2] calldata _taskHash)
        external;

    function taskCreated(uint256 _taskID) external;

    function investedInProject(uint256 _cost) external;

    function scInvited(uint256 _taskID, address _sc) external;

    function scSwapped(
        uint256 _taskID,
        address _old,
        address _new
    ) external;

    function scConfirmed(uint256 _taskID, address _sc) external;

    function taskFunded(uint256 _taskID) external;

    function taskComplete(uint256 _taskID) external;

    function contractorFeeReleased(uint256 _phase) external;

    function changeOrderFee(uint256 _taskID, uint256 _newCost) external;

    function changeOrderSC(uint256 _taskID, address _sc) external;

    function projectAdded(
        uint256 _projectID,
        address _projectAddress,
        address _builder
    ) external;

    function repayInvestor(
        uint256 _index,
        address _projectAddress,
        address _investor,
        uint256 _tAmount
    ) external;

    function disputeRaised(
        address _sender,
        address _project,
        uint256 _taskId,
        uint256 _disputeId
    ) external;

    function disputeResolved(
        uint256 _disputeId,
        uint256 _result,
        bytes calldata _resultHash
    ) external;

    function communityAdded(
        uint256 _communityID,
        address _owner,
        address _currency,
        bytes calldata _hash
    ) external;

    function updateCommunityHash(
        uint256 _communityID,
        bytes calldata _oldHash,
        bytes calldata _newHash
    ) external;

    function memberAdded(uint256 _communityID, address _member) external;

    function projectPublished(
        uint256 _communityID,
        uint256 _apr,
        address _project,
        address _builder
    ) external;

    function investorInvested(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _cost
    ) external;

    function nftCreated(uint256 _id, address _owner) external;

    function debtTransferred(
        uint256 _index,
        address _project,
        address _investor,
        address _to,
        uint256 _totalAmount
    ) external;

    function claimedInterest(
        uint256 _index,
        address _project,
        address _investor,
        uint256 _interestEarned,
        uint256 _totalAmount
    ) external;
}

pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "../external/contracts/math/SafeMath.sol";
import "./IEvents.sol";
import "../external/contracts/BasicMetaTransaction.sol";

interface IProjectFactory {
    function createProject(
        bytes memory _hash,
        address _currency,
        address _sender
    ) external returns (address _clone);
}

abstract contract IRigor is BasicMetaTransaction {
    /// LIBRARIES ///
    using SafeMath for uint256;

    modifier onlyAdmin() {
        require(admin == msgSender(), "only owner");
        _;
    }

    modifier nonZero(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    /// VARIABLES ///
    address public constant etherCurrency =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant daiCurrency =
        0x273f6Ebe797369F53ad3F286F0789Cb6ce548455;
    address public constant usdcCurrency =
        0xCD78b8062029d0EF32cc1c9457b6beC636A81A69;

    IEvents public eventsInstance;
    IProjectFactory public projectFactoryInstance; //TODO if it can be made internal
    address public disputeContract;
    address public communityContract;

    string public name;
    string public symbol;
    address public admin;
    address payable public treasury;
    uint256 public builderFee;
    uint256 public investorFee;
    mapping(uint256 => address) public projects;
    mapping(address => bool) public projectExist;

    mapping(address => uint256) public projectTokenId;

    mapping(address => address) public wrappedToken;

    uint256 public projectSerial;
    bool public addrSet;
    uint256 internal _tokenIds;

    function setAddr(
        address _eventsContract,
        address _projectFactory,
        address _communityContract,
        address _disputeContract,
        address _rETHAddress,
        address _rDaiAddress,
        address _rUSDCAddress
    ) external virtual;

    function validCurrency(address _currency) public pure virtual;

    /// ADMIN MANAGEMENT ///
    function replaceAdmin(address _newAdmin) external virtual;

    function replaceTreasury(address _treasury) external virtual;

    function replaceNetworkFee(uint256 _builderFee, uint256 _investorFee)
        external
        virtual;

    /// PROJECT ///
    function createProject(bytes memory _hash, address _currency)
        external
        virtual;
}

