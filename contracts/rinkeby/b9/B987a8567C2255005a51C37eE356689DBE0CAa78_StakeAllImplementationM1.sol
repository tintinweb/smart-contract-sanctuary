pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { Variables } from "../variables.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

/**
 * @title StakeAllAccountV2.
 * @dev DeFi Smart Account Wallet.
 */

interface ConnectorsInterface {
    function isConnectors(string[] calldata connectorNames) external view returns (bool, address[] memory);
}

contract Constants is Variables {
    // StakeAllIndex Address.
    address internal immutable stakeAllIndex;
    // Connectors Address.
    address public immutable connectorsM1;

    constructor(address _stakeAllIndex, address _connectors) {
        connectorsM1 = _connectors;
        stakeAllIndex = _stakeAllIndex;
    }
}

contract StakeAllImplementationM1 is Constants {

    constructor(address _stakeAllIndex, address _connectors) Constants(_stakeAllIndex, _connectors) {}

    function decodeEvent(bytes memory response) internal pure returns (string memory _eventCode, bytes memory _eventParams) {
        if (response.length > 0) {
            (_eventCode, _eventParams) = abi.decode(response, (string, bytes));
        }
    }

    event LogCast(
        address indexed origin,
        address indexed sender,
        uint256 value,
        string[] targetsNames,
        address[] targets,
        string[] eventNames,
        bytes[] eventParams
    );

    receive() external payable {}

     /**
     * @dev Delegate the calls to Connector.
     * @param _target Connector address
     * @param _data CallData of function.
    */
    function spell(address _target, bytes memory _data) internal returns (bytes memory response) {
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()
            
            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    returndatacopy(0x00, 0x00, size)
                    revert(0x00, size)
                }
        }
    }


    function recoverSignature(bytes memory encodedPayload, bytes calldata  signature) internal pure returns (address) {
    // Recover
    return ECDSA.recover(
      ECDSA.toEthSignedMessageHash(keccak256(encodedPayload)),
      signature
    );
  }

    function _cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    )
    internal 
    returns (bytes32)
    {
        uint256 _length = _targetNames.length;
        require(_length != 0, "1: length-invalid");
        require(_length == _datas.length , "1: array-length-invalid");

        string[] memory eventNames = new string[](_length);
        bytes[] memory eventParams = new bytes[](_length);

        (bool isOk, address[] memory _targets) = ConnectorsInterface(connectorsM1).isConnectors(_targetNames);

        require(isOk, "1: not-connector");

        for (uint i = 0; i < _length; i++) {
            bytes memory response = spell(_targets[i], _datas[i]);
            (eventNames[i], eventParams[i]) = decodeEvent(response);
        }

        emit LogCast(
            _origin,
            msg.sender,
            msg.value,
            _targetNames,
            _targets,
            eventNames,
            eventParams
        );

    }

    /**
     * @dev This is the main function, Where all the different functions are called
     * from Smart Account.
     * @param _targetNames Array of Connector address.
     * @param _datas Array of Calldata.
    */
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    )
    external
    payable 
    returns (bytes32) // Dummy return to fix stakeAllIndex buildWithCast function
    {   
        
        require(_auth[msg.sender] || msg.sender == stakeAllIndex, "1: permission-denied");
        
        return _cast(
            _targetNames,
            _datas,
            _origin
        );
    }


    function getNonce(uint256 _chainId)
    external 
    returns (uint256)
    {
         return _nonces[_chainId];
    }

    struct CastWithSignatureData {
        string[] targetNames;
        bytes[] datas;
        address origin;
        uint256 chainId;
        uint256 nonce;
    }

    function castWithSignature(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin,
        uint256 _chainId,
        bytes calldata signature
    )
    external
    payable 
    returns (bytes32) 
    {

        require(_targetNames.length == _datas.length , "1: array-length-invalid");
        uint256 nonce = _nonces[_chainId];

        _nonces[_chainId] = _nonces[_chainId] + 1;

        string[] memory targetNames = new string[](_targetNames.length);
        bytes[] memory datas = new bytes[](_datas.length);

        for (uint i = 0; i < _targetNames.length; i++) {
            targetNames[i] = _targetNames[i];
            datas[i] = _datas[i];
        }

        CastWithSignatureData memory payload = CastWithSignatureData({
            targetNames: targetNames,
            datas: datas,
            origin: _origin,
            chainId: _chainId,
            nonce: nonce
        });           
        address owner = recoverSignature(abi.encode(payload), signature);
        require(_auth[owner], "!owner");

        return _cast(
            _targetNames,
            _datas,
            _origin
        );
    }
}

pragma solidity ^0.7.0;

contract Variables {
    // Auth Module(Address of Auth => bool).
    mapping (address => bool) internal _auth;

    // nonces chainId => nonces
    mapping (uint256 => uint256) internal _nonces;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
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
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}