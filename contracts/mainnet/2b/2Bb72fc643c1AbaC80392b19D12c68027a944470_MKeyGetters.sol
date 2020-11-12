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

contract MKeyGetters {
    // NOLINTNEXTLINE: external-function.
    function getEthKey(uint256 starkKey) public view returns (address ethKey);

    function isMsgSenderStarkKeyOwner(uint256 starkKey) internal view returns (bool);

    /*
      Allows calling the function only if starkKey is registered to msg.sender.
    */
    modifier isSenderStarkKey(uint256 starkKey)
    {
        // Pure modifier declarations are not supported. Instead we provide
        // a dummy definition.
        revert("UNIMPLEMENTED");
        _;
    }
}
