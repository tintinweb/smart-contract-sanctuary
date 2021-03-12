/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity 0.5.15;

contract IAugur {
    IUniverse public genesisUniverse;
    function createChildUniverse(bytes32 _parentPayoutDistributionHash, uint256[] memory _parentPayoutNumerators) public returns (IUniverse);
    function isKnownUniverse(IUniverse _universe) public view returns (bool);
    function trustedCashTransfer(address _from, address _to, uint256 _amount) public returns (bool);
    function isTrustedSender(address _address) public returns (bool);
    function onCategoricalMarketCreated(uint256 _endTime, string memory _extraInfo, IMarket _market, address _marketCreator, address _designatedReporter, uint256 _feePerCashInAttoCash, bytes32[] memory _outcomes) public returns (bool);
    function onYesNoMarketCreated(uint256 _endTime, string memory _extraInfo, IMarket _market, address _marketCreator, address _designatedReporter, uint256 _feePerCashInAttoCash) public returns (bool);
    function onScalarMarketCreated(uint256 _endTime, string memory _extraInfo, IMarket _market, address _marketCreator, address _designatedReporter, uint256 _feePerCashInAttoCash, int256[] memory _prices, uint256 _numTicks)  public returns (bool);
    function logInitialReportSubmitted(IUniverse _universe, address _reporter, address _market, address _initialReporter, uint256 _amountStaked, bool _isDesignatedReporter, uint256[] memory _payoutNumerators, string memory _description, uint256 _nextWindowStartTime, uint256 _nextWindowEndTime) public returns (bool);
    function disputeCrowdsourcerCreated(IUniverse _universe, address _market, address _disputeCrowdsourcer, uint256[] memory _payoutNumerators, uint256 _size, uint256 _disputeRound) public returns (bool);
    function logDisputeCrowdsourcerContribution(IUniverse _universe, address _reporter, address _market, address _disputeCrowdsourcer, uint256 _amountStaked, string memory description, uint256[] memory _payoutNumerators, uint256 _currentStake, uint256 _stakeRemaining, uint256 _disputeRound) public returns (bool);
    function logDisputeCrowdsourcerCompleted(IUniverse _universe, address _market, address _disputeCrowdsourcer, uint256[] memory _payoutNumerators, uint256 _nextWindowStartTime, uint256 _nextWindowEndTime, bool _pacingOn, uint256 _totalRepStakedInPayout, uint256 _totalRepStakedInMarket, uint256 _disputeRound) public returns (bool);
    function logInitialReporterRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256[] memory _payoutNumerators) public returns (bool);
    function logDisputeCrowdsourcerRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256[] memory _payoutNumerators) public returns (bool);
    function logMarketFinalized(IUniverse _universe, uint256[] memory _winningPayoutNumerators) public returns (bool);
    function logMarketMigrated(IMarket _market, IUniverse _originalUniverse) public returns (bool);
    function logReportingParticipantDisavowed(IUniverse _universe, IMarket _market) public returns (bool);
    function logMarketParticipantsDisavowed(IUniverse _universe) public returns (bool);
    function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public returns (bool);
    function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets, uint256 _fees) public returns (bool);
    function logMarketOIChanged(IUniverse _universe, IMarket _market) public returns (bool);
    function logTradingProceedsClaimed(IUniverse _universe, address _sender, address _market, uint256 _outcome, uint256 _numShares, uint256 _numPayoutTokens, uint256 _fees) public returns (bool);
    function logUniverseForked(IMarket _forkingMarket) public returns (bool);
    function logReputationTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value, uint256 _fromBalance, uint256 _toBalance) public returns (bool);
    function logReputationTokensBurned(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logReputationTokensMinted(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logShareTokensBalanceChanged(address _account, IMarket _market, uint256 _outcome, uint256 _balance) public returns (bool);
    function logDisputeCrowdsourcerTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value, uint256 _fromBalance, uint256 _toBalance) public returns (bool);
    function logDisputeCrowdsourcerTokensBurned(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logDisputeCrowdsourcerTokensMinted(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logDisputeWindowCreated(IDisputeWindow _disputeWindow, uint256 _id, bool _initial) public returns (bool);
    function logParticipationTokensRedeemed(IUniverse universe, address _sender, uint256 _attoParticipationTokens, uint256 _feePayoutShare) public returns (bool);
    function logTimestampSet(uint256 _newTimestamp) public returns (bool);
    function logInitialReporterTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool);
    function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool);
    function logParticipationTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value, uint256 _fromBalance, uint256 _toBalance) public returns (bool);
    function logParticipationTokensBurned(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logParticipationTokensMinted(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logMarketRepBondTransferred(address _universe, address _from, address _to) public returns (bool);
    function logWarpSyncDataUpdated(address _universe, uint256 _warpSyncHash, uint256 _marketEndTime) public returns (bool);
    function isKnownFeeSender(address _feeSender) public view returns (bool);
    function lookup(bytes32 _key) public view returns (address);
    function getTimestamp() public view returns (uint256);
    function getMaximumMarketEndDate() public returns (uint256);
    function isKnownMarket(IMarket _market) public view returns (bool);
    function derivePayoutDistributionHash(uint256[] memory _payoutNumerators, uint256 _numTicks, uint256 numOutcomes) public view returns (bytes32);
    function logValidityBondChanged(uint256 _validityBond) public returns (bool);
    function logDesignatedReportStakeChanged(uint256 _designatedReportStake) public returns (bool);
    function logNoShowBondChanged(uint256 _noShowBond) public returns (bool);
    function logReportingFeeChanged(uint256 _reportingFee) public returns (bool);
    function getUniverseForkIndex(IUniverse _universe) public view returns (uint256);
    function getMarketType(IMarket _market) public view returns (IMarket.MarketType);
    function getMarketOutcomes(IMarket _market) public view returns (bytes32[] memory _outcomes);
    ICash public cash;
}

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
        (bool success, ) = recipient.call.value(amount)("");
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
        (bool success, bytes memory returndata) = target.call.value(value)(data);
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

library ContractExists {
    function exists(address _address) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }
}

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

contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract IOwnable {
    function getOwner() public view returns (address);
    function transferOwnership(address _newOwner) public returns (bool);
}

contract ITyped {
    function getTypeName() public view returns (bytes32);
}

contract Initializable {
    bool private initialized = false;

    modifier beforeInitialized {
        require(!initialized, "contract is already initialized");
        _;
    }

    function endInitialization() internal beforeInitialized {
        initialized = true;
    }

    function getInitialized() public view returns (bool) {
        return initialized;
    }
}

contract ReentrancyGuard {
    /**
     * @dev We use a single lock for the whole contract.
     */
    bool private rentrancyLock = false;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * @notice If you mark a function `nonReentrant`, you should also mark it `external`. Calling one nonReentrant function from another is not supported. Instead, you can implement a `private` function doing the actual work, and a `external` wrapper marked as `nonReentrant`.
     */
    modifier nonReentrant() {
        require(!rentrancyLock);
        rentrancyLock = true;
        _;
        rentrancyLock = false;
    }
}

library TokenId {

    function getTokenId(address _market, uint256 _outcome) internal pure returns (uint256 _tokenId) {
        return getTokenId(IMarket(_market), _outcome);
    }

    function getTokenId(IMarket _market, uint256 _outcome) internal pure returns (uint256 _tokenId) {
        bytes memory _tokenIdBytes = abi.encodePacked(_market, uint8(_outcome));
        assembly {
            _tokenId := mload(add(_tokenIdBytes, add(0x20, 0)))
        }
    }

    function getTokenIds(address _market, uint256[] memory _outcomes) internal pure returns (uint256[] memory _tokenIds) {
        return getTokenIds(IMarket(_market), _outcomes);
    }

    function getTokenIds(IMarket _market, uint256[] memory _outcomes) internal pure returns (uint256[] memory _tokenIds) {
        _tokenIds = new uint256[](_outcomes.length);
        for (uint256 _i = 0; _i < _outcomes.length; _i++) {
            _tokenIds[_i] = getTokenId(_market, _outcomes[_i]);
        }
    }

    function unpackTokenId(uint256 _tokenId) internal pure returns (address _market, uint256 _outcome) {
        assembly {
            _market := shr(96,  and(_tokenId, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000))
            _outcome := shr(88, and(_tokenId, 0x0000000000000000000000000000000000000000FF0000000000000000000000))
        }
    }
}

library SafeMathUint256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function subS(uint256 a, uint256 b, string memory message) internal pure returns (uint256) {
        require(b <= a, message);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            uint256 x = (y + 1) / 2;
            z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getUint256Min() internal pure returns (uint256) {
        return 0;
    }

    function getUint256Max() internal pure returns (uint256) {
        // 2 ** 256 - 1
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
        return a % b == 0;
    }

    // Float [fixed point] Operations
    function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, base), b);
    }
}

interface IERC1155 {

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    /// Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define a token ID with no initial balance, the contract SHOULD emit the TransferSingle event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    ///Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /// @dev MUST emit when an approval is updated.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @dev MUST emit when the URI is updated for a token ID.
    /// URIs are defined in RFC 3986.
    /// The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    event URI(
        string value,
        uint256 indexed id
    );

    /// @notice Transfers value amount of an _id from the _from address to the _to address specified.
    /// @dev MUST emit TransferSingle event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if balance of sender for token `_id` is lower than the `_value` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155Received` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external;

    /// @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
    /// @dev MUST emit TransferBatch event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if length of `_ids` is not the same as length of `_values`.
    ///  MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_values` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
    /// @param from    Source addresses
    /// @param to      Target addresses
    /// @param ids     IDs of each token type
    /// @param values  Transfer amounts per token type
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external;

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param owner     The owner of the Tokens
    /// @param operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Get the balance of an account's Tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the Token
    /// @return        The _owner's balance of the Token type requested
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /// @notice Get the total supply of a Token.
    /// @param id     ID of the Token
    /// @return        The total supply of the Token type requested
    function totalSupply(uint256 id) external view returns (uint256);

    /// @notice Get the balance of multiple account/token pairs
    /// @param owners The addresses of the token holders
    /// @param ids    ID of the Tokens
    /// @return        The _owner's balance of the Token types requested
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    )
        external
        view
        returns (uint256[] memory balances_);
}

contract ERC1155 is ERC165, IERC1155 {
    using SafeMathUint256 for uint256;
    using ContractExists for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) public _balances;

    // Mapping from token ID to total supply
    mapping (uint256 => uint256) public _supplys;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) public _operatorApprovals;

    constructor()
        public
    {
        _registerInterface(
            ERC1155(0).safeTransferFrom.selector ^
            ERC1155(0).safeBatchTransferFrom.selector ^
            ERC1155(0).balanceOf.selector ^
            ERC1155(0).balanceOfBatch.selector ^
            ERC1155(0).setApprovalForAll.selector ^
            ERC1155(0).isApprovedForAll.selector
        );
    }

    /**
        @dev Get the specified address' balance for token with specified ID.

        Attempting to query the zero account for a balance will result in a revert.

        @param account The address of the token holder
        @param id ID of the token
        @return The account's balance of the token type requested
     */
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _supplys[id];
    }

    /**
        @dev Get the balance of multiple account/token pairs.

        If any of the query accounts is the zero account, this query will revert.

        @param accounts The addresses of the token holders
        @param ids IDs of the tokens
        @return Balances for each account and token id pair
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and IDs must have same lengths");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: some address in batch balance query is zero");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev Sets or unsets the approval of a given operator.
     *
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     *
     * Because an account already has operator privileges for itself, this function will revert
     * if the account attempts to set the approval status for itself.
     *
     * @param operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(msg.sender != operator, "ERC1155: cannot set approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
        @notice Queries the approval status of an operator for a given account.
        @param account   The account of the Tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return operator == address(this) || _operatorApprovals[account][operator];
    }

    /**
        @dev Transfers `value` amount of an `id` from the `from` address to the `to` address specified.
        Caller must be approved to manage the tokens being transferred out of the `from` account.
        If `to` is a smart contract, will call `onERC1155Received` on `to` and act appropriately.
        @param from Source address
        @param to Target address
        @param id ID of the token type
        @param value Transfer amount
        @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
    {
        _transferFrom(from, to, id, value, data, true);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool doAcceptanceCheck
    )
        internal
    {
        require(to != address(0), "ERC1155: target address must be non-zero");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) == true,
            "ERC1155: need operator approval for 3rd party transfers"
        );

        _internalTransferFrom(from, to, id, value, data, doAcceptanceCheck);
    }

    function _internalTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool doAcceptanceCheck
    )
        internal
    {
        _balances[id][from] = _balances[id][from].sub(value);
        _balances[id][to] = _balances[id][to].add(value);

        onTokenTransfer(id, from, to, value);
        emit TransferSingle(msg.sender, from, to, id, value);

        if (doAcceptanceCheck) {
            _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, value, data);
        }
    }

    /**
        @dev Transfers `values` amount(s) of `ids` from the `from` address to the
        `to` address specified. Caller must be approved to manage the tokens being
        transferred out of the `from` account. If `to` is a smart contract, will
        call `onERC1155BatchReceived` on `to` and act appropriately.
        @param from Source address
        @param to Target address
        @param ids IDs of each token type
        @param values Transfer amounts per token type
        @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
    {
        _batchTransferFrom(from, to, ids, values, data, true);
    }

    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data,
        bool doAcceptanceCheck
    )
        internal
    {
        require(ids.length == values.length, "ERC1155: IDs and values must have same lengths");
        if (ids.length == 0) {
            return;
        }
        require(to != address(0), "ERC1155: target address must be non-zero");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) == true,
            "ERC1155: need operator approval for 3rd party transfers"
        );

        _internalBatchTransferFrom(from, to, ids, values, data, doAcceptanceCheck);
    }

    function _internalBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data,
        bool doAcceptanceCheck
    )
        internal
    {
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];

            _balances[id][from] = _balances[id][from].sub(value);
            _balances[id][to] = _balances[id][to].add(value);
            onTokenTransfer(id, from, to, value);
        }

        emit TransferBatch(msg.sender, from, to, ids, values);

        if (doAcceptanceCheck) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, values, data);
        }
    }

    /**
     * @dev Internal function to mint an amount of a token with the given ID
     * @param to The address that will own the minted token
     * @param id ID of the token to be minted
     * @param value Amount of the token to be minted
     * @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
     */
    function _mint(address to, uint256 id, uint256 value, bytes memory data, bool doAcceptanceCheck) internal {
        require(to != address(0), "ERC1155: mint to the zero address");

        _balances[id][to] = _balances[id][to].add(value);
        _supplys[id] = _supplys[id].add(value);

        onMint(id, to, value);
        emit TransferSingle(msg.sender, address(0), to, id, value);

        if (doAcceptanceCheck) {
            _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, id, value, data);
        }
    }

    /**
     * @dev Internal function to batch mint amounts of tokens with the given IDs
     * @param to The address that will own the minted token
     * @param ids IDs of the tokens to be minted
     * @param values Amounts of the tokens to be minted
     * @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data, bool doAcceptanceCheck) internal {
        require(to != address(0), "ERC1155: batch mint to the zero address");
        require(ids.length == values.length, "ERC1155: minted IDs and values must have same lengths");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = values[i].add(_balances[ids[i]][to]);
            _supplys[ids[i]] = _supplys[ids[i]].add(values[i]);
            onMint(ids[i], to, values[i]);
        }

        emit TransferBatch(msg.sender, address(0), to, ids, values);

        if (doAcceptanceCheck) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, ids, values, data);
        }
    }

    /**
     * @dev Internal function to burn an amount of a token with the given ID
     * @param account Account which owns the token to be burnt
     * @param id ID of the token to be burnt
     * @param value Amount of the token to be burnt
     */
    function _burn(address account, uint256 id, uint256 value, bytes memory data, bool doAcceptanceCheck) internal {
        require(account != address(0), "ERC1155: attempting to burn tokens on zero account");

        _balances[id][account] = _balances[id][account].sub(value);
        _supplys[id] = _supplys[id].sub(value);
        onBurn(id, account, value);
        emit TransferSingle(msg.sender, account, address(0), id, value);

        if (doAcceptanceCheck) {
            _doSafeTransferAcceptanceCheck(msg.sender, account, address(0), id, value, data);
        }
    }

    /**
     * @dev Internal function to batch burn an amounts of tokens with the given IDs
     * @param account Account which owns the token to be burnt
     * @param ids IDs of the tokens to be burnt
     * @param values Amounts of the tokens to be burnt
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory values, bytes memory data, bool doAcceptanceCheck) internal {
        require(account != address(0), "ERC1155: attempting to burn batch of tokens on zero account");
        require(ids.length == values.length, "ERC1155: burnt IDs and values must have same lengths");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(values[i]);
            _supplys[ids[i]] = _supplys[ids[i]].sub(values[i]);
            onBurn(ids[i], account, values[i]);
        }

        emit TransferBatch(msg.sender, account, address(0), ids, values);

        if (doAcceptanceCheck) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, account, address(0), ids, values, data);
        }
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    )
        internal
    {
        if (to.exists()) {
            require(
                IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) ==
                    IERC1155Receiver(to).onERC1155Received.selector,
                "ERC1155: got unknown value from onERC1155Received"
            );
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    )
        internal
    {
        if (to.exists()) {
            require(
                IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data) ==
                    IERC1155Receiver(to).onERC1155BatchReceived.selector,
                "ERC1155: got unknown value from onERC1155BatchReceived"
            );
        }
    }

    // Subclasses of this token generally want to send additional logs through the centralized Augur log emitter contract
    function onTokenTransfer(uint256 _tokenId, address _from, address _to, uint256 _value) internal;

    // Subclasses of this token may want to send additional logs through the centralized Augur log emitter contract
    function onMint(uint256 _tokenId, address _target, uint256 _amount) internal;

    // Subclasses of this token may want to send additional logs through the centralized Augur log emitter contract
    function onBurn(uint256 _tokenId, address _target, uint256 _amount) internal;
}

contract ParaShareToken is ITyped, Initializable, ERC1155, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IParaAugur public augur;
    IERC20 public cash;
    ShareToken public originalShareToken;

    uint256 private constant MAX_APPROVAL_AMOUNT = 2 ** 256 - 1;

    string constant public name = "Shares";
    string constant public symbol = "SHARE";

    struct MarketData {
        uint256 numOutcomes;
        uint256 numTicks;
    }

    mapping(address => MarketData) markets;

    function initialize(address _augur, ShareToken _originalShareToken) external beforeInitialized {
        endInitialization();
        augur = IParaAugur(_augur);
        originalShareToken = _originalShareToken;
        cash = IERC20(IParaAugur(_augur).lookup("Cash"));

        require(cash != IERC20(0));
    }

    function approveUniverse(IParaUniverse _paraUniverse) external {
        require(msg.sender == address(augur));
        cash.safeApprove(address(_paraUniverse), MAX_APPROVAL_AMOUNT);
        cash.safeApprove(address(_paraUniverse.getFeePot()), MAX_APPROVAL_AMOUNT);
    }

    /**
        @dev Transfers `value` amount of an `id` from the `from` address to the `to` address specified.
        Caller must be approved to manage the tokens being transferred out of the `from` account.
        Regardless of if the desintation is a contract or not this will not call `onERC1155Received` on `to`
        @param _from Source address
        @param _to Target address
        @param _id ID of the token type
        @param _value Transfer amount
    */
    function unsafeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) external {
        _transferFrom(_from, _to, _id, _value, bytes(""), false);
    }

    /**
        @dev Transfers `values` amount(s) of `ids` from the `from` address to the
        `to` address specified. Caller must be approved to manage the tokens being
        transferred out of the `from` account. Regardless of if the desintation is
        a contract or not this will not call `onERC1155Received` on `to`
        @param _from Source address
        @param _to Target address
        @param _ids IDs of each token type
        @param _values Transfer amounts per token type
    */
    function unsafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external {
        _batchTransferFrom(_from, _to, _ids, _values, bytes(""), false);
    }

    // initializeMarket which looks at the market to get data
    function initializeMarket(IMarket _market) public {
        require(augur.isKnownMarket(_market));
        markets[address(_market)].numOutcomes = _market.getNumberOfOutcomes();
        markets[address(_market)].numTicks = _market.getNumTicks();
    }

    function isMarketInitialized(IMarket _market) public view returns (bool) {
        return markets[address(_market)].numTicks != 0;
    }

    /**
     * @notice Buy some amount of complete sets for a market
     * @param _market The market to purchase complete sets in
     * @param _amount The number of complete sets to purchase
     * @return Bool True
     */
    function publicBuyCompleteSets(IMarket _market, uint256 _amount) external returns (bool) {
        buyCompleteSetsInternal(_market, msg.sender, _amount);
        augur.logCompleteSetsPurchased(_market.getUniverse(), _market, msg.sender, _amount);
        return true;
    }

    /**
     * @notice Buy some amount of complete sets for a market
     * @param _market The market to purchase complete sets in
     * @param _account The account receiving the complete sets
     * @param _amount The number of complete sets to purchase
     * @return Bool True
     */
    function buyCompleteSets(IMarket _market, address _account, uint256 _amount) external returns (bool) {
        buyCompleteSetsInternal(_market, _account, _amount);
        return true;
    }

    function buyCompleteSetsInternal(IMarket _market, address _account, uint256 _amount) internal returns (bool) {
        uint256 _numTicks = markets[address(_market)].numTicks;
        if (_numTicks == 0) { // !isMarketInitialized(_market)
            initializeMarket(_market);
            _numTicks = markets[address(_market)].numTicks;
        }

        uint256 _numOutcomes = markets[address(_market)].numOutcomes;

        require(_numOutcomes != 0, "Invalid Market provided");

        IUniverse _universe = _market.getUniverse();
        IParaUniverse _paraUniverse = IParaUniverse(IParaAugur(address(augur)).getParaUniverse(address(_market.getUniverse())));

        uint256 _cost = _amount.mul(_numTicks);

        _paraUniverse.deposit(msg.sender, _cost, address(_market));

        uint256[] memory _tokenIds = new uint256[](_numOutcomes);
        uint256[] memory _values = new uint256[](_numOutcomes);

        for (uint256 _i = 0; _i < _numOutcomes; _i++) {
            _tokenIds[_i] = TokenId.getTokenId(_market, _i);
            _values[_i] = _amount;
        }

        if (!_market.isFinalized()) {
            _paraUniverse.incrementOpenInterest(_cost);
        } else {
            _paraUniverse.setMarketFinalized(_market, totalSupplyForMarketOutcome(_market, 0));
        }

        _mintBatch(_account, _tokenIds, _values, bytes(""), false);

        augur.logMarketOIChanged(_universe, _market);
        return true;
    }

    /**
     * @notice Buy some amount of complete sets for a market and distribute the shares according to the positions of two accounts
     * @param _market The market to purchase complete sets in
     * @param _amount The number of complete sets to purchase
     * @param _longOutcome The outcome for the trade being fulfilled
     * @param _longRecipient The account which should recieve the _longOutcome shares
     * @param _shortRecipient The account which should recieve shares of every outcome other than _longOutcome
     * @return Bool True
     */
    function buyCompleteSetsForTrade(IMarket _market, uint256 _amount, uint256 _longOutcome, address _longRecipient, address _shortRecipient) external returns (bool) {
        uint256 _numTicks = markets[address(_market)].numTicks;
        if (_numTicks == 0) { // !isMarketInitialized(_market)
            initializeMarket(_market);
            _numTicks = markets[address(_market)].numTicks;
        }

        uint256 _numOutcomes = markets[address(_market)].numOutcomes;
        require(_numOutcomes != 0, "Invalid Market provided");
        require(_longOutcome < _numOutcomes);

        IUniverse _universe = _market.getUniverse();
        IParaUniverse _paraUniverse = IParaUniverse(IParaAugur(address(augur)).getParaUniverse(address(_market.getUniverse())));

        {
            uint256 _cost = _amount.mul(_numTicks);
            _paraUniverse.deposit(msg.sender, _cost, address(_market));

            if (!_market.isFinalized()) {
                _paraUniverse.incrementOpenInterest(_cost);
            } else {
                _paraUniverse.setMarketFinalized(_market, totalSupplyForMarketOutcome(_market, 0));
            }
        }

        uint256[] memory _tokenIds = new uint256[](_numOutcomes - 1);
        uint256[] memory _values = new uint256[](_numOutcomes - 1);
        uint256 _outcome = 0;

        for (uint256 _i = 0; _i < _numOutcomes - 1; _i++) {
            if (_outcome == _longOutcome) {
                _outcome++;
            }
            _tokenIds[_i] = TokenId.getTokenId(_market, _outcome);
            _values[_i] = _amount;
            _outcome++;
        }

        _mintBatch(_shortRecipient, _tokenIds, _values, bytes(""), false);
        _mint(_longRecipient, TokenId.getTokenId(_market, _longOutcome), _amount, bytes(""), false);

        augur.logMarketOIChanged(_universe, _market);
        return true;
    }

    /**
     * @notice Sell some amount of complete sets for a market
     * @param _market The market to sell complete sets in
     * @param _amount The number of complete sets to sell
     * @return (uint256 _creatorFee, uint256 _reportingFee) The fees taken for the market creator and reporting respectively
     */
    function publicSellCompleteSets(IMarket _market, uint256 _amount) external returns (uint256 _creatorFee, uint256 _reportingFee) {
        uint256 _payout;
        (_payout, _creatorFee, _reportingFee) = burnCompleteSets(_market, msg.sender, _amount, msg.sender, bytes32(0));

        require(cash.transfer(msg.sender, _payout));

        IUniverse _universe = _market.getUniverse();
        augur.logCompleteSetsSold(_universe, _market, msg.sender, _amount, _creatorFee.add(_reportingFee));
    }

    /**
     * @notice Sell some amount of complete sets for a market
     * @param _market The market to sell complete sets in
     * @param _holder The holder of the complete sets
     * @param _recipient The recipient of funds from the sale
     * @param _amount The number of complete sets to sell
     * @param _fingerprint Fingerprint of the filler used to naively restrict affiliate fee dispursement
     * @return (uint256 _creatorFee, uint256 _reportingFee) The fees taken for the market creator and reporting respectively
     */
    function sellCompleteSets(IMarket _market, address _holder, address _recipient, uint256 _amount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee) {
        require(_holder == msg.sender || isApprovedForAll(_holder, msg.sender) == true, "ERC1155: need operator approval to sell complete sets");

        uint256 _payout;
        (_payout, _creatorFee, _reportingFee) = burnCompleteSets(_market, _holder, _amount, _holder, _fingerprint);

        require(cash.transfer(_recipient, _payout));
    }

    /**
     * @notice Sell some amount of complete sets for a market
     * @param _market The market to sell complete sets in
     * @param _amount The number of complete sets to sell
     * @param _shortParticipant The account which should provide the short party portion of shares
     * @param _longParticipant The account which should provide the long party portion of shares
     * @param _longRecipient The account which should receive the remaining payout for providing the matching shares to the short recipients shares
     * @param _shortRecipient The account which should recieve the (price * shares provided) payout for selling their side of the sale
     * @param _price The price of the trade being done. This determines how much each recipient recieves from the sale proceeds
     * @param _fingerprint Fingerprint of the filler used to naively restrict affiliate fee dispursement
     * @return (uint256 _creatorFee, uint256 _reportingFee) The fees taken for the market creator and reporting respectively
     */
    function sellCompleteSetsForTrade(IMarket _market, uint256 _outcome, uint256 _amount, address _shortParticipant, address _longParticipant, address _shortRecipient, address _longRecipient, uint256 _price, address _sourceAccount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee) {
        require(isApprovedForAll(_shortParticipant, msg.sender) == true, "ERC1155: need operator approval to burn short account shares");
        require(isApprovedForAll(_longParticipant, msg.sender) == true, "ERC1155: need operator approval to burn long account shares");

        _internalTransferFrom(_shortParticipant, _longParticipant, getTokenId(_market, _outcome), _amount, bytes(""), false);

        // NOTE: burnCompleteSets will validate the market provided is legitimate
        uint256 _payout;
        (_payout, _creatorFee, _reportingFee) = burnCompleteSets(_market, _longParticipant, _amount, _sourceAccount, _fingerprint);

        {
            uint256 _longPayout = _payout.mul(_price) / _market.getNumTicks();
            require(cash.transfer(_longRecipient, _longPayout));
            require(cash.transfer(_shortRecipient, _payout.sub(_longPayout)));
        }
    }

    function burnCompleteSets(IMarket _market, address _account, uint256 _amount, address _sourceAccount, bytes32 _fingerprint) private returns (uint256 _payout, uint256 _creatorFee, uint256 _reportingFee) {
        _fingerprint;

        uint256 _numTicks = markets[address(_market)].numTicks;
        if (_numTicks == 0) { // !isMarketInitialized(_market)
            initializeMarket(_market);
            _numTicks = markets[address(_market)].numTicks;
        }

        uint256 _numOutcomes = markets[address(_market)].numOutcomes;

        require(_numOutcomes != 0, "Invalid Market provided");

        // solium-disable indentation
        {
            uint256[] memory _tokenIds = new uint256[](_numOutcomes);
            uint256[] memory _values = new uint256[](_numOutcomes);

            for (uint256 i = 0; i < _numOutcomes; i++) {
                _tokenIds[i] = TokenId.getTokenId(_market, i);
                _values[i] = _amount;
            }

            _burnBatch(_account, _tokenIds, _values, bytes(""), false);
        }
        // solium-enable indentation

        _payout = _amount.mul(_numTicks);
        IUniverse _universe = _market.getUniverse();
        IParaUniverse _paraUniverse = IParaUniverse(IParaAugur(address(augur)).getParaUniverse(address(_universe)));

        if (!_market.isFinalized()) {
            _paraUniverse.decrementOpenInterest(_payout);
        }

        _creatorFee = _market.deriveMarketCreatorFeeAmount(_payout);
        _reportingFee = _payout.div(_paraUniverse.getOrCacheReportingFeeDivisor());
        _payout = _payout.sub(_creatorFee).sub(_reportingFee);

        if (_creatorFee != 0) {
            _paraUniverse.recordMarketCreatorFees(_market, _creatorFee, _sourceAccount);
        }

        _paraUniverse.withdraw(address(this), _payout.add(_reportingFee), address(_market));

        if (_reportingFee != 0) {
            _paraUniverse.getFeePot().depositFees(_reportingFee);
        }

        augur.logMarketOIChanged(_universe, _market);
    }

    /**
     * @notice Claims winnings for a market and for a particular shareholder
     * @param _market The market to claim winnings for
     * @param _shareHolder The account to claim winnings for
     * @param _fingerprint Fingerprint of the filler used to naively restrict affiliate fee dispursement
     * @return Bool True
     */
    function claimTradingProceeds(IMarket _market, address _shareHolder, bytes32 _fingerprint) external nonReentrant returns (uint256[] memory _outcomeFees) {
        return claimTradingProceedsInternal(_market, _shareHolder, _fingerprint);
    }

    function claimTradingProceedsInternal(IMarket _market, address _shareHolder, bytes32 _fingerprint) internal returns (uint256[] memory _outcomeFees) {
        _fingerprint;
        require(augur.isKnownMarket(_market));
        IParaUniverse _paraUniverse = IParaUniverse(IParaAugur(address(augur)).getParaUniverse(address(_market.getUniverse())));
        if (!_market.isFinalized()) {
            _market.finalize();
        }

        _paraUniverse.setMarketFinalized(_market, totalSupplyForMarketOutcome(_market, 0));
        _outcomeFees = new uint256[](8);
        for (uint256 _outcome = 0; _outcome < _market.getNumberOfOutcomes(); ++_outcome) {
            uint256 _tokenId = TokenId.getTokenId(_market, _outcome);
            uint256 _numberOfShares = balanceOf(_shareHolder, _tokenId);

            if (_numberOfShares > 0) {
                uint256 _proceeds;
                uint256 _shareHolderShare;
                uint256 _creatorShare;
                uint256 _reporterShare;
                (_proceeds, _shareHolderShare, _creatorShare, _reporterShare) = divideUpWinnings(_market, _paraUniverse, _outcome, _numberOfShares);

                // always destroy shares as it gives a minor gas refund and is good for the network
                _burn(_shareHolder, _tokenId, _numberOfShares, bytes(""), false);
                logTradingProceedsClaimed(_market, _outcome, _shareHolder, _numberOfShares, _shareHolderShare, _creatorShare.add(_reporterShare));

                if (_proceeds > 0) {
                    _paraUniverse.withdraw(address(this), _shareHolderShare.add(_reporterShare), address(_market));
                    distributeProceeds(_market, _paraUniverse, _shareHolder, _shareHolderShare, _creatorShare, _reporterShare);
                }
                _outcomeFees[_outcome] = _creatorShare.add(_reporterShare);
            }
        }
        return _outcomeFees;
    }

    function distributeProceeds(IMarket _market, IParaUniverse _paraUniverse, address _shareHolder, uint256 _shareHolderShare, uint256 _creatorShare, uint256 _reporterShare) private {
        if (_shareHolderShare > 0) {
            require(cash.transfer(_shareHolder, _shareHolderShare));
        }
        if (_creatorShare > 0) {
            _paraUniverse.recordMarketCreatorFees(_market, _creatorShare, _shareHolder);
        }
        if (_reporterShare > 0) {
            _paraUniverse.getFeePot().depositFees(_reporterShare);
        }
    }

    function logTradingProceedsClaimed(IMarket _market, uint256 _outcome, address _sender, uint256 _numShares, uint256 _numPayoutTokens, uint256 _fees) private {
        augur.logTradingProceedsClaimed(_market.getUniverse(), _sender, address(_market), _outcome, _numShares, _numPayoutTokens, _fees);
    }

    function divideUpWinnings(IMarket _market, IParaUniverse _paraUniverse, uint256 _outcome, uint256 _numberOfShares) public returns (uint256 _proceeds, uint256 _shareHolderShare, uint256 _creatorShare, uint256 _reporterShare) {
        _proceeds = calculateProceeds(_market, _outcome, _numberOfShares);
        _creatorShare = calculateCreatorFee(_market, _proceeds);
        _reporterShare = calculateReportingFee(_paraUniverse, _proceeds);
        _shareHolderShare = _proceeds.sub(_creatorShare).sub(_reporterShare);
    }

    function calculateProceeds(IMarket _market, uint256 _outcome, uint256 _numberOfShares) public view returns (uint256) {
        uint256 _payoutNumerator = _market.getWinningPayoutNumerator(_outcome);
        return _numberOfShares.mul(_payoutNumerator);
    }

    function calculateReportingFee(IParaUniverse _paraUniverse, uint256 _amount) public returns (uint256) {
        uint256 _reportingFeeDivisor = _paraUniverse.getOrCacheReportingFeeDivisor();
        return _amount.div(_reportingFeeDivisor);
    }

    function calculateCreatorFee(IMarket _market, uint256 _amount) public view returns (uint256) {
        return _market.deriveMarketCreatorFeeAmount(_amount);
    }

    function getTypeName() public view returns(bytes32) {
        return "ShareToken";
    }

    /**
     * @return The market associated with this Share Token ID
     */
    function getMarket(uint256 _tokenId) external pure returns(IMarket) {
        (address _market, ) = TokenId.unpackTokenId(_tokenId);
        return IMarket(_market);
    }

    /**
     * @return The outcome associated with this Share Token ID
     */
    function getOutcome(uint256 _tokenId) external pure returns(uint256) {
        (, uint256 _outcome) = TokenId.unpackTokenId(_tokenId);
        return _outcome;
    }

    function totalSupplyForMarketOutcome(IMarket _market, uint256 _outcome) public view returns (uint256) {
        uint256 _tokenId = TokenId.getTokenId(_market, _outcome);
        return totalSupply(_tokenId);
    }

    function balanceOfMarketOutcome(IMarket _market, uint256 _outcome, address _account) public view returns (uint256) {
        uint256 _tokenId = TokenId.getTokenId(_market, _outcome);
        return balanceOf(_account, _tokenId);
    }

    function lowestBalanceOfMarketOutcomes(IMarket _market, uint256[] memory _outcomes, address _account) public view returns (uint256) {
        uint256 _lowest = SafeMathUint256.getUint256Max();
        for (uint256 _i = 0; _i < _outcomes.length; ++_i) {
            uint256 _tokenId = TokenId.getTokenId(_market, _outcomes[_i]);
            _lowest = balanceOf(_account, _tokenId).min(_lowest);
        }
        return _lowest;
    }

    function getTokenId(IMarket _market, uint256 _outcome) public pure returns (uint256 _tokenId) {
        return TokenId.getTokenId(_market, _outcome);
    }

    function getTokenIds(IMarket _market, uint256[] calldata _outcomes) external pure returns (uint256[] memory _tokenIds) {
        return TokenId.getTokenIds(_market, _outcomes);
    }

    function unpackTokenId(uint256 _tokenId) external pure returns (address _market, uint256 _outcome) {
        return TokenId.unpackTokenId(_tokenId);
    }

    function onTokenTransfer(uint256 _tokenId, address _from, address _to, uint256 _value) internal {
        _value;
        (address _marketAddress, uint256 _outcome) = TokenId.unpackTokenId(_tokenId);
        augur.logShareTokensBalanceChanged(_from, IMarket(_marketAddress), _outcome, balanceOf(_from, _tokenId));
        augur.logShareTokensBalanceChanged(_to, IMarket(_marketAddress), _outcome, balanceOf(_to, _tokenId));
    }

    function onMint(uint256 _tokenId, address _target, uint256 _amount) internal {
        _amount;
        (address _marketAddress, uint256 _outcome) = TokenId.unpackTokenId(_tokenId);
        augur.logShareTokensBalanceChanged(_target, IMarket(_marketAddress), _outcome, balanceOf(_target, _tokenId));
    }

    function onBurn(uint256 _tokenId, address _target, uint256 _amount) internal {
        _amount;
        (address _marketAddress, uint256 _outcome) = TokenId.unpackTokenId(_tokenId);
        augur.logShareTokensBalanceChanged(_target, IMarket(_marketAddress), _outcome, balanceOf(_target, _tokenId));
    }
}

contract IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

contract IERC20 {
    uint8 public decimals = 18;
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ICash is IERC20 {
    function faucet(uint256 _amount) public returns (bool);
}

library SafeERC20 {
    using SafeMathUint256 for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract IFeePot is IERC20 {
    function depositFees(uint256 _amount) external returns (bool);
    function withdrawableFeesOf(address _owner) external view returns(uint256);
    function redeem() external returns (bool);
    function cash() external view returns (ICash);
}

contract IOINexus {
    function getAttoCashPerRep(address _cash, address _reputationToken) public returns (uint256);
    function universeReportingFeeDivisor(address _universe) external returns (uint256);
    function addParaAugur(address _paraAugur) external returns (bool);
    function registerParaUniverse(IUniverse _universe, IParaUniverse _paraUniverse) external;
    function recordParaUniverseValuesAndUpdateReportingFee(IUniverse _universe, uint256 _targetRepMarketCapInAttoCash, uint256 _repMarketCapInAttoCash) external returns (uint256);
}

contract IParaAugur {
    mapping(address => address) public getParaUniverse;

    ICash public cash;
    IParaShareToken public shareToken;
    IOINexus public OINexus;

    function generateParaUniverse(IUniverse _universe) external returns (IParaUniverse);
    function registerContract(bytes32 _key, address _address) external returns (bool);
    function lookup(bytes32 _key) external view returns (address);
    function isKnownUniverse(IUniverse _universe) external view returns (bool);
    function trustedCashTransfer(address _from, address _to, uint256 _amount) public returns (bool);
    function isKnownMarket(IMarket _market) public view returns (bool);
    function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) external returns (bool);
    function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets, uint256 _fees) external returns (bool);
    function logMarketOIChanged(IUniverse _universe, IMarket _market) external returns (bool);
    function logTradingProceedsClaimed(IUniverse _universe, address _sender, address _market, uint256 _outcome, uint256 _numShares, uint256 _numPayoutTokens, uint256 _fees) external returns (bool);
    function logShareTokensBalanceChanged(address _account, IMarket _market, uint256 _outcome, uint256 _balance) external returns (bool);
    function logReportingFeeChanged(uint256 _reportingFee) external returns (bool);
    function getTimestamp() public view returns (uint256);
}

interface IParaShareToken {
    function cash() external view returns (ICash);
    function augur() external view returns (address);
    function initialize(address _augur, address _originalShareToken) external;
    function approveUniverse(IParaUniverse _paraUniverse) external;
    function buyCompleteSets(IMarket _market, address _account, uint256 _amount) external returns (bool);
    function claimTradingProceeds(IMarket _market, address _shareHolder, bytes32 _fingerprint) external returns (uint256[] memory _outcomeFees);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function setApprovalForAll(address operator, bool approved) external;
    function publicSellCompleteSets(IMarket _market, uint256 _amount) external returns (uint256 _creatorFee, uint256 _reportingFee);
    function sellCompleteSets(IMarket _market, address _holder, address _recipient, uint256 _amount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee);
    function publicBuyCompleteSets(IMarket _market, uint256 _amount) external returns (bool);
    function getTokenId(IMarket _market, uint256 _outcome) external pure returns (uint256 _tokenId);
    function unsafeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) external;
    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory balances_);
    function unsafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external;
    function getMarket(uint256 _tokenId) external pure returns(IMarket);
    function isMarketInitialized(IMarket _market) external view returns (bool);
    function initializeMarket(IMarket _market) external;
}

interface IParaUniverse {
    function getFeePot() external view returns (IFeePot);
    function getReputationToken() external view returns (IV2ReputationToken);
    function originUniverse() external view returns (IUniverse);
    function setMarketFinalized(IMarket _market, uint256 _totalSupply) external returns (bool);
    function withdraw(address _recipient, uint256 _amount, address _market) external returns (bool);
    function deposit(address _sender, uint256 _amount, address _market) external returns (bool);
    function decrementOpenInterest(uint256 _amount) external returns (bool);
    function incrementOpenInterest(uint256 _amount) external returns (bool);
    function recordMarketCreatorFees(IMarket _market, uint256 _marketCreatorFees, address _sourceAccount) external returns (bool);
    function getMarketOpenInterest(IMarket _market) external view returns (uint256);
    function getOrCacheReportingFeeDivisor() external returns (uint256);
    function getReportingFeeDivisor() external view returns (uint256);
    function setOrigin(IUniverse _originUniverse) external;
}

contract IAffiliateValidator {
    function validateReference(address _account, address _referrer) external view returns (bool);
}

contract IDisputeWindow is ITyped, IERC20 {
    function invalidMarketsTotal() external view returns (uint256);
    function validityBondTotal() external view returns (uint256);

    function incorrectDesignatedReportTotal() external view returns (uint256);
    function initialReportBondTotal() external view returns (uint256);

    function designatedReportNoShowsTotal() external view returns (uint256);
    function designatedReporterNoShowBondTotal() external view returns (uint256);

    function initialize(IAugur _augur, IUniverse _universe, uint256 _disputeWindowId, bool _participationTokensEnabled, uint256 _duration, uint256 _startTime) public;
    function trustedBuy(address _buyer, uint256 _attotokens) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getReputationToken() public view returns (IReputationToken);
    function getStartTime() public view returns (uint256);
    function getEndTime() public view returns (uint256);
    function getWindowId() public view returns (uint256);
    function isActive() public view returns (bool);
    function isOver() public view returns (bool);
    function onMarketFinalized() public;
    function redeem(address _account) public returns (bool);
}

contract IMarket is IOwnable {
    enum MarketType {
        YES_NO,
        CATEGORICAL,
        SCALAR
    }

    function initialize(IAugur _augur, IUniverse _universe, uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, address _creator, uint256 _numOutcomes, uint256 _numTicks) public;
    function derivePayoutDistributionHash(uint256[] memory _payoutNumerators) public view returns (bytes32);
    function doInitialReport(uint256[] memory _payoutNumerators, string memory _description, uint256 _additionalStake) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getDisputeWindow() public view returns (IDisputeWindow);
    function getNumberOfOutcomes() public view returns (uint256);
    function getNumTicks() public view returns (uint256);
    function getMarketCreatorSettlementFeeDivisor() public view returns (uint256);
    function getForkingMarket() public view returns (IMarket _market);
    function getEndTime() public view returns (uint256);
    function getWinningPayoutDistributionHash() public view returns (bytes32);
    function getWinningPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getWinningReportingParticipant() public view returns (IReportingParticipant);
    function getReputationToken() public view returns (IV2ReputationToken);
    function getFinalizationTime() public view returns (uint256);
    function getInitialReporter() public view returns (IInitialReporter);
    function getDesignatedReportingEndTime() public view returns (uint256);
    function getValidityBondAttoCash() public view returns (uint256);
    function affiliateFeeDivisor() external view returns (uint256);
    function getNumParticipants() public view returns (uint256);
    function getDisputePacingOn() public view returns (bool);
    function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256);
    function recordMarketCreatorFees(uint256 _marketCreatorFees, address _sourceAccount, bytes32 _fingerprint) public returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function isFinalizedAsInvalid() public view returns (bool);
    function finalize() public returns (bool);
    function isFinalized() public view returns (bool);
    function getOpenInterest() public view returns (uint256);
}

contract IReportingParticipant {
    function getStake() public view returns (uint256);
    function getPayoutDistributionHash() public view returns (bytes32);
    function liquidateLosing() public;
    function redeem(address _redeemer) public returns (bool);
    function isDisavowed() public view returns (bool);
    function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getPayoutNumerators() public view returns (uint256[] memory);
    function getMarket() public view returns (IMarket);
    function getSize() public view returns (uint256);
}

contract IInitialReporter is IReportingParticipant, IOwnable {
    function initialize(IAugur _augur, IMarket _market, address _designatedReporter) public;
    function report(address _reporter, bytes32 _payoutDistributionHash, uint256[] memory _payoutNumerators, uint256 _initialReportStake) public;
    function designatedReporterShowed() public view returns (bool);
    function initialReporterWasCorrect() public view returns (bool);
    function getDesignatedReporter() public view returns (address);
    function getReportTimestamp() public view returns (uint256);
    function migrateToNewUniverse(address _designatedReporter) public;
    function returnRepFromDisavow() public;
}

contract IReputationToken is IERC20 {
    function migrateOutByPayout(uint256[] memory _payoutNumerators, uint256 _attotokens) public returns (bool);
    function migrateIn(address _reporter, uint256 _attotokens) public returns (bool);
    function trustedReportingParticipantTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedMarketTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedUniverseTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedDisputeWindowTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getTotalMigrated() public view returns (uint256);
    function getTotalTheoreticalSupply() public view returns (uint256);
    function mintForReportingParticipant(uint256 _amountMigrated) public returns (bool);
}

contract IShareToken is ITyped, IERC1155 {
    function initialize(IAugur _augur) external;
    function initializeMarket(IMarket _market, uint256 _numOutcomes, uint256 _numTicks) public;
    function unsafeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) public;
    function unsafeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values) public;
    function claimTradingProceeds(IMarket _market, address _shareHolder, bytes32 _fingerprint) external returns (uint256[] memory _outcomeFees);
    function getMarket(uint256 _tokenId) external view returns (IMarket);
    function getOutcome(uint256 _tokenId) external view returns (uint256);
    function getTokenId(IMarket _market, uint256 _outcome) public pure returns (uint256 _tokenId);
    function getTokenIds(IMarket _market, uint256[] memory _outcomes) public pure returns (uint256[] memory _tokenIds);
    function buyCompleteSets(IMarket _market, address _account, uint256 _amount) external returns (bool);
    function buyCompleteSetsForTrade(IMarket _market, uint256 _amount, uint256 _longOutcome, address _longRecipient, address _shortRecipient) external returns (bool);
    function sellCompleteSets(IMarket _market, address _holder, address _recipient, uint256 _amount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee);
    function sellCompleteSetsForTrade(IMarket _market, uint256 _outcome, uint256 _amount, address _shortParticipant, address _longParticipant, address _shortRecipient, address _longRecipient, uint256 _price, address _sourceAccount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee);
    function totalSupplyForMarketOutcome(IMarket _market, uint256 _outcome) public view returns (uint256);
    function balanceOfMarketOutcome(IMarket _market, uint256 _outcome, address _account) public view returns (uint256);
    function lowestBalanceOfMarketOutcomes(IMarket _market, uint256[] memory _outcomes, address _account) public view returns (uint256);
}

contract IUniverse {
    function creationTime() external view returns (uint256);
    function marketBalance(address) external view returns (uint256);

    function fork() public returns (bool);
    function updateForkValues() public returns (bool);
    function getParentUniverse() public view returns (IUniverse);
    function createChildUniverse(uint256[] memory _parentPayoutNumerators) public returns (IUniverse);
    function getChildUniverse(bytes32 _parentPayoutDistributionHash) public view returns (IUniverse);
    function getReputationToken() public view returns (IV2ReputationToken);
    function getForkingMarket() public view returns (IMarket);
    function getForkEndTime() public view returns (uint256);
    function getForkReputationGoal() public view returns (uint256);
    function getParentPayoutDistributionHash() public view returns (bytes32);
    function getDisputeRoundDurationInSeconds(bool _initial) public view returns (uint256);
    function getOrCreateDisputeWindowByTimestamp(uint256 _timestamp, bool _initial) public returns (IDisputeWindow);
    function getOrCreateCurrentDisputeWindow(bool _initial) public returns (IDisputeWindow);
    function getOrCreateNextDisputeWindow(bool _initial) public returns (IDisputeWindow);
    function getOrCreatePreviousDisputeWindow(bool _initial) public returns (IDisputeWindow);
    function getOpenInterestInAttoCash() public view returns (uint256);
    function getTargetRepMarketCapInAttoCash() public view returns (uint256);
    function getOrCacheValidityBond() public returns (uint256);
    function getOrCacheDesignatedReportStake() public returns (uint256);
    function getOrCacheDesignatedReportNoShowBond() public returns (uint256);
    function getOrCacheMarketRepBond() public returns (uint256);
    function getOrCacheReportingFeeDivisor() public returns (uint256);
    function getDisputeThresholdForFork() public view returns (uint256);
    function getDisputeThresholdForDisputePacing() public view returns (uint256);
    function getInitialReportMinValue() public view returns (uint256);
    function getPayoutNumerators() public view returns (uint256[] memory);
    function getReportingFeeDivisor() public view returns (uint256);
    function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getWinningChildPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function isOpenInterestCash(address) public view returns (bool);
    function isForkingMarket() public view returns (bool);
    function getCurrentDisputeWindow(bool _initial) public view returns (IDisputeWindow);
    function getDisputeWindowStartTimeAndDuration(uint256 _timestamp, bool _initial) public view returns (uint256, uint256);
    function isParentOf(IUniverse _shadyChild) public view returns (bool);
    function updateTentativeWinningChildUniverse(bytes32 _parentPayoutDistributionHash) public returns (bool);
    function isContainerForDisputeWindow(IDisputeWindow _shadyTarget) public view returns (bool);
    function isContainerForMarket(IMarket _shadyTarget) public view returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function migrateMarketOut(IUniverse _destinationUniverse) public returns (bool);
    function migrateMarketIn(IMarket _market, uint256 _cashBalance, uint256 _marketOI) public returns (bool);
    function decrementOpenInterest(uint256 _amount) public returns (bool);
    function decrementOpenInterestFromMarket(IMarket _market) public returns (bool);
    function incrementOpenInterest(uint256 _amount) public returns (bool);
    function getWinningChildUniverse() public view returns (IUniverse);
    function isForking() public view returns (bool);
    function deposit(address _sender, uint256 _amount, address _market) public returns (bool);
    function withdraw(address _recipient, uint256 _amount, address _market) public returns (bool);
    function pokeRepMarketCapInAttoCash() public returns (uint256);
    function createScalarMarket(uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, int256[] memory _prices, uint256 _numTicks, string memory _extraInfo) public returns (IMarket _newMarket);
    function createYesNoMarket(uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, string memory _extraInfo) public returns (IMarket _newMarket);
    function createCategoricalMarket(uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, bytes32[] memory _outcomes, string memory _extraInfo) public returns (IMarket _newMarket);
    function runPeriodicals() external returns (bool);
}

contract IV2ReputationToken is IReputationToken {
    function parentUniverse() external returns (IUniverse);
    function burnForMarket(uint256 _amountToBurn) public returns (bool);
    function mintForWarpSync(uint256 _amountToMint, address _target) public returns (bool);
    function getLegacyRepToken() public view returns (IERC20);
    function symbol() public view returns (string memory);
}

contract ShareToken is ITyped, Initializable, ERC1155, IShareToken, ReentrancyGuard {

    string constant public name = "Shares";
    string constant public symbol = "SHARE";

    struct MarketData {
        uint256 numOutcomes;
        uint256 numTicks;
    }

    mapping(address => MarketData) markets;

    IAugur public augur;
    ICash public cash;

    function initialize(IAugur _augur) external beforeInitialized {
        endInitialization();
        augur = _augur;
        cash = ICash(_augur.lookup("Cash"));

        require(cash != ICash(0));
    }

    /**
        @dev Transfers `value` amount of an `id` from the `from` address to the `to` address specified.
        Caller must be approved to manage the tokens being transferred out of the `from` account.
        Regardless of if the desintation is a contract or not this will not call `onERC1155Received` on `to`
        @param _from Source address
        @param _to Target address
        @param _id ID of the token type
        @param _value Transfer amount
    */
    function unsafeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) public {
        _transferFrom(_from, _to, _id, _value, bytes(""), false);
    }

    /**
        @dev Transfers `values` amount(s) of `ids` from the `from` address to the
        `to` address specified. Caller must be approved to manage the tokens being
        transferred out of the `from` account. Regardless of if the desintation is
        a contract or not this will not call `onERC1155Received` on `to`
        @param _from Source address
        @param _to Target address
        @param _ids IDs of each token type
        @param _values Transfer amounts per token type
    */
    function unsafeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values) public {
        _batchTransferFrom(_from, _to, _ids, _values, bytes(""), false);
    }

    function initializeMarket(IMarket _market, uint256 _numOutcomes, uint256 _numTicks) public {
        require (augur.isKnownUniverse(IUniverse(msg.sender)));
        markets[address(_market)].numOutcomes = _numOutcomes;
        markets[address(_market)].numTicks = _numTicks;
    }

    /**
     * @notice Buy some amount of complete sets for a market
     * @param _market The market to purchase complete sets in
     * @param _amount The number of complete sets to purchase
     * @return Bool True
     */
    function publicBuyCompleteSets(IMarket _market, uint256 _amount) external returns (bool) {
        buyCompleteSetsInternal(_market, msg.sender, _amount);
        augur.logCompleteSetsPurchased(_market.getUniverse(), _market, msg.sender, _amount);
        return true;
    }

    /**
     * @notice Buy some amount of complete sets for a market
     * @param _market The market to purchase complete sets in
     * @param _account The account receiving the complete sets
     * @param _amount The number of complete sets to purchase
     * @return Bool True
     */
    function buyCompleteSets(IMarket _market, address _account, uint256 _amount) external returns (bool) {
        buyCompleteSetsInternal(_market, _account, _amount);
        return true;
    }

    function buyCompleteSetsInternal(IMarket _market, address _account, uint256 _amount) internal returns (bool) {
        uint256 _numOutcomes = markets[address(_market)].numOutcomes;
        uint256 _numTicks = markets[address(_market)].numTicks;

        require(_numOutcomes != 0, "Invalid Market provided");

        IUniverse _universe = _market.getUniverse();

        uint256 _cost = _amount.mul(_numTicks);
        _universe.deposit(msg.sender, _cost, address(_market));

        uint256[] memory _tokenIds = new uint256[](_numOutcomes);
        uint256[] memory _values = new uint256[](_numOutcomes);

        for (uint256 _i = 0; _i < _numOutcomes; _i++) {
            _tokenIds[_i] = TokenId.getTokenId(_market, _i);
            _values[_i] = _amount;
        }

        _mintBatch(_account, _tokenIds, _values, bytes(""), false);

        if (!_market.isFinalized()) {
            _universe.incrementOpenInterest(_cost);
        }

        augur.logMarketOIChanged(_universe, _market);

        assertBalances(_market);
        return true;
    }

    /**
     * @notice Buy some amount of complete sets for a market and distribute the shares according to the positions of two accounts
     * @param _market The market to purchase complete sets in
     * @param _amount The number of complete sets to purchase
     * @param _longOutcome The outcome for the trade being fulfilled
     * @param _longRecipient The account which should recieve the _longOutcome shares
     * @param _shortRecipient The account which should recieve shares of every outcome other than _longOutcome
     * @return Bool True
     */
    function buyCompleteSetsForTrade(IMarket _market, uint256 _amount, uint256 _longOutcome, address _longRecipient, address _shortRecipient) external returns (bool) {
        uint256 _numOutcomes = markets[address(_market)].numOutcomes;

        require(_numOutcomes != 0, "Invalid Market provided");
        require(_longOutcome < _numOutcomes);

        IUniverse _universe = _market.getUniverse();

        {
            uint256 _numTicks = markets[address(_market)].numTicks;
            uint256 _cost = _amount.mul(_numTicks);
            _universe.deposit(msg.sender, _cost, address(_market));

            if (!_market.isFinalized()) {
                _universe.incrementOpenInterest(_cost);
            }
        }

        uint256[] memory _tokenIds = new uint256[](_numOutcomes - 1);
        uint256[] memory _values = new uint256[](_numOutcomes - 1);
        uint256 _outcome = 0;

        for (uint256 _i = 0; _i < _numOutcomes - 1; _i++) {
            if (_outcome == _longOutcome) {
                _outcome++;
            }
            _tokenIds[_i] = TokenId.getTokenId(_market, _outcome);
            _values[_i] = _amount;
            _outcome++;
        }

        _mintBatch(_shortRecipient, _tokenIds, _values, bytes(""), false);
        _mint(_longRecipient, TokenId.getTokenId(_market, _longOutcome), _amount, bytes(""), false);

        augur.logMarketOIChanged(_universe, _market);

        assertBalances(_market);
        return true;
    }

    /**
     * @notice Sell some amount of complete sets for a market
     * @param _market The market to sell complete sets in
     * @param _amount The number of complete sets to sell
     * @return (uint256 _creatorFee, uint256 _reportingFee) The fees taken for the market creator and reporting respectively
     */
    function publicSellCompleteSets(IMarket _market, uint256 _amount) external returns (uint256 _creatorFee, uint256 _reportingFee) {
        (uint256 _payout, uint256 _creatorFee, uint256 _reportingFee) = burnCompleteSets(_market, msg.sender, _amount, msg.sender, bytes32(0));

        require(cash.transfer(msg.sender, _payout));

        IUniverse _universe = _market.getUniverse();
        augur.logCompleteSetsSold(_universe, _market, msg.sender, _amount, _creatorFee.add(_reportingFee));

        assertBalances(_market);
        return (_creatorFee, _reportingFee);
    }

    /**
     * @notice Sell some amount of complete sets for a market
     * @param _market The market to sell complete sets in
     * @param _holder The holder of the complete sets
     * @param _recipient The recipient of funds from the sale
     * @param _amount The number of complete sets to sell
     * @param _fingerprint Fingerprint of the filler used to naively restrict affiliate fee dispursement
     * @return (uint256 _creatorFee, uint256 _reportingFee) The fees taken for the market creator and reporting respectively
     */
    function sellCompleteSets(IMarket _market, address _holder, address _recipient, uint256 _amount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee) {
        require(_holder == msg.sender || isApprovedForAll(_holder, msg.sender) == true, "ERC1155: need operator approval to sell complete sets");
        
        (uint256 _payout, uint256 _creatorFee, uint256 _reportingFee) = burnCompleteSets(_market, _holder, _amount, _holder, _fingerprint);

        require(cash.transfer(_recipient, _payout));

        assertBalances(_market);
        return (_creatorFee, _reportingFee);
    }

    /**
     * @notice Sell some amount of complete sets for a market
     * @param _market The market to sell complete sets in
     * @param _amount The number of complete sets to sell
     * @param _shortParticipant The account which should provide the short party portion of shares
     * @param _longParticipant The account which should provide the long party portion of shares
     * @param _longRecipient The account which should receive the remaining payout for providing the matching shares to the short recipients shares
     * @param _shortRecipient The account which should recieve the (price * shares provided) payout for selling their side of the sale
     * @param _price The price of the trade being done. This determines how much each recipient recieves from the sale proceeds
     * @param _fingerprint Fingerprint of the filler used to naively restrict affiliate fee dispursement
     * @return (uint256 _creatorFee, uint256 _reportingFee) The fees taken for the market creator and reporting respectively
     */
    function sellCompleteSetsForTrade(IMarket _market, uint256 _outcome, uint256 _amount, address _shortParticipant, address _longParticipant, address _shortRecipient, address _longRecipient, uint256 _price, address _sourceAccount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee) {
        require(isApprovedForAll(_shortParticipant, msg.sender) == true, "ERC1155: need operator approval to burn short account shares");
        require(isApprovedForAll(_longParticipant, msg.sender) == true, "ERC1155: need operator approval to burn long account shares");

        _internalTransferFrom(_shortParticipant, _longParticipant, getTokenId(_market, _outcome), _amount, bytes(""), false);

        // NOTE: burnCompleteSets will validate the market provided is legitimate
        (uint256 _payout, uint256 _creatorFee, uint256 _reportingFee) = burnCompleteSets(_market, _longParticipant, _amount, _sourceAccount, _fingerprint);

        {
            uint256 _longPayout = _payout.mul(_price) / _market.getNumTicks();
            require(cash.transfer(_longRecipient, _longPayout));
            require(cash.transfer(_shortRecipient, _payout.sub(_longPayout)));
        }

        assertBalances(_market);
        return (_creatorFee, _reportingFee);
    }

    function burnCompleteSets(IMarket _market, address _account, uint256 _amount, address _sourceAccount, bytes32 _fingerprint) private returns (uint256 _payout, uint256 _creatorFee, uint256 _reportingFee) {
        uint256 _numOutcomes = markets[address(_market)].numOutcomes;
        uint256 _numTicks = markets[address(_market)].numTicks;

        require(_numOutcomes != 0, "Invalid Market provided");

        // solium-disable indentation
        {
            uint256[] memory _tokenIds = new uint256[](_numOutcomes);
            uint256[] memory _values = new uint256[](_numOutcomes);

            for (uint256 i = 0; i < _numOutcomes; i++) {
                _tokenIds[i] = TokenId.getTokenId(_market, i);
                _values[i] = _amount;
            }

            _burnBatch(_account, _tokenIds, _values, bytes(""), false);
        }
        // solium-enable indentation

        _payout = _amount.mul(_numTicks);
        IUniverse _universe = _market.getUniverse();

        if (!_market.isFinalized()) {
            _universe.decrementOpenInterest(_payout);
        }

        _creatorFee = _market.deriveMarketCreatorFeeAmount(_payout);
        uint256 _reportingFeeDivisor = _universe.getOrCacheReportingFeeDivisor();
        _reportingFee = _payout.div(_reportingFeeDivisor);
        _payout = _payout.sub(_creatorFee).sub(_reportingFee);

        if (_creatorFee != 0) {
            _market.recordMarketCreatorFees(_creatorFee, _sourceAccount, _fingerprint);
        }

        _universe.withdraw(address(this), _payout.add(_reportingFee), address(_market));

        if (_reportingFee != 0) {
            require(cash.transfer(address(_universe.getOrCreateNextDisputeWindow(false)), _reportingFee));
        }

        augur.logMarketOIChanged(_universe, _market);
    }

    /**
     * @notice Claims winnings for a market and for a particular shareholder
     * @param _market The market to claim winnings for
     * @param _shareHolder The account to claim winnings for
     * @param _fingerprint Fingerprint of the filler used to naively restrict affiliate fee dispursement
     * @return Bool True
     */
    function claimTradingProceeds(IMarket _market, address _shareHolder, bytes32 _fingerprint) external nonReentrant returns (uint256[] memory _outcomeFees) {
        return claimTradingProceedsInternal(_market, _shareHolder, _fingerprint);
    }

    function claimTradingProceedsInternal(IMarket _market, address _shareHolder, bytes32 _fingerprint) internal returns (uint256[] memory _outcomeFees) {
        require(augur.isKnownMarket(_market));
        if (!_market.isFinalized()) {
            _market.finalize();
        }
        _outcomeFees = new uint256[](8);
        for (uint256 _outcome = 0; _outcome < _market.getNumberOfOutcomes(); ++_outcome) {
            uint256 _numberOfShares = balanceOfMarketOutcome(_market, _outcome, _shareHolder);

            if (_numberOfShares > 0) {
                uint256 _proceeds;
                uint256 _shareHolderShare;
                uint256 _creatorShare;
                uint256 _reporterShare;
                uint256 _tokenId = TokenId.getTokenId(_market, _outcome);
                (_proceeds, _shareHolderShare, _creatorShare, _reporterShare) = divideUpWinnings(_market, _outcome, _numberOfShares);

                // always destroy shares as it gives a minor gas refund and is good for the network
                _burn(_shareHolder, _tokenId, _numberOfShares, bytes(""), false);
                logTradingProceedsClaimed(_market, _outcome, _shareHolder, _numberOfShares, _shareHolderShare, _creatorShare.add(_reporterShare));

                if (_proceeds > 0) {
                    _market.getUniverse().withdraw(address(this), _shareHolderShare.add(_reporterShare), address(_market));
                    distributeProceeds(_market, _shareHolder, _shareHolderShare, _creatorShare, _reporterShare, _fingerprint);
                }
                _outcomeFees[_outcome] = _creatorShare.add(_reporterShare);
            }
        }

        assertBalances(_market);
        return _outcomeFees;
    }

    function distributeProceeds(IMarket _market, address _shareHolder, uint256 _shareHolderShare, uint256 _creatorShare, uint256 _reporterShare, bytes32 _fingerprint) private {
        if (_shareHolderShare > 0) {
            require(cash.transfer(_shareHolder, _shareHolderShare));
        }
        if (_creatorShare > 0) {
            _market.recordMarketCreatorFees(_creatorShare, _shareHolder, _fingerprint);
        }
        if (_reporterShare > 0) {
            require(cash.transfer(address(_market.getUniverse().getOrCreateNextDisputeWindow(false)), _reporterShare));
        }
    }

    function logTradingProceedsClaimed(IMarket _market, uint256 _outcome, address _sender, uint256 _numShares, uint256 _numPayoutTokens, uint256 _fees) private {
        augur.logTradingProceedsClaimed(_market.getUniverse(), _sender, address(_market), _outcome, _numShares, _numPayoutTokens, _fees);
    }

    function divideUpWinnings(IMarket _market, uint256 _outcome, uint256 _numberOfShares) public returns (uint256 _proceeds, uint256 _shareHolderShare, uint256 _creatorShare, uint256 _reporterShare) {
        _proceeds = calculateProceeds(_market, _outcome, _numberOfShares);
        _creatorShare = calculateCreatorFee(_market, _proceeds);
        _reporterShare = calculateReportingFee(_market, _proceeds);
        _shareHolderShare = _proceeds.sub(_creatorShare).sub(_reporterShare);
        return (_proceeds, _shareHolderShare, _creatorShare, _reporterShare);
    }

    function calculateProceeds(IMarket _market, uint256 _outcome, uint256 _numberOfShares) public view returns (uint256) {
        uint256 _payoutNumerator = _market.getWinningPayoutNumerator(_outcome);
        return _numberOfShares.mul(_payoutNumerator);
    }

    function calculateReportingFee(IMarket _market, uint256 _amount) public returns (uint256) {
        uint256 _reportingFeeDivisor = _market.getUniverse().getOrCacheReportingFeeDivisor();
        return _amount.div(_reportingFeeDivisor);
    }

    function calculateCreatorFee(IMarket _market, uint256 _amount) public view returns (uint256) {
        return _market.deriveMarketCreatorFeeAmount(_amount);
    }

    function getTypeName() public view returns(bytes32) {
        return "ShareToken";
    }

    /**
     * @return The market associated with this Share Token ID
     */
    function getMarket(uint256 _tokenId) external view returns(IMarket) {
        (address _market, uint256 _outcome) = TokenId.unpackTokenId(_tokenId);
        return IMarket(_market);
    }

    /**
     * @return The outcome associated with this Share Token ID
     */
    function getOutcome(uint256 _tokenId) external view returns(uint256) {
        (address _market, uint256 _outcome) = TokenId.unpackTokenId(_tokenId);
        return _outcome;
    }

    function totalSupplyForMarketOutcome(IMarket _market, uint256 _outcome) public view returns (uint256) {
        uint256 _tokenId = TokenId.getTokenId(_market, _outcome);
        return totalSupply(_tokenId);
    }

    function balanceOfMarketOutcome(IMarket _market, uint256 _outcome, address _account) public view returns (uint256) {
        uint256 _tokenId = TokenId.getTokenId(_market, _outcome);
        return balanceOf(_account, _tokenId);
    }

    function lowestBalanceOfMarketOutcomes(IMarket _market, uint256[] memory _outcomes, address _account) public view returns (uint256) {
        uint256 _lowest = SafeMathUint256.getUint256Max();
        for (uint256 _i = 0; _i < _outcomes.length; ++_i) {
            uint256 _tokenId = TokenId.getTokenId(_market, _outcomes[_i]);
            _lowest = balanceOf(_account, _tokenId).min(_lowest);
        }
        return _lowest;
    }

    function assertBalances(IMarket _market) public view {
        uint256 _expectedBalance = 0;
        uint256 _numTicks = _market.getNumTicks();
        uint256 _numOutcomes = _market.getNumberOfOutcomes();
        // Market Open Interest. If we're finalized we need actually calculate the value
        if (_market.isFinalized()) {
            for (uint8 i = 0; i < _numOutcomes; i++) {
                _expectedBalance = _expectedBalance.add(totalSupplyForMarketOutcome(_market, i).mul(_market.getWinningPayoutNumerator(i)));
            }
        } else {
            _expectedBalance = totalSupplyForMarketOutcome(_market, 0).mul(_numTicks);
        }

        assert(_market.getUniverse().marketBalance(address(_market)) >= _expectedBalance);
    }

    function getTokenId(IMarket _market, uint256 _outcome) public pure returns (uint256 _tokenId) {
        return TokenId.getTokenId(_market, _outcome);
    }

    function getTokenIds(IMarket _market, uint256[] memory _outcomes) public pure returns (uint256[] memory _tokenIds) {
        return TokenId.getTokenIds(_market, _outcomes);
    }

    function unpackTokenId(uint256 _tokenId) public pure returns (address _market, uint256 _outcome) {
        return TokenId.unpackTokenId(_tokenId);
    }

    function onTokenTransfer(uint256 _tokenId, address _from, address _to, uint256 _value) internal {
        (address _marketAddress, uint256 _outcome) = TokenId.unpackTokenId(_tokenId);
        augur.logShareTokensBalanceChanged(_from, IMarket(_marketAddress), _outcome, balanceOf(_from, _tokenId));
        augur.logShareTokensBalanceChanged(_to, IMarket(_marketAddress), _outcome, balanceOf(_to, _tokenId));
    }

    function onMint(uint256 _tokenId, address _target, uint256 _amount) internal {
        (address _marketAddress, uint256 _outcome) = TokenId.unpackTokenId(_tokenId);
        augur.logShareTokensBalanceChanged(_target, IMarket(_marketAddress), _outcome, balanceOf(_target, _tokenId));
    }

    function onBurn(uint256 _tokenId, address _target, uint256 _amount) internal {
        (address _marketAddress, uint256 _outcome) = TokenId.unpackTokenId(_tokenId);
        augur.logShareTokensBalanceChanged(_target, IMarket(_marketAddress), _outcome, balanceOf(_target, _tokenId));
    }
}

contract IAugurTrading {
    function lookup(bytes32 _key) public view returns (address);
    function logProfitLossChanged(IMarket _market, address _account, uint256 _outcome, int256 _netPosition, uint256 _avgPrice, int256 _realizedProfit, int256 _frozenFunds, int256 _realizedCost) public returns (bool);
    function logOrderCreated(IUniverse _universe, bytes32 _orderId, bytes32 _tradeGroupId) public returns (bool);
    function logOrderCanceled(IUniverse _universe, IMarket _market, address _creator, uint256 _tokenRefund, uint256 _sharesRefund, bytes32 _orderId) public returns (bool);
    function logOrderFilled(IUniverse _universe, address _creator, address _filler, uint256 _price, uint256 _fees, uint256 _amountFilled, bytes32 _orderId, bytes32 _tradeGroupId) public returns (bool);
    function logMarketVolumeChanged(IUniverse _universe, address _market, uint256 _volume, uint256[] memory _outcomeVolumes, uint256 _totalTrades) public returns (bool);
    function logZeroXOrderFilled(IUniverse _universe, IMarket _market, bytes32 _orderHash, bytes32 _tradeGroupId, uint8 _orderType, address[] memory _addressData, uint256[] memory _uint256Data) public returns (bool);
    function logZeroXOrderCanceled(address _universe, address _market, address _account, uint256 _outcome, uint256 _price, uint256 _amount, uint8 _type, bytes32 _orderHash) public;
}

contract AugurTrading is IAugurTrading {
    using SafeMathUint256 for uint256;
    using ContractExists for address;

    enum OrderEventType {
        Create,
        Cancel,
        Fill
    }
    //  addressData
    //  0:  orderCreator
    //  1:  orderFiller (Fill)
    //
    //  uint256Data
    //  0:  price
    //  1:  amount
    //  2:  outcome
    //  3:  tokenRefund (Cancel)
    //  4:  sharesRefund (Cancel)
    //  5:  fees (Fill)
    //  6:  amountFilled (Fill)
    //  7:  timestamp
    //  8:  sharesEscrowed
    //  9:	tokensEscrowed
    event OrderEvent(address indexed universe, address indexed market, OrderEventType indexed eventType, uint8 orderType, bytes32 orderId, bytes32 tradeGroupId, address[] addressData, uint256[] uint256Data);
    event ProfitLossChanged(address indexed universe, address indexed market, address indexed account, uint256 outcome, int256 netPosition, uint256 avgPrice, int256 realizedProfit, int256 frozenFunds, int256 realizedCost, uint256 timestamp);
    event MarketVolumeChanged(address indexed universe, address indexed market, uint256 volume, uint256[] outcomeVolumes, uint256 totalTrades, uint256 timestamp);    event CancelZeroXOrder(
        address indexed universe,
        address indexed market,
        address indexed account,
        uint256 outcome,
        uint256 price,
        uint256 amount,
        uint8 orderType,
        bytes32 orderHash
    );

    mapping(address => bool) public trustedSender;

    address public uploader;
    mapping(bytes32 => address) internal registry;

    IAugur public augur;
    IShareToken public shareToken;

    uint256 private constant MAX_APPROVAL_AMOUNT = 2 ** 256 - 1;

    modifier onlyUploader() {
        require(msg.sender == uploader);
        _;
    }

    constructor(IAugur _augur) public {
        uploader = msg.sender;
        augur = _augur;
    }

    function registerContract(bytes32 _key, address _address) public onlyUploader returns (bool) {
        require(registry[_key] == address(0), "Augur.registerContract: key has already been used in registry");
        require(_address.exists());
        registry[_key] = _address;
        return true;
    }

    function doApprovals() public onlyUploader returns (bool) {
        bytes32[3] memory _names = [bytes32("CancelOrder"), bytes32("FillOrder"), bytes32("CreateOrder")];

        shareToken = IShareToken(augur.lookup("ShareToken"));
        ICash _cash = ICash(augur.lookup("Cash"));

        require(shareToken != IShareToken(0));
        require(_cash != ICash(0));

        for (uint256 i = 0; i < _names.length; i++) {
            address _address = registry[_names[i]];
            shareToken.setApprovalForAll(_address, true);
            _cash.approve(_address, MAX_APPROVAL_AMOUNT);
        }
    }

    /**
     * @notice Find the contract address for a particular key
     * @param _key The key to lookup
     * @return the address of the registered contract if one exists for the given key
     */
    function lookup(bytes32 _key) public view returns (address) {
        return registry[_key];
    }

    function finishDeployment() public onlyUploader returns (bool) {
        uploader = address(1);
        return true;
    }

    /**
     * @notice Claims winnings for multiple markets and for a particular shareholder
     * @param _markets Array of markets to claim winnings for
     * @param _shareHolder The account to claim winnings for
     * @param _fingerprint Fingerprint of the user to restrict affiliate fees
     * @return Bool True
     */
    function claimMarketsProceeds(IMarket[] calldata _markets, address _shareHolder, bytes32 _fingerprint) external returns (bool) {
        for (uint256 i=0; i < _markets.length; i++) {
            uint256[] memory _outcomeFees = shareToken.claimTradingProceeds(_markets[i], _shareHolder, _fingerprint);
            IProfitLoss(registry['ProfitLoss']).recordClaim(_markets[i], _shareHolder, _outcomeFees);
        }
        return true;
    }

    /**
     * @notice Claims winnings for a market and for a particular shareholder
     * @param _market The market to claim winnings for
     * @param _shareHolder The account to claim winnings for
     * @param _fingerprint Fingerprint of the user to restrict affiliate fees
     * @return Bool True
     */
    function claimTradingProceeds(IMarket _market, address _shareHolder, bytes32 _fingerprint) external returns (bool) {
        uint256[] memory _outcomeFees = shareToken.claimTradingProceeds(_market, _shareHolder, _fingerprint);
        IProfitLoss(registry['ProfitLoss']).recordClaim(_market, _shareHolder, _outcomeFees);
        return true;
    }

    //
    // Logs
    //

    function logProfitLossChanged(IMarket _market, address _account, uint256 _outcome, int256 _netPosition, uint256 _avgPrice, int256 _realizedProfit, int256 _frozenFunds, int256 _realizedCost) public returns (bool) {
        require(msg.sender == registry["ProfitLoss"]);
        emit ProfitLossChanged(address(_market.getUniverse()), address(_market), _account, _outcome, _netPosition, _avgPrice, _realizedProfit, _frozenFunds, _realizedCost, augur.getTimestamp());
        return true;
    }

    function logOrderCanceled(IUniverse _universe, IMarket _market, address _creator, uint256 _tokenRefund, uint256 _sharesRefund, bytes32 _orderId) public returns (bool) {
        require(msg.sender == registry["CancelOrder"]);
        IOrders _orders = IOrders(registry["Orders"]);
        (Order.Types _orderType, address[] memory _addressData, uint256[] memory _uint256Data) = _orders.getOrderDataForLogs(_orderId);
        _addressData[0] = _creator;
        _uint256Data[3] = _tokenRefund;
        _uint256Data[4] = _sharesRefund;
        _uint256Data[7] = augur.getTimestamp();
        emit OrderEvent(address(_universe), address(_market), OrderEventType.Cancel, uint8(_orderType), _orderId, 0, _addressData, _uint256Data);
        return true;
    }

    function logOrderCreated(IUniverse _universe, bytes32 _orderId, bytes32 _tradeGroupId) public returns (bool) {
        require(msg.sender == registry["Orders"]);
        IOrders _orders = IOrders(registry["Orders"]);
        (Order.Types _orderType, address[] memory _addressData, uint256[] memory _uint256Data) = _orders.getOrderDataForLogs(_orderId);
        _uint256Data[7] = augur.getTimestamp();
        emit OrderEvent(address(_universe), address(_orders.getMarket(_orderId)), OrderEventType.Create, uint8(_orderType), _orderId, _tradeGroupId, _addressData, _uint256Data);
        return true;
    }

    function logOrderFilled(IUniverse _universe, address _creator, address _filler, uint256 _price, uint256 _fees, uint256 _amountFilled, bytes32 _orderId, bytes32 _tradeGroupId) public returns (bool) {
        require(msg.sender == registry["FillOrder"]);
        IOrders _orders = IOrders(registry["Orders"]);
        (Order.Types _orderType, address[] memory _addressData, uint256[] memory _uint256Data) = _orders.getOrderDataForLogs(_orderId);
        _addressData[0] = _creator;
        _addressData[1] = _filler;
        _uint256Data[0] = _price;
        _uint256Data[5] = _fees;
        _uint256Data[6] = _amountFilled;
        _uint256Data[7] = augur.getTimestamp();
        emit OrderEvent(address(_universe), address(_orders.getMarket(_orderId)), OrderEventType.Fill, uint8(_orderType), _orderId, _tradeGroupId, _addressData, _uint256Data);
        return true;
    }

    function logMarketVolumeChanged(IUniverse _universe, address _market, uint256 _volume, uint256[] memory _outcomeVolumes, uint256 _totalTrades) public returns (bool) {
        require(msg.sender == registry["FillOrder"]);
        emit MarketVolumeChanged(address(_universe), _market, _volume, _outcomeVolumes, _totalTrades, augur.getTimestamp());
        return true;
    }

    function logZeroXOrderFilled(IUniverse _universe, IMarket _market, bytes32 _orderHash, bytes32 _tradeGroupId, uint8 _orderType, address[] memory _addressData, uint256[] memory _uint256Data) public returns (bool) {
        require(msg.sender == registry["ZeroXTrade"]);
        _uint256Data[7] = augur.getTimestamp();
        emit OrderEvent(address(_universe), address(_market), OrderEventType.Fill, _orderType, _orderHash, _tradeGroupId, _addressData, _uint256Data);
        return true;
    }
    
    function logZeroXOrderCanceled(address _universe, address _market, address _account, uint256 _outcome, uint256 _price, uint256 _amount, uint8 _type, bytes32 _orderHash) public {
        require(msg.sender == registry["ZeroXTrade"]);
        require(augur.isKnownMarket(IMarket(_market)));
        emit CancelZeroXOrder(_universe, _market, _account, _outcome, _price, _amount, _type, _orderHash);
    }
}

contract IOrders {
    function saveOrder(uint256[] calldata _uints, bytes32[] calldata _bytes32s, Order.Types _type, IMarket _market, address _sender) external returns (bytes32 _orderId);
    function removeOrder(bytes32 _orderId) external returns (bool);
    function getMarket(bytes32 _orderId) public view returns (IMarket);
    function getOrderType(bytes32 _orderId) public view returns (Order.Types);
    function getOutcome(bytes32 _orderId) public view returns (uint256);
    function getAmount(bytes32 _orderId) public view returns (uint256);
    function getPrice(bytes32 _orderId) public view returns (uint256);
    function getOrderCreator(bytes32 _orderId) public view returns (address);
    function getOrderSharesEscrowed(bytes32 _orderId) public view returns (uint256);
    function getOrderMoneyEscrowed(bytes32 _orderId) public view returns (uint256);
    function getOrderDataForCancel(bytes32 _orderId) public view returns (uint256, uint256, Order.Types, IMarket, uint256, address);
    function getOrderDataForLogs(bytes32 _orderId) public view returns (Order.Types, address[] memory _addressData, uint256[] memory _uint256Data);
    function getBetterOrderId(bytes32 _orderId) public view returns (bytes32);
    function getWorseOrderId(bytes32 _orderId) public view returns (bytes32);
    function getBestOrderId(Order.Types _type, IMarket _market, uint256 _outcome) public view returns (bytes32);
    function getWorstOrderId(Order.Types _type, IMarket _market, uint256 _outcome) public view returns (bytes32);
    function getLastOutcomePrice(IMarket _market, uint256 _outcome) public view returns (uint256);
    function getOrderId(Order.Types _type, IMarket _market, uint256 _amount, uint256 _price, address _sender, uint256 _blockNumber, uint256 _outcome, uint256 _moneyEscrowed, uint256 _sharesEscrowed) public pure returns (bytes32);
    function getTotalEscrowed(IMarket _market) public view returns (uint256);
    function isBetterPrice(Order.Types _type, uint256 _price, bytes32 _orderId) public view returns (bool);
    function isWorsePrice(Order.Types _type, uint256 _price, bytes32 _orderId) public view returns (bool);
    function assertIsNotBetterPrice(Order.Types _type, uint256 _price, bytes32 _betterOrderId) public view returns (bool);
    function assertIsNotWorsePrice(Order.Types _type, uint256 _price, bytes32 _worseOrderId) public returns (bool);
    function recordFillOrder(bytes32 _orderId, uint256 _sharesFilled, uint256 _tokensFilled, uint256 _fill) external returns (bool);
    function setPrice(IMarket _market, uint256 _outcome, uint256 _price) external returns (bool);
}

contract IProfitLoss {
    function initialize(IAugur _augur) public;
    function recordFrozenFundChange(IUniverse _universe, IMarket _market, address _account, uint256 _outcome, int256 _frozenFundDelta) public returns (bool);
    function adjustTraderProfitForFees(IMarket _market, address _trader, uint256 _outcome, uint256 _fees) public returns (bool);
    function recordTrade(IUniverse _universe, IMarket _market, address _longAddress, address _shortAddress, uint256 _outcome, int256 _amount, int256 _price, uint256 _numLongTokens, uint256 _numShortTokens, uint256 _numLongShares, uint256 _numShortShares) public returns (bool);
    function recordClaim(IMarket _market, address _account, uint256[] memory _outcomeFees) public returns (bool);
}

library Order {
    using SafeMathUint256 for uint256;

    enum Types {
        Bid, Ask
    }

    enum TradeDirections {
        Long, Short
    }

    struct Data {
        // Contracts
        IMarket market;
        IAugur augur;
        IAugurTrading augurTrading;
        IShareToken shareToken;
        ICash cash;

        // Order
        bytes32 id;
        address creator;
        uint256 outcome;
        Order.Types orderType;
        uint256 amount;
        uint256 price;
        uint256 sharesEscrowed;
        uint256 moneyEscrowed;
        bytes32 betterOrderId;
        bytes32 worseOrderId;
    }

    function create(IAugur _augur, IAugurTrading _augurTrading, address _creator, uint256 _outcome, Order.Types _type, uint256 _attoshares, uint256 _price, IMarket _market, bytes32 _betterOrderId, bytes32 _worseOrderId) internal view returns (Data memory) {
        require(_outcome < _market.getNumberOfOutcomes(), "Order.create: Outcome is not within market range");
        require(_price != 0, "Order.create: Price may not be 0");
        require(_price < _market.getNumTicks(), "Order.create: Price is outside of market range");
        require(_attoshares > 0, "Order.create: Cannot use amount of 0");
        require(_creator != address(0), "Order.create: Creator is 0x0");

        IShareToken _shareToken = IShareToken(_augur.lookup("ShareToken"));

        return Data({
            market: _market,
            augur: _augur,
            augurTrading: _augurTrading,
            shareToken: _shareToken,
            cash: ICash(_augur.lookup("Cash")),
            id: 0,
            creator: _creator,
            outcome: _outcome,
            orderType: _type,
            amount: _attoshares,
            price: _price,
            sharesEscrowed: 0,
            moneyEscrowed: 0,
            betterOrderId: _betterOrderId,
            worseOrderId: _worseOrderId
        });
    }

    //
    // "public" functions
    //

    function getOrderId(Order.Data memory _orderData, IOrders _orders) internal view returns (bytes32) {
        if (_orderData.id == bytes32(0)) {
            bytes32 _orderId = calculateOrderId(_orderData.orderType, _orderData.market, _orderData.amount, _orderData.price, _orderData.creator, block.number, _orderData.outcome, _orderData.moneyEscrowed, _orderData.sharesEscrowed);
            require(_orders.getAmount(_orderId) == 0, "Order.getOrderId: New order had amount. This should not be possible");
            _orderData.id = _orderId;
        }
        return _orderData.id;
    }

    function calculateOrderId(Order.Types _type, IMarket _market, uint256 _amount, uint256 _price, address _sender, uint256 _blockNumber, uint256 _outcome, uint256 _moneyEscrowed, uint256 _sharesEscrowed) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(_type, _market, _amount, _price, _sender, _blockNumber, _outcome, _moneyEscrowed, _sharesEscrowed));
    }

    function getOrderTradingTypeFromMakerDirection(Order.TradeDirections _creatorDirection) internal pure returns (Order.Types) {
        return (_creatorDirection == Order.TradeDirections.Long) ? Order.Types.Bid : Order.Types.Ask;
    }

    function getOrderTradingTypeFromFillerDirection(Order.TradeDirections _fillerDirection) internal pure returns (Order.Types) {
        return (_fillerDirection == Order.TradeDirections.Long) ? Order.Types.Ask : Order.Types.Bid;
    }

    function saveOrder(Order.Data memory _orderData, bytes32 _tradeGroupId, IOrders _orders) internal returns (bytes32) {
        getOrderId(_orderData, _orders);
        uint256[] memory _uints = new uint256[](5);
        _uints[0] = _orderData.amount;
        _uints[1] = _orderData.price;
        _uints[2] = _orderData.outcome;
        _uints[3] = _orderData.moneyEscrowed;
        _uints[4] = _orderData.sharesEscrowed;
        bytes32[] memory _bytes32s = new bytes32[](4);
        _bytes32s[0] = _orderData.betterOrderId;
        _bytes32s[1] = _orderData.worseOrderId;
        _bytes32s[2] = _tradeGroupId;
        _bytes32s[3] = _orderData.id;
        return _orders.saveOrder(_uints, _bytes32s, _orderData.orderType, _orderData.market, _orderData.creator);
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}