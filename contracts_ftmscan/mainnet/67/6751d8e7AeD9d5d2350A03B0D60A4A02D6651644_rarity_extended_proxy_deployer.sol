// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract rarity_extended_proxy_deployer {

    uint public nonce;

    event Deployed(address, uint);

    fallback() external payable {}

    receive() external payable {}

    function deploy(bytes memory _code) public payable returns (address addr) {
        assembly {
            // create(v, p, n)
            // v = amount of ETH to send
            // p = pointer in memory to start of code
            // n = size of code
            addr := create(callvalue(), add(_code, 0x20), mload(_code))
        }

        // return address 0 on error
        require(addr != address(0), "failed");

        emit Deployed(addr, nonce);
        nonce++;
    }

}