/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";

contract TestStaking {
    mapping(address => bytes32) public poolForMaker;
    mapping(bytes32 => uint256) public balanceForPool;

    IEtherTokenV06 immutable weth;

    constructor(IEtherTokenV06 _weth) public {
        weth = _weth;
    }

    function joinStakingPoolAsMaker(bytes32 poolId) external {
        poolForMaker[msg.sender] = poolId;
    }

    function payProtocolFee(
        address makerAddress,
        address payerAddress,
        uint256 amount
    )
        external
        payable
    {
        require(weth.transferFrom(payerAddress, address(this), amount));
        balanceForPool[poolForMaker[makerAddress]] += amount;
    }
}
