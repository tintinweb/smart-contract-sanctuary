/**
 *Submitted for verification at polygonscan.com on 2021-09-05
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
contract BatchMetaTXProcessor {
    function executeBatchMetaTransactions(
        address[] memory targetAddress,
        address[] memory userAddress,
        bytes[] memory functionSignature,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        uint8[] memory sigV
    ) public payable returns (bytes[] memory returnData, bool[] memory status) {
        returnData = new bytes[](userAddress.length);
        status = new bool[](userAddress.length);
        for(uint i = 0; i< userAddress.length; i++) {
          (status[i], returnData[i]) = (targetAddress[i]).call(
            abi.encodeWithSignature("executeMetaTransaction(address,bytes,bytes32,bytes32,uint8)",
                                userAddress[i], functionSignature[i], sigR[i], sigS[i], sigV[i]
                            )
          );
        }
    }
}