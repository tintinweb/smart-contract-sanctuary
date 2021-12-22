pragma solidity >=0.8.4;

import "./VRFConsumerBaseUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NFZGameMechanics is
    Initializable,
    VRFConsumerBase,
    OwnableUpgradeable
{
    event ELocationSet(uint256[] tokenIds, uint256 location, address from);

    event EPrizes(
        uint256[] userPrizes,
        address from,
        uint256 location,
        uint256 randomNumber,
        uint256 baseChance
    );

    struct LocationPrizes {
        uint256 _locationId;
        uint256[] specialRewards;
        uint256[] prizes;
    }
    struct Location {
        uint256 _id;
        string Location_name;
        uint256 MAX_CAPACITY;
        uint256 CURRENT_CAPACITY;
        uint256[] CURRENT_INHABITANTS;
    }

    bytes32 internal keyHash;
    uint256 internal fee;
    address gameAdmin;
   
    mapping(uint256 => Location) public Locations;

    mapping(uint256 => LocationPrizes) public LocationRewards;
    mapping(uint256 => uint256) public tokenIdToLocations;
    mapping(bytes32 => address) private requestIdToSender;
    mapping(bytes32 => uint256) private requestIdtoLocationId;
    mapping(address => uint256[]) public userRewards;
    

    uint256 hordeRollmodifer;
    uint256 baseChance;
    uint256 specialRewardBasechance;

    function init() public initializer {
        __Ownable_init();
        VRFConsumerBase.initialize(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0,
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1
        );
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10**18;

        baseChance = 10;
        specialRewardBasechance = 2;
    }

    function rollForRewards(
        uint256 _locationid,
        address account,
        uint256[] memory _tokenIds
    ) internal {
        //get base chance probability
        baseChance = prizeProbability(_tokenIds, _locationid);
        bytes32 requestId = getRandomNumber();
        requestIdToSender[requestId] = account;
        requestIdtoLocationId[requestId] = _locationid;
    }

    function getRandomNumber() internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );

        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 _locationId = requestIdtoLocationId[requestId];
        uint256[] storage locationPrizes = LocationRewards[_locationId].prizes;
        uint256[] storage locationSpecialPrizes = LocationRewards[_locationId]
            .specialRewards;
        address user = requestIdToSender[requestId];
        uint256[] memory a = new uint256[](2);

        uint256 prizeRoll;
        uint256 specialPrizeRoll;
        //Location PRIZES
        if (locationPrizes.length > 0) {
            prizeRoll = (randomness % 100) + 1;
            if (prizeRoll >= baseChance && locationPrizes.length > 0) {
                uint256 reward = locationPrizes[locationPrizes.length - 1];
                userRewards[user].push(reward);
                a[0] = reward;
                locationPrizes.pop();
            }
        }

        //CHECK TO SEE IF THERE ARE ANY SPECIAL REWARDS
        if (locationSpecialPrizes.length > 0) {
            specialPrizeRoll = (randomness % 1000) + 1;
            if (specialPrizeRoll < specialRewardBasechance) {
                uint256 reward = locationSpecialPrizes[
                    locationSpecialPrizes.length - 1
                ];
                userRewards[user].push(reward);
                locationSpecialPrizes.pop();
                a[1] = reward;
            }
        }

        emit EPrizes(a, user, _locationId, prizeRoll, baseChance);
    }

    function prizeProbability(uint256[] memory _tokenIds, uint256 _locationId)
        internal
        pure
        returns (uint256 probability)
    {
        uint256 genesisModifer = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_tokenIds[i] <= 2000) {
                genesisModifer = 1;
            }
        }
        uint256 zombiesSent = _tokenIds.length + genesisModifer;
        if (_locationId == 1) {
            if (zombiesSent == 1) {
                return 100 - 10;
            } else if (zombiesSent == 2) {
                return 100 - 25;
            } else if (zombiesSent == 3) {
                return 100 - 35;
            } else if (zombiesSent == 4) {
                return 100 - 50;
            } else if (zombiesSent == 5) {
                return 100 - 70;
            } else if (zombiesSent >= 6) {
                return 0;
            }
        } else if (_locationId == 2) {
            if (zombiesSent == 1) {
                return 100 - 20;
            } else if (zombiesSent == 2) {
                return 100 - 30;
            } else if (zombiesSent == 3) {
                return 100 - 40;
            } else if (zombiesSent == 4) {
                return 100 - 50;
            } else if (zombiesSent == 5) {
                return 100 - 75;
            } else if (zombiesSent >= 6) {
                return 0;
            }
        } else {
            return 100;
        }
    }

    function returnStruct(uint256 _locationId)
        public
        view
        returns (Location memory)
    {
        return Locations[_locationId];
    }

    function getUserRewards(address account)
        public
        view
        returns (uint256[] memory rewards)
    {
        uint256[] memory prizes = userRewards[account];
        return prizes;
    }

    function _setLocation(
        uint256[] memory _tokenIds,
        uint256 _locationId,
        address account
    ) external onlyGameAdmin {
        require(
            Locations[_locationId].CURRENT_CAPACITY + _tokenIds.length <=
                Locations[_locationId].MAX_CAPACITY,
            "Location is Full"
        );
        Location storage newLocation = Locations[_locationId];
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _id = _tokenIds[i];
            uint256 _currentLocation = tokenIdToLocations[_id];
            //Check to see if _tokenId is already part of a location
            if (_currentLocation > 0) {
                Location storage currentLocation = Locations[_currentLocation];
                if (currentLocation.CURRENT_CAPACITY > 0) {
                    currentLocation.CURRENT_CAPACITY--;
                }

                uint256 tokenIndex = indexOf(_id, _currentLocation);
                if (tokenIndex != 9999) {
                    currentLocation.CURRENT_INHABITANTS[
                        tokenIndex
                    ] = currentLocation.CURRENT_INHABITANTS[
                        currentLocation.CURRENT_INHABITANTS.length - 1
                    ];
                    currentLocation.CURRENT_INHABITANTS.pop();
                }
            }

            newLocation.CURRENT_CAPACITY++;
            newLocation.CURRENT_INHABITANTS.push(_id);
            tokenIdToLocations[_id] = _locationId;
        }

        emit ELocationSet(_tokenIds, _locationId, account);
        //Check to make sure thert eare still prizes as location
        uint256[] memory prizes = LocationRewards[_locationId].prizes;
        uint256[] memory specialRewards = LocationRewards[_locationId]
            .specialRewards;
        if (prizes.length > 0 || specialRewards.length > 0) {
            return rollForRewards(_locationId, account, _tokenIds);
        } else {
            uint256[] memory a = new uint256[](2);
            a[0] = 9999;
            a[1] = 0;
            emit EPrizes(a, account, _locationId, 0, 0);
        }
    }

    function removeLocationIdMapping(uint256 _id) external onlyOwner {
        tokenIdToLocations[_id] = 0;
    }

    function addLocation(
        uint256 _id,
        string memory name,
        uint256 _maxCapacity,
        uint256[] memory prizes,
        uint256[] memory specialRerwards
    ) public onlyOwner {
        Location storage loc = Locations[_id];
        loc._id = _id;
        loc.Location_name = name;
        loc.MAX_CAPACITY = _maxCapacity;
        loc.CURRENT_CAPACITY = 0;
        delete loc.CURRENT_INHABITANTS;
        LocationPrizes storage locPrizes = LocationRewards[_id];
        locPrizes._locationId = _id;
        locPrizes.prizes = prizes;
        locPrizes.specialRewards = specialRerwards;

        // for (uint256 i = 0; i < prizes.length; i++) {
        //     locPrizes.prizes.push(prizes[i]);
        // }
        // for (uint256 i = 0; i < prizeIds.length; i++) {
        //     locPrizes.amounts[i + 1] = amounts[i];
        // }
    }

    function getLocationPrizeArray(uint256 _locationId)
        public
        view
        returns (uint256[] memory prizes, uint256[] memory special)
    {
        uint256[] memory locationPrizes = LocationRewards[_locationId].prizes;
        uint256[] memory specialPrizes = LocationRewards[_locationId]
            .specialRewards;

        return (locationPrizes, specialPrizes);
    }

    function addPrizes(
        uint256 _locationId,
        uint256[] memory _prizes,
        uint256[] memory _specialPrizes
    ) external onlyOwner {
        LocationPrizes storage locPrizes = LocationRewards[_locationId];

        for (uint256 i = 0; i < _prizes.length; i++) {
            locPrizes.prizes.push(_prizes[i]);
        }

        for (uint256 i = 0; i < _specialPrizes.length; i++) {
            locPrizes.specialRewards.push(_specialPrizes[i]);
        }
    }

    function setGameAdmin(address _address) external onlyOwner {
        gameAdmin = _address;
    }

    modifier onlyGameAdmin() {
        require(msg.sender == gameAdmin, "Not a Game Admin");
        _;
    }

    function indexOf(uint256 _tokenId, uint256 _locationId)
        internal
        view
        returns (uint256 index)
    {
        uint256[] memory locationDwellers = Locations[_locationId]
            .CURRENT_INHABITANTS;
        for (uint256 i = 0; i < locationDwellers.length; i++) {
            if (_tokenId == locationDwellers[i]) return i;
        }
        return 9999;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

import "@chainlink/contracts/src/v0.8/VRFRequestIDBase.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract VRFConsumerBase is Initializable, VRFRequestIDBase {
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual;

    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    function requestRandomness(bytes32 _keyHash, uint256 _fee)
        internal
        returns (bytes32 requestId)
    {
        LINK.transferAndCall(
            vrfCoordinator,
            _fee,
            abi.encode(_keyHash, USER_SEED_PLACEHOLDER)
        );

        uint256 vRFSeed = makeVRFInputSeed(
            _keyHash,
            USER_SEED_PLACEHOLDER,
            address(this),
            nonces[_keyHash]
        );

        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface /*immutable*/
        internal LINK;
    address /*immutable*/
        private vrfCoordinator;

    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    function initialize(address _vrfCoordinator, address _link)
        public
        initializer
    {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
        external
    {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}