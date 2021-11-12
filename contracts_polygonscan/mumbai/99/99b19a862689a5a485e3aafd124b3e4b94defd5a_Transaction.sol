/**
 *Submitted for verification at polygonscan.com on 2021-11-12
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


interface IChildERC20 {
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external returns (bytes memory);
}

contract Transaction {  
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