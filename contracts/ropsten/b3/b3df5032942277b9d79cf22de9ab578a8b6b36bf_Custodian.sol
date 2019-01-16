pragma solidity ^0.4.21;

/** @title  A dual control contract.
  *
  * @notice  A general purpose contract that implements dual control over
  * co-operating contracts through a callback mechanism.
  *
  * @dev  This contract implements dual control through a 2-of-N
  * threshold multi-signature scheme. The contract recognizes a set of N signers,
  * and will unlock requests with signatures from any distinct pair of them.
  * This contract signals the unlocking through a co-operative callback
  * scheme.
  * This contract also provides time lock and revocation features.
  * Requests made by a &#39;primary&#39; account have a default time lock applied.
  * All other request must pay a 1 ETH stake and have an extended time lock
  * applied.
  * A request that is completed will prevent all previous pending requests
  * that share the same callback from being completed: this is the
  * revocation feature.
  *
  * @author  Gemini Trust Company, LLC
  */
contract Custodian {

    // TYPES
    /** @dev  The `Request` struct stores a pending unlocking.
      * `callbackAddress` and `callbackSelector` are the data required to
      * make a callback. The custodian completes the process by
      * calling `callbackAddress.call(callbackSelector, lockId)`, which
      * signals to the contract co-operating with the Custodian that
      * the 2-of-N signatures have been provided and verified.
      */
    struct Request {
        bytes32 lockId;
        bytes4 callbackSelector; // bytes4 and address can be packed into 1 word
        address callbackAddress;
        uint256 idx;
        uint256 timestamp;
        bool extended;
    }

    // EVENTS
    /// @dev  Emitted by successful `requestUnlock` calls.
    event Requested(
        bytes32 _lockId,
        address _callbackAddress,
        bytes4  _callbackSelector,
        uint256 _nonce,
        address _whitelistedAddress,
        bytes32 _requestMsgHash,
        uint256 _timeLockExpiry
    );

    /// @dev  Emitted by `completeUnlock` calls on requests in the time-locked state.
    event TimeLocked(
        uint256 _timeLockExpiry,
        bytes32 _requestMsgHash
    );

    /// @dev  Emitted by successful `completeUnlock` calls.
    event Completed(
        bytes32 _lockId,
        bytes32 _requestMsgHash,
        address _signer1,
        address _signer2
    );

    /// @dev  Emitted by `completeUnlock` calls where the callback failed.
    event Failed(
        bytes32 _lockId,
        bytes32 _requestMsgHash,
        address _signer1,
        address _signer2
    );

    /// @dev  Emitted by successful `extendRequestTimeLock` calls.
    event TimeLockExtended(
        uint256 _timeLockExpiry,
        bytes32 _requestMsgHash
    );

    // MEMBERS
    /** @dev  The count of all requests.
      * This value is used as a nonce, incorporated into the request hash.
      */
    uint256 public requestCount;

    /// @dev  The set of signers: signatures from two signers unlock a pending request.
    mapping (address => bool) public signerSet;

    /// @dev  The map of request hashes to pending requests.
    mapping (bytes32 => Request) public requestMap;

    /// @dev  The map of callback addresses to callback selectors to request indexes.
    mapping (address => mapping (bytes4 => uint256)) public lastCompletedIdxs;

    /** @dev  The default period of time (in seconds) to time-lock requests.
      * All requests will be subject to this default time lock, and the duration
      * is fixed at contract creation.
      */
    uint256 public defaultTimeLock;

    /** @dev  The extended period of time (in seconds) to time-lock requests.
      * Requests not from the primary account are subject to this time lock.
      * The primary account may also elect to extend the time lock on requests
      * that originally received the default.
      */
    uint256 public extendedTimeLock;

    /// @dev  The primary account is the privileged account for making requests.
    address public primary;

    // CONSTRUCTOR
    function Custodian(
        address[] _signers,
        uint256 _defaultTimeLock,
        uint256 _extendedTimeLock,
        address _primary
    )
        public
    {
        // check for at least two `_signers`
        require(_signers.length >= 2);

        // validate time lock params
        require(_defaultTimeLock <= _extendedTimeLock);
        defaultTimeLock = _defaultTimeLock;
        extendedTimeLock = _extendedTimeLock;

        primary = _primary;

        // explicitly initialize `requestCount` to zero
        requestCount = 0;
        // turn the array into a set
        for (uint i = 0; i < _signers.length; i++) {
            // no zero addresses or duplicates
            require(_signers[i] != address(0) && !signerSet[_signers[i]]);
            signerSet[_signers[i]] = true;
        }
    }

    // MODIFIERS
    modifier onlyPrimary {
        require(msg.sender == primary);
        _;
    }

    // METHODS
    /** @notice  Requests an unlocking with a lock identifier and a callback.
      *
      * @dev  If called by an account other than the primary a 1 ETH stake
      * must be paid. This is an anti-spam measure. As well as the callback
      * and the lock identifier parameters a &#39;whitelisted address&#39; is required
      * for compatibility with existing signature schemes.
      *
      * @param  _lockId  The identifier of a pending request in a co-operating contract.
      * @param  _callbackAddress  The address of a co-operating contract.
      * @param  _callbackSelector  The function selector of a function within
      * the co-operating contract at address `_callbackAddress`.
      * @param  _whitelistedAddress  An address whitelisted in existing
      * offline control protocols.
      *
      * @return  requestMsgHash  The hash of a request message to be signed.
      */
    function requestUnlock(
        bytes32 _lockId,
        address _callbackAddress,
        bytes4 _callbackSelector,
        address _whitelistedAddress
    )
        public
        payable
        returns (bytes32 requestMsgHash)
    {
        require(msg.sender == primary || msg.value >= 1 ether);

        // disallow using a zero value for the callback address
        require(_callbackAddress != address(0));

        uint256 requestIdx = ++requestCount;
        // compute a nonce value
        // - the blockhash prevents prediction of future nonces
        // - the address of this contract prevents conflicts with co-operating contracts using this scheme
        // - the counter prevents conflicts arising from multiple txs within the same block
        uint256 nonce = uint256(keccak256(block.blockhash(block.number - 1), address(this), requestIdx));

        requestMsgHash = keccak256(nonce, _whitelistedAddress, uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF));

        requestMap[requestMsgHash] = Request({
            lockId: _lockId,
            callbackSelector: _callbackSelector,
            callbackAddress: _callbackAddress,
            idx: requestIdx,
            timestamp: block.timestamp,
            extended: false
        });

        // compute the expiry time
        uint256 timeLockExpiry = block.timestamp;
        if (msg.sender == primary) {
            timeLockExpiry += defaultTimeLock;
        } else {
            timeLockExpiry += extendedTimeLock;

            // any sender that is not the creator will get the extended time lock
            requestMap[requestMsgHash].extended = true;
        }

        emit Requested(_lockId, _callbackAddress, _callbackSelector, nonce, _whitelistedAddress, requestMsgHash, timeLockExpiry);
    }

    /** @notice  Completes a pending unlocking with two signatures.
      *
      * @dev  Given a request message hash as two signatures of it from
      * two distinct signers in the signer set, this function completes the
      * unlocking of the pending request by executing the callback.
      *
      * @param  _requestMsgHash  The request message hash of a pending request.
      * @param  _recoveryByte1  The public key recovery byte (27 or 28)
      * @param  _ecdsaR1  The R component of an ECDSA signature (R, S) pair
      * @param  _ecdsaS1  The S component of an ECDSA signature (R, S) pair
      * @param  _recoveryByte2  The public key recovery byte (27 or 28)
      * @param  _ecdsaR2  The R component of an ECDSA signature (R, S) pair
      * @param  _ecdsaS2  The S component of an ECDSA signature (R, S) pair
      *
      * @return  success  True if the callback successfully executed.
      */
    function completeUnlock(
        bytes32 _requestMsgHash,
        uint8 _recoveryByte1, bytes32 _ecdsaR1, bytes32 _ecdsaS1,
        uint8 _recoveryByte2, bytes32 _ecdsaR2, bytes32 _ecdsaS2
    )
        public
        returns (bool success)
    {
        Request storage request = requestMap[_requestMsgHash];

        // copy storage to locals before `delete`
        bytes32 lockId = request.lockId;
        address callbackAddress = request.callbackAddress;
        bytes4 callbackSelector = request.callbackSelector;

        // failing case of the lookup if the callback address is zero
        require(callbackAddress != address(0));

        // reject confirms of earlier withdrawals buried under later confirmed withdrawals
        require(request.idx > lastCompletedIdxs[callbackAddress][callbackSelector]);

        address signer1 = ecrecover(_requestMsgHash, _recoveryByte1, _ecdsaR1, _ecdsaS1);
        require(signerSet[signer1]);

        address signer2 = ecrecover(_requestMsgHash, _recoveryByte2, _ecdsaR2, _ecdsaS2);
        require(signerSet[signer2]);
        require(signer1 != signer2);

        if (request.extended && ((block.timestamp - request.timestamp) < extendedTimeLock)) {
            emit TimeLocked(request.timestamp + extendedTimeLock, _requestMsgHash);
            return false;
        } else if ((block.timestamp - request.timestamp) < defaultTimeLock) {
            emit TimeLocked(request.timestamp + defaultTimeLock, _requestMsgHash);
            return false;
        } else {
            if (address(this).balance > 0) {
                // reward sender with anti-spam payments
                // ignore send success (assign to `success` but this will be overwritten)
                success = msg.sender.send(address(this).balance);
            }

            // raise the waterline for the last completed unlocking
            lastCompletedIdxs[callbackAddress][callbackSelector] = request.idx;
            // and delete the request
            delete requestMap[_requestMsgHash];

            // invoke callback
            success = callbackAddress.call(callbackSelector, lockId);

            if (success) {
                emit Completed(lockId, _requestMsgHash, signer1, signer2);
            } else {
                emit Failed(lockId, _requestMsgHash, signer1, signer2);
            }
        }
    }

    /** @notice  Reclaim the storage of a pending request that is uncompleteable.
      *
      * @dev  If a pending request shares the callback (address and selector) of
      * a later request has has been completed, then the request can no longer
      * be completed. This function will reclaim the contract storage of the
      * pending request.
      *
      * @param  _requestMsgHash  The request message hash of a pending request.
      */
    function deleteUncompletableRequest(bytes32 _requestMsgHash) public {
        Request storage request = requestMap[_requestMsgHash];

        uint256 idx = request.idx;

        require(0 < idx && idx < lastCompletedIdxs[request.callbackAddress][request.callbackSelector]);

        delete requestMap[_requestMsgHash];
    }

    /** @notice  Extend the time lock of a pending request.
      *
      * @dev  Requests made by the primary account receive the default time lock.
      * This function allows the primary account to apply the extended time lock
      * to one its own requests.
      *
      * @param  _requestMsgHash  The request message hash of a pending request.
      */
    function extendRequestTimeLock(bytes32 _requestMsgHash) public onlyPrimary {
        Request storage request = requestMap[_requestMsgHash];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_requestMsgHash` is received
        require(request.callbackAddress != address(0));

        // `extendRequestTimeLock` must be idempotent
        require(request.extended != true);

        // set the `extended` flag; note that this is never unset
        request.extended = true;

        emit TimeLockExtended(request.timestamp + extendedTimeLock, _requestMsgHash);
    }
}