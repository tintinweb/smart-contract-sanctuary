// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


/**
 * @dev Because we use the code hashes of the proxy contracts for proxy address
 * derivation, it is important that other packages have access to the correct
 * values when they import the salt library.
 */
library CodeHashes {
  bytes32 internal constant ONE_TO_ONE_CODEHASH = 0x63d9f7b5931b69188c8f6b806606f25892f1bb17b7f7e966fe3a32c04493aee4;
  bytes32 internal constant MANY_TO_ONE_CODEHASH = 0xa035ad05a1663db5bfd455b99cd7c6ac6bd49269738458eda140e0b78ed53f79;
  bytes32 internal constant IMPLEMENTATION_HOLDER_CODEHASH = 0x11c370493a726a0ffa93d42b399ad046f1b5a543b6e72f1a64f1488dc1c58f2c;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

/* ==========  External Libraries  ========== */
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/* ==========  Proxy Contracts  ========== */
import "./ManyToOneImplementationHolder.sol";
import { DelegateCallProxyManyToOne } from "./DelegateCallProxyManyToOne.sol";
import { DelegateCallProxyOneToOne } from "./DelegateCallProxyOneToOne.sol";

/* ==========  Internal Libraries  ========== */
import { SaltyLib as Salty } from "./SaltyLib.sol";
import { CodeHashes } from "./CodeHashes.sol";

/* ==========  Inheritance  ========== */
import "./interfaces/IDelegateCallProxyManager.sol";


/**
 * @dev Contract that manages deployment and upgrades of delegatecall proxies.
 *
 * An implementation identifier can be created on the proxy manager which is
 * used to specify the logic address for a particular contract type, and to
 * upgrade the implementation as needed.
 *
 * ====== Proxy Types ======
 * A one-to-one proxy is a single proxy contract with an upgradeable implementation
 * address.
 *
 * A many-to-one proxy is a single upgradeable implementation address that may be
 * used by many proxy contracts.
 *
 * ====== Access Control ======
 * The proxy manager has a single address as its owner.
 *
 * The owner is the sole account with the following permissions:
 * - Create new many-to-one implementations
 * - Create new one-to-one proxies
 * - Modify the implementation address of existing proxies
 * - Lock proxies
 * - Designate approved deployers
 * - Remove approved deployers
 * - Modify the owner address
 *
 * Approved deployers may only deploy many-to-one proxies.
 *
 * ====== Upgrades ======
 * Proxies can be upgraded by the owner if they are not locked.
 *
 * Many-to-one proxy implementations are upgraded by calling the holder contract
 * for the implementation ID being upgraded.
 * One-to-one proxies are upgraded by calling the proxy contract directly.
 *
 * The owner can lock a one-to-one proxy or many-to-one implementation ID so that
 * it becomes impossible to upgrade.
 */
contract DelegateCallProxyManager is Ownable, IDelegateCallProxyManager {
/* ==========  Events  ========== */

  event DeploymentApprovalGranted(address deployer);
  event DeploymentApprovalRevoked(address deployer);

  event ManyToOne_ImplementationCreated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ImplementationUpdated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ImplementationLocked(bytes32 implementationID);

  event ManyToOne_ProxyDeployed(
    bytes32 implementationID,
    address proxyAddress
  );

  event OneToOne_ProxyDeployed(
    address proxyAddress,
    address implementationAddress
  );

  event OneToOne_ImplementationUpdated(
    address proxyAddress,
    address implementationAddress
  );

  event OneToOne_ImplementationLocked(address proxyAddress);

/* ==========  Storage  ========== */

  // Addresses allowed to deploy many-to-one proxies.
  mapping(address => bool) internal _approvedDeployers;

  // Maps implementation holders to their implementation IDs.
  mapping(bytes32 => address) internal _implementationHolders;

  // Maps implementation holders & proxy addresses to bool stating if they are locked.
  mapping(address => bool) internal _lockedImplementations;

  // Temporary value used in the many-to-one proxy constructor.
  // The many-to-one proxy contract is deployed with create2 and
  // uses static initialization code for simple address derivation,
  // so it calls the proxy manager in the constructor to get this
  // address in order to save it as an immutable in the bytecode.
  address internal _implementationHolder;

/* ==========  Modifiers  ========== */

  modifier onlyApprovedDeployer {
    address sender = _msgSender();
    require(_approvedDeployers[sender] || sender == owner(), "ERR_NOT_APPROVED");
    _;
  }

/* ==========  Constructor  ========== */

  constructor() public Ownable() {}

/* ==========  Access Control  ========== */

  /**
   * @dev Allows `deployer` to deploy many-to-one proxies.
   */
  function approveDeployer(address deployer) external override onlyOwner {
    _approvedDeployers[deployer] = true;
    emit DeploymentApprovalGranted(deployer);
  }

  /**
   * @dev Prevents `deployer` from deploying many-to-one proxies.
   */
  function revokeDeployerApproval(address deployer) external override onlyOwner {
    _approvedDeployers[deployer] = false;
    emit DeploymentApprovalRevoked(deployer);
  }

/* ==========  Implementation Management  ========== */

  /**
   * @dev Creates a many-to-one proxy relationship.
   *
   * Deploys an implementation holder contract which stores the
   * implementation address for many proxies. The implementation
   * address can be updated on the holder to change the runtime
   * code used by all its proxies.
   *
   * @param implementationID ID for the implementation, used to identify the
   * proxies that use it. Also used as the salt in the create2 call when
   * deploying the implementation holder contract.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  )
    external
    override
    onlyOwner
  {
    // Deploy the implementation holder contract with the implementation
    // ID as the create2 salt.
    address implementationHolder = Create2.deploy(
      0,
      implementationID,
      type(ManyToOneImplementationHolder).creationCode
    );

    // Store the implementation holder address
    _implementationHolders[implementationID] = implementationHolder;

    // Sets the implementation address.
    _setImplementation(implementationHolder, implementation);

    emit ManyToOne_ImplementationCreated(
      implementationID,
      implementation
    );
  }

  /**
   * @dev Lock the current implementation for `implementationID` so that it can never be upgraded again.
   */
  function lockImplementationManyToOne(bytes32 implementationID) external override onlyOwner {
    // Read the implementation holder address from storage.
    address implementationHolder = _implementationHolders[implementationID];
    // Verify that the implementation exists.
    require(implementationHolder != address(0), "ERR_IMPLEMENTATION_ID");
    _lockedImplementations[implementationHolder] = true;
    emit ManyToOne_ImplementationLocked(implementationID);
  }

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationOneToOne(address proxyAddress) external override onlyOwner {
    _lockedImplementations[proxyAddress] = true;
    emit OneToOne_ImplementationLocked(proxyAddress);
  }

  /**
   * @dev Updates the implementation address for a many-to-one
   * proxy relationship.
   *
   * @param implementationID Identifier for the implementation.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  )
    external
    override
    onlyOwner
  {
    // Read the implementation holder address from storage.
    address implementationHolder = _implementationHolders[implementationID];

    // Verify that the implementation exists.
    require(implementationHolder != address(0), "ERR_IMPLEMENTATION_ID");

    // Verify implementation is not locked
    require(!_lockedImplementations[implementationHolder], "ERR_IMPLEMENTATION_LOCKED");

    // Set the implementation address
    _setImplementation(implementationHolder, implementation);

    emit ManyToOne_ImplementationUpdated(
      implementationID,
      implementation
    );
  }

  /**
   * @dev Updates the implementation address for a one-to-one proxy.
   *
   * Note: This could work for many-to-one as well if the caller
   * provides the implementation holder address in place of the
   * proxy address, as they use the same access control and update
   * mechanism.
   *
   * @param proxyAddress Address of the deployed proxy
   * @param implementation Address with the runtime code for
   * the proxy to use.
   */
  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  )
    external
    override
    onlyOwner
  {
    // Verify proxy is not locked
    require(!_lockedImplementations[proxyAddress], "ERR_IMPLEMENTATION_LOCKED");

    // Set the implementation address
    _setImplementation(proxyAddress, implementation);

    emit OneToOne_ImplementationUpdated(proxyAddress, implementation);
  }

/* ==========  Proxy Deployment  ========== */

  /**
   * @dev Deploy a proxy contract with a one-to-one relationship
   * with its implementation.
   *
   * The proxy will have its own implementation address which can
   * be updated by the proxy manager.
   *
   * @param suppliedSalt Salt provided by the account requesting deployment.
   * @param implementation Address of the contract with the runtime
   * code that the proxy should use.
   */
  function deployProxyOneToOne(
    bytes32 suppliedSalt,
    address implementation
  )
    external
    override
    onlyOwner
    returns(address proxyAddress)
  {
    // Derive the create2 salt from the deployment requester's address
    // and the requester-supplied salt.
    bytes32 salt = Salty.deriveOneToOneSalt(_msgSender(), suppliedSalt);

    // Deploy the proxy
    proxyAddress = Create2.deploy(
      0,
      salt,
      type(DelegateCallProxyOneToOne).creationCode
    );

    // Set the implementation address on the new proxy.
    _setImplementation(proxyAddress, implementation);

    emit OneToOne_ProxyDeployed(proxyAddress, implementation);
  }

  /**
   * @dev Deploy a proxy with a many-to-one relationship with its implemenation.
   *
   * The proxy will call the implementation holder for every transaction to
   * determine the address to use in calls.
   *
   * @param implementationID Identifier for the proxy's implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deployProxyManyToOne(bytes32 implementationID, bytes32 suppliedSalt)
    external
    override
    onlyApprovedDeployer
    returns(address proxyAddress)
  {
    // Read the implementation holder address from storage.
    address implementationHolder = _implementationHolders[implementationID];

    // Verify that the implementation exists.
    require(implementationHolder != address(0), "ERR_IMPLEMENTATION_ID");

    // Derive the create2 salt from the deployment requester's address, the
    // implementation ID and the requester-supplied salt.
    bytes32 salt = Salty.deriveManyToOneSalt(
      _msgSender(),
      implementationID,
      suppliedSalt
    );

    // Set the implementation holder address in storage so the proxy
    // constructor can query it.
    _implementationHolder = implementationHolder;

    // Deploy the proxy, which will query the implementation holder address
    // and save it as an immutable in the contract bytecode.
    proxyAddress = Create2.deploy(
      0,
      salt,
      type(DelegateCallProxyManyToOne).creationCode
    );

    // Remove the address from temporary storage.
    _implementationHolder = address(0);

    emit ManyToOne_ProxyDeployed(
      implementationID,
      proxyAddress
    );
  }

/* ==========  Queries  ========== */

  /**
   * @dev Returns a boolean stating whether `implementationID` is locked.
   */
  function isImplementationLocked(bytes32 implementationID) external override view returns (bool) {
    // Read the implementation holder address from storage.
    address implementationHolder = _implementationHolders[implementationID];

    // Verify that the implementation exists.
    require(implementationHolder != address(0), "ERR_IMPLEMENTATION_ID");

    return _lockedImplementations[implementationHolder];
  }

  /**
   * @dev Returns a boolean stating whether `proxyAddress` is locked.
   */
  function isImplementationLocked(address proxyAddress) external override view returns (bool) {
    return _lockedImplementations[proxyAddress];
  }

  /**
   * @dev Returns a boolean stating whether `deployer` is allowed to deploy many-to-one
   * proxies.
   */
  function isApprovedDeployer(address deployer) external override view returns (bool) {
    return _approvedDeployers[deployer];
  }

  /**
   * @dev Queries the temporary storage value `_implementationHolder`.
   * This is used in the constructor of the many-to-one proxy contract
   * so that the create2 address is static (adding constructor arguments
   * would change the codehash) and the implementation holder can be
   * stored as a constant.
   */
  function getImplementationHolder()
    external
    override
    view
    returns (address)
  {
    return _implementationHolder;
  }

  /**
   * @dev Returns the address of the implementation holder contract
   * for `implementationID`.
   */
  function getImplementationHolder(
    bytes32 implementationID
  )
    external
    override
    view
    returns (address)
  {
    return _implementationHolders[implementationID];
  }

  /**
   * @dev Computes the create2 address for a one-to-one proxy requested
   * by `originator` using `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function computeProxyAddressOneToOne(
    address originator,
    bytes32 suppliedSalt
  )
    external
    override
    view
    returns (address)
  {
    bytes32 salt = Salty.deriveOneToOneSalt(originator, suppliedSalt);
    return Create2.computeAddress(salt, CodeHashes.ONE_TO_ONE_CODEHASH);
  }

  /**
   * @dev Computes the create2 address for a many-to-one proxy for the
   * implementation `implementationID` requested by `originator` using
   * `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
  */
  function computeProxyAddressManyToOne(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    external
    override
    view
    returns (address)
  {

    bytes32 salt = Salty.deriveManyToOneSalt(
      originator,
      implementationID,
      suppliedSalt
    );
    return Create2.computeAddress(salt, CodeHashes.MANY_TO_ONE_CODEHASH);
  }

  /**
   * @dev Computes the create2 address of the implementation holder
   * for `implementationID`.
   *
   * @param implementationID The identifier for the contract implementation.
  */
  function computeHolderAddressManyToOne(bytes32 implementationID)
    public
    override
    view
    returns (address)
  {
    return Create2.computeAddress(
      implementationID,
      CodeHashes.IMPLEMENTATION_HOLDER_CODEHASH
    );
  }

/* ==========  Internal Functions  ========== */

  /**
   * @dev Sets the implementation address for a one-to-one proxy or
   * many-to-one implementation holder. Both use the same access
   * control and update mechanism, which is the receipt of a call
   * from the proxy manager with the abi-encoded implementation address
   * as the only calldata.
   *
   * Note: Verifies that the implementation address is a contract.
   *
   * @param proxyOrHolder Address of the one-to-one proxy or
   * many-to-one implementation holder contract.
   * @param implementation Address of the contract with the runtime
   * code that the proxy or proxies should use.
   */
  function _setImplementation(
    address proxyOrHolder,
    address implementation
  ) internal {
    // Verify that the implementation address is a contract.
    require(Address.isContract(implementation), "ERR_NOT_CONTRACT");
    // Set the implementation address on the contract.

    // solium-disable-next-line security/no-low-level-calls
    (bool success,) = proxyOrHolder.call(abi.encode(implementation));
    require(success, "ERR_SET_ADDRESS_REVERT");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;


/**
 * @dev The ManyToOneImplementationHolder stores an upgradeable implementation address
 * in storage, which many-to-one proxies query at execution time to determine which
 * contract to delegate to.
 *
 * The manager can upgrade the implementation address by calling the holder with the
 * abi-encoded address as calldata. If any other account calls the implementation holder,
 * it will return the implementation address.
 *
 * This pattern was inspired by the DharmaUpgradeBeacon from 0age
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/upgradeability/smart-wallet/DharmaUpgradeBeacon.sol
 */
contract ManyToOneImplementationHolder {
/* ---  Storage  --- */
  address internal immutable _manager;
  address internal _implementation;

/* ---  Constructor  --- */
  constructor() public {
    _manager = msg.sender;
  }

  /**
   * @dev Fallback function for the contract.
   *
   * Used by proxies to read the implementation address and used
   * by the proxy manager to set the implementation address.
   *
   * If called by the owner, reads the implementation address from
   * calldata (must be abi-encoded) and stores it to the first slot.
   *
   * Otherwise, returns the stored implementation address.
   */
  fallback() external payable {
    if (msg.sender != _manager) {
      assembly {
        mstore(0, sload(0))
        return(0, 32)
      }
    }
    assembly { sstore(0, calldataload(0)) }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";


/**
 * @dev Proxy contract which uses an implementation address shared with many
 * other proxies.
 *
 * An implementation holder contract stores the upgradeable implementation address.
 * When the proxy is called, it queries the implementation address from the holder
 * contract and delegatecalls the returned address, forwarding the received calldata
 * and ether.
 *
 * Note: This contract does not verify that the implementation
 * address is a valid delegation target. The manager must perform
 * this safety check before updating the implementation on the holder.
 */
contract DelegateCallProxyManyToOne is Proxy {
/* ==========  Constants  ========== */

  // Address that stores the implementation address.
  address internal immutable _implementationHolder;

/* ==========  Constructor  ========== */

  constructor() public {
    // Calls the sender rather than receiving the address in the constructor
    // arguments so that the address is computable using create2.
    _implementationHolder = ProxyDeployer(msg.sender).getImplementationHolder();
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Queries the implementation address from the implementation holder.
   */
  function _implementation() internal override view returns (address) {
    // Queries the implementation address from the implementation holder.
    (bool success, bytes memory data) = _implementationHolder.staticcall("");
    require(success, string(data));
    address implementation = abi.decode((data), (address));
    require(implementation != address(0), "ERR_NULL_IMPLEMENTATION");
    return implementation;
  }
}

interface ProxyDeployer {
  function getImplementationHolder() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () payable external {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () payable external {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";


/**
 * @dev Upgradeable delegatecall proxy for a single contract.
 *
 * This proxy stores an implementation address which can be upgraded by the proxy manager.
 *
 * To upgrade the implementation, the manager calls the proxy with the abi encoded implementation address.
 *
 * If any other account calls the proxy, it will delegatecall the implementation address with the received
 * calldata and ether. If the call succeeds, it will return with the received returndata.
 * If it reverts, it will revert with the received revert data.
 *
 * Note: The storage slot for the implementation address is:
 * `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`
 * This slot must not be used by the implementation contract.
 *
 * Note: This contract does not verify that the implementation address is a valid delegation target.
 * The manager must perform this safety check.
 */
contract DelegateCallProxyOneToOne is Proxy {
/* ==========  Constants  ========== */
  address internal immutable _manager;

/* ==========  Constructor  ========== */
  constructor() public {
    _manager = msg.sender ;
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Reads the implementation address from storage.
   */
  function _implementation() internal override view returns (address) {
    address implementation;
    assembly {
      implementation := sload(
        // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
        0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a
      )
    }
    return implementation;
  }

  /**
    * @dev Hook that is called before falling back to the implementation.
    *
    * Checks if the call is from the owner.
    * If it is, reads the abi-encoded implementation address from calldata and stores
    * it at the slot `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`,
    * then returns with no data.
    * If it is not, continues execution with the fallback function.
    */
  function _beforeFallback() internal override {
    if (msg.sender != _manager) {
      super._beforeFallback();
    } else {
      assembly {
        sstore(
          // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
          0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a,
          calldataload(0)
        )
        return(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ---  External Libraries  --- */
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

/* ---  Proxy Contracts  --- */
import { CodeHashes } from "./CodeHashes.sol";


/**
 * @dev Library for computing create2 salts and addresses for proxies
 * deployed by `DelegateCallProxyManager`.
 *
 * Because the proxy factory is meant to be used by multiple contracts,
 * we use a salt derivation pattern that includes the address of the
 * contract that requested the proxy deployment, a salt provided by that
 * contract and the implementation ID used (for many-to-one proxies only).
 */
library SaltyLib {
/* ---  Salt Derivation  --- */

  /**
   * @dev Derives the create2 salt for a many-to-one proxy.
   *
   * Many different contracts in the Indexed framework may use the
   * same implementation contract, and they all use the same init
   * code, so we derive the actual create2 salt from a combination
   * of the implementation ID, the address of the account requesting
   * deployment and the user-supplied salt.
   *
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deriveManyToOneSalt(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        originator,
        implementationID,
        suppliedSalt
      )
    );
  }

  /**
   * @dev Derives the create2 salt for a one-to-one proxy.
   *
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deriveOneToOneSalt(
    address originator,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(originator, suppliedSalt));
  }

/* ---  Address Derivation  --- */

  /**
   * @dev Computes the create2 address for a one-to-one proxy deployed
   * by `deployer` (the factory) when requested by `originator` using
   * `suppliedSalt`.
   *
   * @param deployer Address of the proxy factory.
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function computeProxyAddressOneToOne(
    address deployer,
    address originator,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (address)
  {
    bytes32 salt = deriveOneToOneSalt(originator, suppliedSalt);
    return Create2.computeAddress(salt, CodeHashes.ONE_TO_ONE_CODEHASH, deployer);
  }

  /**
   * @dev Computes the create2 address for a many-to-one proxy for the
   * implementation `implementationID` deployed by `deployer` (the factory)
   * when requested by `originator` using `suppliedSalt`.
   *
   * @param deployer Address of the proxy factory.
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
  */
  function computeProxyAddressManyToOne(
    address deployer,
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (address)
  {
    bytes32 salt = deriveManyToOneSalt(
      originator,
      implementationID,
      suppliedSalt
    );
    return Create2.computeAddress(salt, CodeHashes.MANY_TO_ONE_CODEHASH, deployer);
  }

  /**
   * @dev Computes the create2 address of the implementation holder
   * for `implementationID`.
   *
   * @param deployer Address of the proxy factory.
   * @param implementationID The identifier for the contract implementation.
  */
  function computeHolderAddressManyToOne(
    address deployer,
    bytes32 implementationID
  )
    internal
    pure
    returns (address)
  {
    return Create2.computeAddress(
      implementationID,
      CodeHashes.IMPLEMENTATION_HOLDER_CODEHASH,
      deployer
    );
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


/**
 * @dev Contract that manages deployment and upgrades of delegatecall proxies.
 *
 * An implementation identifier can be created on the proxy manager which is
 * used to specify the logic address for a particular contract type, and to
 * upgrade the implementation as needed.
 *
 * A one-to-one proxy is a single proxy contract with an upgradeable implementation
 * address.
 *
 * A many-to-one proxy is a single upgradeable implementation address that may be
 * used by many proxy contracts.
 */
interface IDelegateCallProxyManager {
/* ==========  Events  ========== */

  event DeploymentApprovalGranted(address deployer);
  event DeploymentApprovalRevoked(address deployer);

  event ManyToOne_ImplementationCreated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ImplementationUpdated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ProxyDeployed(
    bytes32 implementationID,
    address proxyAddress
  );

  event OneToOne_ProxyDeployed(
    address proxyAddress,
    address implementationAddress
  );

  event OneToOne_ImplementationUpdated(
    address proxyAddress,
    address implementationAddress
  );

/* ==========  Controls  ========== */

  /**
   * @dev Allows `deployer` to deploy many-to-one proxies.
   */
  function approveDeployer(address deployer) external;

  /**
   * @dev Prevents `deployer` from deploying many-to-one proxies.
   */
  function revokeDeployerApproval(address deployer) external;

/* ==========  Implementation Management  ========== */

  /**
   * @dev Creates a many-to-one proxy relationship.
   *
   * Deploys an implementation holder contract which stores the
   * implementation address for many proxies. The implementation
   * address can be updated on the holder to change the runtime
   * code used by all its proxies.
   *
   * @param implementationID ID for the implementation, used to identify the
   * proxies that use it. Also used as the salt in the create2 call when
   * deploying the implementation holder contract.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  ) external;

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationManyToOne(bytes32 implementationID) external;

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationOneToOne(address proxyAddress) external;

  /**
   * @dev Updates the implementation address for a many-to-one
   * proxy relationship.
   *
   * @param implementationID Identifier for the implementation.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external;

  /**
   * @dev Updates the implementation address for a one-to-one proxy.
   *
   * Note: This could work for many-to-one as well if the caller
   * provides the implementation holder address in place of the
   * proxy address, as they use the same access control and update
   * mechanism.
   *
   * @param proxyAddress Address of the deployed proxy
   * @param implementation Address with the runtime code for
   * the proxy to use.
   */
  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  ) external;

/* ==========  Proxy Deployment  ========== */

  /**
   * @dev Deploy a proxy contract with a one-to-one relationship
   * with its implementation.
   *
   * The proxy will have its own implementation address which can
   * be updated by the proxy manager.
   *
   * @param suppliedSalt Salt provided by the account requesting deployment.
   * @param implementation Address of the contract with the runtime
   * code that the proxy should use.
   */
  function deployProxyOneToOne(
    bytes32 suppliedSalt,
    address implementation
  ) external returns(address proxyAddress);

  /**
   * @dev Deploy a proxy with a many-to-one relationship with its implemenation.
   *
   * The proxy will call the implementation holder for every transaction to
   * determine the address to use in calls.
   *
   * @param implementationID Identifier for the proxy's implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external returns(address proxyAddress);

/* ==========  Queries  ========== */

  /**
   * @dev Returns a boolean stating whether `implementationID` is locked.
   */
  function isImplementationLocked(bytes32 implementationID) external view returns (bool);

  /**
   * @dev Returns a boolean stating whether `proxyAddress` is locked.
   */
  function isImplementationLocked(address proxyAddress) external view returns (bool);

  /**
   * @dev Returns a boolean stating whether `deployer` is allowed to deploy many-to-one
   * proxies.
   */
  function isApprovedDeployer(address deployer) external view returns (bool);

  /**
   * @dev Queries the temporary storage value `_implementationHolder`.
   * This is used in the constructor of the many-to-one proxy contract
   * so that the create2 address is static (adding constructor arguments
   * would change the codehash) and the implementation holder can be
   * stored as a constant.
   */
  function getImplementationHolder() external view returns (address);

  /**
   * @dev Returns the address of the implementation holder contract
   * for `implementationID`.
   */
  function getImplementationHolder(bytes32 implementationID) external view returns (address);

  /**
   * @dev Computes the create2 address for a one-to-one proxy requested
   * by `originator` using `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function computeProxyAddressOneToOne(
    address originator,
    bytes32 suppliedSalt
  ) external view returns (address);

  /**
   * @dev Computes the create2 address for a many-to-one proxy for the
   * implementation `implementationID` requested by `originator` using
   * `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
  */
  function computeProxyAddressManyToOne(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external view returns (address);

  /**
   * @dev Computes the create2 address of the implementation holder
   * for `implementationID`.
   *
   * @param implementationID The identifier for the contract implementation.
  */
  function computeHolderAddressManyToOne(bytes32 implementationID) external view returns (address);
}