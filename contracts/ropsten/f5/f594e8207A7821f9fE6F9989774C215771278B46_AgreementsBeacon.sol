// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.1;

import "./agreements-beacon-interface.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AgreementsBeacon is IAgreementsBeacon {
    using Address for address;
    using Strings for uint256;

    mapping(address => mapping(uint256 => Beacon)) private beacons;

    bytes32 private constant EVENT_NAMESPACE = "monax";
    bytes32 private constant EVENT_NAME_BEACON_STATE_CHANGE =
        "request:beacon-status-change";
    bytes32 private constant EVENT_NAME_REQUEST_CREATE_AGREEMENT =
        "request:create-agreement";
    bytes32 private constant EVENT_NAME_REPORT_AGREEMENT_STATUS =
        "report:agreement-status";

    uint256 public constant AGREEMENT_BEACON_PRICE = 1000; // TODO

    address[] private _owners;
    uint256 private _requestIndex;
    uint256 private _currentEventIndex;
    string private _baseUrl;

    modifier ownersOnly() {
        bool isOwner;
        for (uint256 i; i < _owners.length; i++) {
            if (msg.sender == _owners[i]) {
                isOwner = true;
            }
        }
        require(isOwner, "Sender must be a contract owner");
        _;
    }

    modifier requireCharge() {
        uint256 price = AGREEMENT_BEACON_PRICE;
        require(msg.value >= price, "Insufficient funds for operation");
        _;
    }

    modifier isBeaconActivated(address tokenContractAddress, uint256 tokenId) {
        require(
            beacons[tokenContractAddress][tokenId].activated,
            "Beacon not activated"
        );
        _;
    }

    modifier addEvent(uint256 eventCount) {
        _;
        _currentEventIndex += eventCount;
    }

    modifier addRequestIndex() {
        _;
        _requestIndex += 1;
    }

    constructor(address[] memory _o) {
        require(_o.length > 0, "> 1 owner required");
        _requestIndex = 1;
        _owners = _o;
        _baseUrl = string(
            abi.encodePacked(
                "https://agreements.zone/ethereum/",
                block.chainid.toString(),
                "/{tokenContractAddress}/{id}"
            )
        );
    }

    function requestCreateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig
    ) external payable virtual override requireCharge() {
        require(
            beacons[tokenContractAddress][tokenId].creator == address(0),
            "Request limit reached"
        );
        beacons[tokenContractAddress][tokenId].creator = msg.sender;
        beacons[tokenContractAddress][tokenId].templateId = templateId;
        beacons[tokenContractAddress][tokenId].templateConfig = templateConfig;
        beacons[tokenContractAddress][tokenId].activated = true;
        _emitBeaconStateChange(
            tokenContractAddress,
            tokenId,
            templateId,
            templateConfig,
            true
        );
    }

    function requestUpdateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig,
        bool activated
    ) external payable virtual override requireCharge() {
        require(
            beacons[tokenContractAddress][tokenId].creator == msg.sender,
            "You do not own me"
        );
        beacons[tokenContractAddress][tokenId].templateId = templateId;
        beacons[tokenContractAddress][tokenId].templateConfig = templateConfig;
        beacons[tokenContractAddress][tokenId].activated = activated;
        _emitBeaconStateChange(
            tokenContractAddress,
            tokenId,
            templateId,
            templateConfig,
            activated
        );
    }

    function requestCreateAgreement(
        address tokenContractAddress,
        uint256 tokenId,
        address[] memory accepters
    )
        external
        payable
        virtual
        override
        requireCharge()
        isBeaconActivated(tokenContractAddress, tokenId)
        addRequestIndex()
    {
        for (uint256 i = 0; i < accepters.length; i++) {
            address accepter = accepters[i];
            if (
                beacons[tokenContractAddress][tokenId].agreements[accepter]
                    .requestIndex != 0
            ) {
                continue;
            }
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .creator = beacons[tokenContractAddress][tokenId].creator;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .accepter = accepter;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .state = LegalState.FORMULATED;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .requestIndex = _requestIndex;
            _emitCreateAgreementRequest(
                tokenContractAddress,
                tokenId,
                accepter
            );
        }
    }

    function reportAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter,
        address agreement,
        LegalState state,
        string memory errorCode
    ) external virtual override ownersOnly() {
        if (
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement == address(0)
        ) {
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement = agreement;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .state = state;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .errorCode = errorCode;
        } else {
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .state = state;
        }
        beacons[tokenContractAddress][tokenId].agreements[accepter]
            .currentBlockHeight = block.number;
        beacons[tokenContractAddress][tokenId].agreements[accepter]
            .currentEventIndex = _currentEventIndex;
        _emitAgreementStatus(tokenContractAddress, tokenId, accepter);
    }

    function getBeaconURL(address tokenContractAddress, uint256 tokenId)
        external
        view
        virtual
        override
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (string memory)
    {
        return _baseUrl;
    }

    function getBeaconCreator(address tokenContractAddress, uint256 tokenId)
        external
        view
        virtual
        override
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (address creator)
    {
        return beacons[tokenContractAddress][tokenId].creator;
    }

    function getAgreementId(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    )
        external
        view
        virtual
        override
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (address agreement)
    {
        return
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement;
    }

    function getAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    )
        external
        view
        virtual
        override
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (LegalState state)
    {
        return
            beacons[tokenContractAddress][tokenId].agreements[accepter].state;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IAgreementsBeacon).interfaceId;
    }

    function _emitBeaconStateChange(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig,
        bool activated
    ) private addEvent(1) {
        emit LogBeaconStatusChange(
            EVENT_NAMESPACE,
            EVENT_NAME_BEACON_STATE_CHANGE,
            msg.sender,
            tx.origin, // solhint-disable-line avoid-tx-origin
            tokenContractAddress,
            tokenId,
            templateId,
            templateConfig,
            activated,
            block.number,
            _currentEventIndex
        );
    }

    function _emitCreateAgreementRequest(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) private addEvent(1) {
        emit LogRequestCreateAgreement(
            EVENT_NAMESPACE,
            EVENT_NAME_REQUEST_CREATE_AGREEMENT,
            msg.sender,
            tx.origin, // solhint-disable-line avoid-tx-origin
            tokenContractAddress,
            tokenId,
            accepter,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .requestIndex,
            block.number,
            _currentEventIndex
        );
    }

    function _emitAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) private addEvent(1) {
        emit LogAgreementStatus(
            EVENT_NAMESPACE,
            EVENT_NAME_REPORT_AGREEMENT_STATUS,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement,
            beacons[tokenContractAddress][tokenId].agreements[accepter].state,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .errorCode,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .requestIndex,
            block.number,
            _currentEventIndex
        );
    }
}

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IAgreementsBeacon is IERC165 {
    struct Beacon {
        address creator;
        bool activated;
        bytes32 templateId;
        string templateConfig;
        mapping(address => Agreement) agreements;
    }

    struct Agreement {
        address creator;
        address accepter;
        address agreement;
        LegalState state;
        string errorCode;
        uint256 requestIndex;
        uint256 currentBlockHeight;
        uint256 currentEventIndex;
    }
    /**
     * @dev State change enum for an agreement
     */
    enum LegalState {
        DRAFT,
        FORMULATED,
        EXECUTED,
        FULFILLED,
        DEFAULT,
        CANCELED,
        UNDEFINED,
        REDACTED
    }

    /**
     * @dev Emitted when `creator` (potentially via a `relayer`) modifies the state
     * of a beacon for a `tokenContractAddress` and `tokenId` by creating or updating
     * the `templateId` or `templateConfig` that are used to determine the agreement
     * for the token. The `creator` may also turn the beacon on or off via the
     * `activated` field.
     */
    event LogBeaconStatusChange(
        bytes32 indexed eventNamespace,
        bytes32 indexed eventCategory,
        address creator,
        address relayer,
        address indexed tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string templateConfig,
        bool activated,
        uint256 currentBlockHeight,
        uint256 currentEventIndex
    );

    /**
     * @dev Emitted when `creator` (potentially via a `relayer`) of an agreement request
     * asks the beacon to establish a new digital agreement for a given `tokenContractAddress`
     * and `tokenId` combination. The entity accepting the contract offered by the
     * beacon creator will be the `accepter` which may differ from the `creator` or `relayer`.
     *
     * To allow correlation between and across requests, each event will have an embedded
     * `requestIndex` for every request.
     */
    event LogRequestCreateAgreement(
        bytes32 indexed eventNamespace,
        bytes32 indexed eventCategory,
        address creator,
        address relayer,
        address indexed tokenContractAddress,
        uint256 tokenId,
        address accepter,
        uint256 requestIndex,
        uint256 currentBlockHeight,
        uint256 currentEventIndex
    );

    /**
     * @dev Emitted when the beacon has determined that there has been a change in `state`
     * for the digital `agreement`. Can also log and `errorCode` during the agreement creation
     * process. Finally a `requestIndex` is emitted which allows for correlation with {LogRequestCreateAgreement}
     * events.
     */
    event LogAgreementStatus(
        bytes32 indexed eventNamespace,
        bytes32 indexed eventCategory,
        address agreement,
        LegalState state,
        string errorCode,
        uint256 requestIndex,
        uint256 currentBlockHeight,
        uint256 currentEventIndex
    );

    /**
     * @dev Handles the request to create an agreement beacon which will connect a specific token
     * to a set of specific digital agreements that have been agreed to by counterparties.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param templateId The ID of the template that will be used to formulate the agreements (convert
     * the UUID to bytes32 string)
     * @param templateConfig The URL location (preferrable encrypted IPFS hash or Hoard grant) to the
     * JSON encoded parameters to be used with the template ID
     *
     * Emits a {LogBeaconStatusChange} event.
     *
     * Requirements:
     * - minter of the token must not have previously requested beacon activation (note the AgreementsBeacon
     * is purposefully ignorant of who initially owns a particular token)
     * - the {AGREEMENT_BEACON_PRICE} must accompany any calls
     */
    function requestCreateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig
    ) external payable;

    /**
     * @dev Handles the request to update an agreement beacon which will connect a specific token
     * to a set of specific digital agreements that have been agreed to by counterparties.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param templateId The ID of the template that will be used to formulate the agreements (convert the
     * UUID to bytes32 string)
     * @param templateConfig The URL location (preferrable encrypted IPFS hash or Hoard grant) to the JSON
     * encoded parameters to be used with the template ID
     * @param activated Whether the beacon should be turned on or off
     *
     * Emits a {LogBeaconStatusChange} event.
     *
     * Requirements:
     * - requester must have the same address as that which initially requested activation
     * - the {AGREEMENT_BEACON_PRICE} must accompany any calls
     */
    function requestUpdateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig,
        bool activated
    ) external payable;

    /**
     * @dev Handles the request to create an agreement based the template established by a beacon creator.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param accepters The addresses of those accepting the terms of the token as established by the creator
     *
     * Emits {LogRequestCreateAgreement} events (one per accepting party).
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     * - the {AGREEMENT_BEACON_PRICE} must accompany any calls
     */
    function requestCreateAgreement(
        address tokenContractAddress,
        uint256 tokenId,
        address[] memory accepters
    ) external payable;

    /**
     * @dev Handles the logging of state changes to the agreements between the parties.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param accepter The address of those accepting the terms of the token as established by the creator
     * @param agreement The address (within the agreement zone) of the agreement between the creator and
     * the accepter
     * @param state The {LegalState} of the agreement
     * @param errorCode Any error code exhibited by the beacon creating the agreement within the agreements
     * zone (generally follows HTTP error codes)
     *
     * Emits a {LogAgreementStatus} event.
     *
     * Requirements:
     * - only addresses which have the correct roles may call this function
     */
    function reportAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter,
        address agreement,
        LegalState state,
        string memory errorCode
    ) external;

    /**
     * @dev Retrieves the legalURL for the agreement beacon.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     *
     */
    function getBeaconURL(address tokenContractAddress, uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @dev Retrieves the address of the creator of the agreement beacon.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     *
     */
    function getBeaconCreator(address tokenContractAddress, uint256 tokenId)
        external
        view
        returns (address creator);

    /**
     * @dev Retrieves the address of the creator of the agreement beacon.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param accepter The address of those accepting the terms of the token as established by the creator
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     *
     */
    function getAgreementId(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) external view returns (address agreement);

    /**
     * @dev Retrieves the {LegalState} of the agreement between the creator and accepter known to the]
     * agreement beacon.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param accepter The address of those accepting the terms of the token as established by the creator
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     *
     */
    function getAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) external view returns (LegalState state);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}