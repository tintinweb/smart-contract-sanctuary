// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IConsumerBase.sol";
import "./lib/RequestIdBase.sol";


/**
 * @title Router smart contract
 *
 * @dev Routes requests for data from Consumers to data providers.
 * Data providers listen for requests and process data, sending it back to the
 * Consumer's smart contract.
 *
 * An ERC-20 Token fee is charged by the provider, and paid for by the consumer
 *
 */
contract Router is RequestIdBase, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    /*
     * CONSTANTS
     */

    uint8 public constant REQUEST_STATUS_NOT_SET = 0;
    uint8 public constant REQUEST_STATUS_REQUESTED = 1;

    /*
     * STRUCTURES
     */

    struct DataRequest {
        address consumer;
        address provider;
        uint256 fee;
        uint8 status;
    }

    struct DataProvider {
        uint256 minFee;
        mapping(address => uint256) granularFees; // Per consumer fees if required
    }

    /*
     * STATE VARS
     */

    // Contract address of ERC-20 Token being used to pay for data
    IERC20 private immutable token;

    // Mapping to hold registered providers
    mapping(address => DataProvider) private dataProviders;

    // Mapping to hold open data requests
    mapping(bytes32 => DataRequest) public dataRequests;

    // nonces for generating requestIds. Must be in sync with the consumer's 
    // nonces defined in ConsumerBase.sol.
    mapping(address => mapping(address => uint256)) private nonces;

    // Mapping to track accumulated provider earnings upon request fulfillment.
    mapping(address => uint256) private withdrawableTokens;

    /*
     * EVENTS
     */

    /**
     * @dev DataRequested. Emitted when a data request is sent by a Consumer.
     * @param consumer address of the Consumer's contract
     * @param provider address of the data provider
     * @param fee amount of xFUND paid for data request
     * @param data data being requested
     * @param requestId the request ID
     */
    event DataRequested(
        address indexed consumer,
        address indexed provider,
        uint256 fee,
        bytes32 data,
        bytes32 indexed requestId
    );

    /**
     * @dev RequestFulfilled. Emitted when a provider fulfils a data request
     * @param consumer address of the Consumer's contract
     * @param provider address of the data provider
     * @param requestId the request ID being fulfilled
     * @param requestedData the data sent to the Consumer's contract
     */
    event RequestFulfilled(
        address indexed consumer,
        address indexed provider,
        bytes32 indexed requestId,
        uint256 requestedData
    );

    /**
     * @dev TokenSet. Emitted once during contract construction
     * @param tokenAddress contract address of token being used to pay fees
     */
    event TokenSet(address tokenAddress);

    /**
     * @dev ProviderRegistered. Emitted when a provider registers
     * @param provider address of the provider
     * @param minFee new fee value
     */
    event ProviderRegistered(address indexed provider, uint256 minFee);

    /**
     * @dev SetProviderMinFee. Emitted when a provider changes their minimum token fee for providing data
     * @param provider address of the provider
     * @param oldMinFee old fee value
     * @param newMinFee new fee value
     */
    event SetProviderMinFee(address indexed provider, uint256 oldMinFee, uint256 newMinFee);

    /**
     * @dev SetProviderGranularFee. Emitted when a provider changes their token fee for providing data
     * to a selected consumer contract
     * @param provider address of the provider
     * @param consumer address of the consumer
     * @param oldFee old fee value
     * @param newFee new fee value
     */
    event SetProviderGranularFee(address indexed provider, address indexed consumer, uint256 oldFee, uint256 newFee);

    /**
    * @dev WithdrawFees. Emitted when a provider withdraws their accumulated fees
    * @param provider address of the provider withdrawing
    * @param recipient address of the recipient
    * @param amount uint256 amount being withdrawn
    */
    event WithdrawFees(address indexed provider, address indexed recipient, uint256 amount);

    /*
     * FUNCTIONS
     */

    /**
     * @dev Contract constructor. Accepts the address for a Token smart contract.
     * @param _token address must be for an ERC-20 token (e.g. xFUND)
     */
    constructor(address _token) {
        require(_token != address(0), "token cannot be zero address");
        require(_token.isContract(), "token address must be a contract");
        token = IERC20(_token);
        emit TokenSet(_token);
    }

    /**
     * @dev registerAsProvider - register as a provider
     * @param _minFee uint256 - minimum fee provider will accept to fulfill request
     * @return success
     */
    function registerAsProvider(uint256 _minFee) external returns (bool success) {
        require(_minFee > 0, "fee must be > 0");
        require(dataProviders[msg.sender].minFee == 0, "already registered");
        dataProviders[msg.sender].minFee = _minFee;
        emit ProviderRegistered(msg.sender, _minFee);
        return true;
    }

    /**
     * @dev setProviderMinFee - provider calls for setting its minimum fee
     * @param _newMinFee uint256 - minimum fee provider will accept to fulfill request
     * @return success
     */
    function setProviderMinFee(uint256 _newMinFee) external returns (bool success) {
        require(_newMinFee > 0, "fee must be > 0");
        require(dataProviders[msg.sender].minFee > 0, "not registered yet");
        uint256 oldMinFee = dataProviders[msg.sender].minFee;
        dataProviders[msg.sender].minFee = _newMinFee;
        emit SetProviderMinFee(msg.sender, oldMinFee, _newMinFee);
        return true;
    }

    /**
     * @dev setProviderGranularFee - provider calls for setting its fee for the selected consumer
     * @param _consumer address of consumer contract
     * @param _newFee uint256 - minimum fee provider will accept to fulfill request
     * @return success
     */
    function setProviderGranularFee(address _consumer, uint256 _newFee) external returns (bool success) {
        require(_newFee > 0, "fee must be > 0");
        require(dataProviders[msg.sender].minFee > 0, "not registered yet");
        uint256 oldFee = dataProviders[msg.sender].granularFees[_consumer];
        dataProviders[msg.sender].granularFees[_consumer] = _newFee;
        emit SetProviderGranularFee(msg.sender, _consumer, oldFee, _newFee);
        return true;
    }

    /**
     * @dev Allows the provider to withdraw their xFUND
     * @param _recipient is the address the funds will be sent to
     * @param _amount is the amount of xFUND transferred from the Coordinator contract
     */
    function withdraw(address _recipient, uint256 _amount) external hasAvailableTokens(_amount) {
        withdrawableTokens[msg.sender] = withdrawableTokens[msg.sender].sub(_amount);
        emit WithdrawFees(msg.sender, _recipient, _amount);
        assert(token.transfer(_recipient, _amount));
    }

    /**
     * @dev initialiseRequest - called by Consumer contract to initialise a data request. Can only be called by
     * a contract. Daata providers can watch for the DataRequested being emitted, and act on any requests
     * for the provider. Only the provider specified in the request may fulfil the request.
     * @param _provider address of the data provider.
     * @param _fee amount of Tokens to pay for data
     * @param _data type of data being requested. E.g. PRICE.BTC.USD.AVG requests average price for BTC/USD pair
     * @return success if the execution was successful. Status is checked in the Consumer contract
     */
    function initialiseRequest(
        address _provider,
        uint256 _fee,
        bytes32 _data
    ) external paidSufficientFee(_fee, _provider) nonReentrant returns (bool success) {
        address consumer = msg.sender; // msg.sender is the address of the Consumer's smart contract
        require(address(consumer).isContract(), "only a contract can initialise");
        require(dataProviders[_provider].minFee > 0, "provider not registered");

        token.transferFrom(consumer, address(this), _fee);

        uint256 nonce = nonces[_provider][consumer];
        // recreate request ID from params sent
        bytes32 requestId = makeRequestId(consumer, _provider, address(this), nonce, _data);

        dataRequests[requestId].consumer = consumer;
        dataRequests[requestId].provider = _provider;
        dataRequests[requestId].fee = _fee;
        dataRequests[requestId].status = REQUEST_STATUS_REQUESTED;

        // Transfer successful - emit the DataRequested event
        emit DataRequested(
            consumer,
            _provider,
            _fee,
            _data,
            requestId
        );

        nonces[_provider][consumer] = nonces[_provider][consumer].add(1);

        return true;
    }

    /**
     * @dev fulfillRequest - called by data provider to forward data to the Consumer. Only the specified provider
     * may fulfil the data request.
     * @param _requestId the request the provider is sending data for
     * @param _requestedData the data to send
     * @param _signature data provider's signature of the _requestId, _requestedData and Consumer's address
     * this will used to validate the data's origin in the Consumer's contract
     * @return success if the execution was successful.
     */
    function fulfillRequest(bytes32 _requestId, uint256 _requestedData, bytes memory _signature)
    external
    nonReentrant
    returns (bool){
        require(dataProviders[msg.sender].minFee > 0, "provider not registered");
        require(dataRequests[_requestId].status == REQUEST_STATUS_REQUESTED, "request does not exist");

        address consumer = dataRequests[_requestId].consumer;
        address provider = dataRequests[_requestId].provider;
        uint256 fee = dataRequests[_requestId].fee;

        // signature must be valid. msg.sender must match
        // 1. the provider in the request
        // 2. the address recovered from the signature
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_requestId, _requestedData, consumer)));
        address recoveredProvider = ECDSA.recover(message, _signature);

        // msg.sender is the address of the data provider
        require(msg.sender == provider &&
            msg.sender == recoveredProvider &&
            recoveredProvider == provider,
            "ECDSA.recover mismatch - correct provider and data?"
        );

        emit RequestFulfilled(
            consumer,
            msg.sender,
            _requestId,
            _requestedData
        );

        delete dataRequests[_requestId];

        withdrawableTokens[provider] = withdrawableTokens[provider].add(fee);

        // All checks have passed - send the data to the consumer contract
        // consumer will see msg.sender as the Router's contract address
        // using functionCall from OZ's Address library
        IConsumerBase cb; // just used to get the rawReceiveData function's selector
        require(gasleft() >= 400000, "not enough gas");
        consumer.functionCall(abi.encodeWithSelector(cb.rawReceiveData.selector, _requestedData, _requestId));

        return true;
    }

    /**
     * @dev getTokenAddress - get the contract address of the Token being used for paying fees
     * @return address of the token smart contract
     */
    function getTokenAddress() external view returns (address) {
        return address(token);
    }

    /**
     * @dev getDataRequestConsumer - get the consumer for a request
     * @param _requestId bytes32 request id
     * @return address data consumer contract address
     */
    function getDataRequestConsumer(bytes32 _requestId) external view returns (address) {
        return dataRequests[_requestId].consumer;
    }

    /**
     * @dev getDataRequestProvider - get the consumer for a request
     * @param _requestId bytes32 request id
     * @return address data provider address
     */
    function getDataRequestProvider(bytes32 _requestId) external view returns (address) {
        return dataRequests[_requestId].provider;
    }
    /**
     * @dev requestExists - check a request ID exists
     * @param _requestId bytes32 request id
     * @return bool
     */
    function requestExists(bytes32 _requestId) external view returns (bool) {
        return dataRequests[_requestId].status != REQUEST_STATUS_NOT_SET;
    }

    /**
     * @dev getRequestStatus - check a request status
     * 0 = does not exist/not yet initialised
     * 1 = Request initialised
     * @param _requestId bytes32 request id
     * @return bool
     */
    function getRequestStatus(bytes32 _requestId) external view returns (uint8) {
        return dataRequests[_requestId].status;
    }

    /**
     * @dev getProviderMinFee - returns minimum fee provider will accept to fulfill data request
     * @param _provider address of data provider
     * @return uint256
     */
    function getProviderMinFee(address _provider) external view returns (uint256) {
        return dataProviders[_provider].minFee;
    }

    /**
     * @dev getProviderGranularFee - returns fee provider will accept to fulfill data request
     * for the given consumer
     * @param _provider address of data provider
     * @param _consumer address of consumer contract
     * @return uint256
     */
    function getProviderGranularFee(address _provider, address _consumer) external view returns (uint256) {
        if(dataProviders[_provider].granularFees[_consumer] > 0) {
            return dataProviders[_provider].granularFees[_consumer];
        } else {
            return dataProviders[_provider].minFee;
        }
    }

    /**
     * @dev getWithdrawableTokens - returns withdrawable tokens for the given provider
     * @param _provider address of data provider
     * @return uint256
     */
    function getWithdrawableTokens(address _provider) external view returns (uint256) {
        return withdrawableTokens[_provider];
    }

    /**
     * @dev Reverts if amount is not at least what the provider has set as their min fee
     * @param _feePaid The payment for the request
     * @param _provider address of the provider
     */
    modifier paidSufficientFee(uint256 _feePaid, address _provider) {
        require(_feePaid > 0, "fee cannot be zero");
        if(dataProviders[_provider].granularFees[msg.sender] > 0) {
            require(_feePaid >= dataProviders[_provider].granularFees[msg.sender], "below agreed granular fee");
        } else {
            require(_feePaid >= dataProviders[_provider].minFee, "below agreed min fee");
        }
        _;
    }

    /**
     * @dev Reverts if amount requested is greater than withdrawable balance
     * @param _amount The given amount to compare to `withdrawableTokens`
     */
    modifier hasAvailableTokens(uint256 _amount) {
        require(withdrawableTokens[msg.sender] >= _amount, "can't withdraw more than balance");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IConsumerBase {
    function rawReceiveData(uint256 _price, bytes32 _requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RequestIdBase
 *
 * @dev A contract used by ConsumerBase and Router to generate requestIds
 *
 */
contract RequestIdBase {

    /**
    * @dev makeRequestId generates a requestId
    *
    * @param _dataConsumer address of consumer contract
    * @param _dataProvider address of provider
    * @param _router address of Router contract
    * @param _requestNonce uint256 request nonce
    * @param _data bytes32 hex encoded data endpoint
    *
    * @return bytes32 requestId
    */
    function makeRequestId(
        address _dataConsumer,
        address _dataProvider,
        address _router,
        uint256 _requestNonce,
        bytes32 _data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_dataConsumer, _dataProvider, _router, _requestNonce, _data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

