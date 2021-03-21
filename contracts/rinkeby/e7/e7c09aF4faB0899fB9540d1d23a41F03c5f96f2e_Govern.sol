/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@aragon/govern-contract-utils/contracts/adaptive-erc165/AdaptiveERC165.sol";

abstract contract ERC1271 {
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    function isValidSignature(bytes32 _hash, bytes memory _signature) virtual public view returns (bytes4 magicValue);
}

contract Govern is AdaptiveERC165 {

    // bytes4 internal constant EXEC_ROLE = this.exec.selector;
    // bytes4 internal constant REGISTER_STANDARD_ROLE = this.registerStandardAndCallback.selector;
    // bytes4 internal constant SET_SIGNATURE_VALIDATOR_ROLE = this.setSignatureValidator.selector;
    uint256 internal constant MAX_ACTIONS = 256;


    event ETHDeposited(address indexed sender, uint256 value);

    constructor(address _initialExecutor)  public {
        initialize(_initialExecutor);
    }

    function initialize(address _initialExecutor) public {
        uint x = 800;
        bytes4 bla = type(ERC1271).interfaceId;
        // _registerStandard(ERC3000_EXEC_INTERFACE_ID);
        // _registerStandard(type(ERC1271).interfaceId); //TODO THIS IS BUG
    } 

}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

import "../erc165/ERC165.sol";

contract AdaptiveERC165 is ERC165 {
    // ERC165 interface ID -> whether it is supported
    mapping (bytes4 => bool) internal standardSupported;
    // Callback function signature -> magic number to return
    mapping (bytes4 => bytes32) internal callbackMagicNumbers;

    bytes32 internal constant UNREGISTERED_CALLBACK = bytes32(0);

    event RegisteredStandard(bytes4 interfaceId);
    event RegisteredCallback(bytes4 sig, bytes4 magicNumber);
    event ReceivedCallback(bytes4 indexed sig, bytes data);

    function supportsInterface(bytes4 _interfaceId) override virtual public view returns (bool) {
        return standardSupported[_interfaceId] || super.supportsInterface(_interfaceId);
    }

    function _handleCallback(bytes4 _sig, bytes memory _data) internal {
        bytes32 magicNumber = callbackMagicNumbers[_sig];
        require(magicNumber != UNREGISTERED_CALLBACK, "adap-erc165: unknown callback");

        emit ReceivedCallback(_sig, _data);

        // low-level return magic number
        assembly {
            mstore(0x00, magicNumber)
            return(0x00, 0x20)
        }
    }

    function _registerStandardAndCallback(bytes4 _interfaceId, bytes4 _callbackSig, bytes4 _magicNumber) internal {
        _registerStandard(_interfaceId);
        _registerCallback(_callbackSig, _magicNumber);
    }

    function _registerStandard(bytes4 _interfaceId) internal {
        
    }

    function _registerCallback(bytes4 _callbackSig, bytes4 _magicNumber) internal {
        callbackMagicNumbers[_callbackSig] = _magicNumber;
        emit RegisteredCallback(_callbackSig, _magicNumber);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

abstract contract ERC165 {
    // Includes supportsInterface method:
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) virtual public view returns (bool) {
        return _interfaceId == ERC165_INTERFACE_ID;
    }
}