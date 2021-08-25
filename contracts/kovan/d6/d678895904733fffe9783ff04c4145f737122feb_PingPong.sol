// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.8.0;

import { OVM_CrossDomainEnabled } from "./OVM_CrossDomainEnabled.sol";

contract PingPong is OVM_CrossDomainEnabled {
    address public counterPingPong;
    bool public shouldSucceed;

    uint256 public lastPingTimestamp;
    uint256 public lastPongTimestamp;

    /**
     * @param _CrossDomainMessenger Cross-domain messenger used by this contract.
     */
    constructor(
        address _CrossDomainMessenger
    )
        OVM_CrossDomainEnabled(_CrossDomainMessenger)
    {
        shouldSucceed = true;
    }

    /**
     * Initializes the counter Ping Pong address.
     * @param _counterPingPong Address of the counter Ping Pong contract.
     */
    function initialize(
        address _counterPingPong
    )
        public
    {
        require(counterPingPong == address(0), "Contract has already been initialized.");
        counterPingPong = _counterPingPong;
    }

    function flip() public {
        shouldSucceed = !shouldSucceed;
    }

    function ping() public {
        lastPingTimestamp = block.timestamp;

        bytes memory message = abi.encodeWithSelector(
            this.pong.selector
        );
        sendCrossDomainMessage(
            counterPingPong,
            1000000, // gas limit
            message
        );
    }

    function pong() public onlyFromCrossDomainAccount(counterPingPong) {
        require(shouldSucceed, "Should not succeed");
        lastPongTimestamp = block.timestamp;
    }
}