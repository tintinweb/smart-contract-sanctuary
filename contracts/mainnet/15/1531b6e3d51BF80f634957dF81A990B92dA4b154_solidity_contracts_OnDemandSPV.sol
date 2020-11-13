pragma solidity ^0.5.10;

/** @title OnDemandSPV */
/** @author Summa (https://summa.one) */

import {Relay} from "./Relay.sol";
import {ISPVRequestManager, ISPVConsumer} from "./Interfaces.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {ValidateSPV} from "@summa-tx/bitcoin-spv-sol/contracts/ValidateSPV.sol";
import {SafeMath} from "@summa-tx/bitcoin-spv-sol/contracts/SafeMath.sol";


contract OnDemandSPV is ISPVRequestManager, Relay {
    using SafeMath for uint256;
    using BytesLib for bytes;
    using BTCUtils for bytes;

    struct ProofRequest {
        bytes32 spends;
        bytes32 pays;
        uint256 notBefore;
        address consumer;
        uint64 paysValue;
        uint8 numConfs;
        address owner;
        RequestStates state;
    }

    enum RequestStates { NONE, ACTIVE, CLOSED }
    mapping (bytes32 => bool) internal validatedTxns;  // authenticated tx store
    mapping (uint256 => ProofRequest) internal requests;  // request info
    uint256 public constant BASE_COST = 24 * 60 * 60;  // 1 day

    uint256 public nextID;
    bytes32 public latestValidatedTx;
    uint256 public remoteGasAllowance = 500000; // maximum gas for callback call

    /// @notice                   Gives a starting point for the relay
    /// @dev                      We don't check this AT ALL really. Don't use relays with bad genesis
    /// @param  _genesisHeader    The starting header
    /// @param  _height           The starting height
    /// @param  _periodStart      The hash of the first header in the genesis epoch
    constructor(
        bytes memory _genesisHeader,
        uint256 _height,
        bytes32 _periodStart,
        uint256 _firstID
    ) Relay(
        _genesisHeader,
        _height,
        _periodStart
    ) public {
        nextID = _firstID;
    }

    /// @notice                 Cancel a bitcoin event request.
    /// @dev                    Prevents the relay from forwarding tx infromation
    /// @param  _requestID      The ID of the request to be cancelled
    /// @return                 True if succesful, error otherwise
    function cancelRequest(uint256 _requestID) external returns (bool) {
        ProofRequest storage _req = requests[_requestID];
        require(_req.state == RequestStates.ACTIVE, "Request not active");
        require(msg.sender == _req.consumer || msg.sender == _req.owner, "Can only be cancelled by owner or consumer");
        _req.state = RequestStates.CLOSED;
        emit RequestClosed(_requestID);
        return true;
    }

    function getLatestValidatedTx() external view returns (bytes32) {
        return latestValidatedTx;
    }

    /// @notice             Retrieve info about a request
    /// @dev                Requests ids are numerical
    /// @param  _requestID  The numerical ID of the request
    /// @return             A tuple representation of the request struct
    function getRequest(
        uint256 _requestID
    ) external view returns (
        bytes32 spends,
        bytes32 pays,
        uint64 paysValue,
        uint8 state,
        address consumer,
        address owner,
        uint8 numConfs,
        uint256 notBefore
    ) {
        ProofRequest storage _req = requests[_requestID];
        spends = _req.spends;
        pays = _req.pays;
        paysValue = _req.paysValue;
        state = uint8(_req.state);
        consumer = _req.consumer;
        owner = _req.owner;
        numConfs = _req.numConfs;
        notBefore = _req.notBefore;
    }

    /// @notice                 Subscribe to a feed of Bitcoin txns matching a request
    /// @dev                    The request can be a spent utxo and/or a created utxo
    /// @param  _spends         An outpoint that must be spent in acceptable txns (optional)
    /// @param  _pays           An output script that must be paid in acceptable txns (optional)
    /// @param  _paysValue      A minimum value that must be paid to the output script (optional)
    /// @param  _consumer       The address of a ISPVConsumer exposing spv
    /// @param  _numConfs       The minimum number of Bitcoin confirmations to accept
    /// @param  _notBefore      A timestamp before which proofs are not accepted
    /// @return                 A unique request ID.
    function request(
        bytes calldata _spends,
        bytes calldata _pays,
        uint64 _paysValue,
        address _consumer,
        uint8 _numConfs,
        uint256 _notBefore
    ) external returns (uint256) {
        return _request(_spends, _pays, _paysValue, _consumer, _numConfs, _notBefore);
    }

    /// @notice                 Subscribe to a feed of Bitcoin txns matching a request
    /// @dev                    The request can be a spent utxo and/or a created utxo
    /// @param  _spends         An outpoint that must be spent in acceptable txns (optional)
    /// @param  _pays           An output script that must be paid in acceptable txns (optional)
    /// @param  _paysValue      A minimum value that must be paid to the output script (optional)
    /// @param  _consumer       The address of a ISPVConsumer exposing spv
    /// @param  _numConfs       The minimum number of Bitcoin confirmations to accept
    /// @param  _notBefore      A timestamp before which proofs are not accepted
    /// @return                 A unique request ID
    function _request(
        bytes memory _spends,
        bytes memory _pays,
        uint64 _paysValue,
        address _consumer,
        uint8 _numConfs,
        uint256 _notBefore
    ) internal returns (uint256) {
        uint256 _requestID = nextID;
        nextID = nextID + 1;
        bytes memory pays = _pays;

        require(_spends.length == 36 || _spends.length == 0, "Not a valid UTXO");

        /* NB: This will fail if the output is not p2pkh, p2sh, p2wpkh, or p2wsh*/
        uint256 _paysLen = pays.length;

        // if it's not length-prefixed, length-prefix it
        if (_paysLen > 0 && uint8(pays[0]) != _paysLen - 1) {
            pays = abi.encodePacked(uint8(_paysLen), pays);
            _paysLen += 1; // update the length because we made it longer
        }

        bytes memory _p = abi.encodePacked(bytes8(0), pays);
        require(
            _paysLen == 0 ||  // no request OR
            _p.extractHash().length > 0 || // standard output OR
            _p.extractOpReturnData().length > 0, // OP_RETURN output
            "Not a standard output type");

        require(_spends.length > 0 || _paysLen > 0, "No request specified");

        ProofRequest storage _req = requests[_requestID];
        _req.owner = msg.sender;

        if (_spends.length > 0) {
            _req.spends = keccak256(_spends);
        }
        if (_paysLen > 0) {
            _req.pays = keccak256(pays);
        }
        if (_paysValue > 0) {
            _req.paysValue = _paysValue;
        }
        if (_numConfs > 0 && _numConfs < 241) { //241 is arbitray. 40 hours
            _req.numConfs = _numConfs;
        }
        if (_notBefore > 0) {
            _req.notBefore = _notBefore;
        }
        _req.consumer = _consumer;
        _req.state = RequestStates.ACTIVE;

        emit NewProofRequest(msg.sender, _requestID, _paysValue, _spends, pays);

        return _requestID;
    }

    /// @notice                 Provide a proof of a tx that satisfies some request
    /// @dev                    The caller must specify which inputs, which outputs, and which request
    /// @param  _header         The header containing the merkleroot committing to the tx
    /// @param  _proof          The merkle proof intermediate nodes
    /// @param  _version        The tx version, always the first 4 bytes of the tx
    /// @param  _locktime       The tx locktime, always the last 4 bytes of the tx
    /// @param  _index          The index of the tx in the merkle tree's leaves
    /// @param  _reqIndices  The input and output index to check against the request, packed
    /// @param  _vin            The tx input vector
    /// @param  _vout           The tx output vector
    /// @param  _requestID       The id of the request that has been triggered
    /// @return                 True if succesful, error otherwise
    function provideProof(
        bytes calldata _header,
        bytes calldata _proof,
        bytes4 _version,
        bytes4 _locktime,
        uint256 _index,
        uint16 _reqIndices,
        bytes calldata _vin,
        bytes calldata _vout,
        uint256 _requestID
    ) external returns (bool) {
        bytes32 _txid = abi.encodePacked(_version, _vin, _vout, _locktime).hash256();
        /*
        NB: this shortcuts validation of any txn we've seen before
            repeats can omit header, proof, and index
        */
        if (!validatedTxns[_txid]) {
            _checkInclusion(
                _header,
                _proof,
                _index,
                _txid,
                _requestID);
            validatedTxns[_txid] = true;
            latestValidatedTx = _txid;
        }
        _checkRequests(_reqIndices, _vin, _vout, _requestID);
        _callCallback(_txid, _reqIndices, _vin, _vout, _requestID);
        return true;
    }

    /// @notice             Notify a consumer that one of its requests has been triggered
    /// @dev                We include information about the tx that triggered it, so the consumer can take actions
    /// @param  _vin        The tx input vector
    /// @param  _vout       The tx output vector
    /// @param  _txid       The transaction ID
    /// @param  _requestID   The id of the request that has been triggered
    function _callCallback(
        bytes32 _txid,
        uint16 _reqIndices,
        bytes memory _vin,
        bytes memory _vout,
        uint256 _requestID
    ) internal returns (bool) {
        ProofRequest storage _req = requests[_requestID];
        ISPVConsumer c = ISPVConsumer(_req.consumer);

        uint8 _inputIndex = uint8(_reqIndices >> 8);
        uint8 _outputIndex = uint8(_reqIndices & 0xff);

        /*
        NB:
        We want to make the remote call, but we don't care about results
        We use the low-level call so that we can ignore reverts and set gas
        */
        address(c).call.gas(remoteGasAllowance)(
            abi.encodePacked(
                c.spv.selector,
                abi.encode(_txid, _vin, _vout, _requestID, _inputIndex, _outputIndex)
            )
        );

        emit RequestFilled(_txid, _requestID);

        return true;
    }

    /// @notice             Verifies inclusion of a tx in a header, and that header in the Relay chain
    /// @dev                Specifically we check that both the best tip and the heaviest common header confirm it
    /// @param  _header     The header containing the merkleroot committing to the tx
    /// @param  _proof      The merkle proof intermediate nodes
    /// @param  _index      The index of the tx in the merkle tree's leaves
    /// @param  _txid       The txid that is the proof leaf
    /// @param _requestID   The ID of the request to check against
    function _checkInclusion(
        bytes memory _header,
        bytes memory _proof,
        uint256 _index,
        bytes32 _txid,
        uint256 _requestID
    ) internal view returns (bool) {
        require(
            ValidateSPV.prove(
                _txid,
                _header.extractMerkleRootLE().toBytes32(),
                _proof,
                _index),
            "Bad inclusion proof");

        bytes32 _headerHash = _header.hash256();
        bytes32 _GCD = getLastReorgCommonAncestor();

        require(
            _isAncestor(
                _headerHash,
                _GCD,
                240),
            "GCD does not confirm header");
        uint8 _numConfs = requests[_requestID].numConfs;
        require(
            _getConfs(_headerHash) >= _numConfs,
            "Insufficient confirmations");

        return true;
    }

    /// @notice             Finds the number of headers on top of the argument
    /// @dev                Bounded to 6400 gas (8 looksups) max
    /// @param _headerHash  The LE double-sha2 header hash
    /// @return             The number of headers on top
    function _getConfs(bytes32 _headerHash) internal view returns (uint8) {
        return uint8(_findHeight(bestKnownDigest) - _findHeight(_headerHash));
    }

    /// @notice                 Verifies that a tx meets the requester's request
    /// @dev                    Requests can be specify an input, and output, and/or an output value
    /// @param  _reqIndices  The input and output index to check against the request, packed
    /// @param  _vin            The tx input vector
    /// @param  _vout           The tx output vector
    /// @param  _requestID       The id of the request to check
    function _checkRequests (
        uint16 _reqIndices,
        bytes memory _vin,
        bytes memory _vout,
        uint256 _requestID
    ) internal view returns (bool) {
        require(_vin.validateVin(), "Vin is malformatted");
        require(_vout.validateVout(), "Vout is malformatted");

        uint8 _inputIndex = uint8(_reqIndices >> 8);
        uint8 _outputIndex = uint8(_reqIndices & 0xff);

        ProofRequest storage _req = requests[_requestID];
        require(_req.notBefore <= block.timestamp, "Request is submitted too early");
        require(_req.state == RequestStates.ACTIVE, "Request is not active");

        bytes32 _pays = _req.pays;
        bool _hasPays = _pays != bytes32(0);
        if (_hasPays) {
            bytes memory _out = _vout.extractOutputAtIndex(uint8(_outputIndex));
            bytes memory _scriptPubkey = _out.slice(8, _out.length - 8);
            require(
                keccak256(_scriptPubkey) == _pays,
                "Does not match pays request");
            uint64 _paysValue = _req.paysValue;
            require(
                _paysValue == 0 ||
                _out.extractValue() >= _paysValue,
                "Does not match value request");
        }

        bytes32 _spends = _req.spends;
        bool _hasSpends = _spends != bytes32(0);
        if (_hasSpends) {
            bytes memory _in = _vin.extractInputAtIndex(uint8(_inputIndex));
            require(
                !_hasSpends ||
                keccak256(_in.extractOutpoint()) == _spends,
                "Does not match spends request");
        }
        return true;
    }
}
