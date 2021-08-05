/**
 *Submitted for verification at Etherscan.io on 2020-04-30
*/

// File: @onchain-id/solidity/contracts/IERC734.sol

pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {
    /**
     * @dev Definition of the structure of a Key.
     *
     * Specification: Keys are cryptographic public keys, or contract addresses associated with this identity.
     * The structure should be as follows:
     *   - key: A public key owned by this identity
     *      - purposes: uint256[] Array of the key purposes, like 1 = MANAGEMENT, 2 = EXECUTION
     *      - keyType: The type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
     *      - key: bytes32 The public key. // Its the Keccak256 hash of the key
     */
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    /**
     * @dev Emitted when an execution request was approved.
     *
     * Specification: MUST be triggered when approve was successfully called.
     */
    event Approved(uint256 indexed executionId, bool approved);

    /**
     * @dev Emitted when an execute operation was approved and successfully performed.
     *
     * Specification: MUST be triggered when approve was called and the execution was successfully approved.
     */
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when an execution request was performed via `execute`.
     *
     * Specification: MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when the list of required keys to perform an action was updated.
     *
     * Specification: MUST be triggered when changeKeysRequired was successfully called.
     */
    event KeysRequiredChanged(uint256 purpose, uint256 number);


    /**
     * @dev Adds a _key to the identity. The _purpose specifies the purpose of the key.
     *
     * Triggers Event: `KeyAdded`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);

    /**
    * @dev Approves an execution or claim addition.
    *
    * Triggers Event: `Approved`, `Executed`
    *
    * Specification:
    * This SHOULD require n of m approvals of keys purpose 1, if the _to of the execution is the identity contract itself, to successfully approve an execution.
    * And COULD require n of m approvals of keys purpose 2, if the _to of the execution is another contract, to successfully approve an execution.
    */
    function approve(uint256 _id, bool _approve) external returns (bool success);

    /**
     * @dev Passes an execution instruction to an ERC725 identity.
     *
     * Triggers Event: `ExecutionRequested`, `Executed`
     *
     * Specification:
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for `addKey` and `removeKey`.
     */
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);

    /**
     * @dev Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);

    /**
     * @dev Returns the list of purposes associated with a key.
     */
    function getKeyPurposes(bytes32 _key) external view returns(uint256[] memory _purposes);

    /**
     * @dev Returns an array of public key bytes32 held by this identity.
     */
    function getKeysByPurpose(uint256 _purpose) external view returns (bytes32[] memory keys);

    /**
     * @dev Returns TRUE if a key is present and has the given purpose. If the key is not present it returns FALSE.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) external view returns (bool exists);

    /**
     * @dev Removes _purpose for _key from the identity.
     *
     * Triggers Event: `KeyRemoved`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function removeKey(bytes32 _key, uint256 _purpose) external returns (bool success);
}

// File: @onchain-id/solidity/contracts/IERC735.sol

pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {

    /**
     * @dev Emitted when a claim request was performed.
     *
     * Specification: Is not clear
     */
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was changed.
     *
     * Specification: MUST be triggered when changeClaim was successfully called.
     */
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Definition of the structure of a Claim.
     *
     * Specification: Claims are information an issuer has about the identity holder.
     * The structure should be as follows:
     *   - claim: A claim published for the Identity.
     *      - topic: A uint256 number which represents the topic of the claim. (e.g. 1 biometric, 2 residence (ToBeDefined: number schemes, sub topics based on number ranges??))
     *      - scheme : The scheme with which this claim SHOULD be verified or how it should be processed. Its a uint256 for different schemes. E.g. could 3 mean contract verification, where the data will be call data, and the issuer a contract address to call (ToBeDefined). Those can also mean different key types e.g. 1 = ECDSA, 2 = RSA, etc. (ToBeDefined)
     *      - issuer: The issuers identity contract address, or the address used to sign the above signature. If an identity contract, it should hold the key with which the above message was signed, if the key is not present anymore, the claim SHOULD be treated as invalid. The issuer can also be a contract address itself, at which the claim can be verified using the call data.
     *      - signature: Signature which is the proof that the claim issuer issued a claim of topic for this identity. it MUST be a signed message of the following structure: `keccak256(abi.encode(identityHolder_address, topic, data))`
     *      - data: The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
     *      - uri: The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
     */
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(bytes32 _claimId) external view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) external view returns(bytes32[] memory claimIds);

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimRequested`, `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Requests the ADDITION or the CHANGE of a claim from an issuer.
     * Claims can requested to be added by anybody, including the claim holder itself (self issued).
     *
     * _signature is a signed message of the following structure: `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     *
     * This COULD implement an approval process for pending claims, or add them right away.
     * MUST return a claimRequestId (use claim ID) that COULD be sent to the approve function.
     */
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes calldata _signature, bytes calldata _data, string calldata _uri) external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 _claimId) external returns (bool success);
}

// File: @onchain-id/solidity/contracts/IIdentity.sol

pragma solidity ^0.6.2;



interface IIdentity is IERC734, IERC735 {}

// File: contracts/registry/IClaimTopicsRegistry.sol

pragma solidity ^0.6.0;

interface IClaimTopicsRegistry{
    // EVENTS
    event ClaimTopicAdded(uint256 indexed claimTopic);
    event ClaimTopicRemoved(uint256 indexed claimTopic);

    // OPERATIONS
    function addClaimTopic(uint256 claimTopic) external;
    function removeClaimTopic(uint256 claimTopic) external;

    // GETTERS
    function getClaimTopics() external view returns (uint256[] memory);
}

// File: @onchain-id/solidity/contracts/IClaimIssuer.sol

pragma solidity ^0.6.2;


interface IClaimIssuer is IIdentity {
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);
    function isClaimValid(IIdentity _identity, uint256 claimTopic, bytes calldata sig, bytes calldata data) external view returns (bool);
}

// File: contracts/registry/ITrustedIssuersRegistry.sol

pragma solidity ^0.6.0;


interface ITrustedIssuersRegistry {
    // EVENTS
    event TrustedIssuerAdded(uint indexed index, IClaimIssuer indexed trustedIssuer, uint[] claimTopics);
    event TrustedIssuerRemoved(uint indexed index, IClaimIssuer indexed trustedIssuer);
    event TrustedIssuerUpdated(uint indexed index, IClaimIssuer indexed oldTrustedIssuer, IClaimIssuer indexed newTrustedIssuer, uint[] claimTopics);

    // READ OPERATIONS
    function getTrustedIssuer(uint index) external view returns (IClaimIssuer);
    function getTrustedIssuerClaimTopics(uint index) external view returns(uint[] memory);
    function getTrustedIssuers() external view returns (uint[] memory);
    function hasClaimTopic(address issuer, uint claimTopic) external view returns(bool);
    function isTrustedIssuer(address issuer) external view returns(bool);

    // WRITE OPERATIONS
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint index, uint[] calldata claimTopics) external;
    function removeTrustedIssuer(uint index) external;
    function updateIssuerContract(uint index, IClaimIssuer _newTrustedIssuer, uint[] calldata claimTopics) external;
}

// File: contracts/registry/IIdentityRegistry.sol

pragma solidity ^0.6.0;





interface IIdentityRegistry {
    // EVENTS
    event ClaimTopicsRegistrySet(address indexed _claimTopicsRegistry);
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);
    event IdentityRegistered(address indexed investorAddress, IIdentity indexed identity);
    event IdentityRemoved(address indexed investorAddress, IIdentity indexed identity);
    event IdentityUpdated(IIdentity indexed old_identity, IIdentity indexed new_identity);
    event TrustedIssuersRegistrySet(address indexed _trustedIssuersRegistry);

    // WRITE OPERATIONS
    function deleteIdentity(address _user) external;
    function registerIdentity(address _user, IIdentity _identity, uint16 _country) external;
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external;
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external;
    function updateCountry(address _user, uint16 _country) external;
    function updateIdentity(address _user, IIdentity _identity) external;

    // READ OPERATIONS
    function contains(address _wallet) external view returns (bool);
    function isVerified(address _userAddress) external view returns (bool);

    // GETTERS
    function getIdentityOfWallet(address _wallet) external view returns (IIdentity);
    function getInvestorCountryOfWallet(address _wallet) external view returns (uint16);
    function getIssuersRegistry() external view returns (ITrustedIssuersRegistry);
    function getTopicsRegistry() external view returns (IClaimTopicsRegistry);
}

// File: contracts/compliance/ICompliance.sol

pragma solidity ^0.6.0;

interface ICompliance {
    function canTransfer(address _from, address _to, uint256 value) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * Requirements
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
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.6.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/roles/AgentRole.sol

pragma solidity ^0.6.0;



contract AgentRole is Ownable {
    using Roles for Roles.Role;

    event AgentAdded(address indexed account);
    event AgentRemoved(address indexed account);

    Roles.Role private _agents;

    modifier onlyAgent() {
        require(isAgent(msg.sender), "AgentRole: caller does not have the Agent role");
        _;
    }

    function isAgent(address account) public view returns (bool) {
        return _agents.has(account);
    }

    function addAgent(address account) public onlyOwner {
        _addAgent(account);
    }

    function removeAgent(address account) public onlyOwner {
        _removeAgent(account);
    }

    function _addAgent(address account) internal {
        _agents.add(account);
        emit AgentAdded(account);
    }

    function _removeAgent(address account) internal {
        _agents.remove(account);
        emit AgentRemoved(account);
    }
}

// File: contracts/token/TransferManager.sol

pragma solidity ^0.6.0;










contract Pausable is AgentRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyAgent whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyAgent whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


contract TransferManager is Pausable, ERC20 {
    mapping(address => uint256) private holderIndices;
    mapping(address => bool) public frozen;
    mapping(address => IIdentity) public _identity;
    mapping(address => uint256) public frozenTokens;
    mapping(uint16 => uint256) private countryShareHolders;
    address[] private shareholders;

    IIdentityRegistry public identityRegistry;
    ICompliance public compliance;

    event IdentityRegistryAdded(address indexed _identityRegistry);

    event ComplianceAdded(address indexed _compliance);

    event AddressFrozen(
        address indexed addr,
        bool indexed isFrozen,
        address indexed owner
    );

    event RecoverySuccess(
        address wallet_lostAddress,
        address wallet_newAddress,
        address onchainID
    );

    event RecoveryFails(
        address wallet_lostAddress,
        address wallet_newAddress,
        address onchainID
    );

    event TokensFrozen(address indexed addr, uint256 amount);

    event TokensUnfrozen(address indexed addr, uint256 amount);

    constructor (
        address _identityRegistry,
        address _compliance
    ) public {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
        compliance = ICompliance(_compliance);
        emit ComplianceAdded(_compliance);
    }

    /**
    * @notice ERC-20 overridden function that include logic to check for trade validity.
    *  Require that the msg.sender and to addresses are not frozen.
    *  Require that the value should not exceed available balance .
    *  Require that the to address is a verified address,
    *  If the `to` address is not currently a shareholder then it MUST become one.
    *  If the transfer will reduce `msg.sender`'s balance to 0 then that address
    *  MUST be removed from the list of shareholders.
    *
    * @param _to The address of the receiver
    * @param _value The number of tokens to transfer
    *
    * @return `true` if successful and revert if unsuccessful
    */
    function transfer(address _to, uint256 _value) public override whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[msg.sender]);
        require(_value <= balanceOf(msg.sender).sub(frozenTokens[msg.sender]), "Insufficient Balance");
        if (identityRegistry.isVerified(_to) && compliance.canTransfer(msg.sender, _to, _value)) {
            updateShareholders(_to);
            pruneShareholders(msg.sender, _value);
            return super.transfer(_to, _value);
        }

        revert("Transfer not possible");
    }
    /**
    * @notice function allowing to issue transfers in batch
    *  Require that the msg.sender and `to` addresses are not frozen.
    *  Require that the total value should not exceed available balance.
    *  Require that the `to` addresses are all verified addresses,
    *  If one of the `to` addresses is not currently a shareholder then it MUST become one.
    *  If the batchTransfer will reduce `msg.sender`'s balance to 0 then that address
    *  MUST be removed from the list of shareholders.
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *
    * @param _toList The addresses of the receivers
    * @param _values The number of tokens to transfer to the corresponding receiver
    *
    */

    function batchTransfer(address[] calldata _toList, uint256[] calldata _values) external {
        for (uint256 i = 0; i < _toList.length; i++) {
            transfer(_toList[i], _values[i]);
        }
    }

    /**
    * @notice ERC-20 overridden function that include logic to check for trade validity.
    *  Require that the from and to addresses are not frozen.
    *  Require that the value should not exceed available balance .
    *  Require that the to address is a verified address,
    *  If the `to` address is not currently a shareholder then it MUST become one.
    *  If the transfer will reduce `from`'s balance to 0 then that address
    *  MUST be removed from the list of shareholders.
    *
    * @param _from The address of the sender
    * @param _to The address of the receiver
    * @param _value The number of tokens to transfer
    *
    * @return `true` if successful and revert if unsuccessful
    */
    function transferFrom(address _from, address _to, uint256 _value) public override whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[_from]);
        require(_value <= balanceOf(_from).sub(frozenTokens[_from]), "Insufficient Balance");
        if (identityRegistry.isVerified(_to) && compliance.canTransfer(_from, _to, _value)) {
            updateShareholders(_to);
            pruneShareholders(_from, _value);
            return super.transferFrom(_from, _to, _value);
        }

        revert("Transfer not possible");
    }

    /**
    *
    *  In case the `from` address has not enough free tokens (unfrozen tokens)
    *  but has a total balance higher or equal to the `value` amount
    *  the amount of frozen tokens is reduced in order to have enough free tokens
    *  to proceed the transfer, in such a case, the remaining balance on the `from`
    *  account is 100% composed of frozen tokens post-transfer.
    *  Require that the `to` address is a verified address,
    *  If the `to` address is not currently a shareholder then it MUST become one.
    *  If the transfer will reduce `from`'s balance to 0 then that address
    *  MUST be removed from the list of shareholders.
    *
    * @param _from The address of the sender
    * @param _to The address of the receiver
    * @param _value The number of tokens to transfer
    *
    * @return `true` if successful and revert if unsuccessful
    */
    function forcedTransfer(address _from, address _to, uint256 _value) public onlyAgent returns (bool) {
        uint256 freeBalance = balanceOf(_from) - frozenTokens[_from];
        if (_value > freeBalance) {
            uint256 tokensToUnfreeze = _value - freeBalance;
            frozenTokens[_from] -= tokensToUnfreeze;
        }
        if (identityRegistry.isVerified(_to) && compliance.canTransfer(_from, _to, _value)) {
            updateShareholders(_to);
            pruneShareholders(_from, _value);
            _transfer(_from, _to, _value);
            return true;
        }
        revert("Transfer not possible");
    }

    /**
   * @notice function allowing to issue forced transfers in batch
   *  Only Agent can call this function.
   *  Require that `value` should not exceed available balance of `_from`.
   *  Require that the `to` addresses are all verified addresses,
   *  If one of the `to` addresses is not currently a shareholder then it MUST become one.
   *  If the batchForcedTransfer will reduce `_from`'s balance to 0 then that address
   *  MUST be removed from the list of shareholders.
   *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_fromList.length` IS TOO HIGH,
   *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
   *
   * @param _fromList The addresses of the senders
   * @param _toList The addresses of the receivers
   * @param _values The number of tokens to transfer to the corresponding receiver
   *
   */

    function batchForcedTransfer(address[] calldata _fromList, address[] calldata _toList, uint256[] calldata _values) external {
        for (uint256 i = 0; i < _fromList.length; i++) {
            forcedTransfer(_fromList[i], _toList[i], _values[i]);
        }
    }

    /**
     * @notice Improved version of default mint method. Tokens can be minted
     * to an address if only it is a verified address as per the security token.
     * This check will be useful for a complaint crowdsale.
     * Only owner can call.
     *
     * @param _to Address to mint the tokens to.
     * @param _amount Amount of tokens to mint.
     *
     */
    function mint(address _to, uint256 _amount) public onlyAgent {
        require(identityRegistry.isVerified(_to), "Identity is not verified.");

        _mint(_to, _amount);
        updateShareholders(_to);
    }

    function batchMint(address[] calldata _to, uint256[] calldata _amount) external {
        for (uint256 i = 0; i < _to.length; i++) {
            mint(_to[i], _amount[i]);
        }
    }

    function burn(address account, uint256 value) public onlyAgent {
        _burn(account, value);
    }

    function batchBurn(address[] calldata account, uint256[] calldata value) external {
        for (uint256 i = 0; i < account.length; i++) {
            burn(account[i], value[i]);
        }
    }

    /**
     * Holder count simply returns the total number of token holder addresses.
     */
    function holderCount() public view returns (uint) {
        return shareholders.length;
    }

    /**
     *  By counting the number of token holders using `holderCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if `index >= holderCount()`.
     *  @param index The zero-based index of the holder.
     *  @return `address` the address of the token holder with the given index.
     */
    function holderAt(uint256 index) public onlyOwner view returns (address){
        require(index < shareholders.length);
        return shareholders[index];
    }


    /**
     *  If the address is not in the `shareholders` array then push it
     *  and update the `holderIndices` mapping.
     *  @param addr The address to add as a shareholder if it's not already.
     */
    function updateShareholders(address addr) internal {
        if (holderIndices[addr] == 0) {
            shareholders.push(addr);
            holderIndices[addr] = shareholders.length;
            uint16 country = identityRegistry.getInvestorCountryOfWallet(addr);
            countryShareHolders[country]++;
        }
    }

    /**
     *  If the address is in the `shareholders` array and the forthcoming
     *  transfer or transferFrom will reduce their balance to 0, then
     *  we need to remove them from the shareholders array.
     *  @param addr The address to prune if their balance will be reduced to 0.
     *  @dev see https://ethereum.stackexchange.com/a/39311
     */
    function pruneShareholders(address addr, uint256 value) internal {
        uint256 balance = balanceOf(addr) - value;
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[addr] - 1;
        uint256 lastIndex = shareholders.length - 1;
        address lastHolder = shareholders[lastIndex];
        // overwrite the addr's slot with the last shareholder
        shareholders[holderIndex] = lastHolder;
        // also copy over the index
        holderIndices[lastHolder] = holderIndices[addr];
        // trim the shareholders array (which drops the last entry)
        shareholders.pop();
        // and zero out the index for addr
        holderIndices[addr] = 0;
        //Decrease the country count
        uint16 country = identityRegistry.getInvestorCountryOfWallet(addr);
        countryShareHolders[country]--;
    }

    function getShareholderCountByCountry(uint16 index) public view returns (uint) {
        return countryShareHolders[index];
    }

    /**
     *  Sets an address frozen status for this token.
     *  @param addr The address for which to update frozen status
     *  @param freeze Frozen status of the address
     */
    function setAddressFrozen(address addr, bool freeze) public onlyAgent {
        frozen[addr] = freeze;

        emit AddressFrozen(addr, freeze, msg.sender);
    }

    /**
     * @notice function allowing to set frozen addresses in batch
     *  Only Agent can call this function.
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `addrList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *
     *  @param addrList The addresses for which to update frozen status
     *  @param freeze Frozen status of the corresponding address
     *
     */

    function batchSetAddressFrozen(address[] calldata addrList, bool[] calldata freeze) external {
        for (uint256 i = 0; i < addrList.length; i++) {
            setAddressFrozen(addrList[i], freeze[i]);
        }
    }

    /**
     *  Freezes token amount specified for given address.
     *  @param addr The address for which to update frozen tokens
     *  @param amount Amount of Tokens to be frozen
     */
    function freezePartialTokens(address addr, uint256 amount) public onlyAgent {
        uint256 balance = balanceOf(addr);
        require(balance >= frozenTokens[addr] + amount, "Amount exceeds available balance");
        frozenTokens[addr] += amount;
        emit TokensFrozen(addr, amount);
    }

    /**
     * @notice function allowing to freeze tokens partially in batch
     *  Only Agent can call this function.
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `addrList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *
     *  @param addrList The addresses on which tokens need to be frozen
     *  @param amounts the amount of tokens to freeze on the corresponding address
     *
     */

    function batchFreezePartialTokens(address[] calldata addrList, uint256[] calldata amounts) external {
        for (uint256 i = 0; i < addrList.length; i++) {
            freezePartialTokens(addrList[i], amounts[i]);
        }
    }

    /**
     *  Unfreezes token amount specified for given address
     *  @param addr The address for which to update frozen tokens
     *  @param amount Amount of Tokens to be unfrozen
     */
    function unfreezePartialTokens(address addr, uint256 amount) public onlyAgent {
        require(frozenTokens[addr] >= amount, "Amount should be less than or equal to frozen tokens");
        frozenTokens[addr] -= amount;
        emit TokensUnfrozen(addr, amount);
    }

    /**
     * @notice function allowing to unfreeze tokens partially in batch
     *  Only Agent can call this function.
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `addrList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *
     *  @param addrList The addresses on which tokens need to be unfrozen
     *  @param amounts the amount of tokens to unfreeze on the corresponding address
     *
     */

    function batchUnfreezePartialTokens(address[] calldata addrList, uint256[] calldata amounts) external {
        for (uint256 i = 0; i < addrList.length; i++) {
            unfreezePartialTokens(addrList[i], amounts[i]);
        }
    }

    //Identity registry setter.
    function setIdentityRegistry(address _identityRegistry) public onlyOwner {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
    }

    function setCompliance(address _compliance) public onlyOwner {
        compliance = ICompliance(_compliance);
        emit ComplianceAdded(_compliance);
    }

    function recoveryAddress(address wallet_lostAddress, address wallet_newAddress, address onchainID) public onlyAgent returns (bool){
        require(holderIndices[wallet_lostAddress] != 0 && holderIndices[wallet_newAddress] == 0);
        IIdentity _onchainID = IIdentity(onchainID);
        bytes32 _key = keccak256(abi.encode(wallet_newAddress));
        if (_onchainID.keyHasPurpose(_key, 1)) {
            uint investorTokens = balanceOf(wallet_lostAddress);
            identityRegistry.registerIdentity(wallet_newAddress, _onchainID, identityRegistry.getInvestorCountryOfWallet(wallet_lostAddress));
            identityRegistry.deleteIdentity(wallet_lostAddress);
            forcedTransfer(wallet_lostAddress, wallet_newAddress, investorTokens);
            emit RecoverySuccess(wallet_lostAddress, wallet_newAddress, onchainID);
            return true;
        }
        emit RecoveryFails(wallet_lostAddress, wallet_newAddress, onchainID);
        revert("Recovery not possible");
    }
}

// File: contracts/token/IToken.sol

pragma solidity ^0.6.0;

//interface
interface IToken {
    event UpdatedTokenInformation(string newName, string newSymbol, uint8 newDecimals, string newVersion, address newOnchainID);

    // getters
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function onchainID() external view returns (address);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);

    // setters
    function setTokenInformation(string calldata _name, string calldata _symbol, uint8 _decimals, string calldata _version, address _onchainID) external;
}

// File: contracts/token/Token.sol

pragma solidity ^0.6.0;



contract Token is IToken, TransferManager {

    string private tokenName;
    string private tokenSymbol;
    string private tokenVersion;
    uint8 private tokenDecimals;
    address private tokenOnchainID;

    constructor(
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        string memory _version,
        address _onchainID)
    public TransferManager(_identityRegistry, _compliance) {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        tokenVersion = _version;
        tokenOnchainID = _onchainID;

        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, tokenVersion, tokenOnchainID);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * balanceOf() and transfer().
     */
    function decimals() public override view returns (uint8){
        return tokenDecimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public override view returns (string memory){
        return tokenName;
    }

    /**
     * @dev Returns the address of the onchainID of the token.
     * the onchainID of the token gives all the information available
     * about the token and is managed by the token issuer or his agent.
     */
    function onchainID() public override view returns (address){
        return tokenOnchainID;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public override view returns (string memory){
        return tokenSymbol;
    }

    /**
     * @dev Returns the TREX version of the token.
     * current version is 2.5.0
     */
    function version() public override view returns (string memory){
        return tokenVersion;
    }

    /**
     * @dev Sets the values for `tokenName`, `tokenSymbol`, `tokenDecimals`,
     * `tokenVersion` and `tokenOnchainID`
     */

    function setTokenInformation(string calldata _name, string calldata _symbol, uint8 _decimals, string calldata _version, address _onchainID) external override onlyOwner {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        tokenVersion = _version;
        tokenOnchainID = _onchainID;

        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, tokenVersion, tokenOnchainID);
    }
}