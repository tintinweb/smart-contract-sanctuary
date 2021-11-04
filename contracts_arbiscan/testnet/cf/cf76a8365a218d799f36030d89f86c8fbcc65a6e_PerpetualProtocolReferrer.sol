// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import {SafeOwnable} from "./SafeOwnable.sol";

contract PerpetualProtocolReferrer is SafeOwnable {
    enum UpsertAction {
        ADD,
        REMOVE,
        UPDATE
    }

    struct Partner {
        uint256 createdAt;
        string referralCode;
        address createdBy;
    }

    struct Trader {
        string referralCode;
        uint256 createdAt;
        uint256 updatedAt;
    }

    event OnReferralCodeCreated(
        address createdBy,
        address createdFor,
        uint256 timestamp,
        string referralCode
    );

    event OnReferralCodeUpserted(
        address addr,
        UpsertAction action,
        uint256 timestamp,
        string newReferralCode,
        string oldReferralCode
    );

    mapping(address => Partner) public partners;
    mapping(address => Trader) public traders;
    mapping(string => address) public referralCodeToPartnerMap;
    mapping(address => string) public uncappedPartners;

    bool private isInitialised;

    function initialise() internal initializer {
        require(
            !isInitialised,
            "Contract instance has already been initialized"
        );
        isInitialised = true;
        __SafeOwnable_init();
    }

    function createReferralCode(
        address createdFor,
        string calldata referralCode
    ) public {
        address sender = msg.sender;
        uint256 timestamp = block.timestamp;
        // the partner for a code that already exists, used to check against a referral code
        // that has already been assigned
        address existingReferralCodePartner = referralCodeToPartnerMap[
            referralCode
        ];
        // the partner being assigned a new code cannot have an existing code - check using this
        Partner memory existingPartner = partners[createdFor];
        require(bytes(referralCode).length > 0, "Provide a referral code.");
        require(
            createdFor != address(0x0),
            "Provide an address to create the code for."
        );
        require(
            existingReferralCodePartner == address(0x0),
            "This referral code has already been assigned to an address."
        );
        require(
            bytes(existingPartner.referralCode).length == 0,
            "This address already has a referral code assigned."
        );

        partners[createdFor] = Partner(timestamp, referralCode, sender);
        referralCodeToPartnerMap[referralCode] = createdFor;
        emit OnReferralCodeCreated(sender, createdFor, timestamp, referralCode);
    }

    function getReferralCodeByPartnerAddress(address partnerAddress)
        external
        view
        returns (string memory)
    {
        Partner memory partner = partners[partnerAddress];
        require(
            bytes(partner.referralCode).length > 0,
            "Referral code doesn't exist"
        );
        return (partner.referralCode);
    }

    function getMyRefereeCode() public view returns (string memory) {
        Trader memory trader = traders[msg.sender];
        require(
            bytes(trader.referralCode).length > 0,
            "You do not have a referral code"
        );
        return (trader.referralCode);
    }

    function _setReferralCode(string calldata referralCode, address sender)
        internal
    {
        address partner = referralCodeToPartnerMap[referralCode];
        uint256 timestamp = block.timestamp;
        UpsertAction action;
        string memory oldReferralCode = referralCode;

        require(
            partner != sender,
            "You cannot be a referee of a referral code you own"
        );

        // the trader in we are performing the upserts for
        Trader storage trader = traders[sender];

        if (
            bytes(referralCode).length == 0 &&
            bytes(trader.referralCode).length == 0
        ) {
            revert("No referral code was supplied or found.");
        }

        // when referral code is supplied by the trader
        if (bytes(referralCode).length > 0) {
            // if mapping does not exist, referral code doesn't exist.
            require(partner != address(0x0), "Referral code does not exist");

            // if there is a referral code already for that trader, update it with the supplied one
            if (bytes(trader.referralCode).length > 0) {
                oldReferralCode = trader.referralCode;
                trader.referralCode = referralCode;
                trader.updatedAt = timestamp;
                action = UpsertAction.UPDATE;
            } else {
                // if a code doesn't exist for the trader, create the trader
                traders[sender] = Trader(referralCode, timestamp, timestamp);
                action = UpsertAction.ADD;
            }
            // if the referral is not supplied and trader exists, delete trader
        } else if (bytes(trader.referralCode).length > 0) {
            oldReferralCode = trader.referralCode;
            delete traders[sender];
            action = UpsertAction.REMOVE;
        }
        emit OnReferralCodeUpserted(
            sender,
            action,
            timestamp,
            referralCode,
            oldReferralCode
        );
    }

    function setReferralCode(string calldata referralCode) public {
        address sender = msg.sender;
        _setReferralCode(referralCode, sender);
    }

    function _importPartner(
        address partnerAddress,
        string calldata referralCode,
        address[] calldata tradersToImport
    ) public onlyOwner {
        createReferralCode(partnerAddress, referralCode);
        for (uint256 i = 0; i < tradersToImport.length; i++) {
            _setReferralCode(referralCode, tradersToImport[i]);
        }
    }

    function _upsertUncappedPartner(
        address partnerAddress,
        string calldata tier
    ) public onlyOwner {
        require(partnerAddress != address(0x0), "Provide an address");
        require(bytes(tier).length != 0, "Provide a tier");

        Partner memory partner = partners[partnerAddress];
        require(
            bytes(partner.referralCode).length != 0,
            "Partner does not exist"
        );

        uncappedPartners[partnerAddress] = tier;
    }

    function _removeUncappedPartner(address partnerAddress) public onlyOwner {
        require(partnerAddress != address(0x0), "Provide an address");

        Partner memory partner = partners[partnerAddress];
        require(
            bytes(partner.referralCode).length != 0,
            "Partner does not exist"
        );

        string memory tier = uncappedPartners[partnerAddress];
        require(bytes(tier).length != 0, "Partner is not uncapped");

        delete uncappedPartners[partnerAddress];
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract SafeOwnable is ContextUpgradeable {
    address private _owner;
    address private _candidate;

    // __gap is reserved storage
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // caller not owner
        require(owner() == _msgSender(), "SO_CNO");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __SafeOwnable_init() internal initializer {
        __Context_init();
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _candidate = address(0);
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        // newOwner is 0
        require(newOwner != address(0), "SO_NW0");
        // same as original
        require(newOwner != _owner, "SO_SAO");
        // same as candidate
        require(newOwner != _candidate, "SO_SAC");

        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() external {
        // candidate is zero
        require(_candidate != address(0), "SO_C0");
        // caller is not candidate
        require(_candidate == _msgSender(), "SO_CNC");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the candidate that can become the owner.
     */
    function candidate() external view returns (address) {
        return _candidate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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