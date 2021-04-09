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

import "Identity.sol";
import "IQueryableFactRegistry.sol";

/*
  The GpsFactRegistryAdapter contract is used as an adapter between a Dapp contract and a GPS fact
  registry. An isValid(fact) query is answered by querying the GPS contract about
  new_fact := keccak256(programHash, fact).

  The goal of this contract is to simplify the verifier upgradability logic in the Dapp contract
  by making the upgrade flow the same regardless of whether the update is to the program hash or
  the gpsContractAddress.
*/
contract GpsFactRegistryAdapter is IQueryableFactRegistry, Identity {

    IQueryableFactRegistry public gpsContract;
    uint256 public programHash;

    constructor(
        IQueryableFactRegistry gpsStatementContract, uint256 programHash_)
    public {
        gpsContract = gpsStatementContract;
        programHash = programHash_;
    }

    function identify()
        external pure
        returns(string memory)
    {
        return "StarkWare_GpsFactRegistryAdapter_2020_1";
    }

    /*
      Checks if a fact has been verified.
    */
    function isValid(bytes32 fact)
        external view
        returns(bool)
    {
        return gpsContract.isValid(keccak256(abi.encode(programHash, fact)));
    }


    /*
      Indicates whether at least one fact was registered.
    */
    function hasRegisteredFact()
        external view
        returns(bool)
    {
        return gpsContract.hasRegisteredFact();
    }
}