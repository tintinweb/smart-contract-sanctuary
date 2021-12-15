// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../utilities/AdminUpgradeable.sol";
import "./IIndexer.sol";
import "../staking/IStaking.sol";
import "../utilities/AddressCache.sol";
import "../utilities/Constants.sol";

/**
 * @title Indexer contract
 * @dev This contract supports the service discovery process by allowing indexers to
 * register their service url and any other relevant information.
 */
contract Indexer is AdminUpgradeable, AddressCache, IIndexer, Constants {
    mapping(address => IIndexer.IndexerService) public services;

    IStaking staking;

    // -- Events --
    event IndexerRegistered(address indexed indexer, string url, string geo, uint256 price, uint256 feeSplitRatio);
    event IndexerUnregistered(address indexed indexer);

    /**
     * @dev Initialize this contract.
     */
    function initialize(address admin) public initializer {
        AdminUpgradeable.__AdminUpgradeable_init(admin);
    }

    function updateAddressCache(IAddressStorage _addressStorage) public override onlyAdmin {
        staking = IStaking(_addressStorage.getAddressWithRequire(STAKING_KEY, ""));
        emit CachedAddressUpdated(STAKING_KEY, address(staking));
    }

    function register(
        string calldata _url,
        string calldata _geo,
        uint256 _price,
        uint256 _feeSplitRatio
    ) external override {
        require(bytes(_url).length > 0, "Indexer: Service must specify a URL");
        services[msg.sender] = IndexerService(_url, _geo, _price, _feeSplitRatio);
        emit IndexerRegistered(msg.sender, _url, _geo, _price, _feeSplitRatio);
    }

    function unregister() external override {
        require(isRegistered(msg.sender), "Indexer: Service already unregistered");
        delete services[msg.sender];
        emit IndexerUnregistered(msg.sender);
    }

    function isRegistered(address _indexer) public view override returns (bool) {
        return bytes(services[_indexer].url).length > 0;
    }

    function getFeePrice(address _indexer) external override returns (uint256) {
        return services[_indexer].price;
    }

    function getFeeSplitRatio(address _indexer) external override returns (uint256) {
        return services[_indexer].feeSplitRatio;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title AdminUpgradeable
 *
 * @dev This is an upgradeable version of `Admin` by replacing the constructor with
 * an initializer and reserving storage slots.
 */
contract AdminUpgradeable is Initializable {
    event CandidateChanged(address oldCandidate, address newCandidate);
    event AdminChanged(address oldAdmin, address newAdmin);

    address public admin;
    address public candidate;

    function __AdminUpgradeable_init(address _admin) public virtual initializer {
        require(_admin != address(0), "AdminUpgradeable: zero address");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    function setCandidate(address _candidate) external onlyAdmin {
        address old = candidate;
        candidate = _candidate;
        emit CandidateChanged(old, candidate);
    }

    function becomeAdmin() external {
        require(msg.sender == candidate, "AdminUpgradeable: only candidate can become admin");
        address old = admin;
        admin = candidate;
        emit AdminChanged(old, admin);
    }

    modifier onlyAdmin {
        require((msg.sender == admin), "AdminUpgradeable: only the contract admin can perform this action");
        _;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[48] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.6.12;

interface IIndexer {
    struct IndexerService {
        string url;
        string geo;
        uint256 price;
        uint256 feeSplitRatio;
    }

    /**
     * @dev Register an indexer service, you should register first and stake later
     * @param _url URL of the indexer service
     * @param _geo geo of the indexer service location
     * @param _price fee price
     */
    function register(
        string calldata _url,
        string calldata _geo,
        uint256 _price,
        uint256 _feeSplitRatio
    ) external;

    /**
     * @dev Unregister an indexer service
     */
    function unregister() external;

    /**
     * @dev Return the registration status of an indexer service
     * @return True if the indexer service is registered
     */
    function isRegistered(address _indexer) external view returns (bool);

    /**
     * @dev get fee price, how much per seconds
     * @param _indexer Address of the indexer
     * @return fee price
     */
    function getFeePrice(address _indexer) external returns (uint256);

    /**
     * @dev get fee split ratio of Indexer
     * @param _indexer Address of the indexer
     * @return fee split ratio
     */
    function getFeeSplitRatio(address _indexer) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

interface IStaking {
    /// Stake tokens
    /// @dev stake to msg.sender
    /// @param _tokens token amount
    function stake(uint256 _tokens) external;

    /// Unstake tokens
    /// @param _tokens token amount
    function unStake(uint256 _tokens) external;

    /// Punish Indexer for misbehavior. Rewards will also be given to the dispute raiser.
    /// @param _indexer _indexer address
    /// @param _tokens punish amount
    /// @param _reward reward amount
    /// @param _reward reward amount
    /// @param _reward beneficiary address
    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external;

    /// check if a indexer, stake first and become an indexer
    /// @param _indexer an address
    /// @return if an indexer return true
    function hasStaked(address _indexer) external view returns (bool);

    /**
     * @dev Get the total amount of tokens staked by the indexer.
     * @param _indexer Address of the indexer
     * @return Amount of tokens staked by the indexer
     */
    function getIndexerStakedTokens(address _indexer) external view returns (uint256);

    /// forbid stake
    /// @param paused set paused true or false
    function setStakePaused(bool paused) external;

    /// forbid unStake
    /// @param paused set paused true or false
    function setUnStakePaused(bool paused) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces/IAddressStorage.sol";

abstract contract AddressCache {
    function updateAddressCache(IAddressStorage _addressStorage) external virtual;
    event CachedAddressUpdated(string name, address addr);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Constants {
    //Address Cache
    string public constant CONFIG_KEY = "CONFIG_KEY";
    string public constant RELATION_TOKEN_KEY = "RELATION_TOKEN_KEY";
    string public constant STAKING_KEY = "STAKING_KEY";
    string public constant DELEGATING_KEY = "DELEGATING_KEY";
    string public constant INDEXER_KEY = "INDEXER_KEY";
    string public constant ACCESS_CONTROL_KEY = "ACCESS_CONTROL";

    //Config Unit
    string public constant INDEXER_INTEREST_RATE_KEY = "INDEXER_INTEREST_RATE_KEY";
    string public constant DELEGATOR_INTEREST_RATE_KEY = "DELEGATOR_INTEREST_RATE_KEY";
    string public constant SLASHING_PERCENTAGE_KEY = "SLASHING_PERCENTAGE_KEY";
    string public constant FISHERMAN_REWARD_PERCENTAGE_KEY = "FISHERMAN_REWARD_PERCENTAGE_KEY";
    string public constant MINIMUM_FISHMEN_DEPOSIT_KEY = "MINIMUM_FISHMEN_DEPOSIT_KEY";

    constructor() public {}
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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IAddressStorage {
    function updateAll(string[] calldata names, address[] calldata destinations) external;

    function update(string calldata name, address dest) external;

    function getAddress(string calldata name) external view returns (address);

    function getAddressWithRequire(string calldata name, string calldata reason) external view returns (address);
}