/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

/**
 * @title BalancerV1ExchangeAdapter
 * @author Set Protocol
 *
 * A Balancer exchange adapter that returns calldata for trading.
 */
contract BalancerV1ExchangeAdapter {

    /* ============ Constants ============ */

    // Amount of pools examined when fetching quote
    uint256 private constant BALANCER_POOL_LIMIT = 3;
    
    /* ============ State Variables ============ */
    
    // Address of Uniswap V2 Router02 contract
    address public immutable balancerProxy;
    // Balancer proxy function string for swapping exact tokens for a minimum of receive tokens
    string internal constant EXACT_IN = "smartSwapExactIn(address,address,uint256,uint256,uint256)";
    // Balancer proxy function string for swapping tokens for an exact amount of receive tokens
    string internal constant EXACT_OUT = "smartSwapExactOut(address,address,uint256,uint256,uint256)";

    /* ============ Constructor ============ */

    /**
     * Set state variables
     *
     * @param _balancerProxy       Balancer exchange proxy address
     */
    constructor(address _balancerProxy) public {
        balancerProxy = _balancerProxy;
    }

    /* ============ External Getter Functions ============ */

    /**
     * Return calldata for Balancer Proxy. Bool to select trade function is encoded in the arbitrary data parameter.
     *
     * @param  _sourceToken              Address of source token to be sold
     * @param  _destinationToken         Address of destination token to buy
     * @param  _destinationAddress       Address that assets should be transferred to
     * @param  _sourceQuantity           Fixed/Max amount of source token to sell
     * @param  _destinationQuantity      Min/Fixed amount of destination tokens to receive
     * @param  _data                     Arbitrary bytes containing bool to determine function string
     *
     * @return address                   Target contract address
     * @return uint256                   Call value
     * @return bytes                     Trade calldata
     */
    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _destinationQuantity,
        bytes memory _data
    )
        external
        view
        returns (address, uint256, bytes memory)
    {   
        (
            bool shouldSwapFixedInputAmount
        ) = abi.decode(_data, (bool));

        bytes memory callData = abi.encodeWithSignature(
            shouldSwapFixedInputAmount ? EXACT_IN : EXACT_OUT,
            _sourceToken,
            _destinationToken,
            shouldSwapFixedInputAmount ? _sourceQuantity : _destinationQuantity,
            shouldSwapFixedInputAmount ? _destinationQuantity : _sourceQuantity,
            BALANCER_POOL_LIMIT
        );

        return (balancerProxy, 0, callData);
    }

    /**
     * Generate data parameter to be passed to `getTradeCallData`. Returns encoded bool to select trade function.
     *
     * @param _sellComponent        Address of the token to be sold        
     * @param _buyComponent         Address of the token to be bought
     * @param _fixIn                Boolean representing if input tokens amount is fixed
     * 
     * @return bytes                Data parameter to be passed to `getTradeCallData`          
     */
    function generateDataParam(address _sellComponent, address _buyComponent, bool _fixIn)
        external
        view
        returns (bytes memory) 
    {   
        return abi.encode(_fixIn);
    }

    /**
     * Returns the address to approve source tokens to for trading. This is the Balancer proxy address
     *
     * @return address             Address of the contract to approve tokens to
     */
    function getSpender() external view returns (address) {
        return balancerProxy;
    }
}

