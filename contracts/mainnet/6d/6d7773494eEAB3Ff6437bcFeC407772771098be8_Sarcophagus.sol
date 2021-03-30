/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

/**

   ▄▄▄▄▄   ██   █▄▄▄▄ ▄█▄    ████▄ █ ▄▄   ▄  █ ██     ▄▀    ▄      ▄▄▄▄▄   
  █     ▀▄ █ █  █  ▄▀ █▀ ▀▄  █   █ █   █ █   █ █ █  ▄▀       █    █     ▀▄ 
▄  ▀▀▀▀▄   █▄▄█ █▀▀▌  █   ▀  █   █ █▀▀▀  ██▀▀█ █▄▄█ █ ▀▄  █   █ ▄  ▀▀▀▀▄   
 ▀▄▄▄▄▀    █  █ █  █  █▄  ▄▀ ▀████ █     █   █ █  █ █   █ █   █  ▀▄▄▄▄▀    
              █   █   ▀███▀         █       █     █  ███  █▄ ▄█            
             █   ▀                   ▀     ▀     █         ▀▀▀             
            ▀                                   ▀                          

 */

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/libraries/Events.sol

pragma solidity ^0.8.0;

/**
 * @title A collection of Events
 * @notice This library defines all of the Events that the Sarcophagus system
 * emits
 */
library Events {
    event Creation(address sarcophagusContract);

    event RegisterArchaeologist(
        address indexed archaeologist,
        bytes currentPublicKey,
        string endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 bond
    );

    event UpdateArchaeologist(
        address indexed archaeologist,
        string endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 addedBond
    );

    event UpdateArchaeologistPublicKey(
        address indexed archaeologist,
        bytes currentPublicKey
    );

    event WithdrawalFreeBond(
        address indexed archaeologist,
        uint256 withdrawnBond
    );

    event CreateSarcophagus(
        bytes32 indexed identifier,
        address indexed archaeologist,
        bytes archaeologistPublicKey,
        address embalmer,
        string name,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes recipientPublicKey,
        uint256 cursedBond
    );

    event UpdateSarcophagus(bytes32 indexed identifier, string assetId);

    event CancelSarcophagus(bytes32 indexed identifier);

    event RewrapSarcophagus(
        string assetId,
        bytes32 indexed identifier,
        uint256 resurrectionTime,
        uint256 resurrectionWindow,
        uint256 diggingFee,
        uint256 bounty,
        uint256 cursedBond
    );

    event UnwrapSarcophagus(
        string assetId,
        bytes32 indexed identifier,
        bytes32 privatekey
    );

    event AccuseArchaeologist(
        bytes32 indexed identifier,
        address indexed accuser,
        uint256 accuserBondReward,
        uint256 embalmerBondReward
    );

    event BurySarcophagus(bytes32 indexed identifier);

    event CleanUpSarcophagus(
        bytes32 indexed identifier,
        address indexed cleaner,
        uint256 cleanerBondReward,
        uint256 embalmerBondReward
    );
}

// File: contracts/libraries/Types.sol

pragma solidity ^0.8.0;

/**
 * @title A collection of defined structs
 * @notice This library defines the various data models that the Sarcophagus
 * system uses
 */
library Types {
    struct Archaeologist {
        bool exists;
        bytes currentPublicKey;
        string endpoint;
        address paymentAddress;
        uint256 feePerByte;
        uint256 minimumBounty;
        uint256 minimumDiggingFee;
        uint256 maximumResurrectionTime;
        uint256 freeBond;
        uint256 cursedBond;
    }

    enum SarcophagusStates {DoesNotExist, Exists, Done}

    struct Sarcophagus {
        SarcophagusStates state;
        address archaeologist;
        bytes archaeologistPublicKey;
        address embalmer;
        string name;
        uint256 resurrectionTime;
        uint256 resurrectionWindow;
        string assetId;
        bytes recipientPublicKey;
        uint256 storageFee;
        uint256 diggingFee;
        uint256 bounty;
        uint256 currentCursedBond;
        bytes32 privateKey;
    }
}

// File: contracts/libraries/Datas.sol

pragma solidity ^0.8.0;


/**
 * @title A library implementing data structures for the Sarcophagus system
 * @notice This library defines a Data struct, which defines all of the state
 * that the Sarcophagus system needs to operate. It's expected that a single
 * instance of this state will exist.
 */
library Datas {
    struct Data {
        // archaeologists
        address[] archaeologistAddresses;
        mapping(address => Types.Archaeologist) archaeologists;
        // archaeologist stats
        mapping(address => bytes32[]) archaeologistSuccesses;
        mapping(address => bytes32[]) archaeologistCancels;
        mapping(address => bytes32[]) archaeologistAccusals;
        mapping(address => bytes32[]) archaeologistCleanups;
        // archaeologist key control
        mapping(bytes => bool) archaeologistUsedKeys;
        // sarcophaguses
        bytes32[] sarcophagusIdentifiers;
        mapping(bytes32 => Types.Sarcophagus) sarcophaguses;
        // sarcophagus ownerships
        mapping(address => bytes32[]) embalmerSarcophaguses;
        mapping(address => bytes32[]) archaeologistSarcophaguses;
        mapping(address => bytes32[]) recipientSarcophaguses;
    }
}

// File: contracts/libraries/Utils.sol

pragma solidity ^0.8.0;

/**
 * @title Utility functions used within the Sarcophagus system
 * @notice This library implements various functions that are used throughout
 * Sarcophagus, mainly to DRY up the codebase
 * @dev these functions are all stateless, public, pure/view
 */
library Utils {
    /**
     * @notice Reverts if the public key length is not exactly 64 bytes long
     * @param publicKey the key to check length of
     */
    function publicKeyLength(bytes memory publicKey) public pure {
        require(publicKey.length == 64, "public key must be 64 bytes");
    }

    /**
     * @notice Reverts if the hash of singleHash does not equal doubleHash
     * @param doubleHash the hash to compare hash of singleHash to
     * @param singleHash the value to hash and compare against doubleHash
     */
    function hashCheck(bytes32 doubleHash, bytes memory singleHash)
        public
        pure
    {
        require(doubleHash == keccak256(singleHash), "hashes do not match");
    }

    /**
     * @notice Reverts if the input string is not empty
     * @param assetId the string to check
     */
    function confirmAssetIdNotSet(string memory assetId) public pure {
        require(bytes(assetId).length == 0, "assetId has already been set");
    }

    /**
     * @notice Reverts if existing assetId is not empty, or if new assetId is
     * @param existingAssetId the orignal assetId to check, make sure is empty
     * @param newAssetId the new assetId, which must not be empty
     */
    function assetIdsCheck(
        string memory existingAssetId,
        string memory newAssetId
    ) public pure {
        // verify that the existingAssetId is currently empty
        confirmAssetIdNotSet(existingAssetId);

        require(bytes(newAssetId).length > 0, "assetId must not have 0 length");
    }

    /**
     * @notice Reverts if the given data and signature did not come from the
     * given address
     * @param data the payload which has been signed
     * @param v signature element
     * @param r signature element
     * @param s signature element
     * @param account address to confirm data and signature came from
     */
    function signatureCheck(
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address account
    ) public pure {
        // generate the address for a given data and signature
        address hopefulAddress = ecrecover(keccak256(data), v, r, s);

        require(
            hopefulAddress == account,
            "signature did not come from correct account"
        );
    }

    /**
     * @notice Reverts if the given resurrection time is not in the future
     * @param resurrectionTime the time to check against block.timestamp
     */
    function resurrectionInFuture(uint256 resurrectionTime) public view {
        require(
            resurrectionTime > block.timestamp,
            "resurrection time must be in the future"
        );
    }

    /**
     * @notice Calculates the grace period that an archaeologist has after a
     * sarcophagus has reached its resurrection time
     * @param resurrectionTime the resurrection timestamp of a sarcophagus
     * @return the grace period
     * @dev The grace period is dependent on how far out the resurrection time
     * is. The longer out the resurrection time, the longer the grace period.
     * There is a minimum grace period of 30 minutes, otherwise, it's
     * calculated as 1% of the time between now and resurrection time.
     */
    function getGracePeriod(uint256 resurrectionTime)
        public
        view
        returns (uint256)
    {
        // set a minimum window of 30 minutes
        uint16 minimumResurrectionWindow = 30 minutes;

        // calculate 1% of the relative time between now and the resurrection
        // time
        uint256 gracePeriod = (resurrectionTime - block.timestamp) / 100;

        // if our calculated grace period is less than the minimum time, we'll
        // use the minimum time instead
        if (gracePeriod < minimumResurrectionWindow) {
            gracePeriod = minimumResurrectionWindow;
        }

        // return that grace period
        return gracePeriod;
    }

    /**
     * @notice Reverts if we're not within the resurrection window (on either
     * side)
     * @param resurrectionTime the resurrection time of the sarcophagus
     * (absolute, i.e. a date time stamp)
     * @param resurrectionWindow the resurrection window of the sarcophagus
     * (relative, i.e. "30 minutes")
     */
    function unwrapTime(uint256 resurrectionTime, uint256 resurrectionWindow)
        public
        view
    {
        // revert if too early
        require(
            resurrectionTime <= block.timestamp,
            "it's not time to unwrap the sarcophagus"
        );

        // revert if too late
        require(
            resurrectionTime + resurrectionWindow >= block.timestamp,
            "the resurrection window has expired"
        );
    }

    /**
     * @notice Reverts if msg.sender is not equal to passed-in address
     * @param account the account to verify is msg.sender
     */
    function sarcophagusUpdater(address account) public view {
        require(
            account == msg.sender,
            "sarcophagus cannot be updated by account"
        );
    }

    /**
     * @notice Reverts if the input resurrection time, digging fee, or bounty
     * don't fit within the other given maximum and minimum values
     * @param resurrectionTime the resurrection time to check
     * @param diggingFee the digging fee to check
     * @param bounty the bounty to check
     * @param maximumResurrectionTime the maximum resurrection time to check
     * against, in relative terms (i.e. "1 year" is 31536000 (seconds))
     * @param minimumDiggingFee the minimum digging fee to check against
     * @param minimumBounty the minimum bounty to check against
     */
    function withinArchaeologistLimits(
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty,
        uint256 maximumResurrectionTime,
        uint256 minimumDiggingFee,
        uint256 minimumBounty
    ) public view {
        // revert if the given resurrection time is too far in the future
        require(
            resurrectionTime <= block.timestamp + maximumResurrectionTime,
            "resurrection time too far in the future"
        );

        // revert if the given digging fee is too low
        require(diggingFee >= minimumDiggingFee, "digging fee is too low");

        // revert if the given bounty is too low
        require(bounty >= minimumBounty, "bounty is too low");
    }
}

// File: contracts/libraries/Archaeologists.sol

pragma solidity ^0.8.0;






/**
 * @title A library implementing Archaeologist-specific logic in the
 * Sarcophagus system
 * @notice This library includes public functions for manipulating
 * archaeologists in the Sarcophagus system
 */
library Archaeologists {
    /**
     * @notice Checks that an archaeologist exists, or doesn't exist, and
     * and reverts if necessary
     * @param data the system's data struct instance
     * @param account the archaeologist address to check existence of
     * @param exists bool which flips whether function reverts if archaeologist
     * exists or not
     */
    function archaeologistExists(
        Datas.Data storage data,
        address account,
        bool exists
    ) public view {
        // set the error message
        string memory err = "archaeologist has not been registered yet";
        if (!exists) err = "archaeologist has already been registered";

        // revert if necessary
        require(data.archaeologists[account].exists == exists, err);
    }

    /**
     * @notice Increases internal data structure which tracks free bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to increase free bond by
     */
    function increaseFreeBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // increase the freeBond variable by amount
        arch.freeBond = arch.freeBond + amount;
    }

    /**
     * @notice Decreases internal data structure which tracks free bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to decrease free bond by
     */
    function decreaseFreeBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // decrease the free bond variable by amount, reverting if necessary
        require(
            arch.freeBond >= amount,
            "archaeologist does not have enough free bond"
        );
        arch.freeBond = arch.freeBond - amount;
    }

    /**
     * @notice Increases internal data structure which tracks cursed bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to increase cursed bond by
     */
    function increaseCursedBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) private {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // increase the freeBond variable by amount
        arch.cursedBond = arch.cursedBond + amount;
    }

    /**
     * @notice Decreases internal data structure which tracks cursed bond per
     * archaeologist
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to decrease cursed bond by
     */
    function decreaseCursedBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[archAddress];

        // decrease the free bond variable by amount
        arch.cursedBond = arch.cursedBond - amount;
    }

    /**
     * @notice Given an archaeologist and amount, decrease free bond and
     * increase cursed bond
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to decrease free bond and increase cursed bond
     */
    function lockUpBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        decreaseFreeBond(data, archAddress, amount);
        increaseCursedBond(data, archAddress, amount);
    }

    /**
     * @notice Given an archaeologist and amount, increase free bond and
     * decrease cursed bond
     * @param data the system's data struct instance
     * @param archAddress the archaeologist's address to operate on
     * @param amount the amount to increase free bond and decrease cursed bond
     */
    function freeUpBond(
        Datas.Data storage data,
        address archAddress,
        uint256 amount
    ) public {
        increaseFreeBond(data, archAddress, amount);
        decreaseCursedBond(data, archAddress, amount);
    }

    /**
     * @notice Calculates and returns the curse for any sarcophagus
     * @param diggingFee the digging fee of a sarcophagus
     * @param bounty the bounty of a sarcophagus
     * @return amount of the curse
     * @dev Current implementation simply adds the two inputs together. Future
     * strategies should use historical data to build a curve to change this
     * amount over time.
     */
    function getCursedBond(uint256 diggingFee, uint256 bounty)
        public
        pure
        returns (uint256)
    {
        // TODO: implment a better algorithm, using some concept of past state
        return diggingFee + bounty;
    }

    /**
     * @notice Registers a new archaeologist in the system
     * @param data the system's data struct instance
     * @param currentPublicKey the public key to be used in the first
     * sarcophagus
     * @param endpoint where to contact this archaeologist on the internet
     * @param paymentAddress all collected payments for the archaeologist will
     * be sent here
     * @param feePerByte amount of SARCO tokens charged per byte of storage
     * being sent to Arweave
     * @param minimumBounty the minimum bounty for a sarcophagus that the
     * archaeologist will accept
     * @param minimumDiggingFee the minimum digging fee for a sarcophagus that
     * the archaeologist will accept
     * @param maximumResurrectionTime the maximum resurrection time for a
     * sarcophagus that the archaeologist will accept, in relative terms (i.e.
     * "1 year" is 31536000 (seconds))
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to start with
     * @param sarcoToken the SARCO token used for payment handling
     * @return index of the new archaeologist
     */
    function registerArchaeologist(
        Datas.Data storage data,
        bytes memory currentPublicKey,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond,
        IERC20 sarcoToken
    ) public returns (uint256) {
        // verify that the archaeologist does not already exist
        archaeologistExists(data, msg.sender, false);

        // verify that the public key length is accurate
        Utils.publicKeyLength(currentPublicKey);

        // transfer SARCO tokens from the archaeologist to this contract, to be
        // used as their free bond. can be 0, which indicates that the
        // archaeologist is not eligible for any new jobs
        if (freeBond > 0) {
            sarcoToken.transferFrom(msg.sender, address(this), freeBond);
        }

        // create a new archaeologist
        Types.Archaeologist memory newArch =
            Types.Archaeologist({
                exists: true,
                currentPublicKey: currentPublicKey,
                endpoint: endpoint,
                paymentAddress: paymentAddress,
                feePerByte: feePerByte,
                minimumBounty: minimumBounty,
                minimumDiggingFee: minimumDiggingFee,
                maximumResurrectionTime: maximumResurrectionTime,
                freeBond: freeBond,
                cursedBond: 0
            });

        // save the new archaeologist into relevant data structures
        data.archaeologists[msg.sender] = newArch;
        data.archaeologistAddresses.push(msg.sender);

        // emit an event
        emit Events.RegisterArchaeologist(
            msg.sender,
            newArch.currentPublicKey,
            newArch.endpoint,
            newArch.paymentAddress,
            newArch.feePerByte,
            newArch.minimumBounty,
            newArch.minimumDiggingFee,
            newArch.maximumResurrectionTime,
            newArch.freeBond
        );

        // return index of the new archaeologist
        return data.archaeologistAddresses.length - 1;
    }

    /**
     * @notice An archaeologist may update their profile
     * @param data the system's data struct instance
     * @param endpoint where to contact this archaeologist on the internet
     * @param newPublicKey the public key to be used in the next
     * sarcophagus
     * @param paymentAddress all collected payments for the archaeologist will
     * be sent here
     * @param feePerByte amount of SARCO tokens charged per byte of storage
     * being sent to Arweave
     * @param minimumBounty the minimum bounty for a sarcophagus that the
     * archaeologist will accept
     * @param minimumDiggingFee the minimum digging fee for a sarcophagus that
     * the archaeologist will accept
     * @param maximumResurrectionTime the maximum resurrection time for a
     * sarcophagus that the archaeologist will accept, in relative terms (i.e.
     * "1 year" is 31536000 (seconds))
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to add to their profile
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the update was successful
     */
    function updateArchaeologist(
        Datas.Data storage data,
        bytes memory newPublicKey,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond,
        IERC20 sarcoToken
    ) public returns (bool) {
        // verify that the archaeologist exists, and is the sender of this
        // transaction
        archaeologistExists(data, msg.sender, true);

        // load up the archaeologist
        Types.Archaeologist storage arch = data.archaeologists[msg.sender];

        // if archaeologist is updating their active public key, emit an event
        if (keccak256(arch.currentPublicKey) != keccak256(newPublicKey)) {
            emit Events.UpdateArchaeologistPublicKey(msg.sender, newPublicKey);
            arch.currentPublicKey = newPublicKey;
        }

        // update the rest of the archaeologist profile
        arch.endpoint = endpoint;
        arch.paymentAddress = paymentAddress;
        arch.feePerByte = feePerByte;
        arch.minimumBounty = minimumBounty;
        arch.minimumDiggingFee = minimumDiggingFee;
        arch.maximumResurrectionTime = maximumResurrectionTime;

        // the freeBond variable acts as an incrementer, so only if it's above
        // zero will we update their profile variable and transfer the tokens
        if (freeBond > 0) {
            increaseFreeBond(data, msg.sender, freeBond);
            sarcoToken.transferFrom(msg.sender, address(this), freeBond);
        }

        // emit an event
        emit Events.UpdateArchaeologist(
            msg.sender,
            arch.endpoint,
            arch.paymentAddress,
            arch.feePerByte,
            arch.minimumBounty,
            arch.minimumDiggingFee,
            arch.maximumResurrectionTime,
            freeBond
        );

        // return true
        return true;
    }

    /**
     * @notice Archaeologist can withdraw any of their free bond
     * @param data the system's data struct instance
     * @param amount the amount of the archaeologist's free bond that they're
     * withdrawing
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the withdrawal was successful
     */
    function withdrawBond(
        Datas.Data storage data,
        uint256 amount,
        IERC20 sarcoToken
    ) public returns (bool) {
        // verify that the archaeologist exists, and is the sender of this
        // transaction
        archaeologistExists(data, msg.sender, true);

        // move free bond out of the archaeologist
        decreaseFreeBond(data, msg.sender, amount);

        // transfer the freed SARCOs back to the archaeologist
        sarcoToken.transfer(msg.sender, amount);

        // emit event
        emit Events.WithdrawalFreeBond(msg.sender, amount);

        // return true
        return true;
    }
}

// File: contracts/libraries/PrivateKeys.sol

pragma solidity ^0.8.0;

/**
 * @title Private key verification
 * @notice Implements a private key -> public key checking function
 * @dev modified from https://github.com/1Address/ecsol, removes extra code
 * which isn't necessary for our Sarcophagus implementation
 */
library PrivateKeys {
    uint256 public constant gx =
        0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant gy =
        0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    //
    // Based on the original idea of Vitalik Buterin:
    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    //

    function ecmulVerify(
        uint256 x1,
        uint256 y1,
        bytes32 scalar,
        bytes memory pubKey
    ) private pure returns (bool) {
        uint256 m =
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        address signer =
            ecrecover(
                0,
                y1 % 2 != 0 ? 28 : 27,
                bytes32(x1),
                bytes32(mulmod(uint256(scalar), x1, m))
            );

        address xyAddress =
            address(
                uint160(
                    uint256(keccak256(pubKey)) &
                        0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            );
        return xyAddress == signer;
    }

    /**
     * @notice Given a private key and a public key, determines if that public
     * key was derived from the private key
     * @param privKey an secp256k1 private key
     * @param pubKey an secp256k1 public key
     * @return bool indicating whether the public key is derived from the
     * private key
     */
    function keyVerification(bytes32 privKey, bytes memory pubKey)
        public
        pure
        returns (bool)
    {
        return ecmulVerify(gx, gy, privKey, pubKey);
    }
}

// File: contracts/libraries/Sarcophaguses.sol

pragma solidity ^0.8.0;








/**
 * @title A library implementing Sarcophagus-specific logic in the
 * Sarcophagus system
 * @notice This library includes public functions for manipulating
 * sarcophagi in the Sarcophagus system
 */
library Sarcophaguses {
    /**
     * @notice Reverts if the given sarcState does not equal the comparison
     * state
     * @param sarcState the state of a sarcophagus
     * @param state the state to compare to
     */
    function sarcophagusState(
        Types.SarcophagusStates sarcState,
        Types.SarcophagusStates state
    ) internal pure {
        // set the error message
        string memory error = "sarcophagus already exists";
        if (state == Types.SarcophagusStates.Exists)
            error = "sarcophagus does not exist or is not active";

        // revert if states are not equal
        require(sarcState == state, error);
    }

    /**
     * @notice Takes a sarcophagus's cursed bond, splits it in half, and sends
     * to the transaction caller and embalmer
     * @param data the system's data struct instance
     * @param paymentAddress payment address for the transaction caller
     * @param sarc the sarcophagus to operate on
     * @param sarcoToken the SARCO token used for payment handling
     * @return halfToSender the amount of SARCO token going to transaction
     * sender
     * @return halfToEmbalmer the amount of SARCO token going to embalmer
     */
    function splitSend(
        Datas.Data storage data,
        address paymentAddress,
        Types.Sarcophagus storage sarc,
        IERC20 sarcoToken
    ) private returns (uint256, uint256) {
        // split the sarcophagus's cursed bond into two halves, taking into
        // account solidity math
        uint256 halfToEmbalmer = sarc.currentCursedBond / 2;
        uint256 halfToSender = sarc.currentCursedBond - halfToEmbalmer;

        // transfer the cursed half, plus bounty, plus digging fee to the
        // embalmer
        sarcoToken.transfer(
            sarc.embalmer,
            sarc.bounty + sarc.diggingFee + halfToEmbalmer
        );

        // transfer the other half of the cursed bond to the transaction caller
        sarcoToken.transfer(paymentAddress, halfToSender);

        // update (decrease) the archaeologist's cursed bond, because this
        // sarcophagus is over
        Archaeologists.decreaseCursedBond(
            data,
            sarc.archaeologist,
            sarc.currentCursedBond
        );

        // return data
        return (halfToSender, halfToEmbalmer);
    }

    /**
     * @notice Embalmer creates the skeleton for a new sarcopahgus
     * @param data the system's data struct instance
     * @param name the name of the sarcophagus
     * @param archaeologist the address of a registered archaeologist to
     * assign this sarcophagus to
     * @param resurrectionTime the resurrection time of the sarcophagus
     * @param storageFee the storage fee that the archaeologist will receive,
     * for saving this sarcophagus on Arweave
     * @param diggingFee the digging fee that the archaeologist will receive at
     * the first rewrap
     * @param bounty the bounty that the archaeologist will receive when the
     * sarcophagus is unwrapped
     * @param identifier the identifier of the sarcophagus, which is the hash
     * of the hash of the inner encrypted layer of the sarcophagus
     * @param recipientPublicKey the public key of the recipient
     * @param sarcoToken the SARCO token used for payment handling
     * @return index of the new sarcophagus
     */
    function createSarcophagus(
        Datas.Data storage data,
        string memory name,
        address archaeologist,
        uint256 resurrectionTime,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes32 identifier,
        bytes memory recipientPublicKey,
        IERC20 sarcoToken
    ) public returns (uint256) {
        // confirm that the archaeologist exists
        Archaeologists.archaeologistExists(data, archaeologist, true);

        // confirm that the public key length is correct
        Utils.publicKeyLength(recipientPublicKey);

        // confirm that this exact sarcophagus does not yet exist
        sarcophagusState(
            data.sarcophaguses[identifier].state,
            Types.SarcophagusStates.DoesNotExist
        );

        // confirm that the resurrection time is in the future
        Utils.resurrectionInFuture(resurrectionTime);

        // load the archaeologist
        Types.Archaeologist memory arch = data.archaeologists[archaeologist];

        // check that the new sarcophagus parameters fit within the selected
        // archaeologist's parameters
        Utils.withinArchaeologistLimits(
            resurrectionTime,
            diggingFee,
            bounty,
            arch.maximumResurrectionTime,
            arch.minimumDiggingFee,
            arch.minimumBounty
        );

        // calculate the amount of archaeologist's bond to lock up
        uint256 cursedBondAmount =
            Archaeologists.getCursedBond(diggingFee, bounty);

        // lock up that bond
        Archaeologists.lockUpBond(data, archaeologist, cursedBondAmount);

        // create a new sarcophagus
        Types.Sarcophagus memory sarc =
            Types.Sarcophagus({
                state: Types.SarcophagusStates.Exists,
                archaeologist: archaeologist,
                archaeologistPublicKey: arch.currentPublicKey,
                embalmer: msg.sender,
                name: name,
                resurrectionTime: resurrectionTime,
                resurrectionWindow: Utils.getGracePeriod(resurrectionTime),
                assetId: "",
                recipientPublicKey: recipientPublicKey,
                storageFee: storageFee,
                diggingFee: diggingFee,
                bounty: bounty,
                currentCursedBond: cursedBondAmount,
                privateKey: 0
            });

        // derive the recipient's address from their public key
        address recipientAddress =
            address(uint160(uint256(keccak256(recipientPublicKey))));

        // save the sarcophagus into necessary data structures
        data.sarcophaguses[identifier] = sarc;
        data.sarcophagusIdentifiers.push(identifier);
        data.embalmerSarcophaguses[msg.sender].push(identifier);
        data.archaeologistSarcophaguses[archaeologist].push(identifier);
        data.recipientSarcophaguses[recipientAddress].push(identifier);

        // transfer digging fee + bounty + storage fee from embalmer to this
        // contract
        sarcoToken.transferFrom(
            msg.sender,
            address(this),
            diggingFee + bounty + storageFee
        );

        // emit event with all the data
        emit Events.CreateSarcophagus(
            identifier,
            sarc.archaeologist,
            sarc.archaeologistPublicKey,
            sarc.embalmer,
            sarc.name,
            sarc.resurrectionTime,
            sarc.resurrectionWindow,
            sarc.storageFee,
            sarc.diggingFee,
            sarc.bounty,
            sarc.recipientPublicKey,
            sarc.currentCursedBond
        );

        // return index of the new sarcophagus
        return data.sarcophagusIdentifiers.length - 1;
    }

    /**
     * @notice Embalmer updates a sarcophagus given it's identifier, after
     * the archaeologist has uploaded the encrypted payload onto Arweave
     * @param data the system's data struct instance
     * @param newPublicKey the archaeologist's new public key, to use for
     * encrypting the next sarcophagus that they're assigned to
     * @param identifier the identifier of the sarcophagus
     * @param assetId the identifier of the encrypted asset on Arweave
     * @param v signature element
     * @param r signature element
     * @param s signature element
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the update was successful
     */
    function updateSarcophagus(
        Datas.Data storage data,
        bytes memory newPublicKey,
        bytes32 identifier,
        string memory assetId,
        uint8 v,
        bytes32 r,
        bytes32 s,
        IERC20 sarcoToken
    ) public returns (bool) {
        // load the sarcophagus, and make sure it exists
        Types.Sarcophagus storage sarc = data.sarcophaguses[identifier];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);

        // verify that the embalmer is making this transaction
        Utils.sarcophagusUpdater(sarc.embalmer);

        // verify that the sarcophagus does not currently have an assetId, and
        // that we are setting an actual assetId
        Utils.assetIdsCheck(sarc.assetId, assetId);

        // verify that the archaeologist's new public key, and the assetId,
        // actually came from the archaeologist and were not tampered
        Utils.signatureCheck(
            abi.encodePacked(newPublicKey, assetId),
            v,
            r,
            s,
            sarc.archaeologist
        );

        // revert if the new public key coming from the archaeologist has
        // already been used
        require(
            !data.archaeologistUsedKeys[sarc.archaeologistPublicKey],
            "public key already used"
        );

        // make sure that the new public key can't be used again in the future
        data.archaeologistUsedKeys[sarc.archaeologistPublicKey] = true;

        // set the assetId on the sarcophagus
        sarc.assetId = assetId;

        // load up the archaeologist
        Types.Archaeologist storage arch =
            data.archaeologists[sarc.archaeologist];

        // set the new public key on the archaeologist
        arch.currentPublicKey = newPublicKey;

        // transfer the storage fee to the archaeologist
        sarcoToken.transfer(arch.paymentAddress, sarc.storageFee);
        sarc.storageFee = 0;

        // emit some events
        emit Events.UpdateSarcophagus(identifier, assetId);
        emit Events.UpdateArchaeologistPublicKey(
            sarc.archaeologist,
            arch.currentPublicKey
        );

        // return true
        return true;
    }

    /**
     * @notice An embalmer may cancel a sarcophagus if it hasn't been
     * completely created
     * @param data the system's data struct instance
     * @param identifier the identifier of the sarcophagus
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the cancel was successful
     */
    function cancelSarcophagus(
        Datas.Data storage data,
        bytes32 identifier,
        IERC20 sarcoToken
    ) public returns (bool) {
        // load the sarcophagus, and make sure it exists
        Types.Sarcophagus storage sarc = data.sarcophaguses[identifier];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);

        // verify that the asset id has not yet been set
        Utils.confirmAssetIdNotSet(sarc.assetId);

        // verify that the embalmer is making this transaction
        Utils.sarcophagusUpdater(sarc.embalmer);

        // transfer the bounty and storage fee back to the embalmer
        sarcoToken.transfer(sarc.embalmer, sarc.bounty + sarc.storageFee);

        // load the archaeologist
        Types.Archaeologist memory arch =
            data.archaeologists[sarc.archaeologist];

        // transfer the digging fee over to the archaeologist
        sarcoToken.transfer(arch.paymentAddress, sarc.diggingFee);

        // free up the cursed bond on the archaeologist, because this
        // sarcophagus is over
        Archaeologists.freeUpBond(
            data,
            sarc.archaeologist,
            sarc.currentCursedBond
        );

        // set the sarcophagus state to Done
        sarc.state = Types.SarcophagusStates.Done;

        // save the fact that this sarcophagus has been cancelled, against the
        // archaeologist
        data.archaeologistCancels[sarc.archaeologist].push(identifier);

        // emit an event
        emit Events.CancelSarcophagus(identifier);

        // return true
        return true;
    }

    /**
     * @notice Embalmer can extend the resurrection time of the sarcophagus,
     * as long as the previous resurrection time is in the future
     * @param data the system's data struct instance
     * @param identifier the identifier of the sarcophagus
     * @param resurrectionTime new resurrection time for the rewrapped
     * sarcophagus
     * @param diggingFee new digging fee for the rewrapped sarcophagus
     * @param bounty new bounty for the rewrapped sarcophagus
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the rewrap was successful
     */
    function rewrapSarcophagus(
        Datas.Data storage data,
        bytes32 identifier,
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty,
        IERC20 sarcoToken
    ) public returns (bool) {
        // load the sarcophagus, and make sure it exists
        Types.Sarcophagus storage sarc = data.sarcophaguses[identifier];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);

        // verify that the embalmer is making this transaction
        Utils.sarcophagusUpdater(sarc.embalmer);

        // verify that both the current resurrection time, and the new
        // resurrection time, are in the future
        Utils.resurrectionInFuture(sarc.resurrectionTime);
        Utils.resurrectionInFuture(resurrectionTime);

        // load the archaeologist
        Types.Archaeologist storage arch =
            data.archaeologists[sarc.archaeologist];

        // check that the sarcophagus updated parameters fit within the
        // archaeologist's parameters
        Utils.withinArchaeologistLimits(
            resurrectionTime,
            diggingFee,
            bounty,
            arch.maximumResurrectionTime,
            arch.minimumDiggingFee,
            arch.minimumBounty
        );

        // transfer the new digging fee from embalmer to this contract
        sarcoToken.transferFrom(msg.sender, address(this), diggingFee);

        // transfer the old digging fee to the archaeologist
        sarcoToken.transfer(arch.paymentAddress, sarc.diggingFee);

        // calculate the amount of archaeologist's bond to lock up
        uint256 cursedBondAmount =
            Archaeologists.getCursedBond(diggingFee, bounty);

        // if new cursed bond amount is greater than current cursed bond
        // amount, calculate difference and lock it up. if it's less than,
        // calculate difference and free it up.
        if (cursedBondAmount > sarc.currentCursedBond) {
            uint256 diff = cursedBondAmount - sarc.currentCursedBond;
            Archaeologists.lockUpBond(data, sarc.archaeologist, diff);
        } else if (cursedBondAmount < sarc.currentCursedBond) {
            uint256 diff = sarc.currentCursedBond - cursedBondAmount;
            Archaeologists.freeUpBond(data, sarc.archaeologist, diff);
        }

        // determine the new grace period for the archaeologist's final proof
        uint256 gracePeriod = Utils.getGracePeriod(resurrectionTime);

        // set variarbles on the sarcopahgus
        sarc.resurrectionTime = resurrectionTime;
        sarc.diggingFee = diggingFee;
        sarc.bounty = bounty;
        sarc.currentCursedBond = cursedBondAmount;
        sarc.resurrectionWindow = gracePeriod;

        // emit an event
        emit Events.RewrapSarcophagus(
            sarc.assetId,
            identifier,
            resurrectionTime,
            gracePeriod,
            diggingFee,
            bounty,
            cursedBondAmount
        );

        // return true
        return true;
    }

    /**
     * @notice Given a sarcophagus identifier, preimage, and private key,
     * verify that the data is valid and close out that sarcophagus
     * @param data the system's data struct instance
     * @param identifier the identifier of the sarcophagus
     * @param privateKey the archaeologist's private key which will decrypt the
     * @param sarcoToken the SARCO token used for payment handling
     * outer layer of the encrypted payload on Arweave
     * @return bool indicating that the unwrap was successful
     */
    function unwrapSarcophagus(
        Datas.Data storage data,
        bytes32 identifier,
        bytes32 privateKey,
        IERC20 sarcoToken
    ) public returns (bool) {
        // load the sarcophagus, and make sure it exists
        Types.Sarcophagus storage sarc = data.sarcophaguses[identifier];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);

        // verify that we're in the resurrection window
        Utils.unwrapTime(sarc.resurrectionTime, sarc.resurrectionWindow);

        // verify that the given private key derives the public key on the
        // sarcophagus
        require(
            PrivateKeys.keyVerification(
                privateKey,
                sarc.archaeologistPublicKey
            ),
            "!privateKey"
        );

        // save that private key onto the sarcophagus model
        sarc.privateKey = privateKey;

        // load up the archaeologist
        Types.Archaeologist memory arch =
            data.archaeologists[sarc.archaeologist];

        // transfer the Digging fee and bounty over to the archaeologist
        sarcoToken.transfer(arch.paymentAddress, sarc.diggingFee + sarc.bounty);

        // free up the archaeologist's cursed bond, because this sarcophagus is
        // done
        Archaeologists.freeUpBond(
            data,
            sarc.archaeologist,
            sarc.currentCursedBond
        );

        // set the sarcophagus to Done
        sarc.state = Types.SarcophagusStates.Done;

        // save this successful sarcophagus against the archaeologist
        data.archaeologistSuccesses[sarc.archaeologist].push(identifier);

        // emit an event
        emit Events.UnwrapSarcophagus(sarc.assetId, identifier, privateKey);

        // return true
        return true;
    }

    /**
     * @notice Given a sarcophagus, accuse the archaeologist for unwrapping the
     * sarcophagus early
     * @param data the system's data struct instance
     * @param identifier the identifier of the sarcophagus
     * @param singleHash the preimage of the sarcophagus identifier
     * @param paymentAddress the address to receive payment for accusing the
     * archaeologist
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the accusal was successful
     */
    function accuseArchaeologist(
        Datas.Data storage data,
        bytes32 identifier,
        bytes memory singleHash,
        address paymentAddress,
        IERC20 sarcoToken
    ) public returns (bool) {
        // load the sarcophagus, and make sure it exists
        Types.Sarcophagus storage sarc = data.sarcophaguses[identifier];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);

        // verify that the resurrection time is in the future
        Utils.resurrectionInFuture(sarc.resurrectionTime);

        // verify that the accuser has data which proves that the archaeologist
        // released the payload too early
        Utils.hashCheck(identifier, singleHash);

        // reward this transaction's caller, and the embalmer, with the cursed
        // bond, and refund the rest of the payment (bounty and digging fees)
        // back to the embalmer
        (uint256 halfToSender, uint256 halfToEmbalmer) =
            splitSend(data, paymentAddress, sarc, sarcoToken);

        // save the accusal against the archaeologist
        data.archaeologistAccusals[sarc.archaeologist].push(identifier);

        // update sarcophagus state to Done
        sarc.state = Types.SarcophagusStates.Done;

        // emit an event
        emit Events.AccuseArchaeologist(
            identifier,
            msg.sender,
            halfToSender,
            halfToEmbalmer
        );

        // return true
        return true;
    }

    /**
     * @notice Extends a sarcophagus resurrection time into infinity
     * effectively signaling that the sarcophagus is over and should never be
     * resurrected
     * @param data the system's data struct instance
     * @param identifier the identifier of the sarcophagus
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the bury was successful
     */
    function burySarcophagus(
        Datas.Data storage data,
        bytes32 identifier,
        IERC20 sarcoToken
    ) public returns (bool) {
        // load the sarcophagus, and make sure it exists
        Types.Sarcophagus storage sarc = data.sarcophaguses[identifier];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);

        // verify that the embalmer made this transaction
        Utils.sarcophagusUpdater(sarc.embalmer);

        // verify that the existing resurrection time is in the future
        Utils.resurrectionInFuture(sarc.resurrectionTime);

        // load the archaeologist
        Types.Archaeologist storage arch =
            data.archaeologists[sarc.archaeologist];

        // free the archaeologist's bond, because this sarcophagus is over
        Archaeologists.freeUpBond(
            data,
            sarc.archaeologist,
            sarc.currentCursedBond
        );

        // transfer the digging fee to the archae
        sarcoToken.transfer(arch.paymentAddress, sarc.diggingFee);

        // set the resurrection time of this sarcopahgus at maxint
        sarc.resurrectionTime = 2**256 - 1;

        // update sarcophagus state to Done
        sarc.state = Types.SarcophagusStates.Done;

        // emit an event
        emit Events.BurySarcophagus(identifier);

        // return true
        return true;
    }

    /**
     * @notice Clean up a sarcophagus whose resurrection time and window have
     * passed. Callable by anyone.
     * @param data the system's data struct instance
     * @param identifier the identifier of the sarcophagus
     * @param paymentAddress the address to receive payment for cleaning up the
     * sarcophagus
     * @param sarcoToken the SARCO token used for payment handling
     * @return bool indicating that the clean up was successful
     */
    function cleanUpSarcophagus(
        Datas.Data storage data,
        bytes32 identifier,
        address paymentAddress,
        IERC20 sarcoToken
    ) public returns (bool) {
        // load the sarcophagus, and make sure it exists
        Types.Sarcophagus storage sarc = data.sarcophaguses[identifier];
        sarcophagusState(sarc.state, Types.SarcophagusStates.Exists);

        // verify that the resurrection window has expired
        require(
            sarc.resurrectionTime + sarc.resurrectionWindow < block.timestamp,
            "sarcophagus resurrection period must be in the past"
        );

        // reward this transaction's caller, and the embalmer, with the cursed
        // bond, and refund the rest of the payment (bounty and digging fees)
        // back to the embalmer
        (uint256 halfToSender, uint256 halfToEmbalmer) =
            splitSend(data, paymentAddress, sarc, sarcoToken);

        // save the cleanup against the archaeologist
        data.archaeologistCleanups[sarc.archaeologist].push(identifier);

        // update sarcophagus state to Done
        sarc.state = Types.SarcophagusStates.Done;

        // emit an event
        emit Events.CleanUpSarcophagus(
            identifier,
            msg.sender,
            halfToSender,
            halfToEmbalmer
        );

        // return true
        return true;
    }
}

// File: contracts/Sarcophagus.sol

pragma solidity ^0.8.0;








/**
 * @title The main Sarcophagus system contract
 * @notice This contract implements the entire public interface for the
 * Sarcophagus system
 *
 * Sarcophagus implements a Dead Man's Switch using the Ethereum network as
 * the official source of truth for the switch (the "sarcophagus"), the Arweave
 * blockchain as the data storage layer for the encrypted payload, and a
 * decentralized network of secret-holders (the "archaeologists") who are
 * responsible for keeping a private key secret until the dead man's switch is
 * activated (via inaction by the "embalmer", the creator of the sarcophagus).
 *
 * @dev All function calls "proxy" down to functions implemented in one of
 * many libraries
 */
contract Sarcophagus is Initializable {
    // keep a reference to the SARCO token, which is used for payments
    // throughout the system
    IERC20 public sarcoToken;

    // all system data is stored within this single instance (_data) of the
    // Data struct
    Datas.Data private _data;

    /**
     * @notice Contract initializer
     * @param _sarcoToken The address of the SARCO token
     */
    function initialize(address _sarcoToken) public initializer {
        sarcoToken = IERC20(_sarcoToken);
        emit Events.Creation(_sarcoToken);
    }

    /**
     * @notice Return the number of archaeologists that have been registered
     * @return total registered archaeologist count
     */
    function archaeologistCount() public view virtual returns (uint256) {
        return _data.archaeologistAddresses.length;
    }

    /**
     * @notice Given an index (of the full archaeologist array), return the
     * archaeologist address at that index
     * @param index The index of the registered archaeologist
     * @return address of the archaeologist
     */
    function archaeologistAddresses(uint256 index)
        public
        view
        virtual
        returns (address)
    {
        return _data.archaeologistAddresses[index];
    }

    /**
     * @notice Given an archaeologist address, return that archaeologist's
     * profile
     * @param account The archaeologist account's address
     * @return the Archaeologist object
     */
    function archaeologists(address account)
        public
        view
        virtual
        returns (Types.Archaeologist memory)
    {
        return _data.archaeologists[account];
    }

    /**
     * @notice Return the total number of sarcophagi that have been created
     * @return the number of sarcophagi that have ever been created
     */
    function sarcophagusCount() public view virtual returns (uint256) {
        return _data.sarcophagusIdentifiers.length;
    }

    /**
     * @notice Return the unique identifier of a sarcophagus, given it's index
     * @param index The index of the sarcophagus
     * @return the unique identifier of the given sarcophagus
     */
    function sarcophagusIdentifier(uint256 index)
        public
        view
        virtual
        returns (bytes32)
    {
        return _data.sarcophagusIdentifiers[index];
    }

    /**
     * @notice Returns the count of sarcophagi created by a specific embalmer
     * @param embalmer The address of the given embalmer
     * @return the number of sarcophagi which have been created by an embalmer
     */
    function embalmerSarcophagusCount(address embalmer)
        public
        view
        virtual
        returns (uint256)
    {
        return _data.embalmerSarcophaguses[embalmer].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given embalmer
     * and index
     * @param embalmer The address of an embalmer
     * @param index The index of the embalmer's list of sarcophagi
     * @return the double hash associated with the index of the embalmer's
     * sarcophagi
     */
    function embalmerSarcophagusIdentifier(address embalmer, uint256 index)
        public
        view
        virtual
        returns (bytes32)
    {
        return _data.embalmerSarcophaguses[embalmer][index];
    }

    /**
     * @notice Returns the count of sarcophagi created for a specific
     * archaeologist
     * @param archaeologist The address of the given archaeologist
     * @return the number of sarcophagi which have been created for an
     * archaeologist
     */
    function archaeologistSarcophagusCount(address archaeologist)
        public
        view
        virtual
        returns (uint256)
    {
        return _data.archaeologistSarcophaguses[archaeologist].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given
     * archaeologist and index
     * @param archaeologist The address of an archaeologist
     * @param index The index of the archaeologist's list of sarcophagi
     * @return the identifier associated with the index of the archaeologist's
     * sarcophagi
     */
    function archaeologistSarcophagusIdentifier(
        address archaeologist,
        uint256 index
    ) public view virtual returns (bytes32) {
        return _data.archaeologistSarcophaguses[archaeologist][index];
    }

    /**
     * @notice Returns the count of sarcophagi created for a specific recipient
     * @param recipient The address of the given recipient
     * @return the number of sarcophagi which have been created for a recipient
     */
    function recipientSarcophagusCount(address recipient)
        public
        view
        virtual
        returns (uint256)
    {
        return _data.recipientSarcophaguses[recipient].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given recipient
     * and index
     * @param recipient The address of a recipient
     * @param index The index of the recipient's list of sarcophagi
     * @return the identifier associated with the index of the recipient's
     * sarcophagi
     */
    function recipientSarcophagusIdentifier(address recipient, uint256 index)
        public
        view
        virtual
        returns (bytes32)
    {
        return _data.recipientSarcophaguses[recipient][index];
    }

    /**
     * @notice Returns the count of successful sarcophagi completed by the
     * archaeologist
     * @param archaeologist The address of the given archaeologist
     * @return the number of sarcophagi which have been successfully completed
     * by the archaeologist
     */
    function archaeologistSuccessesCount(address archaeologist)
        public
        view
        virtual
        returns (uint256)
    {
        return _data.archaeologistSuccesses[archaeologist].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given archaeologist
     * and index of successful sarcophagi
     * @param archaeologist The address of an archaeologist
     * @param index The index of the archaeologist's list of successfully
     * completed sarcophagi
     * @return the identifier associated with the index of the archaeologist's
     * successfully completed sarcophagi
     */
    function archaeologistSuccessesIdentifier(
        address archaeologist,
        uint256 index
    ) public view returns (bytes32) {
        return _data.archaeologistSuccesses[archaeologist][index];
    }

    /**
     * @notice Returns the count of cancelled sarcophagi from the archaeologist
     * @param archaeologist The address of the given archaeologist
     * @return the number of cancelled sarcophagi from the archaeologist
     */
    function archaeologistCancelsCount(address archaeologist)
        public
        view
        virtual
        returns (uint256)
    {
        return _data.archaeologistCancels[archaeologist].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given archaeologist
     * and index of the cancelled sarcophagi
     * @param archaeologist The address of an archaeologist
     * @param index The index of the archaeologist's cancelled sarcophagi
     * @return the identifier associated with the index of the archaeologist's
     * cancelled sarcophagi
     */
    function archaeologistCancelsIdentifier(
        address archaeologist,
        uint256 index
    ) public view virtual returns (bytes32) {
        return _data.archaeologistCancels[archaeologist][index];
    }

    /**
     * @notice Returns the count of accused sarcophagi from the archaeologist
     * @param archaeologist The address of the given archaeologist
     * @return the number of accused sarcophagi from the archaeologist
     */
    function archaeologistAccusalsCount(address archaeologist)
        public
        view
        virtual
        returns (uint256)
    {
        return _data.archaeologistAccusals[archaeologist].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given
     * archaeologist and index of the accused sarcophagi
     * @param archaeologist The address of an archaeologist
     * @param index The index of the archaeologist's accused sarcophagi
     * @return the identifier associated with the index of the archaeologist's
     * accused sarcophagi
     */
    function archaeologistAccusalsIdentifier(
        address archaeologist,
        uint256 index
    ) public view virtual returns (bytes32) {
        return _data.archaeologistAccusals[archaeologist][index];
    }

    /**
     * @notice Returns the count of cleaned-up sarcophagi from the
     * archaeologist
     * @param archaeologist The address of the given archaeologist
     * @return the number of cleaned-up sarcophagi from the archaeologist
     */
    function archaeologistCleanupsCount(address archaeologist)
        public
        view
        virtual
        returns (uint256)
    {
        return _data.archaeologistCleanups[archaeologist].length;
    }

    /**
     * @notice Returns the sarcophagus unique identifier for a given
     * archaeologist and index of the cleaned-up sarcophagi
     * @param archaeologist The address of an archaeologist
     * @param index The index of the archaeologist's accused sarcophagi
     * @return the identifier associated with the index of the archaeologist's
     * leaned-up sarcophagi
     */
    function archaeologistCleanupsIdentifier(
        address archaeologist,
        uint256 index
    ) public view virtual returns (bytes32) {
        return _data.archaeologistCleanups[archaeologist][index];
    }

    /**
     * @notice Returns sarcophagus data given an indentifier
     * @param identifier the unique identifier a sarcophagus
     * @return sarc the Sarcophagus object
     */
    function sarcophagus(bytes32 identifier)
        public
        view
        virtual
        returns (Types.Sarcophagus memory)
    {
        return _data.sarcophaguses[identifier];
    }

    /**
     * @notice Registers a new archaeologist in the system
     * @param currentPublicKey the public key to be used in the first
     * sarcophagus
     * @param endpoint where to contact this archaeologist on the internet
     * @param paymentAddress all collected payments for the archaeologist will
     * be sent here
     * @param feePerByte amount of SARCO tokens charged per byte of storage
     * being sent to Arweave
     * @param minimumBounty the minimum bounty for a sarcophagus that the
     * archaeologist will accept
     * @param minimumDiggingFee the minimum digging fee for a sarcophagus that
     * the archaeologist will accept
     * @param maximumResurrectionTime the maximum resurrection time for a
     * sarcophagus that the archaeologist will accept, in relative terms (i.e.
     * "1 year" is 31536000 (seconds))
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to start with
     * @return index of the new archaeologist
     */
    function registerArchaeologist(
        bytes memory currentPublicKey,
        string memory endpoint,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond
    ) public virtual returns (uint256) {
        return
            Archaeologists.registerArchaeologist(
                _data,
                currentPublicKey,
                endpoint,
                paymentAddress,
                feePerByte,
                minimumBounty,
                minimumDiggingFee,
                maximumResurrectionTime,
                freeBond,
                sarcoToken
            );
    }

    /**
     * @notice An archaeologist may update their profile
     * @param endpoint where to contact this archaeologist on the internet
     * @param newPublicKey the public key to be used in the next
     * sarcophagus
     * @param paymentAddress all collected payments for the archaeologist will
     * be sent here
     * @param feePerByte amount of SARCO tokens charged per byte of storage
     * being sent to Arweave
     * @param minimumBounty the minimum bounty for a sarcophagus that the
     * archaeologist will accept
     * @param minimumDiggingFee the minimum digging fee for a sarcophagus that
     * the archaeologist will accept
     * @param maximumResurrectionTime the maximum resurrection time for a
     * sarcophagus that the archaeologist will accept, in relative terms (i.e.
     * "1 year" is 31536000 (seconds))
     * @param freeBond the amount of SARCO bond that the archaeologist wants
     * to add to their profile
     * @return bool indicating that the update was successful
     */
    function updateArchaeologist(
        string memory endpoint,
        bytes memory newPublicKey,
        address paymentAddress,
        uint256 feePerByte,
        uint256 minimumBounty,
        uint256 minimumDiggingFee,
        uint256 maximumResurrectionTime,
        uint256 freeBond
    ) public virtual returns (bool) {
        return
            Archaeologists.updateArchaeologist(
                _data,
                newPublicKey,
                endpoint,
                paymentAddress,
                feePerByte,
                minimumBounty,
                minimumDiggingFee,
                maximumResurrectionTime,
                freeBond,
                sarcoToken
            );
    }

    /**
     * @notice Archaeologist can withdraw any of their free bond
     * @param amount the amount of the archaeologist's free bond that they're
     * withdrawing
     * @return bool indicating that the withdrawal was successful
     */
    function withdrawBond(uint256 amount) public virtual returns (bool) {
        return Archaeologists.withdrawBond(_data, amount, sarcoToken);
    }

    /**
     * @notice Embalmer creates the skeleton for a new sarcopahgus
     * @param name the name of the sarcophagus
     * @param archaeologist the address of a registered archaeologist to
     * assign this sarcophagus to
     * @param resurrectionTime the resurrection time of the sarcophagus
     * @param storageFee the storage fee that the archaeologist will receive,
     * for saving this sarcophagus on Arweave
     * @param diggingFee the digging fee that the archaeologist will receive at
     * the first rewrap
     * @param bounty the bounty that the archaeologist will receive when the
     * sarcophagus is unwrapped
     * @param identifier the identifier of the sarcophagus, which is the hash
     * of the hash of the inner encrypted layer of the sarcophagus
     * @param recipientPublicKey the public key of the recipient
     * @return index of the new sarcophagus
     */
    function createSarcophagus(
        string memory name,
        address archaeologist,
        uint256 resurrectionTime,
        uint256 storageFee,
        uint256 diggingFee,
        uint256 bounty,
        bytes32 identifier,
        bytes memory recipientPublicKey
    ) public virtual returns (uint256) {
        return
            Sarcophaguses.createSarcophagus(
                _data,
                name,
                archaeologist,
                resurrectionTime,
                storageFee,
                diggingFee,
                bounty,
                identifier,
                recipientPublicKey,
                sarcoToken
            );
    }

    /**
     * @notice Embalmer updates a sarcophagus given it's identifier, after
     * the archaeologist has uploaded the encrypted payload onto Arweave
     * @param newPublicKey the archaeologist's new public key, to use for
     * encrypting the next sarcophagus that they're assigned to
     * @param identifier the identifier of the sarcophagus
     * @param assetId the identifier of the encrypted asset on Arweave
     * @param v signature element
     * @param r signature element
     * @param s signature element
     * @return bool indicating that the update was successful
     */
    function updateSarcophagus(
        bytes memory newPublicKey,
        bytes32 identifier,
        string memory assetId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (bool) {
        return
            Sarcophaguses.updateSarcophagus(
                _data,
                newPublicKey,
                identifier,
                assetId,
                v,
                r,
                s,
                sarcoToken
            );
    }

    /**
     * @notice An embalmer may cancel a sarcophagus if it hasn't been
     * completely created
     * @param identifier the identifier of the sarcophagus
     * @return bool indicating that the cancel was successful
     */
    function cancelSarcophagus(bytes32 identifier)
        public
        virtual
        returns (bool)
    {
        return Sarcophaguses.cancelSarcophagus(_data, identifier, sarcoToken);
    }

    /**
     * @notice Embalmer can extend the resurrection time of the sarcophagus,
     * as long as the previous resurrection time is in the future
     * @param identifier the identifier of the sarcophagus
     * @param resurrectionTime new resurrection time for the rewrapped
     * sarcophagus
     * @param diggingFee new digging fee for the rewrapped sarcophagus
     * @param bounty new bounty for the rewrapped sarcophagus
     * @return bool indicating that the rewrap was successful
     */
    function rewrapSarcophagus(
        bytes32 identifier,
        uint256 resurrectionTime,
        uint256 diggingFee,
        uint256 bounty
    ) public virtual returns (bool) {
        return
            Sarcophaguses.rewrapSarcophagus(
                _data,
                identifier,
                resurrectionTime,
                diggingFee,
                bounty,
                sarcoToken
            );
    }

    /**
     * @notice Given a sarcophagus identifier, preimage, and private key,
     * verify that the data is valid and close out that sarcophagus
     * @param identifier the identifier of the sarcophagus
     * @param privateKey the archaeologist's private key which will decrypt the
     * outer layer of the encrypted payload on Arweave
     * @return bool indicating that the unwrap was successful
     */
    function unwrapSarcophagus(bytes32 identifier, bytes32 privateKey)
        public
        virtual
        returns (bool)
    {
        return
            Sarcophaguses.unwrapSarcophagus(
                _data,
                identifier,
                privateKey,
                sarcoToken
            );
    }

    /**
     * @notice Given a sarcophagus, accuse the archaeologist for unwrapping the
     * sarcophagus early
     * @param identifier the identifier of the sarcophagus
     * @param singleHash the preimage of the sarcophagus identifier
     * @param paymentAddress the address to receive payment for accusing the
     * archaeologist
     * @return bool indicating that the accusal was successful
     */
    function accuseArchaeologist(
        bytes32 identifier,
        bytes memory singleHash,
        address paymentAddress
    ) public virtual returns (bool) {
        return
            Sarcophaguses.accuseArchaeologist(
                _data,
                identifier,
                singleHash,
                paymentAddress,
                sarcoToken
            );
    }

    /**
     * @notice Extends a sarcophagus resurrection time into infinity
     * effectively signaling that the sarcophagus is over and should never be
     * resurrected
     * @param identifier the identifier of the sarcophagus
     * @return bool indicating that the bury was successful
     */
    function burySarcophagus(bytes32 identifier) public virtual returns (bool) {
        return Sarcophaguses.burySarcophagus(_data, identifier, sarcoToken);
    }

    /**
     * @notice Clean up a sarcophagus whose resurrection time and window have
     * passed. Callable by anyone.
     * @param identifier the identifier of the sarcophagus
     * @param paymentAddress the address to receive payment for cleaning up the
     * sarcophagus
     * @return bool indicating that the clean up was successful
     */
    function cleanUpSarcophagus(bytes32 identifier, address paymentAddress)
        public
        virtual
        returns (bool)
    {
        return
            Sarcophaguses.cleanUpSarcophagus(
                _data,
                identifier,
                paymentAddress,
                sarcoToken
            );
    }
}