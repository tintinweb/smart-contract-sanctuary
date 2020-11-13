pragma solidity ^0.5.10;

/** @title OnDemandSPV */
/** @author Summa (https://summa.one) */

import {ISPVConsumer} from "../Interfaces.sol";
import {OnDemandSPV} from "../OnDemandSPV.sol";

contract DummyConsumer is ISPVConsumer {
    event Consumed(bytes32 indexed _txid, uint256 indexed _requestID, uint256 _gasLeft);

    bool broken = false;

    function setBroken(bool _b) external {
        broken = _b;
    }

    function spv(
        bytes32 _txid,
        bytes calldata,
        bytes calldata,
        uint256 _requestID,
        uint8,
        uint8
    ) external {
        emit Consumed(_txid, _requestID, gasleft());
        if (broken) {
            revert("BORKED");
        }
    }

    function cancel(
        uint256 _requestID,
        address payable _odspv
    ) external returns (bool) {
        return OnDemandSPV(_odspv).cancelRequest(_requestID);
    }
}

contract DummyOnDemandSPV is OnDemandSPV {

    constructor(
        bytes memory _genesisHeader,
        uint256 _height,
        bytes32 _periodStart,
        uint256 _firstID
    ) OnDemandSPV(
        _genesisHeader,
        _height,
        _periodStart,
        _firstID
    ) public {return ;}

    bool callResult = false;

    function requestTest(
        uint256 _requestID,
        bytes calldata _spends,
        bytes calldata _pays,
        uint64 _paysValue,
        address _consumer,
        uint8 _numConfs,
        uint256 _notBefore
    ) external returns (uint256) {
        nextID = _requestID;
        return _request(_spends, _pays, _paysValue, _consumer, _numConfs, _notBefore);
    }

    function setCallResult(bool _r) external {
        callResult = _r;
    }

    function _isAncestor(bytes32, bytes32, uint256) internal view returns (bool) {
        return callResult;
    }

    function getValidatedTx(bytes32 _txid) public view returns (bool) {
        return validatedTxns[_txid];
    }

    function setValidatedTx(bytes32 _txid) public {
        validatedTxns[_txid] = true;
    }

    function unsetValidatedTx(bytes32 _txid) public {
        validatedTxns[_txid] = false;
    }

    function callCallback(
        bytes32 _txid,
        uint16 _reqIndices,
        bytes calldata _vin,
        bytes calldata _vout,
        uint256 _requestID
    ) external returns (bool) {
        return _callCallback(_txid, _reqIndices, _vin, _vout, _requestID);
    }

    function checkInclusion(
        bytes calldata _header,
        bytes calldata _proof,
        uint256 _index,
        bytes32 _txid,
        uint256 _requestID
    ) external view returns (bool) {
        return _checkInclusion(_header, _proof, _index, _txid, _requestID);
    }

    function _getConfs(bytes32 _header) internal view returns (uint8){
        if (_header == bytes32(0)) {
            return OnDemandSPV._getConfs(lastReorgCommonAncestor);
        }
        return 8;
    }

    function getConfsTest() external view returns (uint8) {
        return _getConfs(bytes32(0));
    }

    function checkRequests(
        uint16 _requestIndices,
        bytes calldata _vin,
        bytes calldata _vout,
        uint256 _requestID
    ) external view returns (bool) {
        return _checkRequests(_requestIndices, _vin, _vout, _requestID);
    }

    function whatTimeIsItRightNowDotCom() external view returns (uint256) {
        return block.timestamp;
    }
}
