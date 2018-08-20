/*

  Copyright 2018 HydroProtocol.

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

pragma solidity 0.4.24;

contract ERC20 {
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract Exchange {
    function fillOrder(address[5], uint[6], uint, bool, uint8, bytes32, bytes32) public returns (uint);
}

contract WETH {
    function deposit() public payable;
    function withdraw(uint) public;
}

contract HydroSwap {
    address exchangeAddress;
    address tokenProxyAddress;
    address wethAddress;

    uint256 constant MAX_UINT = 2 ** 256 - 1;

    event LogSwapSuccess(bytes32 indexed id);

    constructor(address _exchangeAddress, address _tokenProxyAddress, address _wethAddress) public {
        exchangeAddress = _exchangeAddress;
        tokenProxyAddress = _tokenProxyAddress;
        wethAddress = _wethAddress;
    }

    function swap(
        bytes32 id,
        address[5] orderAddresses,
        uint[6] orderValues,
        uint8 v,
        bytes32 r,
        bytes32 s)
        external
        payable
        returns (uint256 takerTokenFilledAmount)
    {
        address makerTokenAddress = orderAddresses[2];
        address takerTokenAddress = orderAddresses[3];
        uint makerTokenAmount = orderValues[0];
        uint takerTokenAmount = orderValues[1];

        if (takerTokenAddress == wethAddress) {
            require(takerTokenAmount == msg.value, "WRONG_ETH_AMOUNT");
            WETH(wethAddress).deposit.value(takerTokenAmount)();
        } else {
            require(ERC20(takerTokenAddress).transferFrom(msg.sender, this, takerTokenAmount), "TOKEN_TRANSFER_FROM_ERROR");
        }

        require(ERC20(takerTokenAddress).approve(tokenProxyAddress, takerTokenAmount), "TOKEN_APPROVE_ERROR");

        require(
            Exchange(exchangeAddress).fillOrder(orderAddresses, orderValues, takerTokenAmount, true, v, r, s) == takerTokenAmount,
            "FILL_ORDER_ERROR"
        );

        if (makerTokenAddress == wethAddress) {
            WETH(wethAddress).withdraw(makerTokenAmount);
            msg.sender.transfer(makerTokenAmount);
        } else {
            require(ERC20(makerTokenAddress).transfer(msg.sender, makerTokenAmount), "TOKEN_TRANSFER_ERROR");
        }

        emit LogSwapSuccess(id);

        return takerTokenAmount;
    }

    // Need payable fallback function to accept the WETH withdraw funds.
    function() public payable {} 
}