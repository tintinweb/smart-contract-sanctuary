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

/*
  Interface for generic dispatcher to use,
  which the concrete dispatcher must implement.

  I contains the functions that are specific to the concrete dispatcher instance.

  The interface is implemented as contract, because interface implies all methods external.
*/
contract IDispatcher {

    function getSubContract(bytes4 selector) internal view returns (address);

    function setSubContractAddress(uint256 index, address subContract) internal;

    function getNumSubcontracts() internal pure returns (uint256);

    function validateSubContractIndex(uint256 index, address subContract) internal pure;

    /*
      Ensures initializer can be called. Reverts otherwise.
    */
    function initializationSentinel() internal view;
}
