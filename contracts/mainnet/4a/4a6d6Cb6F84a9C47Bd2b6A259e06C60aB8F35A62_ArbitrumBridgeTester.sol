/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.3;



// Part: ERC20

interface ERC20 {
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

// Part: L1GatewayRouter

interface L1GatewayRouter {
    function outboundTransfer(address _token, address _to, uint256 _amount, uint256 _maxGas, uint256 _gasPriceBid, bytes memory _data) external payable;
}

// File: Arbitrum.sol

contract ArbitrumBridgeTester {

    L1GatewayRouter constant gateway = L1GatewayRouter(0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef);
    ERC20 constant crv = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);

    constructor() {
        crv.approve(0xa3A7B6F88361F48403514059F1F16C8E78d60EeC, type(uint256).max);
    }

    function bridgeCRV(
        uint _amount
    ) external payable {
        require(msg.value == 1000000000000000); // 0.001 ether
        crv.transferFrom(msg.sender, address(this), _amount);
        gateway.outboundTransfer{value: msg.value}(
            address(crv),
            address(this),
            _amount,
            1000000,
            990000000,
            abi.encode(10000000000000, bytes(""))
        );
    }
}