/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.5.2;

import "MainStorage.sol";
import "MTokenQuantization.sol";


contract TokenQuantization is MainStorage, MTokenQuantization {

    function fromQuantized(uint256 presumedAssetType, uint256 quantizedAmount)
        internal view returns (uint256 amount) {
        uint256 quantum = getQuantum(presumedAssetType);
        amount = quantizedAmount * quantum;
        require(amount / quantum == quantizedAmount, "DEQUANTIZATION_OVERFLOW");
    }

    function getQuantum(uint256 presumedAssetType) public view returns (uint256 quantum) {
        if (!registeredAssetType[presumedAssetType]) {
            // Default quantization, for NFTs etc.
            quantum = 1;
        } else {
            // Retrieve registration.
            quantum = assetTypeToQuantum[presumedAssetType];
        }
    }

    function toQuantized(uint256 presumedAssetType, uint256 amount)
        internal view returns (uint256 quantizedAmount) {
        uint256 quantum = getQuantum(presumedAssetType);
        require(amount % quantum == 0, "INVALID_AMOUNT");
        quantizedAmount = amount / quantum;
    }
}
