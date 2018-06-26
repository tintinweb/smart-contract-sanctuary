pragma solidity ^0.4.24;

// File: contracts/token/TransferAndCallbackReceiver.sol

/**
 * An interface for a contract that receives tokens and gets notified after the transfer
 */
contract TransferAndCallbackReceiver { 
/**
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function balanceTransferred(address _from, uint256 _value, bytes _data) public;
}

// File: contracts/test/ContractWithCallback.sol

/**
    This contract is used in testing PathToken&#39; TransferAndCallback functionality
 */


contract ContractWithCallback is TransferAndCallbackReceiver {
    address public approvedToken;
    uint256 public lastData;

    constructor (address _approvedToken) public {
        approvedToken = _approvedToken;
    }

    address public user;
    bytes32 public seekerPublicKey;
    bytes32 public certificateId;

    // Here we receive additional data as bytes type
    // and unpack into expected variables
    function balanceTransferred(address, uint256, bytes _data) public {
        require(msg.sender == approvedToken);

        uint256 btsptr;
        address _user;
        bytes32 _seekerPublicKey;
        bytes32 _certificateId;

        // We need to unpack (address _user, bytes32 _seekerPublicKey, bytes32 certificateId)
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            btsptr := add(_data, /*BYTES_HEADER_SIZE*/32)
            _user := mload(btsptr)
            btsptr := add(_data, /*BYTES_HEADER_SIZE*/64)
            _seekerPublicKey := mload(btsptr)
            btsptr := add(_data, /*BYTES_HEADER_SIZE*/96)
            _certificateId := mload(btsptr)
        }

        user = _user;
        seekerPublicKey = _seekerPublicKey;
        certificateId = _certificateId;
    }


}