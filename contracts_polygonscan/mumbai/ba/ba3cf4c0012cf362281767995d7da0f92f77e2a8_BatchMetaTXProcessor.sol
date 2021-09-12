/**
 *Submitted for verification at polygonscan.com on 2021-09-11
*/

/* Copyright (C) 2021 PlotX.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */
pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;
contract INativeMetaTransaction {
      function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory);
}
contract BatchMetaTXProcessor {
    event BatchTransactionLog(address[] userAddress, bool[] status);
    function executeBatchMetaTransactions(
        address[] memory targetAddress,
        address[] memory userAddress,
        bytes[] memory functionSignature,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        uint8[] memory sigV
    ) public {
        bool[] memory status = new bool[](userAddress.length);
        for(uint i = 0; i< userAddress.length; i++) {
          (status[i], ) = (targetAddress[i]).call(
            abi.encodeWithSignature("executeMetaTransaction(address,bytes,bytes32,bytes32,uint8)",
                                userAddress[i], functionSignature[i], sigR[i], sigS[i], sigV[i]
                            )
          );
        }
        emit BatchTransactionLog(userAddress, status);
    }
    function execute_forEstimateGas(
        address[] memory targetAddress,
        address[] memory userAddress,
        bytes[] memory functionSignature,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        uint8[] memory sigV
    ) public {
        bytes[] memory returnData = new bytes[](userAddress.length);
        for(uint i = 0; i< userAddress.length; i++) {
          (returnData[i]) = INativeMetaTransaction(targetAddress[i]).executeMetaTransaction(
                                userAddress[i], functionSignature[i], sigR[i], sigS[i], sigV[i]
                            );
        }
    }
}