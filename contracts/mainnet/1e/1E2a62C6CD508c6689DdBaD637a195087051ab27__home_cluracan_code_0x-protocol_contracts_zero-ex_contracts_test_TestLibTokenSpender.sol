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

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

import "../src/features/libs/LibTokenSpender.sol";

contract TestLibTokenSpender {
    uint256 constant private TRIGGER_FALLBACK_SUCCESS_AMOUNT = 1340;

    function spendERC20Tokens(
        IERC20TokenV06 token,
        address owner,
        address to,
        uint256 amount
    )
        external
    {
        LibTokenSpender.spendERC20Tokens(token, owner, to, amount);
    }

    event FallbackCalled(
        address token,
        address owner,
        address to,
        uint256 amount
    );

    // This is called as a fallback when the original transferFrom() fails.
    function _spendERC20Tokens(
        IERC20TokenV06 token,
        address owner,
        address to,
        uint256 amount
    )
        external
    {
        require(amount == TRIGGER_FALLBACK_SUCCESS_AMOUNT,
            "TokenSpenderFallback/FAILURE_AMOUNT");

        emit FallbackCalled(address(token), owner, to, amount);
    }

    function getSpendableERC20BalanceOf(
        IERC20TokenV06 token,
        address owner
    )
        external
        view
        returns (uint256)
    {
        return LibTokenSpender.getSpendableERC20BalanceOf(token, owner);
    }
}
