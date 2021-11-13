/**
 *Submitted for verification at polygonscan.com on 2021-11-12
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

    constructor() {
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

interface IChildERC20 {
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external returns (bytes memory);
}

contract Transaction is ReentrancyGuard {  
    struct DataTx {
        address userAddress;
        bytes functionSignature;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }

    function executeTransaction(
        IChildERC20 cERC20,
        DataTx memory transferFromData, 
        DataTx memory withdrawData
    )
        public 
        nonReentrant
        returns (bytes memory transferFromByte, bytes memory withdrawByte) 
    {
        transferFromByte = cERC20.executeMetaTransaction(
            transferFromData.userAddress,
            transferFromData.functionSignature,
            transferFromData.sigR,
            transferFromData.sigS,
            transferFromData.sigV
        ); 

        withdrawByte = cERC20.executeMetaTransaction(
            withdrawData.userAddress,
            withdrawData.functionSignature,
            withdrawData.sigR,
            withdrawData.sigS,
            withdrawData.sigV
        );
    }
}