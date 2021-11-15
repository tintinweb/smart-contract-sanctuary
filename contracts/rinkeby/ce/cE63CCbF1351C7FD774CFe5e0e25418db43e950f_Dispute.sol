pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "./interfaces/IRigor.sol";
import "./interfaces/IProject.sol";
import "./interfaces/IEvents.sol";
import "./external/contracts/BasicMetaTransaction.sol";
import "./external/contracts/proxy/Initializable.sol";
import "./external/contracts/proxy/OwnedUpgradeabilityProxy.sol";

contract Dispute is BasicMetaTransaction, Initializable {
    IRigor public rigor;
    IEvents public eventsInstance;

    enum Status {None, Active, Accepted, Rejected}

    struct DisputeStruct {
        Status status;
        address project;
        uint256 taskId;
        address raisedBy;
        bytes reasonHash;
        bytes resultHash;
        mapping(address => bytes) otherBytes;
    }

    mapping(uint256 => DisputeStruct) public disputes;
    uint256 public disputeCount; //starts from 1

    function initialize(address _rigor, address _eventsContract)
        public
        initializer
    {
        rigor = IRigor(_rigor);
        eventsInstance = IEvents(_eventsContract);
    }

    modifier onlyRigor() {
        require(address(rigor) == msgSender(), "Only rigor");
        _;
    }

    modifier onlyMember(address _project, uint256 _taskId) {
        IProject _projectInstance = IProject(_project);
        (, address _sc, ) = (_projectInstance.tasks(_taskId));
        require(
            _projectInstance.contractor() == msgSender() ||
                _projectInstance.builder() == msgSender() ||
                _sc == msgSender(),
            "Invalid Member of project"
        );
        _;
    }

    modifier onlyAdmin() {
        require(rigor.admin() == msgSender(), "Only admin");
        _;
    }

    function raiseDispute(
        bytes calldata _reasonHash,
        address _project,
        uint256 _taskId
    ) external onlyMember(_project, _taskId) {
        disputeCount++;
        disputes[disputeCount].status = Status.Active;
        disputes[disputeCount].reasonHash = _reasonHash;
        disputes[disputeCount].project = _project;
        disputes[disputeCount].taskId = _taskId;
        disputes[disputeCount].raisedBy = msgSender();
        eventsInstance.disputeRaised(
            msgSender(),
            _project,
            _taskId,
            disputeCount
        );
    }

    function addDocuments(uint256 _disputeNo, bytes calldata _reasonHash)
        external
    {
        address _project = disputes[_disputeNo].project;
        uint256 _taskId = disputes[_disputeNo].taskId;
        IProject _projectInstance = IProject(_project);
        (, address _sc, ) = (_projectInstance.tasks(_taskId));
        require(
            _projectInstance.contractor() == msgSender() ||
                _projectInstance.builder() == msgSender() ||
                _sc == msgSender(),
            "Invalid Member of project"
        );
        disputes[_disputeNo].otherBytes[msgSender()] = _reasonHash;
    }

    function resolveDispute(
        uint256 _disputeId,
        bytes calldata _resultHash,
        uint256 _result
    ) external onlyAdmin {
        require(_result > 1, "Invalid resolve");
        disputes[_disputeId].status = Status(_result);
        disputes[_disputeId].resultHash = _resultHash;
        eventsInstance.disputeResolved(_disputeId, _result, _resultHash);
    }

    function viewDocument(uint256 _disputeId, address _address)
        external
        view
        returns (bytes memory _reasonHash)
    {
        _reasonHash = disputes[_disputeId].otherBytes[_address];
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

pragma solidity >=0.5.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes

contract SignatureDecoder {
    
    /// @dev Recovers address who signed the message
    /// @param messageHash operation ethereum signed message hash
    /// @param messageSignature message `txHash` signature
    /// @param pos which signature to read
    function recoverKey (
        bytes32 messageHash,
        bytes memory messageSignature,
        uint256 pos
    )
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignature, pos);
        return ecrecover(messageHash, v, r, s);
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
import "./IRigor.sol";
import "../external/contracts/signature/SignatureDecode.sol";
import "../external/contracts/token/ERC20/IERC20Original.sol";
import "../external/contracts/BasicMetaTransaction.sol";

import {Tasks, Task} from "../libraries/Tasks.sol";

/**
 * Rigor v0.1.0 Deployable Project Escrow Contract Interface
 *
 * Interface for child contract from Rigor service contract; escrows all funds
 * Use task library to store hashes of data within project
 */
abstract contract IProject is BasicMetaTransaction {
    /// LIBRARIES///
    using SafeMath for uint256;
    using Tasks for Task;

    struct Phase {
        uint256 phaseCost;
        uint256[] phaseToTaskList;
        bool paid;
    }

    // Fixed //
    IRigor public rigor;
    IEvents internal eventsInstance;
    address public currency;
    uint256 public builderFee;
    uint256 public investorFee;
    address public builder;

    // Variable //
    bytes public projectHash;
    address public contractor;
    bool public contractorConfirmed;
    uint256 public hashChangeNonce;
    uint256 public totalInvested;
    uint256 public totalAllocated;
    uint256 public phaseCount; //starts from 1
    uint256 public taskSerial; //starts from 1

    uint256 internal nonFundedCounter;
    uint256[] internal nonFundedPhase;

    uint256 internal nonFundedPhaseIndex = 1;
    uint256 internal nonFundedTask;
    mapping(uint256 => uint256[]) internal nonFundedPhaseToTask; //nonFundedPhaseToTasks
    uint256[] internal nonFundedTaskPhases; //sorted array of phase with non funded tasks

    mapping(uint256 => Phase) public phases;
    mapping(uint256 => Task) public tasks; //starts from 1

    /// MODIFIERS ///
    modifier onlyRigor() {
        require(msgSender() == address(rigor), "1");
        _;
    }

    modifier onlyBuilder() {
        require(msgSender() == builder, "2");
        _;
    }

    modifier contractorNotAccepted() {
        require(!contractorConfirmed, "5");
        _;
    }

    modifier contractorAccepted() {
        require(contractorConfirmed, "5.2");
        _;
    }

    /**
     * Pay a general contractor's fee for a given phase
     * @dev modifier onlyBuilder
     * @param _phase the phase to pay out
     */
    function releaseFeeContractor(uint256 _phase) external virtual;

    // Task-Specific //

    /**
     * Create a new task in this project
     * @dev modifier onlyContractor
     */
    function addTask(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * Mark a task as complete
     * @dev modifier onlyContractor
     */
    function setComplete(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * Invite a subcontractor to a given task
     * @dev modifier onlyContractor
     * @param _index uint: the index of the task the sc is invited to
     * @param _to address: the address of the subcontractor being invited
     */
    function inviteSC(uint256[] memory _index, address[] memory _to)
        public
        virtual;

    /**
     * Accept an invite to a given task
     * @dev modifier onlySC
     * @param _index uint: the index of the task being joined
     */
    function acceptInviteSC(uint256 _index) external virtual;

    function investInProject(uint256 _cost) external payable virtual;

    function fundProject() public virtual;

    /**
     * Recover lifecycle alerts from a task
     * @param _index uint the index of the task within the project contract
     * @return _alerts bool[5] array of alert statuses
     */
    function getAlerts(uint256 _index)
        public
        view
        virtual
        returns (bool[3] memory _alerts);

    function getTaskHash(uint256 _index)
        external
        view
        virtual
        returns (bytes32[2] memory _taskHash)
    {
        return tasks[_index].taskHash;
    }

    /**
     * Get the cost of a contractor's Fees
     * @return _cost uint the sum of all fees across all phases
     */
    function projectCost() external view virtual returns (uint256 _cost);

    function getPhaseToTaskList(uint256 _index)
        external
        view
        virtual
        returns (uint256[] memory _taskList);
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

pragma solidity >=0.7.0 <0.8.0;

//SPDX-License-Identifier: UNLICENSED

library Tasks {
    /// MODIFIERS ///
    modifier uninitialized(Task storage _self) {
        require(_self.state == TaskStatus.None, "Already initialized");
        _;
    }

    modifier onlyInactive(Task storage _self) {
        require(!_self.alerts[uint256(Lifecycle.SCConfirmed)], "Only Inactive");
        _;
    }

    modifier onlyActive(Task storage _self) {
        require(_self.alerts[uint256(Lifecycle.SCConfirmed)], "Only Active");
        _;
    }

    /// MUTABLE FUNCTIONS ///

    // Task Status Changing Functions //

    /**
     * Create a new Task object
     * @dev cannot operate on initialized tasks
     * @param _self Task the task struct being mutated
     * @param _cost uint the number of tokens to be escrowed in this contract
     */
    function initialize(
        Task storage _self,
        bytes32[2] memory _taskHash,
        uint256 _cost
    ) public uninitialized(_self) {
        _self.taskHash = _taskHash;
        _self.cost = _cost;
        _self.state = TaskStatus.Inactive;
        _self.alerts[0] = true;
    }

    /**
     * Attempt to transition task state from Payment Pending to Complete
     * @param _self Task the task whose state is being mutated
     */
    function setComplete(Task storage _self) internal onlyActive(_self) {
        // State/ Lifecycle //
        _self.alerts[uint256(Lifecycle.None)] = true;
        _self.state = TaskStatus.Complete;
    }

    // Subcontractor Joining //

    /**
     * Invite a subcontractor to the task
     * @param _self Task the task being joined by subcontractor
     * @param _sc address the subcontractor being invited
     */
    function inviteSubcontractor(Task storage _self, address _sc)
        internal
        onlyInactive(_self)
    {
        _self.subcontractor = _sc;
    }

    /**
     * As a subcontractor, accept an invitation to participate in a task.
     * @param _self Task the task being joined by subcontractor
     */
    function acceptInvitation(Task storage _self, address _sc)
        internal
        onlyInactive(_self)
    {
        // Prerequisites //
        require(_self.subcontractor == _sc, "Only Subcontractor");
        require(_self.alerts[uint256(Lifecycle.TaskFunded)], "Only funded");

        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.SCConfirmed)] = true;
        if (_self.alerts[uint256(Lifecycle.None)])
            _self.alerts[uint256(Lifecycle.None)] = false;
        _self.state = TaskStatus.Active;
    }

    // Task Funding //

    /**
     * Set a task as funded
     * @dev modifier onlyAdmin
     * @param _self Task the task being set as funded
     */
    function fundTask(Task storage _self) internal onlyInactive(_self) {
        // Prerequisites //
        require(!_self.alerts[uint256(Lifecycle.TaskFunded)], "Already funded");

        // State/ Lifecycle //
        _self.alerts[uint256(Lifecycle.TaskFunded)] = true;
        if (_self.alerts[uint256(Lifecycle.None)])
            _self.alerts[uint256(Lifecycle.None)] = false;
    }

    /// VIEWABLE FUNCTIONS ///

    /**
     * Determine the current state of all alerts in the project
     * @param _self Task the task being queried for alert status
     * @return _alerts bool[3] array of bool representing whether Lifecycle alert has been reached
     */
    function getAlerts(Task storage _self)
        internal
        view
        returns (bool[3] memory _alerts)
    {
        for (uint256 i = 0; i < _alerts.length; i++)
            _alerts[i] = _self.alerts[i];
    }

    /**
     * Return the numerical encoding of the TaskStatus enumeration stored as state in a task
     * @param _self Task the task being queried for state
     * @return _state uint 0: none, 1: inactive, 2: active, 3: complete
     */
    function getState(Task storage _self)
        internal
        view
        returns (uint256 _state)
    {
        return uint256(_self.state);
    }
}

//Task metadata
struct Task {
    // Metadata //
    bytes32[2] taskHash;
    uint256 cost;
    address subcontractor;
    // Lifecycle //
    TaskStatus state;
    mapping(uint256 => bool) alerts;
}

enum TaskStatus {
    None,
    Inactive,
    Active,
    Complete
}

enum Lifecycle {
    None,
    TaskFunded,
    SCConfirmed
}

